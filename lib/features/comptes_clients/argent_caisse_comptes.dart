import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// 💵 Mouvements d'argent du jour hors ventes : comptes clients et remboursements des retours
class MouvementsCaisseJour {
  final double depotsEspeces;
  final double retraitsEspeces;
  final double depotsMobile;
  final double retraitsMobile;
  final double remboursementsEspeces;
  const MouvementsCaisseJour({
    this.depotsEspeces = 0,
    this.retraitsEspeces = 0,
    this.depotsMobile = 0,
    this.retraitsMobile = 0,
    this.remboursementsEspeces = 0,
  });

  MouvementsCaisseJour avecRemboursements(double r) => MouvementsCaisseJour(
        depotsEspeces: depotsEspeces,
        retraitsEspeces: retraitsEspeces,
        depotsMobile: depotsMobile,
        retraitsMobile: retraitsMobile,
        remboursementsEspeces: r,
      );
}

double _num(dynamic v) => v is num ? v.toDouble() : double.tryParse('${v ?? ''}') ?? 0;

/// Boutique choisie ? (null = toutes ; un ancien retour sans boutique est compté)
bool _memeBoutique(String? choisie, Object? b) {
  if (choisie == null) return true;
  final s = (b ?? '').toString();
  if (s.isEmpty) return true;
  return s == choisie;
}

/// Lit les comptes touchés aujourd'hui, puis leurs mouvements depuis minuit.
Stream<MouvementsCaisseJour> mouvementsCaisseDuJour(String entrepriseId, DateTime debut) {
  if (entrepriseId.isEmpty) return Stream.value(const MouvementsCaisseJour());
  final ent = FirebaseFirestore.instance.collection('entreprises').doc(entrepriseId);
  final depuis = Timestamp.fromDate(debut);
  return ent
      .collection('comptes_clients')
      .where('updatedAt', isGreaterThanOrEqualTo: depuis)
      .snapshots()
      .asyncMap((s) async {
    double de = 0, re = 0, dm = 0, rm = 0;
    for (final c in s.docs) {
      QuerySnapshot<Map<String, dynamic>> mv;
      try {
        mv = await c.reference.collection('mouvements').where('date', isGreaterThanOrEqualTo: depuis).get();
      } catch (_) {
        continue;
      }
      for (final m in mv.docs) {
        final d = m.data();
        final type = (d['type'] ?? '').toString();
        final montant = _num(d['montant']);
        final mobile = (d['methode'] ?? '').toString().toLowerCase().contains('mobile');
        if (type == 'depot') {
          if (mobile) {
            dm += montant;
          } else {
            de += montant;
          }
        } else if (type == 'retrait') {
          if (mobile) {
            rm += montant;
          } else {
            re += montant;
          }
        }
      }
    }
    return MouvementsCaisseJour(depotsEspeces: de, retraitsEspeces: re, depotsMobile: dm, retraitsMobile: rm);
  });
}

/// ↩️ Argent rendu EN ESPÈCES aux clients pour les retours faits aujourd'hui
/// (même si la vente date d'un autre jour). Un avoir sur compte client ne sort pas d'argent.
Stream<double> remboursementsDuJour(String entrepriseId, DateTime debut, String? boutique) {
  if (entrepriseId.isEmpty) return Stream.value(0);
  return FirebaseFirestore.instance
      .collection('entreprises')
      .doc(entrepriseId)
      .collection('retours')
      .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(debut))
      .snapshots()
      .map((s) {
    double total = 0;
    for (final d in s.docs) {
      final m = d.data();
      if ((m['modeRemboursement'] ?? '').toString() != 'especes') continue;
      if (!_memeBoutique(boutique, m['boutiqueId'])) continue;
      total += _num(m['montantRembourse']);
    }
    return total;
  });
}

/// Lecture unique (pour le résumé WhatsApp)
Future<MouvementsCaisseJour> lireCaisseDuJour(String entrepriseId, DateTime debut, String? boutique) async {
  try {
    final m = await mouvementsCaisseDuJour(entrepriseId, debut).first.timeout(const Duration(seconds: 8));
    final r = await remboursementsDuJour(entrepriseId, debut, boutique).first.timeout(const Duration(seconds: 8));
    return m.avecRemboursements(r);
  } catch (_) {
    return const MouvementsCaisseJour();
  }
}

/// Ligne « Argent en caisse du jour » + détail (comptes clients, remboursements)
class LigneArgentCaisse extends StatelessWidget {
  final String entrepriseId;
  final DateTime debut;
  final double soldeBase;
  final String? boutique;
  final String Function(double) format;
  final Widget Function(double solde) construire;

  const LigneArgentCaisse({
    super.key,
    required this.entrepriseId,
    required this.debut,
    required this.soldeBase,
    this.boutique,
    required this.format,
    required this.construire,
  });

  static MouvementsCaisseJour _dernier = const MouvementsCaisseJour();
  static double _dernierRemb = 0;

  @override
  Widget build(BuildContext context) {
    final langue = Localizations.localeOf(context).languageCode;
    String tr(String fr, String en, String sw, String ln) => switch (langue) {
          'en' => en,
          'sw' => sw,
          'ln' => ln,
          _ => fr,
        };
    return StreamBuilder<MouvementsCaisseJour>(
      stream: mouvementsCaisseDuJour(entrepriseId, debut),
      initialData: _dernier,
      builder: (context, snap) => StreamBuilder<double>(
        stream: remboursementsDuJour(entrepriseId, debut, boutique),
        initialData: _dernierRemb,
        builder: (context, snapR) {
          final m = snap.data ?? const MouvementsCaisseJour();
          final remb = snapR.data ?? 0;
          _dernier = m;
          _dernierRemb = remb;
          final style = TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant);
          final lignes = <String>[
            if (m.depotsEspeces > 0.005)
              '${tr('Dépôts clients (espèces)', 'Client deposits (cash)', 'Amana za wateja (pesa taslimu)', 'Ba dépôts ya ba clients (mbongo)')} : +${format(m.depotsEspeces)}',
            if (m.retraitsEspeces > 0.005)
              '${tr('Retraits clients (espèces)', 'Client withdrawals (cash)', 'Utoaji wa wateja (pesa taslimu)', 'Ba retraits ya ba clients (mbongo)')} : −${format(m.retraitsEspeces)}',
            if (remb > 0.005)
              '${tr('Remboursements (retours)', 'Refunds (returns)', 'Marejesho ya pesa (bidhaa zilizorudishwa)', 'Mbongo ezongisami (biloko bizongisami)')} : −${format(remb)}',
            if (m.depotsMobile - m.retraitsMobile > 0.005 || m.retraitsMobile - m.depotsMobile > 0.005)
              '${tr('Mobile Money clients (pas dans le tiroir)', 'Client Mobile Money (not in drawer)', 'Mobile Money ya wateja (si kwenye droo)', 'Mobile Money ya ba clients (ezali na tiroir te)')} : ${format(m.depotsMobile - m.retraitsMobile)}',
          ];
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final l in lignes)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(l, textAlign: TextAlign.center, style: style),
                ),
              if (lignes.isNotEmpty) const SizedBox(height: 4),
              construire(soldeBase + m.depotsEspeces - m.retraitsEspeces - remb),
            ],
          );
        },
      ),
    );
  }
}
