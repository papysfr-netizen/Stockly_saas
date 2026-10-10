import 'package:flutter/material.dart';
import 'package:stockly_saas/features/boutiques/boutique_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/produit.dart';
import '../../../core/providers/cart_provider.dart';
import '../../../core/providers/currency_provider.dart';

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

  @override
  void initState() {
    super.initState();
    _qteController = TextEditingController(text: "1");

    final currencyState = ref.read(currencyProvider);
    final rate = currencyState.activeCurrencyInfo.rateToUSD;
    final prixConverti = widget.produit.prixPour(ref.boutiqueVente) * rate;

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
        _erreurStock = 'Quantité invalide';
      } else if (qte > widget.produit.stockBoutique(ref.boutiqueVente)) {
        _erreurStock = 'Max disponible : ${widget.produit.stockBoutique(ref.boutiqueVente)}';
      } else {
        _erreurStock = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencyState = ref.watch(currencyProvider);
    final activeInfo = currencyState.activeCurrencyInfo;

    final prixSaisi = double.tryParse(_prixController.text.replaceAll(',', '.').trim()) ?? 0.0;
    final qteSaisie = int.tryParse(_qteController.text.replaceAll(',', '.').trim()) ?? 0;
    final sousTotalLocal = prixSaisi * qteSaisie;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        'Ajouter ${widget.produit.nom}',
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
                'Stock disponible : ${widget.produit.stockBoutique(ref.boutiqueVente)}',
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
              decoration: InputDecoration(
                labelText: 'Prix unitaire (${activeInfo.code})',
                suffixText: activeInfo.symbol,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _qteController,
              decoration: InputDecoration(
                labelText: 'Quantité',
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
                const Text('Sous-total :', style: TextStyle(fontWeight: FontWeight.w600)),
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
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
          ),
          onPressed: _erreurStock != null
              ? null
              : () {
                  final rate = activeInfo.rateToUSD;

                  final prixTexte = _prixController.text.replaceAll(',', '.').trim();
                  final qteTexte = _qteController.text.replaceAll(',', '.').trim();

                  final prixSaisi = double.tryParse(prixTexte) ?? (widget.produit.prixPour(ref.boutiqueVente) * rate);
                  final qte = int.tryParse(qteTexte) ?? 1;

                  final prixUSD = rate > 0 ? (prixSaisi / rate) : widget.produit.prixPour(ref.boutiqueVente);

                  // Transmettre explicitement widget.produit.stockBoutique(ref.boutiqueVente)
                  final result = ref.read(cartProvider.notifier).addProduct(
                        widget.produit.id,
                        widget.produit.nom,
                        prixUSD,
                        qte,
                        widget.produit.stockBoutique(ref.boutiqueVente),
                      );

                  if (result == CartOperationResult.stockLimitReached) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Quantité supérieure au stock disponible (${widget.produit.stockBoutique(ref.boutiqueVente)})'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  } else if (result == CartOperationResult.outOfStock) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Produit en rupture de stock !'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } else {
                    Navigator.pop(context, true);
                  }
                },
          child: const Text('Ajouter'),
        ),
      ],
    );
  }
}