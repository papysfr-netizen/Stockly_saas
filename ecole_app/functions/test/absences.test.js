const test = require('node:test');
const assert = require('node:assert');
const { doitAlerter, messageAbsence, variablesAbsence } = require('../absences');

test('quand alerter le parent', () => {
  assert.equal(doitAlerter(null, { statut: 'absent' }), true); // nouvelle absence
  assert.equal(doitAlerter({ statut: 'retard' }, { statut: 'absent' }), true); // retard devenu absence
  assert.equal(doitAlerter(null, { statut: 'retard' }), false); // simple retard
  assert.equal(doitAlerter({ statut: 'absent' }, { statut: 'absent', justifiee: true }), false); // justification
  assert.equal(doitAlerter({ statut: 'absent' }, { statut: 'absent', alerte: { statut: 'envoye' } }), false); // trace : pas de boucle
  assert.equal(doitAlerter({ statut: 'absent' }, null), false); // remis présent
});

test("message d'absence", () => {
  const infos = { parent: 'M. Kabeya', eleve: 'KABEYA Jean', classe: '5e année A', date: '2026-11-30', ecole: 'CS La Référence' };
  assert.equal(messageAbsence(infos),
    "Bonjour M. Kabeya, KABEYA Jean (5e année A) est noté(e) absent(e) le lundi 30/11. Merci de contacter l'école ou de justifier l'absence. — CS La Référence");
  assert.match(messageAbsence({ ...infos, parent: '' }), /^Bonjour cher parent,/);
  assert.deepEqual(variablesAbsence(infos), { 1: 'M. Kabeya', 2: 'KABEYA Jean', 3: '5e année A', 4: 'lundi 30/11', 5: 'CS La Référence' });
});
