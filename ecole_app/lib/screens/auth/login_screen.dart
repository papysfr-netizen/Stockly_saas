import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import '../../widgets/common.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _nom = TextEditingController();
  final _email = TextEditingController();
  final _mdp = TextEditingController();
  final _ecole = TextEditingController();
  bool _inscription = false;
  bool _nouvelleEcole = false;
  bool _busy = false;

  Future<void> _valider() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final repo = ref.read(authRepoProvider);
    try {
      if (_inscription) {
        await repo.inscription(
          nom: _nom.text.trim(),
          email: _email.text,
          motDePasse: _mdp.text,
          nomEcole: _nouvelleEcole ? _ecole.text : null,
        );
      } else {
        await repo.connexion(_email.text, _mdp.text);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) showMessage(context, _message(e), erreur: true);
    } catch (e) {
      if (mounted) showMessage(context, 'Erreur : $e', erreur: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _message(FirebaseAuthException e) => switch (e.code) {
        'invalid-credential' || 'wrong-password' || 'user-not-found' =>
          'E-mail ou mot de passe incorrect.',
        'email-already-in-use' => 'Un compte existe déjà avec cet e-mail.',
        'weak-password' => 'Mot de passe trop faible (6 caractères minimum).',
        'invalid-email' => 'Adresse e-mail invalide.',
        _ => e.message ?? e.code,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _form,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Icon(Icons.school, size: 72, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 8),
                Text('Gestion École',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 24),
                if (_inscription) ...[
                  TextFormField(
                    controller: _nom,
                    decoration: const InputDecoration(labelText: 'Nom complet'),
                    validator: requis,
                  ),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'E-mail'),
                  validator: requis,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _mdp,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Mot de passe'),
                  validator: requis,
                ),
                if (_inscription) ...[
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Je crée une nouvelle école'),
                    subtitle: const Text(
                        "Sinon, utilisez l'e-mail auquel votre école vous a invité."),
                    value: _nouvelleEcole,
                    onChanged: (v) => setState(() => _nouvelleEcole = v),
                  ),
                  if (_nouvelleEcole)
                    TextFormField(
                      controller: _ecole,
                      decoration: const InputDecoration(labelText: "Nom de l'école"),
                      validator: requis,
                    ),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _busy ? null : _valider,
                  child: _busy
                      ? const SizedBox(
                          height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_inscription ? 'Créer mon compte' : 'Se connecter'),
                ),
                TextButton(
                  onPressed: () => setState(() => _inscription = !_inscription),
                  child: Text(_inscription
                      ? "J'ai déjà un compte"
                      : 'Créer un compte'),
                ),
                if (!_inscription)
                  TextButton(
                    onPressed: () async {
                      if (_email.text.trim().isEmpty) {
                        showMessage(context, 'Saisissez votre e-mail.');
                        return;
                      }
                      await run(context, () => ref.read(authRepoProvider).motDePasseOublie(_email.text),
                          succes: 'E-mail de réinitialisation envoyé.');
                    },
                    child: const Text('Mot de passe oublié ?'),
                  ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
