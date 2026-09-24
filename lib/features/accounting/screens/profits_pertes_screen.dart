// lib/features/accounting/screens/profits_pertes_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:stockly_saas/core/providers/currency_provider.dart';
import 'package:stockly_saas/core/providers/auth_provider.dart';
import 'package:stockly_saas/core/providers/journal_provider.dart';
import 'package:stockly_saas/core/services/report_export_service.dart';
import 'package:stockly_saas/core/services/accounting_report_service.dart';

class ProfitsPertesScreen extends ConsumerWidget {
  const ProfitsPertesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Récupération sécurisée de l'ID de l'entreprise via le profil authentifié
    final authState = ref.watch(authProvider);
    final String entrepriseId = authState.user?.uid ?? '';
    
    // Récupération propre de la devise active avec .toString()
    final currencyCode = ref.watch(currencyProvider).toString();
    final currencyFormat = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: currencyCode,
      decimalDigits: 2,
    );

    if (entrepriseId.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          title: const Text("Compte de Résultat (P&L)"),
          backgroundColor: const Color(0xFF1E293B),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text("Aucune entreprise sélectionnée."),
        ),
      );
    }

    // Écoute du journal comptable en temps réel pour l'entreprise
    final entriesAsync = ref.watch(journalEntriesStreamProvider(entrepriseId));

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          "Compte de Résultat (P&L)",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          entriesAsync.maybeWhen(
            data: (entries) {
              final report = AccountingReportService.calculateIncomeStatement(entries);
              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                tooltip: 'Options d\'export',
                onSelected: (value) {
                  final enTetes = ["Poste Financier", "Montant"];
                  final lignes = [
                    ["Chiffre d'Affaires (Produits - Cl. 7)", currencyFormat.format(report.totalProduits)],
                    ["Total Charges (Cl. 6)", "-${currencyFormat.format(report.totalCharges)}"],
                    ["Résultat Net", currencyFormat.format(report.resultatNet)],
                  ];

                  if (value == 'pdf') {
                    ReportExportService.exporterPDF(
                      titreRapport: "Compte de Résultat - P&L",
                      enTetes: enTetes,
                      lignes: lignes,
                    );
                  } else if (value == 'excel') {
                    ReportExportService.exporterExcel(
                      titreRapport: "Compte_de_Resultat_PL",
                      enTetes: enTetes,
                      lignes: lignes,
                    );
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'pdf',
                    child: Row(
                      children: [
                        Icon(Icons.picture_as_pdf, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Exporter en PDF'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'excel',
                    child: Row(
                      children: [
                        Icon(Icons.table_chart, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Exporter vers Excel'),
                      ],
                    ),
                  ),
                ],
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text("Erreur de chargement : $err", style: const TextStyle(color: Colors.red)),
        ),
        data: (entries) {
          // Utilisation du service de calcul SYSCOHADA robuste
          final report = AccountingReportService.calculateIncomeStatement(entries);
          
          final totalProduits = report.totalProduits;
          final totalCharges = report.totalCharges;
          final resultatNet = report.resultatNet;
          final isBenefice = report.isBenefice;
          final produits = report.produits;
          final charges = report.charges;

          return SingleChildScrollView(
            child: Column(
              children: [
                // ================= CARTE DE RÉSUMÉ (BANDEAU ORANGE VIF) =================
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
                          isBenefice ? 'RÉSULTAT NET (BÉNÉFICE NET)' : 'RÉSULTAT NET (PERTE NETTE)',
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

                // ================= DÉTAIL DES POSTES COMPTABLES (SYSCOHADA) =================
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
                              'Détail des Postes (Classes 6 & 7)',
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