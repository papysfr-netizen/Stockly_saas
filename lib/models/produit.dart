class Produit {
  final String id;
  final String entrepriseId; // 🛡️ Isolation Multi-Tenant
  final String codeBarre;
  final String nom;
  final String categorie;
  final int quantite;
  final double prixAchat;
  final double prixVente;
  final int seuilAlerte;
  final String? imageUrl;

  const Produit({
    required this.id,
    required this.entrepriseId,
    this.codeBarre = '',
    required this.nom,
    this.categorie = 'Général',
    this.quantite = 0,
    this.prixAchat = 0.0,
    this.prixVente = 0.0,
    this.seuilAlerte = 5,
    this.imageUrl,
  });

  // 🔄 Copie de l'objet avec modifications ciblées
  Produit copyWith({
    String? id,
    String? entrepriseId,
    String? codeBarre,
    String? nom,
    String? categorie,
    int? quantite,
    double? prixAchat,
    double? prixVente,
    int? seuilAlerte,
    String? imageUrl,
  }) {
    return Produit(
      id: id ?? this.id,
      entrepriseId: entrepriseId ?? this.entrepriseId,
      codeBarre: codeBarre ?? this.codeBarre,
      nom: nom ?? this.nom,
      categorie: categorie ?? this.categorie,
      quantite: quantite ?? this.quantite,
      prixAchat: prixAchat ?? this.prixAchat,
      prixVente: prixVente ?? this.prixVente,
      seuilAlerte: seuilAlerte ?? this.seuilAlerte,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  // Conversion sécurisée depuis Firestore / JSON (tolère les nombres, décimaux Excel et chaînes)
  factory Produit.fromJson(Map<String, dynamic> json, [String? docId]) {
    return Produit(
      id: docId ?? json['id'] as String? ?? '',
      entrepriseId: json['entrepriseId'] as String? ?? '',
      codeBarre: json['codeBarre'] as String? ?? json['code_barre'] as String? ?? '',
      nom: json['nom'] as String? ?? '',
      categorie: json['categorie'] as String? ?? 'Général',
      quantite: (num.tryParse(json['quantite']?.toString() ?? '0') ?? 0).toInt(),
      prixAchat: double.tryParse(json['prixAchat']?.toString() ?? '0') ?? 0.0,
      prixVente: double.tryParse(
            (json['prixVente'] ?? json['prix'])?.toString() ?? '0',
          ) ??
          0.0,
      seuilAlerte: (num.tryParse(json['seuilAlerte']?.toString() ?? '5') ?? 5).toInt(),
      imageUrl: json['imageUrl'] as String?,
    );
  }

  // Conversion vers Firestore / JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'entrepriseId': entrepriseId,
      'codeBarre': codeBarre,
      'nom': nom,
      'categorie': categorie,
      'quantite': quantite,
      'prixAchat': prixAchat,
      'prixVente': prixVente,
      'seuilAlerte': seuilAlerte,
      'imageUrl': imageUrl,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Produit &&
        other.id == id &&
        other.entrepriseId == entrepriseId &&
        other.codeBarre == codeBarre &&
        other.nom == nom &&
        other.categorie == categorie &&
        other.quantite == quantite &&
        other.prixAchat == prixAchat &&
        other.prixVente == prixVente &&
        other.seuilAlerte == seuilAlerte &&
        other.imageUrl == imageUrl;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      entrepriseId,
      codeBarre,
      nom,
      categorie,
      quantite,
      prixAchat,
      prixVente,
      seuilAlerte,
      imageUrl,
    );
  }

  @override
  String toString() =>
      'Produit(id: $id, nom: $nom, quantite: $quantite, prixVente: $prixVente)';
}