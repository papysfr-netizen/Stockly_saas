/// 💵 Calcul UNIQUE de l'argent d'une vente (utilisé par l'Accueil et le résumé WhatsApp).
class ArgentVente {
  static double _n(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse('${v ?? ''}'.replaceAll(',', '.')) ?? 0.0;

  /// Argent reçu en caisse AU MOMENT de la vente :
  /// payé (sans la monnaie rendue), moins la part payée avec le compte client.
  /// Les remboursements des retours sont comptés à part, le jour du retour.
  static double cashALaVente(Map<dynamic, dynamic> v) {
    final total = _n(v['montantTotal'] ?? v['total']);
    final paye = _n(v['montantPaye']);
    final payeVente = total > 0 && paye > total ? total : paye;
    final cash = payeVente - _n(v['montantCompteClient']);
    return cash > 0 ? cash : 0.0;
  }
}
