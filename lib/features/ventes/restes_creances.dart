import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';

/// 💳 Reste réel de chaque vente à crédit, lu dans sa dette (collection « creances »).
/// La dette baisse quand le client revient payer ; la vente, elle, garde le reste du jour de la vente.
Map<String, double> restesParVente = {};

double _nombre(dynamic v) => v is num ? v.toDouble() : double.tryParse('${v ?? ''}') ?? 0.0;

final restesCreancesProvider =
    StreamProvider.family<Map<String, double>, String>((ref, entrepriseId) {
  if (entrepriseId.isEmpty) return Stream.value(const <String, double>{});
  // 💸 Pas tout l'historique : les dettes en cours, et celles payées depuis 6 mois
  final col = FirebaseFirestore.instance.collection('entreprises').doc(entrepriseId).collection('creances');
  final il6Mois = Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 183)));
  return Rx.combineLatest2<QuerySnapshot<Map<String, dynamic>>, QuerySnapshot<Map<String, dynamic>>,
      Map<String, double>>(
    col.where('montantReste', isGreaterThan: 0).snapshots(),
    col.where('dernierPaiement', isGreaterThanOrEqualTo: il6Mois).snapshots(),
    (enCours, payees) {
    final parId = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{
      for (final d in [...enCours.docs, ...payees.docs]) d.id: d,
    };
    final m = <String, double>{};
    for (final doc in parId.values) {
      final d = doc.data();
      final venteId = (d['venteId'] ?? '').toString();
      if (venteId.isEmpty) continue;
      final r = d['montantReste'] ?? d['montantRestant'];
      if (r == null) continue;
      m[venteId] = (m[venteId] ?? 0) + _nombre(r);
    }
    restesParVente = m;
    return m;
    },
  );
});

/// Reste à payer d'une vente : le plus petit entre la vente et sa dette.
double resteReel(Map<dynamic, dynamic> vente, [String? venteId]) {
  final brut = _nombre(vente['resteAPayer']);
  final id = venteId ?? (vente['id'] ?? '').toString();
  final dette = restesParVente[id];
  if (dette == null) return brut;
  final v = dette < brut ? dette : brut;
  return v < 0 ? 0.0 : v;
}
