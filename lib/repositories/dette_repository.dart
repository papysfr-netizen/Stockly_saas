import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/compta_service.dart';

class DetteRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Isolation Multi-Tenant : /organizations/{orgId}
  DocumentReference _orgRef(String orgId) {
    return _firestore.collection('organizations').doc(orgId);
  }

  CollectionReference _dettesRef(String orgId) {
    return _orgRef(orgId).collection('dettes');
  }

  /// Enregistre une dette/créance indépendante avec écriture comptable atomique (WriteBatch)
  Future<void> ajouterDette({
    required String entrepriseId,
    required String nomPartenaire,
    required double montant,
    required bool isClient, // true = Créance Client, false = Dette Fournisseur
    required String userId,
    String? note,
  }) async {
    if (entrepriseId.isEmpty || montant <= 0) return;

    final batch = _firestore.batch();
    final detteRef = _dettesRef(entrepriseId).doc();

    // 1. Document Dette / Créance sous /organizations/{orgId}/dettes
    batch.set(detteRef, {
      'id': detteRef.id,
      'entrepriseId': entrepriseId,
      'nom': nomPartenaire,
      'montantInitial': montant,
      'montantRestant': montant,
      'type': isClient ? 'CLIENT' : 'FOURNISSEUR',
      'note': note ?? '',
      'comptabilise': true,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': userId,
    });

    // 2. Écriture comptable automatique (SYSCOHADA)
    if (isClient) {
      // CREANCE CLIENT : Débit Client (411000) / Crédit Ventes (701000)
      ComptaService.ajouterEcritureDansBatch(
        batch: batch,
        entrepriseId: entrepriseId,
        libelle: 'Créance Client : $nomPartenaire',
        compteDebit: '411000',  // Clients / Créances
        compteCredit: '701000', // Ventes de marchandises
        montant: montant,
        date: DateTime.now(),
        pieceRef: detteRef.id,
        userId: userId,
      );
    } else {
      // DETTE FOURNISSEUR : Débit Achats (601000) / Crédit Fournisseur (401000)
      ComptaService.ajouterEcritureDansBatch(
        batch: batch,
        entrepriseId: entrepriseId,
        libelle: 'Dette Fournisseur : $nomPartenaire',
        compteDebit: '601000',  // Achats de marchandises
        compteCredit: '401000', // Fournisseurs
        montant: montant,
        date: DateTime.now(),
        pieceRef: detteRef.id,
        userId: userId,
      );
    }

    // 3. Validation atomique (compatible offline)
    await batch.commit();
  }

  /// Règlement d'une dette fournisseur ou créance client autonome (Atomic WriteBatch)
  Future<void> reglerDetteAutonome({
    required String detteId,
    required String entrepriseId,
    required String nomPartenaire,
    required double montantRegle,
    required bool isClient,
    required String userId,
  }) async {
    if (entrepriseId.isEmpty || userId.isEmpty || montantRegle <= 0) return;

    final batch = _firestore.batch();
    final detteRef = _dettesRef(entrepriseId).doc(detteId);

    // 1. Mise à jour atomique du solde restant
    batch.update(detteRef, {
      'montantRestant': FieldValue.increment(-montantRegle),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': userId,
    });

    // 2. Écriture comptable de règlement intégrée au Batch
    if (isClient) {
      // Encaissement créance client : Débit Caisse (531000) / Crédit Client (411000)
      ComptaService.ajouterEcritureDansBatch(
        batch: batch,
        entrepriseId: entrepriseId,
        libelle: 'Encaissement créance : $nomPartenaire',
        compteDebit: '531000',
        compteCredit: '411000',
        montant: montantRegle,
        date: DateTime.now(),
        pieceRef: detteId,
        userId: userId,
      );
    } else {
      // Paiement dette fournisseur : Débit Fournisseur (401000) / Crédit Caisse (531000)
      ComptaService.ajouterEcritureDansBatch(
        batch: batch,
        entrepriseId: entrepriseId,
        libelle: 'Paiement fournisseur : $nomPartenaire',
        compteDebit: '401000',
        compteCredit: '531000',
        montant: montantRegle,
        date: DateTime.now(),
        pieceRef: detteId,
        userId: userId,
      );
    }

    await batch.commit();
  }

  /// Ecoute en temps réel des dettes/créances de l'organisation
  Stream<List<Map<String, dynamic>>> getDettesStream(String entrepriseId) {
    if (entrepriseId.isEmpty) return Stream.value([]);

    return _dettesRef(entrepriseId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList());
  }
}