import 'package:flutter_test/flutter_test.dart';
import 'package:stockly_saas/core/utils/payment_calculator.dart';

void main() {
  group('parseAmount : lecture du montant tapé à la caisse', () {
    test('accepte le point et la virgule', () {
      expect(parseAmount('12.5'), 12.5);
      expect(parseAmount('12,5'), 12.5); // clavier français
    });

    test('ignore les espaces des milliers', () {
      expect(parseAmount('1 500'), 1500);
      expect(parseAmount('  20 000 '), 20000);
    });

    test('vide, texte ou négatif = 0', () {
      expect(parseAmount(''), 0);
      expect(parseAmount('abc'), 0);
      expect(parseAmount('-5'), 0);
    });
  });

  group('PaymentResult : paiement en dollars et en francs', () {
    // Taux : 2800 FC pour 1 $
    PaymentResult paiement(double total, {double usd = 0, double fc = 0}) =>
        PaymentResult(totalUSD: total, paidUSD: usd, paidLocal: fc, localRate: 2800);

    test('paiement exact en dollars', () {
      final p = paiement(10, usd: 10);
      expect(p.isFullyPaid, isTrue);
      expect(p.remainingUSD, 0);
      expect(p.changeInUSD, 0);
    });

    test('paiement mixte dollars + francs', () {
      final p = paiement(10, usd: 5, fc: 14000); // 5 $ + 5 $
      expect(p.totalPaidInUSD, closeTo(10, 0.0001));
      expect(p.isFullyPaid, isTrue);
    });

    test('monnaie à rendre en dollars et en francs', () {
      final p = paiement(7, usd: 10);
      expect(p.changeInUSD, closeTo(3, 0.0001));
      expect(p.changeInLocal, closeTo(8400, 0.01));
    });

    test('acompte : il reste à payer, pas de monnaie', () {
      final p = paiement(10, usd: 4);
      expect(p.isFullyPaid, isFalse);
      expect(p.remainingUSD, closeTo(6, 0.0001));
      expect(p.changeInUSD, 0);
    });

    test('un centime d\'arrondi ne crée pas de dette', () {
      final p = paiement(10, usd: 9.995);
      expect(p.isFullyPaid, isTrue);
      expect(p.remainingUSD, 0);
    });

    test('taux à zéro : les francs sont ignorés sans planter', () {
      final p = PaymentResult(totalUSD: 10, paidUSD: 2, paidLocal: 5000, localRate: 0);
      expect(p.totalPaidInUSD, 2);
    });
  });
}
