import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stockly_saas/features/boutiques/boutique_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stockly_saas/core/models/produit.dart';
import 'package:stockly_saas/core/providers/cart_provider.dart';
import 'package:stockly_saas/core/providers/currency_provider.dart';
import 'package:stockly_saas/core/providers/user_role_provider.dart';
import 'package:stockly_saas/core/providers/produit_provider.dart';
import 'package:stockly_saas/views/caisse/dialogs/ajout_panier_dialog.dart';
import 'package:stockly_saas/views/caisse/dialogs/prix_negocie_dialog.dart';
import 'package:stockly_saas/views/caisse/dialogs/paiement_dialog.dart';
import 'package:stockly_saas/core/widgets/quick_scanner_widget.dart';

// =============================================================================
// 🧾 CAISSE EN 3 TOUCHES
//  1. Toucher la tuile d'un produit = +1 dans le panier (appui long = quantité / prix)
//  2. Gros bouton vert « Encaisser » toujours visible en bas
//  3. Paiement (dollars + francs + monnaie à rendre)
// =============================================================================

const _bleuNuit = Color(0xFF1E3A8A);
const _vert = Color(0xFF0B7A5A);

// Couleurs des tuiles (choisie selon le nom du produit : toujours la même)
const _couleursTuiles = <Color>[
  Color(0xFF2563EB),
  Color(0xFF0B7A5A),
  Color(0xFFD97706),
  Color(0xFF7C3AED),
  Color(0xFFDB2777),
  Color(0xFF0891B2),
  Color(0xFF65A30D),
  Color(0xFFDC2626),
];

Color _couleurPour(String nom) =>
    _couleursTuiles[nom.trim().toUpperCase().hashCode.abs() % _couleursTuiles.length];

String _initiales(String nom) {
  final mots = nom.trim().split(RegExp(r'[\s#\-_/]+')).where((m) => m.isNotEmpty).toList();
  if (mots.isEmpty) return '?';
  if (mots.length == 1) return mots.first.substring(0, mots.first.length >= 2 ? 2 : 1).toUpperCase();
  return (mots[0][0] + mots[1][0]).toUpperCase();
}

/// Ouvre directement la fenêtre de paiement pour le panier actuel
void ouvrirPaiementCaisse(BuildContext context, WidgetRef ref) {
  final cartItems = ref.read(cartProvider);
  final totalUSD = ref.read(cartTotalProvider);
  // L'entreprise et l'utilisateur viennent du PROFIL connecté (toujours les bons)
  final profil = ref.read(userProfileProvider).value;
  final String entrepriseId = profil?.entrepriseId ?? '';
  final userId = profil?.uid ?? '';

  if (cartItems.isEmpty) return;
  if (entrepriseId.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Erreur : Aucune entreprise sélectionnée.'),
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
}

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

  // ---------------------------------------------------------------------------
  // Ajout rapide : +1 dans le panier
  // ---------------------------------------------------------------------------
  void _ajouterUn(Produit produit) {
    final boutique = ref.boutiqueVente;
    final stock = produit.stockBoutique(boutique);
    final messenger = ScaffoldMessenger.of(context);

    if (stock <= 0) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(
        content: Text('${produit.nom} est en rupture de stock !'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
      return;
    }

    final prix = (produit.prixPour(boutique) as num).toDouble();
    final result = ref.read(cartProvider.notifier).addProduct(
          produit.id,
          produit.nom,
          prix,
          1,
          stock,
          prixAchat: produit.prixAchat,
        );

    if (result == CartOperationResult.stockLimitReached) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(
        content: Text('Limite du stock atteinte ($stock)'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
    } else {
      HapticFeedback.selectionClick();
    }
  }

  // Appui long : fenêtre détaillée (quantité, prix…)
  Future<void> _ajoutDetaille(Produit produit) async {
    if (produit.stockBoutique(ref.boutiqueVente) <= 0) {
      _ajouterUn(produit); // affiche le message de rupture
      return;
    }
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AjoutPanierDialog(produit: produit),
    );
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
      _ajouterUn(produit);
      if (produit.stockBoutique(ref.boutiqueVente) > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${produit.nom} ajouté au panier !'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
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

  void _ouvrirPanier() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => const FractionallySizedBox(
        heightFactor: 0.85,
        child: PanierView(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final produitsAsync = ref.watch(produitsStreamProvider);
    final currencyState = ref.watch(currencyProvider);
    final cartItems = ref.watch(cartProvider);
    final cartItemCount = ref.watch(cartItemCountProvider);
    final totalUSD = ref.watch(cartTotalProvider);
    final boutique = ref.watch(boutiqueActiveProvider) ?? 'principale';

    // Quantité de chaque produit déjà dans le panier
    final dansPanier = <String, int>{};
    for (final item in cartItems) {
      dansPanier[item.id] = (dansPanier[item.id] ?? 0) + item.quantite;
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // BARRE DE RECHERCHE AVEC SCANNER
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un produit…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_searchQuery.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.qr_code_scanner, color: _bleuNuit),
                      tooltip: 'Scanner un code-barres',
                      onPressed: () async {
                        final codeScanne = await showModalBottomSheet<String>(
                          context: context,
                          isScrollControlled: true,
                          builder: (modalContext) => QuickScannerWidget(
                            onCodeScanned: (code) {
                              Navigator.of(modalContext).pop(code);
                            },
                          ),
                        );

                        if (codeScanne != null && codeScanne.isNotEmpty && context.mounted) {
                          produitsAsync.whenData((produits) {
                            _traiterCodeScanne(codeScanne, produits);
                          });
                        }
                      },
                    ),
                  ],
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: (value) => setState(() => _searchQuery = value.trim().toLowerCase()),
            ),
            const SizedBox(height: 8),

            // CONTENU (CATÉGORIES + TUILES)
            Expanded(
              child: produitsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Erreur : $err', style: const TextStyle(color: Colors.red)),
                  ),
                ),
                data: (produits) {
                  if (produits.isEmpty) {
                    return const Center(
                      child: Text(
                        'Aucun produit enregistré.\nAjoutez vos produits dans l\'onglet « Stock ».',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  final Set<String> categoriesSet = {'Tous'};
                  for (final p in produits) {
                    if (p.categorie.trim().isNotEmpty) categoriesSet.add(p.categorie.trim());
                  }

                  final produitsFiltres = produits.where((produit) {
                    final matchSearch = produit.nom.toLowerCase().contains(_searchQuery) ||
                        produit.codeBarre.toLowerCase().contains(_searchQuery);
                    final matchCategory = _selectedCategory == 'Tous' ||
                        produit.categorie.trim().toLowerCase() ==
                            _selectedCategory.trim().toLowerCase();
                    return matchSearch && matchCategory;
                  }).toList()
                    // Produits disponibles d'abord, puis par nom
                    ..sort((a, b) {
                      final ra = a.stockBoutique(boutique) <= 0 ? 1 : 0;
                      final rb = b.stockBoutique(boutique) <= 0 ? 1 : 0;
                      if (ra != rb) return ra.compareTo(rb);
                      return a.nom.toLowerCase().compareTo(b.nom.toLowerCase());
                    });

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (categoriesSet.length > 1)
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
                                  selectedColor: _bleuNuit,
                                  labelStyle: TextStyle(
                                    color: isSelected ? Colors.white : Colors.black87,
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                  onSelected: (_) => setState(() => _selectedCategory = category),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
                        child: Text(
                          'Touchez un produit pour l\'ajouter • appui long : quantité',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ),
                      Expanded(
                        child: produitsFiltres.isEmpty
                            ? const Center(
                                child: Text(
                                  'Aucun produit ne correspond à votre recherche.',
                                  style: TextStyle(color: Colors.grey, fontSize: 14),
                                ),
                              )
                            : GridView.builder(
                                padding: const EdgeInsets.only(bottom: 12),
                                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 190,
                                  mainAxisSpacing: 8,
                                  crossAxisSpacing: 8,
                                  childAspectRatio: 0.92,
                                ),
                                itemCount: produitsFiltres.length,
                                itemBuilder: (context, index) {
                                  final produit = produitsFiltres[index];
                                  return _TuileProduit(
                                    produit: produit,
                                    stock: produit.stockBoutique(boutique),
                                    prixTexte: currencyState.formatPrice(
                                        (produit.prixPour(boutique) as num).toDouble()),
                                    quantitePanier: dansPanier[produit.id] ?? 0,
                                    onTap: () => _ajouterUn(produit),
                                    onLongPress: () => _ajoutDetaille(produit),
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

      // BARRE D'ENCAISSEMENT (toujours visible dès qu'il y a un article)
      bottomNavigationBar: cartItems.isEmpty
          ? null
          : SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Panier (voir / modifier)
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 54),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _ouvrirPanier,
                      child: Badge(
                        label: Text('$cartItemCount'),
                        backgroundColor: _bleuNuit,
                        child: const Icon(Icons.shopping_cart_outlined, color: _bleuNuit),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // ENCAISSER
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: _vert,
                          minimumSize: const Size(0, 54),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () => ouvrirPaiementCaisse(context, ref),
                        icon: const Icon(Icons.payments_rounded),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Encaisser ${currencyState.formatPrice(totalUSD)}',
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// -----------------------------------------------------------------------------
// TUILE D'UN PRODUIT
// -----------------------------------------------------------------------------
class _TuileProduit extends StatelessWidget {
  final Produit produit;
  final int stock;
  final String prixTexte;
  final int quantitePanier;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _TuileProduit({
    required this.produit,
    required this.stock,
    required this.prixTexte,
    required this.quantitePanier,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final enRupture = stock <= 0;
    final couleur = enRupture ? Colors.grey : _couleurPour(produit.nom);
    final nom = produit.nom.isNotEmpty ? produit.nom : 'Sans nom';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: quantitePanier > 0 ? _vert : Colors.grey.shade200,
              width: quantitePanier > 0 ? 2 : 1,
            ),
          ),
          padding: const EdgeInsets.all(10),
          child: Opacity(
            opacity: enRupture ? 0.55 : 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pastille de couleur avec les initiales + quantité dans le panier
                Expanded(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: couleur.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _initiales(nom),
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: couleur,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      if (quantitePanier > 0)
                        Positioned(
                          top: -6,
                          right: -6,
                          child: CircleAvatar(
                            radius: 14,
                            backgroundColor: _vert,
                            child: Text(
                              '$quantitePanier',
                              style: const TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  nom,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, height: 1.15),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          prixTexte,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: enRupture ? Colors.grey : _bleuNuit,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: enRupture
                            ? Colors.red.shade50
                            : (stock < 5 ? Colors.orange.shade50 : Colors.green.shade50),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        enRupture ? 'Épuisé' : '$stock',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: enRupture
                              ? Colors.red.shade700
                              : (stock < 5 ? Colors.orange.shade800 : Colors.green.shade800),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// VUE DU PANIER AVEC DÉCLENCHEMENT DE PAIEMENTDIALOG
// -----------------------------------------------------------------------------
class PanierView extends ConsumerWidget {
  const PanierView({super.key});

  /// 💬 Toucher une ligne : changer son prix (autorisation « Remises et retraits »)
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
    final cartItems = ref.watch(cartProvider);
    final totalUSD = ref.watch(cartTotalProvider);
    final currencyState = ref.watch(currencyProvider);

    if (cartItems.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Panier d\'achat')),
        body: const Center(child: Text('Votre panier est vide')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Panier (${cartItems.length} références)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Vider le panier',
            onPressed: () => ref.read(cartProvider.notifier).clearCart(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              itemCount: cartItems.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = cartItems[index];
                final prixConverti = currencyState.formatPrice(item.prix);
                final totalLigne = currencyState.formatPrice(item.totalPrice);

                return ListTile(
                  onTap: () => _changerPrix(context, ref, item),
                  leading: Icon(
                    Icons.sell_outlined,
                    color: item.aPerte
                        ? Colors.red
                        : (item.prixNegocie ? Colors.orange.shade800 : Colors.grey),
                  ),
                  title: Text(item.nom, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$prixConverti x ${item.quantite} = $totalLigne'),
                      if (item.prixNegocie)
                        Text(
                          'Prix normal : ${currencyState.formatPrice(item.prixNormal)}',
                          style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
                        ),
                      if (item.aPerte)
                        const Text(
                          'Vente à perte',
                          style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => ref.read(cartProvider.notifier).decrementProduct(item.id),
                      ),
                      Text('${item.quantite}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () {
                          final result = ref.read(cartProvider.notifier).addProduct(
                                item.id,
                                item.nom,
                                item.prix,
                                1,
                                item.stock,
                              );
                          if (result == CartOperationResult.stockLimitReached) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Limite du stock atteinte (${item.stock})'),
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
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: _vert,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.payments_rounded),
                  label: Text(
                    'Encaisser ${currencyState.formatPrice(totalUSD)}',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => ouvrirPaiementCaisse(context, ref),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
