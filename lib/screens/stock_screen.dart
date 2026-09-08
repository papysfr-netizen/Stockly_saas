import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/currency_provider.dart';
import '../providers/produit_provider.dart';
import '../providers/user_role_provider.dart';
import '../services/packing_list_service.dart';
import '../widgets/add_product_modal.dart';

// ============================================================================
// 1. CONTROLLER & LOGIQUE D'IMPORTATION (ISOLATION MULTI-TENANT)
// ============================================================================

final stockControllerProvider =
    AsyncNotifierProvider.family<StockController, void, String>(
  StockController.new,
);

class StockController extends FamilyAsyncNotifier<void, String> {
  @override
  Future<void> build(String arg) async {}

  /// Importation du fichier Packing List (Excel) pour l'organisation
  Future<int> importerPackingList() async {
    final entrepriseId = arg;
    if (entrepriseId.isEmpty) {
      throw Exception('Identifiant d\'entreprise introuvable.');
    }

    state = const AsyncValue.loading();
    try {
      final packingService = PackingListService();
      final count = await packingService.importerExcel(entrepriseId: entrepriseId);
      
      // Actualisation du flux de produits
      ref.invalidate(produitsStreamProvider);
      
      state = const AsyncValue.data(null);
      return count;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}

// ============================================================================
// 2. ÉCRAN DE GESTION DU STOCK (PRESENTATION LAYER)
// ============================================================================

class StockScreen extends ConsumerStatefulWidget {
  const StockScreen({super.key});

  @override
  ConsumerState<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends ConsumerState<StockScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Ouvre la modale d'édition pour le produit sélectionné
  void _modifierProduit(
    BuildContext context,
    String entrepriseId,
    dynamic produit,
  ) {
    AddProductModal.show(
      context,
      entrepriseId: entrepriseId,
      id: produit.id,
      product: produit.toJson(),
    );
  }

  /// Déclenche l'importation via le controller Riverpod
  Future<void> _importerPackingList(
    BuildContext context,
    String entrepriseId,
  ) async {
    try {
      final count = await ref
          .read(stockControllerProvider(entrepriseId).notifier)
          .importerPackingList();

      if (!context.mounted) return;

      if (count > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$count produit(s) importé(s) avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aucun produit importé ou sélection annulée.'),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur d\'importation : $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final currency = ref.watch(currencyProvider);

    return profileAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        body: Center(child: Text('Erreur de profil : $err')),
      ),
      data: (userProfile) {
        final String entrepriseId = userProfile.entrepriseId;
        final String roleStr = userProfile.role.toString().toLowerCase();

        final bool canEdit = userProfile.role.isOwner ||
            roleStr.contains('admin') ||
            (userProfile.permissions['canAddProduct'] == true);

        final controllerState = ref.watch(stockControllerProvider(entrepriseId));
        final produitsAsync = ref.watch(produitsStreamProvider);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Gestion du Stock'),
            actions: [
              if (canEdit) ...[
                if (controllerState.isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.file_upload_outlined),
                    tooltip: 'Importer Packing List',
                    onPressed: entrepriseId.isEmpty
                        ? null
                        : () => _importerPackingList(context, entrepriseId),
                  ),
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: 'Nouveau Produit',
                  onPressed: entrepriseId.isEmpty
                      ? null
                      : () => AddProductModal.show(
                            context,
                            entrepriseId: entrepriseId,
                          ),
                ),
              ],
            ],
          ),
          body: Column(
            children: [
              // BARRE DE RECHERCHE
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.trim().toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Rechercher un produit...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),

              // LISTE DES PRODUITS
              Expanded(
                child: Stack(
                  children: [
                    produitsAsync.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'Erreur lors du chargement : $err',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      ),
                      data: (produits) {
                        final produitsFiltres = produits.where((p) {
                          final query = _searchQuery.toLowerCase();
                          return p.nom.toLowerCase().contains(query) ||
                              p.codeBarre.toLowerCase().contains(query);
                        }).toList();

                        if (produitsFiltres.isEmpty) {
                          return Center(
                            child: Text(
                              _searchQuery.isEmpty
                                  ? 'Aucun produit enregistré pour votre entreprise.'
                                  : 'Aucun produit ne correspond à "$_searchQuery".',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          );
                        }

                        return ListView.separated(
                          itemCount: produitsFiltres.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final produit = produitsFiltres[index];
                            final double prixAffiche = produit.prixVente.toDouble();

                            return Material(
                              color: Colors.transparent,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: produit.imageUrl != null &&
                                          produit.imageUrl!.isNotEmpty
                                      ? NetworkImage(produit.imageUrl!)
                                      : null,
                                  child: produit.imageUrl == null ||
                                          produit.imageUrl!.isEmpty
                                      ? const Icon(Icons.shopping_bag)
                                      : null,
                                ),
                                title: Text(
                                  produit.nom.isNotEmpty ? produit.nom : 'Sans nom',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    Text('Stock: ${produit.quantite}'),
                                    if (produit.codeBarre.isNotEmpty)
                                      Text('| Code: ${produit.codeBarre}'),
                                    if (produit.quantite <= produit.seuilAlerte)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade50,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'Alerte stock',
                                          style: TextStyle(
                                            color: Colors.red.shade700,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${prixAffiche.toStringAsFixed(1)} $currency',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.indigo.shade900,
                                      ),
                                    ),
                                    if (canEdit)
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          size: 20,
                                          color: Colors.orange,
                                        ),
                                        onPressed: () => _modifierProduit(
                                          context,
                                          entrepriseId,
                                          produit,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                    if (controllerState.isLoading)
                      Container(
                        color: Colors.black26,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: canEdit
              ? FloatingActionButton.extended(
                  onPressed: entrepriseId.isEmpty
                      ? null
                      : () => AddProductModal.show(
                            context,
                            entrepriseId: entrepriseId,
                          ),
                  icon: const Icon(Icons.add),
                  label: const Text('Nouveau Produit'),
                )
              : null,
        );
      },
    );
  }
}