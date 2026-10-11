// ============================================================================
// 🏠 NOUVEL ACCUEIL SIMPLE
//  - Solde du jour : Ventes, Encaissé, Crédit, Dépenses (boutique affichée)
//  - Taux du jour 1 $ = … FC (modifiable d'un geste)
//  - 4 gros boutons : Caisse, Dépense, Crédit, Stock
//  - Les dernières ventes du jour
// Cet écran ne fait qu'AFFICHER : il n'enregistre rien (sauf le taux).
// ============================================================================
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:stockly_saas/core/models/user_model.dart';
import 'package:stockly_saas/core/providers/currency_provider.dart';
import 'package:stockly_saas/core/providers/depense_provider.dart';
import 'package:stockly_saas/core/providers/user_role_provider.dart';
import 'package:stockly_saas/features/boutiques/boutique_provider.dart';
import 'package:stockly_saas/features/debts/screens/debt_management_screen.dart';
import 'package:stockly_saas/features/debts/screens/depenses_screen.dart';
import 'package:stockly_saas/features/debts/screens/home_screen.dart';
import 'package:stockly_saas/views/caisse/caisse_screen.dart';
import 'package:stockly_saas/features/comptes_clients/comptes_clients_screen.dart';
import 'package:stockly_saas/features/debts/screens/comptabilite_screen.dart';
import 'package:stockly_saas/features/livraisons/a_livrer_screen.dart';
import 'package:stockly_saas/features/ventes/historique_ventes_screen.dart';

const _vert = Color(0xFF0B7A5A);
const _bleu = Color(0xFF0052FF);

class AccueilScreen extends ConsumerStatefulWidget {
  final UserModel currentUser;

  const AccueilScreen({super.key, required this.currentUser});

  @override
  ConsumerState<AccueilScreen> createState() => _AccueilScreenState();
}

class _AccueilScreenState extends ConsumerState<AccueilScreen> {
  Stream<QuerySnapshot<Map<String, dynamic>>>? _ventesDuJour;
  DateTime? _jour;

  String get _entrepriseId => widget.currentUser.entrepriseId;

  /// Ventes depuis minuit (recréé automatiquement si on change de jour)
  Stream<QuerySnapshot<Map<String, dynamic>>> _streamVentes() {
    final now = DateTime.now();
    final aujourdhui = DateTime(now.year, now.month, now.day);
    if (_ventesDuJour == null || _jour != aujourdhui) {
      _jour = aujourdhui;
      _ventesDuJour = FirebaseFirestore.instance
          .collection('entreprises')
          .doc(_entrepriseId)
          .collection('ventes')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(aujourdhui))
          .snapshots();
    }
    return _ventesDuJour!;
  }

  // ---------- Lecture sûre des valeurs ----------
  static double _nombre(Object? v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', '.')) ?? 0.0;
    return 0.0;
  }

  static DateTime? _date(Object? v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  static bool _memeBoutique(String? choisie, Object? b) {
    if (choisie == null) return true;
    final s = (b ?? '').toString();
    return (s.isEmpty ? 'principale' : s) == choisie;
  }

  void _ouvrir(Widget ecran) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ecran));
  }

  // ---------- Modifier le taux ----------
  Future<void> _modifierTaux(double actuel) async {
    final ctrl = TextEditingController(text: actuel.toStringAsFixed(0));
    final nouveau = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Taux du jour'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(prefixText: '1 \$ = ', suffixText: 'FC'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, double.tryParse(ctrl.text.trim())),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    if (nouveau == null || nouveau <= 0) return;
    ref.read(currencyProvider.notifier).updateRate('CDF', nouveau, modifiedBy: widget.currentUser.nom);
  }

  @override
  Widget build(BuildContext context) {
    final devise = ref.watch(currencyProvider);
    final tauxCdf = devise.currencies['CDF']?.rateToUSD ?? devise.bccCdfRate;
    final boutique = ref.watch(boutiqueActiveProvider);
    final profil = ref.watch(userProfileProvider).value;
    final voirFinances = profil?.peutVoirFinances ?? false;
    final depenses = ref.watch(depensesStreamProvider).value ?? const [];

    // Dépenses du jour (boutique affichée)
    final now = DateTime.now();
    final minuit = DateTime(now.year, now.month, now.day);
    double totalDepenses = 0;
    for (final dep in depenses) {
      final d = _date(dep.date);
      if (d == null || d.isBefore(minuit)) continue;
      if (!_memeBoutique(boutique, dep.boutiqueId)) continue;
      totalDepenses += _nombre(dep.montant);
    }

    final prenom = widget.currentUser.nom.split(' ').first;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F7),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _streamVentes(),
        builder: (context, snap) {
          double ventes = 0, encaisse = 0, credit = 0;
          final listeVentes = <Map<String, dynamic>>[];
          for (final doc in snap.data?.docs ?? const []) {
            final v = doc.data();
            if (!_memeBoutique(boutique, v['boutiqueId'])) continue;
            final total = _nombre(v['montantTotal'] ?? v['total']) -
                _nombre(v['montantRetourne']) -
                _nombre(v['montantAnnule']);
            ventes += total;
            encaisse += _nombre(v['montantPaye']);
            credit += _nombre(v['resteAPayer']);
            listeVentes.add(v);
          }
          listeVentes.sort((a, b) => (_date(b['date']) ?? minuit).compareTo(_date(a['date']) ?? minuit));
          final solde = encaisse - totalDepenses;

          return CustomScrollView(
            slivers: [
              // ---------- En-tête vert ----------
              SliverToBoxAdapter(
                child: Container(
                  padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0B7A5A), Color(0xFF075E45)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Bonjour $prenom 👋',
                              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SelecteurBoutique(entrepriseId: _entrepriseId),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Taux du jour
                      InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => _modifierTaux(tauxCdf),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.currency_exchange_rounded, color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                '1 \$ = ${NumberFormat.decimalPattern('fr_FR').format(tauxCdf)} FC',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.edit_rounded, color: Colors.white70, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ---------- Solde du jour ----------
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Text("AUJOURD'HUI",
                            style: TextStyle(fontSize: 12, letterSpacing: 1.2, color: Colors.grey.shade600)),
                        const SizedBox(height: 4),
                        Text(
                          devise.formatPrice(ventes),
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: _vert),
                        ),
                        Text('de ventes', style: TextStyle(color: Colors.grey.shade600)),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _petiteCase('Encaissé', devise.formatPrice(encaisse), Icons.payments_rounded, _vert),
                            const SizedBox(width: 8),
                            _petiteCase('Crédit', devise.formatPrice(credit), Icons.receipt_long_rounded, Colors.indigo),
                            const SizedBox(width: 8),
                            _petiteCase('Dépenses', devise.formatPrice(totalDepenses), Icons.trending_down_rounded, Colors.red),
                          ],
                        ),
                        if (voirFinances) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                            decoration: BoxDecoration(
                              color: (solde >= 0 ? _vert : Colors.red).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Argent en caisse du jour : ${devise.formatPrice(solde)}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: solde >= 0 ? _vert : Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              // ---------- 4 gros boutons ----------
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      _grosBouton('Caisse', Icons.point_of_sale_rounded, _vert, () => _ouvrir(const CaisseScreen())),
                      const SizedBox(width: 10),
                      _grosBouton('Dépense', Icons.upload_rounded, Colors.red,
                          voirFinances ? () => _ouvrir(const DepensesScreen()) : null),
                      const SizedBox(width: 10),
                      _grosBouton('Crédit', Icons.menu_book_rounded, Colors.indigo,
                          () => _ouvrir(const DebtManagementScreen())),
                      const SizedBox(width: 10),
                      _grosBouton('Stock', Icons.inventory_2_rounded, _bleu,
                          () => _ouvrir(HomeScreen(currentUser: widget.currentUser))),
                    ],
                  ),
                ),
              ),

              // ---------- Plus ----------
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _raccourci('Ventes', Icons.receipt_long_rounded, Colors.indigo,
                          () => _ouvrir(HistoriqueVentesScreen(entrepriseId: _entrepriseId))),
                      ALivrerNavButton(entrepriseId: _entrepriseId),
                      _raccourci('Comptes clients', Icons.account_balance_wallet_rounded, Colors.teal,
                          () => _ouvrir(ComptesClientsScreen(entrepriseId: _entrepriseId))),
                      if (voirFinances)
                        _raccourci('Comptabilité', Icons.calculate_rounded, Colors.brown,
                            () => _ouvrir(ComptabiliteScreen(entrepriseId: _entrepriseId))),
                    ],
                  ),
                ),
              ),

              // ---------- Ventes du jour ----------
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
                  child: Text("Ventes d'aujourd'hui (${listeVentes.length})",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              if (snap.connectionState == ConnectionState.waiting && !snap.hasData)
                const SliverToBoxAdapter(
                  child: Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
                )
              else if (listeVentes.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(
                        'Pas encore de vente aujourd\'hui.\nAppuyez sur « Caisse » pour commencer.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade700, height: 1.4),
                      ),
                    ),
                  ),
                )
              else
                SliverList.builder(
                  itemCount: listeVentes.length > 10 ? 10 : listeVentes.length,
                  itemBuilder: (context, i) {
                    final v = listeVentes[i];
                    final d = _date(v['date']);
                    final reste = _nombre(v['resteAPayer']);
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: (reste > 0.005 ? Colors.indigo : _vert).withValues(alpha: 0.12),
                            child: Icon(reste > 0.005 ? Icons.schedule_rounded : Icons.check_rounded,
                                color: reste > 0.005 ? Colors.indigo : _vert),
                          ),
                          title: Text(
                            (v['nomClient'] ?? '').toString().trim().isEmpty
                                ? 'Client'
                                : v['nomClient'].toString(),
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${d == null ? '' : DateFormat('HH:mm').format(d)}'
                            '${reste > 0.005 ? ' • reste ${devise.formatPrice(reste)}' : ''}',
                          ),
                          trailing: Text(
                            devise.formatPrice(_nombre(v['montantTotal'] ?? v['total'])),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          );
        },
      ),
    );
  }

  Widget _raccourci(String titre, IconData icone, Color couleur, VoidCallback onTap) {
    return ActionChip(
      avatar: Icon(icone, size: 18, color: couleur),
      label: Text(titre, style: TextStyle(fontWeight: FontWeight.w600, color: couleur)),
      backgroundColor: Colors.white,
      side: BorderSide(color: Colors.grey.shade300),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onPressed: onTap,
    );
  }

  Widget _petiteCase(String titre, String valeur, IconData icone, Color couleur) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: couleur.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icone, color: couleur, size: 20),
            const SizedBox(height: 4),
            Text(titre, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(valeur, style: TextStyle(fontWeight: FontWeight.bold, color: couleur)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _grosBouton(String titre, IconData icone, Color couleur, VoidCallback? onTap) {
    final actif = onTap != null;
    return Expanded(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Opacity(
              opacity: actif ? 1 : 0.35,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: couleur.withValues(alpha: 0.12),
                    child: Icon(icone, color: couleur, size: 26),
                  ),
                  const SizedBox(height: 8),
                  Text(titre, style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
