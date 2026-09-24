// lib/features/accounting/screens/profits_pertes_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'package:stockly_saas/core/providers/auth_provider.dart';
import 'package:stockly_saas/core/providers/currency_provider.dart';

class ProfitsPertesScreen extends ConsumerStatefulWidget {
  const ProfitsPertesScreen({super.key});

  @override
  ConsumerState<ProfitsPertesScreen> createState() => _ProfitsPertesScreenState();
}

class _ProfitsPertesScreenState extends ConsumerState<ProfitsPertesScreen> {
  // Par défaut sur "TOUT" pour sommer l'ensemble de l'historique comptable
  String selectedFilter = "TOUT"; 

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final String userId = authState.user?.uid ?? '';

    final currencyCode = ref.watch(currencyProvider).toString();
    final currencyFormat = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: currencyCode,
      decimalDigits: 2,
    );

    if (userId.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Compte de Résultat"),
          backgroundColor: const Color(0xFF1E293B),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text("Utilisateur non connecté.")),
      );
    }

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('entreprises')
          .where('ownerId', isEqualTo: userId)
          .get(),
      builder: (context, entrepriseSnapshot) {
        if (entrepriseSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (!entrepriseSnapshot.hasData || entrepriseSnapshot.data!.docs.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text("Compte de Résultat")),
            body: const Center(child: Text("Aucune entreprise trouvée.")),
          );
        }

        final entrepriseId = entrepriseSnapshot.data!.docs.first.id;
        final entrepriseRef = FirebaseFirestore.instance.collection('entreprises').doc(entrepriseId);

        return Scaffold(
          backgroundColor: Colors.grey.shade100,
          appBar: AppBar(
            title: const Text("Compte de Résultat", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            backgroundColor: const Color(0xFF1E293B),
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_sweep),
                onPressed: () {},
              )
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(55),
              child: Container(
                color: const Color(0xFF1E293B),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildPeriodChip("TOUT"),
                      _buildPeriodChip("AUJOURD'HUI"),
                      _buildPeriodChip("HIER"),
                      _buildPeriodChip("22/09/2026"),
                      _buildPeriodChip("16/09/2026"),
                      _buildPeriodChip("15/09/2026"),
                    ],
                  ),
                ),
              ),
            ),
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: entrepriseRef.collection('ecritures_comptables').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    "Aucune écriture comptable enregistrée.",
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                );
              }

              double totalCredits = 0.0;
              double totalDebits = 0.0;

              for (var doc in snapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                
                // Filtrage par date
                if (selectedFilter != "TOUT") {
                  final dateField = data['date'];
                  if (dateField != null) {
                    String formattedDocDate = "";
                    if (dateField is Timestamp) {
                      formattedDocDate = DateFormat('dd/MM/yyyy').format(dateField.toDate());
                    } else if (dateField is String && dateField.length >= 10) {
                      formattedDocDate = dateField.substring(0, 10);
                    }

                    if (selectedFilter == "AUJOURD'HUI") {
                      final todayStr = DateFormat('dd/MM/yyyy').format(DateTime.now());
                      if (formattedDocDate != todayStr) continue;
                    } else if (selectedFilter == "HIER") {
                      final yesterdayStr = DateFormat('dd/MM/yyyy').format(DateTime.now().subtract(const Duration(days: 1)));
                      if (formattedDocDate != yesterdayStr) continue;
                    } else {
                      if (formattedDocDate != selectedFilter) continue;
                    }
                  } else {
                    continue;
                  }
                }

                // Analyse des lignes comptables
                if (data['lines'] != null) {
                  final lines = data['lines'] as List<dynamic>;
                  for (var line in lines) {
                    final lineMap = line as Map<String, dynamic>;
                    final credit = (lineMap['credit'] ?? 0.0) as num;
                    final debit = (lineMap['debit'] ?? 0.0) as num;

                    totalCredits += credit.toDouble();
                    totalDebits += debit.toDouble();
                  }
                }
              }

              final resultatNet = totalCredits - totalDebits;

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Carte principale Résultat Net
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade800,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "RÉSULTAT NET (BÉNÉFICE NET)",
                            style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            currencyFormat.format(resultatNet),
                            style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            resultatNet >= 0 ? "Votre entreprise est bénéficiaire !" : "Votre entreprise est en déficit.",
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text("Analyse Détaillée (P&L)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
                        Text("Appuyez pour détailler", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Blocs détaillés
                    Expanded(
                      child: ListView(
                        children: [
                          _buildDetailCard("Chiffre d'affaires / Ventes", currencyFormat.format(totalCredits), Colors.teal.shade700, Icons.store),
                          const SizedBox(height: 8),
                          _buildDetailCard("Achats / Charges d'exploitation", currencyFormat.format(totalDebits), Colors.orange.shade800, Icons.shopping_cart),
                          const SizedBox(height: 8),
                          _buildDetailCard("Total Produits", currencyFormat.format(totalCredits), Colors.blue.shade700, Icons.account_balance_wallet),
                          const SizedBox(height: 8),
                          _buildDetailCard("Total Charges", currencyFormat.format(totalDebits), Colors.red.shade400, Icons.receipt_long),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPeriodChip(String label) {
    final isSelected = selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            selectedFilter = label;
          });
        },
        selectedColor: Colors.orange.shade800,
        backgroundColor: const Color(0xFF334155),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.white70,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildDetailCard(String title, String value, Color color, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF334155))),
        trailing: Text(
          value,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
        ),
      ),
    );
  }
}