// lib/features/boutiques/prix_boutiques_screen.dart
//
// 💲 MULTI-BOUTIQUES — Étape 4a : prix de vente propre à chaque boutique.
//
// produits/{id}.prixParBoutique = {idBoutique: prix (en USD, comme prixVente)}
// Champ vide (ou égal au prix normal) = la boutique vend au prix normal.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stockly_saas/core/models/produit.dart';
import 'package:stockly_saas/core/providers/currency_provider.dart';
import 'package:stockly_saas/core/providers/user_role_provider.dart';
import 'boutique_provider.dart';

class PrixBoutiquesScreen extends ConsumerStatefulWidget {
  final String entrepriseId;
  const PrixBoutiquesScreen({super.key, required this.entrepriseId});

  @override
  ConsumerState<PrixBoutiquesScreen> createState() => _PrixBoutiquesScreenState();
}

class _PrixBoutiquesScreenState extends ConsumerState<PrixBoutiquesScreen> {
  static const Color _bleuNuit = Color(0xFF1E293B);

  String? _boutique;
  final Map<String, TextEditingController> _ctrls = {};
  final Set<String> _modifies = {};
  String _recherche = '';
  bool _enCours = false;

  CollectionReference<Map<String, dynamic>> get _produits => FirebaseFirestore.instance
      .collection('entreprises')
      .doc(widget.entrepriseId)
      .collection('produits');

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _changerBoutique(String? b) {
    setState(() {
      _boutique = b;
      for (final c in _ctrls.values) {
        c.dispose();
      }
      _ctrls.clear();
      _modifies.clear();
    });
  }

  /// Affiche un montant USD dans la devise active
  String _fmt(double usd, double taux) {
    final v = usd * taux;
    if (taux >= 100 || (v - v.roundToDouble()).abs() < 0.005) return v.toStringAsFixed(0);
    return v.toStringAsFixed(2);
  }

  TextEditingController _ctrl(Produit p, double taux) {
    return _ctrls.putIfAbsent(p.id, () {
      final propre = _boutique == null ? null : p.prixParBoutique[_boutique];
      return TextEditingController(
        text: (propre != null && propre > 0) ? _fmt(propre, taux) : '',
      );
    });
  }

  Future<void> _enregistrer(List<Produit> produits, double taux) async {
    final b = _boutique;
    if (b == null || _modifies.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    final parId = {for (final p in produits) p.id: p};

    setState(() => _enCours = true);
    try {
      final batch = FirebaseFirestore.instance.batch();
      var n = 0;
      for (final id in _modifies) {
        final p = parId[id];
        final c = _ctrls[id];
        if (p == null || c == null) continue;
        final saisi = double.tryParse(c.text.trim().replaceAll(',', '.'));
        final usd = (saisi == null || saisi <= 0 || taux <= 0) ? null : saisi / taux;
        final egalNormal = usd != null && (usd - p.prixVente).abs() < 0.005;
        batch.update(_produits.doc(id), {
          'prixParBoutique.$b': (usd == null || egalNormal) ? FieldValue.delete() : usd,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        n++;
      }
      var horsLigne = false;
      await batch.commit().timeout(const Duration(seconds: 6), onTimeout: () {
        horsLigne = true;
      });
      if (!mounted) return;
      setState(() => _modifies.clear());
      messenger.showSnackBar(SnackBar(
        content: Text(horsLigne
            ? '$n prix enregistrés hors ligne (envoyés au retour du réseau)'
            : '$n prix enregistrés'),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profil = ref.watch(userProfileProvider).value;
    final boutiques = ref.watch(boutiquesActivesProvider(widget.entrepriseId));
    final currencyState = ref.watch(currencyProvider);
    final currency = currencyState.activeCurrency;
    final double taux =
        currencyState.activeCurrencyInfo.rateToUSD > 0 ? currencyState.activeCurrencyInfo.rateToUSD : 1.0;

    if (_boutique != null && !boutiques.any((b) => b.id == _boutique)) _boutique = null;

    Widget corps;
    if (profil != null && !profil.peutGererStock) {
      corps = _message(Icons.lock_outline, 'Accès réservé',
          'Il faut l\'autorisation « Gérer le stock » pour modifier les prix.');
    } else if (boutiques.length < 2) {
      corps = _message(Icons.storefront_outlined, 'Une seule boutique',
          'Créez au moins 2 boutiques pour définir des prix différents.');
    } else {
      corps = Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  key: ValueKey('boutique-$_boutique-${boutiques.length}'),
                  initialValue: _boutique,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Boutique',
                    prefixIcon: Icon(Icons.storefront_rounded),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  hint: const Text('Choisir la boutique…'),
                  items: [
                    for (final b in boutiques)
                      DropdownMenuItem(value: b.id, child: Text(b.nom, overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: _modifies.isNotEmpty ? null : _changerBoutique,
                ),
                const SizedBox(height: 10),
                TextField(
                  onChanged: (v) => setState(() => _recherche = v.trim().toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Rechercher un produit…',
                    prefixIcon: const Icon(Icons.search_rounded),
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _boutique == null
                ? _message(Icons.touch_app_outlined, 'Choisissez une boutique',
                    'Puis saisissez le prix de vente de chaque produit dans cette boutique.')
                : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _produits.snapshots(),
                    builder: (context, snap) {
                      if (snap.hasError) return _message(Icons.error_outline, 'Erreur', '${snap.error}');
                      if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                      final produits = snap.data!.docs.map(Produit.fromDocument).toList()
                        ..sort((a, b) => a.nom.toLowerCase().compareTo(b.nom.toLowerCase()));
                      final visibles = produits
                          .where((p) =>
                              _recherche.isEmpty ||
                              p.nom.toLowerCase().contains(_recherche) ||
                              p.codeBarre.toLowerCase().contains(_recherche))
                          .toList();

                      return Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                              itemCount: visibles.length,
                              itemBuilder: (context, i) => _ligne(visibles[i], taux, currency),
                            ),
                          ),
                          SafeArea(
                            top: false,
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                              color: Colors.white,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _modifies.isEmpty
                                          ? 'Champ vide = prix normal'
                                          : '${_modifies.length} prix modifié(s)',
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  FilledButton.icon(
                                    style: FilledButton.styleFrom(backgroundColor: _bleuNuit),
                                    onPressed: (_enCours || _modifies.isEmpty)
                                        ? null
                                        : () => _enregistrer(produits, taux),
                                    icon: const Icon(Icons.save_rounded),
                                    label: const Text('Enregistrer'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Prix par boutique', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: _bleuNuit,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: corps,
    );
  }

  Widget _ligne(Produit p, double taux, String currency) {
    final c = _ctrl(p, taux);
    final modifie = _modifies.contains(p.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: modifie ? Colors.amber.shade400 : Colors.black12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.nom,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: _bleuNuit)),
                Text('Prix normal : ${_fmt(p.prixVente, taux)} $currency',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 150,
            child: TextField(
              controller: c,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                isDense: true,
                hintText: _fmt(p.prixVente, taux),
                suffixText: currency,
                suffixStyle: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                hintStyle: TextStyle(color: Colors.grey.shade400),
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() => _modifies.add(p.id)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _message(IconData icone, String titre, String texte) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(titre, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(texte, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}
