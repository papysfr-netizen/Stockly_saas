import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../models/eleve.dart';
import '../../models/scolarite.dart';
import '../../providers/providers.dart';
import '../../services/calculs.dart';
import '../../services/pdf_service.dart';
import '../../widgets/common.dart';

const modesPaiement = ['Espèces', 'M-Pesa', 'Airtel Money', 'Orange Money', 'Virement bancaire', 'Autre'];
const motifsPaiement = [
  'Minerval — 1re tranche',
  'Minerval — 2e tranche',
  'Minerval — 3e tranche',
  "Frais d'inscription",
  'Frais connexes',
  "Frais d'examen (ENAFEP, TENASOSP, Exetat)",
  'Uniforme',
  'Fournitures',
  'Transport',
  'Autre',
];

/// Saisit un paiement pour [eleve], l'enregistre et propose d'imprimer le reçu.
Future<void> encaisserPaiement(BuildContext context, WidgetRef ref, Eleve eleve) async {
  final montant = TextEditingController();
  String mode = modesPaiement.first;
  String motif = motifsPaiement.first;
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => StatefulBuilder(
      builder: (c, setState) => AlertDialog(
        title: Text('Paiement — ${eleve.nomComplet}'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: montant,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Montant'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField(
            value: motif,
            decoration: const InputDecoration(labelText: 'Motif'),
            items: [for (final m in motifsPaiement) DropdownMenuItem(value: m, child: Text(m))],
            onChanged: (v) => setState(() => motif = v!),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField(
            value: mode,
            decoration: const InputDecoration(labelText: 'Mode de paiement'),
            items: [for (final m in modesPaiement) DropdownMenuItem(value: m, child: Text(m))],
            onChanged: (v) => setState(() => mode = v!),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Encaisser')),
        ],
      ),
    ),
  );
  final valeur = double.tryParse(montant.text.replaceAll(' ', '').replaceAll(',', '.'));
  if (ok != true || !context.mounted) return;
  if (valeur == null || valeur <= 0) {
    showMessage(context, 'Montant invalide', erreur: true);
    return;
  }

  final repo = ref.read(schoolRepoProvider);
  final me = ref.read(meProvider);
  try {
    final p = await repo.encaisser(Paiement(
      id: '',
      eleveId: eleve.id,
      classeId: eleve.classeId,
      montant: valeur,
      motif: motif,
      mode: mode,
      date: DateTime.now(),
      encaissePar: me.nom,
    ));
    if (!context.mounted) return;
    final ecole = ref.read(ecoleProvider).value!;
    final classes = ref.read(toutesClassesProvider).valueOrNull ?? const [];
    final classe = classes.where((c) => c.id == eleve.classeId).firstOrNull;
    final anciens = ref.read(paiementsProvider(eleve.id)).valueOrNull ?? const [];
    final tous = {for (final x in [...anciens, p]) x.id: x}.values;
    final reste = resteAPayer(classe?.fraisScolarite ?? 0, tous);
    final imprimer = await confirmer(context,
        'Paiement de ${formatMontant(valeur, devise: ecole.devise)} enregistré (reçu ${p.recuNumero}).\nImprimer le reçu ?');
    if (!imprimer) return;
    final bytes = await PdfService.recu(
        ecole: ecole, paiement: p, eleve: eleve, classe: classe, resteAPayer: reste);
    await PdfService.afficher(bytes, 'recu_${p.recuNumero}.pdf');
  } catch (e) {
    if (context.mounted) showMessage(context, 'Erreur : $e', erreur: true);
  }
}

/// Réimprime le reçu d'un paiement existant.
Future<void> imprimerRecu(WidgetRef ref, Eleve eleve, Paiement p) async {
  final ecole = ref.read(ecoleProvider).value!;
  final classes = ref.read(toutesClassesProvider).valueOrNull ?? const [];
  final classe = classes.where((c) => c.id == eleve.classeId).firstOrNull;
  final tous = ref.read(paiementsProvider(eleve.id)).valueOrNull ?? const [];
  final reste = resteAPayer(classe?.fraisScolarite ?? 0, tous);
  final bytes = await PdfService.recu(
      ecole: ecole, paiement: p, eleve: eleve, classe: classe, resteAPayer: reste);
  await PdfService.afficher(bytes, 'recu_${p.recuNumero}.pdf');
}
