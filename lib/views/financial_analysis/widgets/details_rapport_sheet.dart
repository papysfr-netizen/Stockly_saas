import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'details_bottom_sheet.dart';

/// 📋 Détails du rapport : ventes, encaissé, crédits, dépenses
class DetailsRapport {
  static final DateFormat _heure = DateFormat('dd/MM HH:mm');

  static double _n(Object? v) {
    if (v is num) return v.toDouble();
    return double.tryParse((v ?? '').toString().replaceAll(',', '.')) ?? 0;
  }

  static DateTime? _dateDe(Map m) {
    final v = m['date'] ?? m['createdAt'];
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }

  static bool _dans(DateTime? d, DateTimeRange p) =>
      d != null && !d.isBefore(p.start) && !d.isAfter(p.end);

  /// Boutique d'une vente / dépense (vide = boutique principale)
  static String boutiqueDe(Object? v) {
    final s = (v ?? '').toString();
    return s.isEmpty ? 'principale' : s;
  }

  /// Nom du vendeur (même règle que le calcul du rapport)
  static String vendeurDe(Map m) {
    final brut = (m['vendeurNom'] ?? '').toString().trim();
    return (brut.isEmpty || (brut.length >= 20 && !brut.contains(' '))) ? 'Non précisé' : brut;
  }

  static double _totalVente(Map m) => _n(m['montantTotal'] ?? m['total']);

  /// Ce que la boutique garde vraiment pour cette vente (même règle que « Encaissé »)
  static double encaisseDe(Map m) {
    final net = _totalVente(m) - _n(m['montantRetourne']) - _n(m['montantAnnule']);
    final paye = _n(m['montantPaye']);
    final garde = net <= 0 ? 0.0 : (paye < net ? paye : net);
    final cash = garde - _n(m['montantCompteClient']);
    return (cash > 0 ? cash : 0.0) + _n(m['montantConserve']);
  }

  /// Ventes de la période (la plus récente d'abord)
  static List<Map<String, dynamic>> ventesPeriode(
      List<QueryDocumentSnapshot> docs, DateTimeRange p,
      {bool Function(Map<String, dynamic>)? garder}) {
    final l = <Map<String, dynamic>>[];
    for (final d in docs) {
      final m = (d.data() as Map<String, dynamic>?) ?? const <String, dynamic>{};
      if (!_dans(_dateDe(m), p)) continue;
      if (garder != null && !garder(m)) continue;
      l.add(m);
    }
    final ancien = DateTime(2000);
    l.sort((a, b) => (_dateDe(b) ?? ancien).compareTo(_dateDe(a) ?? ancien));
    return l;
  }

  /// Dépenses de la période (null = toutes les boutiques)
  static List<dynamic> depensesPeriode(List<dynamic> deps, DateTimeRange p, {String? boutique}) {
    final l = deps.where((d) {
      final dd = d as dynamic;
      final Object? date = dd.date;
      if (date is! DateTime || !_dans(date, p)) return false;
      if (boutique != null && boutiqueDe(dd.boutiqueId) != boutique) return false;
      return true;
    }).toList();
    l.sort((a, b) => ((b as dynamic).date as DateTime).compareTo((a as dynamic).date as DateTime));
    return l;
  }

  static const TextStyle _blanc = TextStyle(color: Colors.white);

  static Widget _titre(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
        child: Text(t,
            style: const TextStyle(
                color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
      );

  static Widget _vide(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: Text(t, style: const TextStyle(color: Colors.white54)),
      );

  static double _montantMode(Map m, String mode) {
    if (mode == 'encaisse') return encaisseDe(m);
    if (mode == 'credit') return _n(m['resteAPayer']);
    return _totalVente(m);
  }

  static Widget _ligneVente(Map m, String Function(double) fmt, String currency,
      Map<String, String> noms, String mode) {
    final d = _dateDe(m);
    final client = (m['nomClient'] ?? '').toString().trim();
    final tel = (m['telephoneClient'] ?? '').toString().trim();
    final brut = m['articles'];
    final articles = (brut is List ? brut : const [])
        .whereType<Map>()
        .map((a) => '${a['quantite']} × ${a['nom']}')
        .join(', ');
    final idB = boutiqueDe(m['boutiqueId']);
    final nomB = noms[idB] ?? (idB == 'principale' ? 'Boutique principale' : idB);
    final retour = _n(m['montantRetourne']) + _n(m['montantAnnule']);
    final montant = _montantMode(m, mode);
    final credit = mode == 'credit';

    return ListTile(
      dense: true,
      isThreeLine: true,
      leading: Icon(
        credit
            ? Icons.schedule_rounded
            : (mode == 'encaisse' ? Icons.payments_rounded : Icons.receipt_long_rounded),
        color: credit ? Colors.redAccent : Colors.tealAccent,
      ),
      title: Text('${d == null ? '' : _heure.format(d)} · ${client.isEmpty ? 'Client' : client}',
          style: _blanc),
      subtitle: Text(
        [
          if (articles.isNotEmpty) articles,
          if (credit && tel.isNotEmpty) '📞 $tel',
          if (credit) 'Facture : ${fmt(_totalVente(m))} $currency',
          '👤 ${vendeurDe(m)} · 🏬 $nomB',
          if (retour > 0.005) 'Retour / annulation : − ${fmt(retour)} $currency',
        ].join('\n'),
        style: TextStyle(color: Colors.grey.shade400),
      ),
      trailing: Text('${fmt(montant)} $currency',
          style: TextStyle(
              fontWeight: FontWeight.bold, color: credit ? Colors.redAccent : Colors.white)),
    );
  }

  /// Lignes « dépenses » (avec un titre) à ajouter dans une feuille
  static List<Widget> lignesDepenses(
      List<dynamic> deps, String Function(double) fmt, String currency) {
    final total = deps.fold<double>(0, (s, d) => s + _n((d as dynamic).montant));
    return [
      _titre('💸 Chaque dépense (${deps.length}) · − ${fmt(total)} $currency'),
      if (deps.isEmpty) _vide('Aucune dépense'),
      for (final d in deps)
        Builder(builder: (_) {
          final dd = d as dynamic;
          final par = (dd.enregistrePar ?? '').toString();
          final date = dd.date as DateTime;
          return ListTile(
            dense: true,
            leading: const Icon(Icons.money_off, color: Colors.redAccent),
            title: Text('${dd.titre}', style: _blanc),
            subtitle: Text(
              '${_heure.format(date)} · ${dd.categorie}${par.isEmpty ? '' : ' · 👤 $par'}',
              style: TextStyle(color: Colors.grey.shade400),
            ),
            trailing: Text('− ${fmt(_n(dd.montant))} $currency',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
          );
        }),
    ];
  }

  /// Liste de ventes (mode : 'vente', 'encaisse' ou 'credit')
  static void ventes(
    BuildContext context, {
    required String titre,
    required List<Map<String, dynamic>> ventes,
    required String Function(double) fmt,
    required String currency,
    required Map<String, String> noms,
    String mode = 'vente',
  }) {
    final total = ventes.fold<double>(0, (s, m) => s + _montantMode(m, mode));
    DetailsBottomSheet.afficher(
      context: context,
      titre: '$titre · ${fmt(total)} $currency',
      enfants: ventes.isEmpty
          ? [_vide('Aucune donnée sur cette période')]
          : [for (final m in ventes) _ligneVente(m, fmt, currency, noms, mode)],
    );
  }

  /// Fiche d'une boutique : ventes, crédits, dépenses
  static void boutique(
    BuildContext context, {
    required String titre,
    required List<Map<String, dynamic>> ventes,
    required List<dynamic> depenses,
    required String Function(double) fmt,
    required String currency,
    required Map<String, String> noms,
  }) {
    final credits = ventes.where((m) => _n(m['resteAPayer']) > 0.005).toList();
    final totalVentes = ventes.fold<double>(0, (s, m) => s + _totalVente(m));
    final totalCredits = credits.fold<double>(0, (s, m) => s + _n(m['resteAPayer']));
    DetailsBottomSheet.afficher(
      context: context,
      titre: titre,
      enfants: [
        _titre('🧾 Ventes (${ventes.length}) · ${fmt(totalVentes)} $currency'),
        if (ventes.isEmpty) _vide('Aucune vente sur cette période'),
        for (final m in ventes) _ligneVente(m, fmt, currency, noms, 'vente'),
        _titre('⏳ Qui doit encore (${credits.length}) · ${fmt(totalCredits)} $currency'),
        if (credits.isEmpty) _vide('Aucun crédit sur cette période'),
        for (final m in credits) _ligneVente(m, fmt, currency, noms, 'credit'),
        ...lignesDepenses(depenses, fmt, currency),
      ],
    );
  }
}
