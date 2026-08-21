import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/report_export_service.dart';

class ProfitsPertesScreen extends StatelessWidget {
  const ProfitsPertesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profits et Pertes"),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
            onPressed: () => _exporter(context, isPdf: true),
          ),
          IconButton(
            icon: const Icon(Icons.table_chart, color: Colors.green),
            onPressed: () => _exporter(context, isPdf: false),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('ventes').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Aucune donnée disponible"));
          }

          double chiffreAffaires = 0.0;
          double coutAchatTotal = 0.0;

          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final totalVente = (data['totalVente'] ?? 0.0) as num;
            final coutAchat = (data['totalCoutAchat'] ?? 0.0) as num;

            chiffreAffaires += totalVente.toDouble();
            coutAchatTotal += coutAchat.toDouble();
          }

          final beneficeBrut = chiffreAffaires - coutAchatTotal;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildCard("Chiffre d'Affaires (Ventes)", "$chiffreAffaires FCFA", Colors.blue),
                const SizedBox(height: 12),
                _buildCard("Coût d'Achat des Produits", "$coutAchatTotal FCFA", Colors.orange),
                const SizedBox(height: 12),
                _buildCard(
                  "Bénéfice Net",
                  "$beneficeBrut FCFA",
                  beneficeBrut >= 0 ? Colors.green : Colors.red,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard(String title, String value, Color color) {
    return Card(
      elevation: 3,
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: Text(
          value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
      ),
    );
  }

  void _exporter(BuildContext context, {required bool isPdf}) {
    final enTetes = ["Indicateur", "Montant"];
    final lignes = [
      ["Chiffre d'Affaires", "100,000 FCFA"],
      ["Coût d'Achat", "60,000 FCFA"],
      ["Bénéfice Net", "40,000 FCFA"],
    ];

    if (isPdf) {
      ReportExportService.exporterPDF(
        titreRapport: "Rapport Profits et Pertes",
        enTetes: enTetes,
        lignes: lignes,
      );
    } else {
      ReportExportService.exporterExcel(
        titreRapport: "Rapport Profits et Pertes",
        enTetes: enTetes,
        lignes: lignes,
      );
    }
  }
}