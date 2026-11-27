import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../models/classe.dart';
import '../../models/eleve.dart';
import '../../models/scolarite.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';

class PresencesScreen extends ConsumerStatefulWidget {
  const PresencesScreen({super.key});
  @override
  ConsumerState<PresencesScreen> createState() => _PresencesScreenState();
}

class _PresencesScreenState extends ConsumerState<PresencesScreen> {
  String? _classeId;
  DateTime _date = DateTime.now();
  Map<String, StatutPresence> _statuts = {};
  String? _chargePour;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final classes = ref.watch(classesProvider).valueOrNull ?? const <Classe>[];
    final classe = classes.where((c) => c.id == _classeId).firstOrNull;

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
          SizedBox(
            width: 240,
            child: DropdownButtonFormField<String>(
              value: classe?.id,
              decoration: const InputDecoration(labelText: 'Classe'),
              items: [for (final c in classes) DropdownMenuItem(value: c.id, child: Text(c.nom))],
              onChanged: (v) => setState(() => _classeId = v),
            ),
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.calendar_today),
            label: Text(formatDate(_date)),
            onPressed: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now(),
              );
              if (d != null) setState(() => _date = d);
            },
          ),
        ]),
      ),
      Expanded(
        child: classe == null
            ? const EmptyState("Choisissez une classe pour faire l'appel.", icon: Icons.fact_check_outlined)
            : _feuille(classe),
      ),
    ]);
  }

  Widget _feuille(Classe classe) {
    final eleves = ref.watch(elevesProvider(classe.id));
    final feuille = ref.watch(_feuilleProvider((classe.id, isoDay(_date))));
    return AsyncView(eleves, (List<Eleve> list) {
      if (!feuille.hasValue) return const Center(child: CircularProgressIndicator());
      final cle = '${classe.id}|${isoDay(_date)}';
      if (_chargePour != cle) {
        _chargePour = cle;
        _statuts = {
          for (final e in list) e.id: feuille.value?.statuts[e.id] ?? StatutPresence.present,
        };
      }
      if (list.isEmpty) return const EmptyState('Aucun élève dans cette classe.');
      final absents = _statuts.values.where((s) => s == StatutPresence.absent).length;
      final retards = _statuts.values.where((s) => s == StatutPresence.retard).length;

      return ListView(padding: const EdgeInsets.symmetric(horizontal: 12), children: [
        Text(
          '${feuille.value == null ? 'Appel non encore enregistré' : 'Appel enregistré'} · '
          '${list.length - absents} présent(s), $absents absent(s), $retards retard(s)',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        for (final e in list)
          Card(
            child: ListTile(
              title: Text(e.nomComplet),
              trailing: SegmentedButton<StatutPresence>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: StatutPresence.present, label: Text('P')),
                  ButtonSegment(value: StatutPresence.retard, label: Text('R')),
                  ButtonSegment(value: StatutPresence.absent, label: Text('A')),
                ],
                selected: {_statuts[e.id] ?? StatutPresence.present},
                onSelectionChanged: (s) => setState(() => _statuts[e.id] = s.first),
              ),
            ),
          ),
        const SizedBox(height: 12),
        FilledButton.icon(
          icon: const Icon(Icons.save),
          label: const Text("Enregistrer l'appel"),
          onPressed: _busy
              ? null
              : () async {
                  setState(() => _busy = true);
                  await run(
                    context,
                    () => ref.read(schoolRepoProvider).enregistrerPresences(
                          FeuillePresence(
                            classeId: classe.id,
                            date: _date,
                            statuts: {for (final e in list) e.id: _statuts[e.id] ?? StatutPresence.present},
                          ),
                          ref.read(meProvider).nom,
                        ),
                    succes: 'Appel enregistré',
                  );
                  if (mounted) setState(() => _busy = false);
                },
        ),
        const SizedBox(height: 24),
      ]);
    });
  }
}

final _feuilleProvider = StreamProvider.autoDispose.family<FeuillePresence?, (String, String)>(
  (ref, k) => ref.watch(schoolRepoProvider).feuillePresence(k.$1, DateTime.parse(k.$2)),
);
