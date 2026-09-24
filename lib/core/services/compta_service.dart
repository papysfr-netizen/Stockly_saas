import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stockly_saas/core/models/dette.dart';
import 'package:stockly_saas/features/accounting/models/comptabilite_models.dart';

final comptaServiceProvider = Provider<ComptaService>((ref) {
  return ComptaService();
});

class LigneBalance {
  final String compteCode;
  final String compteIntitule;
  final double totalDebit;
  final double totalCredit;

  LigneBalance({
    required this.compteCode,
    required this.compteIntitule,
    required this.totalDebit,
    required this.totalCredit,
  });

  double get soldeDebiteur =>
      totalDebit > totalCredit ? totalDebit - totalCredit : 0.0;
  double get soldeCrediteur =>
      totalCredit > totalDebit ? totalCredit - totalDebit : 0.0;
}

class ComptaService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static CollectionReference _getEcrituresRef(String entrepriseId) {
    return _firestore
        .collection('entreprises')
        .doc(entrepriseId)
        .collection('ecritures_comptables');
  }

  // Plan comptable standard SYSCOHADA
  static final Map<String, String> planComptableStandard = {
    '101000': 'Capital social',
    '120000': 'Résultat de l\'exercice',
    '211000': 'Immobilisations / Équipements',
    '370000': 'Stock de marchandises',
    '401000': 'Fournisseurs',
    '411000': 'Clients (Créances)',
    '512000': 'Banque',
    '571000': 'Caisse principale',
    '601000': 'Achats de marchandises',
    '607000': 'Achats / Charges d\'exploitation',
    '620000': 'Services extérieurs & Dépenses',
    '701000': 'Ventes de marchandises',
  };

  static double _parseDouble(dynamic val) {
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }

  static DateTime _parseDate(dynamic dateVal) {
    if (dateVal is Timestamp) return dateVal.toDate();
    if (dateVal is String) return DateTime.tryParse(dateVal) ?? DateTime.now();
    return DateTime.now();
  }

  // ==========================================
  // 1. ÉCRITURES & TRANSACTIONS
  // ==========================================

  /// Enregistre une écriture multi-lignes équilibrée (SYSCOHADA)
  static Future<void> ajouterEcritureMultiLignes({
    required String entrepriseId,
    required String libelle,
    required List<LigneEcriture> lignes,
    required DateTime date,
    String pieceRef = '',
    String userId = 'SYSTEM',
  }) async {
    if (entrepriseId.isEmpty || lignes.isEmpty) return;

    final docRef = _getEcrituresRef(entrepriseId).doc();

    final ecriture = EcritureComptable(
      id: docRef.id,
      entrepriseId: entrepriseId,
      date: date,
      libelle: libelle,
      pieceRef: pieceRef,
      lignes: lignes,
    );

    if (ecriture.estEquilibree) {
      final data = ecriture.toMap();
      data['createdAt'] = FieldValue.serverTimestamp();
      data['createdBy'] = userId;
      await docRef.set(data);
    }
  }

  /// Ajoute une écriture multi-lignes dans un WriteBatch
  static void ajouterEcritureMultiLignesDansBatch({
    required WriteBatch batch,
    required String entrepriseId,
    required String libelle,
    required List<LigneEcriture> lignes,
    required DateTime date,
    String pieceRef = '',
    String userId = 'SYSTEM',
  }) {
    if (entrepriseId.isEmpty || lignes.isEmpty) return;

    final docRef = _getEcrituresRef(entrepriseId).doc();

    final ecriture = EcritureComptable(
      id: docRef.id,
      entrepriseId: entrepriseId,
      date: date,
      libelle: libelle,
      pieceRef: pieceRef,
      lignes: lignes,
    );

    if (ecriture.estEquilibree) {
      final data = ecriture.toMap();
      data['createdAt'] = FieldValue.serverTimestamp();
      data['createdBy'] = userId;
      batch.set(docRef, data);
    }
  }

  /// Helper spécialisé pour enregistrer une VENTE en UNE SEULE écriture SYSCOHADA
  static void ajouterEcritureVenteDansBatch({
    required WriteBatch batch,
    required String entrepriseId,
    required String venteId,
    required String clientNom,
    required double montantTotal,
    required double montantPaye,
    required double montantReste,
    required DateTime date,
  }) {
    final List<LigneEcriture> lignes = [];

    // 1. Débit Caisse (571000) si versement
    if (montantPaye > 0) {
      lignes.add(LigneEcriture(
        compteCode: '571000',
        compteIntitule: planComptableStandard['571000'] ?? 'Caisse principale',
        debit: montantPaye,
        credit: 0.0,
      ));
    }

    // 2. Débit Créance Client (411000) si reste à payer
    if (montantReste > 0) {
      lignes.add(LigneEcriture(
        compteCode: '411000',
        compteIntitule: 'Clients - $clientNom',
        debit: montantReste,
        credit: 0.0,
      ));
    }

    // 3. Crédit Ventes (701000) du montant TOTAL
    lignes.add(LigneEcriture(
      compteCode: '701000',
      compteIntitule: planComptableStandard['701000'] ?? 'Ventes de marchandises',
      debit: 0.0,
      credit: montantTotal > 0 ? montantTotal : (montantPaye + montantReste),
    ));

    ajouterEcritureMultiLignesDansBatch(
      batch: batch,
      entrepriseId: entrepriseId,
      libelle: 'Vente - $clientNom',
      lignes: lignes,
      date: date,
      pieceRef: venteId,
    );
  }

  /// Méthode simple 1 Débit / 1 Crédit (Rétrocompatibilité)
  static Future<void> ajouterEcriture({
    required String entrepriseId,
    required String libelle,
    required String compteDebit,
    required String compteCredit,
    required double montant,
    required DateTime date,
    String pieceRef = '',
    String userId = 'SYSTEM',
  }) async {
    if (montant <= 0 || entrepriseId.isEmpty) return;

    await ajouterEcritureMultiLignes(
      entrepriseId: entrepriseId,
      libelle: libelle,
      date: date,
      pieceRef: pieceRef,
      userId: userId,
      lignes: [
        LigneEcriture(
          compteCode: compteDebit,
          compteIntitule: planComptableStandard[compteDebit] ?? 'Compte ($compteDebit)',
          debit: montant,
          credit: 0.0,
        ),
        LigneEcriture(
          compteCode: compteCredit,
          compteIntitule: planComptableStandard[compteCredit] ?? 'Compte ($compteCredit)',
          debit: 0.0,
          credit: montant,
        ),
      ],
    );
  }

  static Stream<List<EcritureComptable>> getEcrituresStream(String entrepriseId) {
    if (entrepriseId.isEmpty) return Stream.value([]);

    return _getEcrituresRef(entrepriseId).snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => EcritureComptable.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  // ==========================================
  // 2. NETTOYAGE & SYNCHRONISATION
  // ==========================================

  /// Supprime les anciennes écritures obsolètes (schéma avec compteCredit/compteDebit plats)
  static Future<int> nettoyerEcrituresObsolescentes(String entrepriseId) async {
    if (entrepriseId.isEmpty) return 0;

    final query = await _getEcrituresRef(entrepriseId).get();
    WriteBatch batch = _firestore.batch();
    int count = 0;

    for (var doc in query.docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data.containsKey('compteCredit') || data.containsKey('compteDebit')) {
        batch.delete(doc.reference);
        count++;
      }
    }

    if (count > 0) {
      await batch.commit();
    }
    return count;
  }

  static Future<int> synchroniserHistorique(String entrepriseId) async {
    if (entrepriseId.isEmpty) return 0;

    WriteBatch batch = _firestore.batch();
    int opCount = 0;
    int totalTraite = 0;

    Future<void> verifierEtValiderBatch() async {
      if (opCount >= 400) {
        await batch.commit();
        batch = _firestore.batch();
        opCount = 0;
      }
    }

    final entrepriseRef = _firestore.collection('entreprises').doc(entrepriseId);

    // A. Synchronisation des Ventes (1 seule écriture SYSCOHADA par vente)
    final ventesSnap = await entrepriseRef
        .collection('ventes')
        .where('comptabilise', isEqualTo: false)
        .get();

    for (var doc in ventesSnap.docs) {
      final data = doc.data();
      final String client = data['clientNom'] ?? data['nomClient'] ?? 'Client Divers';
      final double verse = _parseDouble(data['montantPaye']);
      final double reste = _parseDouble(data['resteAPayer']);
      final double total = _parseDouble(data['total']) > 0 
          ? _parseDouble(data['total']) 
          : (verse + reste);
      final DateTime date = _parseDate(data['date'] ?? data['createdAt']);

      if (total > 0) {
        ajouterEcritureVenteDansBatch(
          batch: batch,
          entrepriseId: entrepriseId,
          venteId: doc.id,
          clientNom: client,
          montantTotal: total,
          montantPaye: verse,
          montantReste: reste,
          date: date,
        );
        opCount++;
      }

      batch.update(doc.reference, {
        'comptabilise': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      opCount++;
      totalTraite++;

      await verifierEtValiderBatch();
    }

    // B. Synchronisation des Dépenses
    final depensesSnap = await entrepriseRef
        .collection('depenses')
        .where('comptabilise', isEqualTo: false)
        .get();

    for (var doc in depensesSnap.docs) {
      final data = doc.data();
      final double montant = _parseDouble(data['montant']);
      final String motif = data['motif'] ?? data['categorie'] ?? 'Dépense diverse';
      final DateTime date = _parseDate(data['date'] ?? data['createdAt']);

      if (montant > 0) {
        ajouterEcritureMultiLignesDansBatch(
          batch: batch,
          entrepriseId: entrepriseId,
          libelle: 'Dépense : $motif',
          date: date,
          pieceRef: doc.id,
          lignes: [
            LigneEcriture(
              compteCode: '607000',
              compteIntitule: planComptableStandard['607000'] ?? 'Charges d\'exploitation',
              debit: montant,
              credit: 0.0,
            ),
            LigneEcriture(
              compteCode: '571000',
              compteIntitule: planComptableStandard['571000'] ?? 'Caisse principale',
              debit: 0.0,
              credit: montant,
            ),
          ],
        );
        opCount++;
      }

      batch.update(doc.reference, {
        'comptabilise': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      opCount++;
      totalTraite++;

      await verifierEtValiderBatch();
    }

    // C. Synchronisation des Dettes
    final dettesSnap = await entrepriseRef
        .collection('dettes')
        .where('comptabilise', isEqualTo: false)
        .get();

    for (var doc in dettesSnap.docs) {
      final data = doc.data();
      final dette = Dette.fromMap(doc.id, data);
      final bool isClient = dette.type == TypeDette.client;
      final DateTime date = _parseDate(data['createdAt'] ?? data['dateCreation'] ?? data['date']);

      if (dette.montantReste > 0) {
        ajouterEcritureMultiLignesDansBatch(
          batch: batch,
          entrepriseId: entrepriseId,
          libelle: isClient
              ? 'Créance enregistrée - ${dette.nomTiers}'
              : 'Dette fournisseur enregistrée - ${dette.nomTiers}',
          date: date,
          pieceRef: doc.id,
          lignes: [
            LigneEcriture(
              compteCode: isClient ? '411000' : '601000',
              compteIntitule: isClient ? 'Clients - ${dette.nomTiers}' : 'Achats de marchandises',
              debit: dette.montantReste,
              credit: 0.0,
            ),
            LigneEcriture(
              compteCode: isClient ? '701000' : '401000',
              compteIntitule: isClient ? 'Ventes de marchandises' : 'Fournisseurs - ${dette.nomTiers}',
              debit: 0.0,
              credit: dette.montantReste,
            ),
          ],
        );
        opCount++;
      }

      batch.update(doc.reference, {
        'comptabilise': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      opCount++;
      totalTraite++;

      await verifierEtValiderBatch();
    }

    if (opCount > 0) {
      await batch.commit();
    }

    return totalTraite;
  }

  // ==========================================
  // 3. GENERATION DE LA BALANCE ET DU BILAN
  // ==========================================

  static Map<String, List<LigneEcriture>> genererGrandLivre(
      List<EcritureComptable> ecritures) {
    final Map<String, List<LigneEcriture>> grandLivre = {};

    for (var ecriture in ecritures) {
      for (var ligne in ecriture.lignes) {
        grandLivre.putIfAbsent(ligne.compteCode, () => []).add(ligne);
      }
    }
    return grandLivre;
  }

  static List<LigneBalance> genererBalanceGenerale(
      List<EcritureComptable> ecritures, Map<String, String> planComptable) {
    final Map<String, double> debits = {};
    final Map<String, double> credits = {};

    for (var ecriture in ecritures) {
      for (var ligne in ecriture.lignes) {
        debits[ligne.compteCode] = (debits[ligne.compteCode] ?? 0.0) + ligne.debit;
        credits[ligne.compteCode] = (credits[ligne.compteCode] ?? 0.0) + ligne.credit;
      }
    }

    final Set<String> tousLesComptes = {...debits.keys, ...credits.keys};

    return tousLesComptes.map((code) {
      return LigneBalance(
        compteCode: code,
        compteIntitule: planComptable[code] ??
            planComptableStandard[code] ??
            'Compte inconnu ($code)',
        totalDebit: debits[code] ?? 0.0,
        totalCredit: credits[code] ?? 0.0,
      );
    }).toList()
      ..sort((a, b) => a.compteCode.compareTo(b.compteCode));
  }

  static Map<String, List<LigneBalance>> genererBilan(
      List<LigneBalance> balance) {
    final List<LigneBalance> actif = [];
    final List<LigneBalance> passif = [];

    double totalProduits = 0.0;
    double totalCharges = 0.0;

    for (var ligne in balance) {
      int classe = int.tryParse(ligne.compteCode.substring(0, 1)) ?? 0;

      if ([2, 3, 5].contains(classe) || (classe == 4 && ligne.soldeDebiteur > 0)) {
        actif.add(ligne);
      } else if ([1].contains(classe) || (classe == 4 && ligne.soldeCrediteur > 0)) {
        passif.add(ligne);
      } else if (classe == 6) {
        totalCharges += ligne.soldeDebiteur;
      } else if (classe == 7) {
        totalProduits += ligne.soldeCrediteur;
      }
    }

    final double resultat = totalProduits - totalCharges;
    if (resultat != 0) {
      passif.add(LigneBalance(
        compteCode: '120000',
        compteIntitule: 'Résultat net de l\'exercice',
        totalDebit: resultat < 0 ? resultat.abs() : 0.0,
        totalCredit: resultat > 0 ? resultat : 0.0,
      ));
    }

    return {'actif': actif, 'passif': passif};
  }
}