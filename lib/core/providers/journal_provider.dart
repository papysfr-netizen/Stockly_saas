import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stockly_saas/features/accounting/models/journal_entry.dart';
import 'package:stockly_saas/features/accounting/services/accounting_journal_service.dart';
import '../services/accounting_report_service.dart';

/// Provider du service comptable
final accountingJournalServiceProvider = Provider<AccountingJournalService>((ref) {
  return AccountingJournalService();
});

/// StreamProvider pour écouter le journal en temps réel par entreprise
final journalEntriesStreamProvider = StreamProvider.family<List<JournalEntry>, String>((ref, entrepriseId) {
  final service = ref.watch(accountingJournalServiceProvider);
  return service.streamEcritures(entrepriseId);
});

/// Provider de la Balance des comptes (prend un String entrepriseId pour compatibilité globale)
final trialBalanceProvider = Provider.family<List<AccountBalance>, String>((ref, entrepriseId) {
  final entriesAsync = ref.watch(journalEntriesStreamProvider(entrepriseId));
  return entriesAsync.when(
    data: (entries) => AccountingReportService.calculateTrialBalance(entries),
    loading: () => [],
    error: (_, __) => [],
  );
});