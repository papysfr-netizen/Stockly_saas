import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../models/scolarite.dart';
import '../../providers/providers.dart';
import '../../services/calculs.dart';
import '../../widgets/common.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eleves = ref.watch(elevesProvider(null)).valueOrNull ?? const [];
    final classes = ref.watch(toutesClassesProvider).valueOrNull ?? const [];
    final paiements = ref.watch(paiementsProvider(null)).valueOrNull ?? const [];
    final enseignants = ref.watch(enseignantsProvider).valueOrNull ?? const [];
    final presences = ref.watch(presencesDuJourProvider).valueOrNull ?? const [];
    final devise = ref.watch(ecoleProvider).valueOrNull?.devise ?? 'USD';

    final fraisParClasse = {for (final c in classes) c.id: c.fraisScolarite};
    final paiementsParEleve = <String, List<Paiement>>{};
    for (final p in paiements) {
      paiementsParEleve.putIfAbsent(p.eleveId, () => []).add(p);
    }
    final totalEncaisse = paiements.fold<double>(0, (s, p) => s + p.montant);
    final totalAttendu = eleves.fold<double>(0, (s, e) => s + (fraisParClasse[e.classeId] ?? 0));
    final impayes = eleves.fold<double>(
        0,
        (s, e) =>
            s + resteAPayer(fraisParClasse[e.classeId] ?? 0, paiementsParEleve[e.id] ?? const []));

    final now = DateTime.now();
    final moisEncaisse = paiements
        .where((p) => p.date.year == now.year && p.date.month == now.month)
        .fold<double>(0, (s, p) => s + p.montant);

    final statuts = presences.expand((f) => f.statuts.values).toList();
    final presents = statuts.where((s) => s != StatutPresence.absent).length;
    final tauxPresence = statuts.isEmpty ? null : presents * 100 / statuts.length;

    final effectifs = <String, int>{};
    for (final e in eleves) {
      effectifs[e.classeId] = (effectifs[e.classeId] ?? 0) + 1;
    }

    return ListView(padding: const EdgeInsets.all(16), children: [
      LayoutBuilder(builder: (context, c) {
        final cols = c.maxWidth > 900 ? 3 : (c.maxWidth > 560 ? 2 : 1);
        final cards = [
          StatCard(titre: 'Élèves inscrits', valeur: '${eleves.length}', icon: Icons.groups),
          StatCard(titre: 'Classes', valeur: '${classes.length}', icon: Icons.class_),
          StatCard(titre: 'Enseignants', valeur: '${enseignants.length}', icon: Icons.co_present),
          StatCard(
              titre: 'Encaissé ce mois',
              valeur: formatMontant(moisEncaisse, devise: devise),
              icon: Icons.payments,
              couleur: Colors.green),
          StatCard(
              titre: 'Reste à recouvrer',
              valeur: formatMontant(impayes, devise: devise),
              icon: Icons.warning_amber,
              couleur: Colors.orange),
          StatCard(
              titre: "Présence aujourd'hui",
              valeur: tauxPresence == null ? 'Appel non fait' : '${tauxPresence.toStringAsFixed(0)} %',
              icon: Icons.fact_check,
              couleur: Colors.teal),
        ];
        return GridView.count(
          crossAxisCount: cols,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: cols == 1 ? 4 : 2.8,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          children: cards,
        );
      }),
      const SizedBox(height: 16),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Recouvrement des frais', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: totalAttendu == 0 ? 0 : (totalEncaisse / totalAttendu).clamp(0, 1),
              minHeight: 10,
            ),
            const SizedBox(height: 8),
            Text('${formatMontant(totalEncaisse, devise: devise)} encaissés sur '
                '${formatMontant(totalAttendu, devise: devise)} attendus'),
          ]),
        ),
      ),
      const SizedBox(height: 8),
      Card(
        child: Column(children: [
          const ListTile(title: Text('Effectifs par classe')),
          for (final c in classes)
            ListTile(
              dense: true,
              title: Text(c.nom),
              subtitle: c.description.isEmpty ? null : Text(c.description),
              trailing: Text('${effectifs[c.id] ?? 0} élèves'),
            ),
          if (classes.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Commencez par créer vos classes dans le menu « Classes ».'),
            ),
        ]),
      ),
    ]);
  }
}
