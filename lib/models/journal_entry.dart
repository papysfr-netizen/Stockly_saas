import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Alias de compatibilité
typedef JournalEntryLine = JournalLine;

/// Modèle d'une ligne d'écriture comptable (SYSCOHADA)
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

  factory JournalLine.fromJson(Map<String, dynamic> json) {
    return JournalLine(
      accountCode: json['accountCode']?.toString() ?? '',
      accountLabel: json['accountLabel']?.toString() ?? '',
      debit: (json['debit'] as num?)?.toDouble() ?? 0.0,
      credit: (json['credit'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Modèle d'une pièce comptable (Journal)
@immutable
class JournalEntry {
  final String id;
  final String entrepriseId;
  final DateTime date;
  final String reference;
  final String journalCode;
  final String description;
  final List<JournalLine> lines;
  final double montantEncaisse;

  const JournalEntry({
    required this.id,
    required this.entrepriseId,
    required this.date,
    required this.reference,
    this.journalCode = 'VT',
    required this.description,
    required this.lines,
    this.montantEncaisse = 0.0,
  });

  String get label => description;

  double get totalDebit =>
      lines.fold<double>(0.0, (acc, line) => acc + line.debit);

  double get totalCredit =>
      lines.fold<double>(0.0, (acc, line) => acc + line.credit);

  bool get isBalanced => (totalDebit - totalCredit).abs() < 0.01;

  JournalEntry copyWith({
    String? id,
    String? entrepriseId,
    DateTime? date,
    String? reference,
    String? journalCode,
    String? description,
    List<JournalLine>? lines,
    double? montantEncaisse,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      entrepriseId: entrepriseId ?? this.entrepriseId,
      date: date ?? this.date,
      reference: reference ?? this.reference,
      journalCode: journalCode ?? this.journalCode,
      description: description ?? this.description,
      lines: lines ?? this.lines,
      montantEncaisse: montantEncaisse ?? this.montantEncaisse,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'entrepriseId': entrepriseId,
        'date': date.toIso8601String(),
        'reference': reference,
        'journalCode': journalCode,
        'description': description,
        'label': label,
        'totalAmount': totalDebit,
        'montantEncaisse': montantEncaisse,
        'lines': lines.map((l) => l.toJson()).toList(),
      };

  factory JournalEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime parsedDate = DateTime.now();
    if (data['date'] is Timestamp) {
      parsedDate = (data['date'] as Timestamp).toDate();
    } else if (data['date'] is String) {
      parsedDate = DateTime.tryParse(data['date']) ?? DateTime.now();
    } else if (data['createdAt'] is Timestamp) {
      parsedDate = (data['createdAt'] as Timestamp).toDate();
    }

    List<JournalLine> parsedLines = [];

    if (data['lines'] != null && data['lines'] is List) {
      parsedLines = (data['lines'] as List)
          .map((l) => JournalLine.fromJson(Map<String, dynamic>.from(l)))
          .toList();
    } else {
      final double montant = (data['montant'] as num?)?.toDouble() ?? 
                             (data['totalAmount'] as num?)?.toDouble() ?? 0.0;
      final String compteDebit = data['compteDebit']?.toString() ?? '571000';
      final String compteCredit = data['compteCredit']?.toString() ?? '701000';

      parsedLines = [
        JournalLine(
          accountCode: compteDebit,
          accountLabel: getAccountLabel(compteDebit),
          debit: montant,
          credit: 0.0,
        ),
        JournalLine(
          accountCode: compteCredit,
          accountLabel: getAccountLabel(compteCredit),
          debit: 0.0,
          credit: montant,
        ),
      ];
    }

    return JournalEntry(
      id: doc.id,
      entrepriseId: data['entrepriseId']?.toString() ?? '',
      date: parsedDate,
      reference: data['venteId'] ?? data['reference'] ?? doc.id,
      journalCode: data['journalCode']?.toString() ?? 'VT',
      description: data['libelle'] ?? data['description'] ?? 'Écriture comptable',
      lines: parsedLines,
      montantEncaisse: (data['montantEncaisse'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'entrepriseId': entrepriseId,
      'date': Timestamp.fromDate(date),
      'createdAt': FieldValue.serverTimestamp(),
      'journalCode': journalCode,
      'libelle': description,
      'montant': totalDebit,
      'montantEncaisse': montantEncaisse,
      'reference': reference,
      'lines': lines.map((l) => l.toJson()).toList(),
    };
  }

  static String getAccountLabel(String code) {
    switch (code) {
      case '571000':
        return 'Caisse Principale';
      case '521000':
        return 'Banque';
      case '572000':
        return 'Mobile Money';
      case '411000':
        return 'Clients (Créances)';
      case '401000':
        return 'Fournisseurs (Dettes)';
      case '701000':
        return 'Ventes de marchandises';
      case '601000':
        return 'Achats de marchandises';
      case '603100':
        return 'Variation des stocks de marchandises';
      case '311000':
        return 'Stock de marchandises';
      case '445200':
        return 'TVA récupérable sur achats';
      case '443100':
        return 'TVA facturée sur ventes';
      default:
        return 'Compte $code';
    }
  }
}