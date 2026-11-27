import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../models/classe.dart';
import '../../models/eleve.dart';
import '../../models/scolarite.dart';
import '../../providers/providers.dart';
import '../../services/calculs.dart';
import '../../services/pdf_service.dart';
import '../../widgets/common.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});
  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  String? _classeId;
  int _trimestre = 1;

  @override
  Widget build(BuildContext context) {
    final classes = ref.watch(classesProvider).valueOrNull ?? const <Classe>[];
    final classe = classes.where((c) => c.id == _classeId).firstOrNull;

    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
          SizedBox(
            width: 240,
            child: DropdownButtonFormField<String>(
              value: classe?.id,
              decoration: const InputDecoration(labelText: 'Classe'),
              items: [for (final c in classes) DropdownMenuItem(value: c.id, child: Text(c.nom))],
              onChanged: (v) => setState(() => _classeId = v),
            ),
          ),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 1, label: Text('T1')),
              ButtonSegment(value: 2, label: Text('T2')),
              ButtonSegment(value: 3, label: Text('T3')),
            ],
            selected: {_trimestre},
            onSelectionChanged: (s) => setState(() => _trimestre = s.first),
          ),
        ]),
      ),
      Expanded(
        child: classe == null
            ? const EmptyState('Choisissez une classe.', icon: Icons.class_outlined)
            : DefaultTabController(
                length: 2,
                child: Column(children: [
                  const TabBar(tabs: [Tab(text: 'Saisie des notes'), Tab(text: 'Résultats & bulletins')]),
                  Expanded(
                    child: TabBarView(children: [
                      _SaisieTab(classe: classe, trimestre: _trimestre),
                      _ResultatsTab(classe: classe, trimestre: _trimestre),
                    ]),
                  ),
                ]),
              ),
      ),
    ]);
  }
}

class _SaisieTab extends ConsumerStatefulWidget {
  const _SaisieTab({required this.classe, required this.trimestre});
  final Classe classe;
  final int trimestre;
  @override
  ConsumerState<_SaisieTab> createState() => _SaisieTabState();
}

class _SaisieTabState extends ConsumerState<_SaisieTab> {
  String? _matiereId;
  final _controllers = <String, TextEditingController>{};
  String? _chargePour;
  bool _busy = false;

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// Remplit les champs avec les notes déjà enregistrées (une fois par
  /// combinaison matière / trimestre, pour ne pas écraser la saisie en cours).
  void _charger(List<Eleve> eleves, List<Note> notes) {
    final cle = '$_matiereId|${widget.trimestre}|${widget.classe.id}';
    if (_chargePour == cle) return;
    _chargePour = cle;
    for (final e in eleves) {
      final n = notes.where((n) => n.eleveId == e.id && n.matiereId == _matiereId).firstOrNull;
      (_controllers[e.id] ??= TextEditingController()).text =
          n == null ? '' : n.valeur.toStringAsFixed(n.valeur % 1 == 0 ? 0 : 2);
    }
  }

  Future<void> _enregistrer(List<Eleve> eleves) async {
    final valeurs = <String, double?>{};
    for (final e in eleves) {
      final t = _controllers[e.id]?.text.trim().replaceAll(',', '.') ?? '';
      if (t.isEmpty) {
        valeurs[e.id] = null;
        continue;
      }
      final v = double.tryParse(t);
      if (v == null || v < 0 || v > 20) {
        showMessage(context, 'Note invalide pour ${e.nomComplet} (0 à 20).', erreur: true);
        return;
      }
      valeurs[e.id] = v;
    }
    setState(() => _busy = true);
    await run(
      context,
      () => ref.read(schoolRepoProvider).enregistrerNotes(
            classeId: widget.classe.id,
            matiereId: _matiereId!,
            trimestre: widget.trimestre,
            valeurs: valeurs,
          ),
      succes: 'Notes enregistrées',
    );
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final matieres = ref.watch(matieresProvider(widget.classe.id)).valueOrNull ?? const <Matiere>[];
    final eleves = ref.watch(elevesProvider(widget.classe.id)).valueOrNull;
    final notes = ref.watch(notesClasseProvider((widget.classe.id, widget.trimestre))).valueOrNull;
    if (matieres.isEmpty) {
      return const EmptyState("Aucune matière : la direction doit d'abord les ajouter dans « Classes ».");
    }
    if (!matieres.any((m) => m.id == _matiereId)) _matiereId = null;
    if (eleves == null || notes == null) return const Center(child: CircularProgressIndicator());
    if (_matiereId != null) _charger(eleves, notes);

    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: DropdownButtonFormField<String>(
          value: _matiereId,
          decoration: const InputDecoration(labelText: 'Matière'),
          items: [
            for (final m in matieres)
              DropdownMenuItem(value: m.id, child: Text('${m.nom} (coef. ${m.coefficient.toStringAsFixed(0)})')),
          ],
          onChanged: (v) => setState(() => _matiereId = v),
        ),
      ),
      if (_matiereId == null)
        const Expanded(child: EmptyState('Choisissez une matière.'))
      else
        Expanded(
          child: ListView(padding: const EdgeInsets.symmetric(horizontal: 12), children: [
            for (final e in eleves)
              ListTile(
                title: Text(e.nomComplet),
                subtitle: Text(e.matricule),
                trailing: SizedBox(
                  width: 90,
                  child: TextField(
                    controller: _controllers[e.id],
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(hintText: '/20', isDense: true),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _busy ? null : () => _enregistrer(eleves),
              icon: const Icon(Icons.save),
              label: const Text('Enregistrer les notes'),
            ),
            const SizedBox(height: 24),
          ]),
        ),
    ]);
  }
}

class _ResultatsTab extends ConsumerWidget {
  const _ResultatsTab({required this.classe, required this.trimestre});
  final Classe classe;
  final int trimestre;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matieres = ref.watch(matieresProvider(classe.id)).valueOrNull;
    final eleves = ref.watch(elevesProvider(classe.id)).valueOrNull;
    final notes = ref.watch(notesClasseProvider((classe.id, trimestre))).valueOrNull;
    if (matieres == null || eleves == null || notes == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final resultats = resultatsClasse(
      eleveIds: [for (final e in eleves) e.id],
      matieres: matieres,
      notes: notes,
    );
    final moyennes = resultats.values.map((r) => r.moyenne).whereType<double>().toList();
    final moyenneClasse = moyennes.isEmpty ? null : moyennes.reduce((a, b) => a + b) / moyennes.length;
    final tries = [...eleves]..sort((a, b) =>
        (resultats[a.id]!.rang ?? 9999).compareTo(resultats[b.id]!.rang ?? 9999));

    Future<void> bulletin(Eleve e) async {
      final repo = ref.read(schoolRepoProvider);
      final absences = await repo.absencesEleve(e.id).first;
      final bytes = await PdfService.bulletin(
        ecole: ref.read(ecoleProvider).value!,
        eleve: e,
        classe: classe,
        trimestre: trimestre,
        resultat: resultats[e.id]!,
        effectif: eleves.length,
        moyenneClasse: moyenneClasse,
        absences: absences.length,
      );
      await PdfService.afficher(bytes, 'bulletin_${e.matricule}_T$trimestre.pdf');
    }

    return ListView(padding: const EdgeInsets.all(12), children: [
      Text('Moyenne de la classe : ${formatNote(moyenneClasse)} / 20 · '
          'Admis (≥ 10) : ${moyennes.where((m) => m >= 10).length}/${eleves.length}',
          style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      for (final e in tries)
        Card(
          child: ListTile(
            leading: CircleAvatar(child: Text('${resultats[e.id]!.rang ?? '-'}')),
            title: Text(e.nomComplet),
            subtitle: Text(
                'Moyenne : ${formatNote(resultats[e.id]!.moyenne)} · ${appreciation(resultats[e.id]!.moyenne)}'),
            trailing: IconButton(
              tooltip: 'Bulletin PDF',
              icon: const Icon(Icons.picture_as_pdf_outlined),
              onPressed: () => run(context, () => bulletin(e)),
            ),
          ),
        ),
    ]);
  }
}
