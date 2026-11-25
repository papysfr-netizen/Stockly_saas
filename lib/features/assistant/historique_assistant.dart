// 🕘 Historique des discussions avec « Demandez à Nguli »
//
// Gardé SUR LE TÉLÉPHONE (SharedPreferences), par entreprise et par utilisateur :
// rien ne part sur internet, aucune lecture Firebase. Les 30 dernières discussions.
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class Discussion {
  final int id; // moment de la création (millisecondes) : sert aussi de date
  final List<(String, String)> echanges; // (question, réponse)
  const Discussion(this.id, this.echanges);

  DateTime get date => DateTime.fromMillisecondsSinceEpoch(id);
  String get titre => echanges.isEmpty ? '' : echanges.first.$1;

  Map<String, dynamic> versJson() => {
        'id': id,
        'echanges': [
          for (final (q, r) in echanges) [q, r],
        ],
      };

  static Discussion? depuisJson(Object? m) {
    if (m is! Map) return null;
    final id = m['id'];
    if (id is! int) return null;
    return Discussion(id, [
      for (final e in (m['echanges'] as List?) ?? const [])
        if (e is List && e.length == 2) (e[0].toString(), e[1].toString()),
    ]);
  }
}

class HistoriqueAssistant {
  HistoriqueAssistant._();

  static const int maximum = 30;

  static String _cle(String entrepriseId, String uid) => 'nguli_assistant_${entrepriseId}_$uid';

  /// Lit le texte enregistré (les plus récentes d'abord)
  static List<Discussion> decoder(String? texte) {
    if (texte == null || texte.isEmpty) return [];
    try {
      final liste = jsonDecode(texte);
      if (liste is! List) return [];
      final res = [for (final m in liste) Discussion.depuisJson(m)].whereType<Discussion>().toList();
      res.sort((a, b) => b.id.compareTo(a.id));
      return res;
    } catch (_) {
      return [];
    }
  }

  /// Ajoute ou remplace [d] ; garde les [maximum] plus récentes ; ignore une discussion vide
  static List<Discussion> fusionner(List<Discussion> liste, Discussion d) {
    final res = [for (final x in liste) if (x.id != d.id) x];
    final complets = [for (final e in d.echanges) if (e.$2.trim().isNotEmpty) e];
    if (complets.isNotEmpty) res.add(Discussion(d.id, complets));
    res.sort((a, b) => b.id.compareTo(a.id));
    return res.length > maximum ? res.sublist(0, maximum) : res;
  }

  static String encoder(List<Discussion> liste) => jsonEncode([for (final d in liste) d.versJson()]);

  static Future<List<Discussion>> lire(String entrepriseId, String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return decoder(prefs.getString(_cle(entrepriseId, uid)));
    } catch (_) {
      return [];
    }
  }

  static Future<void> enregistrer(String entrepriseId, String uid, Discussion d) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final liste = fusionner(decoder(prefs.getString(_cle(entrepriseId, uid))), d);
      await prefs.setString(_cle(entrepriseId, uid), encoder(liste));
    } catch (_) {}
  }

  static Future<void> supprimer(String entrepriseId, String uid, int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final liste = [for (final d in decoder(prefs.getString(_cle(entrepriseId, uid)))) if (d.id != id) d];
      await prefs.setString(_cle(entrepriseId, uid), encoder(liste));
    } catch (_) {}
  }
}
