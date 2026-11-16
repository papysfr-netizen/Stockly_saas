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
      caissierRemises: { role: 'caissier', entrepriseId: E, permissions: { remisesRetraits: true } },
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
function batchVente(db, { vendeurId, boutiqueId = 'principale', remiseTotale = 0, qte = 1,
  prix = 10, total = null, prixVendus = null, sansStock = false, avecLien = true }) {
  const b = writeBatch(db);
  const venteRef = doc(collection(db, `entreprises/${E}/ventes`));
  b.set(venteRef, {
    id: venteRef.id, entrepriseId: E, vendeurId, boutiqueId,
    montantTotal: total ?? prix * qte, remiseTotale, statutLivraison: 'Livré',
    articles: [{ produitId: 'p1', quantite: qte, prixUnitaire: prix }],
    prixVendus: prixVendus ?? { p1: prix },
  });
  b.set(doc(collection(db, `entreprises/${E}/ecritures_comptables`)), {
    entrepriseId: E, reference: venteRef.id, lines: [],
  });
  if (!sansStock) {
    b.update(doc(db, `entreprises/${E}/produits/p1`), {
      quantite: increment(-qte),
      ...(boutiqueId !== 'principale' ? { [`stocks.${boutiqueId}`]: increment(-qte) } : {}),
      ...(avecLien ? { derniereVente: venteRef.id } : {}),
    });
  }
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

  it('vente à crédit : nom et téléphone obligatoires', async () => {
    const vente = (extra) => setDoc(doc(collection(dbDe('caissier'), `entreprises/${E}/ventes`)), {
      entrepriseId: E, vendeurId: 'caissier', boutiqueId: 'principale',
      montantTotal: 120, remiseTotale: 0, resteAPayer: 120, nomClient: 'Mama Neema',
      articles: [{ produitId: 'p1', quantite: 12, prixUnitaire: 10 }], prixVendus: { p1: 10 }, ...extra,
    });
    await assertFails(vente({ telephoneClient: '' }));
    await assertFails(vente({ telephoneClient: '0812' }));
    await assertSucceeds(vente({ telephoneClient: '+243 81 234 5678' }));
    // Nom obligatoire aussi
    await assertFails(vente({ telephoneClient: '+243 81 234 5678', nomClient: 'Client Divers' }));
    await assertFails(vente({ telephoneClient: '+243 81 234 5678', nomClient: '  ' }));
    // Payé comptant : pas besoin de téléphone
    await assertSucceeds(vente({ resteAPayer: 0, telephoneClient: '' }));
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
    await assertSucceeds(batchVente(dbDe('caissierB2'), { vendeurId: 'caissierB2', boutiqueId: 'b2', qte: 2 }));
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

  it('créer une dette client : nom et téléphone obligatoires', async () => {
    const creance = (tel, nom = 'Jean') => setDoc(doc(collection(dbDe('caissier'), `entreprises/${E}/creances`)), {
      nomTiers: nom, montantInitial: 50, acomptePaye: 0, montantReste: 50, telephone: tel,
    });
    await assertFails(creance(''));
    await assertFails(creance('12345'));
    await assertSucceeds(creance('0991234567'));
    await assertFails(creance('0991234567', 'Client Divers'));
    await assertFails(creance('0991234567', ''));
  });

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
describe('Clôture de caisse', () => {
  const cloture = (uid, extra = {}) => ({
    boutiqueId: 'principale', jour: '2026-11-14', parUid: uid, parNom: 'X', taux: 2300,
    fondUSD: 10, fondCDF: 0, compteUSD: 150, compteCDF: 23000, compteMobile: 40,
    fondDemainUSD: 10, fondDemainCDF: 0, note: '', createdAt: serverTimestamp(), ...extra,
  });
  const ref = (uid, id = 'principale_2026-11-14') => doc(dbDe(uid), `entreprises/${E}/clotures/${id}`);

  it('un caissier clôture sa boutique, à son nom', async () => {
    await assertSucceeds(setDoc(ref('caissier'), cloture('caissier')));
  });

  it('pas au nom d\'un autre, ni pour une autre boutique, ni avec un mauvais identifiant', async () => {
    await assertFails(setDoc(ref('caissier'), cloture('gerant')));
    await assertFails(setDoc(ref('caissierB2'), cloture('caissierB2')));
    await assertFails(setDoc(ref('caissier', 'principale_2026-11-15'), cloture('caissier')));
    await assertFails(setDoc(ref('caissier'), cloture('caissier', { compteUSD: -5 })));
    await assertFails(setDoc(ref('caissier'), cloture('caissier', { attendu: 999 })));
  });

  it('une clôture ne se modifie jamais ; seul le gérant la supprime (réouverture)', async () => {
    await assertSucceeds(setDoc(ref('caissier'), cloture('caissier')));
    await assertFails(updateDoc(ref('caissier'), { compteUSD: 999 }));
    await assertFails(updateDoc(ref('patron'), { compteUSD: 999 }));
    await assertFails(setDoc(ref('caissier'), cloture('caissier', { compteUSD: 1 })));
    await assertFails(deleteDoc(ref('caissier')));
    await assertSucceeds(deleteDoc(ref('gerant')));
  });

  it('une autre entreprise ne voit pas les clôtures', async () => {
    await assertSucceeds(setDoc(ref('caissier'), cloture('caissier')));
    await assertFails(getDoc(ref('autre')));
    await assertSucceeds(getDoc(ref('patron')));
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

// ─────────────────────────────────────────────────────────────
describe('Prix de vente vérifiés par le serveur', () => {
  it('un caissier ne peut pas vendre sous le prix normal', async () => {
    await assertFails(batchVente(dbDe('caissier'), { vendeurId: 'caissier', prix: 8 }));
  });

  it('un caissier peut vendre au-dessus du prix normal', async () => {
    await assertSucceeds(batchVente(dbDe('caissier'), { vendeurId: 'caissier', prix: 12 }));
  });

  it('avec « Remises et retraits », on peut vendre moins cher', async () => {
    await assertSucceeds(batchVente(dbDe('caissierRemises'), { vendeurId: 'caissierRemises', prix: 8 }));
  });

  it('impossible de déclarer un faux prix vendu ou un total plus bas', async () => {
    // prixVendus gonflé mais la ligne est vendue moins cher
    await assertFails(batchVente(dbDe('caissier'), { vendeurId: 'caissier', prix: 8, prixVendus: { p1: 10 } }));
    // lignes au bon prix, mais total encaissé plus bas
    await assertFails(batchVente(dbDe('caissier'), { vendeurId: 'caissier', qte: 2, total: 5 }));
  });

  it('impossible de baisser le stock sans vente liée', async () => {
    await assertFails(updateDoc(doc(dbDe('caissier'), `entreprises/${E}/produits/p1`), { quantite: increment(-1) }));
    await assertFails(batchVente(dbDe('caissier'), { vendeurId: 'caissier', avecLien: false }));
  });

  it('le prix propre à une boutique est respecté', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await updateDoc(doc(ctx.firestore(), `entreprises/${E}/produits/p1`), { prixParBoutique: { b2: 12 } });
    });
    await assertFails(batchVente(dbDe('caissierB2'), { vendeurId: 'caissierB2', boutiqueId: 'b2', prix: 10 }));
    await assertSucceeds(batchVente(dbDe('caissierB2'), { vendeurId: 'caissierB2', boutiqueId: 'b2', prix: 12 }));
  });
});

// ─────────────────────────────────────────────────────────────
describe('Comptes clients et avoirs', () => {
  const TEL = '0812345678';
  const compte = (db) => doc(db, `entreprises/${E}/comptes_clients/${TEL}`);

  // Mouvement + solde dans le même envoi (comme l'application)
  function mouvement(db, { type, montant, sens, retourId = null, lot = null }) {
    const b = lot ?? writeBatch(db);
    const mvt = doc(collection(db, `entreprises/${E}/comptes_clients/${TEL}/mouvements`));
    b.set(compte(db), {
      telephone: TEL, solde: increment(sens * montant), dernierMouvementId: mvt.id,
    }, { merge: true });
    b.set(mvt, { id: mvt.id, type, montant, sens, retourId });
    return lot ? b : b.commit();
  }

  it('un caissier peut enregistrer un dépôt d\'argent', async () => {
    await assertSucceeds(mouvement(dbDe('caissier'), { type: 'depot', montant: 50, sens: 1 }));
  });

  it('pas de faux avoir sans retour de marchandise', async () => {
    await assertFails(mouvement(dbDe('caissierRetours'), { type: 'avoir', montant: 50, sens: 1 }));
  });

  it('un « achat » ne peut pas augmenter le solde', async () => {
    await assertFails(mouvement(dbDe('caissier'), { type: 'achat', montant: 50, sens: 1 }));
  });

  it('le solde ne bouge pas sans mouvement', async () => {
    await assertFails(setDoc(compte(dbDe('caissier')), { telephone: TEL, solde: 500 }));
  });

  // Retour de la vente v1 (10 $) remboursé en avoir
  function retourEnAvoir(db, { montant = 10, avoir = 10 }) {
    const b = writeBatch(db);
    const retour = doc(collection(db, `entreprises/${E}/retours`));
    b.set(retour, {
      id: retour.id, venteId: 'v1', montant, reductionDette: 0,
      montantRembourse: avoir, montantConserve: 0, modeRemboursement: 'avoir', compteClient: TEL,
    });
    b.update(doc(db, `entreprises/${E}/ventes/v1`), { montantRetourne: increment(montant) });
    mouvement(db, { type: 'avoir', montant: avoir, sens: 1, retourId: retour.id, lot: b });
    return b.commit();
  }

  it('un vrai retour peut créditer un avoir', async () => {
    await assertSucceeds(retourEnAvoir(dbDe('caissierRetours'), {}));
  });

  it('impossible de rendre plus que la vente', async () => {
    await assertFails(retourEnAvoir(dbDe('caissierRetours'), { montant: 30, avoir: 30 }));
    await assertFails(retourEnAvoir(dbDe('caissierRetours'), { montant: 10, avoir: 25 }));
  });

  it('un retour déjà fait ne peut pas être « effacé » de la vente', async () => {
    await assertSucceeds(retourEnAvoir(dbDe('caissierRetours'), {}));
    await assertFails(updateDoc(doc(dbDe('caissier'), `entreprises/${E}/ventes/v1`), { montantRetourne: 0 }));
  });
});

// ─────────────────────────────────────────────────────────────
describe('Grosse vente', () => {
  async function venteDe(n, uid = 'caissier') {
    await env.withSecurityRulesDisabled(async (ctx) => {
      const fdb = ctx.firestore();
      const b = writeBatch(fdb);
      for (let i = 0; i < n; i++) {
        b.set(doc(fdb, `entreprises/${E}/produits/g${i}`), { nom: `G${i}`, prixVente: 2, quantite: 50 });
      }
      await b.commit();
    });
    const db = dbDe(uid);
    const b = writeBatch(db);
    const venteRef = doc(collection(db, `entreprises/${E}/ventes`));
    const articles = [];
    const prixVendus = {};
    for (let i = 0; i < n; i++) {
      articles.push({ produitId: `g${i}`, quantite: 3, prixUnitaire: 2.5 });
      prixVendus[`g${i}`] = 2.5;
      b.update(doc(db, `entreprises/${E}/produits/g${i}`), { quantite: increment(-3), derniereVente: venteRef.id });
    }
    b.set(venteRef, {
      id: venteRef.id, entrepriseId: E, vendeurId: uid, boutiqueId: 'principale',
      montantTotal: 7.5 * n, remiseTotale: 0, statutLivraison: 'Livré', articles, prixVendus,
    });
    return b.commit();
  }

  it('30 articles différents : accepté', async () => {
    await assertSucceeds(venteDe(30));
  });

  it('plus de 30 articles : il faut l\'autorisation « Remises et retraits »', async () => {
    await assertFails(venteDe(31));
    await assertSucceeds(venteDe(31, 'caissierRemises'));
  });
});

// ─────────────────────────────────────────────────────────────
describe('Supprimer son compte (Google Play)', () => {
  const marquer = (uid) => updateDoc(doc(dbDe(uid), `entreprises/${E}`), { enSuppression: true });

  it('un employé peut supprimer son propre profil, pas celui d\'un autre', async () => {
    await assertSucceeds(deleteDoc(doc(dbDe('caissier'), 'users/caissier')));
    await assertFails(deleteDoc(doc(dbDe('gerant'), 'users/caissierB2')));
  });

  it('sans suppression demandée, le patron ne peut pas effacer les ventes, retours ou l\'entreprise', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), `entreprises/${E}/retours/r1`), { venteId: 'v1', montant: 1 });
    });
    await assertFails(deleteDoc(doc(dbDe('patron'), `entreprises/${E}/retours/r1`)));
    await assertFails(deleteDoc(doc(dbDe('patron'), `entreprises/${E}`)));
    await assertFails(deleteDoc(doc(dbDe('patron'), 'users/caissier')));
  });

  it('suppression demandée : le patron efface tout, puis l\'entreprise', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      const fdb = ctx.firestore();
      await setDoc(doc(fdb, `entreprises/${E}/retours/r1`), { venteId: 'v1', montant: 1 });
      await setDoc(doc(fdb, `entreprises/${E}/comptes_clients/c1/mouvements/m1`), { montant: 1 });
    });
    await assertSucceeds(marquer('patron'));
    await assertSucceeds(deleteDoc(doc(dbDe('patron'), `entreprises/${E}/retours/r1`)));
    await assertSucceeds(deleteDoc(doc(dbDe('patron'), `entreprises/${E}/comptes_clients/c1/mouvements/m1`)));
    await assertSucceeds(deleteDoc(doc(dbDe('patron'), `entreprises/${E}/ventes/v1`)));
    await assertSucceeds(deleteDoc(doc(dbDe('patron'), 'users/caissier')));
    await assertSucceeds(deleteDoc(doc(dbDe('patron'), `entreprises/${E}`)));
  });

  it('un gérant ne peut ni demander la suppression ni tout effacer', async () => {
    await assertFails(marquer('gerant'));
    await env.withSecurityRulesDisabled(async (ctx) => {
      const fdb = ctx.firestore();
      await updateDoc(doc(fdb, `entreprises/${E}`), { enSuppression: true });
      await setDoc(doc(fdb, `entreprises/${E}/retours/r1`), { venteId: 'v1', montant: 1 });
    });
    await assertFails(deleteDoc(doc(dbDe('gerant'), `entreprises/${E}/retours/r1`)));
    await assertFails(deleteDoc(doc(dbDe('gerant'), `entreprises/${E}`)));
    await assertFails(deleteDoc(doc(dbDe('autre'), `entreprises/${E}/ventes/v1`)));
  });
});
