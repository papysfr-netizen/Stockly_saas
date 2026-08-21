import 'package:flutter_riverpod/flutter_riverpod.dart';

class CurrencyInfo {
  final String code;
  final String symbol;
  final String name;
  final double rateToUSD; // Combien vaut 1 USD dans cette devise

  const CurrencyInfo({
    required this.code,
    required this.symbol,
    required this.name,
    required this.rateToUSD,
  });
}

class CurrencyState {
  final String activeCurrency;
  final double bccCdfRate; // Taux Officiel BCC (Ex: 1 USD = 2850 CDF)
  final Map<String, CurrencyInfo> currencies;

  CurrencyState({
    required this.activeCurrency,
    required this.bccCdfRate,
    required this.currencies,
  });

  CurrencyState copyWith({
    String? activeCurrency,
    double? bccCdfRate,
    Map<String, CurrencyInfo>? currencies,
  }) {
    return CurrencyState(
      activeCurrency: activeCurrency ?? this.activeCurrency,
      bccCdfRate: bccCdfRate ?? this.bccCdfRate,
      currencies: currencies ?? this.currencies,
    );
  }
}

class CurrencyNotifier extends StateNotifier<CurrencyState> {
  CurrencyNotifier()
      : super(CurrencyState(
          activeCurrency: 'USD',
          bccCdfRate: 2850.0, // Taux de référence BCC par défaut
          currencies: _initialCurrencies(2850.0),
        ));

  static Map<String, CurrencyInfo> _initialCurrencies(double cdfRate) {
    return {
      'USD': const CurrencyInfo(code: 'USD', symbol: '\$', name: 'Dollar Américain', rateToUSD: 1.0),
      'CDF': CurrencyInfo(code: 'CDF', symbol: 'FC', name: 'Franc Congolais (BCC)', rateToUSD: cdfRate),
      'EUR': const CurrencyInfo(code: 'EUR', symbol: '€', name: 'Euro', rateToUSD: 0.92),
      'XOF': const CurrencyInfo(code: 'XOF', symbol: 'FCFA', name: 'Franc CFA (UEMOA)', rateToUSD: 605.0),
      'XAF': const CurrencyInfo(code: 'XAF', symbol: 'FCFA', name: 'Franc CFA (CEMAC)', rateToUSD: 605.0),
      'KES': const CurrencyInfo(code: 'KES', symbol: 'KSh', name: 'Shilling Kényan', rateToUSD: 129.0),
      'RWF': const CurrencyInfo(code: 'RWF', symbol: 'FRw', name: 'Franc Rwandais', rateToUSD: 1350.0),
      'UGX': const CurrencyInfo(code: 'UGX', symbol: 'USh', name: 'Shilling Ougandais', rateToUSD: 3700.0),
      'TZS': const CurrencyInfo(code: 'TZS', symbol: 'TSh', name: 'Shilling Tanzanien', rateToUSD: 2700.0),
      'ZAR': const CurrencyInfo(code: 'ZAR', symbol: 'R', name: 'Rand Sud-Africain', rateToUSD: 18.2),
      'AOA': const CurrencyInfo(code: 'AOA', symbol: 'Kz', name: 'Kwanza Angolais', rateToUSD: 910.0),
      'NGN': const CurrencyInfo(code: 'NGN', symbol: '₦', name: 'Naira Nigérian', rateToUSD: 1600.0),
      'GBP': const CurrencyInfo(code: 'GBP', symbol: '£', name: 'Livre Sterling', rateToUSD: 0.78),
      'CAD': const CurrencyInfo(code: 'CAD', symbol: 'C\$', name: 'Dollar Canadien', rateToUSD: 1.36),
      'CHF': const CurrencyInfo(code: 'CHF', symbol: 'CHF', name: 'Franc Suisse', rateToUSD: 0.89),
      'CNY': const CurrencyInfo(code: 'CNY', symbol: '¥', name: 'Yuan Chinois', rateToUSD: 7.25),
      'INR': const CurrencyInfo(code: 'INR', symbol: '₹', name: 'Roupie Indienne', rateToUSD: 83.5),
      'AED': const CurrencyInfo(code: 'AED', symbol: 'AED', name: 'Dirham Émirats', rateToUSD: 3.67),
      'SAR': const CurrencyInfo(code: 'SAR', symbol: 'SAR', name: 'Riyal Saoudien', rateToUSD: 3.75),
      'JPY': const CurrencyInfo(code: 'JPY', symbol: '¥', name: 'Yen Japonais', rateToUSD: 155.0),
    };
  }

  void setCurrency(String code) {
    state = state.copyWith(activeCurrency: code);
  }

  // Mettre à jour le taux officiel de la Banque Centrale du Congo (USD -> CDF)
  void updateBccRate(double newRate) {
    final updatedCurrencies = Map<String, CurrencyInfo>.from(state.currencies);
    updatedCurrencies['CDF'] = CurrencyInfo(
      code: 'CDF',
      symbol: 'FC',
      name: 'Franc Congolais (BCC)',
      rateToUSD: newRate,
    );
    state = state.copyWith(bccCdfRate: newRate, currencies: updatedCurrencies);
  }

  // Fonction de conversion à utiliser dans toute l'application (en supposant des prix de base en USD)
  String formatPrice(double amountInUSD) {
    final currentCurr = state.currencies[state.activeCurrency]!;
    final double converted = amountInUSD * currentCurr.rateToUSD;

    // Si c'est en Franc Congolais ou Franc CFA, on arrondit au nombre entier
    if (currentCurr.code == 'CDF' || currentCurr.code == 'XOF' || currentCurr.code == 'XAF' || currentCurr.code == 'RWF' || currentCurr.code == 'UGX') {
      return '${converted.toStringAsFixed(0)} ${currentCurr.symbol}';
    }

    return '${converted.toStringAsFixed(2)} ${currentCurr.symbol}';
  }
}

final currencyProvider = StateNotifierProvider<CurrencyNotifier, CurrencyState>((ref) {
  return CurrencyNotifier();
});