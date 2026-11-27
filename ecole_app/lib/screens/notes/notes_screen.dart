import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/evaluation.dart';
import '../../models/classe.dart';
import '../../models/eleve.dart';
import '../../models/scolarite.dart';
import '../../providers/providers.dart';
import '../../services/calculs.dart';
import '../../services/excel_export.dart';
import '../../services/fichier.dart';
import '../../services/pdf_service.dart';
import '../../widgets/common.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});
  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  String? _classeId;

  @override
  Widget build(BuildContext context) {
    final classes = ref.watch(classesProvider).valueOrNull ?? const <Classe>[];
    final classe = classes.where((c) => c.id == _classeId).firstOrNull;

    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: DropdownButtonFormField<String>(
          value: classe?.id,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Classe'),
          items: [
            for (final c in classes)
              DropdownMenuItem(value: c.id, child: Text([c.nom, if (c.section.isNotEmpty) c.section].join(' · '))),
          ],
          onChanged: (v) => setState(() => _classeId = v),
        ),
      ),
      Expanded(
        child: classe == null
            ? const EmptyState('Choisissez une classe.', icon: Icons.class_outlined)
            : DefaultTabController(
                key: ValueKey(classe.id),
                length: 2,
                child: Column(children: [
                  const TabBar(tabs: [Tab(text: 'Saisie'), Tab(text: 'Résultats & bulletins')]),
                  Expanded(
                    child: TabBarView(children: [
                      _SaisieTab(classe: classe),
                      _ResultatsTab(classe: classe),
                    ]),
                  ),
                ]),
              ),
      ),
    ]);
  }
}

const _comportement = '__comportement';

class _SaisieTab extends ConsumerStatefulWidget {
  const _SaisieTab({required this.classe});
  final Classe classe;
  @override
  ConsumerState<_SaisieTab> createState() => _SaisieTabState();
}

class _SaisieTabState extends ConsumerState<_SaisieTab> {
  String? _periode;
  String? _matiereId;
  final _points = <String, TextEditingController>{};
  final _cotes = <String, String?>{};
  final _comport = <String, ({String application, String conduite})>{};
  String? _chargePour;
  bool _busy = false;

  @override
  void dispose() {
    for (final c in _points.values) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _maternelle => widget.classe.cycle == Cycle.maternelle;

  /// Remplit les champs avec ce qui est déjà enregistré (une fois par
  /// combinaison période / branche, pour ne pas écraser la saisie en cours).
  void _charger(List<Eleve> eleves, Evaluations ev, List<Comportement> comps) {
    final cle = '$_periode|$_matiereId';
    if (_chargePour == cle) return;
    _chargePour = cle;
    for (final e in eleves) {
      if (_matiereId == _comportement) {
        final c = comps.where((c) => c.eleveId == e.id && c.periode == _periode).firstOrNull;
        _comport[e.id] = (application: c?.application ?? '', conduite: c?.conduite ?? '');
      } else {
        final n = ev.de(e.id, _matiereId!, _periode!);
        _cotes[e.id] = n?.cote;
        (_points[e.id] ??= TextEditingController()).text = formatPoints(n?.valeur);
      }
    }
  }

  Future<void> _enregistrer(List<Eleve> eleves, double max) async {
    final repo = ref.read(schoolRepoProvider);
    Future<void> Function() action;
    if (_matiereId == _comportement) {
      action = () => repo.enregistrerComportements(
          classeId: widget.classe.id,
          periode: _periode!,
          valeurs: {for (final e in eleves) if (_comport[e.id] != null) e.id: _comport[e.id]!});
    } else if (_maternelle) {
      action = () => repo.enregistrerCotes(
          classeId: widget.classe.id,
          matiereId: _matiereId!,
          periode: _periode!,
          cotes: {for (final e in eleves) e.id: _cotes[e.id]});
    } else {
      final valeurs = <String, double?>{};
      for (final e in eleves) {
        final t = _points[e.id]?.text.trim().replaceAll(',', '.') ?? '';
        if (t.isEmpty) {
          valeurs[e.id] = null;
          continue;
        }
        final v = double.tryParse(t);
        if (v == null || v < 0 || v > max) {
          showMessage(context, 'Note invalide pour ${e.nomComplet} (0 à ${formatPoints(max)}).', erreur: true);
          return;
        }
        valeurs[e.id] = v;
      }
      action = () => repo.enregistrerNotes(
          classeId: widget.classe.id, matiereId: _matiereId!, periode: _periode!, sur: max, valeurs: valeurs);
    }
    setState(() => _busy = true);
    await run(context, action, succes: 'Enregistré');
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final systeme = ref.watch(systemeProvider);
    final periodes = periodesPour(systeme, widget.classe.cycle);
    final matieres = ref.watch(matieresProvider(widget.classe.id)).valueOrNull ?? const <Matiere>[];
    final eleves = ref.watch(elevesProvider(widget.classe.id)).valueOrNull;
    final notes = ref.watch(notesClasseProvider(widget.classe.id)).valueOrNull;
    final comps = ref.watch(comportementsClasseProvider(widget.classe.id)).valueOrNull;
    if (matieres.isEmpty) {
      return const EmptyState("Aucune branche : la direction doit d'abord les ajouter dans « Classes ».");
    }
    if (eleves == null || notes == null || comps == null) return const Center(child: CircularProgressIndicator());

    final periode = periodes.where((p) => p.code == _periode).firstOrNull;
    if (periode == null) _periode = null;
    if (_matiereId != _comportement && !matieres.any((m) => m.id == _matiereId)) _matiereId = null;
    if (_matiereId == _comportement && (periode?.examen ?? false)) _matiereId = null;
    final matiere = matieres.where((m) => m.id == _matiereId).firstOrNull;
    final max = systeme == SystemeEvaluation.rdc && matiere != null && periode != null ? matiere.maximaPour(periode) : 20.0;
    if (_periode != null && _matiereId != null) _charger(eleves, Evaluations(notes), comps);

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
        child: Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(
            width: 260,
            child: DropdownButtonFormField<String>(
              value: _periode,
              decoration: const InputDecoration(labelText: 'Période'),
              items: [for (final p in periodes) DropdownMenuItem(value: p.code, child: Text(p.label))],
              onChanged: (v) => setState(() => _periode = v),
            ),
          ),
          SizedBox(
            width: 300,
            child: DropdownButtonFormField<String>(
              value: _matiereId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Branche'),
              items: [
                for (final m in matieres)
                  DropdownMenuItem(
                    value: m.id,
                    child: Text(systeme == SystemeEvaluation.rdc && !_maternelle
                        ? '${m.nom} (max. ${formatPoints(m.maxima)})'
                        : systeme == SystemeEvaluation.trimestres
                            ? '${m.nom} (coef. ${formatPoints(m.coefficient)})'
                            : m.nom),
                  ),
                if (!(periode?.examen ?? false))
                  const DropdownMenuItem(value: _comportement, child: Text('Application & conduite')),
              ],
              onChanged: (v) => setState(() => _matiereId = v),
            ),
          ),
        ]),
      ),
      if (_periode == null || _matiereId == null)
        const Expanded(child: EmptyState('Choisissez une période et une branche.'))
      else
        Expanded(
          child: ListView(padding: const EdgeInsets.all(12), children: [
            if (_matiereId != _comportement && !_maternelle)
              Text('Points sur ${formatPoints(max)}${periode!.examen ? ' (examen : double du maxima)' : ''}',
                  style: Theme.of(context).textTheme.titleSmall),
            for (final e in eleves) _ligne(e, max),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _busy ? null : () => _enregistrer(eleves, max),
              icon: const Icon(Icons.save),
              label: const Text('Enregistrer'),
            ),
            const SizedBox(height: 24),
          ]),
        ),
    ]);
  }

  Widget _ligne(Eleve e, double max) {
    if (_matiereId == _comportement) {
      final v = _comport[e.id] ?? (application: '', conduite: '');
      Widget choix(String label, String valeur, void Function(String) maj) => SizedBox(
            width: 150,
            child: DropdownButtonFormField<String>(
              value: valeur.isEmpty ? null : valeur,
              isDense: true,
              decoration: InputDecoration(labelText: label, isDense: true),
              items: [for (final x in echelleComportement) DropdownMenuItem(value: x, child: Text(x))],
              onChanged: (x) => setState(() => maj(x!)),
            ),
          );
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(spacing: 12, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
            SizedBox(width: 200, child: Text(e.nomComplet)),
            choix('Application', v.application, (x) => _comport[e.id] = (application: x, conduite: v.conduite)),
            choix('Conduite', v.conduite, (x) => _comport[e.id] = (application: v.application, conduite: x)),
          ]),
        ),
      );
    }
    if (_maternelle) {
      return ListTile(
        title: Text(e.nomComplet),
        trailing: SegmentedButton<String>(
          emptySelectionAllowed: true,
          showSelectedIcon: false,
          segments: [for (final c in cotesMaternelle) ButtonSegment(value: c.$1, label: Text(c.$1), tooltip: c.$2)],
          selected: {if (_cotes[e.id] != null) _cotes[e.id]!},
          onSelectionChanged: (s) => setState(() => _cotes[e.id] = s.firstOrNull),
        ),
      );
    }
    return ListTile(
      title: Text(e.nomComplet),
      subtitle: Text(e.matricule),
      trailing: SizedBox(
        width: 90,
        child: TextField(
          controller: _points[e.id],
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.center,
          decoration: InputDecoration(hintText: '/ ${formatPoints(max)}', isDense: true),
        ),
      ),
    );
  }
}

class _ResultatsTab extends ConsumerStatefulWidget {
  const _ResultatsTab({required this.classe});
  final Classe classe;
  @override
  ConsumerState<_ResultatsTab> createState() => _ResultatsTabState();
}

class _ResultatsTabState extends ConsumerState<_ResultatsTab> {
  int _vue = -1; // -1 = dernière (année)

  @override
  Widget build(BuildContext context) {
    final classe = widget.classe;
    final systeme = ref.watch(systemeProvider);
    final matieres = ref.watch(matieresProvider(classe.id)).valueOrNull;
    final eleves = ref.watch(elevesProvider(classe.id)).valueOrNull;
    final notes = ref.watch(notesClasseProvider(classe.id)).valueOrNull;
    final comps = ref.watch(comportementsClasseProvider(classe.id)).valueOrNull;
    if (matieres == null || eleves == null || notes == null || comps == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final ev = Evaluations(notes);
    final maternelle = classe.cycle == Cycle.maternelle;
    final vues = vuesPour(systeme, classe.cycle);
    final vue = vues[_vue < 0 || _vue >= vues.length ? vues.length - 1 : _vue];
    final res = resultatsClasse(
        systeme: systeme, eleveIds: [for (final e in eleves) e.id], matieres: matieres, codes: vue.codes, ev: ev);
    final tries = [...eleves]..sort((a, b) => (res.rangs[a.id] ?? 9999).compareTo(res.rangs[b.id] ?? 9999));

    Future<void> bulletin(Eleve e) async {
      final absences = await ref.read(schoolRepoProvider).absencesEleve(e.id).first;
      final bytes = await PdfService.bulletin(
        ecole: ref.read(ecoleProvider).value!,
        eleve: e,
        classe: classe,
        matieres: matieres,
        eleveIds: [for (final x in eleves) x.id],
        ev: ev,
        comportements: comps.where((c) => c.eleveId == e.id).toList(),
        absences: absences.length,
      );
      await PdfService.afficher(bytes, 'bulletin_${e.matricule}.pdf');
    }

    Future<void> exporter() async {
      final ecole = ref.read(ecoleProvider).value!;
      final octets = exporterNotes(
          ecole: ecole, classe: classe, matieres: matieres, eleves: eleves, ev: ev, comportements: comps);
      await remettreFichier(octets, nomFichier('notes_${classe.nom}_${ecole.anneeScolaire}.xlsx'), mimeExcel);
    }

    return ListView(padding: const EdgeInsets.all(12), children: [
      Align(
        alignment: Alignment.centerRight,
        child: FilledButton.tonalIcon(
          onPressed: eleves.isEmpty ? null : () => run(context, exporter),
          icon: const Icon(Icons.table_view_outlined),
          label: Text(maternelle ? 'Exporter les cotes (Excel)' : 'Exporter le palmarès et les notes (Excel)'),
        ),
      ),
      const SizedBox(height: 8),
      if (!maternelle) ...[
        DropdownButtonFormField<int>(
          value: vues.indexOf(vue),
          decoration: const InputDecoration(labelText: 'Résultats de'),
          items: [for (var i = 0; i < vues.length; i++) DropdownMenuItem(value: i, child: Text(vues[i].label))],
          onChanged: (v) => setState(() => _vue = v!),
        ),
        const SizedBox(height: 8),
        Text(
          'Moyenne de la classe : ${formatScore(systeme, res.moyenne)} · '
          'Réussite : ${res.scores.values.whereType<double>().where((s) => s >= seuilReussite(systeme)).length}/${eleves.length}',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
      ],
      for (final e in tries)
        Card(
          child: ListTile(
            leading: maternelle ? null : CircleAvatar(child: Text('${res.rangs[e.id] ?? '-'}')),
            title: Text(e.nomComplet),
            subtitle: maternelle ? null : Text(formatScore(systeme, res.scores[e.id])),
            trailing: IconButton(
              tooltip: 'Bulletin PDF',
              icon: const Icon(Icons.picture_as_pdf_outlined),
              onPressed: () => run(context, () => bulletin(e)),
            ),
          ),
        ),
      if (eleves.isEmpty) const EmptyState('Aucun élève dans cette classe.'),
    ]);
  }
}
