// lib/views/financial_analysis/services/financial_calculation_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FinancialCalculationResult {
  final double chiffreAffaires;
  final double coutAchatStockVendu;
  final double margeBrute;
  final double totalDepenses;
  final double beneficeNet;
  final bool isProfit;
  final Map<String, double> depensesParCategorie;
  final List<Map<String, dynamic>> detailsVentesList;
  final List<Map<String, dynamic>> detailsCoutAchatList;
  final List<Map<String, dynamic>> detailsMargeList;

  FinancialCalculationResult({
    required this.chiffreAffaires,
    required this.coutAchatStockVendu,
    required this.margeBrute,
    required this.totalDepenses,
    required this.beneficeNet,
    required this.isProfit,
    required this.depensesParCategorie,
    required this.detailsVentesList,
    required this.detailsCoutAchatList,
    required this.detailsMargeList,
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

    // 3. Traitement des ventes et calcul des coûts (retours déduits)
    double chiffreAffaires = 0.0;
    double coutAchatStockVendu = 0.0;

    final List<Map<String, dynamic>> detailsVentesList = [];
    final List<Map<String, dynamic>> detailsCoutAchatList = [];
    final List<Map<String, dynamic>> detailsMargeList = [];

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

      // ↩️ Retours : le chiffre d'affaires est NET des retours
      chiffreAffaires += totalVente - _num(data['montantRetourne']);

      for (var i = 0; i < items.length; i++) {
        final rawItem = items[i];
        if (rawItem is! Map) continue;
        final item = rawItem;

        final double qteBrute =
            _num(item['quantite'] ?? item['quantity'] ?? item['qte'], 1.0);
        final double qteRetournee = i < retours.length ? _num(retours[i]) : 0.0;
        final double qteNette =
            (qteBrute - qteRetournee) > 0 ? qteBrute - qteRetournee : 0.0;
        if (qteNette <= 0) continue; // tout a été retourné

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

      // ↩️ Articles retournés abîmés : ils ne reviennent pas en stock,
      // leur coût d'achat reste une charge (perte).
      final double perte = _num(data['coutAbimeRetours']);
      if (perte > 0.005) {
        coutAchatStockVendu += perte;

        detailsCoutAchatList.add({
          'nom': 'Pertes : articles retournés abîmés',
          'qte': 0,
          'prixAchatUnit': 0.0,
          'total': perte,
          'date': dateVente,
        });

        detailsMargeList.add({
          'nom': 'Pertes : articles retournés abîmés',
          'qte': 0,
          'totalVente': 0.0,
          'totalAchat': perte,
          'marge': -perte,
        });
      }
    }

    final margeBrute = chiffreAffaires - coutAchatStockVendu;
    final beneficeNet = margeBrute - totalDepenses;

    return FinancialCalculationResult(
      chiffreAffaires: chiffreAffaires,
      coutAchatStockVendu: coutAchatStockVendu,
      margeBrute: margeBrute,
      totalDepenses: totalDepenses,
      beneficeNet: beneficeNet,
      isProfit: beneficeNet >= 0,
      depensesParCategorie: depensesParCategorie,
      detailsVentesList: detailsVentesList,
      detailsCoutAchatList: detailsCoutAchatList,
      detailsMargeList: detailsMargeList,
    );
  }
}