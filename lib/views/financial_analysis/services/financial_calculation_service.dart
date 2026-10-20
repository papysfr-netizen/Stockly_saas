// lib/views/financial_analysis/services/financial_calculation_service.dart
//
// Compte de résultat (P&L) présenté comme un vrai compte de résultat :
//
//   Ventes brutes
//   − Retours et annulations
//   = CHIFFRE D'AFFAIRES NET
//   − Coût des marchandises vendues
//   = MARGE BRUTE
//   + Autres produits (acomptes conservés lors d'annulations)
//   − Charges et dépenses
//   − Pertes (articles retournés abîmés)
//   = RÉSULTAT NET

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FinancialCalculationResult {
  // --- Lignes du compte de résultat ---
  final double ventesBrutes;
  final double retoursAnnulations;
  final double chiffreAffaires; // CA net = ventes brutes − retours/annulations
  final double coutAchatStockVendu; // coût des marchandises vendues (sans les pertes)
  final double margeBrute;
  final double autresProduits; // acomptes conservés
  final double totalDepenses;
  final double pertes; // articles retournés abîmés
  final double beneficeNet;
  final bool isProfit;

  // --- Indicateurs ---
  final int nombreVentes;

  // --- 📊 Rapport du patron ---
  /// Argent payé au moment des ventes de la période
  final double encaisse;
  /// Reste à payer sur les ventes de la période (crédits accordés)
  final double creditsAccordes;
  /// Vendeur -> montant vendu (net des retours) / nombre de ventes
  final Map<String, double> ventesParVendeur;
  final Map<String, int> nbVentesParVendeur;

  /// Marge brute en % du CA net (0 si pas de CA)
  double get tauxMargeBrute =>
      chiffreAffaires.abs() < 0.005 ? 0 : margeBrute / chiffreAffaires * 100;

  /// Résultat net en % du CA net (0 si pas de CA)
  double get tauxMargeNette =>
      chiffreAffaires.abs() < 0.005 ? 0 : beneficeNet / chiffreAffaires * 100;

  /// Panier moyen (CA net / nombre de ventes)
  double get panierMoyen => nombreVentes == 0 ? 0 : chiffreAffaires / nombreVentes;

  // --- Détails ---
  final Map<String, double> depensesParCategorie;
  final List<Map<String, dynamic>> detailsVentesList;
  final List<Map<String, dynamic>> detailsCoutAchatList;
  final List<Map<String, dynamic>> detailsMargeList;
  final List<Map<String, dynamic>> detailsRetoursList;
  final List<Map<String, dynamic>> detailsAutresProduitsList;
  final List<Map<String, dynamic>> detailsPertesList;

  FinancialCalculationResult({
    required this.ventesBrutes,
    required this.retoursAnnulations,
    required this.chiffreAffaires,
    required this.coutAchatStockVendu,
    required this.margeBrute,
    required this.autresProduits,
    required this.totalDepenses,
    required this.pertes,
    required this.beneficeNet,
    required this.isProfit,
    required this.nombreVentes,
    required this.depensesParCategorie,
    required this.detailsVentesList,
    required this.detailsCoutAchatList,
    required this.detailsMargeList,
    required this.detailsRetoursList,
    required this.detailsAutresProduitsList,
    required this.detailsPertesList,
    this.encaisse = 0,
    this.creditsAccordes = 0,
    this.ventesParVendeur = const {},
    this.nbVentesParVendeur = const {},
  });
}

class FinancialCalculationService {
  /// Lecture sécurisée d'un nombre (num, ou texte avec virgule/point).
  static double _num(dynamic value, [double defaut = 0.0]) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString().trim().replaceAll(',', '.') ?? '') ??
        defaut;
  }

  /// Lecture sécurisée d'une date (Timestamp, DateTime, texte ISO, millisecondes).
  static DateTime? _date(dynamic raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw);
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
    return null;
  }

  /// Total d'une ligne d'article : accepte les champs écrits par la caisse
  /// ("totalItem", "prixUnitaire") et les anciens ("total", "prix").
  static double _totalLigne(Map item) {
    final direct = item['totalItem'] ?? item['total'];
    if (direct != null) return _num(direct);
    final qte = _num(item['quantite'] ?? item['quantity'] ?? item['qte'], 1.0);
    return _num(item['prixUnitaire'] ?? item['prix'] ?? item['price']) * qte;
  }

  static FinancialCalculationResult computePL({
    required List<dynamic> toutesLesDepenses,
    required List<QueryDocumentSnapshot> produitsDocs,
    required List<QueryDocumentSnapshot> ventesDocs,
    required DateTimeRange dateRange,
    required String entrepriseId,
  }) {
    // PÉRIODE EN JOURS ENTIERS : du 1er jour à 00:00 jusqu'à la fin du dernier jour.
    final DateTime debut = DateTime(
        dateRange.start.year, dateRange.start.month, dateRange.start.day);
    final DateTime finExclusive = DateTime(
        dateRange.end.year, dateRange.end.month, dateRange.end.day + 1);

    bool dansLaPeriode(DateTime? d) =>
        d != null && !d.isBefore(debut) && d.isBefore(finExclusive);

    // 1. Filtrage et cumul des dépenses
    double totalDepenses = 0.0;
    final Map<String, double> depensesParCategorie = {};

    for (final depense in toutesLesDepenses) {
      final dateDepense = _date(depense.date);
      if (!dansLaPeriode(dateDepense)) continue;

      final montant = _num(depense.montant);
      totalDepenses += montant;
      final categorie = depense.categorie.toString();
      depensesParCategorie[categorie] =
          (depensesParCategorie[categorie] ?? 0.0) + montant;
    }

    // 2. Mapping des prix d'achat produits
    final Map<String, double> prixAchatParId = {};
    final Map<String, double> prixAchatParNom = {};

    for (final prodDoc in produitsDocs) {
      final pData = prodDoc.data() as Map<String, dynamic>;
      final pId = prodDoc.id;
      final pCustomId = pData['id']?.toString();
      final pNom =
          (pData['nom'] ?? pData['name'] ?? '').toString().trim().toLowerCase();

      final pAchat = _num(pData['prixAchat'] ??
          pData['prix_achat'] ??
          pData['achat'] ??
          pData['cost']);

      prixAchatParId[pId] = pAchat;
      if (pCustomId != null) prixAchatParId[pCustomId] = pAchat;
      if (pNom.isNotEmpty) prixAchatParNom[pNom] = pAchat;
    }

    // 3. Traitement des ventes
    double ventesBrutes = 0.0;
    double retoursAnnulations = 0.0;
    double coutAchatStockVendu = 0.0;
    double autresProduits = 0.0;
    double pertes = 0.0;
    int nombreVentes = 0;
    double encaisse = 0.0;
    double creditsAccordes = 0.0;
    final Map<String, double> ventesParVendeur = {};
    final Map<String, int> nbVentesParVendeur = {};

    final List<Map<String, dynamic>> detailsVentesList = [];
    final List<Map<String, dynamic>> detailsCoutAchatList = [];
    final List<Map<String, dynamic>> detailsMargeList = [];
    final List<Map<String, dynamic>> detailsRetoursList = [];
    final List<Map<String, dynamic>> detailsAutresProduitsList = [];
    final List<Map<String, dynamic>> detailsPertesList = [];

    for (final doc in ventesDocs) {
      final data = doc.data() as Map<String, dynamic>;

      final docEntrepriseId = data['entrepriseId']?.toString();
      if (entrepriseId.isNotEmpty &&
          docEntrepriseId != null &&
          docEntrepriseId.isNotEmpty &&
          docEntrepriseId != entrepriseId) {
        continue;
      }

      final dynamic rawItems = data['produits'] ?? data['articles'] ?? data['items'];
      final List<dynamic> items = rawItems is List ? rawItems : const [];

      // Quantités retournées (même ordre que les articles)
      final dynamic rawRetours = data['quantitesRetournees'];
      final List<dynamic> retours = rawRetours is List ? rawRetours : const [];

      // Total de la vente : total déclaré, sinon somme des lignes,
      // et en tout dernier recours le montant payé.
      double totalVente;
      final declare = data['total'] ?? data['montantTotal'];
      if (declare != null) {
        totalVente = _num(declare);
      } else {
        double somme = 0.0;
        for (final item in items) {
          if (item is Map) somme += _totalLigne(item);
        }
        totalVente = somme > 0 ? somme : _num(data['montantPaye']);
      }

      final DateTime? dateVente = _date(data['date'] ?? data['createdAt']);
      if (!dansLaPeriode(dateVente)) continue;

      final client = (data['nomClient'] ?? data['clientNom'] ?? '').toString();

      // Ventes brutes et retours / annulations
      nombreVentes++;
      ventesBrutes += totalVente;
      final double montantRetourne = _num(data['montantRetourne']);
      final double montantAnnule = _num(data['montantAnnule']);
      // 📊 Encaissé, crédits, vendeur
      encaisse += _num(data['montantPaye']);
      creditsAccordes += _num(data['resteAPayer']);
      final vendeurBrut = (data['vendeurNom'] ?? '').toString().trim();
      final vendeur = (vendeurBrut.isEmpty ||
              (vendeurBrut.length >= 20 && !vendeurBrut.contains(' ')))
          ? 'Non précisé'
          : vendeurBrut;
      ventesParVendeur[vendeur] = (ventesParVendeur[vendeur] ?? 0) +
          totalVente - montantRetourne - montantAnnule;
      nbVentesParVendeur[vendeur] = (nbVentesParVendeur[vendeur] ?? 0) + 1;
      if (montantRetourne > 0.005) {
        retoursAnnulations += montantRetourne;
        detailsRetoursList.add({
          'nom': client.isEmpty ? 'Retour de marchandise' : 'Retour : $client',
          'total': montantRetourne,
          'date': dateVente,
        });
      }
      if (montantAnnule > 0.005) {
        retoursAnnulations += montantAnnule;
        detailsRetoursList.add({
          'nom': client.isEmpty ? 'Annulation de vente' : 'Annulation : $client',
          'total': montantAnnule,
          'date': dateVente,
        });
      }

      // Acompte conservé par la boutique lors d'une annulation (compte 758)
      final double conserve = _num(data['montantConserve']);
      if (conserve > 0.005) {
        autresProduits += conserve;
        detailsAutresProduitsList.add({
          'nom': client.isEmpty ? 'Acompte conservé' : 'Acompte conservé : $client',
          'total': conserve,
          'date': dateVente,
        });
      }

      for (var i = 0; i < items.length; i++) {
        final rawItem = items[i];
        if (rawItem is! Map) continue;
        final item = rawItem;

        final double qteBrute =
            _num(item['quantite'] ?? item['quantity'] ?? item['qte'], 1.0);
        final dynamic rawAnnul = data['quantitesAnnulees'];
        final double qteAnnulee =
            (rawAnnul is List && i < rawAnnul.length) ? _num(rawAnnul[i]) : 0.0;
        final double qteRetournee =
            (i < retours.length ? _num(retours[i]) : 0.0) + qteAnnulee;
        final double qteNette =
            (qteBrute - qteRetournee) > 0 ? qteBrute - qteRetournee : 0.0;
        if (qteNette <= 0) continue; // tout a été retourné / annulé

        final num qte =
            qteNette == qteNette.roundToDouble() ? qteNette.toInt() : qteNette;
        final nom =
            (item['nom'] ?? item['name'] ?? item['produit'] ?? 'Produit').toString();

        final double totalLigneBrut = _totalLigne(item);
        final double prixVenteTotal =
            qteBrute > 0 ? totalLigneBrut * qteNette / qteBrute : totalLigneBrut;

        double prixAchatItem = _num(
            item['prixAchat'] ?? item['prix_achat'] ?? item['achat']);

        if (prixAchatItem == 0) {
          final pId =
              (item['produitId'] ?? item['productId'] ?? item['id'])?.toString();
          if (pId != null && prixAchatParId.containsKey(pId)) {
            prixAchatItem = prixAchatParId[pId]!;
          }
        }

        if (prixAchatItem == 0) {
          final pNom = nom.trim().toLowerCase();
          if (pNom.isNotEmpty && prixAchatParNom.containsKey(pNom)) {
            prixAchatItem = prixAchatParNom[pNom]!;
          }
        }

        final double totalCoutItem = prixAchatItem * qteNette;
        coutAchatStockVendu += totalCoutItem;

        detailsVentesList.add({
          'nom': nom,
          'qte': qte,
          'total': prixVenteTotal,
          'date': dateVente,
        });

        detailsCoutAchatList.add({
          'nom': nom,
          'qte': qte,
          'prixAchatUnit': prixAchatItem,
          'total': totalCoutItem,
          'date': dateVente,
        });

        detailsMargeList.add({
          'nom': nom,
          'qte': qte,
          'totalVente': prixVenteTotal,
          'totalAchat': totalCoutItem,
          'marge': prixVenteTotal - totalCoutItem,
        });
      }

      // Articles retournés abîmés : ils ne reviennent pas en stock,
      // leur coût d'achat est une PERTE (ligne à part).
      final double perte = _num(data['coutAbimeRetours']);
      if (perte > 0.005) {
        pertes += perte;
        detailsPertesList.add({
          'nom': client.isEmpty
              ? 'Articles retournés abîmés'
              : 'Articles abîmés : $client',
          'total': perte,
          'date': dateVente,
        });
      }
    }

    final chiffreAffaires = ventesBrutes - retoursAnnulations;
    final margeBrute = chiffreAffaires - coutAchatStockVendu;
    final beneficeNet = margeBrute + autresProduits - totalDepenses - pertes;

    return FinancialCalculationResult(
      ventesBrutes: ventesBrutes,
      retoursAnnulations: retoursAnnulations,
      chiffreAffaires: chiffreAffaires,
      coutAchatStockVendu: coutAchatStockVendu,
      margeBrute: margeBrute,
      autresProduits: autresProduits,
      totalDepenses: totalDepenses,
      pertes: pertes,
      beneficeNet: beneficeNet,
      isProfit: beneficeNet >= 0,
      nombreVentes: nombreVentes,
      depensesParCategorie: depensesParCategorie,
      detailsVentesList: detailsVentesList,
      detailsCoutAchatList: detailsCoutAchatList,
      detailsMargeList: detailsMargeList,
      detailsRetoursList: detailsRetoursList,
      detailsAutresProduitsList: detailsAutresProduitsList,
      detailsPertesList: detailsPertesList,
      encaisse: encaisse,
      creditsAccordes: creditsAccordes,
      ventesParVendeur: ventesParVendeur,
      nbVentesParVendeur: nbVentesParVendeur,
    );
  }
}
