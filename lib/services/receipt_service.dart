import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReceiptService {
  static Future<void> printReceipt({
    required List<dynamic> items,
    required double total,
    required double montantPaye,
    required String currency,
    required String nomClient,
    required String nomMagasin,
    required String adresseMagasin,
    required String phoneMagasin,
  }) async {
    final pdf = pw.Document();

    final now = DateTime.now();
    final formattedDate =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final double reste = total - montantPaye;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // EN-TÊTE MAGASIN
              pw.Center(
                child: pw.Text(
                  nomMagasin.toUpperCase(),
                  style:const pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              if (adresseMagasin.isNotEmpty)
                pw.Center(
                  child: pw.Text(adresseMagasin, style: const pw.TextStyle(fontSize: 8)),
                ),
              if (phoneMagasin.isNotEmpty)
                pw.Center(
                  child: pw.Text('Tél: $phoneMagasin', style: const pw.TextStyle(fontSize: 8)),
                ),
              pw.Divider(thickness: 0.5),

              // INFORMATIONS CLIENT & VENTE
              pw.Text('Client : $nomClient', style: const pw.TextStyle(fontSize: 9)),
              pw.Text('Date : $formattedDate', style: const pw.TextStyle(fontSize: 9)),
              pw.Divider(thickness: 0.5),

              // LISTE DES ARTICLES
              ...items.map((item) {
                final String nom = (item is Map) ? (item['nom'] ?? '') : item.nom;
                final int qte = (item is Map) ? ((item['quantite'] as num?)?.toInt() ?? 1) : item.quantite;
                final double prix = (item is Map)
                    ? ((item['prix'] as num?)?.toDouble() ?? 0.0)
                    : ((item.prix as num?)?.toDouble() ?? 0.0);
                final double prixTotal = prix * qte;

                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          '$nom x$qte',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ),
                      pw.Text(
                        '${prixTotal.toStringAsFixed(2)} $currency',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ],
                  ),
                );
              }),
              pw.Divider(thickness: 0.5),

              // TOTAUX ET PAIEMENT
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL :', style:const pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                  pw.Text(
                    '${total.toStringAsFixed(2)} $currency',
                    style:const pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                  ),
                ],
              ),
              pw.SizedBox(height: 2),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Payé :', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text('${montantPaye.toStringAsFixed(2)} $currency', style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    reste < 0 ? 'Monnaie :' : 'Reste :',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                  pw.Text(
                    '${reste.abs().toStringAsFixed(2)} $currency',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),

              // PIED DE PAGE
              pw.Divider(thickness: 0.5),
              pw.Center(
                child: pw.Text(
                  'Merci pour votre confiance !',
                  style:const pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 8),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text(
                  'Stockly SaaS | Conçu par PAPY SAFARI (+243 97 34 14 587)',
                  style:const pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 6),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Ticket_${nomClient.replaceAll(' ', '_')}_${now.millisecondsSinceEpoch}',
    );
  }
}