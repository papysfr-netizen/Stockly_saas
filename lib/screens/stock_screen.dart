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
      
      // Invalidation directe dans le contrôleur pour réactualiser le flux de produits
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

class StockScreen extends ConsumerWidget {
  const StockScreen({super.key});

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
    WidgetRef ref,
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
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileProvider).value;
    final currency = ref.watch(currencyProvider);

    final String entrepriseId = userProfile?.entrepriseId ?? '';
    final String roleStr = userProfile?.role.toString().toLowerCase() ?? '';

    // Vérification sécurisée des droits d'édition
    final bool canEdit = (userProfile?.role.isOwner == true) ||
        roleStr.contains('admin') ||
        (userProfile?.permissions['canAddProduct'] == true);

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
                    : () => _importerPackingList(context, ref, entrepriseId),
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
      body: Stack(
        children: [
          produitsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(
              child: Text('Erreur lors du chargement : $err'),
            ),
            data: (produits) {
              if (produits.isEmpty) {
                return const Center(
                  child: Text('Aucun produit enregistré pour votre entreprise.'),
                );
              }

              return ListView.builder(
                itemCount: produits.length,
                itemBuilder: (context, index) {
                  final produit = produits[index];
                  final double prixAffiche = produit.prixVente.toDouble();

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: produit.imageUrl != null &&
                              produit.imageUrl!.isNotEmpty
                          ? NetworkImage(produit.imageUrl!)
                          : null,
                      child: produit.imageUrl == null || produit.imageUrl!.isEmpty
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
                            icon: const Icon(Icons.edit, size: 20, color: Colors.orange),
                            onPressed: () => _modifierProduit(
                              context,
                              entrepriseId,
                              produit,
                            ),
                          ),
                      ],
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
  }
}