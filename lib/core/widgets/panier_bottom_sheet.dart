import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stockly_saas/core/providers/cart_provider.dart';
import 'package:stockly_saas/core/providers/currency_provider.dart';
import 'package:stockly_saas/views/caisse/dialogs/paiement_dialog.dart';

class PanierBottomSheet extends ConsumerWidget {
  final String entrepriseId;
  final String userId;

  const PanierBottomSheet({
    super.key,
    required this.entrepriseId,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Récupération des données du panier et de la devise
    final cartItems = ref.watch(cartProvider);
    final totalUSD = ref.watch(cartTotalProvider);
    final currencyState = ref.watch(currencyProvider);

    return Container(
      padding: const EdgeInsets.all(16.0),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // En-tête avec titre et bouton de fermeture
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mon Panier',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const Divider(),

          // Liste des articles dans le panier
          if (cartItems.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'Votre panier est vide',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: cartItems.length,
                itemBuilder: (context, index) {
                  final item = cartItems[index];
                  final String prixUnitaire =
                      currencyState.formatPrice(item.prix);
                  final String totalLigne =
                      currencyState.formatPrice(item.totalPrice);

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      item.nom,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text('${item.quantite} x $prixUnitaire'),
                    trailing: Text(
                      totalLigne,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  );
                },
              ),
            ),

          const Divider(),

          // Section Récapitulative du Total
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total :',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  currencyState.formatPrice(totalUSD),
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12.0),

          // Bouton Valider / Procéder au paiement
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onPressed: cartItems.isEmpty
                  ? null
                  : () {
                      showDialog<bool>(
                        context: context,
                        barrierDismissible: false,
                        builder: (dialogContext) => PaiementDialog(
                          entrepriseId: entrepriseId,
                          userId: userId,
                          total: totalUSD,
                          cart: cartItems,
                        ),
                      ).then((paye) {
                        if (paye == true && context.mounted) {
                          // Vider le panier après paiement réussi
                          ref.read(cartProvider.notifier).clearCart();

                          // Fermer le modal bottom sheet
                          Navigator.of(context).pop();

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Vente enregistrée avec succès !'),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      });
                    },
              child: const Text(
                'Procéder au Paiement',
                style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}