import 'package:flutter_test/flutter_test.dart';
import 'package:stockly_saas/features/accounting/services/soldes_mensuels_service.dart';

void main() {
  group('Soldes mensuels', () {
    final ecritures = [
      {
        'boutiqueId': 'principale',
        'lines': [
          {'accountCode': '571000', 'debit': 45, 'credit': 0},
          {'accountCode': '701000', 'debit': 0, 'credit': 45},
        ],
      },
      {
        'boutiqueId': 'b2',
        'lines': [
          {'accountCode': '571000', 'debit': 10, 'credit': 0},
          {'accountCode': '701000', 'debit': 0, 'credit': 10},
        ],
      },
      {
        // ancienne écriture sans boutique = principale
        'lines': [
          {'accountCode': '605000', 'debit': 5, 'credit': 0},
          {'accountCode': '571000', 'debit': 0, 'credit': 5},
        ],
      },
    ];

    test('totaux nets (débit − crédit) par boutique et par compte', () {
      final s = SoldesMensuelsService.totaliser(ecritures);
      expect(s['principale']!['571000'], 40);
      expect(s['principale']!['701000'], -45);
      expect(s['principale']!['605000'], 5);
      expect(s['b2']!['571000'], 10);
    });

    test('cumul de plusieurs mois et filtre par boutique', () {
      final total = <String, Map<String, double>>{};
      SoldesMensuelsService.ajouter(total, SoldesMensuelsService.totaliser(ecritures));
      SoldesMensuelsService.ajouter(total, SoldesMensuelsService.totaliser(ecritures));
      expect(SoldesMensuelsService.pourBoutique(total, null)['571000'], 100);
      expect(SoldesMensuelsService.pourBoutique(total, 'b2')['701000'], -20);
    });

    test('clé et bornes de mois', () {
      expect(SoldesMensuelsService.cleMois(DateTime(2026, 3, 15)), '2026-03');
      expect(SoldesMensuelsService.moisSuivant(DateTime(2026, 12)), DateTime(2027, 1));
    });
  });
}
