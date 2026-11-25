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

  /// 📉 Coût des marchandises d'une vente, retours et annulations déduits
  /// (même calcul que l'Accueil et le Rapport ; aussi utilisé par l'assistant)
  static double coutNet(Map<dynamic, dynamic> v) {
    final brut = _n(v['coutMarchandises']);
    final articles = v['articles'] ?? v['produits'] ?? v['items'];
    final ret = v['quantitesRetournees'];
    final ann = v['quantitesAnnulees'];
    double qteTotale = 0, qteRendue = 0, coutRendu = 0;
    var prixConnus = true;
    if (articles is List) {
      for (var i = 0; i < articles.length; i++) {
        final a = articles[i];
        if (a is! Map) continue;
        final q = _n(a['quantite']);
        var r = (ret is List && i < ret.length ? _n(ret[i]) : 0.0) +
            (ann is List && i < ann.length ? _n(ann[i]) : 0.0);
        if (r > q) r = q;
        qteTotale += q;
        qteRendue += r;
        if (r > 0) {
          final pa = _n(a['prixAchat']);
          if (pa > 0) {
            coutRendu += pa * r;
          } else {
            prixConnus = false;
          }
        }
      }
    }
    // Ancienne vente sans prix d'achat par article : au prorata des quantités
    if (!prixConnus && qteTotale > 0) coutRendu = brut * qteRendue / qteTotale;
    return brut - coutRendu + _n(v['coutAbimeRetours']) - _n(v['montantConserve']);
  }
}
