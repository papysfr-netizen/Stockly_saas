import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../widgets/quick_scanner_widget.dart';

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

  /// Méthode statique pour ouvrir la modale sous forme de BottomSheet Glassmorphic
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

  // Contrôleurs de texte
  late TextEditingController _nomController;
  late TextEditingController _codeBarresController;
  late TextEditingController _prixAchatController;
  late TextEditingController _prixVenteController;
  late TextEditingController _quantiteController;
  late TextEditingController _seuilAlerteController;
  late TextEditingController _imageUrlController;

  // Catégories
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

  // Mode Édition ou Création
  bool get isEditing => widget.id != null;

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
      text: widget.product?['quantite']?.toString() ?? '1',
    );
    _seuilAlerteController = TextEditingController(
      text: widget.product?['seuilAlerte']?.toString() ?? '5',
    );
    _imageUrlController = TextEditingController(
      text: widget.product?['imageUrl']?.toString() ?? '',
    );

    final existingCat = widget.product?['categorie']?.toString();
    if (existingCat != null && _categories.contains(existingCat)) {
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

  Future<void> _sauvegarderProduit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final Map<String, dynamic> productData = {
        'nom': _nomController.text.trim(),
        'codeBarre': _codeBarresController.text.trim(),
        'categorie': _categorieSelectionnee,
        'prixAchat': double.tryParse(_prixAchatController.text.trim()) ?? 0.0,
        'prixVente': double.tryParse(_prixVenteController.text.trim()) ?? 0.0,
        'prix': double.tryParse(_prixVenteController.text.trim()) ?? 0.0,
        'quantite': int.tryParse(_quantiteController.text.trim()) ?? 0,
        'seuilAlerte': int.tryParse(_seuilAlerteController.text.trim()) ?? 5,
        'imageUrl': _imageUrlController.text.trim(),
        'entrepriseId': widget.entrepriseId,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Référence vers la collection multi-tenant
      final produitsCollection = FirebaseFirestore.instance
          .collection('organizations')
          .doc(widget.entrepriseId)
          .collection('produits');

      if (isEditing) {
        await produitsCollection.doc(widget.id).update(productData);
      } else {
        productData['createdAt'] = FieldValue.serverTimestamp();
        final docRef = await produitsCollection.add(productData);
        productData['id'] = docRef.id;
      }

      if (widget.onProductAdded != null) {
        widget.onProductAdded!(productData);
      }

      // Fermeture de la modale et notification
      navigator.pop(productData);
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isEditing
                      ? 'Produit mis à jour avec succès !'
                      : 'Produit ajouté avec succès !',
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Colors.green.shade700,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'enregistrement : $e'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Poignée de glissement (Drag Handle)
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

                      // En-tête
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isEditing ? 'Modifier le produit' : 'Nouveau Produit',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
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
                      const SizedBox(height: 20),

                      // Aperçu & URL Image
                      Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(16),
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
                                    borderRadius: BorderRadius.circular(15),
                                    child: Image.network(
                                      value.text,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Icon(
                                        Icons.broken_image_outlined,
                                        color: theme.colorScheme.error,
                                      ),
                                    ),
                                  );
                                }
                                return Icon(
                                  Icons.add_a_photo_outlined,
                                  size: 24,
                                  color: theme.colorScheme.primary.withValues(alpha: 0.7),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildInputField(
                              controller: _imageUrlController,
                              label: "URL de l'image (optionnel)",
                              hint: "https://exemple.com/image.jpg",
                              icon: Icons.link_rounded,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Nom
                      _buildInputField(
                        controller: _nomController,
                        label: 'Nom du produit *',
                        hint: 'ex: T-Shirt Coton Noir',
                        icon: Icons.shopping_bag_outlined,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Veuillez saisir un nom de produit';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Code-barres & Catégorie
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildInputField(
                              controller: _codeBarresController,
                              label: 'Code-barres',
                              hint: 'Scanner / Saisir',
                              icon: Icons.qr_code_rounded,
                              suffixIcon: IconButton(
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.only(right: 8),
                                icon: Icon(
                                  Icons.qr_code_scanner_rounded,
                                  color: theme.colorScheme.primary,
                                  size: 20,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (scannerContext) => QuickScannerWidget(
                                        onCodeScanned: (code) {
                                          setState(() {
                                            _codeBarresController.text = code;
                                          });
                                          Navigator.pop(scannerContext);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Code scanné : $code'),
                                              behavior: SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              backgroundColor: Colors.green.shade700,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              isExpanded: true, // Correction : force l'adaptation à la largeur disponible
                              initialValue: _categorieSelectionnee,
                              style: theme.textTheme.bodyMedium,
                              decoration: _buildInputDecoration(
                                label: 'Catégorie',
                                icon: Icons.category_outlined,
                              ),
                              items: _categories.map((cat) {
                                return DropdownMenuItem(
                                  value: cat,
                                  child: Text(
                                    cat,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _categorieSelectionnee = val);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Prix d'achat & Prix de vente
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildInputField(
                              controller: _prixAchatController,
                              label: "Prix d'achat (\$)",
                              hint: '0.00',
                              icon: Icons.attach_money_rounded,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildInputField(
                              controller: _prixVenteController,
                              label: 'Prix de vente (\$)*',
                              hint: '0.00',
                              icon: Icons.sell_outlined,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Prix requis';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Quantité & Seuil d'alerte
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildInputField(
                              controller: _quantiteController,
                              label: 'Stock initial *',
                              hint: '1',
                              icon: Icons.inventory_2_outlined,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Quantité requise';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildInputField(
                              controller: _seuilAlerteController,
                              label: "Seuil d'alerte",
                              hint: '5',
                              icon: Icons.warning_amber_rounded,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Bouton Enregistrer
                      SizedBox(
                        height: 52,
                        child: FilledButton.icon(
                          onPressed: isLoading ? null : _sauvegarderProduit,
                          style: FilledButton.styleFrom(
                            backgroundColor: isEditing
                                ? Colors.orange.shade800
                                : theme.colorScheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          icon: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(isEditing ? Icons.check_circle_rounded : Icons.add_shopping_cart_rounded),
                          label: Text(
                            isLoading
                                ? 'Enregistrement en cours...'
                                : (isEditing ? 'Mettre à jour le produit' : 'Enregistrer le produit'),
                            style: const TextStyle(
                              fontSize: 15,
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
      prefixIcon: Icon(icon, size: 18),
      prefixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      suffixIcon: suffixIcon,
      suffixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      filled: true,
      fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: theme.colorScheme.primary,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: theme.colorScheme.error.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
    );
  }
}