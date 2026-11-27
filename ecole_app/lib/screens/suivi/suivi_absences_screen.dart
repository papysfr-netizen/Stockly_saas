import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/format.dart';
import '../../models/absence_eleve.dart';
import '../../models/classe.dart';
import '../../models/eleve.dart';
import '../../providers/providers.dart';
import '../../services/excel_export.dart';
import '../../services/fichier.dart';
import '../../services/suivi_absences.dart';
import '../../widgets/common.dart';
import '../eleves/eleve_detail_screen.dart';

/// Lutte contre l'école buissonnière : élèves à suivre, justificatifs, bilans.
class SuiviAbsencesScreen extends ConsumerWidget {
  const SuiviAbsencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final absences = ref.watch(absencesAnneeProvider).valueOrNull ?? const <AbsenceEleve>[];
    final enAttente = absences.where((a) => a.enAttente).length;
    return DefaultTabController(
      length: 3,
      child: Column(children: [
        TabBar(isScrollable: true, tabs: [
          const Tab(text: 'Élèves à suivre'),
          Tab(text: enAttente == 0 ? 'Justificatifs' : 'Justificatifs ($enAttente)'),
          const Tab(text: 'Bilan'),
        ]),
        const Expanded(child: TabBarView(children: [_ASuivreTab(), _JustificatifsTab(), _BilanTab()])),
      ]),
    );
  }
}

Map<String, Eleve> _eleves(WidgetRef ref) =>
    {for (final e in ref.watch(elevesProvider(null)).valueOrNull ?? const <Eleve>[]) e.id: e};
Map<String, String> _classes(WidgetRef ref) =>
    {for (final c in ref.watch(toutesClassesProvider).valueOrNull ?? const <Classe>[]) c.id: c.nom};

class _ASuivreTab extends ConsumerWidget {
  const _ASuivreTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seuil = ref.watch(ecoleProvider).valueOrNull?.seuilAbsences ?? 3;
    final eleves = _eleves(ref);
    final classes = _classes(ref);
    return AsyncView(ref.watch(absencesAnneeProvider), (List<AbsenceEleve> absences) {
      final liste = elevesASuivre(absences, seuil: seuil, maintenant: ref.watch(horlogeProvider)())
          .where((x) => eleves.containsKey(x.eleveId))
          .toList();
      return ListView(padding: const EdgeInsets.all(12), children: [
        Text('Élèves ayant au moins $seuil absences non justifiées sur les 30 derniers jours (seuil réglable dans Paramètres).',
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        if (liste.isEmpty)
          const EmptyState('Aucun élève à suivre pour le moment.', icon: Icons.verified_outlined)
        else
          for (final x in liste)
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.errorContainer,
                  child: Text('${x.absences}', style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)),
                ),
                title: Text(eleves[x.eleveId]!.nomComplet),
                subtitle: Text([
                  classes[eleves[x.eleveId]!.classeId] ?? '',
                  '${x.absences} absences non justifiées · dernière le ${formatDate(x.derniere)}',
                  if (eleves[x.eleveId]!.parentTelephone.isNotEmpty)
                    'Parent : ${eleves[x.eleveId]!.parentNom} · ${eleves[x.eleveId]!.parentTelephone}',
                ].join('\n')),
                isThreeLine: true,
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => EleveDetailScreen(eleveId: x.eleveId))),
              ),
            ),
      ]);
    });
  }
}

class _JustificatifsTab extends ConsumerWidget {
  const _JustificatifsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eleves = _eleves(ref);
    final classes = _classes(ref);
    final me = ref.watch(meProvider);
    return AsyncView(ref.watch(absencesAnneeProvider), (List<AbsenceEleve> absences) {
      final liste = absences.where((a) => a.enAttente).toList();
      if (liste.isEmpty) {
        return const EmptyState('Aucune justification de parent en attente.', icon: Icons.mark_email_read_outlined);
      }
      return ListView(padding: const EdgeInsets.all(12), children: [
        for (final a in liste)
          Card(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              ListTile(
                title: Text('${eleves[a.eleveId]?.nomComplet ?? '?'} · ${classes[a.classeId] ?? ''}'),
                subtitle: Text('Absence du ${formatDate(a.date)}\n'
                    'Motif : ${a.justificationParent!.motif}'
                    '${a.justificationParent!.message.isEmpty ? '' : '\n« ${a.justificationParent!.message} »'}'),
                isThreeLine: true,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Wrap(spacing: 8, alignment: WrapAlignment.end, children: [
                  TextButton(
                    onPressed: () => run(context, () => ref.read(schoolRepoProvider).refuserJustification(a.id),
                        succes: 'Justification refusée'),
                    child: const Text('Refuser'),
                  ),
                  FilledButton.tonal(
                    onPressed: () => run(
                      context,
                      () => ref.read(schoolRepoProvider).justifierAbsence(a.id,
                          motif: a.justificationParent!.motif, note: a.justificationParent!.message, par: me.nom),
                      succes: 'Justification acceptée',
                    ),
                    child: const Text('Accepter'),
                  ),
                ]),
              ),
            ]),
          ),
      ]);
    });
  }
}

class _BilanTab extends ConsumerStatefulWidget {
  const _BilanTab();
  @override
  ConsumerState<_BilanTab> createState() => _BilanTabState();
}

class _BilanTabState extends ConsumerState<_BilanTab> {
  DateTime? _mois; // null = toute l'année

  @override
  Widget build(BuildContext context) {
    final now = ref.watch(horlogeProvider)();
    final rentree = DateTime(now.month >= 9 ? now.year : now.year - 1, 9);
    final mois = [
      for (var m = DateTime(now.year, now.month); !m.isBefore(rentree); m = DateTime(m.year, m.month - 1)) m,
    ];
    final fmt = DateFormat('MMMM y', 'fr_FR');
    final classes = ref.watch(toutesClassesProvider).valueOrNull ?? const <Classe>[];
    final eleves = ref.watch(elevesProvider(null)).valueOrNull ?? const <Eleve>[];

    return AsyncView(ref.watch(absencesAnneeProvider), (List<AbsenceEleve> toutes) {
      final absences = duMois(toutes, _mois).toList();
      final periode = _mois == null
          ? 'année ${ref.watch(ecoleProvider).valueOrNull?.anneeScolaire ?? ''}'
          : fmt.format(_mois!);
      final total = bilan(absences);
      return ListView(padding: const EdgeInsets.all(12), children: [
        Row(children: [
          Expanded(
            child: DropdownButtonFormField<DateTime?>(
              value: _mois,
              decoration: const InputDecoration(labelText: 'Période'),
              items: [
                const DropdownMenuItem(value: null, child: Text("Toute l'année")),
                for (final m in mois) DropdownMenuItem(value: m, child: Text(toBeginningOfSentenceCase(fmt.format(m)))),
              ],
              onChanged: (v) => setState(() => _mois = v),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonalIcon(
            icon: const Icon(Icons.table_view_outlined),
            label: const Text('Excel'),
            onPressed: () => run(context, () async {
              final ecole = await ref.read(ecoleProvider.future);
              final octets = exporterAbsences(
                  ecole: ecole, classes: classes, eleves: eleves, absences: absences, periode: periode);
              await remettreFichier(octets, nomFichier('absences_$periode.xlsx'), mimeExcel);
            }),
          ),
        ]),
        const SizedBox(height: 12),
        Text('${total.absences} absences dont ${total.nonJustifiees} non justifiées · ${total.retards} retards',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: Column(children: [
            for (final c in [...classes]..sort((a, b) => a.nom.compareTo(b.nom)))
              Builder(builder: (context) {
                final b = bilan(absences.where((a) => a.classeId == c.id));
                return ListTile(
                  dense: true,
                  title: Text(c.nom),
                  trailing: Text('${b.absences} abs. (${b.nonJustifiees} NJ) · ${b.retards} ret.'),
                );
              }),
          ]),
        ),
        const SizedBox(height: 4),
        Text('NJ : non justifiées.', style: Theme.of(context).textTheme.bodySmall),
      ]);
    });
  }
}
