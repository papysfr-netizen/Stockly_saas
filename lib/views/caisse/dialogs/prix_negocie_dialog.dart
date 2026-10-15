import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stockly_saas/core/providers/currency_provider.dart';
import 'package:stockly_saas/core/providers/user_role_provider.dart';

/// 💬 Fenêtre « Prix négocié ».
/// Tous les prix reçus et renvoyés sont en USD.
/// Renvoie le nouveau prix, ou null si on annule.
Future<double?> demanderPrixNegocie(
  BuildContext context, {
  required String nom,
  required double prixActuel,
  required double prixNormal,
  required double prixAchat,
}) {
  return showDialog<double>(
    context: context,
    builder: (_) => _PrixNegocieDialog(
      nom: nom,
      prixActuel: prixActuel,
      prixNormal: prixNormal,
      prixAchat: prixAchat,
    ),
  );
}

/// Montant lisible : 120 ou 120.50
String _texte(double v) => v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

class _PrixNegocieDialog extends ConsumerStatefulWidget {
  final String nom;
  final double prixActuel;
  final double prixNormal;
  final double prixAchat;

  const _PrixNegocieDialog({
    required this.nom,
    required this.prixActuel,
    required this.prixNormal,
    required this.prixAchat,
  });

  @override
  ConsumerState<_PrixNegocieDialog> createState() => _PrixNegocieDialogState();
}

class _PrixNegocieDialogState extends ConsumerState<_PrixNegocieDialog> {
  late final TextEditingController _ctrl;

  double get _taux {
    final t = ref.read(currencyProvider).activeCurrencyInfo.rateToUSD;
    return t > 0 ? t : 1.0;
  }

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: _texte(widget.prixActuel * _taux));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final info = ref.watch(currencyProvider).activeCurrencyInfo;
    final taux = info.rateToUSD > 0 ? info.rateToUSD : 1.0;
    final voirFinances = ref.watch(userProfileProvider).value?.peutVoirFinances ?? false;

    final saisi = double.tryParse(_ctrl.text.replaceAll(',', '.').trim());
    final prixUSD = saisi == null ? null : saisi / taux;
    final valide = prixUSD != null && prixUSD > 0;
    final remise = valide ? widget.prixNormal - prixUSD : 0.0;
    final aPerte = valide && widget.prixAchat > 0 && prixUSD < widget.prixAchat - 0.005;
    final dejaNegocie = (widget.prixActuel - widget.prixNormal).abs() > 0.005;

    return AlertDialog(
      title: Text('Prix pour ${widget.nom}', overflow: TextOverflow.ellipsis),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Prix normal : ${_texte(widget.prixNormal * taux)} ${info.symbol}',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ctrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Prix accordé (par pièce)',
                suffixText: info.symbol,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            if (remise > 0.005)
              Text(
                'Remise : ${_texte(remise * taux)} ${info.symbol} par pièce',
                style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.w600),
              ),
            if (aPerte) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        voirFinances
                            ? "Vente à perte ! Prix d'achat : ${_texte(widget.prixAchat * taux)} ${info.symbol}"
                            : "Vente à perte ! Ce prix est sous le prix d'achat.",
                        style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        if (dejaNegocie)
          TextButton(
            onPressed: () => Navigator.pop(context, widget.prixNormal),
            child: const Text('Prix normal'),
          ),
        FilledButton(
          style: aPerte ? FilledButton.styleFrom(backgroundColor: Colors.red.shade700) : null,
          onPressed: valide ? () => Navigator.pop(context, prixUSD) : null,
          child: Text(aPerte ? 'Vendre à perte' : 'Valider'),
        ),
      ],
    );
  }
}
