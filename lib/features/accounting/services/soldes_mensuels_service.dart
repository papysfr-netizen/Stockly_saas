// 📊 SOLDES MENSUELS : le bilan sans relire toute l'histoire
//
// Avant : l'écran Comptabilité relisait TOUTES les écritures depuis le début
// à chaque ouverture (lent, et coûteux : Firebase compte chaque lecture).
//
// Maintenant :
//  - chaque mois TERMINÉ est résumé une fois dans
//      entreprises/{id}/soldes_mensuels/{AAAA-MM}
//    { mois, nb (nombre d'écritures), parBoutique: {boutique: {compte: débit − crédit}} }
//  - le bilan = résumés des mois passés + écritures du mois en cours (lues en direct)
//  - un résumé est refait si le nombre d'écritures du mois a changé (comptage
//    Firebase, presque gratuit) ou s'il a été effacé (écriture modifiée).
import 'package:cloud_firestore/cloud_firestore.dart';

/// Totaux nets (débit − crédit) : boutique → compte → montant
typedef SoldesParBoutique = Map<String, Map<String, double>>;

class SoldesMensuelsService {
  SoldesMensuelsService._();

  static String cleMois(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}';

  static DateTime debutMois(DateTime d) => DateTime(d.year, d.month);
  static DateTime moisSuivant(DateTime d) => DateTime(d.year, d.month + 1);

  static double _n(dynamic v) => v is num ? v.toDouble() : double.tryParse('${v ?? ''}') ?? 0.0;

  /// Additionne des écritures (données Firestore) par boutique et par compte
  static SoldesParBoutique totaliser(Iterable<Map<String, dynamic>> ecritures) {
    final res = <String, Map<String, double>>{};
    for (final e in ecritures) {
      final b0 = (e['boutiqueId'] ?? '').toString();
      final b = b0.isEmpty ? 'principale' : b0;
      final comptes = res.putIfAbsent(b, () => {});
      for (final l in (e['lines'] as List?) ?? const []) {
        if (l is! Map) continue;
        final code = (l['accountCode'] ?? '').toString();
        if (code.isEmpty) continue;
        comptes[code] = (comptes[code] ?? 0) + _n(l['debit']) - _n(l['credit']);
      }
    }
    return res;
  }

  /// Ajoute [b] dans [a]
  static void ajouter(SoldesParBoutique a, SoldesParBoutique b) {
    b.forEach((boutique, comptes) {
      final cible = a.putIfAbsent(boutique, () => {});
      comptes.forEach((code, v) => cible[code] = (cible[code] ?? 0) + v);
    });
  }

  /// Totaux d'une boutique (null = toutes)
  static Map<String, double> pourBoutique(SoldesParBoutique s, String? boutique) {
    final res = <String, double>{};
    s.forEach((b, comptes) {
      if (boutique != null && b != boutique) return;
      comptes.forEach((code, v) => res[code] = (res[code] ?? 0) + v);
    });
    return res;
  }

  static CollectionReference<Map<String, dynamic>> _ecritures(String entId) =>
      FirebaseFirestore.instance.collection('entreprises').doc(entId).collection('ecritures_comptables');

  static CollectionReference<Map<String, dynamic>> _soldes(String entId) =>
      FirebaseFirestore.instance.collection('entreprises').doc(entId).collection('soldes_mensuels');

  static Query<Map<String, dynamic>> _duMois(String entId, DateTime mois) => _ecritures(entId)
      .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(debutMois(mois)))
      .where('date', isLessThan: Timestamp.fromDate(moisSuivant(mois)));

  /// Écritures d'un mois, en direct (les plus récentes d'abord)
  static Query<Map<String, dynamic>> requeteDuMois(String entId, DateTime mois) =>
      _duMois(entId, mois).orderBy('date', descending: true);

  /// Soldes cumulés de tous les mois AVANT [moisCourant]
  /// (le mois en cours est ajouté à part, en direct)
  static Future<SoldesParBoutique> cumulAvant(String entId, DateTime moisCourant,
      {bool toutRecalculer = false}) async {
    final total = <String, Map<String, double>>{};
    final premier = await _ecritures(entId).orderBy('date').limit(1).get();
    if (premier.docs.isEmpty) return total;
    final d0 = premier.docs.first.data()['date'];
    if (d0 is! Timestamp) return total;

    final resumes = <String, Map<String, dynamic>>{};
    if (!toutRecalculer) {
      for (final d in (await _soldes(entId).get()).docs) {
        resumes[d.id] = d.data();
      }
    }

    final fin = debutMois(moisCourant);
    for (var m = debutMois(d0.toDate()); m.isBefore(fin); m = moisSuivant(m)) {
      final cle = cleMois(m);
      final q = _duMois(entId, m);
      final resume = resumes[cle];

      // Le résumé est-il encore juste ? (même nombre d'écritures)
      int? nb;
      try {
        nb = (await q.count().get()).count;
      } catch (_) {
        nb = null; // hors connexion : on fait confiance au résumé s'il existe
      }
      if (resume != null && (nb == null || nb == (resume['nb'] as num?)?.toInt())) {
        final pb = (resume['parBoutique'] as Map?) ?? const {};
        ajouter(total, {
          for (final e in pb.entries)
            e.key.toString(): {
              for (final c in ((e.value as Map?) ?? const {}).entries) c.key.toString(): _n(c.value),
            },
        });
        continue;
      }

      // Sinon : on relit ce mois (une seule fois) et on garde son résumé
      final docs = (await q.get()).docs;
      final s = totaliser(docs.map((d) => d.data()));
      ajouter(total, s);
      try {
        await _soldes(entId).doc(cle).set({
          'mois': cle,
          'nb': docs.length,
          'parBoutique': s,
          'calculeLe': FieldValue.serverTimestamp(),
        });
      } catch (_) {
        // Pas le droit d'enregistrer : le calcul reste juste pour cet écran
      }
    }
    return total;
  }

  /// Une écriture d'un mois passé a changé : son résumé sera refait
  static Future<void> invalider(String entId, DateTime date) async {
    if (!debutMois(date).isBefore(debutMois(DateTime.now()))) return;
    try {
      await _soldes(entId).doc(cleMois(date)).delete();
    } catch (_) {}
  }
}
