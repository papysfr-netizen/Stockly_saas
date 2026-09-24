// lib/screens/balance_sheet_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/providers/journal_provider.dart';
import '../core/providers/currency_provider.dart';
import '../core/services/accounting_report_service.dart';

class BalanceSheetScreen extends ConsumerWidget {
  final String entrepriseId;

  const BalanceSheetScreen({
    super.key,
    required this.entrepriseId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trialBalance = ref.watch(trialBalanceProvider(entrepriseId));
    
    // Récupération propre et dynamique de la devise active avec .toString()
    final currencyCode = ref.watch(currencyProvider).toString();
    final currencyFormat = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: currencyCode,
      decimalDigits: 2,
    );

    // Filtrage des comptes de Bilan (Classes 1 à 5)
    final actifImmobilise =
        trialBalance.where((b) => b.accountCode.startsWith('2')).toList();
    final actifCirculant = trialBalance
        .where((b) =>
            b.accountCode.startsWith('3') || b.accountCode.startsWith('41'))
        .toList();
    final tresorerieActif = trialBalance
        .where((b) => b.accountCode.startsWith('5') && b.netBalance > 0)
        .toList();

    final capitauxPropres =
        trialBalance.where((b) => b.accountCode.startsWith('1')).toList();
    final dettesFournisseurs = trialBalance
        .where((b) =>
            b.accountCode.startsWith('40') ||
            b.accountCode.startsWith('42') ||
            b.accountCode.startsWith('43') ||
            b.accountCode.startsWith('44'))
        .toList();
    final tresoreriePassif = trialBalance
        .where((b) => b.accountCode.startsWith('5') && b.netBalance < 0)
        .toList();

    // Calculs des totaux
    final totalActifImm = actifImmobilise.fold<double>(
        0.0, (sum, b) => sum + (b.netBalance > 0 ? b.netBalance : 0.0));
    final totalActifCirc = actifCirculant.fold<double>(
        0.0, (sum, b) => sum + (b.netBalance > 0 ? b.netBalance : 0.0));
    final totalTresorActif =
        tresorerieActif.fold<double>(0.0, (sum, b) => sum + b.netBalance);
    final totalActif = totalActifImm + totalActifCirc + totalTresorActif;

    final totalCapitaux = capitauxPropres.fold<double>(
        0.0, (sum, b) => sum + b.netBalance.abs());
    final totalDettes = dettesFournisseurs.fold<double>(
        0.0, (sum, b) => sum + b.netBalance.abs());
    final totalTresorPassif = tresoreriePassif.fold<double>(
        0.0, (sum, b) => sum + b.netBalance.abs());
    final totalPassif = totalCapitaux + totalDettes + totalTresorPassif;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Bilan Comptable (SYSCOHADA)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Actif
            _buildSectionCard(
              title: 'ACTIF (Emplois)',
              color: Colors.teal.shade800,
              total: totalActif,
              format: currencyFormat,
              children: [
                _buildSubCategory(
                    'Actif Immobilisé (Classe 2)', actifImmobilise, currencyFormat),
                _buildSubCategory(
                    'Actif Circulant - Stocks & Créances (Classes 3 & 4)',
                    actifCirculant,
                    currencyFormat),
                _buildSubCategory(
                    'Trésorerie-Actif (Banque/Caisse)', tresorerieActif, currencyFormat),
              ],
            ),
            const SizedBox(height: 20),

            // Passif
            _buildSectionCard(
              title: 'PASSIF (Ressources)',
              color: Colors.orange.shade800,
              total: totalPassif,
              format: currencyFormat,
              children: [
                _buildSubCategory(
                    'Capitaux Propres & Ressources Durables (Classe 1)',
                    capitauxPropres,
                    currencyFormat),
                _buildSubCategory(
                    'Passif Circulant - Dettes (Classe 4)',
                    dettesFournisseurs,
                    currencyFormat),
                _buildSubCategory(
                    'Trésorerie-Passif (Découverts)', tresoreriePassif, currencyFormat),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Color color,
    required double total,
    required NumberFormat format,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
                Text(
                  format.format(total),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildSubCategory(
      String label, List<AccountBalance> accounts, NumberFormat format) {
    if (accounts.isEmpty) return const SizedBox.shrink();
    return ExpansionTile(
      title: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1E293B)),
      ),
      children: accounts.map((b) {
        return ListTile(
          dense: true,
          title: Text('${b.accountCode} - ${b.accountLabel}', style: const TextStyle(fontSize: 13)),
          trailing: Text(format.format(b.netBalance.abs()), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        );
      }).toList(),
    );
  }
}