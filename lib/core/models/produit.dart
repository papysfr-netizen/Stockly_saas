import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Modèle immuable représentant un produit en stock
@immutable
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

  // ================= GETTERS MÉTIER =================
  bool get estEnRupture => quantite <= 0;
  bool get estEnAlerte => quantite > 0 && quantite <= seuilAlerte;
  bool get estDisponible => quantite > 0;
  
  /// Indique si le produit possède une URL d'image valide
  bool get aUneImage => imageUrl != null && imageUrl!.trim().isNotEmpty;

  double get valeurStockAchat => quantite * prixAchat;
  double get valeurStockVente => quantite * prixVente;
  double get margeUnitaire => prixVente - prixAchat;
  
  /// Calcul du pourcentage de marge brute
  double get pourcentageMarge =>
      prixAchat > 0 ? ((prixVente - prixAchat) / prixAchat) * 100 : 0.0;

  // ================= COPYWITH =================
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

  // ================= DESERIALIZATION =================
  factory Produit.fromFirestore(Map<String, dynamic> data, String docId) {
    return Produit.fromMap(data, docId);
  }

  /// Factory directe depuis un DocumentSnapshot Firestore
  factory Produit.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Produit.fromMap(data, doc.id);
  }

  factory Produit.fromMap(Map<String, dynamic> map, [String? docId]) {
    // Helper sécurisé pour les nombres décimaux
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      String str = val.toString().trim().replaceAll(',', '.');
      return double.tryParse(str) ?? 0.0;
    }

    // Helper sécurisé pour les entiers
    int parseInt(dynamic val, [int defaultValue = 0]) {
      if (val == null) return defaultValue;
      if (val is num) return val.toInt();
      String str = val.toString().trim().replaceAll(',', '.');
      double? parsedDouble = double.tryParse(str);
      return parsedDouble?.toInt() ?? int.tryParse(str) ?? defaultValue;
    }

    // Helper sécurisé pour les chaînes de caractères
    String parseString(dynamic val, [String defaultValue = '']) {
      if (val == null) return defaultValue;
      final str = val.toString().trim();
      return str.isEmpty ? defaultValue : str;
    }

    // Validation sécurisée de l'image (convertit "" en null)
    String? parseImageUrl(dynamic val) {
      if (val == null) return null;
      final str = val.toString().trim();
      return str.isNotEmpty ? str : null;
    }

    return Produit(
      id: (docId != null && docId.isNotEmpty) ? docId : parseString(map['id']),
      entrepriseId: parseString(map['entrepriseId'] ?? map['entreprise_id']),
      codeBarre: parseString(map['codeBarre'] ?? map['code_barre'] ?? map['barcode']),
      nom: parseString(map['nom'] ?? map['name'], 'Sans nom'),
      categorie: parseString(map['categorie'] ?? map['category'], 'Général'),
      quantite: parseInt(map['quantite'] ?? map['quantity']),
      prixAchat: parseDouble(map['prixAchat'] ?? map['prix_achat'] ?? map['cost_price']),
      prixVente: parseDouble(
        map['prixVente'] ?? map['prix'] ?? map['prix_vente'] ?? map['selling_price'],
      ),
      seuilAlerte: parseInt(map['seuilAlerte'] ?? map['seuil_alerte'], 5),
      imageUrl: parseImageUrl(map['imageUrl'] ?? map['image_url'] ?? map['image']),
    );
  }

  factory Produit.fromJson(Map<String, dynamic> json, [String? docId]) =>
      Produit.fromMap(json, docId);

  // ================= SERIALIZATION =================
  Map<String, dynamic> toMap() {
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

  Map<String, dynamic> toJson() => toMap();

  /// Map spécifique pour les écritures Firestore (si vous préférez ignorer l'ID dans le document)
  Map<String, dynamic> toFirestore() => toMap();

  // ================= ÉGALITÉ & HASHCODE =================
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
      'Produit(id: $id, nom: $nom, quantite: $quantite, prixVente: $prixVente, entrepriseId: $entrepriseId)';
}