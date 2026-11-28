import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../providers/providers.dart';
import '../../services/fichier.dart';
import '../../services/import_excel.dart';
import '../../widgets/common.dart';

/// Import des classes, branches, enseignants et élèves depuis Excel.
class ImportCard extends ConsumerStatefulWidget {
  const ImportCard({super.key});
  @override
  ConsumerState<ImportCard> createState() => _ImportCardState();
}

class _ImportCardState extends ConsumerState<ImportCard> {
  bool _busy = false;

  Future<void> _importer() async {
    final choix = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['xlsx'],
      withData: true,
    );
    final octets = choix?.files.single.bytes;
    if (octets == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final repo = ref.read(schoolRepoProvider);
      final ecole = await ref.read(ecoleProvider.future);
      final plan = analyserImport(
        octets,
        classesExistantes: await ref.read(toutesClassesProvider.future),
        branchesExistantes: await repo.toutesMatieres(),
        enseignantsExistants: await ref.read(enseignantsProvider.future),
        elevesExistants: await ref.read(elevesProvider(null).future),
        indicatif: ecole.indicatif,
      );
      if (!mounted) return;
      setState(() => _busy = false);
      if (await _apercu(plan) != true || !mounted) return;

      final etape = ValueNotifier('Préparation…');
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          content: Row(children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(child: ValueListenableBuilder(valueListenable: etape, builder: (_, v, __) => Text(v))),
          ]),
        ),
      );
      try {
        final r = await repo.appliquerImport(plan, progression: (e) => etape.value = e);
        if (!mounted) return;
        Navigator.of(context, rootNavigator: true).pop();
        await showDialog(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('Import terminé'),
            content: Text([
              '${r.classes} classe(s), ${r.branches} branche(s)',
              '${r.enseignants} enseignant(s)',
              '${r.eleves} élève(s)',
              '${r.parents} parent(s) invité(s) : ils se connectent avec leur numéro ou leur e-mail.',
            ].join('\n')),
            actions: [FilledButton(onPressed: () => Navigator.pop(c), child: const Text('OK'))],
          ),
        );
      } catch (e) {
        if (!mounted) return;
        Navigator.of(context, rootNavigator: true).pop();
        showMessage(context, "Erreur pendant l'import : $e", erreur: true);
      }
    } catch (e) {
      if (mounted) showMessage(context, 'Erreur : $e', erreur: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool?> _apercu(PlanImport plan) => showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(plan.erreurs.isNotEmpty
              ? 'Fichier à corriger'
              : plan.vide
                  ? 'Rien à importer'
                  : "Vérifier l'import"),
          content: SizedBox(
            width: 460,
            child: ListView(shrinkWrap: true, children: [
              if (!plan.vide) ...[
                Text(plan.erreurs.isEmpty ? 'Sera créé :' : 'Lu dans le fichier :',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('• ${plan.classes.length} classe(s)\n'
                    '• ${plan.branches.length} branche(s)\n'
                    '• ${plan.enseignants.length} enseignant(s)\n'
                    '• ${plan.eleves.length} élève(s)'),
              ],
              if (plan.vide && plan.erreurs.isEmpty) const Text('Le fichier ne contient aucune ligne remplie.'),
              if (plan.erreurs.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('${plan.erreurs.length} erreur(s) à corriger dans le fichier :',
                    style: TextStyle(fontWeight: FontWeight.bold, color: context.etat.danger)),
                for (final e in plan.erreurs.take(30)) Text('• $e'),
                if (plan.erreurs.length > 30) Text('… et ${plan.erreurs.length - 30} autre(s).'),
                const SizedBox(height: 4),
                const Text("Rien n'a été importé. Corrigez ces lignes puis importez à nouveau."),
              ],
              if (plan.avertissements.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('${plan.avertissements.length} ligne(s) ignorée(s) :',
                    style: TextStyle(fontWeight: FontWeight.bold, color: context.etat.attention)),
                for (final a in plan.avertissements.take(20)) Text('• $a'),
                if (plan.avertissements.length > 20) Text('… et ${plan.avertissements.length - 20} autre(s).'),
              ],
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: Text(plan.importable ? 'Annuler' : 'Fermer')),
            if (plan.importable) FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Importer')),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Importer depuis Excel', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            const Text('Classes, branches, enseignants et élèves en une fois. '
                'Téléchargez le modèle, remplissez-le, puis importez-le. Le fichier est vérifié avant tout enregistrement.'),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.download_outlined),
                label: const Text('Télécharger le modèle'),
                onPressed: () =>
                    run(context, () => remettreFichier(modeleImport(), 'modele_import_ecole.xlsx', mimeExcel)),
              ),
              FilledButton.icon(
                icon: _busy
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.upload_file),
                label: const Text('Importer un fichier'),
                onPressed: _busy ? null : _importer,
              ),
            ]),
          ]),
        ),
      );
}
