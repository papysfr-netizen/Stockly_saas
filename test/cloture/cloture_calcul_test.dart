import 'package:flutter_test/flutter_test.dart';
import 'package:stockly_saas/features/cloture/cloture_service.dart';

void main() {
  group('Famille du moyen de paiement', () {
    test('espèces', () {
      expect(ClotureService.famille('Cash'), Famille.especes);
      expect(ClotureService.famille('cash'), Famille.especes);
      expect(ClotureService.famille('Espèces'), Famille.especes);
      expect(ClotureService.famille(null), Famille.especes);
    });
    test('mobile money', () {
      expect(ClotureService.famille('Mobile Money'), Famille.mobile);
      expect(ClotureService.famille('mobileMoney'), Famille.mobile);
      expect(ClotureService.famille('Mobile Money + Compte client'), Famille.mobile);
    });
    test('autres (non comptés dans le tiroir)', () {
      expect(ClotureService.famille('Carte bancaire'), Famille.autre);
      expect(ClotureService.famille('Virement'), Famille.autre);
      expect(ClotureService.famille('Compte client'), Famille.autre);
    });
  });

  test('identifiant : une clôture par boutique et par jour', () {
    expect(ClotureService.idCloture('principale', DateTime(2026, 11, 4)), 'principale_2026-11-04');
  });

  test('ancienne donnée sans boutique = boutique principale', () {
    expect(ClotureService.memeBoutique('principale', null), isTrue);
    expect(ClotureService.memeBoutique('principale', ''), isTrue);
    expect(ClotureService.memeBoutique('b2', ''), isFalse);
    expect(ClotureService.memeBoutique('b2', 'b2'), isTrue);
  });

  group('Résultat de la clôture (taux 2000 FC = 1 \$)', () {
    Attendu journee() => Attendu()
      ..ventesEspeces = 100
      ..dettesEspeces = 20
      ..depensesEspeces = 15
      ..remboursementsEspeces = 5
      ..ventesMobile = 30
      ..retraitsMobile = 10;

    Map<String, dynamic> cloture({double usd = 0, double cdf = 0, double mobile = 0}) => {
          'taux': 2000,
          'fondUSD': 10,
          'fondCDF': 20000, // = 10 $
          'compteUSD': usd,
          'compteCDF': cdf,
          'compteMobile': mobile,
        };

    test('caisse juste : fond 20 \$ + journée 100 \$ = 120 \$', () {
      // 100 $ en billets + 40 000 FC (= 20 $)
      final r = ResultatCloture(cloture(usd: 100, cdf: 40000, mobile: 20), journee());
      expect(r.fond, 20);
      expect(r.attendu.especes, 100);
      expect(r.especesAttendues, 120);
      expect(r.especesComptees, 120);
      expect(ResultatCloture.juste(r.ecartEspeces), isTrue);
      expect(r.mobileAttendu, 20);
      expect(ResultatCloture.juste(r.ecartMobile), isTrue);
    });

    test('il manque de l\'argent', () {
      final r = ResultatCloture(cloture(usd: 100, cdf: 0, mobile: 20), journee());
      expect(r.ecartEspeces, -20);
      expect(ResultatCloture.juste(r.ecartEspeces), isFalse);
    });

    test('surplus', () {
      final r = ResultatCloture(cloture(usd: 125, cdf: 0, mobile: 25), journee());
      expect(r.ecartEspeces, 5);
      expect(r.ecartMobile, 5);
    });

    test('un écart de quelques centimes est accepté', () {
      expect(ResultatCloture.juste(0.3), isTrue);
      expect(ResultatCloture.juste(-0.49), isTrue);
      expect(ResultatCloture.juste(0.5), isFalse);
    });

    test('taux absent : pas de division par zéro', () {
      final r = ResultatCloture({'compteCDF': 5000}, Attendu());
      expect(r.especesComptees, 5000);
    });
  });
}
