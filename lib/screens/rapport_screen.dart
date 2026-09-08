import 'package:flutter/material.dart';
import 'package:stockly_saas/screens/rapports/profits_pertes_screen.dart';
import 'package:stockly_saas/screens/rapports/ventes_date_screen.dart';

import '../models/rapport_item.dart';
import '../services/report_export_service.dart';

class RapportsScreen extends StatefulWidget {
  const RapportsScreen({super.key});

  @override
  State<RapportsScreen> createState() => _RapportsScreenState();
}

class _RapportsScreenState extends State<RapportsScreen> {
  // Liste initiale des rapports (avec constructeurs const)
  List<RapportItem> _rapports = const [
    RapportItem(id: '1', titre: 'Achats par Fournisseur', type: TypeRapport.dettesFournisseur),
    RapportItem(id: '2', titre: 'Achats par article', type: TypeRapport.ventesArticles),
    RapportItem(id: '3', titre: 'Dettes par client', type: TypeRapport.dettesClient),
    RapportItem(id: '4', titre: 'Dettes par fournisseur', type: TypeRapport.dettesFournisseur),
    RapportItem(id: '5', titre: 'Dépenses', type: TypeRapport.depenses),
    RapportItem(id: '6', titre: 'Liste des documents', type: TypeRapport.documents),
    RapportItem(id: '7', titre: 'Liste des transactions', type: TypeRapport.transactions),
    RapportItem(id: '8', titre: 'Livre De Caisse', type: TypeRapport.livreCaisse),
    RapportItem(id: '9', titre: 'Mouvement de stock', type: TypeRapport.mouvementStock),
    RapportItem(id: '10', titre: 'Profits et pertes', type: TypeRapport.profitsPertes),
    RapportItem(id: '11', titre: 'Rapport de réassort', type: TypeRapport.reassort),
    RapportItem(id: '12', titre: 'Ventes par Articles', type: TypeRapport.ventesArticles),
    RapportItem(id: '13', titre: 'Ventes par Client', type: TypeRapport.ventesClient),
    RapportItem(id: '14', titre: 'Ventes par Date', type: TypeRapport.ventesDate),
    RapportItem(id: '15', titre: 'Ventes par mois', type: TypeRapport.ventesMois),
    RapportItem(id: '16', titre: 'Ventes par utilisateur', type: TypeRapport.ventesUtilisateur),
  ];

  final String _magasinSelectionne = "Tous les magasins";

  /// Getter pour trier la liste : Les favoris s'affichent toujours EN HAUT
  List<RapportItem> get _rapportsTries {
    final list = List<RapportItem>.from(_rapports);
    list.sort((a, b) {
      if (a.estFavori && !b.estFavori) return -1;
      if (!a.estFavori && b.estFavori) return 1;
      return a.titre.compareTo(b.titre);
    });
    return list;
  }

  // --- BASCULER LE STATUT FAVORI (IMMUABLE) ---
  void _toggleFavori(RapportItem rapport) {
    setState(() {
      _rapports = _rapports.map((item) {
        if (item.id == rapport.id) {
          return item.copyWith(estFavori: !item.estFavori);
        }
        return item;
      }).toList();
    });
  }

  // --- REDIRECTION VERS LES ÉCRANS DÉTAILLÉS ---
  void _ouvrirRapport(BuildContext context, RapportItem rapport) {
    switch (rapport.type) {
      case TypeRapport.profitsPertes:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfitsPertesScreen()),
        );
        break;
      case TypeRapport.ventesDate:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const VentesParDateScreen()),
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Le rapport '${rapport.titre}' est prêt à être configuré."),
          ),
        );
    }
  }

  // --- EXPORTATION EXCEL ---
  void _exporterExcel(RapportItem rapport) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Génération d'Excel pour '${rapport.titre}'...")),
    );

    final enTetes = ["ID", "Désignation", "Date", "Statut"];
    final lignes = [
      [rapport.id, rapport.titre, DateTime.now().toString().substring(0, 10), "Exporté"],
    ];

    try {
      final file = await ReportExportService.exporterExcel(
        titreRapport: rapport.titre,
        enTetes: enTetes,
        lignes: lignes,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Fichier enregistré : ${file.path}"),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur lors de la génération Excel : $e"),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  // --- EXPORTATION PDF ---
  void _exporterPDF(RapportItem rapport) async {
    final enTetes = ["ID", "Désignation", "Date", "Statut"];
    final lignes = [
      [rapport.id, rapport.titre, DateTime.now().toString().substring(0, 10), "Généré"],
    ];

    try {
      await ReportExportService.exporterPDF(
        titreRapport: rapport.titre,
        enTetes: enTetes,
        lignes: lignes,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur lors de la génération PDF : $e"),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final listeAffichee = _rapportsTries;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Rapports"),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(26.0),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              "- $_magasinSelectionne -",
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            ),
          ),
        ),
      ),
      body: ListView.separated(
        itemCount: listeAffichee.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final rapport = listeAffichee[index];

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            title: Text(
              rapport.titre,
              style: TextStyle(
                fontWeight: rapport.estFavori ? FontWeight.bold : FontWeight.normal,
                color: rapport.estFavori ? Colors.amber.shade900 : Colors.black87,
              ),
            ),

            // Bouton Étoile Favori (Ajusté pour immutabilité)
            leading: IconButton(
              icon: Icon(
                rapport.estFavori ? Icons.star : Icons.star_border,
                color: rapport.estFavori ? Colors.amber : Colors.grey,
              ),
              onPressed: () => _toggleFavori(rapport),
            ),

            // Menu contextuel d'exportation
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.grey),
              onSelected: (value) {
                if (value == 'excel') {
                  _exporterExcel(rapport);
                } else if (value == 'pdf') {
                  _exporterPDF(rapport);
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem(
                  value: 'excel',
                  child: Row(
                    children: [
                      Icon(Icons.table_chart, color: Colors.green, size: 20),
                      SizedBox(width: 10),
                      Text('Exporter vers Excel'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'pdf',
                  child: Row(
                    children: [
                      Icon(Icons.picture_as_pdf, color: Colors.red, size: 20),
                      SizedBox(width: 10),
                      Text('Exporter en PDF'),
                    ],
                  ),
                ),
              ],
            ),

            onTap: () => _ouvrirRapport(context, rapport),
          );
        },
      ),
    );
  }
}