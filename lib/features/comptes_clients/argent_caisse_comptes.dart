import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// 💵 Mouvements des comptes clients d'aujourd'hui (dépôts / retraits)
class MouvementsCaisseJour {
  final double depotsEspeces;
  final double retraitsEspeces;
  final double depotsMobile;
  final double retraitsMobile;
  const MouvementsCaisseJour({
    this.depotsEspeces = 0,
    this.retraitsEspeces = 0,
    this.depotsMobile = 0,
    this.retraitsMobile = 0,
  });
}

double _num(dynamic v) => v is num ? v.toDouble() : double.tryParse('${v ?? ''}') ?? 0;

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

/// Ligne « Argent en caisse du jour » + détail des comptes clients
class LigneArgentCaisse extends StatelessWidget {
  final String entrepriseId;
  final DateTime debut;
  final double soldeBase;
  final String Function(double) format;
  final Widget Function(double solde) construire;

  const LigneArgentCaisse({
    super.key,
    required this.entrepriseId,
    required this.debut,
    required this.soldeBase,
    required this.format,
    required this.construire,
  });

  static MouvementsCaisseJour _dernier = const MouvementsCaisseJour();

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
      builder: (context, snap) {
        final m = snap.data ?? const MouvementsCaisseJour();
        _dernier = m;
        final style = TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant);
        final lignes = <String>[
          if (m.depotsEspeces > 0.005)
            '${tr('Dépôts clients (espèces)', 'Client deposits (cash)', 'Amana za wateja (pesa taslimu)', 'Ba dépôts ya ba clients (mbongo)')} : +${format(m.depotsEspeces)}',
          if (m.retraitsEspeces > 0.005)
            '${tr('Retraits clients (espèces)', 'Client withdrawals (cash)', 'Utoaji wa wateja (pesa taslimu)', 'Ba retraits ya ba clients (mbongo)')} : −${format(m.retraitsEspeces)}',
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
            construire(soldeBase + m.depotsEspeces - m.retraitsEspeces),
          ],
        );
      },
    );
  }
}
