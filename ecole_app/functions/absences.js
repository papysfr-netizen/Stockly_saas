// Logique des alertes d'absence aux parents, sans dépendance à Firebase (testable).
const { dateLisible } = require('./remplacements');

/** Faut-il prévenir le parent après cette écriture d'une fiche d'absence ? */
function doitAlerter(avant, apres) {
  if (!apres || apres.statut !== 'absent') return false;
  // Seulement quand l'élève devient absent : pas à chaque mise à jour (justification, trace d'envoi…).
  return !avant || avant.statut !== 'absent';
}

function messageAbsence({ parent, eleve, classe, date, ecole }) {
  const p = String(parent || '').trim() || 'cher parent';
  return `Bonjour ${p}, ${eleve} (${classe}) est noté(e) absent(e) le ${dateLisible(date)}. ` +
    `Merci de contacter l'école ou de justifier l'absence. — ${ecole}`;
}

/** Variables du modèle WhatsApp : {{1}} parent, {{2}} élève, {{3}} classe, {{4}} date, {{5}} école. */
function variablesAbsence({ parent, eleve, classe, date, ecole }) {
  return { 1: String(parent || '').trim() || 'cher parent', 2: eleve, 3: classe, 4: dateLisible(date), 5: ecole };
}

module.exports = { doitAlerter, messageAbsence, variablesAbsence };
