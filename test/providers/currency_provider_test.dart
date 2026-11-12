import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stockly_saas/core/providers/currency_provider.dart';

void main() {
  // Simule le stockage du téléphone (SharedPreferences) pendant les tests
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('CurrencyNotifier Tests', () {
    test('L\'état initial par défaut est correct (USD)', () {
      final state = container.read(currencyProvider);

      expect(state.activeCurrency, 'USD');
      expect(state.activeCurrencyInfo.code, 'USD');
      expect(state.bccCdfRate, 2850.0);
      expect(state.currencies.containsKey('USD'), true);
      expect(state.currencies.containsKey('CDF'), true);
    });

    test('Changement de devise active', () {
      final notifier = container.read(currencyProvider.notifier);

      notifier.setCurrency('CDF');
      var state = container.read(currencyProvider);

      expect(state.activeCurrency, 'CDF');
      expect(state.activeCurrencyInfo.symbol, 'FC');

      // Tente de définir une devise inexistante (doit être ignoré)
      notifier.setCurrency('XYZ');
      state = container.read(currencyProvider);
      expect(state.activeCurrency, 'CDF');
    });

    test('Conversion et formatage des prix', () {
      final notifier = container.read(currencyProvider.notifier);

      // USD ($10.00)
      var state = container.read(currencyProvider);
      expect(state.convertFromUSD(10.0), 10.0);
      expect(state.formatPrice(10.0), '10.00 \$');

      // CDF (2850 FC par USD -> $10.00 = 28500 FC)
      notifier.setCurrency('CDF');
      state = container.read(currencyProvider);
      expect(state.convertFromUSD(10.0), 28500.0);
      expect(state.formatPrice(10.0), '28500 FC');
    });

    test('Mise à jour d\'un taux de change', () {
      final notifier = container.read(currencyProvider.notifier);

      notifier.updateRate('CDF', 3000.0);
      final state = container.read(currencyProvider);

      expect(state.bccCdfRate, 3000.0);
      expect(state.currencies['CDF']?.rateToUSD, 3000.0);
    });

    test('Ajout d\'une nouvelle devise', () {
      final notifier = container.read(currencyProvider.notifier);

      const newCurrency = CurrencyInfo(
        code: 'TRY',
        symbol: '₺',
        name: 'Livre Turque',
        rateToUSD: 32.5,
        decimalDigits: 2,
      );

      notifier.addCurrency(newCurrency);
      final state = container.read(currencyProvider);

      expect(state.currencies.containsKey('TRY'), true);
      expect(state.currencies['TRY']?.symbol, '₺');
    });

    test('Protection à la suppression (USD et devise active)', () {
      final notifier = container.read(currencyProvider.notifier);

      // Essai de supprimer USD (interdit)
      notifier.removeCurrency('USD');
      var state = container.read(currencyProvider);
      expect(state.currencies.containsKey('USD'), true);

      // Devise active = EUR -> Essai de supprimer EUR (interdit)
      notifier.setCurrency('EUR');
      notifier.removeCurrency('EUR');
      state = container.read(currencyProvider);
      expect(state.currencies.containsKey('EUR'), true);

      // Suppression d'une devise non active (GBP) -> Autorisé
      notifier.removeCurrency('GBP');
      state = container.read(currencyProvider);
      expect(state.currencies.containsKey('GBP'), false);
    });
  });

  group('Provider Selectors Tests', () {
    test('activeCurrencyInfoProvider retourne la bonne devise', () {
      final activeInfo = container.read(activeCurrencyInfoProvider);
      expect(activeInfo.code, 'USD');

      container.read(currencyProvider.notifier).setCurrency('EUR');
      final updatedActiveInfo = container.read(activeCurrencyInfoProvider);
      expect(updatedActiveInfo.code, 'EUR');
    });

    test('availableCurrenciesProvider liste toutes les devises', () {
      final list = container.read(availableCurrenciesProvider);
      expect(list.isNotEmpty, true);
      expect(list.any((c) => c.code == 'USD'), true);
    });
  });
}