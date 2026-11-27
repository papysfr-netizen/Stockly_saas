import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/classe.dart';
import '../../models/scolarite.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';

class EnseignantsScreen extends ConsumerWidget {
  const EnseignantsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classes = ref.watch(toutesClassesProvider).valueOrNull ?? const <Classe>[];
    final noms = {for (final c in classes) c.id: c.nom};
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editer(context, ref, classes),
        icon: const Icon(Icons.person_add),
        label: const Text('Ajouter'),
      ),
      body: AsyncView(ref.watch(enseignantsProvider), (List<Enseignant> list) {
        if (list.isEmpty) return const EmptyState('Aucun enseignant.', icon: Icons.co_present_outlined);
        return ListView(padding: const EdgeInsets.all(12), children: [
          for (final e in list)
            Card(
              child: ListTile(
                leading: CircleAvatar(child: Text(e.prenom.isEmpty ? '?' : e.prenom[0])),
                title: Text(e.nomComplet),
                subtitle: Text([
                  if (e.specialite.isNotEmpty) e.specialite,
                  if (e.telephone.isNotEmpty) e.telephone,
                  if (e.classeIds.isNotEmpty) e.classeIds.map((id) => noms[id] ?? '?').join(', '),
                ].join(' · ')),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    if (await confirmer(context, 'Supprimer ${e.nomComplet} ?') && context.mounted) {
                      await run(context, () => ref.read(schoolRepoProvider).supprimerEnseignant(e.id));
                    }
                  },
                ),
                onTap: () => _editer(context, ref, classes, e),
              ),
            ),
        ]);
      }),
    );
  }

  Future<void> _editer(BuildContext context, WidgetRef ref, List<Classe> classes, [Enseignant? e]) async {
    final form = GlobalKey<FormState>();
    final nom = TextEditingController(text: e?.nom);
    final prenom = TextEditingController(text: e?.prenom);
    final tel = TextEditingController(text: e?.telephone);
    final email = TextEditingController(text: e?.email);
    final spec = TextEditingController(text: e?.specialite);
    final choix = {...?e?.classeIds};
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setState) => AlertDialog(
          title: Text(e == null ? 'Nouvel enseignant' : 'Modifier'),
          content: SizedBox(
            width: 420,
            child: Form(
              key: form,
              child: ListView(shrinkWrap: true, children: [
                TextFormField(controller: nom, decoration: const InputDecoration(labelText: 'Nom'), validator: requis),
                const SizedBox(height: 12),
                TextFormField(
                    controller: prenom, decoration: const InputDecoration(labelText: 'Prénom'), validator: requis),
                const SizedBox(height: 12),
                TextFormField(controller: spec, decoration: const InputDecoration(labelText: 'Spécialité')),
                const SizedBox(height: 12),
                TextFormField(
                    controller: tel,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Téléphone')),
                const SizedBox(height: 12),
                TextFormField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                      labelText: 'E-mail',
                      helperText: "Permet à l'enseignant de créer son compte (notes, appel)"),
                ),
                const SizedBox(height: 16),
                const Text('Classes confiées'),
                Wrap(spacing: 8, children: [
                  for (final cl in classes)
                    FilterChip(
                      label: Text(cl.nom),
                      selected: choix.contains(cl.id),
                      onSelected: (v) => setState(() => v ? choix.add(cl.id) : choix.remove(cl.id)),
                    ),
                ]),
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
      () => ref.read(schoolRepoProvider).enregistrerEnseignant(Enseignant(
            id: e?.id ?? '',
            nom: nom.text.trim().toUpperCase(),
            prenom: prenom.text.trim(),
            telephone: tel.text.trim(),
            email: email.text.trim(),
            specialite: spec.text.trim(),
            classeIds: choix.toList(),
          )),
      succes: 'Enseignant enregistré',
    );
  }
}
