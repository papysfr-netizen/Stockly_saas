import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../models/eleve.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';

class EleveFormScreen extends ConsumerStatefulWidget {
  const EleveFormScreen({super.key, this.eleve});
  final Eleve? eleve;
  @override
  ConsumerState<EleveFormScreen> createState() => _EleveFormScreenState();
}

class _EleveFormScreenState extends ConsumerState<EleveFormScreen> {
  final _form = GlobalKey<FormState>();
  late final _nom = TextEditingController(text: widget.eleve?.nom);
  late final _prenom = TextEditingController(text: widget.eleve?.prenom);
  late final _matricule = TextEditingController(text: widget.eleve?.matricule);
  late final _parentNom = TextEditingController(text: widget.eleve?.parentNom);
  late final _parentTel = TextEditingController(text: widget.eleve?.parentTelephone);
  late final _parentEmail = TextEditingController(text: widget.eleve?.parentEmail);
  late String? _classeId = widget.eleve?.classeId;
  late String _sexe = widget.eleve?.sexe ?? 'M';
  late DateTime? _naissance = widget.eleve?.dateNaissance;
  bool _busy = false;

  Future<void> _enregistrer() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final repo = ref.read(schoolRepoProvider);
    final e = Eleve(
      id: widget.eleve?.id ?? '',
      matricule: _matricule.text.trim(),
      nom: _nom.text.trim().toUpperCase(),
      prenom: _prenom.text.trim(),
      classeId: _classeId!,
      dateNaissance: _naissance,
      sexe: _sexe,
      parentNom: _parentNom.text.trim(),
      parentTelephone: _parentTel.text.trim(),
      parentEmail: _parentEmail.text.trim(),
      dateInscription: widget.eleve?.dateInscription,
    );
    final ok = await run(context, () async {
      final id = await repo.enregistrerEleve(e);
      if (e.parentEmail.isNotEmpty && e.parentEmail != widget.eleve?.parentEmail) {
        await repo.lierParent(email: e.parentEmail, nom: e.parentNom, eleveId: id);
      }
    }, succes: widget.eleve == null ? 'Élève inscrit' : 'Fiche mise à jour');
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final classes = ref.watch(toutesClassesProvider).valueOrNull ?? const [];
    const gap = SizedBox(height: 12);
    return Scaffold(
      appBar: AppBar(title: Text(widget.eleve == null ? 'Inscription' : 'Modifier l\'élève')),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Text('Élève', style: Theme.of(context).textTheme.titleMedium),
          gap,
          TextFormField(controller: _nom, decoration: const InputDecoration(labelText: 'Nom'), validator: requis),
          gap,
          TextFormField(
              controller: _prenom, decoration: const InputDecoration(labelText: 'Prénom(s)'), validator: requis),
          gap,
          TextFormField(
              controller: _matricule,
              decoration: const InputDecoration(
                  labelText: 'Matricule', helperText: 'Laisser vide pour une numérotation automatique')),
          gap,
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'M', label: Text('Garçon')),
              ButtonSegment(value: 'F', label: Text('Fille')),
            ],
            selected: {_sexe},
            onSelectionChanged: (s) => setState(() => _sexe = s.first),
          ),
          gap,
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.cake_outlined),
            title: const Text('Date de naissance'),
            subtitle: Text(formatDate(_naissance)),
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                firstDate: DateTime(1990),
                lastDate: DateTime.now(),
                initialDate: _naissance ?? DateTime(DateTime.now().year - 8),
              );
              if (d != null) setState(() => _naissance = d);
            },
          ),
          DropdownButtonFormField<String>(
            value: classes.any((c) => c.id == _classeId) ? _classeId : null,
            decoration: const InputDecoration(labelText: 'Classe'),
            items: [for (final c in classes) DropdownMenuItem(value: c.id, child: Text(c.nom))],
            onChanged: (v) => setState(() => _classeId = v),
            validator: (v) => v == null ? 'Choisissez une classe' : null,
          ),
          const SizedBox(height: 24),
          Text('Parent / tuteur', style: Theme.of(context).textTheme.titleMedium),
          gap,
          TextFormField(controller: _parentNom, decoration: const InputDecoration(labelText: 'Nom du parent')),
          gap,
          TextFormField(
              controller: _parentTel,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Téléphone')),
          gap,
          TextFormField(
            controller: _parentEmail,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
                labelText: 'E-mail du parent',
                helperText: "Le parent pourra créer son compte avec cet e-mail pour suivre l'élève"),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _busy ? null : _enregistrer,
            icon: const Icon(Icons.save),
            label: const Text('Enregistrer'),
          ),
        ]),
      ),
    );
  }
}
