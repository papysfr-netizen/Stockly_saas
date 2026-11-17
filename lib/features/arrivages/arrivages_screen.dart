// 📦 ARRIVAGES : chaque packing list importée est une fiche à part
//
// entreprises/{id}/arrivages/{auto}
//   numero, fournisseur, boutiqueId, nomBoutique, nomFichier, date, statut
//   ('actif' | 'annule'), lignes [{produitId, nom, codeBarre, quantite,
//   prixAchat, prixVente, nouveau}], nbProduits, totalPieces, coutTotal, parNom
//
// Créée par l'import en mode « Arrivage » (packing_list_service.dart).
// Annuler une fiche retire ses quantités du stock (autorisation « Gérer le stock »).
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/currency_provider.dart';
import '../../core/providers/user_role_provider.dart';
import '../../core/services/journal_service.dart';
import '../../core/services/utilisateur_service.dart';

double _n(dynamic v) => v is num ? v.toDouble() : double.tryParse('${v ?? ''}') ?? 0.0;

String _date(dynamic d) {
  if (d is! Timestamp) return '…';
  final x = d.toDate();
  String deux(int v) => v.toString().padLeft(2, '0');
  return '${deux(x.day)}/${deux(x.month)}/${x.year} ${deux(x.hour)}:${deux(x.minute)}';
}

CollectionReference<Map<String, dynamic>> _arrivages(String entrepriseId) => FirebaseFirestore.instance
    .collection('entreprises')
    .doc(entrepriseId)
    .collection('arrivages');

/// Liste des arrivages, du plus récent au plus ancien
class ArrivagesScreen extends ConsumerWidget {
  final String entrepriseId;
  const ArrivagesScreen({super.key, required this.entrepriseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devise = ref.watch(currencyProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Arrivages (packing lists)')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _arrivages(entrepriseId).orderBy('date', descending: true).limit(200).snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Erreur : ${snap.error}'));
          }
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Aucun arrivage pour le moment.\n\nImportez une packing list en mode « Arrivage » '
                  '(Stock → Importer) : elle apparaîtra ici avec son fournisseur et ses produits.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final d = docs[i].data();
              final annule = d['statut'] == 'annule';
              final numero = (d['numero'] ?? '').toString();
              final fournisseur = (d['fournisseur'] ?? '').toString();
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: annule ? Colors.grey : Colors.teal,
                    child: const Icon(Icons.local_shipping_outlined, color: Colors.white),
                  ),
                  title: Text(
                    [
                      if (numero.isNotEmpty) 'N° $numero',
                      fournisseur.isEmpty ? 'Fournisseur non indiqué' : fournisseur,
                    ].join(' · '),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      decoration: annule ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  subtitle: Text(
                    '${_date(d['date'])} · ${(d['nomBoutique'] ?? '').toString().isEmpty ? 'Boutique principale' : d['nomBoutique']}\n'
                    '${d['nbProduits'] ?? 0} produit(s) · ${d['totalPieces'] ?? 0} pièce(s)'
                    '${annule ? ' · ANNULÉ' : ''}',
                  ),
                  isThreeLine: true,
                  trailing: Text(
                    devise.formatPrice(_n(d['coutTotal'])),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ArrivageDetailScreen(entrepriseId: entrepriseId, arrivageId: docs[i].id),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Une fiche d'arrivage : ses produits, son coût, et « Annuler l'arrivage »
class ArrivageDetailScreen extends ConsumerStatefulWidget {
  final String entrepriseId;
  final String arrivageId;
  const ArrivageDetailScreen({super.key, required this.entrepriseId, required this.arrivageId});

  @override
  ConsumerState<ArrivageDetailScreen> createState() => _ArrivageDetailScreenState();
}

class _ArrivageDetailScreenState extends ConsumerState<ArrivageDetailScreen> {
  bool _enCours = false;

  Future<void> _annuler(Map<String, dynamic> d) async {
    final messenger = ScaffoldMessenger.of(context);
    final lignes = ((d['lignes'] as List?) ?? const []).whereType<Map>().toList();
    final ent = FirebaseFirestore.instance.collection('entreprises').doc(widget.entrepriseId);
    final b = (d['boutiqueId'] ?? 'principale').toString();

    // Combien de pièces de cet arrivage ne sont plus en stock (déjà vendues) ?
    setState(() => _enCours = true);
    final produits = <String, Map<String, dynamic>>{};
    try {
      for (final l in lignes) {
        final id = (l['produitId'] ?? '').toString();
        if (id.isEmpty) continue;
        final p = await ent.collection('produits').doc(id).get().timeout(const Duration(seconds: 10));
        if (p.exists) produits[id] = p.data()!;
      }
    } catch (_) {
      if (mounted) setState(() => _enCours = false);
      messenger.showSnackBar(const SnackBar(content: Text('Pas de connexion internet : réessayez.')));
      return;
    }
    if (!mounted) return;
    setState(() => _enCours = false);

    var manquantes = 0;
    for (final l in lignes) {
      final p = produits[(l['produitId'] ?? '').toString()];
      if (p == null) continue;
      final stock = b == 'principale'
          ? _n(p['quantite']).toInt()
          : _n((p['stocks'] is Map ? p['stocks'] as Map : const {})[b]).toInt();
      final q = _n(l['quantite']).toInt();
      if (stock < q) manquantes += q - stock;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Annuler cet arrivage ?'),
        content: Text(
          'Les quantités de cette packing list seront RETIRÉES du stock '
          '(${d['totalPieces'] ?? 0} pièce(s)). Les prix modifiés par l\'import ne changent pas.'
          '${manquantes > 0 ? '\n\n⚠️ $manquantes pièce(s) ne sont plus en stock (déjà vendues ou sorties) : '
              'le stock de ces produits deviendra négatif.' : ''}'
          '${produits.length < lignes.length ? '\n\n${lignes.length - produits.length} produit(s) ont été supprimés depuis : ils sont ignorés.' : ''}',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Non')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Annuler l\'arrivage'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _enCours = true);
    try {
      final parNom = await nomUtilisateurConnecte();
      final batch = FirebaseFirestore.instance.batch();
      for (final l in lignes) {
        final id = (l['produitId'] ?? '').toString();
        if (!produits.containsKey(id)) continue;
        final q = _n(l['quantite']).toInt();
        batch.update(ent.collection('produits').doc(id), {
          'quantite': FieldValue.increment(-q),
          if (b != 'principale') 'stocks.$b': FieldValue.increment(-q),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      batch.update(_arrivages(widget.entrepriseId).doc(widget.arrivageId), {
        'statut': 'annule',
        'annuleLe': FieldValue.serverTimestamp(),
        'annulePar': parNom,
      });
      await batch.commit().timeout(const Duration(seconds: 15));
      unawaited(noterJournal(
        entrepriseId: widget.entrepriseId,
        action: ActionsJournal.import,
        details: 'Arrivage annulé${(d['numero'] ?? '').toString().isEmpty ? '' : ' n° ${d['numero']}'} · '
            '${d['totalPieces'] ?? 0} pièce(s) retirée(s) du stock',
        boutiqueId: b,
        reference: widget.arrivageId,
      ));
      messenger.showSnackBar(
        SnackBar(content: const Text('Arrivage annulé.'), backgroundColor: Colors.green.shade700),
      );
    } on TimeoutException {
      messenger.showSnackBar(const SnackBar(
          content: Text('Pas de connexion : l\'annulation partira au retour d\'internet.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Annulation impossible : $e')));
    }
    if (mounted) setState(() => _enCours = false);
  }

  @override
  Widget build(BuildContext context) {
    final devise = ref.watch(currencyProvider);
    final peutStock = ref.watch(userProfileProvider).value?.peutGererStock ?? false;
    return Scaffold(
      appBar: AppBar(title: const Text('Fiche d\'arrivage')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _arrivages(widget.entrepriseId).doc(widget.arrivageId).snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final d = snap.data!.data();
          if (d == null) return const Center(child: Text('Arrivage introuvable.'));
          final annule = d['statut'] == 'annule';
          final lignes = ((d['lignes'] as List?) ?? const []).whereType<Map>().toList();
          final numero = (d['numero'] ?? '').toString();
          final fournisseur = (d['fournisseur'] ?? '').toString();

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fournisseur.isEmpty ? 'Fournisseur non indiqué' : fournisseur,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      if (numero.isNotEmpty) Text('Packing list n° $numero'),
                      const SizedBox(height: 6),
                      Text('Reçu le ${_date(d['date'])}'
                          '${(d['parNom'] ?? '').toString().isEmpty ? '' : ' par ${d['parNom']}'}'),
                      Text('Boutique : ${(d['nomBoutique'] ?? '').toString().isEmpty ? 'principale' : d['nomBoutique']}'),
                      if ((d['nomFichier'] ?? '').toString().isNotEmpty) Text('Fichier : ${d['nomFichier']}'),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${d['nbProduits'] ?? 0} produit(s) · ${d['totalPieces'] ?? 0} pièce(s)'),
                          Text(
                            devise.formatPrice(_n(d['coutTotal'])),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      if (annule)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'ANNULÉ le ${_date(d['annuleLe'])}'
                            '${(d['annulePar'] ?? '').toString().isEmpty ? '' : ' par ${d['annulePar']}'}',
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              for (final l in lignes)
                Card(
                  child: ListTile(
                    dense: true,
                    title: Text((l['nom'] ?? '').toString()),
                    subtitle: Text(
                      '${(l['codeBarre'] ?? '').toString().isEmpty ? '' : '${l['codeBarre']} · '}'
                      'Achat ${devise.formatPrice(_n(l['prixAchat']))}'
                      '${_n(l['prixVente']) > 0 ? ' · Vente ${devise.formatPrice(_n(l['prixVente']))}' : ''}'
                      '${l['nouveau'] == true ? ' · nouveau produit' : ''}',
                    ),
                    trailing: Text('× ${l['quantite']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              if (peutStock && !annule) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  icon: _enCours
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.undo),
                  label: const Text('Annuler cet arrivage'),
                  onPressed: _enCours ? null : () => _annuler(d),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
