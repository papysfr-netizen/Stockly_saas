const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { onDocumentWritten } = require('firebase-functions/v2/firestore');
const { defineSecret, defineString } = require('firebase-functions/params');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue, Timestamp } = require('firebase-admin/firestore');
const { calculerRelances, envoyerTwilio, normaliserTelephone } = require('./rappels');
const { notificationsAEnvoyer, messageRemplacement, variablesRemplacement } = require('./remplacements');
const { doitAlerter, messageAbsence, variablesAbsence } = require('./absences');

initializeApp();
const db = getFirestore();

// Secrets : firebase functions:secrets:set TWILIO_ACCOUNT_SID (puis TWILIO_AUTH_TOKEN)
const TWILIO_ACCOUNT_SID = defineSecret('TWILIO_ACCOUNT_SID');
const TWILIO_AUTH_TOKEN = defineSecret('TWILIO_AUTH_TOKEN');
// Paramètres non secrets, demandés au premier déploiement (ou fichier functions/.env).
const TWILIO_SMS_FROM = defineString('TWILIO_SMS_FROM', { default: '', description: 'Numéro (+…) ou Messaging Service SID (MG…) pour les SMS' });
const TWILIO_WHATSAPP_FROM = defineString('TWILIO_WHATSAPP_FROM', { default: '', description: 'Numéro WhatsApp Twilio (+…)' });
const TWILIO_WHATSAPP_CONTENT_SID = defineString('TWILIO_WHATSAPP_CONTENT_SID', { default: '', description: 'Modèle WhatsApp approuvé (HX…), variables {{1}} parent, {{2}} élève, {{3}} montant, {{4}} école' });
const TWILIO_WHATSAPP_REMPLACEMENT_SID = defineString('TWILIO_WHATSAPP_REMPLACEMENT_SID', { default: '', description: 'Modèle WhatsApp « remplacement » (HX…), variables {{1}} enseignant, {{2}} date, {{3}} heure, {{4}} classe, {{5}} branche, {{6}} école' });
const TWILIO_WHATSAPP_ANNULATION_SID = defineString('TWILIO_WHATSAPP_ANNULATION_SID', { default: '', description: 'Modèle WhatsApp « remplacement annulé » (HX…), mêmes variables' });

const TWILIO_WHATSAPP_ABSENCE_SID = defineString('TWILIO_WHATSAPP_ABSENCE_SID', { default: '', description: 'Modèle WhatsApp « absence » (HX…), variables {{1}} parent, {{2}} élève, {{3}} classe, {{4}} date, {{5}} école' });

function configTwilio(whatsappContentSid) {
  return {
    accountSid: TWILIO_ACCOUNT_SID.value(),
    authToken: TWILIO_AUTH_TOKEN.value(),
    smsFrom: TWILIO_SMS_FROM.value(),
    whatsappFrom: TWILIO_WHATSAPP_FROM.value(),
    whatsappContentSid,
  };
}

/**
 * Envoie les rappels d'impayés aux parents.
 * data : { ecoleId, canal: 'sms' | 'whatsapp', eleveIds?: string[] }
 * Seuls la direction et le secrétariat de l'école peuvent l'appeler.
 * Un même élève n'est pas relancé deux fois en moins de 24 h.
 */
exports.envoyerRappels = onCall(
  { region: 'europe-west1', secrets: [TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN], timeoutSeconds: 300 },
  async (req) => {
    if (!req.auth) throw new HttpsError('unauthenticated', 'Connexion requise.');
    const { ecoleId, canal, eleveIds } = req.data || {};
    if (!['sms', 'whatsapp'].includes(canal)) throw new HttpsError('invalid-argument', 'Canal invalide.');
    if (eleveIds !== undefined && !Array.isArray(eleveIds)) throw new HttpsError('invalid-argument', 'eleveIds invalide.');

    const user = (await db.doc(`users/${req.auth.uid}`).get()).data();
    if (!user || user.ecoleId !== ecoleId || !['admin', 'secretariat'].includes(user.role)) {
      throw new HttpsError('permission-denied', 'Réservé à la direction et au secrétariat.');
    }

    const ecoleRef = db.doc(`ecoles/${ecoleId}`);
    const depuis = Timestamp.fromMillis(Date.now() - 24 * 3600 * 1000);
    const [ecoleSnap, classes, eleves, paiements, rappels] = await Promise.all([
      ecoleRef.get(),
      ecoleRef.collection('classes').get(),
      ecoleRef.collection('eleves').where('actif', '==', true).get(),
      ecoleRef.collection('paiements').get(),
      ecoleRef.collection('rappels').where('date', '>=', depuis).get(),
    ]);
    const docs = (s) => s.docs.map((d) => ({ id: d.id, ...d.data() }));
    const derniersRappels = {};
    for (const r of rappels.docs) {
      const d = r.data();
      if (d.canal === canal && d.statut !== 'echec') derniersRappels[d.eleveId] = d.date.toDate();
    }

    const { aRelancer, sansTelephone, recents } = calculerRelances({
      eleves: docs(eleves),
      classes: docs(classes),
      paiements: docs(paiements),
      derniersRappels,
      ecole: ecoleSnap.data() || {},
      eleveIds,
    });
    if (aRelancer.length > 500) throw new HttpsError('resource-exhausted', 'Plus de 500 rappels : filtrez par classe.');

    const config = configTwilio(TWILIO_WHATSAPP_CONTENT_SID.value());

    let envoyes = 0;
    const echecs = [];
    const batch = db.batch();
    for (const l of aRelancer) {
      const trace = {
        eleveId: l.eleveId, canal, mode: 'auto', telephone: l.telephone, montant: l.reste,
        par: user.nom || '', date: FieldValue.serverTimestamp(),
      };
      try {
        const sid = await envoyerTwilio({ canal, to: l.telephone, body: l.message, variables: l.variables, config });
        envoyes++;
        batch.set(ecoleRef.collection('rappels').doc(), { ...trace, statut: 'envoye', sid });
      } catch (e) {
        echecs.push({ eleveId: l.eleveId, erreur: e.message });
        batch.set(ecoleRef.collection('rappels').doc(), { ...trace, statut: 'echec', erreur: e.message });
      }
    }
    await batch.commit();

    return {
      envoyes,
      echecs: echecs.length,
      erreurs: [...new Set(echecs.map((e) => e.erreur))].slice(0, 3),
      sansTelephone: sansTelephone.length,
      recents: recents.length,
    };
  },
);

/**
 * Prévient l'enseignant remplaçant (SMS ou WhatsApp, selon le réglage
 * `notificationRemplacement` de l'école) quand il est désigné, et l'ancien
 * remplaçant quand le cours lui est retiré (autre remplaçant, étude,
 * annulation, absence supprimée). Chaque envoi est tracé dans `notifications` ;
 * le résultat de l'affectation est aussi écrit sur le remplacement.
 */
exports.notifierRemplacant = onDocumentWritten(
  { document: 'ecoles/{ecoleId}/remplacements/{id}', region: 'europe-west1', secrets: [TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN] },
  async (event) => {
    const avant = event.data.before.exists ? event.data.before.data() : null;
    const apres = event.data.after.exists ? event.data.after.data() : null;
    const aEnvoyer = notificationsAEnvoyer(avant, apres);
    if (aEnvoyer.length === 0) return;

    const { ecoleId, id } = event.params;
    const ecoleRef = db.doc(`ecoles/${ecoleId}`);
    const ecole = (await ecoleRef.get()).data() || {};
    const canal = ecole.notificationRemplacement;
    if (!['sms', 'whatsapp'].includes(canal)) return;

    const r = apres || avant;
    const [classe, matiere] = await Promise.all([
      ecoleRef.collection('classes').doc(r.classeId).get(),
      ecoleRef.collection('matieres').doc(r.matiereId).get(),
    ]);

    for (const n of aEnvoyer) {
      const ens = (await ecoleRef.collection('enseignants').doc(n.enseignantId).get()).data() || {};
      const infos = {
        type: n.type,
        remplacant: `${ens.prenom || ''} ${ens.nom || ''}`.trim() || 'cher collègue',
        absent: r.enseignantAbsentNom || 'un collègue',
        date: r.date,
        plage: r.plage,
        classe: (classe.data() || {}).nom || '',
        branche: (matiere.data() || {}).nom || '',
        ecole: ecole.nom || '',
      };
      const telephone = normaliserTelephone(ens.telephone, ecole.indicatif || '+243');
      let resultat;
      if (!telephone) {
        resultat = { statut: 'sans_telephone' };
      } else {
        try {
          const sid = await envoyerTwilio({
            canal,
            to: telephone,
            body: messageRemplacement(infos),
            variables: variablesRemplacement(infos),
            config: configTwilio(n.type === 'affectation' ? TWILIO_WHATSAPP_REMPLACEMENT_SID.value() : TWILIO_WHATSAPP_ANNULATION_SID.value()),
          });
          resultat = { statut: 'envoye', sid };
        } catch (e) {
          resultat = { statut: 'echec', erreur: e.message };
        }
      }
      await ecoleRef.collection('notifications').add({
        type: n.type, enseignantId: n.enseignantId, remplacementId: id, canal, telephone: telephone || '',
        ...resultat, date: FieldValue.serverTimestamp(),
      });
      // Écrit seulement `notification` : ne change pas le remplaçant, donc ne redéclenche pas d'envoi.
      if (n.type === 'affectation' && event.data.after.exists) {
        await event.data.after.ref.update({
          notification: { ...resultat, canal, enseignantId: n.enseignantId, date: FieldValue.serverTimestamp() },
        });
      }
    }
  },
);

/**
 * Prévient le parent dès que son enfant est noté absent à l'appel (réglage
 * `alerteAbsence` de l'école : 'sms' ou 'whatsapp'). Le résultat de l'envoi
 * est écrit sur la fiche d'absence (champ `alerte`).
 */
exports.alerterParentAbsence = onDocumentWritten(
  { document: 'ecoles/{ecoleId}/absences/{id}', region: 'europe-west1', secrets: [TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN] },
  async (event) => {
    const avant = event.data.before.exists ? event.data.before.data() : null;
    const apres = event.data.after.exists ? event.data.after.data() : null;
    if (!doitAlerter(avant, apres)) return;

    const ecoleRef = db.doc(`ecoles/${event.params.ecoleId}`);
    const ecole = (await ecoleRef.get()).data() || {};
    const canal = ecole.alerteAbsence;
    if (!['sms', 'whatsapp'].includes(canal)) return;

    const [eleveSnap, classeSnap] = await Promise.all([
      ecoleRef.collection('eleves').doc(apres.eleveId).get(),
      ecoleRef.collection('classes').doc(apres.classeId).get(),
    ]);
    const eleve = eleveSnap.data() || {};
    const date = apres.date && apres.date.toDate ? apres.date.toDate().toISOString().slice(0, 10) : String(apres.jour || '');
    const infos = {
      parent: eleve.parentNom,
      eleve: `${eleve.nom || ''} ${eleve.prenom || ''}`.trim(),
      classe: (classeSnap.data() || {}).nom || '',
      date,
      ecole: ecole.nom || '',
    };
    const telephone = normaliserTelephone(eleve.parentTelephone, ecole.indicatif || '+243');
    let resultat;
    if (!telephone) {
      resultat = { statut: 'sans_telephone' };
    } else {
      try {
        const sid = await envoyerTwilio({
          canal, to: telephone, body: messageAbsence(infos), variables: variablesAbsence(infos),
          config: configTwilio(TWILIO_WHATSAPP_ABSENCE_SID.value()),
        });
        resultat = { statut: 'envoye', sid };
      } catch (e) {
        resultat = { statut: 'echec', erreur: e.message };
      }
    }
    await ecoleRef.collection('notifications').add({
      type: 'absence', eleveId: apres.eleveId, absenceId: event.params.id, canal, telephone: telephone || '',
      ...resultat, date: FieldValue.serverTimestamp(),
    });
    await event.data.after.ref.update({ alerte: { ...resultat, canal, date: FieldValue.serverTimestamp() } });
  },
);
