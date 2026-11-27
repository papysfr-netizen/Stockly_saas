import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import '../../widgets/common.dart';
import 'eleve_detail_screen.dart';
import 'eleve_form_screen.dart';

class ElevesScreen extends ConsumerStatefulWidget {
  const ElevesScreen({super.key});
  @override
  ConsumerState<ElevesScreen> createState() => _ElevesScreenState();
}

class _ElevesScreenState extends ConsumerState<ElevesScreen> {
  String? _classeId;
  String _recherche = '';

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(meProvider);
    final classes = ref.watch(classesProvider).valueOrNull ?? const [];
    final nomsClasses = {for (final c in classes) c.id: c.nom};
    final eleves = ref.watch(elevesProvider(_classeId));

    return Scaffold(
      floatingActionButton: me.canManageEleves
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const EleveFormScreen())),
              icon: const Icon(Icons.person_add),
              label: const Text('Inscrire'),
            )
          : null,
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Wrap(spacing: 12, runSpacing: 12, children: [
            SizedBox(
              width: 320,
              child: TextField(
                decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search), hintText: 'Nom, prénom ou matricule'),
                onChanged: (v) => setState(() => _recherche = v.trim().toLowerCase()),
              ),
            ),
            SizedBox(
              width: 220,
              child: DropdownButtonFormField<String?>(
                value: _classeId,
                decoration: const InputDecoration(labelText: 'Classe'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Toutes')),
                  for (final c in classes) DropdownMenuItem(value: c.id, child: Text(c.nom)),
                ],
                onChanged: (v) => setState(() => _classeId = v),
              ),
            ),
          ]),
        ),
        Expanded(
          child: AsyncView(eleves, (list) {
            final filtres = list
                // Un enseignant ne voit que les élèves de ses classes.
                .where((e) => me.peutAccederClasse(e.classeId))
                .where((e) =>
                    _recherche.isEmpty ||
                    e.nomComplet.toLowerCase().contains(_recherche) ||
                    e.matricule.toLowerCase().contains(_recherche))
                .toList();
            if (filtres.isEmpty) return const EmptyState('Aucun élève trouvé.', icon: Icons.groups);
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: filtres.length,
              itemBuilder: (_, i) {
                final e = filtres[i];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text(e.nom.isEmpty ? '?' : e.nom[0])),
                    title: Text(e.nomComplet),
                    subtitle: Text('${e.matricule} · ${nomsClasses[e.classeId] ?? 'Sans classe'}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => EleveDetailScreen(eleveId: e.id))),
                  ),
                );
              },
            );
          }),
        ),
      ]),
    );
  }
}
