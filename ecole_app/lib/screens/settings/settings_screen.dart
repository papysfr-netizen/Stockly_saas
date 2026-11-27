import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/evaluation.dart';
import '../../core/pays.dart';
import '../../core/telephone.dart';
import '../../models/app_user.dart';
import '../../models/ecole.dart';
import '../../providers/providers.dart';
import '../../services/rappels.dart';
import '../../widgets/common.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(meProvider);
    final ecole = ref.watch(ecoleProvider).valueOrNull;
    return ListView(padding: const EdgeInsets.all(12), children: [
      Card(
        child: ListTile(
          leading: const Icon(Icons.person),
          title: Text(me.nom),
          subtitle: Text('${me.identifiant} · ${me.role.label}'),
          trailing: TextButton.icon(
            icon: const Icon(Icons.logout),
            label: const Text('Déconnexion'),
            onPressed: () => ref.read(authRepoProvider).deconnexion(),
          ),
        ),
      ),
      if (me.isAdmin && ecole != null) ...[
        _EcoleCard(ecole: ecole),
        const _ComptesCard(),
      ],
    ]);
  }
}

class _EcoleCard extends ConsumerStatefulWidget {
  const _EcoleCard({required this.ecole});
  final Ecole ecole;
  @override
  ConsumerState<_EcoleCard> createState() => _EcoleCardState();
}

class _EcoleCardState extends ConsumerState<_EcoleCard> {
  late final _nom = TextEditingController(text: widget.ecole.nom);
  late final _adresse = TextEditingController(text: widget.ecole.adresse);
  late final _tel = TextEditingController(text: widget.ecole.telephone);
  late final _devise = TextEditingController(text: widget.ecole.devise);
  late final _annee = TextEditingController(text: widget.ecole.anneeScolaire);
  late final _modele = TextEditingController(
      text: widget.ecole.modeleRappel.isEmpty ? modeleRappelParDefaut : widget.ecole.modeleRappel);
  late String _indicatif = widget.ecole.indicatif;
  late SystemeEvaluation _systeme = widget.ecole.systeme;

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 12);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text("Informations de l'école", style: Theme.of(context).textTheme.titleMedium),
          const Text('Elles apparaissent sur les reçus et les bulletins.'),
          gap,
          TextField(controller: _nom, decoration: const InputDecoration(labelText: 'Nom')),
          gap,
          TextField(controller: _adresse, decoration: const InputDecoration(labelText: 'Adresse')),
          gap,
          TextField(controller: _tel, decoration: const InputDecoration(labelText: 'Téléphone')),
          gap,
          Row(children: [
            Expanded(child: TextField(controller: _devise, decoration: const InputDecoration(labelText: 'Devise'))),
            const SizedBox(width: 12),
            Expanded(
                child: TextField(controller: _annee, decoration: const InputDecoration(labelText: 'Année scolaire'))),
          ]),
          gap,
          DropdownButtonFormField<String>(
            value: indicatifsPays.any((p) => p.$1 == _indicatif) ? _indicatif : null,
            isExpanded: true,
            decoration: const InputDecoration(
                labelText: 'Pays (indicatif téléphonique)',
                helperText: 'Utilisé pour les numéros saisis sans indicatif'),
            items: [for (final p in indicatifsPays) DropdownMenuItem(value: p.$1, child: Text('${p.$2} (${p.$1})'))],
            onChanged: (v) => setState(() => _indicatif = v!),
          ),
          gap,
          DropdownButtonFormField<SystemeEvaluation>(
            value: _systeme,
            isExpanded: true,
            decoration: const InputDecoration(labelText: "Système d'évaluation"),
            items: [
              for (final s in SystemeEvaluation.values) DropdownMenuItem(value: s, child: Text(s.label)),
            ],
            onChanged: (v) => setState(() => _systeme = v!),
          ),
          const SizedBox(height: 24),
          Text("Message de rappel d'impayé", style: Theme.of(context).textTheme.titleSmall),
          gap,
          TextField(
            controller: _modele,
            maxLines: 4,
            decoration: const InputDecoration(
              helperText: 'Variables : {parent} {eleve} {classe} {montant} {ecole}',
              helperMaxLines: 2,
            ),
          ),
          gap,
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: () => run(
                context,
                () => ref.read(schoolRepoProvider).majEcole(widget.ecole.copyWith(
                      nom: _nom.text.trim(),
                      adresse: _adresse.text.trim(),
                      telephone: _tel.text.trim(),
                      devise: _devise.text.trim(),
                      anneeScolaire: _annee.text.trim(),
                      indicatif: _indicatif,
                      systeme: _systeme,
                      modeleRappel: _modele.text.trim() == modeleRappelParDefaut ? '' : _modele.text.trim(),
                    )),
                succes: 'Enregistré',
              ),
              child: const Text('Enregistrer'),
            ),
          ),
        ]),
      ),
    );
  }
}

class _ComptesCard extends ConsumerWidget {
  const _ComptesCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(schoolRepoProvider);
    final users = ref.watch(_usersProvider).valueOrNull ?? const <AppUser>[];
    final invitations = ref.watch(_invitationsProvider).valueOrNull ?? const <Invitation>[];
    return Card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        ListTile(
          title: const Text('Comptes utilisateurs'),
          subtitle: const Text('Enseignants et parents sont invités depuis leurs fiches.'),
          trailing: FilledButton.tonalIcon(
            icon: const Icon(Icons.person_add),
            label: const Text('Inviter'),
            onPressed: () => _inviter(context, ref),
          ),
        ),
        for (final u in users)
          ListTile(dense: true, leading: const Icon(Icons.verified_user_outlined), title: Text(u.nom),
              subtitle: Text('${u.identifiant} · ${u.role.label}')),
        if (invitations.isNotEmpty) const ListTile(dense: true, title: Text('Invitations en attente')),
        for (final i in invitations)
          ListTile(
            dense: true,
            leading: Icon(i.parTelephone ? Icons.phone_outlined : Icons.mail_outline),
            title: Text(i.identifiant),
            subtitle: Text(i.role.label),
            trailing: IconButton(
              icon: const Icon(Icons.close),
              tooltip: "Annuler l'invitation",
              onPressed: () => run(context, () => repo.annulerInvitation(i.identifiant)),
            ),
          ),
      ]),
    );
  }

  Future<void> _inviter(BuildContext context, WidgetRef ref) async {
    final identifiant = TextEditingController();
    final nom = TextEditingController();
    var role = Role.secretariat;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setState) => AlertDialog(
          title: const Text('Inviter un membre du personnel'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nom, decoration: const InputDecoration(labelText: 'Nom')),
            const SizedBox(height: 12),
            TextField(
                controller: identifiant,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'E-mail ou numéro de téléphone')),
            const SizedBox(height: 12),
            DropdownButtonFormField<Role>(
              value: role,
              decoration: const InputDecoration(labelText: 'Rôle'),
              items: const [
                DropdownMenuItem(value: Role.secretariat, child: Text('Secrétariat / comptable')),
                DropdownMenuItem(value: Role.admin, child: Text('Direction')),
              ],
              onChanged: (v) => setState(() => role = v!),
            ),
            const SizedBox(height: 12),
            const Text("La personne se connecte ensuite avec cet e-mail (mot de passe) ou ce numéro (code SMS)."),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Annuler')),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Inviter')),
          ],
        ),
      ),
    );
    if (ok != true || identifiant.text.trim().isEmpty || !context.mounted) return;
    final saisie = identifiant.text.trim();
    final id = saisie.contains('@')
        ? saisie.toLowerCase()
        : normaliserTelephone(saisie, indicatif: ref.read(ecoleProvider).valueOrNull?.indicatif ?? '+243');
    if (id == null) {
      showMessage(context, 'E-mail ou numéro invalide.', erreur: true);
      return;
    }
    await run(
      context,
      () => ref.read(schoolRepoProvider).inviter(Invitation(
            identifiant: id,
            nom: nom.text.trim(),
            role: role,
            ecoleId: ref.read(meProvider).ecoleId,
          )),
      succes: 'Invitation créée',
    );
  }
}

final _usersProvider = StreamProvider.autoDispose((ref) => ref.watch(schoolRepoProvider).utilisateurs());
final _invitationsProvider = StreamProvider.autoDispose((ref) => ref.watch(schoolRepoProvider).invitations());
