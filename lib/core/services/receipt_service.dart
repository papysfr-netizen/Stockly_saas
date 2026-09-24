import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:stockly_saas/core/models/vente.dart';

class ReceiptService {
  // Cache des polices Google Fonts pour éviter les re-téléchargements
  static pw.Font? _fontRegular;
  static pw.Font? _fontBold;
  static pw.Font? _fontItalic;

  static Future<void> _loadFonts() async {
    _fontRegular ??= await PdfGoogleFonts.robotoRegular();
    _fontBold ??= await PdfGoogleFonts.robotoBold();
    _fontItalic ??= await PdfGoogleFonts.robotoItalic();
  }

  /// Formatage unifié de prix
  static String _formatPrice(double amount, String currency) {
    return '${amount.toStringAsFixed(2)} $currency';
  }

  /// Impression directe à partir d'un objet Vente
  static Future<void> imprimerRecu({
    required Vente vente,
    required String monnaie,
    String nomMagasin = 'Stockly Pro',
    String adresseMagasin = '',
    String phoneMagasin = '',
  }) async {
    await printReceipt(
      items: vente.produits,
      total: vente.total,
      montantPaye: vente.total,
      currency: monnaie,
      nomClient: 'Client',
      nomMagasin: nomMagasin,
      adresseMagasin: adresseMagasin,
      phoneMagasin: phoneMagasin,
    );
  }

  /// Passerelle d'impression directe par paramètres (utilisée lors de l'encaissement)
  static Future<void> imprimerTicket({
    required String nomBoutique,
    required String nomClient,
    required List<dynamic> articles,
    required double total,
    required double paye,
    required double reste,
    String adresseBoutique = '',
    String phoneBoutique = '',
    String monnaie = '\$',
  }) async {
    await printReceipt(
      items: articles,
      total: total,
      montantPaye: paye,
      resteForce: reste,
      currency: monnaie,
      nomClient: nomClient,
      nomMagasin: nomBoutique,
      adresseMagasin: adresseBoutique,
      phoneMagasin: phoneBoutique,
    );
  }

  /// Envoi du reçu sous forme de texte via WhatsApp
  static Future<bool> envoyerWhatsApp({
    required String telephone,
    required Vente vente,
    String monnaie = '\$',
  }) async {
    final String cleanPhone = telephone.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleanPhone.isEmpty) return false;

    final buffer = StringBuffer();
    buffer.writeln('📄 *REÇU DE VENTE - Stockly*');
    buffer.writeln('--------------------------------');

    for (final dynamic item in vente.produits) {
      final itemData = _extractItemData(item);
      final String nom = itemData['nom'] as String;
      final int qte = itemData['qte'] as int;
      final double prix = itemData['prix'] as double;
      buffer.writeln('• $nom x$qte : ${_formatPrice(prix * qte, monnaie)}');
    }

    buffer.writeln('--------------------------------');
    buffer.writeln('*TOTAL : ${_formatPrice(vente.total, monnaie)}*');
    buffer.writeln('Merci pour votre confiance !');

    final String encodedText = Uri.encodeComponent(buffer.toString());
    final Uri whatsappUri = Uri.parse('https://wa.me/$cleanPhone?text=$encodedText');

    if (await canLaunchUrl(whatsappUri)) {
      return await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  /// Extraction sécurisée d'un item (Map, CartItem ou objet personnalisé)
  static Map<String, dynamic> _extractItemData(dynamic item) {
    if (item is Map) {
      return {
        'nom': item['nom']?.toString() ?? 'Article',
        'qte': (item['quantite'] ?? item['qte'] as num?)?.toInt() ?? 1,
        'prix': (item['prixUnitaire'] ?? item['prix'] as num?)?.toDouble() ?? 0.0,
      };
    }
    try {
      final dynamic obj = item;
      return {
        'nom': obj.nom?.toString() ?? 'Article',
        'qte': (obj.quantite as num?)?.toInt() ?? 1,
        'prix': (obj.prix as num?)?.toDouble() ?? 0.0,
      };
    } catch (_) {
      return {'nom': 'Article', 'qte': 1, 'prix': 0.0};
    }
  }

  /// Génération et impression du reçu PDF thermique (Format Rouleau 80mm)
  static Future<void> printReceipt({
    required List<dynamic> items,
    required double total,
    required double montantPaye,
    required String currency,
    required String nomClient,
    required String nomMagasin,
    required String adresseMagasin,
    required String phoneMagasin,
    double? resteForce,
  }) async {
    await _loadFonts();

    final pdf = pw.Document();
    final now = DateTime.now();
    final formattedDate =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final double reste = resteForce ?? (total - montantPaye);
    final clientName = nomClient.trim().isEmpty ? 'Client Divers' : nomClient;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        build: (pw.Context context) {
          return pw.Theme(
            data: pw.ThemeData.withFont(
              base: _fontRegular,
              bold: _fontBold,
              italic: _fontItalic,
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // En-tête Magasin
                pw.Center(
                  child: pw.Text(
                    nomMagasin.toUpperCase(),
                    style: const pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 12),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                if (adresseMagasin.isNotEmpty) ...[
                  pw.SizedBox(height: 1),
                  pw.Center(
                    child: pw.Text(
                      adresseMagasin,
                      style: const pw.TextStyle(fontSize: 8),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                ],
                if (phoneMagasin.isNotEmpty) ...[
                  pw.SizedBox(height: 1),
                  pw.Center(
                    child: pw.Text('Tél: $phoneMagasin',
                        style: const pw.TextStyle(fontSize: 8)),
                  ),
                ],
                pw.SizedBox(height: 4),
                pw.Divider(thickness: 0.5),

                // Informations Client & Date
                pw.Text('Client : $clientName',
                    style: const pw.TextStyle(fontSize: 8)),
                pw.Text('Date : $formattedDate',
                    style: const pw.TextStyle(fontSize: 8)),
                pw.Divider(thickness: 0.5),

                // Tableau de désignation des articles
                pw.Table(
                  columnWidths: const {
                    0: pw.FlexColumnWidth(4),
                    1: pw.FlexColumnWidth(1),
                    2: pw.FlexColumnWidth(2),
                  },
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.only(bottom: 2),
                          decoration: const pw.BoxDecoration(
                            border: pw.Border(
                              bottom: pw.BorderSide(
                                  width: 0.5, color: PdfColors.grey),
                            ),
                          ),
                          child: pw.Text('Désignation',
                              style: const pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold, fontSize: 8)),
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.only(bottom: 2),
                          decoration: const pw.BoxDecoration(
                            border: pw.Border(
                              bottom: pw.BorderSide(
                                  width: 0.5, color: PdfColors.grey),
                            ),
                          ),
                          child: pw.Text('Qté',
                              textAlign: pw.TextAlign.center,
                              style: const pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold, fontSize: 8)),
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.only(bottom: 2),
                          decoration: const pw.BoxDecoration(
                            border: pw.Border(
                              bottom: pw.BorderSide(
                                  width: 0.5, color: PdfColors.grey),
                            ),
                          ),
                          child: pw.Text('Total',
                              textAlign: pw.TextAlign.right,
                              style: const pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold, fontSize: 8)),
                        ),
                      ],
                    ),
                    ...items.map((item) {
                      final itemData = _extractItemData(item);
                      final String nom = itemData['nom'] as String;
                      final int qte = itemData['qte'] as int;
                      final double prix = itemData['prix'] as double;
                      final double prixTotal = prix * qte;

                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
                            child: pw.Text(nom,
                                style: const pw.TextStyle(fontSize: 8)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
                            child: pw.Text('$qte',
                                textAlign: pw.TextAlign.center,
                                style: const pw.TextStyle(fontSize: 8)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
                            child: pw.Text(_formatPrice(prixTotal, currency),
                                textAlign: pw.TextAlign.right,
                                style: const pw.TextStyle(fontSize: 8)),
                          ),
                        ],
                      );
                    }),
                  ],
                ),

                pw.Divider(thickness: 0.5),

                // Totaux & Règlement
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('TOTAL :',
                        style: const pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 9)),
                    pw.Text(_formatPrice(total, currency),
                        style: const pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 9)),
                  ],
                ),
                pw.SizedBox(height: 2),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Montant Versé :',
                        style: const pw.TextStyle(fontSize: 8)),
                    pw.Text(_formatPrice(montantPaye, currency),
                        style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(reste < 0 ? 'Monnaie :' : 'Reste à Payer :',
                        style: pw.TextStyle(
                            fontWeight: reste > 0
                                ? pw.FontWeight.bold
                                : pw.FontWeight.normal,
                            fontSize: 8)),
                    pw.Text(_formatPrice(reste.abs(), currency),
                        style: pw.TextStyle(
                            fontWeight: reste > 0
                                ? pw.FontWeight.bold
                                : pw.FontWeight.normal,
                            fontSize: 8)),
                  ],
                ),

                pw.SizedBox(height: 6),
                pw.Divider(thickness: 0.5),

                // Pied de page
                pw.Center(
                  child: pw.Text(
                    'Merci pour votre confiance !',
                    style: const pw.TextStyle(
                        fontStyle: pw.FontStyle.italic, fontSize: 8),
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Center(
                  child: pw.Text(
                    'Stockly SaaS | Conçu par PAPY SAFARI (+243 97 34 14 587)',
                    style: const pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 6),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Ticket_${clientName.replaceAll(' ', '_')}_${now.millisecondsSinceEpoch}',
    );
  }
}