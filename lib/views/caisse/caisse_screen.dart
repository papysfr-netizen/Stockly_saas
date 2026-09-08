import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stockly_saas/widgets/currency_selector_widget.dart';
import '../../providers/cart_provider.dart';
import '../../providers/currency_provider.dart';
import '../../providers/produit_provider.dart';
import '../../providers/user_role_provider.dart';
import '../../repositories/vente_repository.dart';
import '../../screens/settings_screen.dart';
import '../../services/report_export_service.dart';
import '../../utils/currency_extension.dart';
import 'dialogs/nouveau_produit_dialog.dart';
import 'dialogs/paiement_dialog.dart';
import 'widgets/panier_view.dart';
import 'widgets/produits_view.dart' hide PanierView;

final venteRepositoryProvider =
    Provider<VenteRepository>((ref) => VenteRepository());

class CaisseScreen extends ConsumerWidget {
  const CaisseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return profileAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Erreur de chargement du profil : $err',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      ),
      data: (profile) {
        final entrepriseId = profile.entrepriseId;
        final userId = profile.uid;
        final canAddProduct = profile.can('canAddProduct');

        final cart = ref.watch(cartProvider);
        final cartNotifier = ref.read(cartProvider.notifier);
        final totalAmount = ref.watch(cartTotalProvider);
        final totalItemsCount = ref.watch(cartItemCountProvider);

        return LayoutBuilder(
          builder: (context, constraints) {
            final bool isMobile = constraints.maxWidth < 700;

            return Scaffold(
              appBar: AppBar(
                title: const Text('Caisse / POS'),
                actions: [
                  const CurrencySelectorWidget(),
                  if (canAddProduct)
                    IconButton(
                      icon: const Icon(Icons.add_box, size: 26),
                      tooltip: 'Nouveau Produit en Stock',
                      onPressed: () =>
                          _afficherDialogNouveauProduit(context, entrepriseId),
                    ),
                  IconButton(
                    icon: const Icon(Icons.settings, size: 26),
                    tooltip: 'Paramètres',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 26),
                    tooltip: 'Options d\'exportation',
                    onSelected: (value) async {
                      final produits =
                          ref.read(produitsStreamProvider).value ?? [];
                      final currencyState = ref.read(currencyProvider);

                      final enTetes = [
                        'Nom du produit',
                        'Stock disponible',
                        'Prix Vente'
                      ];
                      final lignes = produits
                          .map((p) => [
                                p.nom,
                                p.quantite,
                                currencyState.formatPrice(p.prixVente),
                              ])
                          .toList();

                      if (value == 'excel') {
                        await ReportExportService.exporterExcel(
                          titreRapport: 'Catalogue_Produits_Caisse',
                          enTetes: enTetes,
                          lignes: lignes,
                        );
                      } else if (value == 'pdf') {
                        await ReportExportService.exporterPDF(
                          titreRapport: 'Catalogue des Produits (Caisse)',
                          nomBoutique: 'Stockly Pro',
                          enTetes: enTetes,
                          lignes: lignes,
                        );
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'excel',
                        child: Row(
                          children: [
                            Icon(Icons.table_chart, color: Colors.green),
                            SizedBox(width: 8),
                            Text('Exporter vers Excel'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'pdf',
                        child: Row(
                          children: [
                            Icon(Icons.picture_as_pdf, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Imprimer / PDF'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              body: isMobile
                  ? const ProduitsView()
                  : Row(
                      children: [
                        const Expanded(flex: 2, child: ProduitsView()),
                        const VerticalDivider(
                          width: 1,
                          thickness: 2,
                          color: Colors.grey,
                        ),
                        Expanded(
                          flex: 1,
                          child: PanierView(
                            entrepriseId: entrepriseId,
                            userId: userId,
                          ),
                        ),
                      ],
                    ),
              floatingActionButton: isMobile && cart.isNotEmpty
                  ? FloatingActionButton.extended(
                      onPressed: () => _afficherModalPanier(
                        context,
                        ref,
                        cart,
                        cartNotifier,
                        totalAmount,
                        entrepriseId,
                        userId,
                      ),
                      backgroundColor: Colors.green,
                      icon:
                          const Icon(Icons.shopping_cart, color: Colors.white),
                      label: Text(
                        'Panier ($totalItemsCount) - ${ref.formatPrice(totalAmount)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : null,
            );
          },
        );
      },
    );
  }

  void _afficherModalPanier(
    BuildContext context,
    WidgetRef ref,
    List<CartItem> cart,
    CartNotifier cartNotifier,
    double totalAmount,
    String entrepriseId,
    String userId,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (modalContext) {
        return Container(
          height: MediaQuery.of(modalContext).size.height * 0.75,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Panier Actuel',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(modalContext),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: cart.length,
                  itemBuilder: (context, index) {
                    final item = cart[index];
                    return ListTile(
                      title: Text(
                        item.nom,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Qté: ${item.quantite} x ${ref.formatPrice(item.prix)}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          cartNotifier.removeProduct(item.id);
                          if (cart.length <= 1 && modalContext.mounted) {
                            Navigator.pop(modalContext);
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      'Total: ${ref.formatPrice(totalAmount)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(modalContext);
                          _afficherDialogPaiement(
                            context,
                            totalAmount,
                            cart,
                            entrepriseId,
                            userId,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'ENCAISSER',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _afficherDialogNouveauProduit(
      BuildContext context, String entrepriseId) {
    showDialog(
      context: context,
      builder: (dialogContext) =>
          NouveauProduitDialog(entrepriseId: entrepriseId),
    );
  }

  void _afficherDialogPaiement(
    BuildContext context,
    double total,
    List<CartItem> cart,
    String entrepriseId,
    String userId,
  ) {
    // 1. Validation préventive du stock
    final stockInsuffisant = cart.where((item) => item.quantite > item.stock);
    if (stockInsuffisant.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Stock insuffisant pour : ${stockInsuffisant.map((e) => e.nom).join(", ")}',
          ),
          backgroundColor: Colors.orange.shade800,
        ),
      );
      return;
    }

    // 2. Ouverture du dialogue de paiement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PaiementDialog(
        total: total,
        cart: cart,
        entrepriseId: entrepriseId,
        userId: userId,
      ),
    );
  }
}