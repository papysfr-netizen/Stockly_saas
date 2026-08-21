enum TypeCompte { actif, passif, capitaux, charge, produit }

class CompteComptable {
  final String code; // Ex: "411000" (Clients), "512000" (Banque/Caisse)
  final String intitule;
  final int classe; // 1 à 7 (SYSCOHADA / PCG)
  final TypeCompte type;

  CompteComptable({
    required this.code,
    required this.intitule,
    required this.classe,
    required this.type,
  });

  Map<String, dynamic> toMap() => {
    'code': code,
    'intitule': intitule,
    'classe': classe,
    'type': type.name,
  };

  factory CompteComptable.fromMap(Map<String, dynamic> map) {
    return CompteComptable(
      code: map['code'] ?? '',
      intitule: map['intitule'] ?? '',
      classe: map['classe'] ?? 1,
      type: TypeCompte.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => TypeCompte.actif,
      ),
    );
  }
}

class LigneEcriture {
  final String compteCode;
  final String compteIntitule;
  final double debit;
  final double credit;

  LigneEcriture({
    required this.compteCode,
    required this.compteIntitule,
    this.debit = 0.0,
    this.credit = 0.0,
  });

  Map<String, dynamic> toMap() => {
    'compteCode': compteCode,
    'compteIntitule': compteIntitule,
    'debit': debit,
    'credit': credit,
  };

  factory LigneEcriture.fromMap(Map<String, dynamic> map) {
    return LigneEcriture(
      compteCode: map['compteCode'] ?? '',
      compteIntitule: map['compteIntitule'] ?? '',
      debit: (map['debit'] ?? 0.0).toDouble(),
      credit: (map['credit'] ?? 0.0).toDouble(),
    );
  }
}

class EcritureComptable {
  final String id;
  final String entrepriseId;
  final DateTime date;
  final String libelle;
  final String pieceRef; // N° de facture ou reçu
  final List<LigneEcriture> lignes;

  EcritureComptable({
    required this.id,
    required this.entrepriseId,
    required this.date,
    required this.libelle,
    required this.pieceRef,
    required this.lignes,
  });

  // Vérification de la partie double
  bool get estEquilibree {
    double totalDebit = lignes.fold(0.0, (sum, l) => sum + l.debit);
    double totalCredit = lignes.fold(0.0, (sum, l) => sum + l.credit);
    return (totalDebit - totalCredit).abs() < 0.001;
  }

  Map<String, dynamic> toMap() => {
    'entrepriseId': entrepriseId,
    'date': date.toIso8601String(),
    'libelle': libelle,
    'pieceRef': pieceRef,
    'lignes': lignes.map((l) => l.toMap()).toList(),
  };

  factory EcritureComptable.fromMap(String id, Map<String, dynamic> map) {
    return EcritureComptable(
      id: id,
      entrepriseId: map['entrepriseId'] ?? '',
      date: DateTime.parse(map['date']),
      libelle: map['libelle'] ?? '',
      pieceRef: map['pieceRef'] ?? '',
      lignes: (map['lignes'] as List? ?? [])
          .map((l) => LigneEcriture.fromMap(l))
          .toList(),
    );
  }
}