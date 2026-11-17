import 'package:flutter_test/flutter_test.dart';
import 'package:stockly_saas/features/arrivages/lots_service.dart';

void main() {
  // 5 pièces anciennes + arrivage A (10 reçues, 4 vendues) + arrivage B (20 reçues)
  final produit = <String, dynamic>{
    'quantite': 31,
    'lots': [
      {'a': 'A', 'q': 10, 'pa': 6.0},
      {'a': 'B', 'q': 20, 'pa': 7.0},
    ],
    'lotsVendus': {'A': 4},
    'lotsCA': {'A': 40.0},
  };

  group('Stock par arrivage', () {
    test('restants et stock ancien', () {
      final l = LotsService.lots(produit);
      expect(l.map((x) => x.restant), [6, 20]);
      expect(LotsService.stockAncien(produit), 5);
      expect(l.first.cout, 24);
      expect(l.first.marge, 16);
    });

    test('une vente prend le stock ancien, puis le plus ancien arrivage', () {
      expect(LotsService.allouer(produit, 3), isEmpty);
      expect(LotsService.allouer(produit, 8), [const AllocationLot('A', 3)]);
      expect(LotsService.allouer(produit, 15), [const AllocationLot('A', 6), const AllocationLot('B', 4)]);
      // plus que le stock : on ne note que ce qui existe
      expect(LotsService.allouer(produit, 40), [const AllocationLot('A', 6), const AllocationLot('B', 20)]);
    });

    test('un retour rend d\'abord au plus récent arrivage de la vente', () {
      const vente = [AllocationLot('A', 6), AllocationLot('B', 4)];
      // vente de 15 : 5 anciennes + 6 A + 4 B
      expect(LotsService.rendre(vente, 15, 3), isEmpty); // les 5 anciennes d'abord
      expect(LotsService.rendre(vente, 15, 8), [const AllocationLot('B', 3)]);
      expect(LotsService.rendre(vente, 15, 15), [const AllocationLot('B', 4), const AllocationLot('A', 6)]);
    });

    test('deux retours successifs ne rendent pas deux fois au même arrivage', () {
      const vente = [AllocationLot('A', 6), AllocationLot('B', 4)];
      // 1er retour : 8 pièces (5 anciennes + 3 de B) ; 2e retour : 4 pièces (1 de B + 3 de A)
      expect(LotsService.rendreEnPlus(vente, 15, 0, 8), [const AllocationLot('B', 3)]);
      expect(LotsService.rendreEnPlus(vente, 15, 8, 4), [const AllocationLot('B', 1), const AllocationLot('A', 3)]);
    });

    test('sans arrivage suivi : rien n\'est noté', () {
      expect(LotsService.allouer({'quantite': 12}, 5), isEmpty);
      expect(LotsService.stockAncien({'quantite': 12}), 12);
    });
  });
}
