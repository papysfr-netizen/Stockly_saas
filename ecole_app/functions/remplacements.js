// Logique des notifications de remplacement, sans dépendance à Firebase (testable).

/**
 * Notifications à envoyer après l'écriture d'un remplacement.
 * - un remplaçant vient d'être désigné → « affectation » pour lui ;
 * - un remplaçant perd le cours (changement, étude, annulation, suppression) → « annulation » pour lui.
 */
function notificationsAEnvoyer(avant, apres) {
  const ancien = avant && avant.statut === 'remplace' ? avant.remplacantId : null;
  const nouveau = apres && apres.statut === 'remplace' ? apres.remplacantId : null;
  if (ancien === nouveau) return [];
  const r = [];
  if (ancien) r.push({ enseignantId: ancien, type: 'annulation' });
  if (nouveau) r.push({ enseignantId: nouveau, type: 'affectation' });
  return r;
}

const JOURS = ['dimanche', 'lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi'];

/** "2026-11-30" → "lundi 30/11" */
function dateLisible(iso) {
  const [a, m, j] = iso.split('-').map(Number);
  const d = new Date(Date.UTC(a, m - 1, j));
  return `${JOURS[d.getUTCDay()]} ${String(j).padStart(2, '0')}/${String(m).padStart(2, '0')}`;
}

function messageRemplacement({ type, remplacant, absent, date, plage, classe, branche, ecole }) {
  const quand = `le ${dateLisible(date)} de ${plage.replace('-', ' à ')}`;
  return type === 'affectation'
    ? `Bonjour ${remplacant}, vous êtes désigné(e) pour remplacer ${absent} ${quand} en ${classe} (${branche}). Merci. — ${ecole}`
    : `Bonjour ${remplacant}, le remplacement prévu ${quand} en ${classe} (${branche}) est annulé. Merci. — ${ecole}`;
}

/** Variables des modèles WhatsApp : {{1}} enseignant, {{2}} date, {{3}} heure, {{4}} classe, {{5}} branche, {{6}} école. */
function variablesRemplacement({ remplacant, date, plage, classe, branche, ecole }) {
  return { 1: remplacant, 2: dateLisible(date), 3: plage.replace('-', ' à '), 4: classe, 5: branche, 6: ecole };
}

module.exports = { notificationsAEnvoyer, dateLisible, messageRemplacement, variablesRemplacement };
