const test = require('node:test');
const assert = require('node:assert');
const { normaliserTelephone, messageRappel, calculerRelances, envoyerTwilio, formatMontant } = require('../rappels');

test('normalisation des numéros', () => {
  assert.equal(normaliserTelephone('07 07 12 34 56', '+225'), '+2250707123456');
  assert.equal(normaliserTelephone('77 123 45 67', '+221'), '+221771234567');
  assert.equal(normaliserTelephone('06 12 34 56 78', '+33'), '+33612345678');
  assert.equal(normaliserTelephone('00225 0707123456'), '+2250707123456');
  assert.equal(normaliserTelephone('+229 97 00 00 00'), '+22997000000');
  assert.equal(normaliserTelephone('abc'), null);
  assert.equal(normaliserTelephone(''), null);
});

test('message avec variables', () => {
  const m = messageRappel({ modele: 'Bonjour {parent}, reste {montant} pour {eleve} ({classe}) — {ecole} {inconnu}',
    parent: '', eleve: 'Awa KONE', classe: 'CM2', montant: 125000, devise: 'FCFA', ecole: 'Les Lauriers' });
  assert.equal(m, 'Bonjour cher parent, reste 125 000 FCFA pour Awa KONE (CM2) — Les Lauriers {inconnu}');
  assert.equal(formatMontant(1500000), '1 500 000 FCFA');
});

test('calcul des relances', () => {
  const now = new Date('2026-11-27T10:00:00Z');
  const r = calculerRelances({
    ecole: { nom: 'E', indicatif: '+225' },
    classes: [{ id: 'c', nom: 'CM2', fraisScolarite: 100000 }],
    eleves: [
      { id: 'a', nom: 'A', prenom: 'x', classeId: 'c', parentTelephone: '0707123456' },
      { id: 'b', nom: 'B', classeId: 'c', parentTelephone: '0707000000' }, // soldé
      { id: 'c', nom: 'C', classeId: 'c', parentTelephone: '' },          // sans téléphone
      { id: 'd', nom: 'D', classeId: 'c', parentTelephone: '0101010101' }, // relancé il y a 2 h
      { id: 'e', nom: 'E', classeId: 'c', parentTelephone: '0505050505', actif: false },
    ],
    paiements: [{ eleveId: 'a', montant: 40000 }, { eleveId: 'b', montant: 100000 }],
    derniersRappels: { d: new Date(now - 2 * 3600 * 1000) },
    maintenant: now,
  });
  assert.deepEqual(r.aRelancer.map((l) => [l.eleveId, l.reste, l.telephone]), [['a', 60000, '+2250707123456']]);
  assert.match(r.aRelancer[0].message, /60 000 FCFA/);
  assert.deepEqual(r.sansTelephone.map((l) => l.eleveId), ['c']);
  assert.deepEqual(r.recents.map((l) => l.eleveId), ['d']);
});

test('filtre par élèves', () => {
  const r = calculerRelances({
    ecole: {}, classes: [{ id: 'c', fraisScolarite: 10 }], paiements: [],
    eleves: [{ id: 'a', classeId: 'c', parentTelephone: '0707123456' }, { id: 'b', classeId: 'c', parentTelephone: '0707123457' }],
    eleveIds: ['b'],
  });
  assert.deepEqual(r.aRelancer.map((l) => l.eleveId), ['b']);
});

function fauxFetch(capture, ok = true) {
  return async (url, opts) => {
    capture.url = url; capture.body = new URLSearchParams(opts.body); capture.auth = opts.headers.Authorization;
    return { ok, status: ok ? 201 : 400, json: async () => (ok ? { sid: 'SM123' } : { message: 'Numéro invalide' }) };
  };
}
const config = { accountSid: 'AC1', authToken: 'tok', smsFrom: '+15550001', whatsappFrom: '+15550002', whatsappContentSid: '' };

test('envoi SMS Twilio', async () => {
  const c = {};
  const sid = await envoyerTwilio({ canal: 'sms', to: '+2250707123456', body: 'Bonjour', config, fetchImpl: fauxFetch(c) });
  assert.equal(sid, 'SM123');
  assert.equal(c.url, 'https://api.twilio.com/2010-04-01/Accounts/AC1/Messages.json');
  assert.equal(c.body.get('From'), '+15550001');
  assert.equal(c.body.get('To'), '+2250707123456');
  assert.equal(c.auth, 'Basic ' + Buffer.from('AC1:tok').toString('base64'));
});

test('envoi WhatsApp avec et sans modèle', async () => {
  const c = {};
  await envoyerTwilio({ canal: 'whatsapp', to: '+2250707123456', body: 'Bonjour', config, fetchImpl: fauxFetch(c) });
  assert.equal(c.body.get('From'), 'whatsapp:+15550002');
  assert.equal(c.body.get('To'), 'whatsapp:+2250707123456');
  assert.equal(c.body.get('Body'), 'Bonjour');
  await envoyerTwilio({ canal: 'whatsapp', to: '+2250707123456', body: 'x', variables: { 1: 'M. Kone' },
    config: { ...config, whatsappContentSid: 'HX9' }, fetchImpl: fauxFetch(c) });
  assert.equal(c.body.get('ContentSid'), 'HX9');
  assert.equal(c.body.get('ContentVariables'), '{"1":"M. Kone"}');
  assert.equal(c.body.get('Body'), null);
});

test('erreur Twilio remontée', async () => {
  await assert.rejects(envoyerTwilio({ canal: 'sms', to: '+1', body: 'x', config, fetchImpl: fauxFetch({}, false) }), /Numéro invalide/);
});
