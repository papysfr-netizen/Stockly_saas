import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/user_role_provider.dart';
import '../widgets/quick_scanner_widget.dart';

// ============================================================================
// 1. CONTROLLER & LOGIQUE MÉTIER (ISOLATION MULTI-TENANT)
// ============================================================================

final addProductControllerProvider =
    AsyncNotifierProvider.family<AddProductController, void, String>(
  AddProductController.new,
);

class AddProductController extends FamilyAsyncNotifier<void, String> {
  @override
  Future<void> build(String arg) async {}

  /// Ajout d'un nouveau produit dans la sous-collection de l'organisation
  Future<void> addProduct({
    required String nom,
    required String codeBarre,
    required double prixAchat,
    required double prixVente,
    required int quantite,
  }) async {
    final entrepriseId = arg;
    if (entrepriseId.isEmpty) return;

    state = const AsyncValue.loading();
    try {
      final docRef = FirebaseFirestore.instance
          .collection('entreprises') // 👈 Correction : 'entreprises' au lieu de 'organizations'
          .doc(entrepriseId)
          .collection('produits')
          .doc();

      await docRef.set({
        'id': docRef.id,
        'nom': nom.trim(),
        'codeBarre': codeBarre.trim(),
        'prixAchat': prixAchat,
        'prixVente': prixVente,
        'prix_achat': prixAchat,
        'quantite': quantite,
        'entrepriseId': entrepriseId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}

// ============================================================================
// 2. ÉCRAN D'AJOUT DE PRODUIT (PRESENTATION LAYER)
// ============================================================================

class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({super.key});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nomController = TextEditingController();
  final TextEditingController codeBarreController = TextEditingController();
  final TextEditingController prixAchatController = TextEditingController();
  final TextEditingController prixVenteController = TextEditingController();
  final TextEditingController quantiteController = TextEditingController(text: '1');

  @override
  void dispose() {
    nomController.dispose();
    codeBarreController.dispose();
    prixAchatController.dispose();
    prixVenteController.dispose();
    quantiteController.dispose();
    super.dispose();
  }

  // Helper pour parser les doubles en supportant la virgule ','
  double _parseDouble(String text) {
    final cleaned = text.trim().replaceAll(',', '.');
    return double.tryParse(cleaned) ?? 0.0;
  }

  void _soumettreProduit(String entrepriseId) async {
    if (!_formKey.currentState!.validate()) return;

    final nom = nomController.text;
    final codeBarre = codeBarreController.text;
    final prixAchat = _parseDouble(prixAchatController.text);
    final prixVente = _parseDouble(prixVenteController.text);
    final quantite = int.tryParse(quantiteController.text.trim()) ?? 0;

    try {
      await ref
          .read(addProductControllerProvider(entrepriseId).notifier)
          .addProduct(
            nom: nom,
            codeBarre: codeBarre,
            prixAchat: prixAchat,
            prixVente: prixVente,
            quantite: quantite,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produit ajouté avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'ajout : $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final entrepriseId = profileAsync.value?.entrepriseId ?? '';
    final controllerState = ref.watch(addProductControllerProvider(entrepriseId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un produit'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Champ Nom du Produit
                  TextFormField(
                    controller: nomController,
                    decoration: const InputDecoration(
                      labelText: 'Nom du produit *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.shopping_bag),
                    ),
                    validator: (value) => (value == null || value.trim().isEmpty)
                        ? 'Veuillez entrer un nom'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Champ Code-barres avec Scanner
                  TextFormField(
                    controller: codeBarreController,
                    decoration: InputDecoration(
                      labelText: 'Code-barres',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.qr_code),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.qr_code_scanner, color: Colors.blue),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => QuickScannerWidget(
                                onCodeScanned: (code) {
                                  setState(() {
                                    codeBarreController.text = code;
                                  });

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Code scanné : $code'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Champ Prix d'Achat
                  TextFormField(
                    controller: prixAchatController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Prix d\'achat unitaire',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.sell),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Champ Prix de Vente
                  TextFormField(
                    controller: prixVenteController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Prix de vente *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.payments),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Veuillez entrer un prix de vente';
                      }
                      final cleaned = value.trim().replaceAll(',', '.');
                      if (double.tryParse(cleaned) == null) {
                        return 'Prix invalide';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Champ Quantité initiale
                  TextFormField(
                    controller: quantiteController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantité en stock *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.inventory),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Veuillez entrer une quantité';
                      }
                      if (int.tryParse(value.trim()) == null) {
                        return 'Quantité invalide';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Bouton d'Enregistrement
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.indigo.shade800,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.save),
                    label: const Text(
                      'Enregistrer le produit',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    onPressed: entrepriseId.isEmpty || controllerState.isLoading
                        ? null
                        : () => _soumettreProduit(entrepriseId),
                  ),
                ],
              ),
            ),
          ),
          if (controllerState.isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}