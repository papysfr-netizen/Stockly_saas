// lib/providers/comptabilite_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/journal_entry.dart';
import '../services/accounting_journal_service.dart';

/// Provider d'accès au service comptable
final accountingJournalServiceProvider = Provider<AccountingJournalService>((ref) {
  return AccountingJournalService();
});

/// Flux en temps réel de toutes les écritures du journal
final journalEcrituresStreamProvider =
    StreamProvider.family<List<JournalEntry>, String>((ref, entrepriseId) {
  final service = ref.watch(accountingJournalServiceProvider);
  return service.streamEcritures(entrepriseId);
});

/// Modèle d'état pour le résumé financier (P&L + Bilan)
class FinancialSummaryState {
  final double chiffreAffaires;
  final double totalCharges;
  final double resultatNet;
  final double soldeTresorerie;
  final double totalCreancesClients;
  final double totalDettesFournisseurs;

  const FinancialSummaryState({
    this.chiffreAffaires = 0.0,
    this.totalCharges = 0.0,
    this.resultatNet = 0.0,
    this.soldeTresorerie = 0.0,
    this.totalCreancesClients = 0.0,
    this.totalDettesFournisseurs = 0.0,
  });

  factory FinancialSummaryState.fromEntries(List<JournalEntry> entries) {
    double ca = 0.0;
    double charges = 0.0;
    double tresorerie = 0.0;
    double creances = 0.0;
    double dettes = 0.0;

    for (var entry in entries) {
      for (var line in entry.lines) {
        final code = line.accountCode;

        // Classe 7 : Produits / Chiffre d'Affaires
        if (code.startsWith('7')) {
          ca += (line.credit - line.debit);
        }
        // Classe 6 : Charges (Achats, Transports, Variations de stock)
        else if (code.startsWith('6')) {
          charges += (line.debit - line.credit);
        }
        // Classe 5 : Trésorerie (Caisse 571, Banque 521, Mobile Money 572)
        else if (code.startsWith('5')) {
          tresorerie += (line.debit - line.credit);
        }
        // Compte 411 : Créances Clients
        else if (code.startsWith('411')) {
          creances += (line.debit - line.credit);
        }
        // Compte 401 : Dettes Fournisseurs
        else if (code.startsWith('401')) {
          dettes += (line.credit - line.debit);
        }
      }
    }

    return FinancialSummaryState(
      chiffreAffaires: ca,
      totalCharges: charges,
      resultatNet: ca - charges,
      soldeTresorerie: tresorerie,
      totalCreancesClients: creances,
      totalDettesFournisseurs: dettes,
    );
  }
}

/// Provider calculant le résumé financier en direct
final financialSummaryProvider =
    Provider.family<FinancialSummaryState, String>((ref, entrepriseId) {
  final asyncEntries = ref.watch(journalEcrituresStreamProvider(entrepriseId));

  return asyncEntries.when(
    data: (entries) => FinancialSummaryState.fromEntries(entries),
    loading: () => const FinancialSummaryState(),
    error: (_, __) => const FinancialSummaryState(),
  );
});