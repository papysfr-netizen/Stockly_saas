import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../models/eleve.dart';
import '../../models/scolarite.dart';
import '../../providers/providers.dart';
import '../../services/calculs.dart';
import '../../widgets/common.dart';
import '../eleves/eleve_detail_screen.dart';
import '../../services/rappels.dart';
import 'encaisser_dialog.dart';
import 'rappels_actions.dart';

class PaiementsScreen extends ConsumerWidget {
  const PaiementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => const DefaultTabController(
        length: 2,
        child: Column(children: [
          TabBar(tabs: [Tab(text: 'Journal des encaissements'), Tab(text: 'Impayés')]),
          Expanded(child: TabBarView(children: [_JournalTab(), _ImpayesTab()])),
        ]),
      );
}

enum _Periode { jour, mois, annee, tout }

class _JournalTab extends ConsumerStatefulWidget {
  const _JournalTab();
  @override
  ConsumerState<_JournalTab> createState() => _JournalTabState();
}

class _JournalTabState extends ConsumerState<_JournalTab> {
  _Periode _periode = _Periode.mois;

  bool _dansPeriode(DateTime d) {
    final n = DateTime.now();
    return switch (_periode) {
      _Periode.jour => d.year == n.year && d.month == n.month && d.day == n.day,
      _Periode.mois => d.year == n.year && d.month == n.month,
      _Periode.annee => d.year == n.year,
      _Periode.tout => true,
    };
  }

  @override
  Widget build(BuildContext context) {
    final devise = ref.watch(ecoleProvider).valueOrNull?.devise ?? 'USD';
    final eleves = ref.watch(elevesProvider(null)).valueOrNull ?? const <Eleve>[];
    final parId = {for (final e in eleves) e.id: e};

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final e = await _choisirEleve(context, eleves);
          if (e != null && context.mounted) await encaisserPaiement(context, ref, e);
        },
        icon: const Icon(Icons.add),
        label: const Text('Encaisser'),
      ),
      body: AsyncView(ref.watch(paiementsProvider(null)), (List<Paiement> all) {
        final list = all.where((p) => _dansPeriode(p.date)).toList();
        final total = list.fold<double>(0, (s, p) => s + p.montant);
        return Column(children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SegmentedButton<_Periode>(
              segments: const [
                ButtonSegment(value: _Periode.jour, label: Text("Aujourd'hui")),
                ButtonSegment(value: _Periode.mois, label: Text('Ce mois')),
                ButtonSegment(value: _Periode.annee, label: Text('Cette année')),
                ButtonSegment(value: _Periode.tout, label: Text('Tout')),
              ],
              selected: {_periode},
              onSelectionChanged: (s) => setState(() => _periode = s.first),
            ),
          ),
          Text('Total : ${formatMontant(total, devise: devise)} (${list.length} paiements)',
              style: Theme.of(context).textTheme.titleMedium),
          Expanded(
            child: list.isEmpty
                ? const EmptyState('Aucun encaissement sur la période.')
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final p = list[i];
                      final e = parId[p.eleveId];
                      return Card(
                        child: ListTile(
                          title: Text(e?.nomComplet ?? 'Élève retiré'),
                          subtitle: Text('${formatDate(p.date)} · ${p.motif} · ${p.mode} · ${p.recuNumero}'),
                          trailing: Text(formatMontant(p.montant, devise: devise),
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          onTap: e == null ? null : () => imprimerRecu(ref, e, p),
                        ),
                      );
                    },
                  ),
          ),
        ]);
      }),
    );
  }
}

class _ImpayesTab extends ConsumerStatefulWidget {
  const _ImpayesTab();
  @override
  ConsumerState<_ImpayesTab> createState() => _ImpayesTabState();
}

class _ImpayesTabState extends ConsumerState<_ImpayesTab> {
  String? _classeId;

  @override
  Widget build(BuildContext context) {
    final devise = ref.watch(ecoleProvider).valueOrNull?.devise ?? 'USD';
    final classes = ref.watch(toutesClassesProvider).valueOrNull ?? const [];
    final frais = {for (final c in classes) c.id: c.fraisScolarite};
    final nomsClasses = {for (final c in classes) c.id: c.nom};
    final paiements = ref.watch(paiementsProvider(null)).valueOrNull ?? const <Paiement>[];
    final parEleve = <String, List<Paiement>>{};
    for (final p in paiements) {
      parEleve.putIfAbsent(p.eleveId, () => []).add(p);
    }
    final rappels = ref.watch(derniersRappelsProvider).valueOrNull ?? const <String, DateTime>{};

    return AsyncView(ref.watch(elevesProvider(_classeId)), (List<Eleve> eleves) {
      final lignes = [
        for (final e in eleves)
          (eleve: e, reste: resteAPayer(frais[e.classeId] ?? 0, parEleve[e.id] ?? const [])),
      ].where((l) => l.reste > 0).toList()
        ..sort((a, b) => b.reste.compareTo(a.reste));
      final total = lignes.fold<double>(0, (s, l) => s + l.reste);

      return Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: DropdownButtonFormField<String?>(
            value: _classeId,
            decoration: const InputDecoration(labelText: 'Classe'),
            items: [
              const DropdownMenuItem(value: null, child: Text('Toutes les classes')),
              for (final c in classes) DropdownMenuItem(value: c.id, child: Text(c.nom)),
            ],
            onChanged: (v) => setState(() => _classeId = v),
          ),
        ),
        Text('${lignes.length} élève(s) · ${formatMontant(total, devise: devise)} à recouvrer',
            style: Theme.of(context).textTheme.titleMedium),
        if (lignes.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
              for (final canal in CanalRappel.values)
                FilledButton.tonalIcon(
                  icon: Icon(canal == CanalRappel.sms ? Icons.sms_outlined : Icons.chat_outlined),
                  label: Text('Relancer tous par ${canal.label}'),
                  onPressed: () => relancerAutomatiquement(
                      context, ref, [for (final l in lignes) l.eleve.id], canal),
                ),
            ]),
          ),
        Expanded(
          child: lignes.isEmpty
              ? const EmptyState('Tous les frais sont réglés.', icon: Icons.check_circle_outline)
              : ListView(padding: const EdgeInsets.all(12), children: [
                  for (final l in lignes)
                    Card(
                      child: ListTile(
                        title: Text(l.eleve.nomComplet),
                        subtitle: Text([
                          nomsClasses[l.eleve.classeId] ?? '',
                          if (l.eleve.parentTelephone.isNotEmpty) 'Tél. ${l.eleve.parentTelephone}',
                          if (rappels[l.eleve.id] != null) 'Relancé le ${formatDate(rappels[l.eleve.id])}',
                        ].join(' · ')),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(formatMontant(l.reste, devise: devise),
                              style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold)),
                          MenuRelance(eleve: l.eleve, reste: l.reste),
                          IconButton(
                            tooltip: 'Encaisser',
                            icon: const Icon(Icons.payments_outlined),
                            onPressed: () => encaisserPaiement(context, ref, l.eleve),
                          ),
                        ]),
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => EleveDetailScreen(eleveId: l.eleve.id))),
                      ),
                    ),
                ]),
        ),
      ]);
    });
  }
}

Future<Eleve?> _choisirEleve(BuildContext context, List<Eleve> eleves) => showDialog<Eleve>(
      context: context,
      builder: (c) {
        var filtre = '';
        return StatefulBuilder(builder: (c, setState) {
          final f = eleves
              .where((e) =>
                  filtre.isEmpty ||
                  e.nomComplet.toLowerCase().contains(filtre) ||
                  e.matricule.toLowerCase().contains(filtre))
              .take(50)
              .toList();
          return AlertDialog(
            title: const Text('Choisir un élève'),
            content: SizedBox(
              width: 400,
              height: 420,
              child: Column(children: [
                TextField(
                  autofocus: true,
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Rechercher'),
                  onChanged: (v) => setState(() => filtre = v.trim().toLowerCase()),
                ),
                Expanded(
                  child: ListView(children: [
                    for (final e in f)
                      ListTile(
                        title: Text(e.nomComplet),
                        subtitle: Text(e.matricule),
                        onTap: () => Navigator.pop(c, e),
                      ),
                  ]),
                ),
              ]),
            ),
          );
        });
      },
    );
