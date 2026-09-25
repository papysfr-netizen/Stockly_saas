import 'dart:async';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/packing_list_service.dart';
import 'quick_scanner_widget.dart';

class AddProductModal extends StatefulWidget {
  final String entrepriseId;
  final Map<String, dynamic>? product;
  final String? id;
  final Function(Map<String, dynamic> productData)? onProductAdded;

  const AddProductModal({
    super.key,
    required this.entrepriseId,
    this.product,
    this.id,
    this.onProductAdded,
  });

  static Future<void> show(
    BuildContext context, {
    required String entrepriseId,
    Map<String, dynamic>? product,
    String? id,
    Function(Map<String, dynamic> productData)? onProductAdded,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddProductModal(
        entrepriseId: entrepriseId,
        product: product,
        id: id,
        onProductAdded: onProductAdded,
      ),
    );
  }

  @override
  State<AddProductModal> createState() => _AddProductModalState();
}

class _AddProductModalState extends State<AddProductModal> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nomController;
  late TextEditingController _codeBarresController;
  late TextEditingController _prixAchatController;
  late TextEditingController _prixVenteController;
  late TextEditingController _quantiteController;
  late TextEditingController _seuilAlerteController;
  late TextEditingController _imageUrlController;

  late String _categorieSelectionnee;
  final List<String> _categories = [
    'Général',
    'Alimentation',
    'Boissons',
    'Électronique',
    'Vêtements',
    'Cosmétique',
    'Pharmacie',
    'Autre',
  ];

  bool isLoading = false;

  bool get isEditing => widget.id != null && widget.id!.isNotEmpty;

  @override
  void initState() {
    super.initState();

    _nomController = TextEditingController(
      text: widget.product?['nom']?.toString() ?? '',
    );
    _codeBarresController = TextEditingController(
      text: widget.product?['codeBarre']?.toString() ??
          widget.product?['code_barre']?.toString() ??
          widget.product?['codeBarres']?.toString() ??
          '',
    );
    _prixAchatController = TextEditingController(
      text: widget.product?['prixAchat']?.toString() ?? '',
    );
    _prixVenteController = TextEditingController(
      text: widget.product?['prixVente']?.toString() ??
          widget.product?['prix']?.toString() ??
          '',
    );
    _quantiteController = TextEditingController(
      text: widget.product?['quantite']?.toString() ??
          widget.product?['stock']?.toString() ??
          '1',
    );
    _seuilAlerteController = TextEditingController(
      text: widget.product?['seuilAlerte']?.toString() ?? '5',
    );
    _imageUrlController = TextEditingController(
      text: widget.product?['imageUrl']?.toString() ?? '',
    );

    final existingCat = widget.product?['categorie']?.toString();
    if (existingCat != null && existingCat.isNotEmpty) {
      if (!_categories.contains(existingCat)) {
        _categories.add(existingCat);
      }
      _categorieSelectionnee = existingCat;
    } else {
      _categorieSelectionnee = 'Général';
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _codeBarresController.dispose();
    _prixAchatController.dispose();
    _prixVenteController.dispose();
    _quantiteController.dispose();
    _seuilAlerteController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  // ================= OUTILS DE LECTURE DES NOMBRES =================

  /// Accepte "12,5", "12.5" et "1 500" (virgule et espaces tolérés).
  double? _lireDecimal(String texte) {
    final nettoye = texte.trim().replaceAll(' ', '').replaceAll(',', '.');
    if (nettoye.isEmpty) return null;
    return double.tryParse(nettoye);
  }

  int? _lireEntier(String texte) {
    final nettoye = texte.trim().replaceAll(' ', '');
    if (nettoye.isEmpty) return null;
    return int.tryParse(nettoye);
  }

  void _afficherMessage(
    ScaffoldMessengerState messenger,
    String texte,
    Color couleur,
    IconData icone,
  ) {
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icone, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(texte)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: couleur,
      ),
    );
  }

  // ================= ENREGISTREMENT (RÉSISTANT AUX COUPURES) =================

  Future<void> _sauvegarderProduit() async {
    if (!_formKey.currentState!.validate()) return;

    // On récupère ces outils AVANT toute attente, pour pouvoir
    // les utiliser même après la fermeture du formulaire.
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final entrepriseId = widget.entrepriseId.trim();
    if (entrepriseId.isEmpty) {
      _afficherMessage(
        messenger,
        'Entreprise introuvable. Déconnectez-vous puis reconnectez-vous.',
        Colors.red.shade700,
        Icons.error_outline,
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final codeBarreVal = _codeBarresController.text.trim();
      final prixVenteVal = _lireDecimal(_prixVenteController.text) ?? 0.0;
      final quantiteVal = _lireEntier(_quantiteController.text) ?? 0;

      final Map<String, dynamic> productData = {
        'nom': _nomController.text.trim(),
        'codeBarre': codeBarreVal,
        'codeBarres': codeBarreVal,
        'categorie': _categorieSelectionnee,
        'prixAchat': _lireDecimal(_prixAchatController.text) ?? 0.0,
        'prixVente': prixVenteVal,
        'prix': prixVenteVal,
        'quantite': quantiteVal,
        'stock': quantiteVal,
        'seuilAlerte': _lireEntier(_seuilAlerteController.text) ?? 5,
        'imageUrl': _imageUrlController.text.trim(),
        'entrepriseId': entrepriseId,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Un seul emplacement : entreprises/{id}/produits
      final produitsRef = FirebaseFirestore.instance
          .collection('entreprises')
          .doc(entrepriseId)
          .collection('produits');

      // L'identifiant est créé sur le téléphone : pas besoin d'internet.
      final docRef = isEditing ? produitsRef.doc(widget.id!) : produitsRef.doc();

      if (!isEditing) {
        productData['createdAt'] = FieldValue.serverTimestamp();
      }

      final Future<void> ecriture = isEditing
          ? docRef.set(productData, SetOptions(merge: true))
          : docRef.set(productData);

      // Firestore garde l'écriture sur le téléphone tout de suite.
      // Si le serveur ne répond pas en 5 s (coupure réseau), on n'attend
      // pas : l'envoi se fera automatiquement quand internet reviendra.
      bool enAttenteReseau = false;
      try {
        await ecriture.timeout(const Duration(seconds: 5));
      } on TimeoutException {
        enAttenteReseau = true;
        debugPrint(
          '[Stockly] Produit ${docRef.id} enregistré sur le téléphone, '
          'envoi au serveur en attente du réseau',
        );
      }

      productData['id'] = docRef.id;
      widget.onProductAdded?.call(productData);

      if (!mounted) return;

      navigator.pop(productData);

      if (enAttenteReseau) {
        _afficherMessage(
          messenger,
          'Enregistré sur le téléphone. Il sera envoyé dès que internet revient.',
          Colors.orange.shade800,
          Icons.cloud_off_rounded,
        );
      } else {
        _afficherMessage(
          messenger,
          isEditing
              ? 'Produit mis à jour avec succès !'
              : 'Produit ajouté avec succès !',
          Colors.green.shade700,
          Icons.check_circle_outline,
        );
      }
    } catch (e) {
      debugPrint('[Stockly] Erreur enregistrement produit : $e');
      _afficherMessage(
        messenger,
        'Erreur lors de l\'enregistrement : $e',
        Colors.red.shade700,
        Icons.error_outline,
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }
  // ================= SCANNER =================

  /// Ouvre le scanner et attend le code.
  /// Le scanner se ferme TOUT SEUL en renvoyant le code :
  /// ici on ne ferme rien, sinon on fermerait aussi le formulaire.
  Future<void> _ouvrirScanner() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => const QuickScannerWidget(),
      ),
    );

    if (!mounted || code == null || code.trim().isEmpty) return;

    setState(() => _codeBarresController.text = code.trim());
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    final maxHeight = mediaQuery.size.height * 0.85;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.92),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              isEditing ? 'Modifier le produit' : 'Nouveau Produit',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton.filledTonal(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () => Navigator.pop(context),
                            style: IconButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (!isEditing) ...[
                        OutlinedButton.icon(
                          onPressed: () async {
                            final entId = widget.entrepriseId.trim();
                            if (entId.isEmpty) {
                              _afficherMessage(
                                ScaffoldMessenger.of(context),
                                'Entreprise introuvable. Déconnectez-vous puis reconnectez-vous.',
                                Colors.red.shade700,
                                Icons.error_outline,
                              );
                              return;
                            }
                            Navigator.pop(context);
                            await PackingListService.importerEtTraiter(
                              context,
                              entrepriseId: entId,
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 44),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            side: BorderSide(
                              color: theme.colorScheme.primary,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: Icon(
                            Icons.file_upload_outlined,
                            color: theme.colorScheme.primary,
                            size: 18,
                          ),
                          label: Text(
                            'Importer Packing List (Excel / CSV)',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: theme.colorScheme.outline.withValues(alpha: 0.3),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6.0),
                              child: Text(
                                'OU SAISIE MANUELLE',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: theme.colorScheme.outline.withValues(alpha: 0.3),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                      ],
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth < 280) {
                            return Column(
                              children: [
                                _buildImagePreview(theme),
                                const SizedBox(height: 10),
                                _buildInputField(
                                  controller: _imageUrlController,
                                  label: "URL de l'image",
                                  hint: "https://...",
                                  icon: Icons.link_rounded,
                                ),
                              ],
                            );
                          }
                          return Row(
                            children: [
                              _buildImagePreview(theme),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildInputField(
                                  controller: _imageUrlController,
                                  label: "URL de l'image (optionnel)",
                                  hint: "https://exemple.com/image.jpg",
                                  icon: Icons.link_rounded,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      _buildInputField(
                        controller: _nomController,
                        label: 'Nom du produit *',
                        hint: 'ex: T-Shirt Coton',
                        icon: Icons.shopping_bag_outlined,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nom obligatoire';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 300;
                          final codeField = _buildInputField(
                            controller: _codeBarresController,
                            label: 'Code-barres',
                            hint: 'Scanner / Saisir',
                            icon: Icons.qr_code_rounded,
                            suffixIcon: IconButton(
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.only(right: 6),
                              icon: Icon(
                                Icons.qr_code_scanner_rounded,
                                color: theme.colorScheme.primary,
                                size: 18,
                              ),
                              onPressed: _ouvrirScanner,
                            ),
                          );

                          final catField = DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: _categorieSelectionnee,
                            style: theme.textTheme.bodyMedium,
                            decoration: _buildInputDecoration(
                              label: 'Catégorie',
                              icon: Icons.category_outlined,
                            ),
                            items: _categories.map((cat) {
                              return DropdownMenuItem(
                                value: cat,
                                child: Text(cat, overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _categorieSelectionnee = val);
                              }
                            },
                          );

                          if (isNarrow) {
                            return Column(
                              children: [
                                codeField,
                                const SizedBox(height: 14),
                                catField,
                              ],
                            );
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: codeField),
                              const SizedBox(width: 8),
                              Expanded(child: catField),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 300;
                          final prixAchatField = _buildInputField(
                            controller: _prixAchatController,
                            label: "Prix d'achat (\$)",
                            hint: '0.00',
                            icon: Icons.attach_money_rounded,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return null; // optionnel
                              }
                              if (_lireDecimal(value) == null) {
                                return 'Prix invalide';
                              }
                              return null;
                            },
                          );

                          final prixVenteField = _buildInputField(
                            controller: _prixVenteController,
                            label: 'Prix vente (\$)*',
                            hint: '0.00',
                            icon: Icons.sell_outlined,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Prix requis';
                              }
                              if (_lireDecimal(value) == null) {
                                return 'Prix invalide';
                              }
                              return null;
                            },
                          );

                          if (isNarrow) {
                            return Column(
                              children: [
                                prixAchatField,
                                const SizedBox(height: 14),
                                prixVenteField,
                              ],
                            );
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: prixAchatField),
                              const SizedBox(width: 8),
                              Expanded(child: prixVenteField),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 300;
                          final quantiteField = _buildInputField(
                            controller: _quantiteController,
                            label: 'Stock initial *',
                            hint: '1',
                            icon: Icons.inventory_2_outlined,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Stock requis';
                              }
                              if (_lireEntier(value) == null) {
                                return 'Nombre entier';
                              }
                              return null;
                            },
                          );

                          final seuilField = _buildInputField(
                            controller: _seuilAlerteController,
                            label: "Seuil d'alerte",
                            hint: '5',
                            icon: Icons.warning_amber_rounded,
                            keyboardType: TextInputType.number,
                          );

                          if (isNarrow) {
                            return Column(
                              children: [
                                quantiteField,
                                const SizedBox(height: 14),
                                seuilField,
                              ],
                            );
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: quantiteField),
                              const SizedBox(width: 8),
                              Expanded(child: seuilField),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 48,
                        child: FilledButton.icon(
                          onPressed: isLoading ? null : _sauvegarderProduit,
                          style: FilledButton.styleFrom(
                            backgroundColor: isEditing
                                ? Colors.orange.shade800
                                : theme.colorScheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          icon: isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.0,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(
                                  isEditing
                                      ? Icons.check_circle_rounded
                                      : Icons.add_shopping_cart_rounded,
                                  size: 20,
                                ),
                          label: Text(
                            isLoading
                                ? 'Enregistrement...'
                                : (isEditing ? 'Mettre à jour' : 'Enregistrer le produit'),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview(ThemeData theme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: _imageUrlController,
        builder: (context, value, _) {
          if (value.text.isNotEmpty &&
              Uri.tryParse(value.text)?.hasAbsolutePath == true) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Image.network(
                value.text,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.broken_image_outlined,
                  color: theme.colorScheme.error,
                  size: 20,
                ),
              ),
            );
          }
          return Icon(
            Icons.add_a_photo_outlined,
            size: 20,
            color: theme.colorScheme.primary.withValues(alpha: 0.7),
          );
        },
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    String? hint,
    required IconData icon,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      decoration: _buildInputDecoration(
        label: label,
        hint: hint,
        icon: icon,
        suffixIcon: suffixIcon,
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String label,
    String? hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    final theme = Theme.of(context);
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, size: 16),
      prefixIconConstraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      suffixIcon: suffixIcon,
      suffixIconConstraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      filled: true,
      fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      isDense: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: theme.colorScheme.primary,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: theme.colorScheme.error.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
    );
  }
}