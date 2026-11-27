import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/evaluation.dart';
import '../../core/format.dart';
import '../../services/calculs.dart';
import '../../models/classe.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';
import '../eleves/eleve_detail_screen.dart';

class ClassesScreen extends ConsumerWidget {
  const ClassesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(meProvider);
    final devise = ref.watch(ecoleProvider).valueOrNull?.devise ?? 'USD';
    return Scaffold(
      floatingActionButton: me.isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => editerClasse(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Nouvelle classe'),
            )
          : null,
      body: AsyncView(ref.watch(classesProvider), (classes) {
        if (classes.isEmpty) return const EmptyState('Aucune classe.', icon: Icons.class_outlined);
        return ListView(padding: const EdgeInsets.all(12), children: [
          for (final c in classes)
            Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.class_)),
                title: Text(c.nom),
                subtitle: Text([
                  c.cycle.label,
                  if (c.description.isNotEmpty) c.description,
                  'Frais : ${formatMontant(c.fraisScolarite, devise: devise)}',
                ].join(' · ')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => ClasseDetailScreen(classe: c))),
              ),
            ),
        ]);
      }),
    );
  }
}

Future<void> editerClasse(BuildContext context, WidgetRef ref, [Classe? classe]) async {
  final form = GlobalKey<FormState>();
  final nom = TextEditingController(text: classe?.nom);
  final niveau = TextEditingController(text: classe?.niveau);
  final section = TextEditingController(text: classe?.section);
  final frais = TextEditingController(text: classe == null ? '' : formatPoints(classe.fraisScolarite));
  var cycle = classe?.cycle ?? Cycle.primaire;
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => StatefulBuilder(
      builder: (c, setState) => AlertDialog(
        title: Text(classe == null ? 'Nouvelle classe' : 'Modifier la classe'),
        content: SizedBox(
          width: 420,
          child: Form(
            key: form,
            child: ListView(shrinkWrap: true, children: [
              SegmentedButton<Cycle>(
                segments: [for (final x in Cycle.values) ButtonSegment(value: x, label: Text(x.label))],
                selected: {cycle},
                onSelectionChanged: (v) => setState(() => cycle = v.first),
              ),
              const SizedBox(height: 12),
              Wrap(spacing: 6, children: [
                for (final n in cycle.niveauxRdc)
                  ActionChip(
                    label: Text(n),
                    onPressed: () => setState(() {
                      niveau.text = n;
                      if (nom.text.trim().isEmpty) nom.text = n;
                    }),
                  ),
              ]),
              const SizedBox(height: 12),
              TextFormField(
                  controller: niveau, decoration: const InputDecoration(labelText: 'Niveau (ex. 5e année)')),
              const SizedBox(height: 12),
              TextFormField(
                  controller: nom,
                  decoration: const InputDecoration(labelText: 'Nom de la classe (ex. 5e A)'),
                  validator: requis),
              if (cycle == Cycle.secondaire) ...[
                const SizedBox(height: 12),
                TextFormField(
                    controller: section,
                    decoration: const InputDecoration(
                        labelText: 'Section / option', hintText: 'Scientifique, Commerciale, Pédagogique…')),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: frais,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Frais scolaires annuels (minerval et frais connexes)'),
                validator: (v) => double.tryParse((v ?? '').replaceAll(',', '.')) == null ? 'Montant invalide' : null,
              ),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Annuler')),
          FilledButton(
              onPressed: () {
                if (form.currentState!.validate()) Navigator.pop(c, true);
              },
              child: const Text('Enregistrer')),
        ],
      ),
    ),
  );
  if (ok != true || !context.mounted) return;
  await run(
    context,
    () => ref.read(schoolRepoProvider).enregistrerClasse(Classe(
          id: classe?.id ?? '',
          nom: nom.text.trim(),
          cycle: cycle,
          niveau: niveau.text.trim(),
          section: cycle == Cycle.secondaire ? section.text.trim() : '',
          fraisScolarite: double.parse(frais.text.replaceAll(',', '.')),
          enseignantPrincipalId: classe?.enseignantPrincipalId,
        )),
    succes: 'Classe enregistrée',
  );
}

class ClasseDetailScreen extends ConsumerWidget {
  const ClasseDetailScreen({super.key, required this.classe});
  final Classe classe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(meProvider);
    final systeme = ref.watch(systemeProvider);
    final matieres = ref.watch(matieresProvider(classe.id));
    final eleves = ref.watch(elevesProvider(classe.id));
    return Scaffold(
      appBar: AppBar(title: Text(classe.nom), actions: [
        if (me.isAdmin) ...[
          IconButton(
              icon: const Icon(Icons.edit), onPressed: () => editerClasse(context, ref, classe)),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final nb = eleves.valueOrNull?.length ?? 0;
              if (nb > 0) {
                showMessage(context, 'Impossible : $nb élève(s) sont encore dans cette classe.',
                    erreur: true);
                return;
              }
              if (!await confirmer(context, 'Supprimer la classe ${classe.nom} ?')) return;
              if (!context.mounted) return;
              final ok = await run(context, () => ref.read(schoolRepoProvider).supprimerClasse(classe.id));
              if (ok && context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ]),
      body: ListView(padding: const EdgeInsets.all(12), children: [
        Row(children: [
          Text('Branches', style: Theme.of(context).textTheme.titleMedium),
          const Spacer(),
          if (me.isAdmin)
            TextButton.icon(
              onPressed: () => _editerMatiere(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter'),
            ),
        ]),
        AsyncView(matieres, (list) {
          if (list.isEmpty) {
            return const Padding(
                padding: EdgeInsets.all(8), child: Text('Aucune branche pour cette classe.'));
          }
          return Card(
            child: Column(children: [
              for (final m in list)
                ListTile(
                  dense: true,
                  title: Text(m.nom),
                  subtitle: Text(classe.cycle == Cycle.maternelle
                      ? 'Évaluée en cotes (A, ECA, NA)'
                      : systeme == SystemeEvaluation.rdc
                          ? 'Maxima ${formatPoints(m.maxima)} par période · ${formatPoints(m.maxima * 2)} à l\'examen'
                          : 'Coefficient ${formatPoints(m.coefficient)}'),
                  trailing: me.isAdmin
                      ? IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            if (await confirmer(context, 'Supprimer ${m.nom} ?') && context.mounted) {
                              await run(context, () => ref.read(schoolRepoProvider).supprimerMatiere(m.id));
                            }
                          })
                      : null,
                  onTap: me.isAdmin ? () => _editerMatiere(context, ref, m) : null,
                ),
            ]),
          );
        }),
        const SizedBox(height: 16),
        Text('Élèves (${eleves.valueOrNull?.length ?? 0})',
            style: Theme.of(context).textTheme.titleMedium),
        AsyncView(eleves, (list) => Card(
              child: Column(children: [
                for (final e in list)
                  ListTile(
                    dense: true,
                    title: Text(e.nomComplet),
                    subtitle: Text(e.matricule),
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => EleveDetailScreen(eleveId: e.id))),
                  ),
                if (list.isEmpty)
                  const Padding(padding: EdgeInsets.all(16), child: Text('Aucun élève.')),
              ]),
            )),
      ]),
    );
  }

  Future<void> _editerMatiere(BuildContext context, WidgetRef ref, [Matiere? m]) async {
    final systeme = ref.read(systemeProvider);
    final nom = TextEditingController(text: m?.nom);
    final maxima = TextEditingController(text: formatPoints(m?.maxima ?? 10));
    final coef = TextEditingController(text: formatPoints(m?.coefficient ?? 1));
    final maternelle = classe.cycle == Cycle.maternelle;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(m == null ? 'Nouvelle branche' : 'Modifier la branche'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nom, decoration: const InputDecoration(labelText: 'Branche (ex. Français, Calcul)')),
          if (!maternelle && systeme == SystemeEvaluation.rdc) ...[
            const SizedBox(height: 12),
            TextField(
                controller: maxima,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Maxima par période', helperText: "L'examen est noté sur le double")),
          ],
          if (!maternelle && systeme == SystemeEvaluation.trimestres) ...[
            const SizedBox(height: 12),
            TextField(
                controller: coef,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Coefficient')),
          ],
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Enregistrer')),
        ],
      ),
    );
    if (ok != true || nom.text.trim().isEmpty || !context.mounted) return;
    await run(
        context,
        () => ref.read(schoolRepoProvider).enregistrerMatiere(Matiere(
              id: m?.id ?? '',
              classeId: classe.id,
              nom: nom.text.trim(),
              maxima: double.tryParse(maxima.text.replaceAll(',', '.')) ?? 10,
              coefficient: double.tryParse(coef.text.replaceAll(',', '.')) ?? 1,
              enseignantId: m?.enseignantId,
            )));
  }
}
