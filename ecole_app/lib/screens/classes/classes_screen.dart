import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../models/classe.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';
import '../eleves/eleve_detail_screen.dart';

class ClassesScreen extends ConsumerWidget {
  const ClassesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(meProvider);
    final devise = ref.watch(ecoleProvider).valueOrNull?.devise ?? 'FCFA';
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
                  if (c.niveau.isNotEmpty) c.niveau,
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
  final frais = TextEditingController(text: classe == null ? '' : classe.fraisScolarite.toStringAsFixed(0));
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(classe == null ? 'Nouvelle classe' : 'Modifier la classe'),
      content: Form(
        key: form,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextFormField(
              controller: nom,
              decoration: const InputDecoration(labelText: 'Nom (ex. CM2 A)'),
              validator: requis),
          const SizedBox(height: 12),
          TextFormField(
              controller: niveau, decoration: const InputDecoration(labelText: 'Niveau / cycle')),
          const SizedBox(height: 12),
          TextFormField(
            controller: frais,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Frais de scolarité annuels'),
            validator: (v) => double.tryParse(v ?? '') == null ? 'Montant invalide' : null,
          ),
        ]),
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
  );
  if (ok != true || !context.mounted) return;
  await run(
    context,
    () => ref.read(schoolRepoProvider).enregistrerClasse(Classe(
          id: classe?.id ?? '',
          nom: nom.text.trim(),
          niveau: niveau.text.trim(),
          fraisScolarite: double.parse(frais.text),
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
          Text('Matières', style: Theme.of(context).textTheme.titleMedium),
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
                padding: EdgeInsets.all(8), child: Text('Aucune matière pour cette classe.'));
          }
          return Card(
            child: Column(children: [
              for (final m in list)
                ListTile(
                  dense: true,
                  title: Text(m.nom),
                  subtitle: Text('Coefficient ${m.coefficient.toStringAsFixed(0)}'),
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
    final nom = TextEditingController(text: m?.nom);
    final coef = TextEditingController(text: m == null ? '1' : m.coefficient.toStringAsFixed(0));
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(m == null ? 'Nouvelle matière' : 'Modifier la matière'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nom, decoration: const InputDecoration(labelText: 'Matière')),
          const SizedBox(height: 12),
          TextField(
              controller: coef,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Coefficient')),
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
              coefficient: double.tryParse(coef.text) ?? 1,
              enseignantId: m?.enseignantId,
            )));
  }
}
