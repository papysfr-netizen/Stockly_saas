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
import 'package:stockly_saas/l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:stockly_saas/core/models/user_model.dart';
import 'package:stockly_saas/core/providers/currency_provider.dart';
import 'package:stockly_saas/core/providers/depense_provider.dart';
import 'package:stockly_saas/core/providers/user_role_provider.dart';
import 'package:stockly_saas/features/boutiques/boutique_provider.dart';
import 'package:stockly_saas/features/debts/screens/debt_management_screen.dart';
import 'package:stockly_saas/features/debts/screens/depenses_screen.dart';
import 'package:stockly_saas/features/debts/screens/home_screen.dart';
import 'package:stockly_saas/views/caisse/caisse_screen.dart';
import 'package:stockly_saas/features/shell/accueil_widgets.dart';
import 'package:stockly_saas/features/shell/rapport_jour.dart';
import 'package:stockly_saas/core/providers/produit_provider.dart';
import 'package:stockly_saas/features/aide/aide_screen.dart';
import 'package:stockly_saas/features/comptes_clients/comptes_clients_screen.dart';
import 'package:stockly_saas/features/debts/screens/comptabilite_screen.dart';
import 'package:stockly_saas/features/livraisons/a_livrer_screen.dart';
import 'package:stockly_saas/features/ventes/historique_ventes_screen.dart';
import 'package:stockly_saas/features/comptes_clients/argent_caisse_comptes.dart';
import 'package:stockly_saas/features/cloture/cloture_screen.dart';
import 'package:stockly_saas/features/cloture/cloture_service.dart';
import 'package:stockly_saas/core/services/argent_vente.dart';
import 'package:stockly_saas/core/services/ventes_refusees.dart';

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
  Stream<QuerySnapshot<Map<String, dynamic>>>? _dettesPayeesDuJour; // 💰
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
      // 💰 Créances payées aujourd'hui (au moins un paiement depuis minuit)
      _dettesPayeesDuJour = FirebaseFirestore.instance
          .collection('entreprises')
          .doc(_entrepriseId)
          .collection('creances')
          .where('dernierPaiement', isGreaterThanOrEqualTo: Timestamp.fromDate(aujourdhui))
          .snapshots();
    }
    return _ventesDuJour!;
  }

  /// 💰 Créances payées aujourd'hui (recréé avec les ventes si on change de jour)
  Stream<QuerySnapshot<Map<String, dynamic>>> get _streamDettesPayees {
    _streamVentes();
    return _dettesPayeesDuJour!;
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

  /// 📉 Coût d'achat de ce que le client GARDE (comme le Rapport) :
  ///    coût de la vente − coût des articles retournés/annulés
  ///    + articles retournés abîmés (perte) − acompte gardé (gain).
  static double _coutNet(Map<String, dynamic> v) {
    final brut = _nombre(v['coutMarchandises']);
    final articles = v['articles'] ?? v['produits'] ?? v['items'];
    final ret = v['quantitesRetournees'];
    final ann = v['quantitesAnnulees'];
    double qteTotale = 0, qteRendue = 0, coutRendu = 0;
    var prixConnus = true;
    if (articles is List) {
      for (var i = 0; i < articles.length; i++) {
        final a = articles[i];
        if (a is! Map) continue;
        final q = _nombre(a['quantite']);
        var r = (ret is List && i < ret.length ? _nombre(ret[i]) : 0.0) +
            (ann is List && i < ann.length ? _nombre(ann[i]) : 0.0);
        if (r > q) r = q;
        qteTotale += q;
        qteRendue += r;
        if (r > 0) {
          final pa = _nombre(a['prixAchat']);
          if (pa > 0) {
            coutRendu += pa * r;
          } else {
            prixConnus = false;
          }
        }
      }
    }
    // Ancienne vente sans prix d'achat par article : au prorata des quantités
    if (!prixConnus && qteTotale > 0) coutRendu = brut * qteRendue / qteTotale;
    return brut - coutRendu + _nombre(v['coutAbimeRetours']) - _nombre(v['montantConserve']);
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
        title: Text(AppLocalizations.of(ctx).tauxTitle),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(prefixText: '1 \$ = ', suffixText: 'FC'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(ctx).cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, double.tryParse(ctrl.text.trim())),
            child: Text(AppLocalizations.of(ctx).save),
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
    final depenses = ref.watch(depensesDuJourProvider).value ?? const []; // 💸 du jour seulement

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
    final t = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF121418) : const Color(0xFFF3F5F7),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _streamDettesPayees,
        builder: (context, snapDettes) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _streamVentes(),
        builder: (context, snap) {
          double ventes = 0, encaisse = 0, credit = 0, cout = 0, remises = 0;
          final listeVentes = <Map<String, dynamic>>[];
          for (final doc in snap.data?.docs ?? const []) {
            final v = doc.data();
            if (!_memeBoutique(boutique, v['boutiqueId'])) continue;
            final total = _nombre(v['montantTotal'] ?? v['total']) -
                _nombre(v['montantRetourne']) -
                _nombre(v['montantAnnule']);
            ventes += total;
            // 💵 Argent reçu À LA VENTE (calcul unique : sans monnaie rendue ni compte client).
            //    Les remboursements des retours sont retirés à part, le jour du retour.
            encaisse += ArgentVente.cashALaVente(v);
            credit += _nombre(v['resteAPayer']);
            cout += _coutNet(v); // 📉 retours déduits (comme le Rapport)
            remises += _nombre(v['remiseTotale']);
            listeVentes.add(v);
          }
          listeVentes.sort((a, b) => (_date(b['date']) ?? minuit).compareTo(_date(a['date']) ?? minuit));
          // 💰 Dettes encaissées aujourd'hui (historique des paiements)
          double dettesEncaissees = 0;
          final encaissementsDettes = <Map<String, dynamic>>[];
          for (final doc in snapDettes.data?.docs ?? const []) {
            final c = doc.data();
            if (!_memeBoutique(boutique, c['boutiqueId'])) continue; // 🏬
            final creation = c['dateCreation'] ?? c['createdAt'];
            final paiements = c['paiements'];
            if (paiements is! List) continue;
            for (final p in paiements.whereType<Map>()) {
              final quand = _date(p['date']);
              if (quand == null || quand.isBefore(minuit)) continue;
              // Acompte donné à la CAISSE : déjà compté dans « Encaissé ».
              // (Une dette créée à la main n'a pas de vente : son acompte compte.)
              final deVente = (c['venteId'] ?? '').toString().isNotEmpty;
              if (deVente && creation is Timestamp && p['date'] == creation) continue;
              final montant = _nombre(p['montant']);
              dettesEncaissees += montant;
              encaissementsDettes.add({
                'nom': (c['nomTiers'] ?? c['nomClient'] ?? '').toString(),
                'date': quand,
                'montant': montant,
                'parNom': (p['parNom'] ?? '').toString(),
              });
            }
          }
          encaissementsDettes.sort(
              (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
          final solde = encaisse + dettesEncaissees - totalDepenses;

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
                              t.accHello(prenom),
                              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // 🏬 Propriétaire OU membre autorisé « Toutes les boutiques »
                          if (profil?.role.isOwner == true || profil?.peutToutesBoutiques == true)
                            SelecteurBoutique(entrepriseId: _entrepriseId)
                          else
                            _etiquetteBoutique(boutique),
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
                                '1 \$ = ${NumberFormat('#,##0', 'fr_FR').format(tauxCdf)} FC',
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

              // ---------- 🚨 Ventes refusées par le serveur ----------
              const SliverToBoxAdapter(child: AlerteVentesRefusees()),

              // ---------- La phrase du jour ----------
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: ResumeDuJour(
                    prenom: prenom,
                    nbVentes: listeVentes.length,
                    ventes: ventes,
                    benefice: ventes - cout - totalDepenses,
                    voirFinances: voirFinances,
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
                      color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1C1F26) : Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2A2E37) : Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Text(t.accToday,
                            style: TextStyle(fontSize: 12, letterSpacing: 1.2, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade600)),
                        const SizedBox(height: 4),
                        Text(
                          devise.formatPrice(ventes),
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: _vert),
                        ),
                        Text(t.accOfSales, style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade600)),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _petiteCase(t.accCashed, devise.formatPrice(encaisse), Icons.payments_rounded, _vert),
                            const SizedBox(width: 8),
                            _petiteCase(t.accCredit, devise.formatPrice(credit), Icons.receipt_long_rounded, Colors.indigo),
                            const SizedBox(width: 8),
                            _petiteCase(t.accExpenses, devise.formatPrice(totalDepenses), Icons.trending_down_rounded, Colors.red),
                          ],
                        ),
                        if (dettesEncaissees > 0.005) ...[
                          const SizedBox(height: 10),
                          Text(
                            t.accDebtsCollected(devise.formatPrice(dettesEncaissees)),
                            style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.w600),
                          ),
                        ],
                        if (voirFinances) ...[
                          const SizedBox(height: 12),
                          // 💵 Argent en caisse : + dépôts / − retraits en espèces des comptes clients
                          LigneArgentCaisse(
                            entrepriseId: widget.currentUser.entrepriseId,
                            debut: minuit,
                            soldeBase: solde,
                            boutique: boutique,
                            format: (x) => devise.formatPrice(x),
                            // 💵 EN GRAND : l'argent qui doit être dans la caisse
                            construire: (solde) => Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                            decoration: BoxDecoration(
                              color: (solde >= 0 ? _vert : Colors.red).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: (solde >= 0 ? _vert : Colors.red).withValues(alpha: 0.5)),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.account_balance_wallet_rounded, size: 18,
                                        color: solde >= 0 ? _vert : Colors.red),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        t.accCashInDrawer('').replaceAll(':', '').trim(),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: solde >= 0 ? _vert : Colors.red,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    devise.formatPrice(solde),
                                    style: TextStyle(
                                      fontSize: 34,
                                      fontWeight: FontWeight.bold,
                                      color: solde >= 0 ? _vert : Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ),
                        ],
                        if (voirFinances && remises > 0.005) ...[
                          const SizedBox(height: 8),
                          Text(
                            t.accDiscounts(devise.formatPrice(remises)),
                            style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.w600),
                          ),
                        ],
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _envoyerResume(
                              boutique: boutique,
                              nbVentes: listeVentes.length,
                              ventes: ventes,
                              encaisse: encaisse,
                              credit: credit,
                              depenses: totalDepenses,
                              solde: solde,
                              benefice: ventes - cout - totalDepenses,
                              voirFinances: voirFinances,
                              devise: devise,
                              taux: tauxCdf,
                              remises: remises,
                              dettesEncaissees: dettesEncaissees,
                              listeVentes: listeVentes,
                              encaissementsDettes: encaissementsDettes,
                            ),
                            icon: const Icon(Icons.send_rounded, color: Color(0xFF25D366)),
                            label: Text(t.accSendSummary),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
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
                      _grosBouton(t.navCaisse, Icons.point_of_sale_rounded, _vert, () => _ouvrir(const CaisseScreen())),
                      const SizedBox(width: 10),
                      _grosBouton(t.accExpense, Icons.upload_rounded, Colors.red,
                          voirFinances ? () => _ouvrir(const DepensesScreen()) : null),
                      const SizedBox(width: 10),
                      _grosBouton(t.accCredit, Icons.menu_book_rounded, Colors.indigo,
                          () => _ouvrir(const DebtManagementScreen())),
                      const SizedBox(width: 10),
                      _grosBouton(t.navStock, Icons.inventory_2_rounded, _bleu,
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
                      // 🔒 Clôture de caisse (état du jour)
                      _boutonCloture(t, boutique),
                      _raccourci(t.accSales, Icons.receipt_long_rounded, Colors.indigo,
                          () => _ouvrir(HistoriqueVentesScreen(entrepriseId: _entrepriseId))),
                      ALivrerNavButton(entrepriseId: _entrepriseId),
                      _raccourci(t.accClientAccounts, Icons.account_balance_wallet_rounded, Colors.teal,
                          () => _ouvrir(ComptesClientsScreen(entrepriseId: _entrepriseId))),
                      _raccourci(t.accHelp, Icons.menu_book_rounded, Colors.blueGrey,
                          () => _ouvrir(const AideScreen())),
                      if (voirFinances)
                        _raccourci(t.accAccounting, Icons.calculate_rounded, Colors.brown,
                            () => _ouvrir(ComptabiliteScreen(entrepriseId: _entrepriseId))),
                    ],
                  ),
                ),
              ),

              // ---------- À faire aujourd'hui ----------
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: AFaireAujourdhui(
                    entrepriseId: _entrepriseId,
                    boutique: boutique,
                    onOuvrirStock: () => _ouvrir(HomeScreen(currentUser: widget.currentUser)),
                    onOuvrirCredits: () => _ouvrir(const DebtManagementScreen()),
                  ),
                ),
              ),

              // ---------- Ventes du jour ----------
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
                  child: Text(t.accTodaySales(listeVentes.length),
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
                        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1C1F26) : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2A2E37) : Colors.grey.shade200),
                      ),
                      child: Text(
                        t.accNoSales,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade700, height: 1.4),
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
                          color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1C1F26) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2A2E37) : Colors.grey.shade200),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: (reste > 0.005 ? Colors.indigo : _vert).withValues(alpha: 0.12),
                            child: Icon(reste > 0.005 ? Icons.schedule_rounded : Icons.check_rounded,
                                color: reste > 0.005 ? Colors.indigo : _vert),
                          ),
                          title: Text(
                            (v['nomClient'] ?? '').toString().trim().isEmpty
                                ? t.accClient
                                : v['nomClient'].toString(),
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${d == null ? '' : DateFormat('HH:mm').format(d)}'
                            '${reste > 0.005 ? ' • ${t.accRemaining(devise.formatPrice(reste))}' : ''}',
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
              // ---------- 💰 Dettes encaissées aujourd'hui ----------
              if (encaissementsDettes.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                    child: Text(t.accDebtsCollectedTitle(encaissementsDettes.length),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                SliverList.builder(
                  itemCount: encaissementsDettes.length,
                  itemBuilder: (context, i) {
                    final e = encaissementsDettes[i];
                    final nom = (e['nom'] as String).trim();
                    final par = (e['parNom'] as String).trim();
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1C1F26) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2A2E37) : Colors.grey.shade200),
                        ),
                        child: ListTile(
                          onTap: () => _ouvrir(const DebtManagementScreen()),
                          leading: CircleAvatar(
                            backgroundColor: Colors.teal.withValues(alpha: 0.12),
                            child: const Icon(Icons.call_received_rounded, color: Colors.teal),
                          ),
                          title: Text(nom.isEmpty ? t.accClient : nom, overflow: TextOverflow.ellipsis),
                          subtitle: Text(
                            '${DateFormat('HH:mm').format(e['date'] as DateTime)}'
                            '${par.isEmpty ? '' : ' • $par'}',
                          ),
                          trailing: Text(
                            '+ ${devise.formatPrice(e['montant'] as double)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          );
        },
      ),
      ),
    );
  }

  // ---------- 📤 Résumé du jour par WhatsApp ----------
  Future<void> _envoyerResume({
    required String? boutique,
    required int nbVentes,
    required double ventes,
    required double encaisse,
    required double credit,
    required double depenses,
    required double solde,
    required double benefice,
    required bool voirFinances,
    required CurrencyState devise,
    required double taux,
    double remises = 0,
    double dettesEncaissees = 0,
    List<Map<String, dynamic>> listeVentes = const [],
    List<Map<String, dynamic>> encaissementsDettes = const [],
  }) async {
    final l = AppLocalizations.of(context); // langue de l'application (lue avant toute attente)
    // 📊 Résumé court ou rapport détaillé ?
    final choix = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(l.repChoiceTitle,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.short_text_rounded, color: Colors.teal),
              title: Text(l.repShort),
              subtitle: Text(l.repShortHint),
              onTap: () => Navigator.pop(ctx, 'court'),
            ),
            ListTile(
              leading: const Icon(Icons.article_rounded, color: Colors.indigo),
              title: Text(l.repDetailed),
              subtitle: Text(l.repDetailedHint),
              onTap: () => Navigator.pop(ctx, 'detail'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (choix == null || !mounted) return;
    final jours = l.sumDays.split(',');
    final now = DateTime.now();
    final date = '${jours[now.weekday - 1]} '
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}';
    final nomBoutique = boutique == null
        ? l.sumAllShops
        : ref
                .read(boutiquesActivesProvider(_entrepriseId))
                .where((b) => b.id == boutique)
                .map((b) => b.nom)
                .firstOrNull ??
            l.accMainShop;

    // 💵 Même « argent en caisse » que l'Accueil : + dépôts − retraits − remboursements (espèces)
    final caisseJour =
        await lireCaisseDuJour(_entrepriseId, DateTime(now.year, now.month, now.day), boutique);
    if (!mounted) return;
    final soldeReel = solde +
        caisseJour.depotsEspeces -
        caisseJour.retraitsEspeces -
        caisseJour.remboursementsEspeces;

    final t = StringBuffer()
      ..writeln('📊 *$nomBoutique — $date*')
      ..writeln(l.sumSales(nbVentes, devise.formatPrice(ventes)))
      ..writeln(l.sumCollected(devise.formatPrice(encaisse)))
      ..writeln(l.sumCredit(devise.formatPrice(credit)))
      ..writeln(l.sumExpenses(devise.formatPrice(depenses)));
    if (dettesEncaissees > 0.005) {
      t.writeln('💰 ${l.accDebtsCollected(devise.formatPrice(dettesEncaissees))}');
    }
    if (voirFinances) {
      t
        ..writeln(l.sumCash(devise.formatPrice(soldeReel)))
        ..writeln(l.sumProfit(devise.formatPrice(benefice)));
      if (remises > 0.005) {
        t.writeln('🏷️ ${l.accDiscounts(devise.formatPrice(remises))}');
      }
    }
    t
      ..writeln(l.sumRate(NumberFormat('#,##0', 'fr_FR').format(taux)))
      ..write(l.sumSentBy(widget.currentUser.nom));
    final resumeCourt = t.toString();
    String texte = resumeCourt;
    if (choix == 'detail') {
      final minuit = DateTime(now.year, now.month, now.day);
      final depJour = (ref.read(depensesDuJourProvider).value ?? const [])
          .where((d) => !d.date.isBefore(minuit) && _memeBoutique(boutique, d.boutiqueId))
          .toList();
      final stockBas = <MapEntry<String, num>>[];
      for (final p in ref.read(produitsStreamProvider).value ?? const []) {
        final num stock = p.stockBoutique(boutique);
        final seuil = p.toMap()['seuilAlerte'];
        final num limite = (seuil is num && seuil > 0) ? seuil : 5;
        if (stock > 0 && stock <= limite) stockBas.add(MapEntry(p.nom, stock));
      }
      texte = await RapportJour.detail(
        l: l,
        resumeCourt: resumeCourt,
        entrepriseId: _entrepriseId,
        ventes: listeVentes,
        depenses: depJour,
        dettesEncaissees: encaissementsDettes,
        stockBas: stockBas,
        prix: devise.formatPrice,
        boutique: boutique, // 🏬 rapport
      );
    }

    // WhatsApp d'abord (on choisit le contact), sinon le menu de partage
    try {
      final wa = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(texte)}');
      if (await launchUrl(wa, mode: LaunchMode.externalApplication)) return;
    } catch (_) {
      // WhatsApp absent : on passe au menu de partage
    }
    await Share.share(texte);
  }

  /// 🏬 Nom de la boutique de l'employé (lecture seule)
  Widget _etiquetteBoutique(String? id) {
    final boutiques = ref.watch(boutiquesActivesProvider(_entrepriseId));
    final nom = boutiques.where((b) => b.id == (id ?? 'principale')).map((b) => b.nom).firstOrNull ??
        AppLocalizations.of(context).accMainShop;
    return Container(
      constraints: const BoxConstraints(maxWidth: 170),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.storefront_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              nom,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  /// 🔒 « Clôturer la caisse » ou « Caisse clôturée à … » (boutique affichée)
  Widget _boutonCloture(AppLocalizations t, String? boutique) {
    void ouvrir() => _ouvrir(ClotureScreen(entrepriseId: _entrepriseId));
    if (boutique == null) {
      return _raccourci(t.cloButton, Icons.lock_clock_rounded, Colors.deepOrange, ouvrir);
    }
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: ClotureService.ecouter(_entrepriseId, boutique, DateTime.now()),
      builder: (context, snap) {
        final faite = snap.data?.exists == true;
        if (!faite) {
          return _raccourci(t.cloButton, Icons.lock_clock_rounded, Colors.deepOrange, ouvrir);
        }
        final quand = ClotureService.date(snap.data!.data()?['createdAt']) ?? DateTime.now();
        final heure = '${quand.hour.toString().padLeft(2, '0')}:${quand.minute.toString().padLeft(2, '0')}';
        return _raccourci(t.cloDoneAt(heure), Icons.lock_rounded, _vert, ouvrir);
      },
    );
  }

  Widget _raccourci(String titre, IconData icone, Color couleur, VoidCallback onTap) {
    return ActionChip(
      avatar: Icon(icone, size: 18, color: couleur),
      label: Text(titre, style: TextStyle(fontWeight: FontWeight.w600, color: couleur)),
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1C1F26) : Colors.white,
      side: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF343944) : Colors.grey.shade300),
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
            Text(titre, style: TextStyle(fontSize: 12, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade700)),
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
        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1C1F26) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2A2E37) : Colors.grey.shade200),
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
