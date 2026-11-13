import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../providers/settings_provider.dart' show ShopSettings;

/// Une ligne du document (article vendu).
class LigneDocument {
  final String nom;
  final int quantite;
  final double prixUnitaire;

  const LigneDocument({
    required this.nom,
    required this.quantite,
    required this.prixUnitaire,
  });

  double get total => quantite * prixUnitaire;
}

enum TypeDocument { facture, bonLivraison }

/// 📄 Fabrique les PDF (facture, bon de livraison), les imprime ou les partage.
class FacturePdfService {
  static Future<Uint8List> construire({
    required TypeDocument type,
    required String numero,
    required DateTime date,
    required ShopSettings boutique,
    required String nomClient,
    String telephoneClient = '',
    String adresseClient = '',
    required List<LigneDocument> lignes,
    required String Function(double) formatPrix,
    double? montantPaye,
    double? resteAPayer,
    String vendeur = '',
    String livreur = '',
  }) async {
    final doc = pw.Document();
    final estFacture = type == TypeDocument.facture;
    final titre = estFacture ? 'FACTURE' : 'BON DE LIVRAISON';
    const couleur = PdfColors.teal800;

    final nomMagasin =
        boutique.nomBoutique.trim().isEmpty ? 'Ma Boutique' : boutique.nomBoutique.trim();
    final coordonnees = <String>[
      if (boutique.adresse.trim().isNotEmpty) boutique.adresse.trim(),
      if (boutique.telephone.trim().isNotEmpty) 'Tél : ${boutique.telephone.trim()}',
    ];
    final mentions = <String>[
      if (boutique.rccm.trim().isNotEmpty) 'RCCM : ${boutique.rccm.trim()}',
      if (boutique.idNat.trim().isNotEmpty) 'ID.NAT : ${boutique.idNat.trim()}',
      if (boutique.nif.trim().isNotEmpty) 'NIF : ${boutique.nif.trim()}',
    ];

    final total = lignes.fold<double>(0, (s, l) => s + l.total);
    final dateTexte = DateFormat('dd/MM/yyyy HH:mm').format(date);
    final client = nomClient.trim().isEmpty ? 'Client Divers' : nomClient.trim();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        footer: (ctx) => pw.Column(
          children: [
            pw.Divider(color: PdfColors.grey400),
            pw.Text(
              nomMagasin,
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
            ),
            if (mentions.isNotEmpty)
              pw.Text(
                mentions.join('  |  '),
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
              ),
            pw.SizedBox(height: 2),
            pw.Text(
              'Document généré par Nguli - page ${ctx.pageNumber}/${ctx.pagesCount}',
              style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
            ),
          ],
        ),
        build: (ctx) => [
          // ---------- EN-TÊTE ----------
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      nomMagasin.toUpperCase(),
                      style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: couleur),
                    ),
                    ...coordonnees.map((c) => pw.Text(
                          c,
                          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                        )),
                  ],
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.teal50,
                  border: pw.Border.all(color: PdfColors.teal200),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(titre,
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: couleur)),
                    pw.SizedBox(height: 4),
                    pw.Text('N° : $numero', style: const pw.TextStyle(fontSize: 11)),
                    pw.Text('Date : $dateTexte',
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 20),

          // ---------- CLIENT ----------
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(10),
            decoration: const pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  estFacture ? 'FACTURÉ À :' : 'CLIENT LIVRÉ :',
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: couleur),
                ),
                pw.SizedBox(height: 4),
                pw.Text(client, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
                if (telephoneClient.trim().isNotEmpty)
                  pw.Text('Téléphone : ${telephoneClient.trim()}', style: const pw.TextStyle(fontSize: 10)),
                if (adresseClient.trim().isNotEmpty)
                  pw.Text('Adresse : ${adresseClient.trim()}', style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // ---------- ARTICLES ----------
          pw.TableHelper.fromTextArray(
            headers: ['Désignation', 'Qté', 'P.U.', 'Total'],
            data: lignes
                .map((l) => [l.nom, '${l.quantite}', formatPrix(l.prixUnitaire), formatPrix(l.total)])
                .toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
            headerDecoration: const pw.BoxDecoration(color: couleur),
            cellStyle: const pw.TextStyle(fontSize: 10),
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.center,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
            },
            columnWidths: {
              0: const pw.FlexColumnWidth(4),
              1: const pw.FlexColumnWidth(1),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(2),
            },
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            cellPadding: const pw.EdgeInsets.all(6),
          ),
          pw.SizedBox(height: 12),

          // ---------- TOTAUX ----------
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Container(
                width: 230,
                child: pw.Column(
                  children: [
                    _ligneTotal('TOTAL', formatPrix(total), gras: true, couleur: couleur),
                    if (estFacture && montantPaye != null)
                      _ligneTotal('Payé', formatPrix(montantPaye)),
                    if (estFacture && resteAPayer != null && resteAPayer > 0.005)
                      _ligneTotal('Reste à payer', formatPrix(resteAPayer), couleur: PdfColors.red),
                    if (estFacture && resteAPayer != null && resteAPayer <= 0.005)
                      _ligneTotal('Statut', 'PAYÉ', couleur: PdfColors.green700),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),

          if (vendeur.trim().isNotEmpty)
            pw.Text('Vendu par : ${vendeur.trim()}', style: const pw.TextStyle(fontSize: 10)),
          if (livreur.trim().isNotEmpty)
            pw.Text('Livré par : ${livreur.trim()}', style: const pw.TextStyle(fontSize: 10)),

          // ---------- SIGNATURES (bon de livraison) ----------
          if (!estFacture) ...[
            pw.SizedBox(height: 30),
            pw.Row(
              children: [
                pw.Expanded(child: _signature('Le Livreur / Expéditeur')),
                pw.SizedBox(width: 20),
                pw.Expanded(child: _signature('Le Client (Bon accord)')),
              ],
            ),
          ],

          pw.SizedBox(height: 24),
          pw.Center(
            child: pw.Text(
              'Merci pour votre confiance !',
              style: pw.TextStyle(fontSize: 11, fontStyle: pw.FontStyle.italic),
            ),
          ),
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _ligneTotal(String titre, String valeur, {bool gras = false, PdfColor? couleur}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(titre,
              style: pw.TextStyle(
                fontSize: gras ? 12 : 10,
                fontWeight: gras ? pw.FontWeight.bold : pw.FontWeight.normal,
              )),
          pw.Text(valeur,
              style: pw.TextStyle(
                fontSize: gras ? 13 : 10,
                fontWeight: gras ? pw.FontWeight.bold : pw.FontWeight.normal,
                color: couleur,
              )),
        ],
      ),
    );
  }

  static pw.Widget _signature(String titre) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(titre, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 35),
        pw.Container(height: 0.8, color: PdfColors.grey500),
      ],
    );
  }

  /// Ouvre le menu « Partager » d'Android (WhatsApp, e-mail…).
  static Future<void> partager(Uint8List octets, String nomFichier) {
    return Printing.sharePdf(bytes: octets, filename: nomFichier);
  }

  /// Ouvre l'écran d'impression d'Android.
  static Future<void> imprimer(Uint8List octets, String nomDocument) {
    return Printing.layoutPdf(onLayout: (_) async => octets, name: nomDocument);
  }
}