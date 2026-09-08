// lib/screens/income_statement_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/journal_provider.dart';

class IncomeStatementScreen extends ConsumerWidget {
  final String entrepriseId;

  const IncomeStatementScreen({
    super.key,
    required this.entrepriseId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trialBalance = ref.watch(trialBalanceProvider(entrepriseId));
    final currencyFormat = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'FCFA',
      decimalDigits: 2,
    );

    // Filtrage des comptes SYSCOHADA (Classe 6 = Charges, Classe 7 = Produits)
    final charges =
        trialBalance.where((b) => b.accountCode.startsWith('6')).toList();
    final produits =
        trialBalance.where((b) => b.accountCode.startsWith('7')).toList();

    // Calculs des Totaux Globaux
    final totalCharges = charges.fold<double>(
        0.0, (sum, b) => sum + b.netBalance.abs());
    final totalProduits = produits.fold<double>(
        0.0, (sum, b) => sum + b.netBalance.abs());
    final resultatNet = totalProduits - totalCharges;
    final isBenefice = resultatNet >= 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compte de Résultat (SYSCOHADA)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Carte de Résultat Net (Bénéfice / Perte)
            Card(
              elevation: 2,
              color: isBenefice ? Colors.green.shade50 : Colors.red.shade50,
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  color: isBenefice ? Colors.green : Colors.red,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isBenefice ? 'BÉNÉFICE NET' : 'PERTE NETTE',
                          style: TextStyle(
                            color: isBenefice
                                ? Colors.green.shade900
                                : Colors.red.shade900,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currencyFormat.format(resultatNet.abs()),
                          style: TextStyle(
                            color: isBenefice
                                ? Colors.green.shade800
                                : Colors.red.shade800,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      isBenefice ? Icons.trending_up : Icons.trending_down,
                      size: 40,
                      color: isBenefice ? Colors.green : Colors.red,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Section Produits (Classe 7)
            _buildSectionHeader(
              'PRODUITS (Ventes & Revenus - Classe 7)',
              Colors.green.shade800,
              currencyFormat.format(totalProduits),
            ),
            const SizedBox(height: 8),
            if (produits.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Aucun produit enregistré.',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ...produits.map(
                (b) => _buildRow(
                  b.accountCode,
                  b.accountLabel,
                  b.netBalance.abs(),
                  currencyFormat,
                ),
              ),

            const SizedBox(height: 24),

            // Section Charges (Classe 6)
            _buildSectionHeader(
              'CHARGES (Achats & Dépenses - Classe 6)',
              Colors.red.shade800,
              currencyFormat.format(totalCharges),
            ),
            const SizedBox(height: 8),
            if (charges.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Aucune charge enregistrée.',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ...charges.map(
                (b) => _buildRow(
                  b.accountCode,
                  b.accountLabel,
                  b.netBalance.abs(),
                  currencyFormat,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color, String total) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            total,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(
      String code, String label, double amount, NumberFormat format) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 0.8),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '$code - $label',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            format.format(amount),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}