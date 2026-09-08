class PaymentResult {
  final double totalUSD;
  final double paidUSD;
  final double paidLocal;
  final double localRate;

  const PaymentResult({
    required this.totalUSD,
    required this.paidUSD,
    required this.paidLocal,
    required this.localRate,
  });

  /// Total cumulé payé par le client (converti en USD avec protection contre taux nul)
  double get totalPaidInUSD =>
      paidUSD + (localRate > 0 ? (paidLocal / localRate) : 0.0);

  /// Solde restant dû en USD (bloqué à 0.0 si la commande est surpayée)
  double get remainingUSD {
    final reste = totalUSD - totalPaidInUSD;
    return reste > 0 ? reste : 0.0;
  }

  /// Indique si la somme perçue couvre le total
  bool get isFullyPaid => totalPaidInUSD >= (totalUSD - 0.001);

  /// Monnaie à rendre exprimée en USD
  double get changeInUSD => isFullyPaid ? (totalPaidInUSD - totalUSD) : 0.0;

  /// Monnaie à rendre convertie dans la devise locale
  double get changeInLocal => changeInUSD * localRate;
}