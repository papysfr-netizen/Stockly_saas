// lib/screens/bon_livraison_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/providers/currency_provider.dart';
import '../core/providers/settings_provider.dart' show settingsProvider;
import '../core/services/facture_pdf_service.dart';
import '../l10n/app_localizations.dart';

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
  // Numéro et date fixés une seule fois (ne changent plus à chaque rafraîchissement)
  late final DateTime _date;
  late final String _numeroBL;
  bool _enCours = false;

  @override
  void initState() {
    super.initState();
    _date = DateTime.now();
    _numeroBL = 'BL-${_date.millisecondsSinceEpoch.toString().substring(5)}';
  }

  double get _totalGlobal {
    double total = 0;
    for (var item in widget.articles) {
      total += (item.quantite * item.prix);
    }
    return total;
  }

  Future<void> _imprimerOuPartager() async {
    // --- RÈGLE DE SÉCURITÉ / TRAÇABILITÉ ---
    final t = AppLocalizations.of(context);
    final double totalGlobal = _totalGlobal;

    const double seuilMinimumTracabilite = 1000.0; // Seuil fixé à 1000 USD
    final bool estClientAnonyme = widget.nomClient.isEmpty ||
        widget.nomClient.toLowerCase().contains('client divers') ||
        widget.nomClient.toLowerCase().contains('comptoir');
    final bool telephoneManquant =
        widget.telephoneClient.isEmpty || widget.telephoneClient == 'N/A';

    if (totalGlobal >= seuilMinimumTracabilite &&
        (estClientAnonyme || telephoneManquant)) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orange),
              const SizedBox(width: 8),
              Text(t.blTraceTitle, style: const TextStyle(fontSize: 16)),
            ],
          ),
          content: Text(
            t.blTraceMsg(totalGlobal.toStringAsFixed(2), seuilMinimumTracabilite.toStringAsFixed(0)),
            style: const TextStyle(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t.payUnderstood),
            ),
          ],
        ),
      );
      return; // Bloque la génération du document
    }

    // --- CHOIX : IMPRIMER OU PARTAGER ---
    final choix = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Text(t.blTitle,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ListTile(
              leading: const Icon(Icons.print, color: Colors.teal),
              title: Text(t.blPrint),
              onTap: () => Navigator.pop(ctx, 'imprimer'),
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.green),
              title: Text(t.blShare),
              onTap: () => Navigator.pop(ctx, 'partager'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (choix == null || !mounted) return;

    setState(() => _enCours = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final boutique = ref.read(settingsProvider);
      final currencyState = ref.read(currencyProvider);

      final lignes = widget.articles
          .map((item) => LigneDocument(
                nom: item.nom.toString(),
                quantite: (item.quantite as num).toInt(),
                prixUnitaire: (item.prix as num).toDouble(),
              ))
          .toList();

      final octets = await FacturePdfService.construire(
        type: TypeDocument.bonLivraison,
        numero: _numeroBL,
        date: _date,
        boutique: boutique,
        nomClient: widget.nomClient,
        telephoneClient: widget.telephoneClient,
        adresseClient: widget.adresseClient,
        lignes: lignes,
        formatPrix: (v) => currencyState.formatPrice(v),
      );

      if (choix == 'imprimer') {
        await FacturePdfService.imprimer(octets, 'Bon de livraison $_numeroBL');
      } else {
        await FacturePdfService.partager(octets, 'Bon_livraison_$_numeroBL.pdf');
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(t.blPdfError('$e')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyState = ref.watch(currencyProvider);
    final boutique = ref.watch(settingsProvider);
    final dateDuJour = DateFormat('dd/MM/yyyy HH:mm').format(_date);
    final t = AppLocalizations.of(context);

    // Infos du magasin (Paramètres) : les champs vides ne s'affichent pas
    final String nomMagasin = boutique.nomBoutique.trim().isEmpty
        ? t.blMyShop
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
      if (phoneMagasin.isNotEmpty) t.blPhoneShort(phoneMagasin),
    ];

    final double totalGlobal = _totalGlobal;

    return Scaffold(
      appBar: AppBar(
        title: Text('${t.blTitle} ($_numeroBL)',
            overflow: TextOverflow.ellipsis),
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
        actions: [
          _enCours
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.print_rounded),
                  tooltip: t.blPrintShare,
                  onPressed: _imprimerOuPartager,
                ),
        ],
      ),
      // 📄 La feuille reste claire comme un vrai papier, même en mode sombre
      body: Theme(
        data: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          colorSchemeSeed: const Color(0xFF0052FF),
        ),
        // ✒️ Texte foncé par défaut sur la feuille
        child: DefaultTextStyle.merge(
          style: const TextStyle(color: Color(0xFF1F2937)),
          child: SingleChildScrollView(
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
                            t.blTitle.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal.shade800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'N° : $_numeroBL',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            t.depDate(dateDuJour),
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
                      Text(
                        t.blDeliveredTo,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.nomClient.isEmpty
                            ? t.blCounterClient
                            : widget.nomClient,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        t.blAddress(widget.adresseClient.isEmpty ? t.blNotSpecified : widget.adresseClient),
                        style: const TextStyle(
                            fontSize: 11, color: Colors.black87),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        t.blPhone(widget.telephoneClient.isEmpty ? 'N/A' : widget.telephoneClient),
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
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(t.blColItem,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(t.blColQty,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(t.blColUnit,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(t.blColTotal,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
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
                          Text(t.blGrandTotal,
                              style: const TextStyle(
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.blDeliverer,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 11)),
                          const SizedBox(height: 35),
                          const Text('--------------------------------',
                              style: TextStyle(color: Colors.grey),
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.blCustomerSign,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 11)),
                          const SizedBox(height: 35),
                          const Text('--------------------------------',
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
      ))),
    );
  }
}