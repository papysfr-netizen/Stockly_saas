import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stockly_saas/models/produit.dart';
import 'package:stockly_saas/providers/auth_provider.dart';
import 'package:stockly_saas/providers/cart_provider.dart';
import 'package:stockly_saas/providers/currency_provider.dart';
import 'package:stockly_saas/providers/entreprise_provider.dart';
import 'package:stockly_saas/providers/produit_provider.dart';
import 'package:stockly_saas/views/caisse/dialogs/ajout_panier_dialog.dart';
import 'package:stockly_saas/views/caisse/dialogs/paiement_dialog.dart';
import 'package:stockly_saas/widgets/quick_scanner_widget.dart';

class ProduitsView extends ConsumerStatefulWidget {
  const ProduitsView({super.key});

  @override
  ConsumerState<ProduitsView> createState() => _ProduitsViewState();
}

class _ProduitsViewState extends ConsumerState<ProduitsView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'Tous';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Traitement automatique du produit détecté par le scanner
  void _traiterCodeScanne(String codeScanne, List<Produit> produits) {
    final codeClean = codeScanne.trim();
    if (codeClean.isEmpty) return;

    final produitIndex = produits.indexWhere(
      (p) => p.codeBarre.trim().toLowerCase() == codeClean.toLowerCase(),
    );

    if (produitIndex != -1) {
      final produit = produits[produitIndex];

      if (produit.quantite <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${produit.nom} est en rupture de stock !'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      showDialog<bool>(
        context: context,
        builder: (dialogContext) => AjoutPanierDialog(produit: produit),
      ).then((added) {
        if (added == true && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${produit.nom} ajouté au panier !'),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Aucun produit trouvé pour le code : $codeClean'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final produitsAsync = ref.watch(produitsStreamProvider);
    final currencyState = ref.watch(currencyProvider);
    final cartItems = ref.watch(cartProvider);
    final cartItemCount = ref.watch(cartItemCountProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // BARRE DE RECHERCHE AVEC SCANNER
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher par nom ou code-barres...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_searchQuery.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      ),
                    IconButton(
                      icon: const Icon(
                        Icons.qr_code_scanner,
                        color: Color(0xFF1E3A8A),
                      ),
                      tooltip: 'Scanner un code-barres',
                      onPressed: () async {
                        final codeScanne =
                            await showModalBottomSheet<String>(
                          context: context,
                          isScrollControlled: true,
                          builder: (modalContext) => QuickScannerWidget(
                            onCodeScanned: (code) {
                              Navigator.of(modalContext).pop(code);
                            },
                          ),
                        );

                        if (codeScanne != null &&
                            codeScanne.isNotEmpty &&
                            context.mounted) {
                          produitsAsync.whenData((produits) {
                            _traiterCodeScanne(codeScanne, produits);
                          });
                        }
                      },
                    ),
                  ],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim().toLowerCase();
                });
              },
            ),
            const SizedBox(height: 8),

            // CONTENU DYNAMIQUE (LISTE DES PRODUITS ET CATÉGORIES)
            Expanded(
              child: produitsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Erreur : $err',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ),
                data: (produits) {
                  // Extraction dynamique des catégories
                  final Set<String> categoriesSet = {'Tous'};
                  for (final p in produits) {
                    if (p.categorie.trim().isNotEmpty) {
                      categoriesSet.add(p.categorie.trim());
                    }
                  }

                  // Filtrage combiné (Recherche + Catégorie)
                  final produitsFiltres = produits.where((produit) {
                    final matchNom =
                        produit.nom.toLowerCase().contains(_searchQuery);
                    final matchCodeBarre =
                        produit.codeBarre.toLowerCase().contains(_searchQuery);
                    final matchSearch = matchNom || matchCodeBarre;
                    final matchCategory = _selectedCategory == 'Tous' ||
                        produit.categorie.trim().toLowerCase() ==
                            _selectedCategory.trim().toLowerCase();

                    return matchSearch && matchCategory;
                  }).toList();

                  if (produits.isEmpty) {
                    return const Center(
                      child: Text(
                        'Aucun produit enregistré dans la base de données.',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // FILTRE PAR CATÉGORIE
                      SizedBox(
                        height: 40,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: categoriesSet.map((category) {
                            final isSelected = _selectedCategory == category;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6.0),
                              child: ChoiceChip(
                                label: Text(category),
                                selected: isSelected,
                                selectedColor: const Color(0xFF1E3A8A),
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                onSelected: (bool selected) {
                                  setState(() {
                                    _selectedCategory = category;
                                  });
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // LISTE FILTRÉE DES ARTICLES
                      Expanded(
                        child: produitsFiltres.isEmpty
                            ? const Center(
                                child: Text(
                                  'Aucun produit ne correspond à votre recherche.',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: produitsFiltres.length,
                                itemBuilder: (context, index) {
                                  final produit = produitsFiltres[index];
                                  final bool enRupture = produit.quantite <= 0;

                                  final double prixBase =
                                      (produit.prixVente as num).toDouble();
                                  final String prixTexte =
                                      currencyState.formatPrice(prixBase);

                                  return Card(
                                    elevation: 1.5,
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 4.0,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                      child: ListTile(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 2,
                                        ),
                                        title: Text(
                                          produit.nom.isNotEmpty
                                              ? produit.nom
                                              : 'Sans nom',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: enRupture
                                                ? Colors.grey
                                                : Colors.black87,
                                          ),
                                        ),
                                        subtitle: Wrap(
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          spacing: 8,
                                          children: [
                                            Text(
                                              'Code: ${produit.codeBarre.isEmpty ? "N/A" : produit.codeBarre}',
                                              style:
                                                  const TextStyle(fontSize: 12),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: enRupture
                                                    ? Colors.red.shade100
                                                    : (produit.quantite < 5
                                                        ? Colors.orange.shade100
                                                        : Colors
                                                            .green.shade100),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'Stock: ${produit.quantite}',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: enRupture
                                                      ? Colors.red.shade800
                                                      : (produit.quantite < 5
                                                          ? Colors.orange
                                                              .shade900
                                                          : Colors
                                                              .green.shade800),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              prixTexte,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: enRupture
                                                    ? Colors.grey
                                                    : Colors.indigo.shade800,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            IconButton(
                                              icon: Icon(
                                                Icons.add_shopping_cart,
                                                color: enRupture
                                                    ? Colors.grey
                                                    : Colors.blue,
                                              ),
                                              onPressed: enRupture
                                                  ? null
                                                  : () async {
                                                      final added =
                                                          await showDialog<
                                                              bool>(
                                                        context: context,
                                                        builder: (dialogContext) =>
                                                            AjoutPanierDialog(
                                                          produit: produit,
                                                        ),
                                                      );

                                                      if (added == true &&
                                                          context.mounted) {
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                              '${produit.nom} ajouté au panier !',
                                                            ),
                                                            behavior:
                                                                SnackBarBehavior
                                                                    .floating,
                                                            duration:
                                                                const Duration(
                                                              seconds: 2,
                                                            ),
                                                          ),
                                                        );
                                                      }
                                                    },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // BOUTON FLOTTANT D'OUVERTURE DU PANIER
      floatingActionButton: cartItems.isNotEmpty
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFF1E3A8A),
              icon: const Icon(
                Icons.shopping_cart_checkout,
                color: Colors.white,
              ),
              label: Text(
                'Panier ($cartItemCount)',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  builder: (context) => const FractionallySizedBox(
                    heightFactor: 0.85,
                    child: PanierView(),
                  ),
                );
              },
            )
          : null,
    );
  }
}

// -----------------------------------------------------------------------------
// VUE DU PANIER AVEC DÉCLENCHEMENT DE PAIEMENTDIALOG
// -----------------------------------------------------------------------------
class PanierView extends ConsumerWidget {
  const PanierView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final totalUSD = ref.watch(cartTotalProvider);
    final currencyState = ref.watch(currencyProvider);

    if (cartItems.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Panier d\'achat')),
        body: const Center(
          child: Text('Votre panier est vide'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Panier (${cartItems.length} références)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Vider le panier',
            onPressed: () {
              ref.read(cartProvider.notifier).clearCart();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // LISTE DES ARTICLES DANS LE PANIER
          Expanded(
            child: ListView.separated(
              itemCount: cartItems.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = cartItems[index];
                final prixConverti = currencyState.formatPrice(item.prix);
                final totalLigne = currencyState.formatPrice(item.totalPrice);

                return ListTile(
                  title: Text(
                    item.nom,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle:
                      Text('$prixConverti x ${item.quantite} = $totalLigne'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () {
                          ref
                              .read(cartProvider.notifier)
                              .decrementProduct(item.id);
                        },
                      ),
                      Text(
                        '${item.quantite}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () {
                          final result =
                              ref.read(cartProvider.notifier).addProduct(
                                    item.id,
                                    item.nom,
                                    item.prix,
                                    1,
                                    item.stock,
                                  );

                          if (result == CartOperationResult.stockLimitReached) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Limite du stock atteinte (${item.stock})',
                                ),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // BARRE INFERIEURE AVEC BOUTON D'ENCAISSEMENT
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total à payer :',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        currencyState.formatPrice(totalUSD),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade800,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.payments),
                      label: const Text(
                        'ENCAISSER / PAYER',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () {
                        final entreprise = ref.read(entrepriseProvider);
                        final authState = ref.read(authProvider);
                        final userId = authState.user?.uid ?? '';
                        final String entrepriseId = entreprise.id;

                        if (entrepriseId.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Erreur : Aucune entreprise sélectionnée.',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => PaiementDialog(
                            total: totalUSD,
                            cart: cartItems,
                            entrepriseId: entrepriseId,
                            userId: userId,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}