import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/comptabilite_models.dart';

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

  /// Helpers pour l'isolation Multi-Tenant /organizations/{orgId}
  static DocumentReference _orgRef(String orgId) {
    return _firestore.collection('organizations').doc(orgId);
  }

  static CollectionReference _ecrituresRef(String orgId) {
    return _orgRef(orgId).collection('ecritures_comptables');
  }

  /// Plan comptable standard (SYSCOHADA / PCG)
  static final Map<String, String> planComptableStandard = {
    '101000': 'Capital social',
    '120000': 'Résultat de l\'exercice',
    '211000': 'Immobilisations / Équipements',
    '370000': 'Stock de marchandises',
    '401000': 'Fournisseurs',
    '411000': 'Clients (Créances)',
    '512000': 'Banque',
    '531000': 'Caisse principale',
    '601000': 'Achats de marchandises',
    '607000': 'Achats / Charges d\'exploitation',
    '620000': 'Services extérieurs & Dépenses',
    '701000': 'Ventes de marchandises',
  };

  // ==========================================
  // 1. ÉCRITURES & TRANSACTIONS (ATOMIQUES)
  // ==========================================

  /// Enregistre une écriture unique en base
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

    final docRef = _ecrituresRef(entrepriseId).doc();

    final ecriture = EcritureComptable(
      id: docRef.id,
      entrepriseId: entrepriseId,
      date: date,
      libelle: libelle,
      pieceRef: pieceRef,
      lignes: [
        LigneEcriture(
          compteCode: compteDebit,
          compteIntitule: planComptableStandard[compteDebit] ??
              'Compte débit ($compteDebit)',
          debit: montant,
          credit: 0.0,
        ),
        LigneEcriture(
          compteCode: compteCredit,
          compteIntitule: planComptableStandard[compteCredit] ??
              'Compte crédit ($compteCredit)',
          debit: 0.0,
          credit: montant,
        ),
      ],
    );

    if (ecriture.estEquilibree) {
      final data = ecriture.toMap();
      data['createdAt'] = FieldValue.serverTimestamp();
      data['createdBy'] = userId;
      await docRef.set(data);
    }
  }

  /// Inserer une écriture dans un WriteBatch existant (Offline-First)
  static void ajouterEcritureDansBatch({
    required WriteBatch batch,
    required String entrepriseId,
    required String libelle,
    required String compteDebit,
    required String compteCredit,
    required double montant,
    required DateTime date,
    String pieceRef = '',
    String userId = 'SYSTEM',
  }) {
    if (montant <= 0 || entrepriseId.isEmpty) return;

    final docRef = _ecrituresRef(entrepriseId).doc();

    final ecriture = EcritureComptable(
      id: docRef.id,
      entrepriseId: entrepriseId,
      date: date,
      libelle: libelle,
      pieceRef: pieceRef,
      lignes: [
        LigneEcriture(
          compteCode: compteDebit,
          compteIntitule: planComptableStandard[compteDebit] ??
              'Compte débit ($compteDebit)',
          debit: montant,
          credit: 0.0,
        ),
        LigneEcriture(
          compteCode: compteCredit,
          compteIntitule: planComptableStandard[compteCredit] ??
              'Compte crédit ($compteCredit)',
          debit: 0.0,
          credit: montant,
        ),
      ],
    );

    if (ecriture.estEquilibree) {
      final data = ecriture.toMap();
      data['createdAt'] = FieldValue.serverTimestamp();
      data['createdBy'] = userId;
      batch.set(docRef, data);
    }
  }

  /// Flux réactif du Journal des Écritures
  static Stream<List<EcritureComptable>> getEcrituresStream(
      String entrepriseId) {
    if (entrepriseId.isEmpty) {
      return Stream.value([]);
    }

    return _ecrituresRef(entrepriseId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EcritureComptable.fromMap(
                doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  // ==========================================
  // 2. SYNCHRONISATION SÉCURISÉE AVEC BATCH AUTO-COMMIT
  // ==========================================

  /// Synchronise l'historique sous /organizations/{orgId}
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

    // A. Synchronisation des Ventes non comptabilisées
    final ventesSnap =
        await _orgRef(entrepriseId).collection('ventes').get();

    for (var doc in ventesSnap.docs) {
      final data = doc.data();
      if (data['comptabilise'] == true) continue;

      final String client =
          data['clientNom'] ?? data['nomClient'] ?? 'Client Divers';
      final double verse =
          ((data['montantPaye'] ?? data['total']) ?? 0.0).toDouble();
      final double reste = (data['resteAPayer'] ?? 0.0).toDouble();
      final DateTime date = _parseDate(data['date'] ?? data['createdAt']);

      if (verse > 0) {
        ajouterEcritureDansBatch(
          batch: batch,
          entrepriseId: entrepriseId,
          libelle: 'Vente en caisse - $client',
          compteDebit: '531000',
          compteCredit: '701000',
          montant: verse,
          date: date,
          pieceRef: doc.id,
        );
        opCount++;
      }

      if (reste > 0) {
        ajouterEcritureDansBatch(
          batch: batch,
          entrepriseId: entrepriseId,
          libelle: 'Créance vente - Client : $client',
          compteDebit: '411000',
          compteCredit: '701000',
          montant: reste,
          date: date,
          pieceRef: doc.id,
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

    // B. Synchronisation des Dépenses non comptabilisées
    final depensesSnap =
        await _orgRef(entrepriseId).collection('depenses').get();

    for (var doc in depensesSnap.docs) {
      final data = doc.data();
      if (data['comptabilise'] == true) continue;

      final double montant = (data['montant'] ?? 0.0).toDouble();
      final String motif =
          data['motif'] ?? data['categorie'] ?? 'Dépense diverse';
      final DateTime date = _parseDate(data['date'] ?? data['createdAt']);

      if (montant > 0) {
        ajouterEcritureDansBatch(
          batch: batch,
          entrepriseId: entrepriseId,
          libelle: 'Dépense : $motif',
          compteDebit: '607000',
          compteCredit: '531000',
          montant: montant,
          date: date,
          pieceRef: doc.id,
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

    // C. Synchronisation des Dettes non comptabilisées
    final dettesSnap =
        await _orgRef(entrepriseId).collection('dettes').get();

    for (var doc in dettesSnap.docs) {
      final data = doc.data();
      if (data['comptabilise'] == true) continue;

      final double reste =
          (data['montantRestant'] ?? data['montant'] ?? 0.0).toDouble();
      final String client = data['nomClient'] ?? 'Client';
      final String typeDette = data['type'] ?? 'CLIENT';
      final DateTime date = _parseDate(data['date'] ?? data['createdAt']);

      if (reste > 0) {
        ajouterEcritureDansBatch(
          batch: batch,
          entrepriseId: entrepriseId,
          libelle: typeDette == 'CLIENT'
              ? 'Créance enregistrée - $client'
              : 'Dette fournisseur enregistrée - $client',
          compteDebit: typeDette == 'CLIENT' ? '411000' : '601000',
          compteCredit: typeDette == 'CLIENT' ? '701000' : '401000',
          montant: reste,
          date: date,
          pieceRef: doc.id,
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

  static DateTime _parseDate(dynamic dateVal) {
    if (dateVal is Timestamp) {
      return dateVal.toDate();
    } else if (dateVal is String) {
      return DateTime.tryParse(dateVal) ?? DateTime.now();
    }
    return DateTime.now();
  }

  // ==========================================
  // 3. CALCULS FINANCIERS (GRAND LIVRE / BALANCE / BILAN)
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
        debits[ligne.compteCode] =
            (debits[ligne.compteCode] ?? 0.0) + ligne.debit;
        credits[ligne.compteCode] =
            (credits[ligne.compteCode] ?? 0.0) + ligne.credit;
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

  /// Génère le Bilan avec équilibre automatique Actif = Passif
  static Map<String, List<LigneBalance>> genererBilan(
      List<LigneBalance> balance) {
    final List<LigneBalance> actif = [];
    final List<LigneBalance> passif = [];

    double totalProduits = 0.0;
    double totalCharges = 0.0;

    for (var ligne in balance) {
      int classe = int.tryParse(ligne.compteCode.substring(0, 1)) ?? 0;

      // Comptes de bilan (1 à 5)
      if ([2, 3, 5].contains(classe) ||
          (classe == 4 && ligne.soldeDebiteur > 0)) {
        actif.add(ligne);
      } else if ([1].contains(classe) ||
          (classe == 4 && ligne.soldeCrediteur > 0)) {
        passif.add(ligne);
      }
      // Comptes de gestion (6 & 7) pour calcul du résultat
      else if (classe == 6) {
        totalCharges += ligne.soldeDebiteur;
      } else if (classe == 7) {
        totalProduits += ligne.soldeCrediteur;
      }
    }

    // Intégration du Résultat (Compte 120000) dans les Capitaux Propres
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