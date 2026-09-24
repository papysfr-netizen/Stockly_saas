// lib/features/accounting/services/accounting_pdf_service.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class GrandLivrePdfService {
  static Future<void> imprimerOuExporterGrandLivre({
    required String nomEntreprise,
    required String selectedAccount,
    required DateTimeRange dateRange,
    required List<dynamic> rows,
    required double totalDebit,
    required double totalCredit,
    required double soldeFinal,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // En-tête du document
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      nomEntreprise,
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Grand Livre des Comptes',
                      style: pw.TextStyle(
                        fontSize: 14,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Compte : $selectedAccount',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Période : ${DateFormat('dd/MM/yyyy').format(dateRange.start)} au ${DateFormat('dd/MM/yyyy').format(dateRange.end)}',
                      style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.SizedBox(height: 10),

            // Tableau des données
            pw.TableHelper.fromTextArray(
              headers: ['Date', 'Référence', 'Libellé', 'Débit', 'Crédit', 'Solde Cumulé'],
              data: rows.map((row) {
                return [
                  DateFormat('dd/MM/yyyy').format(row.date),
                  row.reference,
                  row.description,
                  row.debit > 0 ? '${row.debit.toStringAsFixed(2)} \$' : '-',
                  row.credit > 0 ? '${row.credit.toStringAsFixed(2)} \$' : '-',
                  '${row.soldeCumule.toStringAsFixed(2)} \$',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: pw.BoxDecoration(
                color: PdfColors.blueGrey800,
              ),
              rowDecoration: pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                ),
              ),
              cellAlignment: pw.Alignment.centerLeft,
              cellAlignments: {
                3: pw.Alignment.centerRight,
                4: pw.Alignment.centerRight,
                5: pw.Alignment.centerRight,
              },
            ),
            pw.SizedBox(height: 20),

            // Totaux et solde final
            pw.Container(
              alignment: pw.Alignment.centerRight,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Total Débit : ${totalDebit.toStringAsFixed(2)} \$'),
                  pw.SizedBox(height: 4),
                  pw.Text('Total Crédit : ${totalCredit.toStringAsFixed(2)} \$'),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Solde Final : ${soldeFinal.abs().toStringAsFixed(2)} \$ ${soldeFinal >= 0 ? "(D)" : "(C)"}',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: soldeFinal >= 0 ? PdfColors.blue800 : PdfColors.red800,
                    ),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Grand_Livre_$selectedAccount.pdf',
    );
  }
}