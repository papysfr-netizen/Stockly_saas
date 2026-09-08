import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';

import '../models/dette.dart';
import '../models/journal_entry.dart';
import '../models/payment_method.dart';
import '../services/accounting_journal_service.dart';

// ============================================================================
// PROVIDERS RIVERPOD
// ============================================================================

/// Flux temps réel combinant 'creances' (clients) et 'dettes' (fournisseurs)
final dettesStreamProvider =
    StreamProvider.family<List<Dette>, String>((ref, entrepriseId) {
  if (entrepriseId.isEmpty) return Stream.value([]);

  final db = FirebaseFirestore.instance;

  // Stream 1 : Créances clients
  final creancesStream = db
      .collection('entreprises')
      .doc(entrepriseId)
      .collection('creances')
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => Dette.fromDocument(doc))
          .toList());

  // Stream 2 : Dettes fournisseurs
  final dettesStream = db
      .collection('entreprises')
      .doc(entrepriseId)
      .collection('dettes')
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => Dette.fromDocument(doc))
          .toList());

  // Fusion des deux collections et tri dynamique par date de création décroissante
  return Rx.combineLatest2<List<Dette>, List<Dette>, List<Dette>>(
    creancesStream,
    dettesStream,
    (creances, dettes) {
      final combined = [...creances, ...dettes];
      combined.sort((a, b) => b.dateCreation.compareTo(a.dateCreation));
      return combined;
    },
  );
});

/// Controller gérant les mutations de dettes/créances et la synchronisation comptable
final debtControllerProvider =
    AsyncNotifierProvider.family<DebtController, void, String>(
  DebtController.new,
);

// ============================================================================
// DEBT CONTROLLER (FamilyAsyncNotifier)
// ============================================================================

class DebtController extends FamilyAsyncNotifier<void, String> {
  @override
  Future<void> build(String arg) async {}

  /// Sélectionne la bonne sous-collection selon le type (creances vs dettes)
  CollectionReference _getTargetRef(String entrepriseId, TypeDette type) {
    final collectionName = type == TypeDette.client ? 'creances' : 'dettes';
    return FirebaseFirestore.instance
        .collection('entreprises')
        .doc(entrepriseId)
        .collection(collectionName);
  }

  CollectionReference _ecrituresRef(String entrepriseId) {
    return FirebaseFirestore.instance
        .collection('entreprises')
        .doc(entrepriseId)
        .collection('ecritures_comptables');
  }

  /// Ajoute une nouvelle dette/créance avec écritures comptables d'engagement et d'acompte
  Future<void> ajouterDette({
    required String nomTiers,
    required String numeroFacture,
    required double montantTotal,
    required double acompte,
    required TypeDette type,
    required String note,
    DateTime? dateEcheance,
    PaymentMethod paymentMethod = PaymentMethod.cash,
  }) async {
    final entrepriseId = arg;
    if (entrepriseId.isEmpty || montantTotal <= 0) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final db = FirebaseFirestore.instance;
      final batch = db.batch();
      final targetRef = _getTargetRef(entrepriseId, type).doc();
      final now = DateTime.now();

      final double pureAcompte = acompte > montantTotal ? montantTotal : (acompte < 0 ? 0.0 : acompte);
      final double montantReste = montantTotal - pureAcompte;

      String statutInitial = 'non_paye';
      if (montantReste <= 0) {
        statutInitial = 'paye';
      } else if (pureAcompte > 0) {
        statutInitial = 'partiel';
      }

      final bool isClient = type == TypeDette.client;

      // 1. Enregistrement du document Dette/Créance
      final dette = Dette(
        id: targetRef.id,
        nomTiers: nomTiers,
        numeroFacture: numeroFacture,
        montantInitial: montantTotal,
        acomptePaye: pureAcompte,
        montantReste: montantReste < 0 ? 0.0 : montantReste,
        type: type,
        statut: statutInitial,
        note: note,
        dateCreation: now,
        dateEcheance: dateEcheance,
        entrepriseId: entrepriseId,
        comptabilise: true,
      );

      batch.set(targetRef, dette.toFirestore());

      // 2. Écriture d'engagement comptable (SYSCOHADA)
      final ecritureEngagementRef = _ecrituresRef(entrepriseId).doc();
      final String codeDebit = isClient ? '411000' : '601000';
      final String codeCredit = isClient ? '701000' : '401000';

      final String labelDebit = isClient
          ? 'Clients - $nomTiers'
          : AccountingJournalService.getAccountLabel('601000');
      final String labelCredit = isClient
          ? AccountingJournalService.getAccountLabel('701000')
          : 'Fournisseurs - $nomTiers';

      final engagementEntry = JournalEntry(
        id: ecritureEngagementRef.id,
        entrepriseId: entrepriseId,
        date: now,
        reference: targetRef.id,
        description: isClient
            ? 'Créance Client : $nomTiers'
            : 'Dette Fournisseur : $nomTiers',
        lines: [
          JournalLine(
            accountCode: codeDebit,
            accountLabel: labelDebit,
            debit: montantTotal,
            credit: 0.0,
          ),
          JournalLine(
            accountCode: codeCredit,
            accountLabel: labelCredit,
            debit: 0.0,
            credit: montantTotal,
          ),
        ],
      );

      batch.set(ecritureEngagementRef, engagementEntry.toFirestore());

      // 3. Écriture d'acompte comptable (si versé à la création)
      if (pureAcompte > 0) {
        final ecritureAcompteRef = _ecrituresRef(entrepriseId).doc();
        final String codeTresorerie =
            AccountingJournalService.getAccountCodeForPayment(paymentMethod);

        final String acompteDebit = isClient ? codeTresorerie : '401000';
        final String acompteCredit = isClient ? '411000' : codeTresorerie;

        final String acompteDebitLabel = isClient
            ? AccountingJournalService.getAccountLabel(codeTresorerie)
            : 'Fournisseurs - $nomTiers';
        final String acompteCreditLabel = isClient
            ? 'Clients - $nomTiers'
            : AccountingJournalService.getAccountLabel(codeTresorerie);

        final acompteEntry = JournalEntry(
          id: ecritureAcompteRef.id,
          entrepriseId: entrepriseId,
          date: now,
          reference: targetRef.id,
          description: isClient
              ? 'Acompte créance client : $nomTiers'
              : 'Acompte dette fournisseur : $nomTiers',
          lines: [
            JournalLine(
              accountCode: acompteDebit,
              accountLabel: acompteDebitLabel,
              debit: pureAcompte,
              credit: 0.0,
            ),
            JournalLine(
              accountCode: acompteCredit,
              accountLabel: acompteCreditLabel,
              debit: 0.0,
              credit: pureAcompte,
            ),
          ],
          montantEncaisse: isClient ? pureAcompte : 0.0,
        );

        batch.set(ecritureAcompteRef, acompteEntry.toFirestore());
      }

      await batch.commit();
    });
  }

  /// Enregistre un règlement partiel ou solde complet
  Future<void> enregistrerPaiement({
    required String detteId,
    required double montantPaye,
    PaymentMethod paymentMethod = PaymentMethod.cash,
  }) async {
    final entrepriseId = arg;
    if (entrepriseId.isEmpty || detteId.isEmpty || montantPaye <= 0) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final db = FirebaseFirestore.instance;

      // 1. Recherche du document dans 'creances' puis 'dettes'
      DocumentReference docRef = db
          .collection('entreprises')
          .doc(entrepriseId)
          .collection('creances')
          .doc(detteId);

      DocumentSnapshot snapshot = await docRef.get();
      if (!snapshot.exists) {
        docRef = db
            .collection('entreprises')
            .doc(entrepriseId)
            .collection('dettes')
            .doc(detteId);
        snapshot = await docRef.get();
      }

      if (!snapshot.exists) {
        throw Exception('Dette ou Créance introuvable dans Firestore.');
      }

      final dette = Dette.fromDocument(snapshot);
      final bool isClient = dette.type == TypeDette.client;

      // Détermination du montant effectif pour éviter le solde négatif
      final double montantEffectif =
          montantPaye > dette.montantReste ? dette.montantReste : montantPaye;
      final double nouveauReste = dette.montantReste - montantEffectif;
      final String nouveauStatut = nouveauReste <= 0 ? 'paye' : 'partiel';
      final double acompteCumule = dette.acomptePaye + montantEffectif;
      final DateTime now = DateTime.now();

      final batch = db.batch();

      // Mise à jour de la dette / créance
      batch.update(docRef, {
        'montantReste': nouveauReste < 0 ? 0.0 : nouveauReste,
        'montantRestant': nouveauReste < 0 ? 0.0 : nouveauReste,
        'acomptePaye': acompteCumule,
        'statut': nouveauStatut,
        'dernierPaiement': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2. Écriture comptable du règlement
      final ecritureRef = _ecrituresRef(entrepriseId).doc();
      final String codeTresorerie =
          AccountingJournalService.getAccountCodeForPayment(paymentMethod);

      final String debitCode = isClient ? codeTresorerie : '401000';
      final String creditCode = isClient ? '411000' : codeTresorerie;

      final journalEntry = JournalEntry(
        id: ecritureRef.id,
        entrepriseId: entrepriseId,
        date: now,
        reference: detteId,
        description: isClient
            ? 'Règlement créance client : ${dette.nomTiers}'
            : 'Règlement dette fournisseur : ${dette.nomTiers}',
        lines: [
          JournalLine(
            accountCode: debitCode,
            accountLabel: isClient
                ? AccountingJournalService.getAccountLabel(codeTresorerie)
                : 'Fournisseurs - ${dette.nomTiers}',
            debit: montantEffectif,
            credit: 0.0,
          ),
          JournalLine(
            accountCode: creditCode,
            accountLabel: isClient
                ? 'Clients - ${dette.nomTiers}'
                : AccountingJournalService.getAccountLabel(codeTresorerie),
            debit: 0.0,
            credit: montantEffectif,
          ),
        ],
        montantEncaisse: isClient ? montantEffectif : 0.0,
      );

      batch.set(ecritureRef, journalEntry.toFirestore());

      await batch.commit();
    });
  }
}