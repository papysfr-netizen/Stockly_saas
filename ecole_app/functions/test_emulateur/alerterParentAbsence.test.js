// Alerte d'absence au parent, de bout en bout contre l'émulateur Firestore, Twilio simulé.
const test = require('node:test');
const assert = require('node:assert');

process.env.GCLOUD_PROJECT = 'demo-ecole';
Object.assign(process.env, {
  TWILIO_ACCOUNT_SID: 'ACtest', TWILIO_AUTH_TOKEN: 'tok', TWILIO_SMS_FROM: '+15550001', TWILIO_WHATSAPP_FROM: '+15550002',
  TWILIO_WHATSAPP_CONTENT_SID: '', TWILIO_WHATSAPP_REMPLACEMENT_SID: '', TWILIO_WHATSAPP_ANNULATION_SID: '', TWILIO_WHATSAPP_ABSENCE_SID: '',
});
const envois = [];
global.fetch = async (url, opts) => {
  const b = new URLSearchParams(opts.body);
  envois.push({ to: b.get('To'), text: b.get('Body') });
  return { ok: true, status: 201, json: async () => ({ sid: 'SM' + envois.length }) };
};

const fft = require('firebase-functions-test')({ projectId: 'demo-ecole' });
const { alerterParentAbsence } = require('../index.js');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');
const db = getFirestore();
const wrapped = fft.wrap(alerterParentAbsence);
const E = 'ecoleAbs';

async function ecrire(id, avant, apres) {
  const chemin = `ecoles/${E}/absences/${id}`;
  if (apres) await db.doc(chemin).set(apres); else await db.doc(chemin).delete();
  const snap = (d) => (d ? fft.firestore.makeDocumentSnapshot(d, chemin) : fft.firestore.makeDocumentSnapshot({}, chemin, { exists: false }));
  await wrapped({ data: fft.makeChange(snap(avant), snap(apres)), params: { ecoleId: E, id } });
}
const absence = (eleveId, statut) => ({ eleveId, classeId: 'p5A', statut, date: Timestamp.fromDate(new Date('2026-11-30T00:00:00Z')) });

test("alertes d'absence", async (t) => {
  await db.recursiveDelete(db.doc(`ecoles/${E}`));
  await db.doc(`ecoles/${E}`).set({ nom: 'CS La Référence', indicatif: '+243', alerteAbsence: 'sms' });
  await db.doc(`ecoles/${E}/classes/p5A`).set({ nom: '5e année A' });
  await db.doc(`ecoles/${E}/eleves/jean`).set({ nom: 'KABEYA', prenom: 'Jean', parentNom: 'M. Kabeya', parentTelephone: '0812345678' });
  await db.doc(`ecoles/${E}/eleves/ruth`).set({ nom: 'NZUZI', prenom: 'Ruth', parentTelephone: '' });

  await t.test('absence : SMS au parent, résultat écrit sur la fiche', async () => {
    await ecrire('a1', null, absence('jean', 'absent'));
    assert.equal(envois.length, 1);
    assert.equal(envois[0].to, '+243812345678');
    assert.match(envois[0].text, /^Bonjour M\. Kabeya, KABEYA Jean \(5e année A\) est noté\(e\) absent\(e\) le lundi 30\/11\./);
    assert.equal((await db.doc(`ecoles/${E}/absences/a1`).get()).data().alerte.statut, 'envoye');
  });

  await t.test('justification ou trace : pas de nouvel envoi', async () => {
    await ecrire('a1', absence('jean', 'absent'), { ...absence('jean', 'absent'), justifiee: true, motif: 'Maladie' });
    assert.equal(envois.length, 1);
  });

  await t.test('retard : pas d\'alerte', async () => {
    await ecrire('a2', null, absence('jean', 'retard'));
    assert.equal(envois.length, 1);
  });

  await t.test('parent sans numéro : tracé', async () => {
    await ecrire('a3', null, absence('ruth', 'absent'));
    assert.equal(envois.length, 1);
    assert.equal((await db.doc(`ecoles/${E}/absences/a3`).get()).data().alerte.statut, 'sans_telephone');
  });

  await t.test('réglage désactivé : rien', async () => {
    await db.doc(`ecoles/${E}`).update({ alerteAbsence: 'aucune' });
    await ecrire('a4', null, absence('jean', 'absent'));
    assert.equal(envois.length, 1);
  });
});
