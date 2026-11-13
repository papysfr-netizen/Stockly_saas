import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:stockly_saas/core/models/vente.dart';
import 'package:stockly_saas/core/providers/settings_provider.dart';
import 'package:stockly_saas/core/services/imprimante_reglages.dart';

class ReceiptService {
  // Cache des polices Google Fonts pour éviter les re-téléchargements
  static pw.Font? _fontRegular;
  static pw.Font? _fontBold;
  static pw.Font? _fontItalic;

  static Future<void> _loadFonts() async {
    if (_fontRegular != null && _fontBold != null && _fontItalic != null) return;
    try {
      // 🌐 Roboto vient d'Internet : 5 secondes maximum
      final polices = await Future.wait([
        PdfGoogleFonts.robotoRegular(),
        PdfGoogleFonts.robotoBold(),
        PdfGoogleFonts.robotoItalic(),
      ]).timeout(const Duration(seconds: 5));
      _fontRegular = polices[0];
      _fontBold = polices[1];
      _fontItalic = polices[2];
    } catch (e) {
      // 📴 Pas de réseau : police de base du PDF (le reçu sort quand même)
      debugPrint('[Nguli] Police Roboto indisponible, reçu avec la police de base : $e');
      _fontRegular = null;
      _fontBold = null;
      _fontItalic = null;
    }
  }

  /// Formatage unifié de prix
  static String _formatPrice(double amount, String currency) {
    return '${amount.toStringAsFixed(2)} $currency';
  }

  // ================= INFOS DU MAGASIN (LUES DANS FIRESTORE) =================

  /// Lit un document : réseau d'abord (3 s max), sinon copie du téléphone.
  static Future<DocumentSnapshot<Map<String, dynamic>>> _lireDoc(
    DocumentReference<Map<String, dynamic>> ref,
  ) async {
    try {
      return await ref.get().timeout(const Duration(seconds: 3));
    } catch (_) {
      return await ref.get(const GetOptions(source: Source.cache));
    }
  }

  /// Récupère les infos du magasin enregistrées dans Paramètres
  /// (entreprises/{id}, champ 'infosBoutique').
  /// Renvoie null si rien n'est disponible : le reçu garde alors
  /// les valeurs passées en paramètre.
  static Future<ShopSettings?> _chargerInfosBoutique() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return null;

      final firestore = FirebaseFirestore.instance;
      final userDoc = await _lireDoc(firestore.collection('users').doc(uid));
      final entrepriseId = userDoc.data()?['entrepriseId']?.toString() ?? '';
      if (entrepriseId.isEmpty) return null;

      final entDoc =
          await _lireDoc(firestore.collection('entreprises').doc(entrepriseId));
      final data = entDoc.data();
      if (data == null) return null;

      return ShopSettings.fromEntreprise(data);
    } catch (e) {
      debugPrint('[Nguli] Infos boutique indisponibles pour le reçu : $e');
      return null;
    }
  }

  /// Garde la valeur enregistrée si elle existe, sinon celle de secours.
  static String _choisir(String? enregistre, String secours) {
    final valeur = enregistre?.trim() ?? '';
    return valeur.isNotEmpty ? valeur : secours;
  }

  // ================= POINTS D'ENTRÉE =================

  /// Impression directe à partir d'un objet Vente
  static Future<void> imprimerRecu({
    required Vente vente,
    required String monnaie,
    String nomMagasin = 'Nguli',
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

    final infos = await _chargerInfosBoutique();
    final nomMagasin = _choisir(infos?.nomBoutique, 'Nguli');

    final buffer = StringBuffer();
    buffer.writeln('📄 *REÇU DE VENTE - $nomMagasin*');
    if (infos != null && infos.telephone.trim().isNotEmpty) {
      buffer.writeln('Tél : ${infos.telephone.trim()}');
    }
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
    // 🖨️ Réglages de l'imprimante de ce téléphone (papier, mode)
    final reglages = await ReglagesImprimante.charger();

    // Les infos enregistrées dans Paramètres priment sur les valeurs
    // écrites en dur par les écrans (ex : 'Nguli').
    final infos = await _chargerInfosBoutique();
    final String nomFinal = _choisir(infos?.nomBoutique, nomMagasin);
    final String adresseFinale = _choisir(infos?.adresse, adresseMagasin);
    final String phoneFinal = _choisir(infos?.telephone, phoneMagasin);
    final String rccm = infos?.rccm.trim() ?? '';
    final String idNat = infos?.idNat.trim() ?? '';
    final String nif = infos?.nif.trim() ?? '';

    final List<String> mentionsLegales = [
      if (rccm.isNotEmpty) 'RCCM : $rccm',
      if (idNat.isNotEmpty) 'ID.NAT : $idNat',
      if (nif.isNotEmpty) 'NIF : $nif',
    ];

    final pdf = pw.Document();
    final now = DateTime.now();
    final formattedDate =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final double reste = resteForce ?? (total - montantPaye);
    final clientName = nomClient.trim().isEmpty ? 'Client Divers' : nomClient;

    pdf.addPage(
      pw.Page(
        pageFormat: reglages.papier58 ? PdfPageFormat.roll57 : PdfPageFormat.roll80,
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
                    nomFinal.toUpperCase(),
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 12),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                if (adresseFinale.isNotEmpty) ...[
                  pw.SizedBox(height: 1),
                  pw.Center(
                    child: pw.Text(
                      adresseFinale,
                      style: const pw.TextStyle(fontSize: 8),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                ],
                if (phoneFinal.isNotEmpty) ...[
                  pw.SizedBox(height: 1),
                  pw.Center(
                    child: pw.Text('Tél: $phoneFinal',
                        style: const pw.TextStyle(fontSize: 8)),
                  ),
                ],
                if (mentionsLegales.isNotEmpty) ...[
                  pw.SizedBox(height: 1),
                  pw.Center(
                    child: pw.Text(
                      mentionsLegales.join('  |  '),
                      style: const pw.TextStyle(fontSize: 7),
                      textAlign: pw.TextAlign.center,
                    ),
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
                              style: pw.TextStyle(
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
                              style: pw.TextStyle(
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
                              style: pw.TextStyle(
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
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 9)),
                    pw.Text(_formatPrice(total, currency),
                        style: pw.TextStyle(
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
                    style: pw.TextStyle(
                        fontStyle: pw.FontStyle.italic, fontSize: 8),
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Center(
                  child: pw.Text(
                    'Nguli | Conçu par PAPY SAFARI (+243 97 34 14 587)',
                    style: pw.TextStyle(
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

    final nomTicket =
        'Ticket_${clientName.replaceAll(' ', '_')}_${now.millisecondsSinceEpoch}';

    if (reglages.partagerPdf) {
      // 📤 Pas d'imprimante : le reçu part en PDF (WhatsApp, Bluetooth, e-mail…)
      await Printing.sharePdf(bytes: await pdf.save(), filename: '$nomTicket.pdf');
    } else {
      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        name: nomTicket,
      );
    }
  }
}