import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stockly_saas/features/accounting/models/journal_entry.dart';
import 'package:stockly_saas/core/services/accounting_report_service.dart';

class ClosingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Exécute la clôture annuelle de l'exercice
  Future<void> executeFiscalYearClosing({
    required String entrepriseId,
    required List<JournalEntry> currentEntries,
    required int year,
  }) async {
    final balances = AccountingReportService.calculateTrialBalance(currentEntries);
    final batch = _firestore.batch();

    final List<JournalLine> closingLines = [];
    double totalCharges = 0.0;
    double totalProduits = 0.0;

    // 1. Solder la Classe 6 (Charges) et la Classe 7 (Produits)
    for (var b in balances) {
      if (b.accountCode.startsWith('6')) {
        final amount = b.netBalance.abs();
        totalCharges += amount;
        // Créditer la charge pour la remettre à zéro
        closingLines.add(
          JournalLine(
            accountCode: b.accountCode,
            accountLabel: b.accountLabel,
            debit: 0.0,
            credit: amount,
          ),
        );
      } else if (b.accountCode.startsWith('7')) {
        final amount = b.netBalance.abs();
        totalProduits += amount;
        // Débiter le produit pour le remettre à zéro
        closingLines.add(
          JournalLine(
            accountCode: b.accountCode,
            accountLabel: b.accountLabel,
            debit: amount,
            credit: 0.0,
          ),
        );
      }
    }

    final netResult = totalProduits - totalCharges;

    // 2. Affectation du résultat net au compte 13
    if (netResult >= 0) {
      // Bénéfice (Compte 131000) -> Crédit
      closingLines.add(
        JournalLine(
          accountCode: '131000',
          accountLabel: 'Résultat net de l\'exercice (Bénéfice)',
          debit: 0.0,
          credit: netResult,
        ),
      );
    } else {
      // Perte (Compte 139000) -> Débit
      closingLines.add(
        JournalLine(
          accountCode: '139000',
          accountLabel: 'Résultat net de l\'exercice (Perte)',
          debit: netResult.abs(),
          credit: 0.0,
        ),
      );
    }

    final closingEntry = JournalEntry(
      id: 'JE-CLOTURE-$year',
      entrepriseId: entrepriseId,
      date: DateTime(year, 12, 31, 23, 59),
      reference: 'CLOTURE-$year',
      description: 'Clôture et solder des comptes de gestion de l\'exercice $year',
      lines: closingLines,
    );

    // 3. Écriture dans Firestore
    final docRef = _firestore
        .collection('entreprises')
        .doc(entrepriseId)
        .collection('ecritures_comptables')
        .doc(closingEntry.id);

    batch.set(docRef, closingEntry.toFirestore());

    await batch.commit();
  }
}