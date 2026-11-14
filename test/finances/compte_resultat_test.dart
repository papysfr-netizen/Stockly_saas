import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stockly_saas/core/models/depense.dart';
import 'package:stockly_saas/views/financial_analysis/services/financial_calculation_service.dart';

final jour = DateTime(2026, 11, 14, 10);
final periode = DateTimeRange(start: DateTime(2026, 11, 14), end: DateTime(2026, 11, 14));
Timestamp ts(DateTime d) => Timestamp.fromDate(d);

Map<String, dynamic> vente({
  double total = 45,
  double paye = 45,
  double reste = 0,
  double retourne = 0,
  List<int> qtesRetournees = const [],
  double conserve = 0,
  double abime = 0,
  DateTime? date,
}) =>
    {
      'entrepriseId': 'ent1',
      'montantTotal': total,
      'montantPaye': paye,
      'resteAPayer': reste,
      if (retourne > 0) 'montantRetourne': retourne,
      if (qtesRetournees.isNotEmpty) 'quantitesRetournees': qtesRetournees,
      if (conserve > 0) 'montantConserve': conserve,
      if (abime > 0) 'coutAbimeRetours': abime,
      'vendeurNom': 'Jean Kabila',
      'date': ts(date ?? jour),
      'articles': [
        {'produitId': 'p1', 'nom': 'Chemise', 'quantite': 2, 'prixUnitaire': 10, 'totalItem': 20, 'prixAchat': 6},
        {'produitId': 'p2', 'nom': 'Jean', 'quantite': 1, 'prixUnitaire': 25, 'totalItem': 25, 'prixAchat': 15},
      ],
    };

FinancialCalculationResult calculer(List<Map<String, dynamic>> ventes, {List<Depense> depenses = const []}) =>
    FinancialCalculationService.calculer(
      toutesLesDepenses: depenses,
      produits: const [],
      ventes: ventes,
      dateRange: periode,
      entrepriseId: 'ent1',
    );

void main() {
  test('vente simple : CA, coût, marge, bénéfice', () {
    final r = calculer([vente()]);
    expect(r.chiffreAffaires, 45);
    expect(r.coutAchatStockVendu, 27); // 2 × 6 + 15
    expect(r.margeBrute, 18);
    expect(r.beneficeNet, 18);
    expect(r.nombreVentes, 1);
    expect(r.encaisse, 45);
  });

  test('dépenses déduites, seulement celles de la période', () {
    final r = calculer([vente()], depenses: [
      Depense(id: 'd1', entrepriseId: 'ent1', titre: 'Loyer', montant: 10, categorie: 'Loyer', date: jour),
      Depense(id: 'd2', entrepriseId: 'ent1', titre: 'Hier', montant: 99, categorie: 'Autre', date: jour.subtract(const Duration(days: 1))),
    ]);
    expect(r.totalDepenses, 10);
    expect(r.beneficeNet, 8);
  });

  test('retour d\'un jean : CA et coût diminuent', () {
    final r = calculer([vente(retourne: 25, qtesRetournees: [0, 1])]);
    expect(r.chiffreAffaires, 20);
    expect(r.coutAchatStockVendu, 12);
    expect(r.margeBrute, 8);
  });

  test('article abîmé : perte ; acompte gardé : autre produit', () {
    final r = calculer([vente(abime: 15, conserve: 5)]);
    expect(r.pertes, 15);
    expect(r.autresProduits, 5);
    expect(r.beneficeNet, 18 + 5 - 15);
  });

  test('vente à crédit : crédit accordé, encaissé partiel', () {
    final r = calculer([vente(paye: 15, reste: 30)]);
    expect(r.encaisse, 15);
    expect(r.creditsAccordes, 30);
    expect(r.chiffreAffaires, 45);
  });

  test('vente hors de la période ignorée', () {
    final r = calculer([vente(date: jour.subtract(const Duration(days: 2)))]);
    expect(r.nombreVentes, 0);
    expect(r.chiffreAffaires, 0);
  });

  group('Dettes créées dans Crédit', () {
    Map<String, dynamic> dette(String origine, {String venteId = ''}) => {
          'entrepriseId': 'ent1',
          'type': 'client',
          'origine': origine,
          if (venteId.isNotEmpty) 'venteId': venteId,
          'nomTiers': 'Mama Neema',
          'montantInitial': 100,
          'acomptePaye': 40,
          'montantReste': 60,
          'dateCreation': ts(jour),
        };

    test('« Vente hors caisse » compte comme une vente', () {
      final r = calculer([dette('vente')]);
      expect(r.chiffreAffaires, 100);
      expect(r.encaisse, 40);
      expect(r.creditsAccordes, 60);
      expect(r.nombreVentes, 1);
    });

    test('prêt, ancienne dette, ou dette d\'une vente de caisse : pas une vente', () {
      expect(calculer([dette('pret')]).chiffreAffaires, 0);
      expect(calculer([dette('cahier')]).chiffreAffaires, 0);
      expect(calculer([dette('vente', venteId: 'v1')]).chiffreAffaires, 0);
      // Ancienne dette sans origine : pas comptée non plus
      final sansOrigine = dette('vente')..remove('origine');
      expect(calculer([sansOrigine]).chiffreAffaires, 0);
    });
  });
}
