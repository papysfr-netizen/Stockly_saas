import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/cart_provider.dart';
import '../../../providers/currency_provider.dart';
import '../dialogs/paiement_dialog.dart';

class PanierView extends ConsumerWidget {
  final String entrepriseId;
  final String userId;

  const PanierView({
    super.key,
    required this.entrepriseId,
    required this.userId,
  });

  /// Dialogue pour la mise à jour rapide du taux de change du jour (USD -> FC)
  void _afficherDialogTauxChange(BuildContext context, WidgetRef ref) {
    final currencyState = ref.read(currencyProvider);
    // Utilisation directe du taux CDF au lieu du taux de la devise active (qui vaut 1.0 en USD)
    final cdfRate = currencyState.bccCdfRate;
    final controller = TextEditingController(
      text: cdfRate.toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.currency_exchange, color: Colors.indigo),
            SizedBox(width: 8),
            Text('Taux du jour (USD -> FC)', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Taux pour 1 USD',
            border: OutlineInputBorder(),
            suffixText: 'FC',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final newRate = double.tryParse(controller.text.trim());
              if (newRate != null && newRate > 0) {
                ref.read(currencyProvider.notifier).updateExchangeRate(newRate);
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Mettre à jour'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final totalAmount = ref.watch(cartTotalProvider);
    final currencyState = ref.watch(currencyProvider);
    final activeInfo = currencyState.activeCurrencyInfo;

    return Container(
      color: Colors.grey.shade50,
      child: Column(
        children: [
          // 1. En-tête : Changement de devise & Taux du jour
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
            color: Colors.indigo.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Bascule rapide USD / FC
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'USD',
                      label: Text('USD (\$)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    ButtonSegment(
                      value: 'CDF',
                      label: Text('FC', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                  selected: {activeInfo.code},
                  onSelectionChanged: (newSelection) {
                    ref.read(currencyProvider.notifier).setCurrency(newSelection.first);
                  },
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),

                // Taux d'échange interactif
                InkWell(
                  onTap: () => _afficherDialogTauxChange(context, ref),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(
                      children: [
                        Text(
                          '1\$ = ${currencyState.bccCdfRate.toStringAsFixed(0)} FC',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo.shade900,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.edit, size: 14, color: Colors.indigo),
                      ],
                    ),
                  ),
                ),

                if (cart.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.delete_sweep, color: Colors.redAccent, size: 22),
                    tooltip: 'Vider le panier',
                    onPressed: () => ref.read(cartProvider.notifier).clearCart(),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),

          // 2. Liste des articles du panier
          Expanded(
            child: cart.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text(
                          'Votre panier est vide',
                          style: TextStyle(color: Colors.grey, fontSize: 15),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: cart.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
                    itemBuilder: (context, index) {
                      final item = cart[index];
                      final sousTotal = item.quantite * item.prix;

                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                        title: Text(
                          item.nom,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        subtitle: Text(
                          '${item.quantite} x ${currencyState.formatPrice(item.prix)}',
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              currencyState.formatPrice(sousTotal),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                              onPressed: () => ref.read(cartProvider.notifier).removeProduct(item.id),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // 3. Footer : Total et bouton d'encaissement
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(12),
                  offset: const Offset(0, -2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total à payer :',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      currencyState.formatPrice(totalAmount),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: cart.isEmpty
                        ? null
                        : () {
                            showDialog(
                              context: context,
                              builder: (dialogContext) => PaiementDialog(
                                total: totalAmount,
                                cart: cart,
                                entrepriseId: entrepriseId,
                                userId: userId,
                              ),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'ENCAISSER',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}