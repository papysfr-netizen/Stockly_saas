import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../providers/providers.dart';
import '../../services/calculs.dart';
import '../../widgets/common.dart';
import '../eleves/eleve_detail_screen.dart';

/// Espace parent : la liste de ses enfants, avec accès à leurs notes,
/// absences et paiements.
class ParentScreen extends ConsumerWidget {
  const ParentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(meProvider);
    if (me.eleveIds.isEmpty) {
      return const EmptyState(
        "Aucun enfant n'est encore rattaché à votre compte.\n"
        "Demandez à l'école d'indiquer votre e-mail sur la fiche de votre enfant.",
        icon: Icons.family_restroom,
      );
    }
    return ListView(padding: const EdgeInsets.all(12), children: [
      for (final id in me.eleveIds) _CarteEnfant(eleveId: id),
    ]);
  }
}

class _CarteEnfant extends ConsumerWidget {
  const _CarteEnfant({required this.eleveId});
  final String eleveId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eleve = ref.watch(eleveProvider(eleveId)).valueOrNull;
    if (eleve == null) return const SizedBox.shrink();
    final classes = ref.watch(toutesClassesProvider).valueOrNull ?? const [];
    final classe = classes.where((c) => c.id == eleve.classeId).firstOrNull;
    final paiements = ref.watch(paiementsProvider(eleveId)).valueOrNull ?? const [];
    final absences = ref.watch(absencesEleveProvider(eleveId)).valueOrNull ?? const [];
    final devise = ref.watch(ecoleProvider).valueOrNull?.devise ?? 'FCFA';
    final reste = resteAPayer(classe?.fraisScolarite ?? 0, paiements);

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(radius: 24, child: Text(eleve.prenom.isEmpty ? '?' : eleve.prenom[0])),
        title: Text(eleve.nomComplet, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text('${classe?.nom ?? ''}\n'
            'Reste à payer : ${formatMontant(reste, devise: devise)} · ${absences.length} absence(s)/retard(s)'),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
        onTap: () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => EleveDetailScreen(eleveId: eleveId))),
      ),
    );
  }
}
