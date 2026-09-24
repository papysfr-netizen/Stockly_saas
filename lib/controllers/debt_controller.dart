import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';

import 'package:stockly_saas/core/models/dette.dart';
import 'package:stockly_saas/features/accounting/models/journal_entry.dart';
import '../core/models/payment_method.dart';
import '../core/services/accounting_journal_service.dart';

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

  // Fusion et tri dynamique sécurisé contre les valeurs nulles
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

  /// Arrondi financier à 2 décimales pour éviter les imprécisions de calcul des doubles
  double _roundMoney(double value) => (value * 100).roundToDouble() / 100;

  /// Sélectionne la collection cible selon le type
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

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      if (entrepriseId.isEmpty) {
        throw ArgumentError("L'identifiant de l'entreprise est manquant.");
      }
      if (montantTotal <= 0) {
        throw ArgumentError('Le montant total doit être supérieur à zéro.');
      }

      final db = FirebaseFirestore.instance;
      final batch = db.batch();
      final targetRef = _getTargetRef(entrepriseId, type).doc();
      final now = DateTime.now();

      final double totalArrondi = _roundMoney(montantTotal);
      final double pureAcompte = _roundMoney(
        acompte > totalArrondi ? totalArrondi : (acompte < 0 ? 0.0 : acompte),
      );
      final double montantReste = _roundMoney(totalArrondi - pureAcompte);

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
        montantInitial: totalArrondi,
        acomptePaye: pureAcompte,
        montantReste: montantReste,
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
            debit: totalArrondi,
            credit: 0.0,
          ),
          JournalLine(
            accountCode: codeCredit,
            accountLabel: labelCredit,
            debit: 0.0,
            credit: totalArrondi,
          ),
        ],
      );

      batch.set(ecritureEngagementRef, engagementEntry.toFirestore());

      // 3. Écriture d'acompte comptable (si versé immédiatement)
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

  /// Enregistre un règlement partiel ou total de manière atomique (Transaction)
  Future<void> enregistrerPaiement({
    required String detteId,
    required double montantPaye,
    TypeDette? type,
    PaymentMethod paymentMethod = PaymentMethod.cash,
  }) async {
    final entrepriseId = arg;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      if (entrepriseId.isEmpty || detteId.isEmpty) {
        throw ArgumentError("Paramètres d'identification invalides.");
      }
      if (montantPaye <= 0) {
        throw ArgumentError('Le montant payé doit être strictement positif.');
      }

      final db = FirebaseFirestore.instance;

      // 1. Résolution de la référence de document si le type n'est pas fourni
      DocumentReference docRef;
      if (type != null) {
        docRef = _getTargetRef(entrepriseId, type).doc(detteId);
      } else {
        final creanceRef = _getTargetRef(entrepriseId, TypeDette.client).doc(detteId);
        final creanceSnap = await creanceRef.get();
        if (creanceSnap.exists) {
          docRef = creanceRef;
        } else {
          docRef = _getTargetRef(entrepriseId, TypeDette.fournisseur).doc(detteId);
        }
      }

      // 2. Transaction Firestore : atomicité des calculs de solde et de l'écriture
      await db.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          throw StateError('Dette ou Créance introuvable dans Firestore.');
        }

        final dette = Dette.fromDocument(snapshot);

        if (dette.montantReste <= 0) {
          throw StateError('Cette créance/dette est déjà entièrement soldée.');
        }

        // Calcul du montant effectif plafonné au restant dû
        final double montantEffectif = _roundMoney(
          montantPaye > dette.montantReste ? dette.montantReste : montantPaye,
        );
        final double nouveauReste = _roundMoney(dette.montantReste - montantEffectif);
        final double acompteCumule = _roundMoney(dette.acomptePaye + montantEffectif);
        final String nouveauStatut = nouveauReste <= 0 ? 'paye' : 'partiel';
        final now = DateTime.now();
        final bool isClient = dette.type == TypeDette.client;

        // Mise à jour de la dette / créance
        transaction.update(docRef, {
          'montantReste': nouveauReste,
          'montantRestant': nouveauReste, // Compatibilité schémas
          'acomptePaye': acompteCumule,
          'statut': nouveauStatut,
          'dernierPaiement': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // 3. Écriture comptable du règlement
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

        transaction.set(ecritureRef, journalEntry.toFirestore());
      });
    });
  }
}