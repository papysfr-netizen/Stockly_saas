import 'package:stockly_saas/l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Fenêtre « Changer mon mot de passe » (tous les rôles).
/// On demande l'ancien mot de passe (sécurité Firebase), puis le nouveau.
class ChangerMotDePasseDialog extends StatefulWidget {
  const ChangerMotDePasseDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const ChangerMotDePasseDialog(),
    );
  }

  @override
  State<ChangerMotDePasseDialog> createState() =>
      _ChangerMotDePasseDialogState();
}

class _ChangerMotDePasseDialogState extends State<ChangerMotDePasseDialog> {
  final _ancienCtrl = TextEditingController();
  final _nouveauCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _voirAncien = false;
  bool _voirNouveau = false;
  bool _enCours = false;
  String? _erreur;

  @override
  void dispose() {
    _ancienCtrl.dispose();
    _nouveauCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String _messageErreur(FirebaseAuthException e) {
    switch (e.code) {
      case 'wrong-password':
      case 'invalid-credential':
        return AppLocalizations.of(context).pwdOldWrong;
      case 'weak-password':
        return AppLocalizations.of(context).pwdTooWeak;
      case 'too-many-requests':
        return AppLocalizations.of(context).pwdTooMany;
      case 'network-request-failed':
        return AppLocalizations.of(context).pwdNoInternet;
      case 'requires-recent-login':
        return AppLocalizations.of(context).pwdRelogin;
      default:
        return e.message ?? AppLocalizations.of(context).errorUnknown;
    }
  }

  Future<void> _valider() async {
    final ancien = _ancienCtrl.text.trim();
    final nouveau = _nouveauCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (ancien.isEmpty || nouveau.isEmpty || confirm.isEmpty) {
      setState(() => _erreur = AppLocalizations.of(context).pwdFillAll);
      return;
    }
    if (nouveau.length < 6) {
      setState(() => _erreur = AppLocalizations.of(context).pwdMin6);
      return;
    }
    if (nouveau != confirm) {
      setState(() => _erreur = AppLocalizations.of(context).pwdMismatch);
      return;
    }
    if (nouveau == ancien) {
      setState(() => _erreur = AppLocalizations.of(context).pwdSameAsOld);
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      setState(() => _erreur =
          AppLocalizations.of(context).pwdSmsAccount);
      return;
    }

    setState(() {
      _enCours = true;
      _erreur = null;
    });

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      // 1. Vérifier l'ancien mot de passe
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: ancien,
      );
      await user.reauthenticateWithCredential(credential);

      // 2. Enregistrer le nouveau
      await user.updatePassword(nouveau);

      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).pwdChanged),
          backgroundColor: Colors.green.shade700,
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _erreur = _messageErreur(e));
    } catch (e) {
      if (mounted) setState(() => _erreur = AppLocalizations.of(context).errorWith('$e'));
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.lock_reset),
          const SizedBox(width: 8),
          Expanded(child: Text(AppLocalizations.of(context).pwdChangeTitle)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _ancienCtrl,
              obscureText: !_voirAncien,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).pwdOld,
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_voirAncien ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _voirAncien = !_voirAncien),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nouveauCtrl,
              obscureText: !_voirNouveau,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).pwdNew,
                helperText: AppLocalizations.of(context).pwdMinHint,
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(_voirNouveau ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _voirNouveau = !_voirNouveau),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmCtrl,
              obscureText: !_voirNouveau,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).pwdConfirm,
                prefixIcon: Icon(Icons.lock),
              ),
              onSubmitted: (_) {
                if (!_enCours) _valider();
              },
            ),
            if (_erreur != null) ...[
              const SizedBox(height: 12),
              Text(
                _erreur!,
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _enCours ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _enCours ? null : _valider,
          child: _enCours
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Valider'),
        ),
      ],
    );
  }
}