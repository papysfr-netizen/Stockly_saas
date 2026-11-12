// Tests automatiques des règles de sécurité Firestore (firestore.rules).
//
// Chaque test joue un personnage (patron, caissier…) qui essaie de faire
// quelque chose, et vérifie que le serveur ACCEPTE ou REFUSE.
//
// Lancer :  cd tests_regles && npm install && npm test

import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, it } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  addDoc,
  serverTimestamp,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  collection,
  increment,
  setDoc,
  updateDoc,
  writeBatch,
} from 'firebase/firestore';

const E = 'ent1'; // l'entreprise testée
const E2 = 'ent2'; // une autre entreprise (concurrent)

let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-stockly',
    firestore: { rules: readFileSync(new URL('../../firestore.rules', import.meta.url), 'utf8') },
  });
});

after(async () => {
  await env?.cleanup();
});

// Données de départ, remises à zéro avant chaque test
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    const profils = {
      patron: { role: 'owner', entrepriseId: E },
      gerant: { role: 'gerant', entrepriseId: E },
      caissier: { role: 'caissier', entrepriseId: E },
      caissierB2: { role: 'caissier', entrepriseId: E, boutiqueId: 'b2' },
      caissierRetours: { role: 'caissier', entrepriseId: E, permissions: { retours: true } },
      bloque: { role: 'caissier', entrepriseId: E, estActif: false },
      autre: { role: 'owner', entrepriseId: E2 },
    };
    for (const [uid, p] of Object.entries(profils)) {
      await setDoc(doc(db, 'users', uid), { uid, ...p });
    }
    await setDoc(doc(db, 'entreprises', E), { nom: 'Boutique Test', ownerId: 'patron' });
    await setDoc(doc(db, 'entreprises', E2), { nom: 'Concurrent', ownerId: 'autre' });
    await setDoc(doc(db, `entreprises/${E}/produits/p1`), {
      nom: 'Chemise', prixVente: 10, prixAchat: 6, quantite: 20, stocks: { b2: 5 },
    });
    await setDoc(doc(db, `entreprises/${E}/ventes/v1`), {
      id: 'v1', entrepriseId: E, vendeurId: 'caissier', boutiqueId: 'principale',
      montantTotal: 10, remiseTotale: 0, statutLivraison: 'Non livré',
      articles: [{ produitId: 'p1', quantite: 1, prixUnitaire: 10 }],
    });
    await setDoc(doc(db, `entreprises/${E}/creances/c1`), {
      montantInitial: 100, acomptePaye: 20, montantReste: 80, statut: 'partiel',
    });
    await setDoc(doc(db, `entreprises/${E}/ecritures_comptables/e1`), { description: 'test' });
  });
});

/** La base de données vue par un utilisateur connecté (ou anonyme si uid = null) */
function dbDe(uid) {
  return uid ? env.authenticatedContext(uid).firestore() : env.unauthenticatedContext().firestore();
}

/** Une vente complète comme celle de la caisse (vente + écriture + stock) */
function batchVente(db, { vendeurId, boutiqueId = 'principale', remiseTotale = 0, qte = 1 }) {
  const b = writeBatch(db);
  const venteRef = doc(collection(db, `entreprises/${E}/ventes`));
  b.set(venteRef, {
    id: venteRef.id, entrepriseId: E, vendeurId, boutiqueId,
    montantTotal: 10 * qte, remiseTotale, statutLivraison: 'Livré',
    articles: [{ produitId: 'p1', quantite: qte, prixUnitaire: 10 }],
  });
  b.set(doc(collection(db, `entreprises/${E}/ecritures_comptables`)), {
    entrepriseId: E, reference: venteRef.id, lines: [],
  });
  b.update(doc(db, `entreprises/${E}/produits/p1`), {
    quantite: increment(-qte),
    ...(boutiqueId !== 'principale' ? { [`stocks.${boutiqueId}`]: increment(-qte) } : {}),
  });
  return b.commit();
}

// ─────────────────────────────────────────────────────────────
describe('Ventes', () => {
  it('un caissier peut vendre dans sa boutique', async () => {
    await assertSucceeds(batchVente(dbDe('caissier'), { vendeurId: 'caissier' }));
  });

  it('un caissier ne peut pas vendre au nom d\'un autre', async () => {
    await assertFails(batchVente(dbDe('caissier'), { vendeurId: 'gerant' }));
  });

  it('un caissier ne peut pas faire de remise sans autorisation', async () => {
    await assertFails(batchVente(dbDe('caissier'), { vendeurId: 'caissier', remiseTotale: 2 }));
  });

  it('un caissier ne vend que dans sa boutique', async () => {
    await assertSucceeds(batchVente(dbDe('caissierB2'), { vendeurId: 'caissierB2', boutiqueId: 'b2' }));
    await assertFails(batchVente(dbDe('caissierB2'), { vendeurId: 'caissierB2', boutiqueId: 'principale' }));
  });

  it('un compte bloqué ne peut plus vendre ni lire', async () => {
    await assertFails(batchVente(dbDe('bloque'), { vendeurId: 'bloque' }));
    await assertFails(getDoc(doc(dbDe('bloque'), `entreprises/${E}/ventes/v1`)));
  });

  it('une autre entreprise et un visiteur ne voient pas les ventes', async () => {
    await assertFails(getDoc(doc(dbDe('autre'), `entreprises/${E}/ventes/v1`)));
    await assertFails(getDoc(doc(dbDe(null), `entreprises/${E}/ventes/v1`)));
  });

  it('un caissier peut marquer une vente comme livrée', async () => {
    await assertSucceeds(updateDoc(doc(dbDe('caissier'), `entreprises/${E}/ventes/v1`), {
      statutLivraison: 'Livré',
    }));
  });

  it('un caissier ne peut pas changer le montant ou les articles d\'une vente', async () => {
    const ref = doc(dbDe('caissier'), `entreprises/${E}/ventes/v1`);
    await assertFails(updateDoc(ref, { montantTotal: 1 }));
    await assertFails(updateDoc(ref, { articles: [] }));
  });

  it('seul le gérant peut supprimer une vente', async () => {
    await assertFails(deleteDoc(doc(dbDe('caissier'), `entreprises/${E}/ventes/v1`)));
    await assertSucceeds(deleteDoc(doc(dbDe('gerant'), `entreprises/${E}/ventes/v1`)));
  });
});

// ─────────────────────────────────────────────────────────────
describe('Stock des produits', () => {
  const p1 = (uid) => doc(dbDe(uid), `entreprises/${E}/produits/p1`);

  it('un caissier ne peut pas créer un produit ni changer un prix', async () => {
    await assertFails(setDoc(doc(dbDe('caissier'), `entreprises/${E}/produits/p2`), { nom: 'X', quantite: 1 }));
    await assertFails(updateDoc(p1('caissier'), { prixVente: 1 }));
  });

  it('le gérant peut corriger le stock', async () => {
    await assertSucceeds(updateDoc(p1('gerant'), { quantite: 100 }));
  });

  it('un caissier NE PEUT PAS augmenter le stock (stock fictif)', async () => {
    await assertFails(updateDoc(p1('caissier'), { quantite: increment(5) }));
  });

  it('un caissier autorisé aux retours peut remettre du stock', async () => {
    await assertSucceeds(updateDoc(p1('caissierRetours'), { quantite: increment(1) }));
  });

  it('boutique b2 : le total et la boutique baissent ensemble', async () => {
    await assertSucceeds(updateDoc(p1('caissierB2'), {
      quantite: increment(-2), 'stocks.b2': increment(-2),
    }));
  });

  it('boutique b2 : impossible de baisser seulement le total ou seulement la boutique', async () => {
    // Baisser le total sans la boutique b2 = vider la boutique principale en douce
    await assertFails(updateDoc(p1('caissierB2'), { quantite: increment(-2) }));
    // Baisser b2 sans le total = « transfert » caché vers la principale
    await assertFails(updateDoc(p1('caissierB2'), { 'stocks.b2': increment(-2) }));
    // Montants différents
    await assertFails(updateDoc(p1('caissierB2'), {
      quantite: increment(-2), 'stocks.b2': increment(-1),
    }));
  });

  it('boutique principale : un caissier ne touche pas au stock des autres boutiques', async () => {
    await assertFails(updateDoc(p1('caissier'), {
      quantite: increment(-1), 'stocks.b2': increment(-1),
    }));
  });
});

// ─────────────────────────────────────────────────────────────
describe('Dettes des clients', () => {
  const c1 = (uid) => doc(dbDe(uid), `entreprises/${E}/creances/c1`);

  it('un caissier peut encaisser un paiement', async () => {
    await assertSucceeds(updateDoc(c1('caissier'), { acomptePaye: 50, montantReste: 50 }));
  });

  it('un caissier ne peut pas effacer une dette sans paiement', async () => {
    await assertFails(updateDoc(c1('caissier'), { montantReste: 0 }));
  });

  it('un caissier ne peut pas changer le montant de départ', async () => {
    await assertFails(updateDoc(c1('caissier'), { montantInitial: 10 }));
  });

  it('seul le gérant peut supprimer une dette', async () => {
    await assertFails(deleteDoc(c1('caissier')));
    await assertSucceeds(deleteDoc(c1('gerant')));
  });
});

// ─────────────────────────────────────────────────────────────
describe('Comptabilité et journal', () => {
  it('un caissier ne lit pas la comptabilité, le gérant oui', async () => {
    await assertFails(getDocs(collection(dbDe('caissier'), `entreprises/${E}/ecritures_comptables`)));
    await assertSucceeds(getDocs(collection(dbDe('gerant'), `entreprises/${E}/ecritures_comptables`)));
  });

  it('un caissier ne modifie ni ne supprime une écriture comptable', async () => {
    const ref = doc(dbDe('caissier'), `entreprises/${E}/ecritures_comptables/e1`);
    await assertFails(updateDoc(ref, { description: 'modifiée' }));
    await assertFails(deleteDoc(ref));
  });

  it('chacun écrit SA ligne de journal, personne ne la modifie', async () => {
    const db = dbDe('caissier');
    await assertSucceeds(setDoc(doc(db, `entreprises/${E}/journal/j1`), { userId: 'caissier', action: 'vente' }));
    await assertFails(setDoc(doc(db, `entreprises/${E}/journal/j2`), { userId: 'gerant', action: 'vente' }));
    await assertFails(updateDoc(doc(db, `entreprises/${E}/journal/j1`), { action: 'rien' }));
    await assertFails(getDocs(collection(db, `entreprises/${E}/journal`)));
    await assertSucceeds(getDocs(collection(dbDe('gerant'), `entreprises/${E}/journal`)));
  });
});

// ─────────────────────────────────────────────────────────────
describe('Rapports de plantages', () => {
  const rapport = (uid, extra = {}) => ({
    uid, message: 'Null check operator', pile: '#0 main', contexte: '',
    fatale: false, plateforme: 'android', date: serverTimestamp(), ...extra,
  });

  it('un utilisateur connecté envoie un rapport à son nom', async () => {
    await assertSucceeds(addDoc(collection(dbDe('caissier'), 'rapports_erreurs'), rapport('caissier')));
  });

  it('pas de rapport anonyme, au nom d\'un autre, ou trop gros', async () => {
    await assertFails(addDoc(collection(dbDe(null), 'rapports_erreurs'), rapport('x')));
    await assertFails(addDoc(collection(dbDe('caissier'), 'rapports_erreurs'), rapport('gerant')));
    await assertFails(addDoc(collection(dbDe('caissier'), 'rapports_erreurs'),
      rapport('caissier', { pile: 'x'.repeat(5000) })));
    await assertFails(addDoc(collection(dbDe('caissier'), 'rapports_erreurs'),
      rapport('caissier', { motDePasse: 'secret' })));
  });

  it('personne ne lit les rapports depuis l\'application', async () => {
    await assertFails(getDocs(collection(dbDe('patron'), 'rapports_erreurs')));
  });
});

// ─────────────────────────────────────────────────────────────
describe('Profils et équipe', () => {
  it('un employé ne peut pas se donner plus de droits', async () => {
    const ref = doc(dbDe('caissier'), 'users/caissier');
    await assertFails(updateDoc(ref, { role: 'gerant' }));
    await assertFails(updateDoc(ref, { permissions: { gererStock: true } }));
    await assertFails(updateDoc(ref, { entrepriseId: E2 }));
    await assertFails(updateDoc(doc(dbDe('bloque'), 'users/bloque'), { estActif: true }));
  });

  it('un employé peut changer son propre nom', async () => {
    await assertSucceeds(updateDoc(doc(dbDe('caissier'), 'users/caissier'), { nom: 'Jean' }));
  });

  it('un caissier ne lit pas le profil des collègues', async () => {
    await assertFails(getDoc(doc(dbDe('caissier'), 'users/gerant')));
    await assertSucceeds(getDoc(doc(dbDe('patron'), 'users/gerant')));
  });

  it('le patron ne peut pas nommer quelqu\'un « owner »', async () => {
    await assertFails(updateDoc(doc(dbDe('patron'), 'users/caissier'), { role: 'owner' }));
    await assertSucceeds(updateDoc(doc(dbDe('patron'), 'users/caissier'), { role: 'gerant' }));
  });

  it('personne ne modifie l\'entreprise d\'un autre', async () => {
    await assertFails(updateDoc(doc(dbDe('autre'), `entreprises/${E}`), { nom: 'Piraté' }));
    await assertFails(updateDoc(doc(dbDe('gerant'), `entreprises/${E}`), { ownerId: 'gerant' }));
  });
});
