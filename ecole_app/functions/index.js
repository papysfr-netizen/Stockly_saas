const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { defineSecret, defineString } = require('firebase-functions/params');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue, Timestamp } = require('firebase-admin/firestore');
const { calculerRelances, envoyerTwilio } = require('./rappels');

initializeApp();
const db = getFirestore();

// Secrets : firebase functions:secrets:set TWILIO_ACCOUNT_SID (puis TWILIO_AUTH_TOKEN)
const TWILIO_ACCOUNT_SID = defineSecret('TWILIO_ACCOUNT_SID');
const TWILIO_AUTH_TOKEN = defineSecret('TWILIO_AUTH_TOKEN');
// Paramètres non secrets, demandés au premier déploiement (ou fichier functions/.env).
const TWILIO_SMS_FROM = defineString('TWILIO_SMS_FROM', { default: '', description: 'Numéro (+…) ou Messaging Service SID (MG…) pour les SMS' });
const TWILIO_WHATSAPP_FROM = defineString('TWILIO_WHATSAPP_FROM', { default: '', description: 'Numéro WhatsApp Twilio (+…)' });
const TWILIO_WHATSAPP_CONTENT_SID = defineString('TWILIO_WHATSAPP_CONTENT_SID', { default: '', description: 'Modèle WhatsApp approuvé (HX…), variables {{1}} parent, {{2}} élève, {{3}} montant, {{4}} école' });

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

    const config = {
      accountSid: TWILIO_ACCOUNT_SID.value(),
      authToken: TWILIO_AUTH_TOKEN.value(),
      smsFrom: TWILIO_SMS_FROM.value(),
      whatsappFrom: TWILIO_WHATSAPP_FROM.value(),
      whatsappContentSid: TWILIO_WHATSAPP_CONTENT_SID.value(),
    };

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
