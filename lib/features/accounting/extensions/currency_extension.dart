import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stockly_saas/core/providers/currency_provider.dart';

extension CurrencyFormattingExtension on WidgetRef {
  /// Formate directement un prix USD selon la devise active configurée
  String formatPrice(double amountInUSD) {
    return watch(currencyProvider).formatPrice(amountInUSD);
  }

  /// Récupère la devise active
  CurrencyInfo get activeCurrency => watch(activeCurrencyInfoProvider);
}