// 📦 STOCK PAR ARRIVAGE (« lots »), méthode du plus ancien d'abord
//
// Sur chaque fiche produit :
//   lots       : [{a: idArrivage, q: pièces reçues, pa: prix d'achat}]  (du plus ancien au plus récent)
//   lotsVendus : {idArrivage: pièces vendues}     (compteurs, toujours par incréments)
//   lotsCA     : {idArrivage: argent des ventes}  (compteurs, toujours par incréments)
//
// Le stock « ancien » (présent avant tout arrivage suivi) = stock total − pièces
// restantes des lots. Une vente le consomme D'ABORD, puis les arrivages du plus
// ancien au plus récent. Une vente note dans ses articles d'où viennent ses
// pièces (lots: [{a, q}]) : un retour les remet dans les mêmes arrivages.

class AllocationLot {
  final String arrivageId;
  final int quantite;
  const AllocationLot(this.arrivageId, this.quantite);

  Map<String, dynamic> versMap() => {'a': arrivageId, 'q': quantite};

  @override
  bool operator ==(Object o) => o is AllocationLot && o.arrivageId == arrivageId && o.quantite == quantite;
  @override
  int get hashCode => Object.hash(arrivageId, quantite);
  @override
  String toString() => '$arrivageId:$quantite';
}

/// Un arrivage vu depuis une fiche produit
class LotProduit {
  final String arrivageId;
  final int recu;
  final int vendu;
  final double prixAchat;
  final double chiffreAffaires;
  const LotProduit({
    required this.arrivageId,
    required this.recu,
    required this.vendu,
    required this.prixAchat,
    required this.chiffreAffaires,
  });

  int get restant => recu - vendu > 0 ? recu - vendu : 0;
  int get venduBorne => vendu < 0 ? 0 : (vendu > recu ? recu : vendu);
  double get cout => venduBorne * prixAchat;
  double get marge => chiffreAffaires - cout;
}

class LotsService {
  LotsService._();

  static int _i(dynamic v) => v is num ? v.toInt() : int.tryParse('${v ?? ''}') ?? 0;
  static double _d(dynamic v) => v is num ? v.toDouble() : double.tryParse('${v ?? ''}') ?? 0.0;

  /// Les arrivages d'un produit, du plus ancien au plus récent
  static List<LotProduit> lots(Map<String, dynamic> produit) {
    final vendus = produit['lotsVendus'] is Map ? produit['lotsVendus'] as Map : const {};
    final ca = produit['lotsCA'] is Map ? produit['lotsCA'] as Map : const {};
    return [
      for (final l in (produit['lots'] as List?) ?? const [])
        if (l is Map && (l['a'] ?? '').toString().isNotEmpty)
          LotProduit(
            arrivageId: l['a'].toString(),
            recu: _i(l['q']),
            vendu: _i(vendus[l['a']]),
            prixAchat: _d(l['pa']),
            chiffreAffaires: _d(ca[l['a']]),
          ),
    ];
  }

  /// Pièces d'avant les arrivages suivis (jamais négatif)
  static int stockAncien(Map<String, dynamic> produit) {
    final total = _i(produit['quantite']);
    final enLots = lots(produit).fold<int>(0, (s, l) => s + l.restant);
    final a = total - enLots;
    return a > 0 ? a : 0;
  }

  /// D'où viennent [quantite] pièces vendues : le stock ancien d'abord (non noté),
  /// puis les arrivages du plus ancien au plus récent
  static List<AllocationLot> allouer(Map<String, dynamic> produit, int quantite) {
    var reste = quantite - stockAncien(produit);
    final res = <AllocationLot>[];
    for (final l in lots(produit)) {
      if (reste <= 0) break;
      final q = l.restant < reste ? l.restant : reste;
      if (q > 0) {
        res.add(AllocationLot(l.arrivageId, q));
        reste -= q;
      }
    }
    return res;
  }

  /// Lit les arrivages notés dans un article de vente
  static List<AllocationLot> lireArticle(Map article) => [
        for (final l in (article['lots'] as List?) ?? const [])
          if (l is Map && (l['a'] ?? '').toString().isNotEmpty) AllocationLot(l['a'].toString(), _i(l['q'])),
      ];

  /// Retour de [quantite] pièces quand [deja] pièces de cette ligne sont déjà revenues
  static List<AllocationLot> rendreEnPlus(
      List<AllocationLot> vendus, int quantiteVendue, int deja, int quantite) {
    final avant = <String, int>{};
    for (final a in rendre(vendus, quantiteVendue, deja)) {
      avant[a.arrivageId] = (avant[a.arrivageId] ?? 0) + a.quantite;
    }
    final res = <AllocationLot>[];
    for (final a in rendre(vendus, quantiteVendue, deja + quantite)) {
      final q = a.quantite - (avant[a.arrivageId] ?? 0);
      if (q > 0) res.add(AllocationLot(a.arrivageId, q));
    }
    return res;
  }

  /// Retour de [quantite] pièces : on les rend aux arrivages de la vente,
  /// du plus récent au plus ancien (les pièces du stock ancien d'abord)
  static List<AllocationLot> rendre(List<AllocationLot> vendus, int quantiteVendue, int quantite) {
    final dansLots = vendus.fold<int>(0, (s, a) => s + a.quantite);
    final ancien = quantiteVendue - dansLots;
    var reste = quantite - (ancien > 0 ? ancien : 0);
    final res = <AllocationLot>[];
    for (final a in vendus.reversed) {
      if (reste <= 0) break;
      final q = a.quantite < reste ? a.quantite : reste;
      res.add(AllocationLot(a.arrivageId, q));
      reste -= q;
    }
    return res;
  }
}
