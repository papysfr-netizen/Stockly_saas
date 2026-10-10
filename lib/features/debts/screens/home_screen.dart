import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:stockly_saas/features/comptes_clients/comptes_clients_screen.dart';
import 'package:stockly_saas/features/boutiques/boutique_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/user_model.dart';
import '../../../core/providers/user_role_provider.dart';
import '../../../core/providers/currency_provider.dart';
import '../../../core/providers/produit_provider.dart';
import '../../../core/providers/entreprise_provider.dart';
import '../../../core/services/packing_list_service.dart';
import '../../../views/caisse/caisse_screen.dart';
import '../../../views/financial_analysis/financial_analysis_screen.dart';
import '../../../core/widgets/add_product_modal.dart';
import '../../../core/widgets/changer_mot_de_passe_dialog.dart';
import 'comptabilite_screen.dart';
import 'debt_management_screen.dart';
import 'depenses_screen.dart';
import '../../livraisons/a_livrer_screen.dart'; // 🚚
import '../../ventes/historique_ventes_screen.dart'; // 🧾
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

  // ------------------------------------------------------------------
  // 🔐 DROITS SELON LE RÔLE
  // Propriétaire : tout
  // Gérant       : stock + finances (pas Paramètres / Équipe / Maintenance)
  // Caissier     : Caisse + Ventes + Dettes + À livrer
  // ------------------------------------------------------------------
  // Les autorisations réglées par le patron (Paramètres → Équipe).
  // Tant que le profil n'est pas chargé, on garde l'ancienne règle du rôle.
  UserProfile? get _profil {
    final p = ref.watch(userProfileProvider).value;
    return (p == null || p.uid.isEmpty) ? null : p;
  }

  bool get _peutGererStock =>
      _profil?.peutGererStock ?? widget.currentUser.isAdmin; // interrupteur « Gérer le stock »
  bool get _peutVoirFinances =>
      _profil?.peutVoirFinances ?? widget.currentUser.canAccessFinance; // interrupteur « Voir les finances »
  bool get _peutGererParametres => widget.currentUser.canManageTeam; // owner seul

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Supprime un produit de l'entreprise : entreprises/{id}/produits/{produitId}.
  /// Hors ligne : la suppression est gardée sur le téléphone
  /// et envoyée automatiquement au retour du réseau.
  Future<void> _supprimerProduit(String id, String nom) async {
    final messenger = ScaffoldMessenger.of(context);
    final entrepriseId = widget.currentUser.entrepriseId;
    if (entrepriseId.isEmpty || id.isEmpty) return;

    try {
      await FirebaseFirestore.instance
          .collection('entreprises')
          .doc(entrepriseId)
          .collection('produits')
          .doc(id)
          .delete()
          .timeout(const Duration(seconds: 5));
      messenger.showSnackBar(
        SnackBar(
          content: Text('« $nom » supprimé.'),
          backgroundColor: Colors.green.shade700,
        ),
      );
    } on TimeoutException {
      messenger.showSnackBar(
        SnackBar(
          content: Text('« $nom » supprimé sur le téléphone. Envoi dès le retour d\'internet.'),
          backgroundColor: Colors.orange.shade800,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
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
      final count = await PackingListService().importerAvecApercu(context,
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
    final String currency = currencyState.activeCurrencyInfo.symbol;
    final produitsAsync = ref.watch(produitsStreamProvider);
    ref.watch(entrepriseProvider); // 🏪 charge les infos de la boutique dès l'accueil

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
            Row(
              children: [
                Flexible(
                  child: Text(
                    "Connecté: ${widget.currentUser.nom}",
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ),
                const SizedBox(width: 8),
                // 🏬 Choix de la boutique (patron, dès 2 boutiques)
                SelecteurBoutique(entrepriseId: widget.currentUser.entrepriseId),
              ],
            ),
          ],
        ),
        actions: [
          // 📥 Import Excel : Propriétaire + Gérant
          if (_peutGererStock) ...[
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
          // ⚙️ Paramètres : Propriétaire seulement
          if (_peutGererParametres)
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
          // 👤 Mon compte : tout le monde (mot de passe + déconnexion)
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle),
            tooltip: 'Mon compte',
            onSelected: (choix) {
              if (choix == 'mdp') {
                ChangerMotDePasseDialog.show(context);
              } else if (choix == 'deco') {
                FirebaseAuth.instance.signOut();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'mdp',
                child: ListTile(
                  leading: Icon(Icons.lock_reset),
                  title: Text('Changer mon mot de passe'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'deco',
                child: ListTile(
                  leading: Icon(Icons.logout, color: Colors.red),
                  title: Text('Se déconnecter'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
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
                  // 🧾 Caisse : tout le monde
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
                  // 🧾 Historique des ventes : tout le monde
                  const SizedBox(width: 8),
                  _buildNavBtn(
                    icon: Icons.receipt_long,
                    label: 'Ventes',
                    bgColor: Colors.indigo.shade50,
                    fgColor: Colors.indigo.shade900,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HistoriqueVentesScreen(
                          entrepriseId: widget.currentUser.entrepriseId,
                        ),
                      ),
                    ),
                  ),
                  // 💸 Dépenses : Propriétaire + Gérant
                  if (_peutVoirFinances) ...[
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
                  ],
                  // 📒 Dettes : tout le monde
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
                  // 🚚 À livrer : tout le monde (avec le nombre en attente)
                  const SizedBox(width: 8),
                  ALivrerNavButton(entrepriseId: widget.currentUser.entrepriseId),
                  // 💰 Comptes clients (dépôts / avoirs) : tout le monde
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade100,
                      foregroundColor: Colors.teal.shade900,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    ),
                    icon: const Icon(Icons.account_balance_wallet, size: 18),
                    label: const Text(
                      'Comptes clients',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ComptesClientsScreen(
                          entrepriseId: widget.currentUser.entrepriseId,
                        ),
                      ),
                    ),
                  ),
                  // 📊 P&L + Comptabilité : Propriétaire + Gérant
                  if (_peutVoirFinances) ...[
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
                // 🏬 Boutique affichée (null = toutes les boutiques)
                final boutique = ref.watch(boutiqueActiveProvider);
                final filteredDocs = produits.where((p) {
                  final nom = p.nom.toLowerCase();
                  final code = p.codeBarre.toLowerCase();
                  return nom.contains(_searchQuery) || code.contains(_searchQuery);
                }).toList();

                // 🏬 Boutique précise : produits en stock d'abord, ruptures à la fin
                if (boutique != null) {
                  final enStock =
                      filteredDocs.where((p) => p.stockBoutique(boutique) > 0).toList();
                  final sansStock =
                      filteredDocs.where((p) => p.stockBoutique(boutique) <= 0).toList();
                  filteredDocs
                    ..clear()
                    ..addAll(enStock)
                    ..addAll(sansStock);
                }

                if (filteredDocs.isEmpty) {
                  return const Center(
                    child: Text("Aucun produit trouvé.",
                        style: TextStyle(color: Colors.grey)),
                  );
                }

                final double valeurTotale = filteredDocs.fold(0.0, (acc, item) {
                  return acc + (item.prixPour(boutique) * item.stockBoutique(boutique));
                });

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          _buildStatCard("Produits", "${filteredDocs.length}",
                              Icons.inventory_2, Colors.blue),
                          // 💰 Valeur du stock : Propriétaire + Gérant
                          if (_peutVoirFinances) ...[
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
                            quantite: produit.stockBoutique(boutique),
                            prix: produit.prixPour(boutique),
                            currency: currency,
                            imageUrl: produit.imageUrl,
                            // ✏️ Modifier : Propriétaire + Gérant
                            onEdit: _peutGererStock
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

                          // 🗑️ Supprimer (glisser) : Propriétaire + Gérant
                          if (_peutGererStock) {
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
                                // 🛑 Produit avec du stock : suppression refusée
                                if (produit.quantite > 0) {
                                  await showDialog<void>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Suppression impossible'),
                                      content: Text(
                                          '« ${produit.nom} » a encore ${produit.quantite} article(s) en stock.\n\n'
                                          'Mettez d\'abord le stock à 0 (inventaire ou perte), '
                                          'pour que la perte reste visible dans les comptes.'),
                                      actions: [
                                        ElevatedButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: const Text('Compris'),
                                        ),
                                      ],
                                    ),
                                  );
                                  return false;
                                }
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Supprimer le produit'),
                                    content: Text(
                                        'Voulez-vous vraiment supprimer « ${produit.nom} » ?\n\nCette action est définitive.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, false),
                                        child: const Text('Annuler'),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                        onPressed: () => Navigator.pop(ctx, true),
                                        child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await _supprimerProduit(produit.id, produit.nom);
                                }
                                // On ne retire jamais la carte nous-mêmes : la liste se met à jour
                                // toute seule quand la suppression est faite (plus d'écran rouge).
                                return false;
                              },
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
      // ➕ Nouveau produit : Propriétaire + Gérant
      floatingActionButton: _peutGererStock
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