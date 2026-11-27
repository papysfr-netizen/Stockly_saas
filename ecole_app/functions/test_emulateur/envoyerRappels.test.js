// Test de bout en bout de la Cloud Function contre l'émulateur Firestore,
// avec l'API Twilio simulée. Lancer : npm run test:emulateur
const test = require('node:test');
const assert = require('node:assert');

process.env.GCLOUD_PROJECT = 'demo-ecole';
Object.assign(process.env, {
  TWILIO_ACCOUNT_SID: 'ACtest', TWILIO_AUTH_TOKEN: 'tok',
  TWILIO_SMS_FROM: '+15550001', TWILIO_WHATSAPP_FROM: '+15550002', TWILIO_WHATSAPP_CONTENT_SID: '',
});
const envois = [];
global.fetch = async (url, opts) => {
  const body = new URLSearchParams(opts.body);
  envois.push({ url, to: body.get('To'), from: body.get('From'), text: body.get('Body') });
  if (body.get('To').endsWith('0102030405')) return { ok: false, status: 400, json: async () => ({ message: 'Numéro non joignable' }) };
  return { ok: true, status: 201, json: async () => ({ sid: 'SM' + envois.length }) };
};

const { envoyerRappels } = require('../index.js');
const { getFirestore } = require('firebase-admin/firestore');
const db = getFirestore();
const E = 'ecoleTest';

test('envoi des rappels', async (t) => {
  await db.recursiveDelete(db.doc(`ecoles/${E}`));
  await db.doc(`ecoles/${E}`).set({ nom: 'Les Lauriers', devise: 'FCFA', indicatif: '+225' });
  await db.doc('users/secr').set({ role: 'secretariat', ecoleId: E, nom: 'Mme Secr' });
  await db.doc('users/prof').set({ role: 'enseignant', ecoleId: E, nom: 'Prof' });
  await db.doc(`ecoles/${E}/classes/c`).set({ nom: 'CM2', fraisScolarite: 150000 });
  const eleves = {
    a: { nom: 'KONE', prenom: 'Awa', parentNom: 'M. Kone', parentTelephone: '07 07 12 34 56' },
    b: { nom: 'DIALLO', prenom: 'Ali', parentTelephone: '0505050505' },      // soldé
    c: { nom: 'TRAORE', prenom: 'Sia', parentTelephone: '' },                // sans numéro
    d: { nom: 'YAO', prenom: 'Koffi', parentTelephone: '0102030405' },       // Twilio refuse
  };
  for (const [id, e] of Object.entries(eleves)) await db.doc(`ecoles/${E}/eleves/${id}`).set({ ...e, classeId: 'c', actif: true });
  await db.collection(`ecoles/${E}/paiements`).add({ eleveId: 'a', montant: 50000 });
  await db.collection(`ecoles/${E}/paiements`).add({ eleveId: 'b', montant: 150000 });

  await t.test('refusé à un enseignant', async () => {
    await assert.rejects(envoyerRappels.run({ auth: { uid: 'prof' }, data: { ecoleId: E, canal: 'sms' } }), /Réservé/);
  });
  await t.test("refusé pour une autre école", async () => {
    await assert.rejects(envoyerRappels.run({ auth: { uid: 'secr' }, data: { ecoleId: 'autre', canal: 'sms' } }), /Réservé/);
  });

  await t.test('premier envoi SMS', async () => {
    const r = await envoyerRappels.run({ auth: { uid: 'secr' }, data: { ecoleId: E, canal: 'sms' } });
    assert.deepEqual({ ...r, erreurs: undefined }, { envoyes: 1, echecs: 1, sansTelephone: 1, recents: 0, erreurs: undefined });
    assert.deepEqual(r.erreurs, ['Numéro non joignable']);
    const a = envois.find((x) => x.to === '+2250707123456');
    assert.equal(a.from, '+15550001');
    assert.equal(a.text, 'Bonjour M. Kone, sauf erreur de notre part, il reste 100 000 FCFA à régler pour la scolarité de Awa KONE (CM2). Merci de passer au secrétariat. — Les Lauriers');
    const traces = (await db.collection(`ecoles/${E}/rappels`).get()).docs.map((d) => d.data());
    assert.deepEqual(traces.map((x) => `${x.eleveId}:${x.statut}`).sort(), ['a:envoye', 'd:echec']);
  });

  await t.test("pas de double relance dans les 24 h, mais réessai après un échec", async () => {
    envois.length = 0;
    const r = await envoyerRappels.run({ auth: { uid: 'secr' }, data: { ecoleId: E, canal: 'sms' } });
    assert.equal(r.recents, 1);
    assert.deepEqual(envois.map((x) => x.to), ['+2250102030405']);
  });

  await t.test('WhatsApp est un canal distinct, filtre par élève', async () => {
    envois.length = 0;
    const r = await envoyerRappels.run({ auth: { uid: 'secr' }, data: { ecoleId: E, canal: 'whatsapp', eleveIds: ['a'] } });
    assert.equal(r.envoyes, 1);
    assert.deepEqual(envois.map((x) => [x.to, x.from]), [['whatsapp:+2250707123456', 'whatsapp:+15550002']]);
  });
});
