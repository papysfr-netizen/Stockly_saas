// lib/features/debts/repositories/dette_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';

import 'package:stockly_saas/core/models/dette.dart';
import 'package:stockly_saas/features/accounting/models/journal_entry.dart';
import 'package:stockly_saas/features/accounting/services/accounting_journal_service.dart';

// ============================================================================
// PROVIDERS RIVERPOD
// ============================================================================

final detteRepositoryProvider = Provider<DetteRepository>((ref) {
  return DetteRepository();
});

/// StreamProvider utilisé directement par l'UI pour récupérer toutes les dettes/créances
final dettesStreamProvider =
    StreamProvider.family<List<Dette>, String>((ref, entrepriseId) {
  final repository = ref.watch(detteRepositoryProvider);
  return repository.getDettesStream(entrepriseId);
});

class DetteRepository {
  final FirebaseFirestore _firestore;

  DetteRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ============================================================================
  // REFERENCES COLLECTIONS
  // ============================================================================

  /// Cible dynamiquement la sous-collection appropriée ('creances' pour client, 'dettes' pour fournisseur)
  CollectionReference _getTargetRef(String entrepriseId, bool isClient) {
    final collectionName = isClient ? 'creances' : 'dettes';
    return _firestore
        .collection('entreprises')
        .doc(entrepriseId)
        .collection(collectionName);
  }

  /// Référence vers la collection des écritures comptables
  CollectionReference _ecrituresRef(String entrepriseId) {
    return _firestore
        .collection('entreprises')
        .doc(entrepriseId)
        .collection('ecritures_comptables');
  }

  // ============================================================================
  // CRÉATION & RÈGLEMENTS (WRITE BATCH)
  // ============================================================================

  /// Enregistre une dette ou créance autonome avec écriture comptable atomique en partie double
  Future<void> ajouterDette({
    required String entrepriseId,
    required String nomPartenaire,
    required double montant,
    required bool isClient,
    required String userId,
    String? numeroFacture,
    String? note,
    DateTime? dateEcheance,
  }) async {
    if (entrepriseId.isEmpty || montant <= 0) return;

    final batch = _firestore.batch();
    final detteRef = _getTargetRef(entrepriseId, isClient).doc();

    final dette = Dette(
      id: detteRef.id,
      nomTiers: nomPartenaire,
      numeroFacture: numeroFacture ?? '',
      montantInitial: montant,
      acomptePaye: 0.0,
      montantReste: montant,
      type: isClient ? TypeDette.client : TypeDette.fournisseur,
      statut: 'non_paye',
      note: note ?? '',
      dateCreation: DateTime.now(),
      dateEcheance: dateEcheance,
      entrepriseId: entrepriseId,
      comptabilise: true,
    );

    batch.set(detteRef, dette.toMap());

    // Écriture comptable SYSCOHADA (Partie Double)
    final ecritureRef = _ecrituresRef(entrepriseId).doc();
    final String debitCode = isClient ? '411000' : '601000';
    final String creditCode = isClient ? '701000' : '401000';

    final String debitLabel = isClient
        ? 'Clients - $nomPartenaire'
        : AccountingJournalService.getAccountLabel('601000');

    final String creditLabel = isClient
        ? AccountingJournalService.getAccountLabel('701000')
        : 'Fournisseurs - $nomPartenaire';

    final journalEntry = JournalEntry(
      id: ecritureRef.id,
      entrepriseId: entrepriseId,
      date: DateTime.now(),
      reference: detteRef.id,
      description: isClient
          ? 'Créance Client : $nomPartenaire'
          : 'Dette Fournisseur : $nomPartenaire',
      lines: [
        JournalLine(
          accountCode: debitCode,
          accountLabel: debitLabel,
          debit: montant,
          credit: 0.0,
        ),
        JournalLine(
          accountCode: creditCode,
          accountLabel: creditLabel,
          debit: 0.0,
          credit: montant,
        ),
      ],
    );

    batch.set(ecritureRef, journalEntry.toFirestore());

    await batch.commit();
  }

  /// Règlement autonome d'une dette ou créance avec mise à jour du statut, du dernier paiement et de la comptabilité
  Future<void> reglerDetteAutonome({
    required String detteId,
    required String entrepriseId,
    required String nomPartenaire,
    required double montantRegle,
    required double montantResteActuel,
    required bool isClient,
    required String userId,
    String compteTresorerie = '571000',
  }) async {
    if (entrepriseId.isEmpty || userId.isEmpty || montantRegle <= 0) return;

    final batch = _firestore.batch();
    final detteRef = _getTargetRef(entrepriseId, isClient).doc(detteId);

    final double montantEffectif =
        montantRegle > montantResteActuel ? montantResteActuel : montantRegle;
    final double nouveauReste = montantResteActuel - montantEffectif;
    final String nouveauStatut = nouveauReste <= 0 ? 'solde' : 'partiel';

    // 1. Mise à jour de la dette/créance avec enregistrement de la date du dernier paiement
    batch.update(detteRef, {
      'acomptePaye': FieldValue.increment(montantEffectif),
      'montantReste': nouveauReste < 0 ? 0.0 : nouveauReste,
      'statut': nouveauStatut,
      'dernierPaiement': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': userId,
    });

    // 2. Écriture comptable associée au règlement
    final ecritureRef = _ecrituresRef(entrepriseId).doc();
    final String debitCode = isClient ? compteTresorerie : '401000';
    final String creditCode = isClient ? '411000' : compteTresorerie;

    final String debitLabel = isClient
        ? AccountingJournalService.getAccountLabel(compteTresorerie)
        : 'Fournisseurs - $nomPartenaire';

    final String creditLabel = isClient
        ? 'Clients - $nomPartenaire'
        : AccountingJournalService.getAccountLabel(compteTresorerie);

    final journalEntry = JournalEntry(
      id: ecritureRef.id,
      entrepriseId: entrepriseId,
      date: DateTime.now(),
      reference: detteId,
      description: isClient
          ? 'Encaissement créance : $nomPartenaire'
          : 'Paiement fournisseur : $nomPartenaire',
      lines: [
        JournalLine(
          accountCode: debitCode,
          accountLabel: debitLabel,
          debit: montantEffectif,
          credit: 0.0,
        ),
        JournalLine(
          accountCode: creditCode,
          accountLabel: creditLabel,
          debit: 0.0,
          credit: montantEffectif,
        ),
      ],
      montantEncaisse: isClient ? montantEffectif : 0.0,
    );

    batch.set(ecritureRef, journalEntry.toFirestore());

    // 3. Validation atomique de l'ensemble de la transaction
    await batch.commit();
  }

  // ============================================================================
  // STREAMS & LECTURE
  // ============================================================================

  /// Stream unifié fusionnant les sous-collections 'creances' et 'dettes' en temps réel
  Stream<List<Dette>> getDettesStream(String entrepriseId) {
    if (entrepriseId.isEmpty) return Stream.value([]);

    final creancesStream = _getTargetRef(entrepriseId, true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => Dette.fromDocument(doc)).toList());

    final dettesStream = _getTargetRef(entrepriseId, false)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => Dette.fromDocument(doc)).toList());

    return Rx.combineLatest2<List<Dette>, List<Dette>, List<Dette>>(
      creancesStream,
      dettesStream,
      (creances, dettes) {
        final combined = [...creances, ...dettes];
        combined.sort((a, b) {
          final bDate = b.dateCreation;
          final aDate = a.dateCreation;
          return bDate.compareTo(aDate);
        });
        return combined;
      },
    );
  }

  /// Flux dédié uniquement aux CRÉANCES CLIENTS non réglées
  Stream<List<Dette>> streamCreancesClients(String entrepriseId) {
    if (entrepriseId.isEmpty) return Stream.value([]);

    return getDettesStream(entrepriseId).map((list) => list
        .where((dette) =>
            dette.type == TypeDette.client &&
            dette.montantReste > 0 &&
            dette.statut.toLowerCase() != 'paye' &&
            dette.statut.toLowerCase() != 'solde' &&
            dette.statut.toLowerCase() != 'annule')
        .toList());
  }

  /// Flux dédié uniquement aux DETTES FOURNISSEURS non réglées
  Stream<List<Dette>> streamDettesFournisseurs(String entrepriseId) {
    if (entrepriseId.isEmpty) return Stream.value([]);

    return getDettesStream(entrepriseId).map((list) => list
        .where((dette) =>
            dette.type == TypeDette.fournisseur &&
            dette.montantReste > 0 &&
            dette.statut.toLowerCase() != 'paye' &&
            dette.statut.toLowerCase() != 'solde' &&
            dette.statut.toLowerCase() != 'annule')
        .toList());
  }
}