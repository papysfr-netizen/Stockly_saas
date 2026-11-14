import 'package:flutter_test/flutter_test.dart';
import 'package:stockly_saas/core/models/dette.dart';

void main() {
  test('compte du tiers selon l\'origine (SYSCOHADA)', () {
    expect(OrigineDette.compteTiers(TypeDette.client, OrigineDette.vente), '411000');
    expect(OrigineDette.compteTiers(TypeDette.client, OrigineDette.cahier), '411000');
    expect(OrigineDette.compteTiers(TypeDette.client, OrigineDette.pret), '471000');
    expect(OrigineDette.compteTiers(TypeDette.fournisseur, OrigineDette.achat), '401000');
    expect(OrigineDette.compteTiers(TypeDette.fournisseur, OrigineDette.cahier), '401000');
    expect(OrigineDette.compteTiers(TypeDette.fournisseur, OrigineDette.emprunt), '168000');
  });

  test('une ancienne dette (sans origine) reste une vente ou un achat', () {
    final client = Dette.fromJson({'type': 'client', 'montantInitial': 10, 'montantReste': 10}, 'c1');
    final fournisseur =
        Dette.fromJson({'type': 'fournisseur', 'montantInitial': 10, 'montantReste': 10}, 'f1');
    expect(client.origine, OrigineDette.vente);
    expect(fournisseur.origine, OrigineDette.achat);
  });

  test('l\'origine est relue et réécrite', () {
    final d = Dette.fromJson(
        {'type': 'client', 'origine': 'pret', 'montantInitial': 50, 'montantReste': 50}, 'c2');
    expect(d.origine, OrigineDette.pret);
    expect(d.compteTiers, '471000');
    expect(d.toFirestore()['origine'], 'pret');
  });
}
