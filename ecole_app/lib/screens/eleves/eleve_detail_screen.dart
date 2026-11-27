import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../models/eleve.dart';
import '../../models/scolarite.dart';
import '../../providers/providers.dart';
import '../../services/calculs.dart';
import '../../widgets/common.dart';
import '../paiements/encaisser_dialog.dart';
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
        length: 3,
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
            bottom: const TabBar(tabs: [
              Tab(text: 'Infos & frais'),
              Tab(text: 'Notes'),
              Tab(text: 'Absences'),
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
    final devise = ref.watch(ecoleProvider).valueOrNull?.devise ?? 'FCFA';
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
                Text('Reste : ${m(reste)}',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: reste > 0 ? Colors.orange.shade800 : Colors.green)),
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
    final matieres = ref.watch(matieresProvider(eleve.classeId)).valueOrNull ?? const [];
    return AsyncView(ref.watch(notesEleveProvider(eleve.id)), (List<Note> notes) {
      if (matieres.isEmpty) return const EmptyState('Aucune matière définie pour la classe.');
      return ListView(padding: const EdgeInsets.all(12), children: [
        for (final t in [1, 2, 3])
          Builder(builder: (context) {
            final lignes = [
              for (final mat in matieres)
                LigneBulletin(
                  mat,
                  notes
                      .where((n) => n.trimestre == t && n.matiereId == mat.id && n.classeId == eleve.classeId)
                      .firstOrNull
                      ?.sur20,
                ),
            ];
            final moy = moyennePonderee(lignes);
            return Card(
              child: ExpansionTile(
                initiallyExpanded: t == 1,
                title: Text('Trimestre $t'),
                subtitle: Text('Moyenne : ${formatNote(moy)} / 20 · ${appreciation(moy)}'),
                children: [
                  for (final l in lignes)
                    ListTile(
                      dense: true,
                      title: Text(l.matiere.nom),
                      subtitle: Text('Coef. ${l.matiere.coefficient.toStringAsFixed(0)}'),
                      trailing: Text(formatNote(l.note)),
                    ),
                ],
              ),
            );
          }),
      ]);
    });
  }
}

class _AbsencesTab extends ConsumerWidget {
  const _AbsencesTab(this.eleve);
  final Eleve eleve;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncView(ref.watch(absencesEleveProvider(eleve.id)), (list) {
      if (list.isEmpty) return const EmptyState('Aucune absence ni retard.', icon: Icons.check_circle_outline);
      final absences = list.where((a) => a.statut == StatutPresence.absent).length;
      return ListView(padding: const EdgeInsets.all(12), children: [
        Text('$absences absence(s), ${list.length - absences} retard(s)',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final a in list)
          Card(
            child: ListTile(
              leading: Icon(a.statut == StatutPresence.absent ? Icons.cancel : Icons.schedule,
                  color: a.statut == StatutPresence.absent ? Colors.red : Colors.orange),
              title: Text(a.statut.label),
              subtitle: Text(formatDate(a.date)),
            ),
          ),
      ]);
    });
  }
}
