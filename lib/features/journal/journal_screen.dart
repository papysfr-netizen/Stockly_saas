import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:stockly_saas/core/services/journal_service.dart';

/// Carte des Paramètres qui ouvre le journal (propriétaire).
class JournalCard extends StatelessWidget {
  final String entrepriseId;
  const JournalCard({super.key, required this.entrepriseId});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.history_edu_rounded, color: Color(0xFF0052FF)),
        title: const Text('📒 Journal : qui a fait quoi',
            style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text(
            "Les actions de l'équipe jour par jour : ventes, retours, stock, dettes…"),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => JournalScreen(entrepriseId: entrepriseId),
          ),
        ),
      ),
    );
  }
}

/// Écran du journal : une journée à la fois, filtre par personne.
class JournalScreen extends StatefulWidget {
  final String entrepriseId;
  const JournalScreen({super.key, required this.entrepriseId});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  late DateTime _jour;
  late Stream<QuerySnapshot<Map<String, dynamic>>> _flux;
  String _personne = ''; // '' = tout le monde
  Map<String, String> _nomsBoutiques = {};
  // 🚚 Ventes pas encore (entièrement) livrées : id -> livrée en partie ?
  Map<String, bool> _aLivrer = {};
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _ecouteLivraisons;

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    _jour = DateTime(n.year, n.month, n.day);
    _majFlux();
    _chargerBoutiques();
    _ecouteLivraisons = FirebaseFirestore.instance
        .collection('entreprises')
        .doc(widget.entrepriseId)
        .collection('ventes')
        .where('statutLivraison', isEqualTo: 'Non livré')
        .snapshots()
        .listen((s) {
      if (!mounted) return;
      setState(() {
        _aLivrer = {
          for (final d in s.docs) d.id: d.data()['livraisonPartielle'] == true,
        };
      });
    }, onError: (Object _) {});
  }

  @override
  void dispose() {
    _ecouteLivraisons?.cancel();
    super.dispose();
  }

  /// Ligne « livré / à livrer » sous une vente du journal.
  String _etatLivraison(Map<String, dynamic> l) {
    if (l['action'] != ActionsJournal.vente) return '';
    final id = (l['reference'] ?? '').toString();
    if (id.isEmpty) return '';
    if (!_aLivrer.containsKey(id)) return '\n✅ Livré';
    return _aLivrer[id] == true ? '\n📦 Livré en partie' : '\n📦 À livrer';
  }

  void _majFlux() {
    final debut = _jour;
    final fin = DateTime(_jour.year, _jour.month, _jour.day + 1);
    _flux = FirebaseFirestore.instance
        .collection('entreprises')
        .doc(widget.entrepriseId)
        .collection('journal')
        .where('dateLocale', isGreaterThanOrEqualTo: Timestamp.fromDate(debut))
        .where('dateLocale', isLessThan: Timestamp.fromDate(fin))
        .orderBy('dateLocale', descending: true)
        .snapshots();
  }

  Future<void> _chargerBoutiques() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('entreprises')
          .doc(widget.entrepriseId)
          .collection('boutiques')
          .get();
      final noms = <String, String>{};
      for (final d in snap.docs) {
        final nom = (d.data()['nom'] ?? '').toString();
        if (nom.isNotEmpty) noms[d.id] = nom;
      }
      if (mounted) setState(() => _nomsBoutiques = noms);
    } catch (_) {
      // Sans les noms, on affiche l'identifiant de la boutique.
    }
  }

  String _boutique(String id) {
    if (_nomsBoutiques.containsKey(id)) return _nomsBoutiques[id]!;
    if (id.isEmpty || id == 'principale') return 'Boutique principale';
    return id;
  }

  static String _deux(int n) => n.toString().padLeft(2, '0');

  bool get _estAujourdhui {
    final n = DateTime.now();
    return _jour == DateTime(n.year, n.month, n.day);
  }

  String get _titreJour {
    final n = DateTime.now();
    final aujourdhui = DateTime(n.year, n.month, n.day);
    final date = '${_deux(_jour.day)}/${_deux(_jour.month)}/${_jour.year}';
    if (_jour == aujourdhui) return "Aujourd'hui · $date";
    if (_jour == DateTime(n.year, n.month, n.day - 1)) return 'Hier · $date';
    return date;
  }

  void _changerJour(int decalage) {
    setState(() {
      _jour = DateTime(_jour.year, _jour.month, _jour.day + decalage);
      _majFlux();
    });
  }

  Future<void> _choisirJour() async {
    final choisi = await showDatePicker(
      context: context,
      initialDate: _jour,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (choisi == null || !mounted) return;
    setState(() {
      _jour = DateTime(choisi.year, choisi.month, choisi.day);
      _majFlux();
    });
  }

  static IconData _icone(String action) {
    switch (action) {
      case ActionsJournal.vente:
        return Icons.point_of_sale_rounded;
      case ActionsJournal.retour:
        return Icons.undo_rounded;
      case ActionsJournal.annulation:
        return Icons.cancel_rounded;
      case ActionsJournal.produitAjoute:
        return Icons.add_box_rounded;
      case ActionsJournal.produitModifie:
        return Icons.edit_rounded;
      case ActionsJournal.produitSupprime:
        return Icons.delete_rounded;
      case ActionsJournal.transfert:
        return Icons.swap_horiz_rounded;
      case ActionsJournal.import:
        return Icons.upload_file_rounded;
      case ActionsJournal.paiementDette:
        return Icons.payments_rounded;
      case ActionsJournal.depense:
        return Icons.money_off_rounded;
      case ActionsJournal.compteClient:
        return Icons.account_balance_wallet_rounded;
      case ActionsJournal.livraison:
        return Icons.local_shipping_rounded;
      default:
        return Icons.history_rounded;
    }
  }

  static Color _couleur(String action) {
    switch (action) {
      case ActionsJournal.vente:
      case ActionsJournal.paiementDette:
        return Colors.green.shade700;
      case ActionsJournal.retour:
        return Colors.orange.shade800;
      case ActionsJournal.annulation:
      case ActionsJournal.produitSupprime:
      case ActionsJournal.depense:
        return Colors.red.shade700;
      case ActionsJournal.transfert:
        return Colors.purple.shade600;
      case ActionsJournal.import:
      case ActionsJournal.livraison:
        return Colors.teal.shade700;
      default:
        return const Color(0xFF0052FF);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('📒 Journal')),
      body: Column(
        children: [
          // ----- Choix du jour -----
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: () => _changerJour(-1),
                ),
                Expanded(
                  child: TextButton.icon(
                    icon: const Icon(Icons.calendar_month_rounded),
                    label: Text(_titreJour,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: _choisirJour,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: _estAujourdhui ? null : () => _changerJour(1),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _flux,
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Journal illisible : ${snap.error}',
                          textAlign: TextAlign.center),
                    ),
                  );
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final toutes = snap.data!.docs.map((d) => d.data()).toList();
                final personnes = <String>{
                  for (final l in toutes) (l['userNom'] ?? '').toString(),
                }..remove('');
                final choix = personnes.contains(_personne) ? _personne : '';
                final lignes = choix.isEmpty
                    ? toutes
                    : toutes.where((l) => l['userNom'] == choix).toList();

                if (toutes.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Aucune action notée ce jour-là.',
                          textAlign: TextAlign.center),
                    ),
                  );
                }

                // Résumé des ventes du jour (pour la personne choisie)
                var nbVentes = 0;
                num totalVentes = 0;
                for (final l in lignes) {
                  if (l['action'] == ActionsJournal.vente) {
                    nbVentes++;
                    final m = l['montant'];
                    if (m is num) totalVentes += m;
                  }
                }

                return Column(
                  children: [
                    // ----- Filtre par personne -----
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          for (final p in ['', ...personnes.toList()..sort()])
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(p.isEmpty ? 'Tout le monde' : p),
                                selected: choix == p,
                                onSelected: (_) => setState(() => _personne = p),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                      child: Text(
                        '${lignes.length} action(s) · $nbVentes vente(s) : '
                        '${totalVentes.toStringAsFixed(2)} \$',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.only(bottom: 24),
                        itemCount: lignes.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final l = lignes[i];
                          final action = (l['action'] ?? '').toString();
                          final quand = (l['dateLocale'] as Timestamp?)?.toDate();
                          final heure = quand == null
                              ? ''
                              : '${_deux(quand.hour)}:${_deux(quand.minute)}';
                          final m = l['montant'];
                          final montant =
                              m is num ? ' · ${m.toStringAsFixed(2)} \$' : '';
                          final couleur = _couleur(action);
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: couleur.withValues(alpha: 0.12),
                              child: Icon(_icone(action), color: couleur),
                            ),
                            title: Text(
                              '${ActionsJournal.titre(action)}$montant',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '${l['details'] ?? ''}\n'
                              '👤 ${l['userNom'] ?? '?'} · 🏬 ${_boutique((l['boutiqueId'] ?? '').toString())}'
                              '${_etatLivraison(l)}',
                            ),
                            isThreeLine: true,
                            trailing: Text(heure,
                                style: const TextStyle(fontWeight: FontWeight.bold)),
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
