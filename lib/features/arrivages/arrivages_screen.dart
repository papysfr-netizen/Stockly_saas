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

import 'package:stockly_saas/l10n/app_localizations.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/currency_provider.dart';
import '../../core/providers/user_role_provider.dart';
import '../../core/services/journal_service.dart';
import '../../core/services/utilisateur_service.dart';
import 'lots_service.dart';

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
      appBar: AppBar(title: Text(AppLocalizations.of(context).arrTitle)),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _arrivages(entrepriseId).orderBy('date', descending: true).limit(200).snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text(AppLocalizations.of(context).errorWith('${snap.error}')));
          }
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  AppLocalizations.of(context).arrEmpty,
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
                      if (numero.isNotEmpty) AppLocalizations.of(context).arrNo(numero),
                      fournisseur.isEmpty ? AppLocalizations.of(context).arrNoSupplier : fournisseur,
                    ].join(' · '),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      decoration: annule ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  subtitle: Text(
                    AppLocalizations.of(context).arrListLine(_date(d['date']), (d['nomBoutique'] ?? '').toString().isEmpty ? AppLocalizations.of(context).arrMainShop : d['nomBoutique'].toString(), '${d['nbProduits'] ?? 0}', '${d['totalPieces'] ?? 0}') + (annule ? ' · ${AppLocalizations.of(context).arrCancelledTag}' : ''),
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
  Future<Map<String, Map<String, dynamic>>>? _produits;

  /// Fiches des produits de l'arrivage (par paquets de 30)
  Future<Map<String, Map<String, dynamic>>> _lireProduits(List<Map> lignes) async {
    final ids = {
      for (final l in lignes)
        if ((l['produitId'] ?? '').toString().isNotEmpty) l['produitId'].toString(),
    }.toList();
    final col = FirebaseFirestore.instance
        .collection('entreprises')
        .doc(widget.entrepriseId)
        .collection('produits');
    final res = <String, Map<String, dynamic>>{};
    for (var i = 0; i < ids.length; i += 30) {
      final paquet = ids.skip(i).take(30).toList();
      final snap = await col.where(FieldPath.documentId, whereIn: paquet).get();
      for (final d in snap.docs) {
        res[d.id] = d.data();
      }
    }
    return res;
  }

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
      messenger.showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).arrNoNet)));
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
        title: Text(AppLocalizations.of(context).arrCancelQ),
        content: Text(
          AppLocalizations.of(context).arrCancelBody('${d['totalPieces'] ?? 0}') + (manquantes > 0 ? '\n\n⚠️ ${AppLocalizations.of(context).arrCancelMissing('$manquantes')}' : '') + (produits.length < lignes.length ? '\n\n${AppLocalizations.of(context).arrCancelDeleted('${lignes.length - produits.length}')}' : ''),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.of(context).no)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppLocalizations.of(context).arrCancelBtn),
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
        // 📦 Le lot de cet arrivage disparaît de la fiche produit
        final lot = ((produits[id]!['lots'] as List?) ?? const [])
            .whereType<Map>()
            .where((x) => x['a'] == widget.arrivageId)
            .toList();
        batch.update(ent.collection('produits').doc(id), {
          'quantite': FieldValue.increment(-q),
          if (b != 'principale') 'stocks.$b': FieldValue.increment(-q),
          if (lot.isNotEmpty) 'lots': FieldValue.arrayRemove(lot),
          'lotsVendus.${widget.arrivageId}': FieldValue.delete(),
          'lotsCA.${widget.arrivageId}': FieldValue.delete(),
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
        SnackBar(content: Text(AppLocalizations.of(context).arrCancelled), backgroundColor: Colors.green.shade700),
      );
    } on TimeoutException {
      messenger.showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context).arrCancelOffline)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).arrCancelError('$e'))));
    }
    if (mounted) setState(() => _enCours = false);
  }

  @override
  Widget build(BuildContext context) {
    final devise = ref.watch(currencyProvider);
    final peutStock = ref.watch(userProfileProvider).value?.peutGererStock ?? false;
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).arrSheet)),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _arrivages(widget.entrepriseId).doc(widget.arrivageId).snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final d = snap.data!.data();
          if (d == null) return Center(child: Text(AppLocalizations.of(context).arrNotFound));
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
                        fournisseur.isEmpty ? AppLocalizations.of(context).arrNoSupplier : fournisseur,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      if (numero.isNotEmpty) Text(AppLocalizations.of(context).arrPlNo(numero)),
                      const SizedBox(height: 6),
                      Text(AppLocalizations.of(context).arrReceived(_date(d['date'])) + ((d['parNom'] ?? '').toString().isEmpty ? '' : ' · ${d['parNom']}')),
                      Text(AppLocalizations.of(context).arrShop((d['nomBoutique'] ?? '').toString().isEmpty ? AppLocalizations.of(context).arrMainShop : d['nomBoutique'].toString())),
                      if ((d['nomFichier'] ?? '').toString().isNotEmpty) Text(AppLocalizations.of(context).arrFile('${d['nomFichier']}')),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(AppLocalizations.of(context).arrCounts('${d['nbProduits'] ?? 0}', '${d['totalPieces'] ?? 0}')),
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
                            AppLocalizations.of(context).arrCancelledOn(_date(d['annuleLe'])) + ((d['annulePar'] ?? '').toString().isEmpty ? '' : ' · ${d['annulePar']}'),
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              // 📦 Ventes de cet arrivage : vendu, reste, argent, bénéfice
              FutureBuilder<Map<String, Map<String, dynamic>>>(
                future: _produits ??= _lireProduits(lignes),
                builder: (context, snapP) {
                  final produits = snapP.data ?? const <String, Map<String, dynamic>>{};
                  var vendu = 0, reste = 0;
                  double ca = 0, cout = 0;
                  final suivi = <String, LotProduit>{};
                  for (final l in lignes) {
                    final id = (l['produitId'] ?? '').toString();
                    final p = produits[id];
                    if (p == null) continue;
                    final lot = LotsService.lots(p).where((x) => x.arrivageId == widget.arrivageId);
                    if (lot.isEmpty) continue;
                    suivi[id] = lot.first;
                    vendu += lot.first.venduBorne;
                    reste += lot.first.restant;
                    ca += lot.first.chiffreAffaires;
                    cout += lot.first.cout;
                  }
                  return Column(
                    children: [
                      if (!annule)
                        Card(
                          color: Colors.teal.withValues(alpha: 0.10),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: snapP.connectionState != ConnectionState.done
                                ? const Center(child: CircularProgressIndicator())
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(AppLocalizations.of(context).arrSales,
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      const SizedBox(height: 6),
                                      Text(AppLocalizations.of(context).arrSoldLeft('$vendu', '$reste')),
                                      Text(AppLocalizations.of(context).arrRevenue(devise.formatPrice(ca))),
                                      Text(AppLocalizations.of(context).arrCost(devise.formatPrice(cout))),
                                      Text(
                                        AppLocalizations.of(context).arrProfit(devise.formatPrice(ca - cout)),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: ca - cout >= 0 ? Colors.green.shade700 : Colors.red,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        AppLocalizations.of(context).arrOldestFirst,
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      for (final l in lignes)
                        Card(
                          child: ListTile(
                            dense: true,
                            title: Text((l['nom'] ?? '').toString()),
                            subtitle: Text(
                              '${(l['codeBarre'] ?? '').toString().isEmpty ? '' : '${l['codeBarre']} · '}'
                              '${AppLocalizations.of(context).arrLineCost(devise.formatPrice(_n(l['prixAchat'])))}'
                              '${_n(l['prixVente']) > 0 ? ' · ${AppLocalizations.of(context).arrLinePrice(devise.formatPrice(_n(l['prixVente'])))}' : ''}'
                              '${l['nouveau'] == true ? ' · ${AppLocalizations.of(context).arrLineNew}' : ''}'
                              '${suivi[l['produitId']] == null || annule ? '' : '\n${AppLocalizations.of(context).arrLineStats('${suivi[l['produitId']]!.venduBorne}', '${suivi[l['produitId']]!.restant}', devise.formatPrice(suivi[l['produitId']]!.marge))}'}',
                            ),
                            trailing: Text('× ${l['quantite']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                    ],
                  );
                },
              ),
              if (peutStock && !annule) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  icon: _enCours
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.undo),
                  label: Text(AppLocalizations.of(context).arrCancelThis),
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
