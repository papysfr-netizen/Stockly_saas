import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/currency_provider.dart';

extension CurrencyFormattingExtension on WidgetRef {
  String formatPrice(double amountInUSD) {
    return watch(currencyProvider).formatPrice(amountInUSD);
  }

  CurrencyInfo get activeCurrency => watch(activeCurrencyInfoProvider);
}