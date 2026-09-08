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
  static FinancialCalculationResult computePL({
    required List<dynamic> toutesLesDepenses,
    required List<QueryDocumentSnapshot> produitsDocs,
    required List<QueryDocumentSnapshot> ventesDocs,
    required DateTimeRange dateRange,
    required String entrepriseId,
  }) {
    // 1. Filtrage et cumul des dépenses
    final depensesFiltrees = toutesLesDepenses.where((d) {
      return d.date.isAfter(dateRange.start.subtract(const Duration(seconds: 1))) &&
          d.date.isBefore(dateRange.end.add(const Duration(seconds: 1)));
    }).toList();

    double totalDepenses = 0.0;
    final Map<String, double> depensesParCategorie = {};

    for (var depense in depensesFiltrees) {
      final montant = (depense.montant as num).toDouble();
      totalDepenses += montant;
      depensesParCategorie[depense.categorie.toString()] =
          (depensesParCategorie[depense.categorie.toString()] ?? 0.0) + montant;
    }

    // 2. Mapping des prix d'achat produits
    final Map<String, double> prixAchatParId = {};
    final Map<String, double> prixAchatParNom = {};

    for (var prodDoc in produitsDocs) {
      final pData = prodDoc.data() as Map<String, dynamic>;
      final pId = prodDoc.id;
      final pCustomId = pData['id']?.toString();
      final pNom = (pData['nom'] ?? pData['name'] ?? '').toString().trim().toLowerCase();

      final pAchat = (pData['prixAchat'] ??
              pData['prix_achat'] ??
              pData['achat'] ??
              pData['cost'] ??
              0.0) as num;

      prixAchatParId[pId] = pAchat.toDouble();
      if (pCustomId != null) prixAchatParId[pCustomId] = pAchat.toDouble();
      if (pNom.isNotEmpty) prixAchatParNom[pNom] = pAchat.toDouble();
    }

    // 3. Traitement des ventes et calcul des coûts
    double chiffreAffaires = 0.0;
    double coutAchatStockVendu = 0.0;

    final List<Map<String, dynamic>> detailsVentesList = [];
    final List<Map<String, dynamic>> detailsCoutAchatList = [];
    final List<Map<String, dynamic>> detailsMargeList = [];

    for (var doc in ventesDocs) {
      final data = doc.data() as Map<String, dynamic>;

      final docEntrepriseId = data['entrepriseId']?.toString();
      if (entrepriseId.isNotEmpty &&
          docEntrepriseId != null &&
          docEntrepriseId.isNotEmpty &&
          docEntrepriseId != entrepriseId) {
        continue;
      }

      double totalVente = 0.0;
      final items = (data['produits'] ?? data['items'] ?? []) as List;

      if (data['total'] != null) {
        totalVente = (data['total'] as num).toDouble();
      } else if (data['montantTotal'] != null) {
        totalVente = (data['montantTotal'] as num).toDouble();
      } else if (data['montantPaye'] != null) {
        totalVente = (data['montantPaye'] as num).toDouble();
      } else {
        for (var item in items) {
          totalVente += (item['total'] ??
              ((item['prix'] ?? 0.0) * (item['quantite'] ?? 1))).toDouble();
        }
      }

      DateTime? dateVente;
      final rawDate = data['date'] ?? data['createdAt'];
      if (rawDate is Timestamp) {
        dateVente = rawDate.toDate();
      } else if (rawDate is String) {
        dateVente = DateTime.tryParse(rawDate);
      }

      bool dansLaPeriode = true;
      if (dateVente != null) {
        dansLaPeriode = dateVente.isAfter(dateRange.start.subtract(const Duration(seconds: 1))) &&
            dateVente.isBefore(dateRange.end.add(const Duration(seconds: 1)));
      }

      if (dansLaPeriode) {
        chiffreAffaires += totalVente;

        for (var item in items) {
          final qte = (item['quantite'] ?? item['quantity'] ?? 1) as num;
          final nom = (item['nom'] ?? item['name'] ?? item['produit'] ?? 'Produit').toString();
          final prixVenteTotal = (item['total'] ??
                  ((item['prix'] ?? 0.0) * qte))
              .toDouble();

          double prixAchatItem = ((item['prixAchat'] ??
                  item['prix_achat'] ??
                  item['achat'] ??
                  0.0) as num).toDouble();

          if (prixAchatItem == 0) {
            final pId = (item['produitId'] ?? item['productId'] ?? item['id'])?.toString();
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

          final double totalCoutItem = (prixAchatItem * qte).toDouble();
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