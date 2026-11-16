// 🗑️ Fenêtre « Supprimer mon compte » (Paramètres → Mon compte)
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'suppression_compte_service.dart';

class SupprimerCompteDialog extends StatefulWidget {
  /// Le patron efface toute l'entreprise ; un employé, seulement son accès
  final bool estProprietaire;
  const SupprimerCompteDialog({super.key, required this.estProprietaire});

  static Future<void> show(BuildContext context, {required bool estProprietaire}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => SupprimerCompteDialog(estProprietaire: estProprietaire),
    );
  }

  @override
  State<SupprimerCompteDialog> createState() => _SupprimerCompteDialogState();
}

class _SupprimerCompteDialogState extends State<SupprimerCompteDialog> {
  final _mot = TextEditingController();
  final _motDePasse = TextEditingController();
  bool _enCours = false;
  String? _erreur;
  int _fait = 0;
  int _total = 0;

  @override
  void dispose() {
    _mot.dispose();
    _motDePasse.dispose();
    super.dispose();
  }

  bool _peutValider(AppLocalizations t) {
    final motOk = _mot.text.trim().toUpperCase() == t.delConfirmWord.toUpperCase();
    final mdpOk = !SuppressionCompteService.aMotDePasse || _motDePasse.text.isNotEmpty;
    return motOk && mdpOk && !_enCours;
  }

  Future<void> _supprimer(AppLocalizations t) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      await SuppressionCompteService.supprimer(
        motDePasse: _motDePasse.text,
        progression: (fait, total) {
          if (mounted) {
            setState(() {
              _fait = fait;
              _total = total;
            });
          }
        },
      );
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text(t.delDone)));
    } on SuppressionException catch (e) {
      if (!mounted) return;
      setState(() {
        _enCours = false;
        _erreur = switch (e.raison) {
          ErreurSuppression.motDePasseIncorrect => t.delErrPassword,
          ErreurSuppression.reconnexionRequise => t.delErrRelogin,
          ErreurSuppression.pasDeConnexion => t.delErrNetwork,
          // Le code technique aide à trouver la cause (ex. permission-denied)
          ErreurSuppression.inconnue => e.detail.isEmpty ? t.delErrUnknown : '${t.delErrUnknown} (${e.detail})',
        };
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _enCours = false;
        _erreur = t.delErrUnknown;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return AlertDialog(
      icon: const Icon(Icons.delete_forever_rounded, color: Colors.red, size: 36),
      title: Text(t.delTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
              ),
              child: Text(
                widget.estProprietaire ? t.delOwnerWarning : t.delEmployeeWarning,
                style: const TextStyle(fontSize: 13),
              ),
            ),
            const SizedBox(height: 14),
            // La consigne au-dessus (le libellé du champ coupait le mot à écrire)
            Text(t.delTypeConfirm(t.delConfirmWord),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: _mot,
              enabled: !_enCours,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: t.delConfirmWord,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            if (SuppressionCompteService.aMotDePasse)
              TextField(
                controller: _motDePasse,
                enabled: !_enCours,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: t.delPassword,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (_) => setState(() {}),
              )
            else
              Text(t.delSmsHint, style: const TextStyle(fontSize: 12)),
            if (_enCours) ...[
              const SizedBox(height: 14),
              LinearProgressIndicator(value: _total > 0 ? _fait / _total : null),
              const SizedBox(height: 6),
              Text(t.delProgress, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
            ],
            if (_erreur != null) ...[
              const SizedBox(height: 12),
              Text(_erreur!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _enCours ? null : () => Navigator.pop(context),
          child: Text(t.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: _peutValider(t) ? () => _supprimer(t) : null,
          child: Text(t.delButton),
        ),
      ],
    );
  }
}
