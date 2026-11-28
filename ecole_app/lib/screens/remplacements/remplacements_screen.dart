import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/telephone.dart';
import '../../models/classe.dart';
import '../../models/remplacement.dart';
import '../../models/scolarite.dart';
import '../../providers/providers.dart';
import '../../services/rappels.dart' show CanalRappel, CanalRappelX, lienRappel;
import '../../services/remplacements.dart';
import '../../widgets/common.dart';

class RemplacementsScreen extends StatelessWidget {
  const RemplacementsScreen({super.key});

  @override
  Widget build(BuildContext context) => const DefaultTabController(
        length: 2,
        child: Column(children: [
          TabBar(tabs: [Tab(text: 'Remplacements du jour'), Tab(text: 'Absences déclarées')]),
          Expanded(child: TabBarView(children: [_JourTab(), _AbsencesTab()])),
        ]),
      );
}

Color couleurStatut(BuildContext context, StatutRemplacement s) => switch (s) {
      StatutRemplacement.aPourvoir => context.etat.attention,
      StatutRemplacement.remplace => context.etat.succes,
      StatutRemplacement.etude => context.etat.info,
      StatutRemplacement.annule => context.etat.danger,
    };

// ============================================================
// Remplacements, jour par jour
// ============================================================
class _JourTab extends ConsumerStatefulWidget {
  const _JourTab();
  @override
  ConsumerState<_JourTab> createState() => _JourTabState();
}

class _JourTabState extends ConsumerState<_JourTab> {
  late DateTime _date = ref.read(horlogeProvider)();

  void _decaler(int jours) => setState(() => _date = DateTime(_date.year, _date.month, _date.day + jours));

  @override
  Widget build(BuildContext context) {
    final iso = isoDay(_date);
    final classes = {for (final c in ref.watch(toutesClassesProvider).valueOrNull ?? const <Classe>[]) c.id: c.nom};
    final noms = ref.watch(nomsMatieresProvider).valueOrNull ?? const <String, String>{};
    final aVenir = (ref.watch(tousRemplacementsProvider).valueOrNull ?? const <Remplacement>[])
        .where((r) =>
            r.statut == StatutRemplacement.aPourvoir && r.date.compareTo(isoDay(ref.read(horlogeProvider)())) >= 0)
        .toList();

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
        child: Row(children: [
          IconButton(onPressed: () => _decaler(-1), icon: const Icon(Icons.chevron_left), tooltip: 'Jour précédent'),
          Expanded(
            child: TextButton.icon(
              icon: const Icon(Icons.calendar_today, size: 18),
              label: Text(toBeginningOfSentenceCase(DateFormat('EEEE d MMMM y', 'fr_FR').format(_date))),
              onPressed: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (d != null) setState(() => _date = d);
              },
            ),
          ),
          IconButton(onPressed: () => _decaler(1), icon: const Icon(Icons.chevron_right), tooltip: 'Jour suivant'),
        ]),
      ),
      if (aVenir.isNotEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: ActionChip(
            avatar: Icon(Icons.warning_amber, color: context.etat.attention),
            label: Text('${aVenir.length} cours à pourvoir à venir — prochain le '
                '${formatDate(DateTime.parse((aVenir..sort((a, b) => a.date.compareTo(b.date))).first.date))}'),
            onPressed: () => setState(() => _date = DateTime.parse(aVenir.first.date)),
          ),
        ),
      Expanded(
        child: AsyncView(ref.watch(remplacementsDuJourProvider(iso)), (List<Remplacement> list) {
          if (list.isEmpty) {
            return const EmptyState('Aucun cours touché par une absence ce jour-là.', icon: Icons.event_available);
          }
          return ListView(padding: const EdgeInsets.all(12), children: [
            for (final r in list)
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: couleurStatut(context, r.statut).withValues(alpha: 0.15),
                    child: Icon(
                      r.statut == StatutRemplacement.aPourvoir ? Icons.priority_high : Icons.check,
                      color: couleurStatut(context, r.statut),
                    ),
                  ),
                  title: Text('${r.plage} · ${classes[r.classeId] ?? '?'} · ${noms[r.matiereId] ?? '?'}'),
                  subtitle: Text([
                    'Absent : ${r.enseignantAbsentNom}',
                    r.statut == StatutRemplacement.remplace ? 'Remplacé par ${r.remplacantNom}' : r.statut.label,
                    if (r.etatNotification != null) r.etatNotification!,
                  ].join('\n')),
                  isThreeLine: true,
                  trailing: r.statut == StatutRemplacement.remplace
                      ? PopupMenuButton<CanalRappel>(
                          tooltip: 'Prévenir le remplaçant',
                          icon: const Icon(Icons.send_to_mobile_outlined),
                          onSelected: (canal) => _prevenir(context, r, canal, noms, classes),
                          itemBuilder: (_) => [
                            for (final canal in CanalRappel.values)
                              PopupMenuItem(
                                  value: canal, child: Text('Prévenir par ${canal.label} (depuis ce téléphone)')),
                          ],
                        )
                      : const Icon(Icons.edit_outlined),
                  onTap: () => _decider(context, r, list, noms, classes),
                ),
              ),
          ]);
        }),
      ),
    ]);
  }

  /// Ouvre SMS ou WhatsApp avec le message déjà rédigé pour le remplaçant.
  Future<void> _prevenir(BuildContext context, Remplacement r, CanalRappel canal, Map<String, String> noms,
      Map<String, String> classes) async {
    final enseignants = await ref.read(enseignantsProvider.future);
    final ecole = await ref.read(ecoleProvider.future);
    if (!context.mounted) return;
    final e = enseignants.where((x) => x.id == r.remplacantId).firstOrNull;
    final tel = e == null ? null : normaliserTelephone(e.telephone, indicatif: ecole.indicatif);
    if (tel == null) {
      showMessage(context, "Pas de numéro valide sur la fiche de ${r.remplacantNom}.", erreur: true);
      return;
    }
    final message = messageRemplacement(
      annulation: false,
      remplacant: r.remplacantNom,
      absent: r.enseignantAbsentNom,
      date: r.date,
      plage: r.plage,
      classe: classes[r.classeId] ?? '',
      branche: noms[r.matiereId] ?? '',
      ecole: ecole.nom,
    );
    if (!await launchUrl(lienRappel(canal, tel, message), mode: LaunchMode.externalApplication) && context.mounted) {
      showMessage(context, "Impossible d'ouvrir ${canal.label} sur cet appareil.", erreur: true);
    }
  }

  Future<void> _decider(BuildContext context, Remplacement r, List<Remplacement> duJour, Map<String, String> noms,
      Map<String, String> classes) async {
    // Attendre les données : elles ne sont pas forcément encore chargées.
    final candidats = remplacantsDisponibles(
      cours: r,
      enseignants: await ref.read(enseignantsProvider.future),
      creneaux: await ref.read(creneauxProvider.future),
      absences: await ref.read(absencesEnseignantsProvider.future),
      remplacementsDuJour: duJour,
      nomsMatieres: {...noms, ...await ref.read(nomsMatieresProvider.future)},
    );
    if (!context.mounted) return;
    final choix = await showModalBottomSheet<(StatutRemplacement, Enseignant?)>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(c).height * 0.8),
          child: ListView(shrinkWrap: true, children: [
            ListTile(
              title: Text('${classes[r.classeId] ?? '?'} · ${noms[r.matiereId] ?? '?'}',
                  style: Theme.of(c).textTheme.titleMedium),
              subtitle: Text('${formatDate(DateTime.parse(r.date))} · ${r.plage} · absent : ${r.enseignantAbsentNom}'),
            ),
            const Divider(),
            ListTile(
              dense: true,
              title:
                  Text(candidats.isEmpty ? 'Aucun enseignant libre à cette heure' : 'Enseignants libres à cette heure'),
            ),
            for (final x in candidats)
              ListTile(
                leading: Icon(x.enseignant.id == r.remplacantId ? Icons.radio_button_checked : Icons.person_outline),
                title: Text(x.enseignant.nomComplet),
                subtitle: Text([
                  ...x.raisons,
                  x.minutesCeJour == 0
                      ? 'Libre toute la journée'
                      : '${x.minutesCeJour ~/ 60} h ${(x.minutesCeJour % 60).toString().padLeft(2, '0')} de cours ce jour',
                ].join(' · ')),
                onTap: () => Navigator.pop(c, (StatutRemplacement.remplace, x.enseignant)),
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.menu_book_outlined),
              title: const Text('Étude surveillée'),
              onTap: () => Navigator.pop(c, (StatutRemplacement.etude, null)),
            ),
            ListTile(
              leading: const Icon(Icons.event_busy_outlined),
              title: const Text('Cours annulé'),
              onTap: () => Navigator.pop(c, (StatutRemplacement.annule, null)),
            ),
            if (r.statut != StatutRemplacement.aPourvoir)
              ListTile(
                leading: const Icon(Icons.undo),
                title: const Text('Remettre « à pourvoir »'),
                onTap: () => Navigator.pop(c, (StatutRemplacement.aPourvoir, null)),
              ),
          ]),
        ),
      ),
    );
    if (choix == null || !context.mounted) return;
    await run(context, () => ref.read(schoolRepoProvider).deciderRemplacement(r.id, choix.$1, remplacant: choix.$2));
  }
}

// ============================================================
// Absences déclarées + bilan par enseignant
// ============================================================
class _AbsencesTab extends ConsumerWidget {
  const _AbsencesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ecole = ref.watch(ecoleProvider).valueOrNull;
    final enseignants = ref.watch(enseignantsProvider).valueOrNull ?? const <Enseignant>[];
    final remplacements = ref.watch(tousRemplacementsProvider).valueOrNull ?? const <Remplacement>[];
    final aujourdhui = isoDay(ref.watch(horlogeProvider)());

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: ecole == null ? null : () => _declarer(context, ref, enseignants, ecole.jours),
        icon: const Icon(Icons.add),
        label: const Text('Déclarer une absence'),
      ),
      body: AsyncView(ref.watch(absencesEnseignantsProvider), (List<AbsenceEnseignant> absences) {
        if (absences.isEmpty) {
          return const EmptyState("Aucune absence d'enseignant déclarée.", icon: Icons.event_available);
        }
        final enCours = absences.where((a) => a.fin.compareTo(aujourdhui) >= 0).toList();
        final passees = absences.where((a) => a.fin.compareTo(aujourdhui) < 0).toList();
        final concernes = {for (final a in absences) a.enseignantId: a.enseignantNom};

        Widget carte(AbsenceEnseignant a) {
          final lies = remplacements.where((r) => r.absenceId == a.id).toList();
          final restants = lies.where((r) => r.statut == StatutRemplacement.aPourvoir).length;
          return Card(
            child: ListTile(
              title: Text(a.enseignantNom),
              subtitle: Text([
                a.debut == a.fin
                    ? 'Le ${formatDate(DateTime.parse(a.debut))}'
                    : 'Du ${formatDate(DateTime.parse(a.debut))} au ${formatDate(DateTime.parse(a.fin))}',
                '${a.motif}${a.justifiee ? ' (justifiée)' : ''}',
                '${lies.length} cours touché(s)${restants > 0 ? ', $restants à pourvoir' : ''}',
                if (a.note.isNotEmpty) a.note,
              ].join('\n')),
              isThreeLine: true,
              trailing: IconButton(
                tooltip: "Supprimer l'absence",
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  if (await confirmer(context,
                          "Supprimer cette absence ? Les ${lies.length} remplacement(s) associés seront aussi supprimés.") &&
                      context.mounted) {
                    await run(context, () => ref.read(schoolRepoProvider).supprimerAbsence(a.id));
                  }
                },
              ),
            ),
          );
        }

        return ListView(padding: const EdgeInsets.fromLTRB(12, 12, 12, 88), children: [
          if (enCours.isNotEmpty) ...[
            Text('En cours et à venir', style: Theme.of(context).textTheme.titleSmall),
            for (final a in enCours) carte(a),
            const SizedBox(height: 12),
          ],
          Card(
            child: Column(children: [
              const ListTile(title: Text('Bilan par enseignant (année)')),
              for (final e in concernes.entries)
                Builder(builder: (context) {
                  final b = bilanAbsences(e.key, absences, remplacements, ecole?.jours ?? const [1, 2, 3, 4, 5]);
                  return ListTile(
                    dense: true,
                    title: Text(e.value),
                    trailing: Text('${b.jours} j · ${b.cours} cours · ${b.coursNonAssures} non assuré(s)'),
                  );
                }),
            ]),
          ),
          if (passees.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Passées', style: Theme.of(context).textTheme.titleSmall),
            for (final a in passees) carte(a),
          ],
        ]);
      }),
    );
  }

  Future<void> _declarer(BuildContext context, WidgetRef ref, List<Enseignant> enseignants, List<int> jours) async {
    if (enseignants.isEmpty) {
      showMessage(context, "Ajoutez d'abord les enseignants.", erreur: true);
      return;
    }
    String? enseignantId;
    var debut = ref.read(horlogeProvider)();
    var fin = debut;
    var motif = motifsAbsence.first;
    var justifiee = false;
    final note = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setState) => AlertDialog(
          title: const Text('Absence d\'un enseignant'),
          content: SizedBox(
            width: 400,
            child: ListView(shrinkWrap: true, children: [
              DropdownButtonFormField<String>(
                value: enseignantId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Enseignant'),
                items: [for (final e in enseignants) DropdownMenuItem(value: e.id, child: Text(e.nomComplet))],
                onChanged: (v) => setState(() => enseignantId = v),
              ),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final d = await showDatePicker(
                          context: c,
                          initialDate: debut,
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 365)));
                      if (d != null) {
                        setState(() {
                          debut = d;
                          if (fin.isBefore(d)) fin = d;
                        });
                      }
                    },
                    child: Text('Du ${formatDate(debut)}'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final d = await showDatePicker(
                          context: c,
                          initialDate: fin,
                          firstDate: debut,
                          lastDate: DateTime.now().add(const Duration(days: 365)));
                      if (d != null) setState(() => fin = d);
                    },
                    child: Text('Au ${formatDate(fin)}'),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: motif,
                decoration: const InputDecoration(labelText: 'Motif'),
                items: [for (final m in motifsAbsence) DropdownMenuItem(value: m, child: Text(m))],
                onChanged: (v) => setState(() => motif = v!),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Absence justifiée'),
                value: justifiee,
                onChanged: (v) => setState(() => justifiee = v),
              ),
              TextField(controller: note, decoration: const InputDecoration(labelText: 'Remarque (facultatif)')),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Annuler')),
            FilledButton(
              onPressed: enseignantId == null ? null : () => Navigator.pop(c, true),
              child: const Text('Déclarer'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !context.mounted) return;
    final e = enseignants.firstWhere((x) => x.id == enseignantId);
    final absence = AbsenceEnseignant(
      id: '',
      enseignantId: e.id,
      enseignantNom: e.nomComplet,
      debut: isoDay(debut),
      fin: isoDay(fin),
      motif: motif,
      justifiee: justifiee,
      note: note.text.trim(),
    );
    int n = 0;
    final reussi = await run(context, () async {
      // L'emploi du temps n'est peut-être pas encore chargé : on l'attend.
      final creneaux = await ref.read(creneauxProvider.future);
      n = await ref.read(schoolRepoProvider).declarerAbsence(
            absence,
            (absenceId) => coursTouches(
              absence: AbsenceEnseignant(
                  id: absenceId,
                  enseignantId: e.id,
                  enseignantNom: e.nomComplet,
                  debut: absence.debut,
                  fin: absence.fin),
              creneaux: creneaux,
              jours: jours,
            ),
          );
    });
    if (reussi && context.mounted) {
      showMessage(
          context,
          n == 0
              ? "Absence enregistrée. Aucun cours de son emploi du temps n'est touché."
              : 'Absence enregistrée : $n cours à pourvoir (onglet « Remplacements du jour »).');
    }
  }
}
