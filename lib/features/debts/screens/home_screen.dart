import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stockly_saas/core/services/journal_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:stockly_saas/features/boutiques/boutique_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/user_model.dart';
import '../../../core/providers/user_role_provider.dart';
import '../../../core/providers/currency_provider.dart';
import '../../../core/providers/produit_provider.dart';
import '../../../core/providers/entreprise_provider.dart';
import '../../../core/services/packing_list_service.dart';
import '../../../core/widgets/add_product_modal.dart';
import '../../../core/widgets/changer_mot_de_passe_dialog.dart';
import 'package:stockly_saas/l10n/app_localizations.dart';

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
  bool _voirEpuises = false; // 📦 false = seulement les produits en stock

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

  AppLocalizations get _t => AppLocalizations.of(context);

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
    final t = _t;
    final entrepriseId = widget.currentUser.entrepriseId;
    if (entrepriseId.isEmpty || id.isEmpty) return;

    // 📒 Ce que contenait le produit avant suppression (pour le journal)
    var infoProduit = nom;
    try {
      final avant = await FirebaseFirestore.instance
          .collection('entreprises')
          .doc(entrepriseId)
          .collection('produits')
          .doc(id)
          .get(const GetOptions(source: Source.cache));
      final d = avant.data();
      if (d != null) {
        final code = (d['codeBarre'] ?? d['codeBarres'] ?? '').toString().trim();
        infoProduit = '${code.isEmpty ? '' : '$code · '}$nom · '
            'stock total ${d['quantite'] ?? '?'}';
      }
    } catch (_) {
      // Pas dans le téléphone : on garde seulement le nom.
    }
    void noterSuppression() => unawaited(noterJournal(
          entrepriseId: entrepriseId,
          action: ActionsJournal.produitSupprime,
          details: infoProduit,
          boutiqueId: 'Toutes',
          reference: id,
        ));

    try {
      await FirebaseFirestore.instance
          .collection('entreprises')
          .doc(entrepriseId)
          .collection('produits')
          .doc(id)
          .delete()
          .timeout(const Duration(seconds: 5));
      noterSuppression();
      messenger.showSnackBar(
        SnackBar(
          content: Text(t.stockDeleted(nom)),
          backgroundColor: Colors.green.shade700,
        ),
      );
    } on TimeoutException {
      noterSuppression();
      messenger.showSnackBar(
        SnackBar(
          content: Text(t.stockDeletedOffline(nom)),
          backgroundColor: Colors.orange.shade800,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(t.stockDeleteError('$e')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _importerExcel() async {
    if (widget.currentUser.entrepriseId.isEmpty) return;

    setState(() {
      _isImporting = true;
      _importProgressText = _t.stockAnalyzing;
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
            content: Text(_t.stockImported(count)),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_t.stockImportError('$e')),
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
    final t = _t;

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF121418) : Colors.grey.shade50,
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
                    t.stockConnected(widget.currentUser.nom),
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
                    tooltip: t.stockImportTooltip,
                    onPressed: _importerExcel,
                  ),
          ],
          // 👤 Mon compte : tout le monde (mot de passe + déconnexion)
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle),
            tooltip: t.myAccount,
            onSelected: (choix) {
              if (choix == 'mdp') {
                ChangerMotDePasseDialog.show(context);
              } else if (choix == 'deco') {
                FirebaseAuth.instance.signOut();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'mdp',
                child: ListTile(
                  leading: const Icon(Icons.lock_reset),
                  title: Text(t.changePassword),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'deco',
                child: ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: Text(t.logout),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // ================= 2. BARRE DE RECHERCHE =================
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
              decoration: InputDecoration(
                hintText: t.caisseSearch,
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
                fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF22262E) : Colors.white,
              ),
            ),
          ),

          // ================= 3. LISTE ET STATISTIQUES =================
          Expanded(
            child: produitsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Text(t.debtLoadError('$err')),
              ),
              data: (produits) {
                // 🏬 Boutique affichée (null = toutes les boutiques)
                final boutique = ref.watch(boutiqueActiveProvider);
                final filteredDocs = produits.where((p) {
                  final nom = p.nom.toLowerCase();
                  final code = p.codeBarre.toLowerCase();
                  return nom.contains(_searchQuery) || code.contains(_searchQuery);
                }).toList();

                // 📦 Produits à 0 cachés ; le bouton « Voir les épuisés » montre seulement eux
                final nbEpuises =
                    filteredDocs.where((p) => p.stockBoutique(boutique) <= 0).length;
                if (_voirEpuises) {
                  filteredDocs.retainWhere((p) => p.stockBoutique(boutique) <= 0);
                } else {
                  filteredDocs.removeWhere((p) => p.stockBoutique(boutique) <= 0);
                }

                if (filteredDocs.isEmpty) {
                  return Column(
                    children: [
                      _chipEpuises(nbEpuises),
                      Expanded(
                        child: Center(
                          child: Text(t.stockNoProduct,
                              style: const TextStyle(color: Colors.grey)),
                        ),
                      ),
                    ],
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
                          _buildStatCard(t.stockProducts, "${filteredDocs.length}",
                              Icons.inventory_2, Colors.blue),
                          // 💰 Valeur du stock : Propriétaire + Gérant
                          if (_peutVoirFinances) ...[
                            const SizedBox(width: 12),
                            _buildStatCard(
                              t.stockValue,
                              "${valeurTotale.toStringAsFixed(0)} $currency",
                              Icons.monetization_on,
                              Colors.green,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _chipEpuises(nbEpuises),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredDocs.length,
                        padding: const EdgeInsets.only(bottom: 80),
                        itemBuilder: (context, index) {
                          final produit = filteredDocs[index];

                          final produitWidget = ProduitCard(
                            nom: '${produit.codeBarre.trim().isEmpty ? '' : '${produit.codeBarre.trim()} · '}' // 🏷️ code devant le nom
                                '${produit.nom.isNotEmpty ? produit.nom : t.caisseNoName}',
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
                                      boutiqueId: ref.read(boutiqueActiveProvider), // 🏬
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
                                      title: Text(t.stockCannotDelete),
                                      content: Text(t.stockCannotDeleteMsg(produit.nom, produit.quantite)),
                                      actions: [
                                        ElevatedButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: Text(t.payUnderstood),
                                        ),
                                      ],
                                    ),
                                  );
                                  return false;
                                }
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: Text(t.stockDeleteTitle),
                                    content: Text(t.stockDeleteConfirm(produit.nom)),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, false),
                                        child: Text(t.cancel),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                        onPressed: () => Navigator.pop(ctx, true),
                                        child: Text(t.delete, style: const TextStyle(color: Colors.white)),
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
                boutiqueId: ref.read(boutiqueActiveProvider), // 🏬
              ),
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(t.stockNewProduct,
                  style: const TextStyle(color: Colors.white)),
            )
          : null,
    );
  }


  /// 📦 Bouton : voir les produits épuisés / revenir aux produits en stock
  Widget _chipEpuises(int nb) {
    if (nb == 0 && !_voirEpuises) return const SizedBox(height: 4);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FilterChip(
          avatar: Icon(
            _voirEpuises ? Icons.inventory_2 : Icons.remove_shopping_cart,
            size: 16,
            color: _voirEpuises ? Colors.blue : Colors.red,
          ),
          label: Text(_voirEpuises ? _t.stockShowInStock : _t.stockShowOut(nb)),
          selected: _voirEpuises,
          onSelected: (v) => setState(() => _voirEpuises = v),
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1C1F26) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2A2E37) : Colors.grey.shade200),
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
        side: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2A2E37) : Colors.grey.shade200),
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
                    Theme.of(context).brightness == Brightness.dark
                        ? (isLowStock ? const Color(0xFF3A2A14) : const Color(0xFF1E2A4A))
                        : (isLowStock ? Colors.orange.shade50 : Colors.blue.shade50),
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
                          AppLocalizations.of(context).stockQty(quantite),
                          style: TextStyle(
                              fontSize: 12, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade700),
                        ),
                        if (isLowStock) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF3A1A1A) : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                  color: Colors.red.shade200, width: 0.5),
                            ),
                            child: Text(
                              AppLocalizations.of(context).stockAlert,
                              style: const TextStyle(
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
                      tooltip: AppLocalizations.of(context).edit,
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