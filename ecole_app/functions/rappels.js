// Logique des rappels d'impayés, sans dépendance à Firebase (testable).
// Le calcul du reste à payer et le modèle de message suivent
// lib/services/calculs.dart et lib/services/rappels.dart.

const MODELE_PAR_DEFAUT =
  "Bonjour {parent}, sauf erreur de notre part, il reste {montant} à régler pour la scolarité de " +
  '{eleve} ({classe}). Merci de passer au secrétariat. — {ecole}';

/** Pays où le 0 initial fait partie du numéro national. */
const GARDE_0 = new Set(['225', '39']);

function normaliserTelephone(brut, indicatif = '+225') {
  let t = String(brut || '').trim().replace(/[\s.\-()/]/g, '');
  if (!t) return null;
  if (t.startsWith('00')) t = '+' + t.slice(2);
  if (!t.startsWith('+')) {
    const code = String(indicatif).replace(/[^0-9]/g, '');
    if (t.startsWith('0') && !GARDE_0.has(code)) t = t.slice(1);
    t = `+${code}${t}`;
  }
  return /^\+[1-9][0-9]{7,14}$/.test(t) ? t : null;
}

function formatMontant(montant, devise = 'FCFA') {
  // Espace simple comme séparateur : les espaces insécables passent mal en SMS (GSM-7).
  const n = Math.round(montant).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ' ');
  return `${n} ${devise}`;
}

function messageRappel({ modele, parent, eleve, classe, montant, devise, ecole }) {
  const valeurs = {
    parent: String(parent || '').trim() || 'cher parent',
    eleve,
    classe,
    montant: formatMontant(montant, devise),
    ecole,
  };
  const m = String(modele || '').trim() ? modele : MODELE_PAR_DEFAUT;
  return m.replace(/\{(\w+)\}/g, (tout, cle) => (cle in valeurs ? valeurs[cle] : tout));
}

/**
 * Liste des élèves à relancer.
 * @returns {{ aRelancer: object[], sansTelephone: object[], recents: object[] }}
 */
function calculerRelances({ eleves, classes, paiements, derniersRappels = {}, ecole, eleveIds, maintenant = new Date(), delaiHeures = 24 }) {
  const classeParId = Object.fromEntries(classes.map((c) => [c.id, c]));
  const paye = {};
  for (const p of paiements) paye[p.eleveId] = (paye[p.eleveId] || 0) + Number(p.montant || 0);
  const filtre = eleveIds && eleveIds.length ? new Set(eleveIds) : null;

  const res = { aRelancer: [], sansTelephone: [], recents: [] };
  for (const e of eleves) {
    if (e.actif === false || (filtre && !filtre.has(e.id))) continue;
    const classe = classeParId[e.classeId];
    const reste = Math.max(0, Number(classe?.fraisScolarite || 0) - (paye[e.id] || 0));
    if (reste <= 0) continue;
    const telephone = normaliserTelephone(e.parentTelephone, ecole.indicatif || '+225');
    const ligne = { eleveId: e.id, telephone, reste };
    if (!telephone) { res.sansTelephone.push(ligne); continue; }
    const dernier = derniersRappels[e.id];
    if (dernier && maintenant - dernier < delaiHeures * 3600 * 1000) { res.recents.push(ligne); continue; }
    ligne.message = messageRappel({
      modele: ecole.modeleRappel,
      parent: e.parentNom,
      eleve: `${e.prenom || ''} ${e.nom || ''}`.trim(),
      classe: classe?.nom || '',
      montant: reste,
      devise: ecole.devise || 'FCFA',
      ecole: ecole.nom || '',
    });
    ligne.variables = {
      1: String(e.parentNom || '').trim() || 'cher parent',
      2: `${e.prenom || ''} ${e.nom || ''}`.trim(),
      3: formatMontant(reste, ecole.devise || 'FCFA'),
      4: ecole.nom || '',
    };
    res.aRelancer.push(ligne);
  }
  return res;
}

/**
 * Envoie un message via l'API REST de Twilio.
 * WhatsApp : hors fenêtre de 24 h, Meta impose un modèle approuvé ([contentSid]).
 */
async function envoyerTwilio({ canal, to, body, variables, config, fetchImpl = fetch }) {
  const { accountSid, authToken, smsFrom, whatsappFrom, whatsappContentSid } = config;
  const form = new URLSearchParams();
  if (canal === 'whatsapp') {
    if (!whatsappFrom) throw new Error('TWILIO_WHATSAPP_FROM non configuré');
    form.set('From', `whatsapp:${whatsappFrom}`);
    form.set('To', `whatsapp:${to}`);
    if (whatsappContentSid) {
      form.set('ContentSid', whatsappContentSid);
      form.set('ContentVariables', JSON.stringify(variables || {}));
    } else {
      form.set('Body', body);
    }
  } else {
    if (!smsFrom) throw new Error('TWILIO_SMS_FROM non configuré');
    // Un identifiant commençant par "MG" est un Messaging Service.
    form.set(smsFrom.startsWith('MG') ? 'MessagingServiceSid' : 'From', smsFrom);
    form.set('To', to);
    form.set('Body', body);
  }
  const r = await fetchImpl(`https://api.twilio.com/2010-04-01/Accounts/${accountSid}/Messages.json`, {
    method: 'POST',
    headers: {
      Authorization: 'Basic ' + Buffer.from(`${accountSid}:${authToken}`).toString('base64'),
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: form.toString(),
  });
  const json = await r.json().catch(() => ({}));
  if (!r.ok) throw new Error(json.message || `Twilio HTTP ${r.status}`);
  return json.sid;
}

module.exports = { MODELE_PAR_DEFAUT, normaliserTelephone, formatMontant, messageRappel, calculerRelances, envoyerTwilio };
