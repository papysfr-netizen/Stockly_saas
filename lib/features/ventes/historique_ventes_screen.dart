import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/cart_provider.dart';
import '../../core/utils/currency_extension.dart';
import '../../screens/bon_livraison_screen.dart';

// ============================================================================
// 🧾 HISTORIQUE DES VENTES (les 500 plus récentes)
// ============================================================================
final historiqueVentesProvider = StreamProvider.family<
    List<QueryDocumentSnapshot<Map<String, dynamic>>>, String>((ref, entrepriseId) {
  if (entrepriseId.isEmpty) {
    return Stream.value(const <QueryDocumentSnapshot<Map<String, dynamic>>>[]);
  }
  return FirebaseFirestore.instance
      .collection('entreprises')
      .doc(entrepriseId)
      .collection('ventes')
      .orderBy('date', descending: true)
      .limit(500)
      .snapshots()
      .map((snap) => snap.docs);
});

DateTime _dateVente(Map<String, dynamic> d) {
  final v = d['date'] ?? d['createdAt'];
  if (v is Timestamp) return v.toDate();
  return DateTime(2000);
}

double _num(dynamic v) => v is num ? v.toDouble() : 0.0;

String _deux(int n) => n.toString().padLeft(2, '0');

String _formatDate(DateTime d) =>
    '${_deux(d.day)}/${_deux(d.month)}/${d.year} ${_deux(d.hour)}:${_deux(d.minute)}';

String _numeroFacture(String id) =>
    id.length >= 8 ? id.substring(0, 8).toUpperCase() : id.toUpperCase();

enum _Periode { aujourdhui, semaine, mois, tout }

extension on _Periode {
  String get label => switch (this) {
        _Periode.aujourdhui => "Aujourd'hui",
        _Periode.semaine => '7 jours',
        _Periode.mois => '30 jours',
        _Periode.tout => 'Tout',
      };
}

// ============================================================================
// 🧾 ÉCRAN
// ============================================================================
class HistoriqueVentesScreen extends ConsumerStatefulWidget {
  final String entrepriseId;
  const HistoriqueVentesScreen({super.key, required this.entrepriseId});

  @override
  ConsumerState<HistoriqueVentesScreen> createState() =>
      _HistoriqueVentesScreenState();
}

class _HistoriqueVentesScreenState extends ConsumerState<HistoriqueVentesScreen> {
  final _rechercheCtrl = TextEditingController();
  String _recherche = '';
  _Periode _periode = _Periode.aujourdhui;

  @override
  void dispose() {
    _rechercheCtrl.dispose();
    super.dispose();
  }

  bool _dansPeriode(DateTime d) {
    final now = DateTime.now();
    final debutJour = DateTime(now.year, now.month, now.day);
    switch (_periode) {
      case _Periode.aujourdhui:
        return !d.isBefore(debutJour);
      case _Periode.semaine:
        return !d.isBefore(debutJour.subtract(const Duration(days: 6)));
      case _Periode.mois:
        return !d.isBefore(debutJour.subtract(const Duration(days: 29)));
      case _Periode.tout:
        return true;
    }
  }

  bool _correspond(String id, Map<String, dynamic> d) {
    if (_recherche.isEmpty) return true;
    final q = _recherche;
    final client = (d['nomClient'] ?? '').toString().toLowerCase();
    final tel = (d['telephoneClient'] ?? '').toString().toLowerCase();
    final facture = _numeroFacture(id).toLowerCase();
    return client.contains(q) || tel.contains(q) || facture.contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(historiqueVentesProvider(widget.entrepriseId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des ventes'),
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Recherche
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              controller: _rechercheCtrl,
              onChanged: (v) => setState(() => _recherche = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Client, téléphone ou n° de facture…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _recherche.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _rechercheCtrl.clear();
                          setState(() => _recherche = '');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Période
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: _Periode.values
                  .map((p) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(p.label),
                          selected: _periode == p,
                          onSelected: (_) => setState(() => _periode = p),
                        ),
                      ))
                  .toList(),
            ),
          ),

          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Erreur de chargement : $e', textAlign: TextAlign.center),
                ),
              ),
              data: (docs) {
                final ventes = docs.where((doc) {
                  final d = doc.data();
                  return _dansPeriode(_dateVente(d)) && _correspond(doc.id, d);
                }).toList();

                double total = 0, encaisse = 0, reste = 0;
                for (final v in ventes) {
                  final d = v.data();
                  final t = _num(d['montantTotal']);
                  final r = _num(d['resteAPayer']);
                  total += t;
                  reste += r;
                  encaisse += (t - r);
                }

                return Column(
                  children: [
                    // Résumé
                    Container(
                      margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          _Resume(titre: 'Ventes', valeur: '${ventes.length}'),
                          _Resume(titre: 'Total', valeur: ref.formatPrice(total)),
                          _Resume(
                            titre: 'Encaissé',
                            valeur: ref.formatPrice(encaisse),
                            couleur: Colors.green.shade800,
                          ),
                          _Resume(
                            titre: 'Reste',
                            valeur: ref.formatPrice(reste),
                            couleur: reste > 0.005 ? Colors.red : Colors.grey.shade700,
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: ventes.isEmpty
                          ? const Center(
                              child: Text('Aucune vente pour cette recherche.',
                                  style: TextStyle(color: Colors.grey)),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                              itemCount: ventes.length,
                              itemBuilder: (context, i) {
                                final doc = ventes[i];
                                return _LigneVente(
                                  entrepriseId: widget.entrepriseId,
                                  venteId: doc.id,
                                  data: doc.data(),
                                );
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
    );
  }
}

// ============================================================================
// Petits blocs du résumé
// ============================================================================
class _Resume extends StatelessWidget {
  final String titre;
  final String valeur;
  final Color? couleur;
  const _Resume({required this.titre, required this.valeur, this.couleur});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(titre, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              valeur,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: couleur ?? Colors.indigo.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Badges
// ============================================================================
Widget _badge(String texte, Color couleur) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        texte,
        style: TextStyle(color: couleur, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );

Widget _badgePaiement(Map<String, dynamic> d) {
  final reste = _num(d['resteAPayer']);
  final total = _num(d['montantTotal']);
  if (reste <= 0.005) return _badge('Payé', Colors.green.shade700);
  if (reste < total - 0.005) return _badge('Partiel', Colors.orange.shade800);
  return _badge('Dette', Colors.red);
}

Widget _badgeLivraison(Map<String, dynamic> d) {
  final statut = (d['statutLivraison'] ?? 'Livré').toString();
  return statut == 'Non livré'
      ? _badge('À livrer', Colors.brown)
      : _badge('Livré', Colors.blueGrey);
}

// ============================================================================
// Ligne d'une vente + détail
// ============================================================================
class _LigneVente extends ConsumerWidget {
  final String entrepriseId;
  final String venteId;
  final Map<String, dynamic> data;

  const _LigneVente({
    required this.entrepriseId,
    required this.venteId,
    required this.data,
  });

  List<Map<String, dynamic>> get _articles {
    final brut = data['articles'];
    if (brut is! List) return [];
    return brut.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  void _ouvrirDetail(BuildContext context, WidgetRef ref) {
    final client = (data['nomClient'] ?? 'Client Divers').toString();
    final tel = (data['telephoneClient'] ?? '').toString();
    final total = _num(data['montantTotal']);
    final reste = _num(data['resteAPayer']);
    final articles = _articles;
    final livre = (data['statutLivraison'] ?? 'Livré').toString() != 'Non livré';
    final dateLiv = data['dateLivraison'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (ctx, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.all(18),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Facture ${_numeroFacture(venteId)}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            Text(_formatDate(_dateVente(data)), style: TextStyle(color: Colors.grey.shade700)),
            const SizedBox(height: 12),
            Row(children: [
              const Icon(Icons.person, size: 18),
              const SizedBox(width: 6),
              Expanded(child: Text(client, style: const TextStyle(fontWeight: FontWeight.w600))),
            ]),
            if (tel.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 24, top: 2),
                child: Text(tel),
              ),
            const SizedBox(height: 10),
            Wrap(spacing: 6, children: [_badgePaiement(data), _badgeLivraison(data)]),
            if (livre && dateLiv is Timestamp)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('Livré le ${_formatDate(dateLiv.toDate())}',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
              ),
            const Divider(height: 24),
            const Text('Articles', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            ...articles.map((a) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Expanded(child: Text('${a['quantite']} × ${a['nom']}')),
                      Text(ref.formatPrice(_num(a['totalItem']))),
                    ],
                  ),
                )),
            const Divider(height: 24),
            _ligneMontant('Total', ref.formatPrice(total), gras: true),
            _ligneMontant('Payé', ref.formatPrice(total - reste)),
            if (reste > 0.005)
              _ligneMontant('Reste à payer', ref.formatPrice(reste), couleur: Colors.red),
            _ligneMontant('Moyen', (data['methodePaiement'] ?? '-').toString()),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              icon: const Icon(Icons.description_outlined),
              label: const Text('Réimprimer le bon de livraison'),
              onPressed: () {
                final items = articles
                    .map((a) => CartItem(
                          id: (a['produitId'] ?? '').toString(),
                          nom: (a['nom'] ?? '').toString(),
                          prix: _num(a['prixUnitaire']),
                          quantite: (a['quantite'] is num) ? (a['quantite'] as num).toInt() : 0,
                          stock: 0,
                        ))
                    .toList();
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BonLivraisonScreen(
                      entrepriseId: entrepriseId,
                      nomClient: client,
                      adresseClient: '',
                      telephoneClient: tel,
                      articles: items,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _ligneMontant(String titre, String valeur, {bool gras = false, Color? couleur}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(titre)),
          Text(
            valeur,
            style: TextStyle(
              fontWeight: gras ? FontWeight.bold : FontWeight.normal,
              color: couleur,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = (data['nomClient'] ?? 'Client Divers').toString();
    final total = _num(data['montantTotal']);
    final nbArticles = _articles.fold<int>(
        0, (s, a) => s + ((a['quantite'] is num) ? (a['quantite'] as num).toInt() : 0));

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => _ouvrirDetail(context, ref),
        title: Text(client,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_formatDate(_dateVente(data))} • ${_numeroFacture(venteId)} • $nbArticles article(s)',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 4),
              Wrap(spacing: 6, children: [_badgePaiement(data), _badgeLivraison(data)]),
            ],
          ),
        ),
        trailing: Text(
          ref.formatPrice(total),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.indigo.shade800,
          ),
        ),
      ),
    );
  }
}