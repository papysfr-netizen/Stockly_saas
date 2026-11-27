import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/pays.dart';
import '../../core/telephone.dart';
import '../../data/auth_repository.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';

String messageAuth(Object e) {
  if (e is! FirebaseAuthException) return 'Erreur : $e';
  return switch (e.code) {
    'invalid-credential' || 'wrong-password' || 'user-not-found' => 'E-mail ou mot de passe incorrect.',
    'email-already-in-use' => 'Un compte existe déjà avec cet e-mail.',
    'weak-password' => 'Mot de passe trop faible (6 caractères minimum).',
    'invalid-email' => 'Adresse e-mail invalide.',
    'invalid-phone-number' => 'Numéro de téléphone invalide.',
    'invalid-verification-code' => 'Code incorrect.',
    'session-expired' || 'code-expired' => 'Code expiré : demandez-en un nouveau.',
    'too-many-requests' => 'Trop de tentatives. Réessayez plus tard.',
    'quota-exceeded' => "Quota d'envoi de SMS atteint. Réessayez plus tard.",
    _ => e.message ?? e.code,
  };
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Icon(Icons.school, size: 72, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 8),
                Text('Gestion École',
                    textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 24),
                const DefaultTabController(
                  length: 2,
                  child: Column(children: [
                    TabBar(tabs: [
                      Tab(icon: Icon(Icons.phone_android), text: 'Téléphone'),
                      Tab(icon: Icon(Icons.email_outlined), text: 'E-mail'),
                    ]),
                    SizedBox(height: 16),
                    SizedBox(height: 460, child: TabBarView(children: [_TelephoneForm(), _EmailForm()])),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      );
}

/// Connexion ou inscription par numéro : un code est envoyé par SMS.
/// Après la première connexion, l'écran de finalisation crée le profil.
class _TelephoneForm extends ConsumerStatefulWidget {
  const _TelephoneForm();
  @override
  ConsumerState<_TelephoneForm> createState() => _TelephoneFormState();
}

class _TelephoneFormState extends ConsumerState<_TelephoneForm> {
  final _numero = TextEditingController();
  final _code = TextEditingController();
  String _indicatif = indicatifsPays.first.$1;
  VerificationTelephone? _verification;
  String? _numeroE164;
  bool _busy = false;

  Future<void> _envoyer() async {
    final tel = normaliserTelephone(_numero.text, indicatif: _indicatif);
    if (tel == null) {
      showMessage(context, 'Numéro invalide.', erreur: true);
      return;
    }
    setState(() => _busy = true);
    try {
      final v = await ref.read(authRepoProvider).envoyerCode(tel);
      if (mounted && !v.dejaConnecte) {
        setState(() {
          _verification = v;
          _numeroE164 = tel;
        });
      }
    } catch (e) {
      if (mounted) showMessage(context, messageAuth(e), erreur: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmer() async {
    if (_code.text.trim().length < 6) return;
    setState(() => _busy = true);
    try {
      await _verification!.confirmer(_code.text);
    } catch (e) {
      if (mounted) showMessage(context, messageAuth(e), erreur: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bouton = _busy
        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
        : null;
    if (_verification == null) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        DropdownButtonFormField<String>(
          value: _indicatif,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Pays'),
          items: [
            for (final p in indicatifsPays) DropdownMenuItem(value: p.$1, child: Text('${p.$2} (${p.$1})')),
          ],
          onChanged: (v) => setState(() => _indicatif = v!),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _numero,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(labelText: 'Numéro de téléphone', prefixText: '$_indicatif '),
          onSubmitted: (_) => _envoyer(),
        ),
        const SizedBox(height: 20),
        FilledButton(onPressed: _busy ? null : _envoyer, child: bouton ?? const Text('Recevoir un code par SMS')),
        const SizedBox(height: 12),
        const Text(
          "Première connexion : utilisez le numéro communiqué à l'école pour retrouver votre compte, "
          'ou créez une nouvelle école.',
          textAlign: TextAlign.center,
        ),
      ]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Code envoyé au $_numeroE164', textAlign: TextAlign.center),
      const SizedBox(height: 12),
      TextField(
        controller: _code,
        autofocus: true,
        keyboardType: TextInputType.number,
        maxLength: 6,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 24, letterSpacing: 8),
        decoration: const InputDecoration(labelText: 'Code à 6 chiffres', counterText: ''),
        onChanged: (v) {
          if (v.trim().length == 6) _confirmer();
        },
      ),
      const SizedBox(height: 20),
      FilledButton(onPressed: _busy ? null : _confirmer, child: bouton ?? const Text('Valider')),
      TextButton(
        onPressed: _busy ? null : () => setState(() => _verification = null),
        child: const Text('Changer de numéro / renvoyer le code'),
      ),
    ]);
  }
}

class _EmailForm extends ConsumerStatefulWidget {
  const _EmailForm();
  @override
  ConsumerState<_EmailForm> createState() => _EmailFormState();
}

class _EmailFormState extends ConsumerState<_EmailForm> {
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
        await repo.inscriptionEmail(
          nom: _nom.text.trim(),
          email: _email.text,
          motDePasse: _mdp.text,
          nomEcole: _nouvelleEcole ? _ecole.text : null,
        );
      } else {
        await repo.connexion(_email.text, _mdp.text);
      }
    } catch (e) {
      // « aucune-invitation » : le compte est créé, l'écran de finalisation s'affiche.
      if (mounted && !(e is FirebaseAuthException && e.code == 'aucune-invitation')) {
        showMessage(context, messageAuth(e), erreur: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Form(
        key: _form,
        child: ListView(children: [
          if (_inscription) ...[
            TextFormField(controller: _nom, decoration: const InputDecoration(labelText: 'Nom complet'), validator: requis),
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
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Je crée une nouvelle école'),
              subtitle: const Text("Sinon, utilisez l'e-mail auquel votre école vous a invité."),
              value: _nouvelleEcole,
              onChanged: (v) => setState(() => _nouvelleEcole = v),
            ),
            if (_nouvelleEcole)
              TextFormField(
                  controller: _ecole, decoration: const InputDecoration(labelText: "Nom de l'école"), validator: requis),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy ? null : _valider,
            child: _busy
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(_inscription ? 'Créer mon compte' : 'Se connecter'),
          ),
          TextButton(
            onPressed: () => setState(() => _inscription = !_inscription),
            child: Text(_inscription ? "J'ai déjà un compte" : 'Créer un compte'),
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
      );
}
