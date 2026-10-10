// lib/features/boutiques/transferts_screen.dart
//
// 🔁 MULTI-BOUTIQUES — Étape 3b : transferts de stock entre boutiques.
//
// Principe (le stock TOTAL « quantite » ne change jamais lors d'un transfert) :
//   principale -> B : stocks.B += q   (la principale baisse automatiquement)
//   B -> principale : stocks.B -= q
//   B -> C          : stocks.B -= q ; stocks.C += q
// Chaque transfert est enregistré dans entreprises/{id}/transferts (historique).

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:stockly_saas/core/models/produit.dart';
import 'package:stockly_saas/core/providers/user_role_provider.dart';
import 'boutique_provider.dart';
import 'boutiques_screen.dart';

class TransfertsScreen extends ConsumerStatefulWidget {
  final String entrepriseId;
  const TransfertsScreen({super.key, required this.entrepriseId});

  @override
  ConsumerState<TransfertsScreen> createState() => _TransfertsScreenState();
}

class _TransfertsScreenState extends ConsumerState<TransfertsScreen> {
  static const Color _bleuNuit = Color(0xFF1E293B);
  static const String _principale = BoutiquesService.idPrincipale;

  String _de = _principale;
  String? _vers;
  final Map<String, int> _qte = {}; // produitId -> quantité à transférer
  final TextEditingController _rechercheCtrl = TextEditingController();
  String _recherche = '';
  bool _enCours = false;

  DocumentReference<Map<String, dynamic>> get _entRef =>
      FirebaseFirestore.instance.collection('entreprises').doc(widget.entrepriseId);

  @override
  void dispose() {
    _rechercheCtrl.dispose();
    super.dispose();
  }

  String _nomBoutique(List<Boutique> boutiques, String? id) =>
      boutiques.firstWhere((b) => b.id == id,
          orElse: () => Boutique(id: id ?? '', nom: id ?? '?', actif: true)).nom;

  int get _totalArticles => _qte.values.fold(0, (s, v) => s + v);

  // ------------------------------------------------------------------
  // VALIDATION DU TRANSFERT
  // ------------------------------------------------------------------
  Future<void> _valider(List<Produit> produits, List<Boutique> boutiques) async {
    final vers = _vers;
    if (vers == null || vers == _de) return;
    final messenger = ScaffoldMessenger.of(context);

    final parId = {for (final p in produits) p.id: p};
    final lignes = <Map<String, dynamic>>[];
    for (final e in _qte.entries) {
      if (e.value <= 0) continue;
      final p = parId[e.key];
      if (p == null) continue;
      final dispo = p.stockBoutique(_de);
      if (e.value > dispo) {
        messenger.showSnackBar(SnackBar(
          content: Text('« ${p.nom} » : seulement $dispo disponible(s) à ${_nomBoutique(boutiques, _de)}.'),
          backgroundColor: Colors.red,
        ));
        return;
      }
      lignes.add({'produitId': p.id, 'nom': p.nom, 'quantite': e.value});
    }
    if (lignes.isEmpty) return;

    final deNom = _nomBoutique(boutiques, _de);
    final versNom = _nomBoutique(boutiques, vers);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer le transfert'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$deNom  →  $versNom', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final l in lignes)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Expanded(child: Text('${l['nom']}', overflow: TextOverflow.ellipsis)),
                            Text('× ${l['quantite']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(),
              Text('Total : $_totalArticles article(s)'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Transférer')),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _enCours = true);
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final l in lignes) {
        final q = l['quantite'] as int;
        final maj = <String, dynamic>{'updatedAt': FieldValue.serverTimestamp()};
        if (_de != _principale) maj['stocks.$_de'] = FieldValue.increment(-q);
        if (vers != _principale) maj['stocks.$vers'] = FieldValue.increment(q);
        batch.update(_entRef.collection('produits').doc(l['produitId'] as String), maj);
      }

      final profil = ref.read(userProfileProvider).value;
      final transfertRef = _entRef.collection('transferts').doc();
      batch.set(transfertRef, {
        'id': transfertRef.id,
        'de': _de,
        'deNom': deNom,
        'vers': vers,
        'versNom': versNom,
        'lignes': lignes,
        'totalArticles': _totalArticles,
        'date': Timestamp.now(),
        'par': FirebaseAuth.instance.currentUser?.uid ?? '',
        'parNom': profil?.nom ?? '',
      });

      // Hors ligne : le transfert est gardé sur le téléphone et envoyé au retour du réseau.
      var horsLigne = false;
      await batch.commit().timeout(const Duration(seconds: 6), onTimeout: () {
        horsLigne = true;
      });

      if (!mounted) return;
      setState(() => _qte.clear());
      messenger.showSnackBar(SnackBar(
        content: Text(horsLigne
            ? 'Transfert enregistré hors ligne : il sera envoyé au retour du réseau.'
            : 'Transfert effectué : $deNom → $versNom'),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  // ------------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final profil = ref.watch(userProfileProvider).value;
    final boutiques = ref.watch(boutiquesActivesProvider(widget.entrepriseId));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        appBar: AppBar(
          title: const Text('Transferts de stock', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: _bleuNuit,
          foregroundColor: Colors.white,
          elevation: 0,
          bottom: const TabBar(
            indicatorColor: Colors.amber,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            tabs: [
              Tab(icon: Icon(Icons.swap_horiz_rounded), text: 'Nouveau'),
              Tab(icon: Icon(Icons.history_rounded), text: 'Historique'),
            ],
          ),
        ),
        body: (profil != null && !profil.peutGererStock)
            ? _message(Icons.lock_outline, 'Accès réservé',
                'Il faut l\'autorisation « Gérer le stock » pour faire des transferts.')
            : boutiques.length < 2
                ? _message(Icons.storefront_outlined, 'Une seule boutique',
                    'Créez au moins 2 boutiques (Paramètres → Mes boutiques) pour transférer du stock.')
                : TabBarView(
                    children: [
                      _ongletNouveau(boutiques),
                      _ongletHistorique(),
                    ],
                  ),
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

  // ------------------------------------------------------------------
  // ONGLET « NOUVEAU »
  // ------------------------------------------------------------------
  Widget _ongletNouveau(List<Boutique> boutiques) {
    if (!boutiques.any((b) => b.id == _de)) _de = boutiques.first.id;
    if (_vers != null && (!boutiques.any((b) => b.id == _vers) || _vers == _de)) _vers = null;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _entRef.collection('produits').snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return _message(Icons.error_outline, 'Erreur', '${snap.error}');
        }
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());

        final produits = snap.data!.docs.map(Produit.fromDocument).toList()
          ..sort((a, b) => a.nom.toLowerCase().compareTo(b.nom.toLowerCase()));
        final visibles = produits.where((p) {
          if (p.stockBoutique(_de) <= 0 && (_qte[p.id] ?? 0) == 0) return false;
          if (_recherche.isEmpty) return true;
          return p.nom.toLowerCase().contains(_recherche) ||
              p.codeBarre.toLowerCase().contains(_recherche);
        }).toList();

        return Column(
          children: [
            // De -> Vers
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              child: Row(
                children: [
                  Expanded(child: _choixBoutique('De', _de, boutiques, (v) {
                    setState(() {
                      _de = v!;
                      _qte.clear();
                      if (_vers == _de) _vers = null;
                    });
                  })),
                  IconButton(
                    tooltip: 'Inverser',
                    icon: const Icon(Icons.swap_horiz_rounded),
                    onPressed: _vers == null
                        ? null
                        : () => setState(() {
                              final ancienDe = _de;
                              _de = _vers!;
                              _vers = ancienDe;
                              _qte.clear();
                            }),
                  ),
                  Expanded(
                    child: _choixBoutique(
                      'Vers',
                      _vers,
                      boutiques.where((b) => b.id != _de).toList(),
                      (v) => setState(() => _vers = v),
                    ),
                  ),
                ],
              ),
            ),
            // Recherche
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: TextField(
                controller: _rechercheCtrl,
                onChanged: (v) => setState(() => _recherche = v.trim().toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Rechercher un produit…',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: Colors.white,
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
            ),
            // Produits
            Expanded(
              child: visibles.isEmpty
                  ? _message(Icons.inventory_2_outlined, 'Aucun produit disponible',
                      'Cette boutique n\'a pas de stock à transférer.')
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      itemCount: visibles.length,
                      itemBuilder: (context, i) => _ligneProduit(visibles[i]),
                    ),
            ),
            // Barre de validation
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, -2)),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _totalArticles == 0
                            ? 'Choisissez les quantités'
                            : '$_totalArticles article(s) • ${_qte.values.where((v) => v > 0).length} produit(s)',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: _bleuNuit),
                      onPressed: (_enCours || _vers == null || _totalArticles == 0)
                          ? null
                          : () => _valider(produits, boutiques),
                      icon: _enCours
                          ? const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.local_shipping_rounded),
                      label: const Text('Transférer'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _choixBoutique(String titre, String? valeur, List<Boutique> choix, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      key: ValueKey('$titre-$valeur-${choix.length}'),
      initialValue: choix.any((b) => b.id == valeur) ? valeur : null,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: titre,
        isDense: true,
        border: const OutlineInputBorder(),
      ),
      hint: const Text('Choisir…'),
      items: [
        for (final b in choix)
          DropdownMenuItem(value: b.id, child: Text(b.nom, overflow: TextOverflow.ellipsis)),
      ],
      onChanged: onChanged,
    );
  }

  Widget _ligneProduit(Produit p) {
    final dispo = p.stockBoutique(_de);
    final q = _qte[p.id] ?? 0;

    void changer(int nouvelle) {
      setState(() {
        final v = nouvelle.clamp(0, dispo);
        if (v == 0) {
          _qte.remove(p.id);
        } else {
          _qte[p.id] = v;
        }
      });
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: q > 0 ? Colors.indigo.shade200 : Colors.black12),
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
                Text('Disponible : $dispo', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: q > 0 ? () => changer(q - 1) : null,
          ),
          InkWell(
            onTap: () => _saisirQuantite(p, dispo, q, changer),
            child: Container(
              width: 44,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: q > 0 ? Colors.indigo.shade50 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('$q', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: q < dispo ? () => changer(q + 1) : null,
          ),
        ],
      ),
    );
  }

  Future<void> _saisirQuantite(Produit p, int dispo, int actuelle, void Function(int) changer) async {
    final ctrl = TextEditingController(text: actuelle == 0 ? '' : '$actuelle');
    final res = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(p.nom),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: 'Quantité (max $dispo)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, int.tryParse(ctrl.text.trim()) ?? 0),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (res != null) changer(res);
  }

  // ------------------------------------------------------------------
  // ONGLET « HISTORIQUE »
  // ------------------------------------------------------------------
  Widget _ongletHistorique() {
    final df = DateFormat('dd/MM/yyyy à HH:mm', 'fr_FR');
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _entRef
          .collection('transferts')
          .orderBy('date', descending: true)
          .limit(100)
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasError) return _message(Icons.error_outline, 'Erreur', '${snap.error}');
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return _message(Icons.history_rounded, 'Aucun transfert', 'Les transferts effectués apparaîtront ici.');
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final d = docs[i].data();
            final date = d['date'] is Timestamp ? (d['date'] as Timestamp).toDate() : null;
            final lignes = (d['lignes'] as List?) ?? const [];
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.indigo.shade50,
                  child: Icon(Icons.local_shipping_rounded, color: Colors.indigo.shade700),
                ),
                title: Text('${d['deNom'] ?? '?'}  →  ${d['versNom'] ?? '?'}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text([
                  if (date != null) df.format(date),
                  '${d['totalArticles'] ?? 0} article(s)',
                  if ((d['parNom'] ?? '').toString().isNotEmpty) 'par ${d['parNom']}',
                ].join(' • ')),
                onTap: () => showModalBottomSheet(
                  context: context,
                  builder: (_) => SafeArea(
                    child: ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text('${d['deNom']}  →  ${d['versNom']}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        if (date != null) Text(df.format(date), style: TextStyle(color: Colors.grey.shade600)),
                        const Divider(),
                        for (final l in lignes)
                          if (l is Map)
                            ListTile(
                              dense: true,
                              title: Text('${l['nom']}'),
                              trailing: Text('× ${l['quantite']}',
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
