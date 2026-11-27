import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_user.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';
import 'login_screen.dart';

/// Affiché quand le compte est authentifié (e-mail ou téléphone) mais n'a pas
/// encore de profil : on rejoint l'école qui a invité, ou on en crée une.
class FinaliserProfilScreen extends ConsumerStatefulWidget {
  const FinaliserProfilScreen({super.key});
  @override
  ConsumerState<FinaliserProfilScreen> createState() => _FinaliserProfilScreenState();
}

class _FinaliserProfilScreenState extends ConsumerState<FinaliserProfilScreen> {
  final _nom = TextEditingController();
  final _ecole = TextEditingController();
  late final Future<Invitation?> _invitation = ref.read(authRepoProvider).invitationPourMoi();
  bool _busy = false;

  Future<void> _valider(Invitation? inv) async {
    if (inv == null && (_nom.text.trim().isEmpty || _ecole.text.trim().isEmpty)) {
      showMessage(context, "Indiquez votre nom et celui de l'école.", erreur: true);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(authRepoProvider).finaliserProfil(nom: _nom.text, nomEcole: _ecole.text);
    } catch (e) {
      if (mounted) showMessage(context, messageAuth(e), erreur: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final identifiant = user?.phoneNumber ?? user?.email ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Bienvenue'), actions: [
        TextButton(
            onPressed: () => ref.read(authRepoProvider).deconnexion(), child: const Text('Se déconnecter')),
      ]),
      body: FutureBuilder<Invitation?>(
        future: _invitation,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final inv = snap.data;
          if (inv != null && _nom.text.isEmpty) _nom.text = inv.nom;
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text('Connecté avec $identifiant', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(inv != null
                          ? "Vous êtes invité(e) par votre école en tant que « ${inv.role.label} ». "
                              'Confirmez votre nom pour accéder à votre espace.'
                          : "Aucune invitation n'est associée à ce compte.\n\n"
                              "• Si vous êtes parent, enseignant ou membre du personnel, demandez à l'école "
                              'd\'enregistrer ce numéro / cet e-mail, puis reconnectez-vous.\n'
                              "• Si vous gérez une école, créez-la ci-dessous : vous en serez la direction."),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(controller: _nom, decoration: const InputDecoration(labelText: 'Votre nom complet')),
                  if (inv == null) ...[
                    const SizedBox(height: 12),
                    TextField(controller: _ecole, decoration: const InputDecoration(labelText: "Nom de l'école à créer")),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _busy ? null : () => _valider(inv),
                    child: Text(inv != null ? 'Rejoindre mon école' : "Créer l'école"),
                  ),
                ]),
              ),
            ),
          );
        },
      ),
    );
  }
}
