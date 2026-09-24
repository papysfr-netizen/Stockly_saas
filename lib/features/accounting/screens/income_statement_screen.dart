// lib/features/accounting/screens/income_statement_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:stockly_saas/core/providers/journal_provider.dart';
import 'package:stockly_saas/core/services/accounting_report_service.dart';

class IncomeStatementScreen extends ConsumerStatefulWidget {
  final String entrepriseId;

  const IncomeStatementScreen({
    super.key,
    required this.entrepriseId,
  });

  @override
  ConsumerState<IncomeStatementScreen> createState() => _IncomeStatementScreenState();
}

class _IncomeStatementScreenState extends ConsumerState<IncomeStatementScreen> {
  int _selectedPeriodeIndex = 0;
  DateTime? _customSelectedDate;

  List<Map<String, dynamic>> _getBeSoccerTabs() {
    final now = DateTime.now();
    final formatter = DateFormat('EEE. d MMM', 'fr_FR');

    List<Map<String, dynamic>> tabs = [
      {'label': 'AUJOURD\'HUI', 'type': 'Aujourd\'hui', 'date': now, 'isCalendar': false},
      {'label': 'HIER', 'type': 'Hier', 'date': now.subtract(const Duration(days: 1)), 'isCalendar': false},
    ];

    for (int i = 2; i <= 6; i++) {
      final date = now.subtract(Duration(days: i));
      tabs.add({
        'label': formatter.format(date).toUpperCase(),
        'type': 'DateSpecifique',
        'date': date,
        'isCalendar': false,
      });
    }

    final customLabel = _customSelectedDate != null
        ? DateFormat('dd/MM/yyyy').format(_customSelectedDate!)
        : '';

    tabs.add({
      'label': customLabel,
      'type': 'CustomDate',
      'date': _customSelectedDate,
      'isCalendar': true,
    });

    return tabs;
  }

  Future<void> _ouvrirDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _customSelectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1E293B),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customSelectedDate = picked;
        _selectedPeriodeIndex = 7;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Écoute directe du flux des écritures du journal pour cette entreprise
    const currencySymbol = 'USD';
    final currencyFormat = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: currencySymbol,
      decimalDigits: 2,
    );

    final entriesAsync = ref.watch(journalEntriesStreamProvider(widget.entrepriseId));

    final tabs = _getBeSoccerTabs();
    if (_selectedPeriodeIndex >= tabs.length) {
      _selectedPeriodeIndex = 0;
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Compte de Résultat',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('Erreur de chargement : $err', style: const TextStyle(color: Colors.red)),
        ),
        data: (entries) {
          // Utilisation du service robuste SYSCOHADA
          final report = AccountingReportService.calculateIncomeStatement(entries);
          
          final charges = report.charges;
          final produits = report.produits;
          final totalCharges = report.totalCharges;
          final totalProduits = report.totalProduits;
          final resultatNet = report.resultatNet;
          final isBenefice = report.isBenefice;

          return SingleChildScrollView(
            child: Column(
              children: [
                // ================= BARRE DES ONGLETS TEMPORELS =================
                Container(
                  color: const Color(0xFF1E293B),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: tabs.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final item = tabs[index];
                        final isSelected = _selectedPeriodeIndex == index;
                        final isCalendar = item['isCalendar'] as bool;
                        final hasLabel = (item['label'] as String).isNotEmpty;

                        return InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            if (isCalendar) {
                              _ouvrirDatePicker();
                            } else {
                              setState(() {
                                _selectedPeriodeIndex = index;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.orange.shade800 : Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                if (isCalendar) ...[
                                  const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 16),
                                  if (hasLabel) const SizedBox(width: 6),
                                ],
                                if (hasLabel)
                                  Text(
                                    item['label'],
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // ================= CARTE DE RÉSUMÉ PRINCIPALE (BANDEAU ORANGE VIF) =================
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'RÉSULTAT NET (BÉNÉFICE NET)',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade800,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.white24,
                                radius: 18,
                                child: Icon(
                                  isBenefice ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      currencyFormat.format(resultatNet.abs()),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      isBenefice ? 'Votre entreprise est bénéficiaire !' : 'Votre entreprise est déficitaire',
                                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ================= ANALYSE DÉTAILLÉE (P&L) =================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(
                            'Analyse Détaillée (P&L)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        _buildPLTile(
                          icon: Icons.storefront_rounded,
                          iconColor: Colors.teal,
                          title: 'Chiffre d\'Affaires (Produits)',
                          amount: currencyFormat.format(totalProduits),
                          amountColor: Colors.black87,
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        _buildPLTile(
                          icon: Icons.receipt_long_rounded,
                          iconColor: Colors.red.shade600,
                          title: 'Total Charges & Dépenses',
                          amount: '-${currencyFormat.format(totalCharges)}',
                          amountColor: Colors.red.shade700,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ================= LISTE DÉTAILLÉE DES COMPTES (SYSCOHADA) =================
                if (produits.isNotEmpty || charges.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Text(
                              'Détail des Postes Comptables',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          if (produits.isNotEmpty) ...[
                            _buildSectionHeader('PRODUITS (Classe 7)', Colors.green.shade800),
                            ...produits.map((b) => _buildRow(b.accountCode, b.accountLabel, b.netBalance.abs(), currencyFormat)),
                          ],
                          if (charges.isNotEmpty) ...[
                            _buildSectionHeader('CHARGES (Classe 6)', Colors.red.shade800),
                            ...charges.map((b) => _buildRow(b.accountCode, b.accountLabel, b.netBalance.abs(), currencyFormat)),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPLTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String amount,
    required Color amountColor,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: iconColor.withValues(alpha: 0.1),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
      ),
      trailing: Text(
        amount,
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: amountColor),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: color.withValues(alpha: 0.05),
      child: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13),
      ),
    );
  }

  Widget _buildRow(String code, String label, double amount, NumberFormat format) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      title: Text(
        '$code - $label',
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
      ),
      trailing: Text(
        format.format(amount),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: Color(0xFF1E293B),
        ),
      ),
    );
  }
}