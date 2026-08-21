import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/report_export_service.dart';
import '../services/receipt_service.dart';

import '../providers/produit_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/user_role_provider.dart';
import '../repositories/vente_repository.dart';
import '../models/produit.dart';
import '../models/vente.dart';
import 'settings_screen.dart';

final venteRepositoryProvider = Provider<VenteRepository>((ref) => VenteRepository());

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
        body: Center(child: Text('Erreur de chargement du profil : $err')),
      ),
      data: (profile) {
        final entrepriseId = profile.entrepriseId;
        final userId = profile.uid;
        final canAddProduct = profile.can('canAddProduct');

        final cart = ref.watch(cartProvider);
        final cartNotifier = ref.read(cartProvider.notifier);
        final totalAmount = ref.watch(cartTotalProvider);
        final totalItemsCount = ref.watch(cartItemCountProvider);
        final currency = ref.watch(currencyProvider);

        return LayoutBuilder(
          builder: (context, constraints) {
            final bool isMobile = constraints.maxWidth < 700;

            return Scaffold(
              appBar: AppBar(
                title: const Text('Caisse / Point de Vente'),
                actions: [
                  if (canAddProduct)
                    IconButton(
                      icon: const Icon(Icons.add_box, size: 28),
                      tooltip: 'Nouveau Produit en Stock',
                      onPressed: () => _afficherDialogNouveauProduit(context, entrepriseId),
                    ),
                  IconButton(
                    icon: const Icon(Icons.settings, size: 28),
                    tooltip: 'Paramètres',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SettingsScreen()),
                      );
                    },
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 28),
                    tooltip: 'Options d\'exportation',
                    onSelected: (value) async {
                      final produits = ref.read(produitsStreamProvider).value ?? [];
                      final curr = ref.read(currencyProvider);
                      final enTetes = ['Nom du produit', 'Stock disponible', 'Prix Vente'];
                      final lignes = produits
                          .map((p) => [
                                p.nom,
                                p.quantite,
                                '${p.prixVente} $curr',
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
                  ? const _ProduitsView()
                  : Row(
                      children: [
                        const Expanded(flex: 2, child: _ProduitsView()),
                        const VerticalDivider(width: 1, thickness: 2, color: Colors.grey),
                        Expanded(
                          flex: 1,
                          child: _PanierView(entrepriseId: entrepriseId, userId: userId),
                        ),
                      ],
                    ),
              floatingActionButton: isMobile && cart.isNotEmpty
                  ? FloatingActionButton.extended(
                      onPressed: () => _afficherModalPanier(
                        context,
                        cart,
                        cartNotifier,
                        totalAmount,
                        currency,
                        entrepriseId,
                        userId,
                      ),
                      backgroundColor: Colors.green,
                      icon: const Icon(Icons.shopping_cart, color: Colors.white),
                      label: Text(
                        'Panier ($totalItemsCount) - ${totalAmount.toStringAsFixed(2)} $currency',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
    List<CartItem> cart,
    CartNotifier cartNotifier,
    double totalAmount,
    String currency,
    String entrepriseId,
    String userId,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text('Panier Actuel', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: cart.length,
                  itemBuilder: (context, index) {
                    final item = cart[index];
                    return ListTile(
                      title: Text(item.nom, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Qté: ${item.quantite} x ${item.prix} $currency'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          cartNotifier.removeProduct(item.id);
                          if (cart.length == 1 && context.mounted) {
                            Navigator.pop(context);
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12.0),
                color: Colors.grey.shade100,
                child: Column(
                  children: [
                    Text(
                      'Total: ${totalAmount.toStringAsFixed(2)} $currency',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _afficherDialogPaiement(
                            context,
                            totalAmount,
                            cart,
                            entrepriseId,
                            userId,
                          );
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        child: const Text('ENCAISSER', style: TextStyle(color: Colors.white, fontSize: 18)),
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

  void _afficherDialogNouveauProduit(BuildContext context, String entrepriseId) {
    showDialog(
      context: context,
      builder: (dialogContext) => _NouveauProduitDialog(entrepriseId: entrepriseId),
    );
  }

  void _afficherDialogPaiement(
    BuildContext context,
    double total,
    List<CartItem> cart,
    String entrepriseId,
    String userId,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => _PaiementDialog(
        total: total,
        cart: cart,
        entrepriseId: entrepriseId,
        userId: userId,
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// VUE PRODUITS
// -----------------------------------------------------------------------------

class _ProduitsView extends ConsumerStatefulWidget {
  const _ProduitsView();

  @override
  ConsumerState<_ProduitsView> createState() => _ProduitsViewState();
}

class _ProduitsViewState extends ConsumerState<_ProduitsView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'Tous';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final produitsAsync = ref.watch(produitsStreamProvider);
    final currency = ref.watch(currencyProvider);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher par nom ou code-barres...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.trim().toLowerCase();
              });
            },
          ),
          const SizedBox(height: 8),
          Expanded(
            child: produitsAsync.when(
              data: (produits) {
                final Set<String> categoriesSet = {'Tous'};
                for (var p in produits) {
                  if (p.categorie.isNotEmpty) {
                    categoriesSet.add(p.categorie);
                  }
                }

                final produitsFiltres = produits.where((produit) {
                  final matchNom = produit.nom.toLowerCase().contains(_searchQuery);
                  final matchCodeBarre = produit.codeBarre.toLowerCase().contains(_searchQuery);
                  final matchSearch = matchNom || matchCodeBarre;
                  final matchCategory = _selectedCategory == 'Tous' || produit.categorie == _selectedCategory;

                  return matchSearch && matchCategory;
                }).toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 6.0,
                      children: categoriesSet.map((category) {
                        final isSelected = _selectedCategory == category;
                        return ChoiceChip(
                          label: Text(category),
                          selected: isSelected,
                          selectedColor: const Color(0xFF1E3A8A),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontSize: 12,
                          ),
                          onSelected: (bool selected) {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: produitsFiltres.isEmpty
                          ? const Center(child: Text('Aucun produit trouvé'))
                          : ListView.builder(
                              itemCount: produitsFiltres.length,
                              itemBuilder: (context, index) {
                                final produit = produitsFiltres[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                                  child: ListTile(
                                    title: Text(produit.nom, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text(
                                      'Code: ${produit.codeBarre.isEmpty ? "N/A" : produit.codeBarre} | Stock: ${produit.quantite} | Prix: ${produit.prixVente} $currency',
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.add_shopping_cart, color: Colors.blue),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (dialogContext) => _AjoutPanierDialog(produit: produit),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Erreur : $err')),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// VUE PANIER
// -----------------------------------------------------------------------------

class _PanierView extends ConsumerWidget {
  final String entrepriseId;
  final String userId;

  const _PanierView({
    required this.entrepriseId,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final totalAmount = ref.watch(cartTotalProvider);
    final currency = ref.watch(currencyProvider);

    return Container(
      color: Colors.grey.shade50,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(12.0),
            child: Text(
              'Panier Actuel',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: cart.isEmpty
                ? const Center(child: Text('Votre panier est vide', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    itemCount: cart.length,
                    itemBuilder: (context, index) {
                      final item = cart[index];
                      return ListTile(
                        title: Text(item.nom, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Qté: ${item.quantite} x ${item.prix} $currency'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => cartNotifier.removeProduct(item.id),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(12.0),
            color: Colors.grey.shade200,
            child: Column(
              children: [
                Text(
                  'Total: ${totalAmount.toStringAsFixed(2)} $currency',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: cart.isEmpty
                        ? null
                        : () {
                            showDialog(
                              context: context,
                              builder: (dialogContext) => _PaiementDialog(
                                total: totalAmount,
                                cart: cart,
                                entrepriseId: entrepriseId,
                                userId: userId,
                              ),
                            );
                          },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text('ENCAISSER', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// COMPOSANTS DIALOGUES
// -----------------------------------------------------------------------------

class _AjoutPanierDialog extends ConsumerStatefulWidget {
  final Produit produit;
  const _AjoutPanierDialog({required this.produit});

  @override
  ConsumerState<_AjoutPanierDialog> createState() => _AjoutPanierDialogState();
}

class _AjoutPanierDialogState extends ConsumerState<_AjoutPanierDialog> {
  late final TextEditingController _qteController;
  late final TextEditingController _prixController;

  @override
  void initState() {
    super.initState();
    _qteController = TextEditingController(text: "1");
    _prixController = TextEditingController(text: widget.produit.prixVente.toString());
  }

  @override
  void dispose() {
    _qteController.dispose();
    _prixController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Ajouter ${widget.produit.nom}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _prixController,
            decoration: const InputDecoration(
              labelText: 'Prix unitaire',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _qteController,
            decoration: const InputDecoration(
              labelText: 'Quantité',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            final prix = double.tryParse(_prixController.text) ?? widget.produit.prixVente;
            final qte = int.tryParse(_qteController.text) ?? 1;
            ref.read(cartProvider.notifier).addProduct(widget.produit.id, widget.produit.nom, prix, qte);
            Navigator.pop(context);
          },
          child: const Text('Ajouter'),
        ),
      ],
    );
  }
}

class _NouveauProduitDialog extends ConsumerStatefulWidget {
  final String entrepriseId;

  const _NouveauProduitDialog({
    required this.entrepriseId,
  });

  @override
  ConsumerState<_NouveauProduitDialog> createState() => _NouveauProduitDialogState();
}

class _NouveauProduitDialogState extends ConsumerState<_NouveauProduitDialog> {
  final _nomController = TextEditingController();
  final _qteController = TextEditingController();
  final _prixAchatController = TextEditingController();
  final _prixVenteController = TextEditingController();
  final _codeBarreController = TextEditingController();

  @override
  void dispose() {
    _nomController.dispose();
    _qteController.dispose();
    _prixAchatController.dispose();
    _prixVenteController.dispose();
    _codeBarreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter un Produit au Stock'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 6),
            TextField(
              controller: _nomController,
              decoration: const InputDecoration(
                labelText: 'Nom du produit *',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _codeBarreController,
              decoration: const InputDecoration(
                labelText: 'Code-barres / Référence',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _qteController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantité en stock',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _prixAchatController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: "Prix d'achat unitaire",
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _prixVenteController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Prix de vente unitaire',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_nomController.text.trim().isNotEmpty && widget.entrepriseId.isNotEmpty) {
              final navigator = Navigator.of(context);
              final int qte = int.tryParse(_qteController.text) ?? 0;
              final double prixAchat = double.tryParse(_prixAchatController.text) ?? 0.0;
              final double prixVente = double.tryParse(_prixVenteController.text) ?? 0.0;

              final nouveauProduit = Produit(
                id: '',
                entrepriseId: widget.entrepriseId,
                nom: _nomController.text.trim(),
                codeBarre: _codeBarreController.text.trim(),
                quantite: qte,
                prixAchat: prixAchat,
                prixVente: prixVente,
              );

              await ref
                  .read(produitRepositoryProvider)
                  .ajouterOuMettreAJourProduit(nouveauProduit, widget.entrepriseId);

              if (!mounted) return;
              navigator.pop();
            }
          },
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}

class _PaiementDialog extends ConsumerStatefulWidget {
  final double total;
  final List<CartItem> cart;
  final String entrepriseId;
  final String userId;

  const _PaiementDialog({
    required this.total,
    required this.cart,
    required this.entrepriseId,
    required this.userId,
  });

  @override
  ConsumerState<_PaiementDialog> createState() => _PaiementDialogState();
}

class _PaiementDialogState extends ConsumerState<_PaiementDialog> {
  final _clientController = TextEditingController();
  late final TextEditingController _acompteController;
  final _telephoneController = TextEditingController();

  String statutPaiement = 'Payé';
  static String methodePaiement = 'Cash';
  String statutLivraison = 'Livré';

  bool imprimerRecu = true;
  bool envoyerWhatsApp = false;
  bool envoyerSMS = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _acompteController = TextEditingController(text: widget.total.toString());
  }

  @override
  void dispose() {
    _clientController.dispose();
    _acompteController.dispose();
    _telephoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencyProvider);
    final double verse = double.tryParse(_acompteController.text) ?? 0.0;
    final double reste = widget.total - verse;

    return AlertDialog(
      title: const Text('Finaliser la vente & Options'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            TextField(
              controller: _clientController,
              decoration: InputDecoration(
                labelText: 'Nom du Client',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _telephoneController,
              decoration: InputDecoration(
                labelText: 'Téléphone (ex: +243...)',
                hintText: '+243...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: statutPaiement,
              decoration: InputDecoration(
                labelText: 'Statut du paiement',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              items: ['Payé', 'Dette', 'Acompte'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (val) {
                if (val == null) return;
                setState(() {
                  statutPaiement = val;
                  if (statutPaiement == 'Payé') {
                    _acompteController.text = widget.total.toString();
                  } else if (statutPaiement == 'Dette') {
                    _acompteController.text = '0.0';
                  }
                });
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _acompteController,
              decoration: InputDecoration(
                labelText: 'Montant Versé',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                reste < 0
                    ? 'Monnaie à rendre : ${reste.abs().toStringAsFixed(2)} $currency'
                    : 'Reste à payer : ${reste.toStringAsFixed(2)} $currency',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: reste > 0 ? Colors.red : Colors.green,
                ),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: statutLivraison,
              decoration: InputDecoration(
                labelText: 'Livraison',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              items: ['Livré', 'Non livré'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => statutLivraison = val);
              },
            ),
            const Divider(height: 24),
            const Text('Actions pour le reçu :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
            CheckboxListTile(
              title: const Text('Imprimer le reçu thermique', style: TextStyle(fontSize: 13)),
              value: imprimerRecu,
              onChanged: (val) => setState(() => imprimerRecu = val ?? true),
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              title: const Text('Envoyer par WhatsApp', style: TextStyle(fontSize: 13)),
              value: envoyerWhatsApp,
              onChanged: (val) => setState(() => envoyerWhatsApp = val ?? false),
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              title: const Text('Envoyer par SMS', style: TextStyle(fontSize: 13)),
              value: envoyerSMS,
              onChanged: (val) => setState(() => envoyerSMS = val ?? false),
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: isLoading ? null : _traiterValidation,
          child: isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('VALIDER'),
        ),
      ],
    );
  }

  Future<void> _traiterValidation() async {
    final nomClient = _clientController.text.trim().isEmpty 
        ? "Client Divers" 
        : _clientController.text.trim();
    final double verse = double.tryParse(_acompteController.text) ?? 0.0;
    final double reste = widget.total - verse;
    final dateActuelle = DateTime.now();

    setState(() => isLoading = true);

    try {
      final vente = Vente(
        id: '',
        clientNom: nomClient,
        total: widget.total,
        montantPaye: verse,
        resteAPayer: reste > 0 ? reste : 0.0,
        statutPaiement: reste > 0 ? (verse > 0 ? 'Acompte' : 'Dette') : 'Payé',
        methodePaiement: methodePaiement,
        produits: widget.cart.map((item) => item.toMap()).toList(),
        date: dateActuelle,
      );

      await ref.read(venteRepositoryProvider).enregistrerVente(
            vente: vente,
            cartItems: widget.cart,
            entrepriseId: widget.entrepriseId,
            userId: widget.userId,
          );

      if (imprimerRecu) {
        final currency = ref.read(currencyProvider);
        await ReceiptService.printReceipt(
          items: widget.cart,
          total: widget.total,
          montantPaye: verse,
          currency: currency,
          nomClient: nomClient,
          nomMagasin: "Stockly SaaS",
          adresseMagasin: "Boutique Principale",
          phoneMagasin: "+243 97 34 14 587",
        );
      }

      ref.read(cartProvider.notifier).clear();

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vente enregistrée avec succès !')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'enregistrement : $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }
}