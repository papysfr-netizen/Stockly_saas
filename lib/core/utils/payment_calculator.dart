// lib/core/utils/payment_calculator.dart

/// Convertit un texte saisi en nombre.
/// - accepte la virgule OU le point comme séparateur décimal ("12,5" ou "12.5")
/// - ignore les espaces ("1 500" devient 1500)
/// - retourne 0.0 si le texte est vide, invalide ou négatif
double parseAmount(String text) {
  final cleaned = text.trim().replaceAll(' ', '').replaceAll(',', '.');
  final value = double.tryParse(cleaned) ?? 0.0;
  if (value.isNaN || value.isInfinite || value < 0) return 0.0;
  return value;
}

class PaymentResult {
  /// Écart accepté (en USD) : 1 centime.
  /// Évite qu'un arrondi de conversion (ex. 0.0000001 $) transforme une vente
  /// payée en "acompte" avec une micro-créance.
  static const double tolerance = 0.01;

  final double totalUSD;
  final double paidUSD;
  final double paidLocal;

  /// Nombre d'unités de devise locale pour 1 USD (ex. 2800 CDF pour 1 $).
  final double localRate;

  const PaymentResult({
    required this.totalUSD,
    required this.paidUSD,
    required this.paidLocal,
    required this.localRate,
  });

  /// Total cumulé payé par le client, converti en USD (protégé contre un taux nul).
  double get totalPaidInUSD =>
      paidUSD + (localRate > 0 ? (paidLocal / localRate) : 0.0);

  /// Indique si la somme perçue couvre le total (à 1 centime près).
  bool get isFullyPaid => totalPaidInUSD >= (totalUSD - tolerance);

  /// Solde restant dû en USD : 0.0 si la vente est couverte ou surpayée.
  double get remainingUSD => isFullyPaid ? 0.0 : (totalUSD - totalPaidInUSD);

  /// Monnaie à rendre en USD (jamais négative, donc plus de "-0.00").
  double get changeInUSD {
    if (!isFullyPaid) return 0.0;
    final change = totalPaidInUSD - totalUSD;
    return change > 0 ? change : 0.0;
  }

  /// Monnaie à rendre convertie dans la devise locale.
  double get changeInLocal => changeInUSD * localRate;
}