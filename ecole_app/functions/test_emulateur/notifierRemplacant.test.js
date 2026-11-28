// Test de bout en bout du déclencheur, contre l'émulateur Firestore, Twilio simulé.
const test = require('node:test');
const assert = require('node:assert');

process.env.GCLOUD_PROJECT = 'demo-ecole';
Object.assign(process.env, {
  TWILIO_ACCOUNT_SID: 'ACtest', TWILIO_AUTH_TOKEN: 'tok', TWILIO_SMS_FROM: '+15550001', TWILIO_WHATSAPP_FROM: '+15550002',
  TWILIO_WHATSAPP_CONTENT_SID: '', TWILIO_WHATSAPP_REMPLACEMENT_SID: 'HXremp', TWILIO_WHATSAPP_ANNULATION_SID: '',
});
const envois = [];
global.fetch = async (url, opts) => {
  const b = new URLSearchParams(opts.body);
  envois.push({ to: b.get('To'), text: b.get('Body'), contentSid: b.get('ContentSid'), vars: b.get('ContentVariables') });
  return { ok: true, status: 201, json: async () => ({ sid: 'SM' + envois.length }) };
};

const fft = require('firebase-functions-test')({ projectId: 'demo-ecole' });
const { notifierRemplacant } = require('../index.js');
const { getFirestore } = require('firebase-admin/firestore');
const db = getFirestore();
const wrapped = fft.wrap(notifierRemplacant);
const E = 'ecoleNotif';
const chemin = `ecoles/${E}/remplacements/2026-11-30_k1`;

const base = {
  absenceId: 'abs', date: '2026-11-30', creneauId: 'k1', classeId: 'c5A', jour: 1, plage: '07:30-08:20', matiereId: 'fr5',
  enseignantAbsentId: 'kas', enseignantAbsentNom: 'Marie KASONGO', statut: 'aPourvoir', remplacantId: null,
};
const snap = (data) => (data ? fft.firestore.makeDocumentSnapshot(data, chemin) : fft.firestore.makeDocumentSnapshot({}, chemin, { exists: false }));
async function ecrire(avant, apres) {
  if (apres) await db.doc(chemin).set(apres); else await db.doc(chemin).delete();
  await wrapped({ data: fft.makeChange(snap(avant), snap(apres)), params: { ecoleId: E, id: '2026-11-30_k1' } });
}
const notifs = async () => (await db.collection(`ecoles/${E}/notifications`).get()).docs.map((d) => d.data());

test('notifications de remplacement', async (t) => {
  await db.recursiveDelete(db.doc(`ecoles/${E}`));
  await db.doc(`ecoles/${E}`).set({ nom: 'CS Les Bâtisseurs', indicatif: '+243', notificationRemplacement: 'sms' });
  await db.doc(`ecoles/${E}/classes/c5A`).set({ nom: '5e A' });
  await db.doc(`ecoles/${E}/matieres/fr5`).set({ nom: 'Français' });
  await db.doc(`ecoles/${E}/enseignants/mbu`).set({ prenom: 'Paul', nom: 'MBUYI', telephone: '081 234 5678' });
  await db.doc(`ecoles/${E}/enseignants/tsh`).set({ prenom: 'Rose', nom: 'TSHIBANDA', telephone: '0991234567' });
  await db.doc(`ecoles/${E}/enseignants/ilu`).set({ prenom: 'Jean', nom: 'ILUNGA', telephone: '' });

  await t.test('affectation : SMS au remplaçant et statut écrit sur le remplacement', async () => {
    await ecrire(base, { ...base, statut: 'remplace', remplacantId: 'mbu', remplacantNom: 'Paul MBUYI' });
    assert.equal(envois.length, 1);
    assert.equal(envois[0].to, '+243812345678');
    assert.equal(envois[0].text, 'Bonjour Paul MBUYI, vous êtes désigné(e) pour remplacer Marie KASONGO le lundi 30/11 de 07:30 à 08:20 en 5e A (Français). Merci. — CS Les Bâtisseurs');
    const r = (await db.doc(chemin).get()).data();
    assert.equal(r.notification.statut, 'envoye');
    assert.equal(r.notification.enseignantId, 'mbu');
  });

  await t.test("l'écriture du statut ne redéclenche pas d'envoi", async () => {
    const avant = { ...base, statut: 'remplace', remplacantId: 'mbu' };
    await ecrire(avant, { ...avant, notification: { statut: 'envoye' } });
    assert.equal(envois.length, 1);
  });

  await t.test('changement de remplaçant : annulation à l\'ancien, affectation au nouveau', async () => {
    envois.length = 0;
    await ecrire({ ...base, statut: 'remplace', remplacantId: 'mbu' }, { ...base, statut: 'remplace', remplacantId: 'tsh' });
    assert.deepEqual(envois.map((e) => e.to), ['+243812345678', '+243991234567']);
    assert.match(envois[0].text, /est annulé/);
    assert.match(envois[1].text, /Bonjour Rose TSHIBANDA/);
  });

  await t.test('remplaçant sans téléphone : tracé, rien envoyé', async () => {
    envois.length = 0;
    await ecrire({ ...base, statut: 'remplace', remplacantId: 'tsh' }, { ...base, statut: 'remplace', remplacantId: 'ilu' });
    assert.deepEqual(envois.map((e) => e.to), ['+243991234567']); // seulement l'annulation à Rose
    assert.equal((await db.doc(chemin).get()).data().notification.statut, 'sans_telephone');
  });

  await t.test('absence supprimée : annulation au remplaçant', async () => {
    await ecrire(null, { ...base, statut: 'remplace', remplacantId: 'mbu' });
    envois.length = 0;
    await ecrire({ ...base, statut: 'remplace', remplacantId: 'mbu' }, null);
    assert.equal(envois.length, 1);
    assert.match(envois[0].text, /est annulé/);
  });

  await t.test('WhatsApp avec modèle approuvé', async () => {
    await db.doc(`ecoles/${E}`).update({ notificationRemplacement: 'whatsapp' });
    envois.length = 0;
    await ecrire(base, { ...base, statut: 'remplace', remplacantId: 'mbu' });
    assert.equal(envois[0].to, 'whatsapp:+243812345678');
    assert.equal(envois[0].contentSid, 'HXremp');
    assert.equal(JSON.parse(envois[0].vars)['4'], '5e A');
  });

  await t.test('réglage désactivé : rien', async () => {
    await db.doc(`ecoles/${E}`).update({ notificationRemplacement: 'aucune' });
    envois.length = 0;
    await ecrire(base, { ...base, statut: 'remplace', remplacantId: 'tsh' });
    assert.equal(envois.length, 0);
  });

  await t.test('chaque envoi est tracé', async () => {
    const n = await notifs();
    assert.ok(n.length >= 7);
    assert.ok(n.some((x) => x.type === 'annulation' && x.statut === 'envoye'));
    assert.ok(n.some((x) => x.statut === 'sans_telephone'));
  });
});
