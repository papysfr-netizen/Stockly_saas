import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/telephone.dart';
import '../../models/eleve.dart';
import '../../providers/providers.dart';
import '../../services/rappels.dart';
import '../../widgets/common.dart';

/// Ouvre l'application SMS ou WhatsApp du téléphone avec le rappel prérempli.
/// Gratuit et sans configuration : le message part du numéro de l'appareil.
Future<void> relancerDepuisTelephone(
    BuildContext context, WidgetRef ref, Eleve eleve, double reste, CanalRappel canal) async {
  final ecole = ref.read(ecoleProvider).value!;
  final tel = normaliserTelephone(eleve.parentTelephone, indicatif: ecole.indicatif);
  if (tel == null) {
    showMessage(context, "Le numéro du parent de ${eleve.nomComplet} est absent ou invalide.", erreur: true);
    return;
  }
  final classes = ref.read(toutesClassesProvider).valueOrNull ?? const [];
  final message = messageRappel(
    modele: ecole.modeleRappel,
    parent: eleve.parentNom,
    eleve: eleve.nomComplet,
    classe: classes.where((c) => c.id == eleve.classeId).firstOrNull?.nom ?? '',
    montant: reste,
    devise: ecole.devise,
    ecole: ecole.nom,
  );
  final ouvert = await launchUrl(lienRappel(canal, tel, message), mode: LaunchMode.externalApplication);
  if (!context.mounted) return;
  if (!ouvert) {
    showMessage(context, "Impossible d'ouvrir ${canal.label} sur cet appareil.", erreur: true);
    return;
  }
  await ref.read(schoolRepoProvider).noterRappelManuel(
        eleveId: eleve.id,
        canal: canal.name,
        telephone: tel,
        montant: reste,
        par: ref.read(meProvider).nom,
      );
}

/// Envoi automatique via Twilio (Cloud Function) à un ou plusieurs élèves.
Future<void> relancerAutomatiquement(
    BuildContext context, WidgetRef ref, List<String> eleveIds, CanalRappel canal) async {
  if (eleveIds.isEmpty) return;
  final ok = await confirmer(
      context,
      'Envoyer un rappel par ${canal.label} aux parents de ${eleveIds.length} élève(s) ?\n'
      "Les élèves déjà relancés par ${canal.label} il y a moins de 24 h seront ignorés.");
  if (!ok || !context.mounted) return;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const AlertDialog(
      content: Row(children: [CircularProgressIndicator(), SizedBox(width: 16), Text('Envoi en cours…')]),
    ),
  );
  String resume;
  try {
    final r = await ref.read(rappelRepoProvider).envoyer(
          ecoleId: ref.read(meProvider).ecoleId,
          canal: canal,
          eleveIds: eleveIds,
        );
    resume = r.resume;
  } on FirebaseFunctionsException catch (e) {
    resume = e.code == 'not-found'
        ? "L'envoi automatique n'est pas encore activé (Cloud Function non déployée)."
        : 'Erreur : ${e.message ?? e.code}';
  } catch (e) {
    resume = 'Erreur : $e';
  }
  if (!context.mounted) return;
  Navigator.of(context, rootNavigator: true).pop();
  await showDialog(
    context: context,
    builder: (c) => AlertDialog(
      title: Text('Rappels ${canal.label}'),
      content: Text(resume),
      actions: [FilledButton(onPressed: () => Navigator.pop(c), child: const Text('OK'))],
    ),
  );
}

/// Menu des relances pour un élève.
class MenuRelance extends ConsumerWidget {
  const MenuRelance({super.key, required this.eleve, required this.reste});
  final Eleve eleve;
  final double reste;

  @override
  Widget build(BuildContext context, WidgetRef ref) => PopupMenuButton<(CanalRappel, bool)>(
        tooltip: 'Relancer le parent',
        icon: const Icon(Icons.campaign_outlined),
        onSelected: (choix) => choix.$2
            ? relancerAutomatiquement(context, ref, [eleve.id], choix.$1)
            : relancerDepuisTelephone(context, ref, eleve, reste, choix.$1),
        itemBuilder: (_) => const [
          PopupMenuItem(
              value: (CanalRappel.sms, false),
              child: ListTile(leading: Icon(Icons.sms_outlined), title: Text('SMS depuis ce téléphone'))),
          PopupMenuItem(
              value: (CanalRappel.whatsapp, false),
              child: ListTile(leading: Icon(Icons.chat_outlined), title: Text('WhatsApp depuis ce téléphone'))),
          PopupMenuDivider(),
          PopupMenuItem(
              value: (CanalRappel.sms, true),
              child: ListTile(leading: Icon(Icons.send_outlined), title: Text('SMS automatique'))),
          PopupMenuItem(
              value: (CanalRappel.whatsapp, true),
              child: ListTile(leading: Icon(Icons.send_outlined), title: Text('WhatsApp automatique'))),
        ],
      );
}
