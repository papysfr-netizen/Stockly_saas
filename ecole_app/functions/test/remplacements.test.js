const test = require('node:test');
const assert = require('node:assert');
const { notificationsAEnvoyer, dateLisible, messageRemplacement, variablesRemplacement } = require('../remplacements');

const base = { statut: 'aPourvoir', remplacantId: null };
const remplace = (id) => ({ statut: 'remplace', remplacantId: id });

test('quand prévenir', () => {
  assert.deepEqual(notificationsAEnvoyer(base, remplace('mbu')), [{ enseignantId: 'mbu', type: 'affectation' }]);
  assert.deepEqual(notificationsAEnvoyer(remplace('mbu'), remplace('tsh')), [
    { enseignantId: 'mbu', type: 'annulation' },
    { enseignantId: 'tsh', type: 'affectation' },
  ]);
  assert.deepEqual(notificationsAEnvoyer(remplace('mbu'), { statut: 'etude', remplacantId: null }), [{ enseignantId: 'mbu', type: 'annulation' }]);
  assert.deepEqual(notificationsAEnvoyer(remplace('mbu'), null), [{ enseignantId: 'mbu', type: 'annulation' }]); // absence supprimée
  // Écriture qui ne change pas le remplaçant (ex. : trace de la notification) → rien, donc pas de boucle.
  assert.deepEqual(notificationsAEnvoyer(remplace('mbu'), { ...remplace('mbu'), notification: { statut: 'envoye' } }), []);
  assert.deepEqual(notificationsAEnvoyer(null, base), []);
  assert.deepEqual(notificationsAEnvoyer(base, { statut: 'annule' }), []);
});

test('date lisible', () => {
  assert.equal(dateLisible('2026-11-30'), 'lundi 30/11');
  assert.equal(dateLisible('2026-12-05'), 'samedi 05/12');
});

test('messages', () => {
  const infos = { remplacant: 'Paul MBUYI', absent: 'Marie KASONGO', date: '2026-11-30', plage: '07:30-08:20', classe: '5e A', branche: 'Français', ecole: 'CS Les Bâtisseurs' };
  assert.equal(messageRemplacement({ type: 'affectation', ...infos }),
    'Bonjour Paul MBUYI, vous êtes désigné(e) pour remplacer Marie KASONGO le lundi 30/11 de 07:30 à 08:20 en 5e A (Français). Merci. — CS Les Bâtisseurs');
  assert.match(messageRemplacement({ type: 'annulation', ...infos }), /est annulé/);
  assert.deepEqual(variablesRemplacement(infos), { 1: 'Paul MBUYI', 2: 'lundi 30/11', 3: '07:30 à 08:20', 4: '5e A', 5: 'Français', 6: 'CS Les Bâtisseurs' });
});
