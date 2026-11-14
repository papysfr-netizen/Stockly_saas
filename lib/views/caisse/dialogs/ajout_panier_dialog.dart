import 'package:flutter/material.dart';
import 'package:stockly_saas/features/boutiques/boutique_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/produit.dart';
import '../../../core/providers/cart_provider.dart';
import '../../../core/providers/currency_provider.dart';
import '../../../core/providers/user_role_provider.dart';
import 'package:stockly_saas/l10n/app_localizations.dart';
import 'package:stockly_saas/core/utils/payment_calculator.dart';

class AjoutPanierDialog extends ConsumerStatefulWidget {
  final Produit produit;
  const AjoutPanierDialog({super.key, required this.produit});

  @override
  ConsumerState<AjoutPanierDialog> createState() => _AjoutPanierDialogState();
}

class _AjoutPanierDialogState extends ConsumerState<AjoutPanierDialog> {
  late final TextEditingController _qteController;
  late final TextEditingController _prixController;
  String? _erreurStock;

  /// Prix normal du produit dans la boutique de vente (USD)
  double get _prixNormalUSD => (widget.produit.prixPour(ref.boutiqueVente) as num).toDouble();

  @override
  void initState() {
    super.initState();
    _qteController = TextEditingController(text: "1");

    final currencyState = ref.read(currencyProvider);
    final rate = currencyState.activeCurrencyInfo.rateToUSD;
    final prixConverti = _prixNormalUSD * rate;

    _prixController = TextEditingController(
      text: prixConverti % 1 == 0
          ? prixConverti.toStringAsFixed(0)
          : prixConverti.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _qteController.dispose();
    _prixController.dispose();
    super.dispose();
  }

  void _validerChamps() {
    final qteTexte = _qteController.text.replaceAll(',', '.').trim();
    final qte = int.tryParse(qteTexte) ?? 0;

    setState(() {
      if (qte <= 0) {
        _erreurStock = AppLocalizations.of(context).qtyInvalid;
      } else if (qte > widget.produit.stockBoutique(ref.boutiqueVente)) {
        _erreurStock = AppLocalizations.of(context).maxAvailable(widget.produit.stockBoutique(ref.boutiqueVente));
      } else {
        _erreurStock = null;
      }
    });
  }

  /// Demande confirmation avant une vente à perte
  Future<bool> _confirmerPerte() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 40),
        title: Text(AppLocalizations.of(ctx).sellAtLoss),
        content: Text(AppLocalizations.of(ctx).lossConfirm(widget.produit.nom)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.of(ctx).noCorrect)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppLocalizations.of(ctx).yesSell),
          ),
        ],
      ),
    );
    return ok == true;
  }

  @override
  Widget build(BuildContext context) {
    final currencyState = ref.watch(currencyProvider);
    final activeInfo = currencyState.activeCurrencyInfo;
    final rate = activeInfo.rateToUSD > 0 ? activeInfo.rateToUSD : 1.0;

    // 🔐 Changer le prix : autorisation « Remises et retraits » (patron : toujours)
    final peutChangerPrix =
        ref.watch(userProfileProvider).value?.peutRemisesRetraits ?? false;
    final voirFinances = ref.watch(userProfileProvider).value?.peutVoirFinances ?? false;
    final t = AppLocalizations.of(context);

    final prixSaisi = parseAmount(_prixController.text);
    final qteSaisie = int.tryParse(_qteController.text.replaceAll(',', '.').trim()) ?? 0;
    final sousTotalLocal = prixSaisi * qteSaisie;

    final prixAchat = widget.produit.prixAchat;
    final aPerte = peutChangerPrix &&
        prixSaisi > 0 &&
        prixAchat > 0 &&
        prixSaisi / rate < prixAchat - 0.005;
    final remiseUSD = _prixNormalUSD - prixSaisi / rate;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        t.addTitle(widget.produit.nom),
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: widget.produit.stockBoutique(ref.boutiqueVente) < 5 ? Colors.orange.shade50 : Colors.green.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                t.stockAvailable(widget.produit.stockBoutique(ref.boutiqueVente)),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: widget.produit.stockBoutique(ref.boutiqueVente) < 5 ? Colors.orange.shade900 : Colors.green.shade900,
                ),
              ),
            ),
            const SizedBox(height: 14),

            TextField(
              controller: _prixController,
              enabled: peutChangerPrix,
              decoration: InputDecoration(
                labelText: t.unitPrice(activeInfo.code),
                suffixText: activeInfo.symbol,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                helperText: peutChangerPrix
                    ? (remiseUSD > 0.005
                        ? t.discountPerPiece('${(remiseUSD * rate).toStringAsFixed(2)} ${activeInfo.symbol}')
                        : null)
                    : t.fixedPrice,
                helperMaxLines: 2,
                helperStyle: TextStyle(
                  color: peutChangerPrix ? Colors.orange.shade800 : Colors.grey.shade600,
                ),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
            ),
            if (aPerte) ...[
              const SizedBox(height: 8),
              Text(
                voirFinances
                    ? '⚠️ ${t.lossWithCost('${(prixAchat * rate).toStringAsFixed(2)} ${activeInfo.symbol}')}'
                    : '⚠️ ${t.lossBelowCost}',
                style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w600),
              ),
            ],
            const SizedBox(height: 12),

            TextField(
              controller: _qteController,
              decoration: InputDecoration(
                labelText: t.quantity,
                errorText: _erreurStock,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) => _validerChamps(),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(t.subtotal, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  '${sousTotalLocal.toStringAsFixed(2)} ${activeInfo.symbol}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(t.cancel),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: aPerte ? Colors.red.shade700 : const Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
          ),
          onPressed: _erreurStock != null
              ? null
              : () async {
                  final qteTexte = _qteController.text.replaceAll(',', '.').trim();

                  final prixNormal = _prixNormalUSD;
                  final saisi = parseAmount(_prixController.text);
                  final qte = int.tryParse(qteTexte) ?? 1;

                  // Sans autorisation : toujours le prix normal
                  final double prixUSD = (!peutChangerPrix || saisi <= 0)
                      ? prixNormal
                      : saisi / rate;

                  // ⚠️ Vente à perte : on demande confirmation
                  if (prixAchat > 0 && prixUSD < prixAchat - 0.005) {
                    if (!await _confirmerPerte()) return;
                  }
                  if (!mounted) return;

                  final stock = widget.produit.stockBoutique(ref.boutiqueVente);
                  final notifier = ref.read(cartProvider.notifier);
                  final result = notifier.addProduct(
                    widget.produit.id,
                    widget.produit.nom,
                    prixUSD,
                    qte,
                    stock,
                    prixNormal: prixNormal,
                    prixAchat: prixAchat,
                  );

                  if (result == CartOperationResult.stockLimitReached) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(t.qtyOverStock(stock)),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  } else if (result == CartOperationResult.outOfStock) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(t.outOfStockGeneric),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } else {
                    // Déjà dans le panier : le nouveau prix s'applique aussi
                    if (peutChangerPrix) notifier.changerPrix(widget.produit.id, prixUSD);
                    Navigator.pop(context, true);
                  }
                },
          child: Text(aPerte ? t.sellAtLoss : t.add),
        ),
      ],
    );
  }
}
