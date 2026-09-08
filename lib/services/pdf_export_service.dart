// lib/services/pdf_export_service.dart

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/journal_entry.dart';
import 'accounting_report_service.dart';

class PdfExportService {
  static final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  static final _currencyFormat = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'FCFA',
    decimalDigits: 2,
  );

  /// 1. Impression d'une Fiche de Pièce Comptable
  static Future<void> printJournalEntry(JournalEntry entry) async {
    final pdf = pw.Document();

    final totalDebit =
        entry.lines.fold<double>(0.0, (acc, line) => acc + line.debit);
    final totalCredit =
        entry.lines.fold<double>(0.0, (acc, line) => acc + line.credit);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'PIÈCE COMPTABLE',
                    style: const pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Réf: ${entry.reference}',
                    style: const pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              pw.Divider(thickness: 1.5),
              pw.SizedBox(height: 8),
              pw.Text('Date : ${_dateFormat.format(entry.date)}'),
              pw.Text('Libellé : ${entry.description}'),
              pw.SizedBox(height: 16),
              pw.TableHelper.fromTextArray(
                headers: [
                  'Code Compte',
                  'Intitulé du Compte',
                  'Débit',
                  'Crédit',
                ],
                data: [
                  ...entry.lines.map((line) => [
                        line.accountCode,
                        line.accountLabel,
                        line.debit > 0
                            ? _currencyFormat.format(line.debit)
                            : '-',
                        line.credit > 0
                            ? _currencyFormat.format(line.credit)
                            : '-',
                      ]),
                  [
                    'TOTAL',
                    '',
                    _currencyFormat.format(totalDebit),
                    _currencyFormat.format(totalCredit),
                  ],
                ],
                headerStyle: const pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.blue800,
                ),
                cellAlignment: pw.Alignment.centerLeft,
                cellAlignments: {
                  2: pw.Alignment.centerRight,
                  3: pw.Alignment.centerRight,
                },
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Piece_Comptable_${entry.reference}.pdf',
    );
  }

  /// 2. Impression de la Balance Générale
  static Future<void> printTrialBalance({
    required String entrepriseNom,
    required List<AccountBalance> balances,
  }) async {
    final pdf = pw.Document();

    final grandTotalDebit =
        balances.fold<double>(0.0, (acc, b) => acc + b.totalDebit);
    final grandTotalCredit =
        balances.fold<double>(0.0, (acc, b) => acc + b.totalCredit);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _buildHeader(entrepriseNom, 'BALANCE GÉNÉRALE DES COMPTES'),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: [
              'Compte',
              'Intitulé',
              'Total Débit',
              'Total Crédit',
              'Solde Débiteur',
              'Solde Créditeur',
            ],
            data: balances.map((b) {
              return [
                b.accountCode,
                b.accountLabel,
                _currencyFormat.format(b.totalDebit),
                _currencyFormat.format(b.totalCredit),
                b.isDebtor ? _currencyFormat.format(b.netBalance) : '-',
                b.isCreditor
                    ? _currencyFormat.format(b.netBalance.abs())
                    : '-',
              ];
            }).toList(),
            headerStyle: const pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              fontSize: 9,
            ),
            cellStyle: const pw.TextStyle(fontSize: 8),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.blue800,
            ),
            cellAlignment: pw.Alignment.centerLeft,
            cellAlignments: {
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerRight,
              5: pw.Alignment.centerRight,
            },
          ),
          pw.Divider(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'TOTAUX GÉNÉRAUX',
                style: const pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                ),
              ),
              pw.Text(
                'Débit: ${_currencyFormat.format(grandTotalDebit)} | Crédit: ${_currencyFormat.format(grandTotalCredit)}',
                style: const pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Balance_Generale.pdf',
    );
  }

  /// 3. Impression du Compte de Résultat
  static Future<void> printIncomeStatement({
    required String entrepriseNom,
    required IncomeStatementReport report,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildHeader(entrepriseNom, 'COMPTE DE RÉSULTAT (SYSCOHADA)'),
            pw.SizedBox(height: 16),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                color: report.isBenefice ? PdfColors.green50 : PdfColors.red50,
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    report.isBenefice
                        ? 'RÉSULTAT NET : BÉNÉFICE'
                        : 'RÉSULTAT NET : PERTE',
                    style: const pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                  pw.Text(
                    _currencyFormat.format(report.resultatNet.abs()),
                    style: const pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            pw.Text(
              'PRODUITS (CLASSE 7)',
              style: const pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
              ),
            ),
            pw.SizedBox(height: 4),
            _buildReportTable(report.produits),
            pw.SizedBox(height: 4),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'Total Produits: ${_currencyFormat.format(report.totalProduits)}',
                style: const pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 9,
                ),
              ),
            ),
            pw.SizedBox(height: 16),
            pw.Text(
              'CHARGES (CLASSE 6)',
              style: const pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
              ),
            ),
            pw.SizedBox(height: 4),
            _buildReportTable(report.charges),
            pw.SizedBox(height: 4),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'Total Charges: ${_currencyFormat.format(report.totalCharges)}',
                style: const pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 9,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Compte_De_Resultat.pdf',
    );
  }

  /// 4. Impression du Bilan
  static Future<void> printBalanceSheet({
    required String entrepriseNom,
    required BalanceSheetReport report,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildHeader(entrepriseNom, 'BILAN COMPTABLE (SYSCOHADA)'),
            pw.SizedBox(height: 16),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'ACTIF (Emplois)',
                        style: const pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                      pw.Divider(),
                      _buildReportTable(report.actif),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'TOTAL ACTIF: ${_currencyFormat.format(report.totalActif)}',
                        style: const pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 16),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'PASSIF (Ressources)',
                        style: const pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                      pw.Divider(),
                      _buildReportTable(report.passif),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Résultat Net:',
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                          pw.Text(
                            _currencyFormat.format(report.resultatExercice),
                            style: const pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 8,
                            ),
                          ),
                        ],
                      ),
                      pw.Divider(),
                      pw.Text(
                        'TOTAL PASSIF: ${_currencyFormat.format(report.totalPassif)}',
                        style: const pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Bilan_Comptable.pdf',
    );
  }

  // En-tête partagé
  static pw.Widget _buildHeader(String entreprise, String titre) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              entreprise.toUpperCase(),
              style: const pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 14,
              ),
            ),
            pw.Text(
              'Imprimé le: ${_dateFormat.format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 8),
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          titre,
          style: const pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 12,
            color: PdfColors.blue800,
          ),
        ),
        pw.Divider(thickness: 1.5),
      ],
    );
  }

  // Tableau simple pour sous-rapports
  static pw.Widget _buildReportTable(List<AccountBalance> items) {
    return pw.TableHelper.fromTextArray(
      headers: ['Code', 'Intitulé', 'Montant Net'],
      data: items
          .map((i) => [
                i.accountCode,
                i.accountLabel,
                _currencyFormat.format(i.netBalance.abs()),
              ])
          .toList(),
      headerStyle: const pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        fontSize: 8,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(
        color: PdfColors.blue800,
      ),
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellAlignment: pw.Alignment.centerLeft,
      cellAlignments: {2: pw.Alignment.centerRight},
    );
  }
}