// lib/screens/bon_livraison_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/providers/currency_provider.dart';
import '../core/providers/settings_provider.dart' show settingsProvider;

class BonLivraisonScreen extends ConsumerStatefulWidget {
  final String entrepriseId;
  final String nomClient;
  final String adresseClient;
  final String telephoneClient;
  final List<dynamic> articles;

  const BonLivraisonScreen({
    super.key,
    required this.entrepriseId,
    required this.nomClient,
    required this.adresseClient,
    required this.telephoneClient,
    required this.articles,
  });

  @override
  ConsumerState<BonLivraisonScreen> createState() => _BonLivraisonScreenState();
}

class _BonLivraisonScreenState extends ConsumerState<BonLivraisonScreen> {
  void _imprimerOuPartager() {
    // --- RÈGLE DE SÉCURITÉ / TRAÇABILITÉ ---
    double totalGlobal = 0;
    for (var item in widget.articles) {
      totalGlobal += (item.quantite * item.prix);
    }

    const double seuilMinimumTracabilite = 1000.0; // Seuil fixé à 1000 USD
    bool estClientAnonyme = widget.nomClient.isEmpty ||
        widget.nomClient.toLowerCase().contains('client divers') ||
        widget.nomClient.toLowerCase().contains('comptoir');
    bool telephoneManquant =
        widget.telephoneClient.isEmpty || widget.telephoneClient == 'N/A';

    // Si le montant dépasse le seuil et que les infos client sont insuffisantes
    if (totalGlobal >= seuilMinimumTracabilite &&
        (estClientAnonyme || telephoneManquant)) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text('Traçabilité requise', style: TextStyle(fontSize: 16)),
            ],
          ),
          content: Text(
            'Ce bon de livraison s\'élève à ${totalGlobal.toStringAsFixed(2)} \$ (ce qui dépasse le seuil de $seuilMinimumTracabilite \$).\n\n'
            'Pour des raisons de sécurité financière et de suivi, un nom de client valide et un numéro de téléphone sont obligatoires.',
            style: const TextStyle(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Compris'),
            ),
          ],
        ),
      );
      return; // Bloque la génération du document
    }

    // --- IMPRESSION PAS ENCORE DISPONIBLE ---
    // Aucun document n'est encore généré : on le dit honnêtement
    // au lieu d'afficher un faux message de succès.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'L\'impression du bon de livraison arrive bientôt. '
          'Faites une capture d\'écran en attendant.',
        ),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyState = ref.watch(currencyProvider);
    final boutique = ref.watch(settingsProvider);
    final dateDuJour = DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.now());
    final numeroBL =
        'BL-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

    // Infos du magasin (Paramètres) : les champs vides ne s'affichent pas
    final String nomMagasin = boutique.nomBoutique.trim().isEmpty
        ? 'Ma Boutique'
        : boutique.nomBoutique.trim();
    final String adresseMagasin = boutique.adresse.trim();
    final String phoneMagasin = boutique.telephone.trim();
    final List<String> mentionsLegales = [
      if (boutique.rccm.trim().isNotEmpty) 'RCCM : ${boutique.rccm.trim()}',
      if (boutique.idNat.trim().isNotEmpty) 'ID.NAT : ${boutique.idNat.trim()}',
      if (boutique.nif.trim().isNotEmpty) 'NIF : ${boutique.nif.trim()}',
    ];
    final List<String> coordonnees = [
      if (adresseMagasin.isNotEmpty) adresseMagasin,
      if (phoneMagasin.isNotEmpty) 'Tél : $phoneMagasin',
    ];

    double totalGlobal = 0;
    for (var item in widget.articles) {
      totalGlobal += (item.quantite * item.prix);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Bon de Livraison ($numeroBL)',
            overflow: TextOverflow.ellipsis),
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.print_rounded),
            tooltip: 'Imprimer / Partager',
            onPressed: _imprimerOuPartager,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(20),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- EN-TÊTE ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nomMagasin.toUpperCase(),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal.shade900,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          for (final ligne in coordonnees) ...[
                            const SizedBox(height: 2),
                            Text(
                              ligne,
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.teal.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'BON DE LIVRAISON',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal.shade800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'N° : $numeroBL',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Date : $dateDuJour',
                            style: const TextStyle(
                                fontSize: 10, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 30, thickness: 1.5),

                // --- CLIENT ---
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CLIENT LIVRÉ :',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.nomClient.isEmpty
                            ? 'Client Comptoir'
                            : widget.nomClient,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Adresse : ${widget.adresseClient.isEmpty ? 'Non spécifiée' : widget.adresseClient}',
                        style: const TextStyle(
                            fontSize: 11, color: Colors.black87),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Téléphone : ${widget.telephoneClient.isEmpty ? 'N/A' : widget.telephoneClient}',
                        style: const TextStyle(
                            fontSize: 11, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // --- TABLEAU ---
                Table(
                  border:
                      TableBorder.all(color: Colors.grey.shade300, width: 1),
                  columnWidths: const {
                    0: FlexColumnWidth(4),
                    1: FlexColumnWidth(1.5),
                    2: FlexColumnWidth(2.5),
                    3: FlexColumnWidth(2.5),
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: Colors.teal.shade100),
                      children: const [
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('Désignation',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('Qté',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('P.U.',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('Total',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                      ],
                    ),
                    ...widget.articles.map((item) {
                      final sousTotal = item.quantite * item.prix;
                      return TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(item.nom,
                                style: const TextStyle(fontSize: 11)),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(item.quantite.toString(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 11)),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(currencyState.formatPrice(item.prix),
                                textAlign: TextAlign.right,
                                style: const TextStyle(fontSize: 11)),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(currencyState.formatPrice(sousTotal),
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 16),

                // --- TOTAL ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.teal.shade200),
                      ),
                      child: Row(
                        children: [
                          const Text('TOTAL GÉNÉRAL : ',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12)),
                          Text(
                            currencyState.formatPrice(totalGlobal),
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.teal.shade900),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // --- SIGNATURES ---
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Le Livreur / Expéditeur',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 11)),
                          SizedBox(height: 35),
                          Text('--------------------------------',
                              style: TextStyle(color: Colors.grey),
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Le Client (Bon accord)',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 11)),
                          SizedBox(height: 35),
                          Text('--------------------------------',
                              style: TextStyle(color: Colors.grey),
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),

                // --- MENTIONS LÉGALES (PIED DE PAGE) ---
                const SizedBox(height: 30),
                const Divider(height: 20, thickness: 1),
                Center(
                  child: Column(
                    children: [
                      Text(
                        nomMagasin,
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      if (mentionsLegales.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          mentionsLegales.join('  |  '),
                          style:
                              const TextStyle(fontSize: 9, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      if (adresseMagasin.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          adresseMagasin,
                          style:
                              const TextStyle(fontSize: 9, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}