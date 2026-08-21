import 'package:flutter/foundation.dart';

/// Modes de règlement pris en charge
enum PaymentMethod { cash, bank, mobileMoney, credit }

/// Modèle d'une ligne d'écriture comptable
@immutable
class JournalLine {
  final String accountCode;
  final String accountLabel;
  final double debit;
  final double credit;

  const JournalLine({
    required this.accountCode,
    required this.accountLabel,
    this.debit = 0.0,
    this.credit = 0.0,
  });

  Map<String, dynamic> toJson() => {
        'accountCode': accountCode,
        'accountLabel': accountLabel,
        'debit': debit,
        'credit': credit,
      };
}

/// Modèle d'une pièce comptable (Journal)
@immutable
class JournalEntry {
  final String id;
  final DateTime date;
  final String reference;
  final String description;
  final List<JournalLine> lines;

  JournalEntry({
    required this.id,
    required this.date,
    required this.reference,
    required this.description,
    required this.lines,
  }) {
    // RÈGLE COMPTABLE CRUCIALE : Équilibre Débit/Crédit
    assert(
      isBalanced,
      'Écriture déséquilibrée pour $reference: Débit ($totalDebit) != Crédit ($totalCredit)',
    );
  }

  double get totalDebit =>
      lines.fold(0.0, (sum, line) => sum + line.debit);

  double get totalCredit =>
      lines.fold(0.0, (sum, line) => sum + line.credit);

  bool get isBalanced => (totalDebit - totalCredit).abs() < 0.001;

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'reference': reference,
        'description': description,
        'totalAmount': totalDebit,
        'lines': lines.map((l) => l.toJson()).toList(),
      };
}

/// Service de génération automatique des pièces de journal comptable
class AccountingJournalService {
  /// Mappage des modes de paiement vers les comptes SYSCOHADA
  static String getAccountCodeForPayment(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return '571000'; // Caisse
      case PaymentMethod.bank:
        return '521000'; // Banque
      case PaymentMethod.mobileMoney:
        return '572000'; // Mobile Money (Airtel / M-Pesa / Orange)
      case PaymentMethod.credit:
        return '411000'; // Client (ou 401000 pour Fournisseur)
    }
  }

  /// --------------------------------------------------------------------------
  /// 1. GÉNÉRATION DES ÉCRITURES POUR UN ACHAT DE STOCK
  /// --------------------------------------------------------------------------
  static List<JournalEntry> generatePurchaseEntries({
    required String transactionId,
    required DateTime date,
    required String invoiceRef,
    required String supplierName,
    required double amountExclTax, // Montant HT
    required double taxRate,       // ex: 0.16 pour 16% TVA
    required PaymentMethod paymentMethod,
    required double costOfGoodsPurchased, // Montant réel valorisé en stock
  }) {
    final taxAmount = amountExclTax * taxRate;
    final totalAmountTTC = amountExclTax + taxAmount;
    final entries = <JournalEntry>[];

    // --- Piece A : Écriture de la Facture d'Achat ---
    final purchaseLines = <JournalLine>[
      // Débit: 601000 - Achats de marchandises (HT)
      JournalLine(
        accountCode: '601000',
        accountLabel: 'Achats de marchandises',
        debit: amountExclTax,
      ),
    ];

    if (taxAmount > 0) {
      // Débit: 445200 - TVA récupérable sur achats
      purchaseLines.add(
        JournalLine(
          accountCode: '445200',
          accountLabel: 'TVA récupérable sur achats',
          debit: taxAmount,
        ),
      );
    }

    // Crédit: Compte de paiement ou Fournisseur (TTC)
    final creditCode = paymentMethod == PaymentMethod.credit
        ? '401000'
        : getAccountCodeForPayment(paymentMethod);

    final creditLabel = paymentMethod == PaymentMethod.credit
        ? 'Fournisseur - $supplierName'
        : _getAccountLabel(creditCode);

    purchaseLines.add(
      JournalLine(
        accountCode: creditCode,
        accountLabel: creditLabel,
        credit: totalAmountTTC,
      ),
    );

    entries.add(
      JournalEntry(
        id: 'JE-PUR-$transactionId',
        date: date,
        reference: invoiceRef,
        description: 'Facture d\'achat - $supplierName',
        lines: purchaseLines,
      ),
    );

    // --- Piece B : Écriture de Mouvement de Stock (Inventaire Permanent) ---
    entries.add(
      JournalEntry(
        id: 'JE-STK-IN-$transactionId',
        date: date,
        reference: invoiceRef,
        description: 'Entrée en stock marchandises ($invoiceRef)',
        lines: [
          // Débit: 311000 - Stock de marchandises
          JournalLine(
            accountCode: '311000',
            accountLabel: 'Stock de marchandises',
            debit: costOfGoodsPurchased,
          ),
          // Crédit: 603100 - Variation des stocks de marchandises
          JournalLine(
            accountCode: '603100',
            accountLabel: 'Variation des stocks de marchandises',
            credit: costOfGoodsPurchased,
          ),
        ],
      ),
    );

    return entries;
  }

  /// --------------------------------------------------------------------------
  /// 2. GÉNÉRATION DES ÉCRITURES POUR UNE VENTE DE STOCK
  /// --------------------------------------------------------------------------
  static List<JournalEntry> generateSaleEntries({
    required String transactionId,
    required DateTime date,
    required String invoiceRef,
    required String customerName,
    required double amountExclTax, // Montant HT
    required double taxRate,       // ex: 0.16 pour 16% TVA
    required PaymentMethod paymentMethod,
    required double costOfGoodsSold, // CUMP total des produits vendus (Coût d'achat)
  }) {
    final taxAmount = amountExclTax * taxRate;
    final totalAmountTTC = amountExclTax + taxAmount;
    final entries = <JournalEntry>[];

    // --- Piece A : Écriture de la Facture de Vente ---
    final debitCode = paymentMethod == PaymentMethod.credit
        ? '411000'
        : getAccountCodeForPayment(paymentMethod);

    final debitLabel = paymentMethod == PaymentMethod.credit
        ? 'Client - $customerName'
        : _getAccountLabel(debitCode);

    final saleLines = <JournalLine>[
      // Débit: Compte de Trésorerie ou Client (TTC)
      JournalLine(
        accountCode: debitCode,
        accountLabel: debitLabel,
        debit: totalAmountTTC,
      ),
      // Crédit: 701000 - Ventes de marchandises (HT)
      JournalLine(
        accountCode: '701000',
        accountLabel: 'Ventes de marchandises',
        credit: amountExclTax,
      ),
    ];

    if (taxAmount > 0) {
      // Crédit: 443100 - TVA facturée sur ventes
      saleLines.add(
        JournalLine(
          accountCode: '443100',
          accountLabel: 'TVA facturée sur ventes',
          credit: taxAmount,
        ),
      );
    }

    entries.add(
      JournalEntry(
        id: 'JE-SAL-$transactionId',
        date: date,
        reference: invoiceRef,
        description: 'Facture de vente - $customerName',
        lines: saleLines,
      ),
    );

    // --- Piece B : Écriture de Déstockage (Coût de Revient / CUMP) ---
    entries.add(
      JournalEntry(
        id: 'JE-STK-OUT-$transactionId',
        date: date,
        reference: invoiceRef,
        description: 'Sortie de stock (Déstockage au CUMP) pour $invoiceRef',
        lines: [
          // Débit: 603100 - Variation des stocks de marchandises (Charge)
          JournalLine(
            accountCode: '603100',
            accountLabel: 'Variation des stocks de marchandises',
            debit: costOfGoodsSold,
          ),
          // Crédit: 311000 - Stock de marchandises (Sortie d'actif)
          JournalLine(
            accountCode: '311000',
            accountLabel: 'Stock de marchandises',
            credit: costOfGoodsSold,
          ),
        ],
      ),
    );

    return entries;
  }

  static String _getAccountLabel(String code) {
    switch (code) {
      case '571000':
        return 'Caisse';
      case '521000':
        return 'Banque';
      case '572000':
        return 'Mobile Money';
      case '411000':
        return 'Clients';
      case '401000':
        return 'Fournisseurs';
      default:
        return 'Compte $code';
    }
  }
}