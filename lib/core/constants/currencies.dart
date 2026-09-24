class StocklyCurrency {
  final String code;
  final String symbol;
  final String name;

  const StocklyCurrency({
    required this.code,
    required this.symbol,
    required this.name,
  });

  /// Conversion Map pour la persistance ou sérialisation
  Map<String, String> toMap() => {
        'code': code,
        'symbol': symbol,
        'name': name,
      };

  factory StocklyCurrency.fromMap(Map<String, dynamic> map) {
    return StocklyCurrency(
      code: map['code']?.toString() ?? 'USD',
      symbol: map['symbol']?.toString() ?? '\$',
      name: map['name']?.toString() ?? 'Dollar Américain',
    );
  }

  /// Liste globale des devises supportées
  static const List<StocklyCurrency> all = [
    StocklyCurrency(code: 'USD', symbol: '\$', name: 'Dollar Américain'),
    StocklyCurrency(code: 'CDF', symbol: 'FC', name: 'Franc Congolais (BCC)'),
    StocklyCurrency(code: 'EUR', symbol: '€', name: 'Euro'),
    StocklyCurrency(code: 'XOF', symbol: 'FCFA', name: 'Franc CFA (UEMOA)'),
    StocklyCurrency(code: 'XAF', symbol: 'FCFA', name: 'Franc CFA (CEMAC)'),
    StocklyCurrency(code: 'KES', symbol: 'KSh', name: 'Shilling Kényan'),
    StocklyCurrency(code: 'RWF', symbol: 'FRw', name: 'Franc Rwandais'),
    StocklyCurrency(code: 'UGX', symbol: 'USh', name: 'Shilling Ougandais'),
    StocklyCurrency(code: 'TZS', symbol: 'TSh', name: 'Shilling Tanzanien'),
    StocklyCurrency(code: 'ZAR', symbol: 'R', name: 'Rand Sud-Africain'),
    StocklyCurrency(code: 'AOA', symbol: 'Kz', name: 'Kwanza Angolais'),
    StocklyCurrency(code: 'NGN', symbol: '₦', name: 'Naira Nigérian'),
    StocklyCurrency(code: 'GBP', symbol: '£', name: 'Livre Sterling'),
    StocklyCurrency(code: 'CAD', symbol: 'C\$', name: 'Dollar Canadien'),
    StocklyCurrency(code: 'CHF', symbol: 'CHF', name: 'Franc Suisse'),
    StocklyCurrency(code: 'CNY', symbol: '¥', name: 'Yuan Chinois'),
    StocklyCurrency(code: 'INR', symbol: '₹', name: 'Roupie Indienne'),
    StocklyCurrency(code: 'AED', symbol: 'AED', name: 'Dirham Émirats'),
    StocklyCurrency(code: 'SAR', symbol: 'SAR', name: 'Riyal Saoudien'),
    StocklyCurrency(code: 'JPY', symbol: '¥', name: 'Yen Japonais'),
  ];

  /// Recherche une devise par son code ISO (ex: 'USD') avec repli de sécurité
  static StocklyCurrency findByCode(String code, {StocklyCurrency? fallback}) {
    return all.firstWhere(
      (c) => c.code.toUpperCase() == code.trim().toUpperCase(),
      orElse: () => fallback ?? all.first,
    );
  }

  /// Extrait directement le symbole d'un code (ex: 'CDF' -> 'FC')
  static String getSymbol(String code) {
    return findByCode(code).symbol;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StocklyCurrency &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => '$name ($symbol)';
}