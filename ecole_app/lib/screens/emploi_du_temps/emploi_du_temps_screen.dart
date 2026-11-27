import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_user.dart';
import '../../models/classe.dart';
import '../../models/ecole.dart';
import '../../core/format.dart';
import '../../models/emploi_du_temps.dart';
import '../../models/remplacement.dart';
import '../../models/scolarite.dart';
import '../../providers/providers.dart';
import '../../services/emploi_du_temps.dart';
import '../../services/pdf_service.dart';
import '../../widgets/common.dart';
import 'grille.dart';

enum _Vue { classe, enseignant }

class EmploiDuTempsScreen extends ConsumerStatefulWidget {
  const EmploiDuTempsScreen({super.key});
  @override
  ConsumerState<EmploiDuTempsScreen> createState() => _EmploiDuTempsScreenState();
}

class _EmploiDuTempsScreenState extends ConsumerState<EmploiDuTempsScreen> {
  late _Vue _vue = ref.read(meProvider).role == Role.enseignant ? _Vue.enseignant : _Vue.classe;
  String? _classeId;
  String? _enseignantId;

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(meProvider);
    final ecole = ref.watch(ecoleProvider).valueOrNull;
    final classes = ref.watch(toutesClassesProvider).valueOrNull ?? const <Classe>[];
    final enseignants = ref.watch(enseignantsProvider).valueOrNull ?? const <Enseignant>[];
    final moi = ref.watch(monEnseignantProvider);
    if (ecole == null) return const Center(child: CircularProgressIndicator());

    final estEnseignant = me.role == Role.enseignant;
    final enseignantId = estEnseignant ? moi?.id : _enseignantId;

    return ListView(padding: const EdgeInsets.all(12), children: [
      Wrap(spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
        SegmentedButton<_Vue>(
          segments: [
            const ButtonSegment(value: _Vue.classe, label: Text('Par classe'), icon: Icon(Icons.class_outlined)),
            ButtonSegment(
              value: _Vue.enseignant,
              label: Text(estEnseignant ? 'Mon emploi du temps' : 'Par enseignant'),
              icon: const Icon(Icons.co_present_outlined),
            ),
          ],
          selected: {_vue},
          onSelectionChanged: (s) => setState(() => _vue = s.first),
        ),
        if (_vue == _Vue.classe)
          SizedBox(
            width: 240,
            child: DropdownButtonFormField<String>(
              value: classes.any((c) => c.id == _classeId) ? _classeId : null,
              decoration: const InputDecoration(labelText: 'Classe'),
              items: [for (final c in classes) DropdownMenuItem(value: c.id, child: Text(c.nom))],
              onChanged: (v) => setState(() => _classeId = v),
            ),
          ),
        if (_vue == _Vue.enseignant && !estEnseignant)
          SizedBox(
            width: 260,
            child: DropdownButtonFormField<String>(
              value: enseignants.any((e) => e.id == _enseignantId) ? _enseignantId : null,
              decoration: const InputDecoration(labelText: 'Enseignant'),
              items: [for (final e in enseignants) DropdownMenuItem(value: e.id, child: Text(e.nomComplet))],
              onChanged: (v) => setState(() => _enseignantId = v),
            ),
          ),
      ]),
      const SizedBox(height: 12),
      if (_vue == _Vue.classe)
        _classeId == null || !classes.any((c) => c.id == _classeId)
            ? const EmptyState('Choisissez une classe.', icon: Icons.calendar_view_week)
            : EmploiDuTempsClasse(classe: classes.firstWhere((c) => c.id == _classeId), modifiable: me.isAdmin)
      else if (enseignantId == null)
        EmptyState(
          estEnseignant
              ? "Votre compte n'est relié à aucune fiche enseignant.\n"
                  "Demandez à la direction d'indiquer votre e-mail ou votre téléphone sur votre fiche."
              : 'Choisissez un enseignant.',
          icon: Icons.co_present_outlined,
        )
      else
        _EmploiDuTempsEnseignant(ecole: ecole, enseignant: enseignants.firstWhere((e) => e.id == enseignantId)),
    ]);
  }
}

/// Emploi du temps d'une classe ; modifiable par la direction.
/// Aussi utilisé (en lecture) sur la fiche élève, donc par les parents.
class EmploiDuTempsClasse extends ConsumerWidget {
  const EmploiDuTempsClasse({super.key, required this.classe, this.modifiable = false});
  final Classe classe;
  final bool modifiable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ecole = ref.watch(ecoleProvider).valueOrNull;
    final tous = ref.watch(creneauxProvider).valueOrNull;
    final matieres = ref.watch(matieresProvider(classe.id)).valueOrNull ?? const <Matiere>[];
    if (ecole == null || tous == null) return const Center(child: CircularProgressIndicator());
    final nomMatiere = {for (final m in matieres) m.id: m.nom};
    final siens = tous.where((c) => c.classeId == classe.id).toList();
    final horsGrille =
        siens.where((c) => !ecole.plagesHoraires.contains(c.plage) || !ecole.jours.contains(c.jour)).toList();
    final volumes = volumeHoraire(siens, (c) => c.matiereId);

    String texte(Creneau c) =>
        [c.enseignantNom, if (c.salle.isNotEmpty) 'Salle ${c.salle}'].where((s) => s.isNotEmpty).join(' · ');

    final changements = ref.watch(remplacementsClasseProvider(classe.id)).valueOrNull ?? const <Remplacement>[];

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      ChangementsAVenir(
        titre: 'Changements à venir',
        remplacements: changements,
        libelle: (r) => '${nomMatiere[r.matiereId] ?? '?'} : ${r.resume}',
      ),
      Row(children: [
        Expanded(child: Text('Emploi du temps — ${classe.nom}', style: Theme.of(context).textTheme.titleMedium)),
        IconButton(
          tooltip: 'Imprimer / PDF',
          icon: const Icon(Icons.print_outlined),
          onPressed: () => run(context, () async {
            final bytes = await PdfService.emploiDuTemps(
              ecole: ecole,
              titre: 'Emploi du temps — ${classe.nom}${classe.section.isEmpty ? '' : ' (${classe.section})'}',
              creneaux: siens,
              contenu: (c) => (titre: nomMatiere[c.matiereId] ?? '?', detail: texte(c)),
            );
            await PdfService.afficher(bytes, 'emploi_du_temps_${classe.nom}.pdf');
          }),
        ),
      ]),
      if (modifiable && matieres.isEmpty)
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text("Ajoutez d'abord les branches de la classe (menu Classes)."),
        ),
      GrilleEmploiDuTemps(
        jours: ecole.jours,
        plages: ecole.plagesHoraires,
        creneaux: siens,
        contenu: (c) => (titre: nomMatiere[c.matiereId] ?? '?', detail: texte(c)),
        onTap: modifiable && matieres.isNotEmpty
            ? (jour, plage, existant) => _editer(context, ref, ecole, matieres, tous, jour, plage, existant)
            : null,
      ),
      if (horsGrille.isNotEmpty) ...[
        const SizedBox(height: 12),
        Text('Heures hors de la grille actuelle', style: Theme.of(context).textTheme.titleSmall),
        for (final c in horsGrille)
          ListTile(
            dense: true,
            title: Text('${nomsJours[c.jour - 1]} ${c.plage} · ${nomMatiere[c.matiereId] ?? '?'}'),
            subtitle: const Text('Ne correspond plus à la grille horaire (Paramètres).'),
            trailing: modifiable
                ? IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => run(context, () => ref.read(schoolRepoProvider).supprimerCreneau(c.id)),
                  )
                : null,
          ),
      ],
      if (volumes.isNotEmpty) ...[
        const SizedBox(height: 12),
        Card(
          child: Column(children: [
            ListTile(
              title: const Text('Volume horaire hebdomadaire'),
              trailing: Text(formatDuree(volumes.values.fold(0, (a, b) => a + b)),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            for (final e in (volumes.entries.toList()..sort((a, b) => b.value.compareTo(a.value))))
              ListTile(dense: true, title: Text(nomMatiere[e.key] ?? '?'), trailing: Text(formatDuree(e.value))),
          ]),
        ),
      ],
    ]);
  }

  Future<void> _editer(BuildContext context, WidgetRef ref, Ecole ecole, List<Matiere> matieres, List<Creneau> tous,
      int jour, String plage, Creneau? existant) async {
    final enseignants = await ref.read(enseignantsProvider.future);
    if (!context.mounted) return;
    // Enseignants de la classe d'abord.
    final tries = [...enseignants]..sort((a, b) {
        final x = a.classeIds.contains(classe.id) ? 0 : 1, y = b.classeIds.contains(classe.id) ? 0 : 1;
        return x != y ? x.compareTo(y) : a.nomComplet.compareTo(b.nomComplet);
      });
    String? matiereId = existant?.matiereId;
    String? enseignantId = existant?.enseignantId;
    final salle = TextEditingController(text: existant?.salle);

    /// Par défaut : l'enseignant qui a déjà cette branche dans cette classe.
    String? enseignantHabituel(String mId) =>
        tous
            .where((c) => c.classeId == classe.id && c.matiereId == mId && c.enseignantId != null)
            .firstOrNull
            ?.enseignantId ??
        matieres.where((m) => m.id == mId).firstOrNull?.enseignantId;

    final action = await showDialog<String>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setState) => AlertDialog(
          title: Text('${nomsJours[jour - 1]} · $plage'),
          content: SizedBox(
            width: 380,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<String>(
                value: matiereId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Branche'),
                items: [for (final m in matieres) DropdownMenuItem(value: m.id, child: Text(m.nom))],
                onChanged: (v) => setState(() {
                  matiereId = v;
                  enseignantId ??= enseignantHabituel(v!);
                }),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                value: tries.any((e) => e.id == enseignantId) ? enseignantId : null,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Enseignant'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('— Non précisé —')),
                  for (final e in tries)
                    DropdownMenuItem(
                      value: e.id,
                      child: Text(e.classeIds.contains(classe.id) ? e.nomComplet : '${e.nomComplet} (autre classe)'),
                    ),
                ],
                onChanged: (v) => setState(() => enseignantId = v),
              ),
              const SizedBox(height: 12),
              TextField(controller: salle, decoration: const InputDecoration(labelText: 'Salle (facultatif)')),
            ]),
          ),
          actions: [
            if (existant != null)
              TextButton(onPressed: () => Navigator.pop(c, 'vider'), child: const Text('Vider la case')),
            TextButton(onPressed: () => Navigator.pop(c), child: const Text('Annuler')),
            FilledButton(
                onPressed: matiereId == null ? null : () => Navigator.pop(c, 'ok'), child: const Text('Enregistrer')),
          ],
        ),
      ),
    );
    if (!context.mounted || action == null) return;
    final repo = ref.read(schoolRepoProvider);
    if (action == 'vider') {
      await run(context, () => repo.supprimerCreneau(existant!.id));
      return;
    }
    final enseignant = enseignants.where((e) => e.id == enseignantId).firstOrNull;
    final nouveau = Creneau(
      id: '',
      classeId: classe.id,
      jour: jour,
      plage: plage,
      matiereId: matiereId!,
      enseignantId: enseignant?.id,
      enseignantNom: enseignant?.nomComplet ?? '',
      salle: salle.text.trim(),
    );
    final clash = conflits(tous, nouveau);
    if (clash.isNotEmpty) {
      final classes = {for (final c in ref.read(toutesClassesProvider).valueOrNull ?? const <Classe>[]) c.id: c.nom};
      showMessage(
        context,
        'Conflit : ${clash.map((c) => '${classes[c.classeId] ?? '?'} (${c.plage}'
            '${c.enseignantId == nouveau.enseignantId && c.enseignantId != null ? ', même enseignant' : ', même salle'})').join(' ; ')}',
        erreur: true,
      );
      return;
    }
    await run(context, () => repo.enregistrerCreneau(nouveau));
  }
}

class _EmploiDuTempsEnseignant extends ConsumerWidget {
  const _EmploiDuTempsEnseignant({required this.ecole, required this.enseignant});
  final Ecole ecole;
  final Enseignant enseignant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tous = ref.watch(creneauxProvider).valueOrNull;
    final classes = {for (final c in ref.watch(toutesClassesProvider).valueOrNull ?? const <Classe>[]) c.id: c};
    if (tous == null) return const Center(child: CircularProgressIndicator());
    final siens = tous.where((c) => c.enseignantId == enseignant.id).toList();
    // Noms de branches de toutes ses classes.
    final noms = <String, String>{};
    for (final cid in siens.map((c) => c.classeId).toSet()) {
      for (final m in ref.watch(matieresProvider(cid)).valueOrNull ?? const <Matiere>[]) {
        noms[m.id] = m.nom;
      }
    }
    ContenuCase contenu(Creneau c) => (
          titre: classes[c.classeId]?.nom ?? '?',
          detail: [noms[c.matiereId] ?? '', if (c.salle.isNotEmpty) 'Salle ${c.salle}'].join(' · '),
        );
    final total = volumeHoraire(siens, (_) => 'total')['total'] ?? 0;
    final assures = ref.watch(remplacementsAssuresProvider(enseignant.id)).valueOrNull ?? const <Remplacement>[];
    final tousNoms = ref.watch(nomsMatieresProvider).valueOrNull ?? const <String, String>{};

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      ChangementsAVenir(
        titre: 'Remplacements à assurer',
        remplacements: assures.where((r) => r.statut == StatutRemplacement.remplace).toList(),
        libelle: (r) => '${classes[r.classeId]?.nom ?? '?'} · ${tousNoms[r.matiereId] ?? '?'} (pour ${r.enseignantAbsentNom})',
      ),
      Row(children: [
        Expanded(
          child: Text('${enseignant.nomComplet} — ${formatDuree(total)} de cours par semaine',
              style: Theme.of(context).textTheme.titleMedium),
        ),
        IconButton(
          tooltip: 'Imprimer / PDF',
          icon: const Icon(Icons.print_outlined),
          onPressed: () => run(context, () async {
            final bytes = await PdfService.emploiDuTemps(
                ecole: ecole, titre: 'Emploi du temps — ${enseignant.nomComplet}', creneaux: siens, contenu: contenu);
            await PdfService.afficher(bytes, 'emploi_du_temps_${enseignant.nom}.pdf');
          }),
        ),
      ]),
      if (siens.isEmpty)
        const EmptyState("Aucune heure de cours attribuée pour l'instant.", icon: Icons.event_busy)
      else
        GrilleEmploiDuTemps(jours: ecole.jours, plages: ecole.plagesHoraires, creneaux: siens, contenu: contenu),
    ]);
  }
}

/// Changements des 14 prochains jours (absences, remplacements, cours annulés).
class ChangementsAVenir extends ConsumerWidget {
  const ChangementsAVenir({super.key, required this.titre, required this.remplacements, required this.libelle});
  final String titre;
  final List<Remplacement> remplacements;
  final String Function(Remplacement r) libelle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aujourdhui = isoDay(DateTime.now());
    final limite = isoDay(DateTime.now().add(const Duration(days: 14)));
    final list = remplacements.where((r) => r.date.compareTo(aujourdhui) >= 0 && r.date.compareTo(limite) <= 0).toList()
      ..sort((a, b) => a.date != b.date ? a.date.compareTo(b.date) : a.plage.compareTo(b.plage));
    if (list.isEmpty) return const SizedBox.shrink();
    return Card(
      color: Theme.of(context).colorScheme.tertiaryContainer.withValues(alpha: 0.4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        ListTile(leading: const Icon(Icons.campaign_outlined), title: Text(titre)),
        for (final r in list)
          ListTile(
            dense: true,
            title: Text('${nomsJours[r.jour - 1]} ${formatDate(DateTime.parse(r.date))} · ${r.plage}'),
            subtitle: Text(libelle(r)),
          ),
      ]),
    );
  }
}
