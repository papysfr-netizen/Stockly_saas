import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_user.dart';
import '../../models/ecole.dart';
import '../../providers/providers.dart';
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
          subtitle: Text('${me.email} · ${me.role.label}'),
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
              subtitle: Text('${u.email} · ${u.role.label}')),
        if (invitations.isNotEmpty) const ListTile(dense: true, title: Text('Invitations en attente')),
        for (final i in invitations)
          ListTile(
            dense: true,
            leading: const Icon(Icons.mail_outline),
            title: Text(i.email),
            subtitle: Text(i.role.label),
            trailing: IconButton(
              icon: const Icon(Icons.close),
              tooltip: "Annuler l'invitation",
              onPressed: () => run(context, () => repo.annulerInvitation(i.email)),
            ),
          ),
      ]),
    );
  }

  Future<void> _inviter(BuildContext context, WidgetRef ref) async {
    final email = TextEditingController();
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
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'E-mail')),
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
            const Text("La personne crée ensuite son compte dans l'application avec cet e-mail."),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Annuler')),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Inviter')),
          ],
        ),
      ),
    );
    if (ok != true || email.text.trim().isEmpty || !context.mounted) return;
    await run(
      context,
      () => ref.read(schoolRepoProvider).inviter(Invitation(
            email: email.text.trim().toLowerCase(),
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
