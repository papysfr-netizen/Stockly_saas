// lib/views/caisse/panier_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/cart_provider.dart';
import '../../../core/providers/currency_provider.dart';
import '../../../core/providers/user_role_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../dialogs/paiement_dialog.dart';
import '../dialogs/prix_negocie_dialog.dart';

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
    final t = AppLocalizations.of(context);
    // 🔒 Taux : le patron, ou « Paramètres sensibles » seulement
    final autorise = ref.read(userProfileProvider).value?.peutParametres ?? false;
    if (!autorise) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.panRateLocked)),
      );
      return;
    }
    final currencyState = ref.read(currencyProvider);
    // Utilisation directe du taux CDF au lieu du taux de la devise active (qui vaut 1.0 en USD)
    final cdfRate = currencyState.bccCdfRate;
    final controller = TextEditingController(
      text: cdfRate.toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.currency_exchange, color: Colors.indigo),
            const SizedBox(width: 8),
            Text(t.panRateTitle, style: const TextStyle(fontSize: 16)),
          ],
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: t.panRateFor1,
            border: const OutlineInputBorder(),
            suffixText: 'FC',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final newRate = double.tryParse(controller.text.trim());
              if (newRate != null && newRate > 0) {
                ref.read(currencyProvider.notifier).updateExchangeRate(newRate);
                Navigator.pop(dialogContext);
              }
            },
            child: Text(t.panUpdate),
          ),
        ],
      ),
    );
  }

  /// 🏷️ Changer le prix d'une ligne du panier (autorisation « Remises et retraits »)
  Future<void> _changerPrix(BuildContext context, WidgetRef ref, CartItem item) async {
    final peut = ref.read(userProfileProvider).value?.peutRemisesRetraits ?? false;
    if (!peut) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Changer le prix demande l'autorisation « Remises et retraits »."),
        backgroundColor: Colors.orange,
      ));
      return;
    }
    final nouveau = await demanderPrixNegocie(
      context,
      nom: item.nom,
      prixActuel: item.prix,
      prixNormal: item.prixNormal,
      prixAchat: item.prixAchat,
    );
    if (nouveau == null) return;
    ref.read(cartProvider.notifier).changerPrix(item.id, nouveau);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final totalAmount = ref.watch(cartTotalProvider);
    final currencyState = ref.watch(currencyProvider);
    final activeInfo = currencyState.activeCurrencyInfo;
    final t = AppLocalizations.of(context);
    final peutChangerTaux = ref.watch(userProfileProvider).value?.peutParametres ?? false;

    return Container(
      color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF16191F) : Colors.grey.shade50,
      child: Column(
        children: [
          // 1. En-tête : Changement de devise & Taux du jour (Corrigé avec Flexible)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
            color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF232A45) : Colors.indigo.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Bascule rapide USD / FC
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'USD',
                      label: Text('USD', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    ButtonSegment(
                      value: 'CDF',
                      label: Text('FC', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
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
                const SizedBox(width: 4),

                // Taux d'échange interactif flexible
                Flexible(
                  child: InkWell(
                    onTap: () => _afficherDialogTauxChange(context, ref),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              '1\$ = ${currencyState.bccCdfRate.toStringAsFixed(0)} FC',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).brightness == Brightness.dark ? Colors.indigo.shade200 : Colors.indigo.shade900,
                              ),
                            ),
                          ),
                          if (peutChangerTaux) ...[
                            const SizedBox(width: 2),
                            const Icon(Icons.edit, size: 12, color: Colors.indigo),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                if (cart.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.delete_sweep, color: Colors.redAccent, size: 20),
                    tooltip: t.panClear,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => ref.read(cartProvider.notifier).clearCart(),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),

          // 2. Liste des articles du panier
          Expanded(
            child: cart.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.shopping_cart_outlined, size: 48, color: Colors.grey),
                        const SizedBox(height: 8),
                        Text(
                          t.panEmpty,
                          style: const TextStyle(color: Colors.grey, fontSize: 15),
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
                        onTap: () => _changerPrix(context, ref, item),
                        leading: Icon(
                          Icons.sell_outlined,
                          size: 20,
                          color: item.aPerte
                              ? Colors.red
                              : (item.prixNegocie ? Colors.orange.shade800 : Colors.grey),
                        ),
                        title: Text(
                          item.nom,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${item.quantite} x ${currencyState.formatPrice(item.prix)}',
                              style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade700, fontSize: 12),
                            ),
                            if (item.prixNegocie)
                              Text(
                                'Prix normal : ${currencyState.formatPrice(item.prixNormal)}',
                                style: TextStyle(fontSize: 11, color: Colors.orange.shade800),
                              ),
                            if (item.aPerte)
                              const Text(
                                'Vente à perte',
                                style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold),
                              ),
                          ],
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
              color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1C1F26) : Colors.white,
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
                    Text(
                      t.panTotal,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      currencyState.formatPrice(totalAmount),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.indigo.shade200 : Colors.indigo.shade800,
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
                      disabledBackgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2A2E37) : Colors.grey.shade300,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      t.panCheckout,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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