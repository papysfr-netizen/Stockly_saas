import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/evaluation.dart';
import '../../core/format.dart';
import '../../models/absence_eleve.dart';
import '../../models/app_user.dart';
import '../../models/classe.dart';
import '../../models/eleve.dart';
import '../../models/scolarite.dart';
import '../../providers/providers.dart';
import '../../services/calculs.dart';
import '../../services/suivi_absences.dart';
import '../../widgets/common.dart';
import '../paiements/encaisser_dialog.dart';
import '../emploi_du_temps/emploi_du_temps_screen.dart';
import '../paiements/rappels_actions.dart';
import 'eleve_form_screen.dart';

/// Fiche élève : utilisée par le personnel et par les parents (lecture seule).
class EleveDetailScreen extends ConsumerWidget {
  const EleveDetailScreen({super.key, required this.eleveId});
  final String eleveId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(meProvider);
    return AsyncView(ref.watch(eleveProvider(eleveId)), (Eleve? eleve) {
      if (eleve == null) {
        return Scaffold(appBar: AppBar(), body: const EmptyState('Élève introuvable.'));
      }
      return DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: AppBar(
            title: Text(eleve.nomComplet),
            actions: [
              if (me.canManageEleves) ...[
                IconButton(
                  tooltip: 'Modifier',
                  icon: const Icon(Icons.edit),
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => EleveFormScreen(eleve: eleve))),
                ),
                IconButton(
                  tooltip: 'Retirer (départ, fin de scolarité)',
                  icon: const Icon(Icons.archive_outlined),
                  onPressed: () async {
                    if (!await confirmer(context,
                        "Retirer ${eleve.nomComplet} des effectifs ? Son historique est conservé.")) {
                      return;
                    }
                    if (!context.mounted) return;
                    final ok = await run(context, () => ref.read(schoolRepoProvider).archiverEleve(eleve.id));
                    if (ok && context.mounted) Navigator.pop(context);
                  },
                ),
              ],
            ],
            bottom: const TabBar(isScrollable: true, tabs: [
              Tab(text: 'Infos & frais'),
              Tab(text: 'Notes'),
              Tab(text: 'Absences'),
              Tab(text: 'Emploi du temps'),
            ]),
          ),
          floatingActionButton: me.canManagePaiements
              ? FloatingActionButton.extended(
                  onPressed: () => encaisserPaiement(context, ref, eleve),
                  icon: const Icon(Icons.payments),
                  label: const Text('Encaisser'),
                )
              : null,
          body: TabBarView(children: [
            _InfosTab(eleve),
            _NotesTab(eleve),
            _AbsencesTab(eleve),
            _EmploiDuTempsTab(eleve),
          ]),
        ),
      );
    });
  }
}

class _InfosTab extends ConsumerWidget {
  const _InfosTab(this.eleve);
  final Eleve eleve;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(meProvider);
    final devise = ref.watch(ecoleProvider).valueOrNull?.devise ?? 'USD';
    final classes = ref.watch(toutesClassesProvider).valueOrNull ?? const [];
    final classe = classes.where((c) => c.id == eleve.classeId).firstOrNull;
    final paiements = ref.watch(paiementsProvider(eleve.id));
    String m(num v) => formatMontant(v, devise: devise);

    return ListView(padding: const EdgeInsets.all(12), children: [
      Card(
        child: Column(children: [
          _info('Matricule', eleve.matricule),
          _info('Classe', classe?.nom ?? '-'),
          _info('Sexe', eleve.sexe == 'F' ? 'Fille' : 'Garçon'),
          _info('Date de naissance', formatDate(eleve.dateNaissance)),
          _info('Inscrit le', formatDate(eleve.dateInscription)),
          _info('Parent', eleve.parentNom),
          _info('Téléphone', eleve.parentTelephone),
          _info('E-mail parent', eleve.parentEmail),
        ]),
      ),
      const SizedBox(height: 8),
      AsyncView(paiements, (List<Paiement> list) {
        final frais = classe?.fraisScolarite ?? 0;
        final reste = resteAPayer(frais, list);
        final paye = list.fold<double>(0, (s, p) => s + p.montant);
        return Column(children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Frais de scolarité', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: frais == 0 ? 0 : (paye / frais).clamp(0, 1), minHeight: 8),
                const SizedBox(height: 8),
                Text('Payé : ${m(paye)} / ${m(frais)}'),
                Row(children: [
                  Expanded(
                    child: Text('Reste : ${m(reste)}',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: reste > 0 ? Colors.orange.shade800 : Colors.green)),
                  ),
                  if (reste > 0 && me.canManagePaiements) MenuRelance(eleve: eleve, reste: reste),
                ]),
              ]),
            ),
          ),
          Card(
            child: Column(children: [
              const ListTile(title: Text('Historique des paiements')),
              for (final p in list)
                ListTile(
                  dense: true,
                  title: Text('${m(p.montant)} · ${p.motif}'),
                  subtitle: Text('${formatDate(p.date)} · ${p.mode} · ${p.recuNumero}'),
                  trailing: IconButton(
                    tooltip: 'Imprimer le reçu',
                    icon: const Icon(Icons.print_outlined),
                    onPressed: () => imprimerRecu(ref, eleve, p),
                  ),
                  onLongPress: me.isAdmin
                      ? () async {
                          if (await confirmer(context, 'Annuler le paiement ${p.recuNumero} ?') &&
                              context.mounted) {
                            await run(context, () => ref.read(schoolRepoProvider).annulerPaiement(p.id),
                                succes: 'Paiement annulé');
                          }
                        }
                      : null,
                ),
              if (list.isEmpty) const Padding(padding: EdgeInsets.all(16), child: Text('Aucun paiement.')),
            ]),
          ),
        ]);
      }),
      const SizedBox(height: 72),
    ]);
  }

  Widget _info(String label, String valeur) => ListTile(
        dense: true,
        title: Text(label),
        trailing: Text(valeur.isEmpty ? '-' : valeur),
      );
}

class _NotesTab extends ConsumerWidget {
  const _NotesTab(this.eleve);
  final Eleve eleve;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final systeme = ref.watch(systemeProvider);
    final classes = ref.watch(toutesClassesProvider).valueOrNull ?? const [];
    final classe = classes.where((c) => c.id == eleve.classeId).firstOrNull;
    final matieres = ref.watch(matieresProvider(eleve.classeId)).valueOrNull ?? const [];
    final comps = ref.watch(comportementsEleveProvider(eleve.id)).valueOrNull ?? const <Comportement>[];
    if (classe == null) return const EmptyState('Classe inconnue.');
    return AsyncView(ref.watch(notesEleveProvider(eleve.id)), (List<Note> notes) {
      if (matieres.isEmpty) return const EmptyState('Aucune branche définie pour la classe.');
      // Seulement les notes de la classe actuelle (un élève peut avoir changé de classe).
      final ev = Evaluations(notes.where((n) => n.classeId == eleve.classeId));
      final maternelle = classe.cycle == Cycle.maternelle;
      final vues = vuesPour(systeme, classe.cycle);
      return ListView(padding: const EdgeInsets.all(12), children: [
        for (final (i, vue) in vues.indexed)
          if (vue.codes.length == 1 || !maternelle)
            Card(
              child: ExpansionTile(
                initiallyExpanded: i == 0,
                title: Text(vue.label),
                subtitle: maternelle
                    ? null
                    : Text(formatScore(systeme,
                        scoreEleve(systeme: systeme, eleveId: eleve.id, matieres: matieres, codes: vue.codes, ev: ev))),
                children: [
                  for (final m in matieres)
                    ListTile(
                      dense: true,
                      title: Text(m.nom),
                      trailing: Text(_valeur(systeme, maternelle, ev, m, vue.codes)),
                    ),
                  if (vue.codes.length == 1)
                    for (final c in comps.where((c) => c.periode == vue.codes.single))
                      ListTile(
                        dense: true,
                        title: const Text('Application / conduite'),
                        trailing: Text('${c.application} / ${c.conduite}'),
                      ),
                ],
              ),
            ),
      ]);
    });
  }

  String _valeur(SystemeEvaluation s, bool maternelle, Evaluations ev, Matiere m, List<String> codes) {
    if (maternelle) {
      final cote = ev.de(eleve.id, m.id, codes.single)?.cote;
      return cote == null ? '-' : cotesMaternelle.firstWhere((c) => c.$1 == cote).$2;
    }
    if (s == SystemeEvaluation.trimestres) {
      return formatNote(scoreEleve(systeme: s, eleveId: eleve.id, matieres: [m], codes: codes, ev: ev));
    }
    final t = ev.total(eleve.id, m.id, codes);
    return t == null ? '-' : '${formatPoints(t.points)} / ${formatPoints(t.maxima)}';
  }
}

class _AbsencesTab extends ConsumerWidget {
  const _AbsencesTab(this.eleve);
  final Eleve eleve;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(meProvider);
    final gestion = me.canManageEleves;
    final parent = me.role == Role.parent;
    return AsyncView(ref.watch(absencesEleveProvider(eleve.id)), (List<AbsenceEleve> list) {
      if (list.isEmpty) return const EmptyState('Aucune absence ni retard.', icon: Icons.check_circle_outline);
      final b = bilan(list);
      return ListView(padding: const EdgeInsets.all(12), children: [
        Text(
          '${b.absences} absence(s) dont ${b.nonJustifiees} non justifiée(s) · ${b.retards} retard(s)',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        for (final a in list)
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                ListTile(
                  leading: Icon(a.estAbsence ? Icons.cancel : Icons.schedule,
                      color: !a.estAbsence
                          ? Colors.orange
                          : a.justifiee
                              ? Colors.blueGrey
                              : Colors.red),
                  title: Text('${a.statut.label} · ${formatDate(a.date)}'),
                  subtitle: Text([
                    if (a.justifiee) 'Justifiée : ${a.motif}${a.note.isEmpty ? '' : ' (${a.note})'}',
                    if (!a.justifiee && a.estAbsence && a.justificationParent == null) 'Non justifiée',
                    if (a.enAttente)
                      'Justification du parent en attente : ${a.justificationParent!.motif}'
                          '${a.justificationParent!.message.isEmpty ? '' : ' — « ${a.justificationParent!.message} »'}',
                    if (gestion && a.etatAlerte != null) a.etatAlerte!,
                  ].join('\n')),
                ),
                if (a.estAbsence && (gestion || (parent && !a.justifiee)))
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    child: Wrap(spacing: 8, runSpacing: 4, alignment: WrapAlignment.end, children: [
                      if (gestion && a.enAttente) ...[
                        FilledButton.tonal(
                          onPressed: () => run(
                            context,
                            () => ref.read(schoolRepoProvider).justifierAbsence(a.id,
                                motif: a.justificationParent!.motif, note: a.justificationParent!.message, par: me.nom),
                            succes: 'Justification acceptée',
                          ),
                          child: const Text('Accepter'),
                        ),
                        TextButton(
                          onPressed: () => run(context, () => ref.read(schoolRepoProvider).refuserJustification(a.id),
                              succes: 'Justification refusée'),
                          child: const Text('Refuser'),
                        ),
                      ],
                      if (gestion && !a.justifiee && !a.enAttente)
                        OutlinedButton(
                          onPressed: () => _justifier(context, ref, a, parParent: false),
                          child: const Text('Justifier'),
                        ),
                      if (gestion && a.justifiee)
                        TextButton(
                          onPressed: () => run(context, () => ref.read(schoolRepoProvider).annulerJustification(a.id)),
                          child: const Text('Annuler la justification'),
                        ),
                      if (parent && !a.justifiee)
                        OutlinedButton(
                          onPressed: () => _justifier(context, ref, a, parParent: true),
                          child: Text(a.enAttente ? 'Modifier ma justification' : 'Justifier cette absence'),
                        ),
                    ]),
                  ),
              ]),
            ),
          ),
      ]);
    });
  }

  Future<void> _justifier(BuildContext context, WidgetRef ref, AbsenceEleve a, {required bool parParent}) async {
    var motif = a.justificationParent?.motif ?? motifsJustification.first;
    if (!motifsJustification.contains(motif)) motif = 'Autre';
    final note = TextEditingController(text: a.justificationParent?.message);
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setState) => AlertDialog(
          title: Text('Absence du ${formatDate(a.date)}'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<String>(
              value: motif,
              decoration: const InputDecoration(labelText: 'Motif'),
              items: [for (final m in motifsJustification) DropdownMenuItem(value: m, child: Text(m))],
              onChanged: (v) => setState(() => motif = v!),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: note,
              maxLines: 3,
              decoration: InputDecoration(
                  labelText: parParent ? 'Message (facultatif)' : 'Remarque (facultatif)'),
            ),
            if (parParent) ...[
              const SizedBox(height: 8),
              const Text("L'école validera votre justification.", style: TextStyle(fontSize: 12)),
            ],
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Annuler')),
            FilledButton(
                onPressed: () => Navigator.pop(c, true), child: Text(parParent ? 'Envoyer' : 'Justifier')),
          ],
        ),
      ),
    );
    if (ok != true || !context.mounted) return;
    final repo = ref.read(schoolRepoProvider);
    await run(
      context,
      () => parParent
          ? repo.proposerJustification(a.id, motif: motif, message: note.text.trim())
          : repo.justifierAbsence(a.id, motif: motif, note: note.text.trim(), par: ref.read(meProvider).nom),
      succes: parParent ? "Justification envoyée à l'école" : 'Absence justifiée',
    );
  }
}

class _EmploiDuTempsTab extends ConsumerWidget {
  const _EmploiDuTempsTab(this.eleve);
  final Eleve eleve;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classes = ref.watch(toutesClassesProvider).valueOrNull ?? const [];
    final classe = classes.where((c) => c.id == eleve.classeId).firstOrNull;
    if (classe == null) return const EmptyState('Classe inconnue.');
    return ListView(padding: const EdgeInsets.all(12), children: [EmploiDuTempsClasse(classe: classe)]);
  }
}
