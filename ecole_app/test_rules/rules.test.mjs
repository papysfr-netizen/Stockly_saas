import { initializeTestEnvironment, assertSucceeds, assertFails } from '@firebase/rules-unit-testing';
import { doc, setDoc, getDoc, getDocs, collection, query, where, writeBatch, deleteDoc, updateDoc, runTransaction } from 'firebase/firestore';
import fs from 'fs';

const env = await initializeTestEnvironment({
  projectId: 'demo-ecole',
  firestore: { rules: fs.readFileSync('../firestore.rules', 'utf8'), host: '127.0.0.1', port: 8080 },
});
const E = 'ecole1';
await env.withSecurityRulesDisabled(async (c) => {
  const db = c.firestore();
  await setDoc(doc(db, 'ecoles', E), { nom: 'Test', proprietaire: 'admin' });
  await setDoc(doc(db, 'users/admin'), { email: 'admin@x.fr', role: 'admin', ecoleId: E, classeIds: [], eleveIds: [] });
  await setDoc(doc(db, 'users/secr'), { email: 'secr@x.fr', role: 'secretariat', ecoleId: E, classeIds: [], eleveIds: [] });
  await setDoc(doc(db, 'users/prof'), { email: 'prof@x.fr', role: 'enseignant', ecoleId: E, classeIds: ['c1'], eleveIds: [] });
  await setDoc(doc(db, 'users/parent'), { email: 'parent@x.fr', role: 'parent', ecoleId: E, classeIds: [], eleveIds: ['e1'] });
  for (const [id, c] of [['e1', 'c1'], ['e2', 'c2']]) {
    await setDoc(doc(db, `ecoles/${E}/eleves/${id}`), { nom: id, classeId: c, actif: true });
    await setDoc(doc(db, `ecoles/${E}/notes/${id}_m_T1`), { eleveId: id, classeId: c, matiereId: 'm', trimestre: 1, valeur: 12, sur: 20 });
    await setDoc(doc(db, `ecoles/${E}/paiements/p${id}`), { eleveId: id, classeId: c, montant: 1000 });
    await setDoc(doc(db, `ecoles/${E}/absences/a${id}`), { eleveId: id, classeId: c, statut: 'absent' });
  }
  await setDoc(doc(db, 'invitations/nouveau@x.fr'), { email: 'nouveau@x.fr', role: 'parent', ecoleId: E, eleveIds: ['e2'] });
});

const as = (uid, email) => env.authenticatedContext(uid, { email }).firestore();
const admin = as('admin', 'admin@x.fr'), secr = as('secr', 'secr@x.fr'), prof = as('prof', 'prof@x.fr'), parent = as('parent', 'parent@x.fr');
let ok = 0, ko = 0;
async function t(nom, p) { try { await p; ok++; console.log('✓', nom); } catch (e) { ko++; console.log('✗', nom, '-', e.message.split('\n')[0]); } }
const q = (db, col, f, v) => getDocs(query(collection(db, `ecoles/${E}/${col}`), where(f, '==', v)));

// Inscription d'un fondateur
const fondateur = as('fond', 'fond@x.fr');
await t('fondateur crée son école', assertSucceeds((() => { const b = writeBatch(fondateur);
  b.set(doc(fondateur, 'ecoles/ecole2'), { nom: 'B', proprietaire: 'fond' });
  b.set(doc(fondateur, 'users/fond'), { email: 'fond@x.fr', role: 'admin', ecoleId: 'ecole2', classeIds: [], eleveIds: [] });
  return b.commit(); })()));
const pirate = as('pirate', 'pirate@x.fr');
await t("un inconnu ne peut pas se déclarer admin d'une école", assertFails(setDoc(doc(pirate, 'users/pirate'), { email: 'pirate@x.fr', role: 'admin', ecoleId: E })));
// Inscription par invitation
const nouveau = as('nouveau', 'nouveau@x.fr');
await t('invité lit son invitation', assertSucceeds(getDoc(doc(nouveau, 'invitations/nouveau@x.fr'))));
await t("invité crée son profil et consomme l'invitation", assertSucceeds((() => { const b = writeBatch(nouveau);
  b.set(doc(nouveau, 'users/nouveau'), { email: 'nouveau@x.fr', role: 'parent', ecoleId: E, classeIds: [], eleveIds: ['e2'] });
  b.delete(doc(nouveau, 'invitations/nouveau@x.fr'));
  return b.commit(); })()));
await t("l'invité ne peut pas s'attribuer un autre rôle", assertFails(setDoc(doc(as('x', 'x@x.fr'), 'users/x'), { email: 'x@x.fr', role: 'admin', ecoleId: E })));

// Parents
await t('parent : notes de son enfant (requête)', assertSucceeds(q(parent, 'notes', 'eleveId', 'e1')));
await t("parent : notes d'un autre élève refusées", assertFails(q(parent, 'notes', 'eleveId', 'e2')));
await t('parent : paiements de son enfant', assertSucceeds(q(parent, 'paiements', 'eleveId', 'e1')));
await t('parent : absences de son enfant', assertSucceeds(q(parent, 'absences', 'eleveId', 'e1')));
await t('parent : fiche de son enfant', assertSucceeds(getDoc(doc(parent, `ecoles/${E}/eleves/e1`))));
await t("parent : fiche d'un autre élève refusée", assertFails(getDoc(doc(parent, `ecoles/${E}/eleves/e2`))));
await t('parent : liste de tous les élèves refusée', assertFails(q(parent, 'eleves', 'actif', true)));
await t('parent ne peut pas écrire de note', assertFails(setDoc(doc(parent, `ecoles/${E}/notes/z`), { eleveId: 'e1', classeId: 'c1', valeur: 20, sur: 20 })));

// Enseignant
await t('enseignant : liste des élèves', assertSucceeds(q(prof, 'eleves', 'actif', true)));
await t('enseignant : note dans sa classe', assertSucceeds(setDoc(doc(prof, `ecoles/${E}/notes/n1`), { eleveId: 'e1', classeId: 'c1', matiereId: 'm', trimestre: 1, valeur: 15, sur: 20 })));
await t('enseignant : note hors de sa classe refusée', assertFails(setDoc(doc(prof, `ecoles/${E}/notes/n2`), { eleveId: 'e2', classeId: 'c2', matiereId: 'm', trimestre: 1, valeur: 15, sur: 20 })));
await t('enseignant : note > 20 refusée', assertFails(setDoc(doc(prof, `ecoles/${E}/notes/n3`), { eleveId: 'e1', classeId: 'c1', matiereId: 'm', trimestre: 1, valeur: 25, sur: 20 })));
await t("enseignant : appel dans sa classe", assertSucceeds(setDoc(doc(prof, `ecoles/${E}/presences/c1_2026-11-27`), { classeId: 'c1', statuts: {} })));
await t('enseignant : pas accès aux paiements', assertFails(q(prof, 'paiements', 'eleveId', 'e1')));

// Secrétariat
await t('secrétariat : encaisse un paiement', assertSucceeds(setDoc(doc(secr, `ecoles/${E}/paiements/p9`), { eleveId: 'e1', classeId: 'c1', montant: 5000 })));
await t('secrétariat : ne peut pas modifier un paiement', assertFails(updateDoc(doc(secr, `ecoles/${E}/paiements/p9`), { montant: 1 })));
await t('secrétariat : ne peut pas supprimer un paiement', assertFails(deleteDoc(doc(secr, `ecoles/${E}/paiements/p9`))));
await t('secrétariat : numérotation des reçus', assertSucceeds(runTransaction(secr, async (tx) => { const r = doc(secr, `ecoles/${E}/meta/compteurs`); await tx.get(r); tx.set(r, { recu: 1 }, { merge: true }); })));
await t('secrétariat : invite un parent', assertSucceeds(setDoc(doc(secr, 'invitations/p2@x.fr'), { email: 'p2@x.fr', role: 'parent', ecoleId: E, eleveIds: ['e1'] }, { merge: true })));
await t('secrétariat : ne peut pas inviter un admin', assertFails(setDoc(doc(secr, 'invitations/a2@x.fr'), { email: 'a2@x.fr', role: 'admin', ecoleId: E })));
await t('secrétariat : cherche un compte parent par e-mail', assertSucceeds(getDocs(query(collection(secr, 'users'), where('ecoleId', '==', E), where('email', '==', 'parent@x.fr')))));
await t('secrétariat : rattache un élève à un parent', assertSucceeds(updateDoc(doc(secr, 'users/parent'), { eleveIds: ['e1', 'e2'] })));
await t('secrétariat : ne peut pas changer un rôle', assertFails(updateDoc(doc(secr, 'users/parent'), { role: 'admin' })));
await t('secrétariat : ne peut pas créer de classe', assertFails(setDoc(doc(secr, `ecoles/${E}/classes/c9`), { nom: 'X' })));

// Direction & isolation entre écoles
await t('admin : crée une classe', assertSucceeds(setDoc(doc(admin, `ecoles/${E}/classes/c9`), { nom: 'CM2' })));
await t('admin : invite un enseignant', assertSucceeds(setDoc(doc(admin, 'invitations/prof2@x.fr'), { email: 'prof2@x.fr', role: 'enseignant', ecoleId: E, classeIds: ['c1'] })));
await t("admin d'une autre école : aucun accès", assertFails(q(fondateur, 'eleves', 'actif', true)));
await t("autre école : ne peut pas écraser une invitation", assertFails(setDoc(doc(fondateur, 'invitations/p2@x.fr'), { email: 'p2@x.fr', role: 'parent', ecoleId: 'ecole2' })));

console.log(`\n${ok} réussis, ${ko} échoués`);
await env.cleanup();
process.exit(ko ? 1 : 0);
