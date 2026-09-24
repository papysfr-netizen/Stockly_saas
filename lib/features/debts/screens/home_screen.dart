import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/user_model.dart';
import '../../../core/providers/currency_provider.dart';
import '../../../core/providers/produit_provider.dart';
import '../../../core/services/packing_list_service.dart';
import '../../../views/caisse/caisse_screen.dart';
import '../../../views/financial_analysis/financial_analysis_screen.dart';
import '../../../core/widgets/add_product_modal.dart';
import 'comptabilite_screen.dart';
import 'debt_management_screen.dart';
import 'depenses_screen.dart';
import 'package:stockly_saas/screens/settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final UserModel currentUser;
  const HomeScreen({super.key, required this.currentUser});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  bool _isImporting = false;
  String _importProgressText = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _supprimerProduit(String id) async {
    try {
      await FirebaseFirestore.instance
          .collection('produits')
          .doc(id)
          .delete();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la suppression : $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _importerExcel() async {
    if (widget.currentUser.entrepriseId.isEmpty) return;

    setState(() {
      _isImporting = true;
      _importProgressText = "Analyse...";
    });

    try {
      final count = await PackingListService().importerExcel(
        entrepriseId: widget.currentUser.entrepriseId,
        onProgress: (traites, total) {
          if (mounted) {
            setState(() {
              _importProgressText = "$traites / $total";
            });
          }
        },
      );

      if (!mounted) return;
      if (count > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$count produit(s) importé(s) ou mis à jour avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur d\'importation : $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
          _importProgressText = "";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
   final currencyState = ref.watch(currencyProvider);
    // Utilise .name si c'est un Enum, ou adapte selon ton modèle (ex: currencyState.toString() ne marchait pas car c'était l'instance, mais tu peux cibler .name)
    final String currency = currencyState.activeCurrencyInfo.symbol;
    final produitsAsync = ref.watch(produitsStreamProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Stockly Pro",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              "Connecté: ${widget.currentUser.nom}",
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          if (widget.currentUser.isAdmin) ...[
            _isImporting
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        ),
                        if (_importProgressText.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            _importProgressText,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ],
                      ],
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.file_upload_outlined),
                    tooltip: 'Importer Excel / CSV / Packing List',
                    onPressed: _importerExcel,
                  ),
          ],
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Paramètres',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: Column(
        children: [
          // ================= 1. MENU ACCÈS RAPIDE =================
          Container(
            color: Colors.blue.shade800,
            padding: const EdgeInsets.only(left: 12, right: 12, bottom: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildNavBtn(
                    icon: Icons.point_of_sale,
                    label: 'Caisse POS',
                    bgColor: Colors.white,
                    fgColor: Colors.blue.shade800,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CaisseScreen()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildNavBtn(
                    icon: Icons.account_balance_wallet,
                    label: 'Dépenses',
                    bgColor: Colors.redAccent.shade100,
                    fgColor: Colors.red.shade900,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const DepensesScreen()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildNavBtn(
                    icon: Icons.menu_book,
                    label: 'Dettes',
                    bgColor: Colors.orange.shade100,
                    fgColor: Colors.orange.shade900,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const DebtManagementScreen()),
                    ),
                  ),
                  if (widget.currentUser.isAdmin) ...[
                    const SizedBox(width: 8),
                    _buildNavBtn(
                      icon: Icons.analytics,
                      label: 'P&L Net',
                      bgColor: Colors.indigo.shade100,
                      fgColor: Colors.indigo.shade900,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const FinancialAnalysisScreen()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildNavBtn(
                      icon: Icons.calculate,
                      label: 'Comptabilité',
                      bgColor: Colors.teal.shade100,
                      fgColor: Colors.teal.shade900,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ComptabiliteScreen(
                            entrepriseId: widget.currentUser.entrepriseId,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ================= 2. BARRE DE RECHERCHE =================
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
              decoration: InputDecoration(
                hintText: "Rechercher un produit...",
                prefixIcon: const Icon(Icons.search, color: Colors.blue),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = "");
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),

          // ================= 3. LISTE ET STATISTIQUES =================
          Expanded(
            child: produitsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Text("Erreur de chargement : $err"),
              ),
              data: (produits) {
                final filteredDocs = produits.where((p) {
                  final nom = p.nom.toLowerCase();
                  final code = p.codeBarre.toLowerCase();
                  return nom.contains(_searchQuery) || code.contains(_searchQuery);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(
                    child: Text("Aucun produit trouvé.",
                        style: TextStyle(color: Colors.grey)),
                  );
                }

                final double valeurTotale = filteredDocs.fold(0.0, (acc, item) {
                  return acc + (item.prixVente * item.quantite);
                });

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          _buildStatCard("Produits", "${filteredDocs.length}",
                              Icons.inventory_2, Colors.blue),
                          if (widget.currentUser.isAdmin) ...[
                            const SizedBox(width: 12),
                            _buildStatCard(
                              "Valeur Stock",
                              "${valeurTotale.toStringAsFixed(0)} $currency",
                              Icons.monetization_on,
                              Colors.green,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredDocs.length,
                        padding: const EdgeInsets.only(bottom: 80),
                        itemBuilder: (context, index) {
                          final produit = filteredDocs[index];

                          final produitWidget = ProduitCard(
                            nom: produit.nom.isNotEmpty ? produit.nom : 'Sans nom',
                            quantite: produit.quantite,
                            prix: produit.prixVente.toDouble(),
                            currency: currency,
                            imageUrl: produit.imageUrl,
                            onEdit: widget.currentUser.isAdmin
                                ? () {
                                    AddProductModal.show(
                                      context,
                                      entrepriseId: widget.currentUser.entrepriseId,
                                      product: produit.toJson(),
                                      id: produit.id,
                                    );
                                  }
                                : null,
                          );

                          if (widget.currentUser.isAdmin) {
                            return Dismissible(
                              key: Key(produit.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                color: Colors.red,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                child: const Icon(Icons.delete, color: Colors.white),
                              ),
                              confirmDismiss: (_) async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Supprimer le produit'),
                                    content: const Text(
                                        'Voulez-vous vraiment supprimer ce produit ?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, false),
                                        child: const Text('Annuler'),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red),
                                        onPressed: () => Navigator.pop(ctx, true),
                                        child: const Text('Supprimer',
                                            style: TextStyle(color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                );
                                return confirm ?? false;
                              },
                              onDismissed: (_) => _supprimerProduit(produit.id),
                              child: produitWidget,
                            );
                          }

                          return produitWidget;
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
      floatingActionButton: widget.currentUser.isAdmin
          ? FloatingActionButton.extended(
              backgroundColor: Colors.blue.shade800,
              onPressed: () => AddProductModal.show(
                context,
                entrepriseId: widget.currentUser.entrepriseId,
              ),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Nouveau Produit',
                  style: TextStyle(color: Colors.white)),
            )
          : null,
    );
  }

  Widget _buildNavBtn({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color fgColor,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: fgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      onPressed: onTap,
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.1),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: color),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProduitCard extends StatelessWidget {
  final String nom;
  final int quantite;
  final double prix;
  final String currency;
  final String? imageUrl;
  final VoidCallback? onEdit;

  const ProduitCard({
    super.key,
    required this.nom,
    required this.quantite,
    required this.prix,
    required this.currency,
    this.imageUrl,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLowStock = quantite <= 5;
    final String priceText = prix.truncateToDouble() == prix
        ? prix.toInt().toString()
        : prix.toStringAsFixed(2);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor:
                    isLowStock ? Colors.orange.shade50 : Colors.blue.shade50,
                backgroundImage: imageUrl != null && imageUrl!.isNotEmpty
                    ? NetworkImage(imageUrl!)
                    : null,
                child: imageUrl == null || imageUrl!.isEmpty
                    ? Icon(Icons.inventory_2,
                        color: isLowStock ? Colors.orange : Colors.blue, size: 20)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nom,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          "Stock: $quantite",
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade700),
                        ),
                        if (isLowStock) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                  color: Colors.red.shade200, width: 0.5),
                            ),
                            child: const Text(
                              'Alerte stock',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "$priceText $currency",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                      fontSize: 14,
                    ),
                  ),
                  if (onEdit != null) ...[
                    const SizedBox(width: 2),
                    IconButton(
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(6),
                      icon: const Icon(Icons.edit, color: Colors.orange, size: 18),
                      onPressed: onEdit,
                      tooltip: 'Modifier',
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}