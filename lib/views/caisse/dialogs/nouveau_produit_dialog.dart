import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/produit.dart';
import '../../../providers/produit_provider.dart';

class NouveauProduitDialog extends ConsumerStatefulWidget {
  final String entrepriseId;

  const NouveauProduitDialog({
    super.key,
    required this.entrepriseId,
  });

  @override
  ConsumerState<NouveauProduitDialog> createState() => _NouveauProduitDialogState();
}

class _NouveauProduitDialogState extends ConsumerState<NouveauProduitDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _codeBarreController = TextEditingController();
  final _categorieController = TextEditingController();
  final _qteController = TextEditingController();
  final _prixAchatController = TextEditingController();
  final _prixVenteController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _nomController.dispose();
    _codeBarreController.dispose();
    _categorieController.dispose();
    _qteController.dispose();
    _prixAchatController.dispose();
    _prixVenteController.dispose();
    super.dispose();
  }

  Future<void> _enregistrerProduit() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.entrepriseId.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final int qte = int.tryParse(_qteController.text.trim()) ?? 0;
      final double prixAchat = double.tryParse(_prixAchatController.text.trim()) ?? 0.0;
      final double prixVente = double.tryParse(_prixVenteController.text.trim()) ?? 0.0;

      final nouveauProduit = Produit(
        id: '',
        entrepriseId: widget.entrepriseId,
        nom: _nomController.text.trim(),
        codeBarre: _codeBarreController.text.trim(),
        categorie: _categorieController.text.trim(),
        quantite: qte,
        prixAchat: prixAchat,
        prixVente: prixVente,
      );

      await ref
          .read(produitRepositoryProvider)
          .ajouterOuMettreAJourProduit(nouveauProduit, widget.entrepriseId);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'enregistrement : $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter un Produit au Stock'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 6),
              TextFormField(
                controller: _nomController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Nom du produit *',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez saisir le nom du produit';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _codeBarreController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Code-barres / Référence',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _categorieController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Catégorie',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _qteController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Quantité en stock',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _prixAchatController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: "Prix d'achat unitaire",
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _prixVenteController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _enregistrerProduit(),
                decoration: const InputDecoration(
                  labelText: 'Prix de vente unitaire',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _enregistrerProduit,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Enregistrer'),
        ),
      ],
    );
  }
}