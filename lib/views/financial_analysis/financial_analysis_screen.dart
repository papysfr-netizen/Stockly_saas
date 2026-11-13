// lib/views/financial_analysis/financial_analysis_screen.dart
//
// Compte de résultat (P&L) – présentation professionnelle :
//  - périodes : Aujourd'hui, Hier, 7 jours, Ce mois, Mois dernier, Cette année, dates au choix
//  - carte « Résultat net » (vert = bénéfice, rouge = perte) + marge nette
//    + comparaison avec la période précédente
//  - indicateurs : CA net, marge brute %, nombre de ventes, panier moyen
//  - tableau du compte de résultat avec sous-totaux, chaque ligne détaillable

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';

import '../../core/providers/currency_provider.dart';
import '../../core/providers/user_role_provider.dart';
import '../../core/providers/depense_provider.dart';
import '../../core/services/report_export_service.dart';
import '../../features/boutiques/boutique_provider.dart';

import 'services/financial_calculation_service.dart';
import 'widgets/details_bottom_sheet.dart';
import 'widgets/recherche_client_sheet.dart';
import 'widgets/details_rapport_sheet.dart';

class FinancialAnalysisScreen extends ConsumerStatefulWidget {
  const FinancialAnalysisScreen({super.key});

  @override
  ConsumerState<FinancialAnalysisScreen> createState() => _FinancialAnalysisScreenState();
}

class _Periode {
  final String label;
  final DateTimeRange? range;
  final bool isCalendar;
  const _Periode(this.label, this.range, {this.isCalendar = false});
}

class _FinancialAnalysisScreenState extends ConsumerState<FinancialAnalysisScreen> {
  static const Color _bleuNuit = Color(0xFF1E293B);
  static const Color _vert = Color(0xFF0F9D58);
  static const Color _rouge = Color(0xFFD93025);
  // 🌙 Couleur des titres et montants : bleu nuit le jour, clair la nuit
  Color get _encre =>
      Theme.of(context).brightness == Brightness.dark ? const Color(0xFFE5E7EB) : _bleuNuit;

  int _selectedPeriodeIndex = 0;
  DateTimeRange? _customRange;

  // Dernier résultat (pour l'export)
  FinancialCalculationResult? _dernier;
  String _dernierePeriode = '';
  // 📊 Pour le rapport complet (export PDF / Excel)
  List<({String id, String nom, FinancialCalculationResult r})> _dernierComparatif = const [];
  List<QueryDocumentSnapshot> _derniersProduits = const [];
  String? _derniereBoutique;
  // 📋 Pour les détails touchables
  List<QueryDocumentSnapshot> _ventesToutes = const [];
  List<QueryDocumentSnapshot> _ventesAffichees = const [];
  List<dynamic> _depensesToutes = const [];
  List<dynamic> _depensesAffichees = const [];
  DateTimeRange? _periodeAffichee;
  // ⚡ Flux des ventes gardé tant que la période ne change pas
  String? _cleVentes;
  Stream<List<QueryDocumentSnapshot>>? _fluxVentes;
  Map<String, String> _nomsBoutiques = const {};

  // ------------------------------------------------------------------
  // PÉRIODES
  // ------------------------------------------------------------------
  static DateTime _jour(DateTime d) => DateTime(d.year, d.month, d.day);
  static DateTime _finJour(DateTime d) => DateTime(d.year, d.month, d.day, 23, 59, 59);

  List<_Periode> _periodes() {
    final now = DateTime.now();
    final aujourdHui = _jour(now);
    final hier = aujourdHui.subtract(const Duration(days: 1));
    final debutMois = DateTime(now.year, now.month, 1);
    final debutMoisDernier = DateTime(now.year, now.month - 1, 1);
    final finMoisDernier = DateTime(now.year, now.month, 0);

    final customLabel = _customRange != null
        ? '${DateFormat('dd/MM').format(_customRange!.start)} – ${DateFormat('dd/MM').format(_customRange!.end)}'
        : 'DATES…';

    return [
      _Periode("AUJOURD'HUI", DateTimeRange(start: aujourdHui, end: _finJour(now))),
      _Periode('HIER', DateTimeRange(start: hier, end: _finJour(hier))),
      _Periode('7 JOURS',
          DateTimeRange(start: aujourdHui.subtract(const Duration(days: 6)), end: _finJour(now))),
      _Periode('CE MOIS', DateTimeRange(start: debutMois, end: _finJour(now))),
      _Periode('MOIS DERNIER',
          DateTimeRange(start: debutMoisDernier, end: _finJour(finMoisDernier))),
      _Periode('CETTE ANNÉE', DateTimeRange(start: DateTime(now.year, 1, 1), end: _finJour(now))),
      _Periode(customLabel, _customRange, isCalendar: true),
    ];
  }

  /// Période précédente de même longueur (pour la comparaison).
  static DateTimeRange _periodePrecedente(DateTimeRange r) {
    final debut = _jour(r.start);
    final nbJours = _jour(r.end).difference(debut).inDays + 1;
    final finPrec = debut.subtract(const Duration(days: 1));
    final debutPrec = debut.subtract(Duration(days: nbJours));
    return DateTimeRange(start: debutPrec, end: _finJour(finPrec));
  }

  Future<void> _ouvrirDateRangePicker(int indexCalendrier) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDateRange: _customRange,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _bleuNuit,
            onPrimary: Colors.white,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        _customRange = DateTimeRange(start: _jour(picked.start), end: _finJour(picked.end));
        _selectedPeriodeIndex = indexCalendrier;
      });
    }
  }

  // ------------------------------------------------------------------
  // EXPORT
  // ------------------------------------------------------------------
  Future<void> _exporter(String type, String Function(double) fmt, String currency) async {
    final r = _dernier;
    if (r == null) return;
    final enTetes = ['Poste', 'Montant ($currency)'];
    final lignes = <List<String>>[
      ['Ventes brutes', fmt(r.ventesBrutes)],
      ['Retours et annulations', '-${fmt(r.retoursAnnulations)}'],
      ["CHIFFRE D'AFFAIRES NET", fmt(r.chiffreAffaires)],
      ['Coût des marchandises vendues', '-${fmt(r.coutAchatStockVendu)}'],
      ['MARGE BRUTE (${r.tauxMargeBrute.toStringAsFixed(1)} %)', fmt(r.margeBrute)],
      ['Autres produits (acomptes conservés)', fmt(r.autresProduits)],
      ['Charges et dépenses', '-${fmt(r.totalDepenses)}'],
      for (final e in r.depensesParCategorie.entries) ['   dont ${e.key}', '-${fmt(e.value)}'],
      ['Pertes (articles abîmés)', '-${fmt(r.pertes)}'],
      ['RÉSULTAT NET (${r.tauxMargeNette.toStringAsFixed(1)} %)', fmt(r.beneficeNet)],
      ['Nombre de ventes', '${r.nombreVentes}'],
      ['Panier moyen', fmt(r.panierMoyen)],
      ['Encaissé (payé à la vente)', fmt(r.encaisse)],
      ['Crédits accordés (reste à payer)', fmt(r.creditsAccordes)],
      // 🏬 Par boutique
      if (_dernierComparatif.isNotEmpty) ...[
        ['', ''],
        ['PAR BOUTIQUE', 'Résultat net'],
        for (final e in _dernierComparatif) ...[
          [e.nom.toUpperCase(), fmt(e.r.beneficeNet)],
          ['   CA net / nombre de ventes', '${fmt(e.r.chiffreAffaires)} / ${e.r.nombreVentes}'],
          ['   Encaissé / crédits', '${fmt(e.r.encaisse)} / ${fmt(e.r.creditsAccordes)}'],
          ['   Dépenses', '-${fmt(e.r.totalDepenses)}'],
          ["   Stock (prix d'achat)", fmt(_valeurStock(_derniersProduits, e.id))],
        ],
      ],
      // 👤 Par vendeur
      ['', ''],
      ['PAR VENDEUR', 'Vendu'],
      for (final e in (r.ventesParVendeur.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value))))
        ['${e.key} (${r.nbVentesParVendeur[e.key] ?? 0} vente(s))', fmt(e.value)],
      // 📦 Produits
      ['', ''],
      ['PRODUITS LES PLUS VENDUS', 'Montant'],
      for (final e in _topProduits(r).take(15))
        ['${e.key} (x${e.value[0].toStringAsFixed(e.value[0] % 1 == 0 ? 0 : 1)})', fmt(e.value[1])],
      ['', ''],
      ['NE BOUGENT PAS (en stock, aucune vente)', 'Stock / valeur achat'],
      for (final e in _listeDormants(_derniersProduits, r, _derniereBoutique).take(30))
        [
          '${e.code.isEmpty ? '' : '${e.code} · '}${e.nom}',
          '${e.qte.toStringAsFixed(e.qte % 1 == 0 ? 0 : 1)} / ${fmt(e.valeur)}',
        ],
    ];

    if (type == 'excel') {
      await ReportExportService.exporterExcel(
        titreRapport: 'Rapport complet $_dernierePeriode',
        enTetes: enTetes,
        lignes: lignes,
      );
    } else {
      await ReportExportService.exporterPDF(
        titreRapport: 'Rapport complet – $_dernierePeriode',
        nomBoutique: 'Nguli',
        enTetes: enTetes,
        lignes: lignes,
      );
    }
  }

  // ------------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final currencyState = ref.watch(currencyProvider);
    final currency = currencyState.activeCurrency;
    final activeInfo = currencyState.activeCurrencyInfo;

    // Montants enregistrés en USD -> convertis dans la devise affichée
    final double taux = activeInfo.rateToUSD > 0 ? activeInfo.rateToUSD : 1.0;
    final int decimales = taux >= 100 ? 0 : 2;
    final nf = NumberFormat(decimales == 0 ? '#,##0' : '#,##0.00', 'fr_FR');
    String fmt(double usd) => nf.format(usd * taux);

    final userProfile = ref.watch(userProfileProvider).value;
    final entrepriseId = userProfile?.entrepriseId ?? '';

    final depensesAsync = ref.watch(depensesStreamProvider);
    // 🏬 Boutique affichée (null = toutes les boutiques)
    final boutique = ref.watch(boutiqueActiveProvider);
    final boutiques = ref.watch(boutiquesActivesProvider(entrepriseId));
    final nomBoutique = boutique == null
        ? null
        : boutiques.where((b) => b.id == boutique).map((b) => b.nom).firstOrNull;
    final periodes = _periodes();
    if (_selectedPeriodeIndex >= periodes.length) _selectedPeriodeIndex = 0;

    final periode = periodes[_selectedPeriodeIndex];
    final dateRange = periode.range ?? periodes[0].range!;
    final rangePrec = _periodePrecedente(dateRange);

    Stream<QuerySnapshot>? produitsStream;
    Stream<List<QueryDocumentSnapshot>>? ventesStream;
    if (entrepriseId.isNotEmpty) {
      final racine = FirebaseFirestore.instance.collection('entreprises').doc(entrepriseId);
      produitsStream = racine.collection('produits').snapshots();
      // ⚡ Seulement les ventes de la période affichée ET de la période précédente
      //    (pour la comparaison), au lieu de TOUTES les ventes depuis le début.
      //    Les anciennes ventes dont la date est écrite en texte sont ajoutées.
      final debutLecture = _jour(rangePrec.start);
      final finLecture =
          DateTime(dateRange.end.year, dateRange.end.month, dateRange.end.day + 1);
      final cle = '$entrepriseId|$debutLecture|$finLecture';
      if (cle != _cleVentes || _fluxVentes == null) {
        _cleVentes = cle;
        final ventes = racine.collection('ventes');
        final recentes = ventes
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(debutLecture))
            .where('date', isLessThan: Timestamp.fromDate(finLecture))
            .snapshots();
        final anciennes = ventes.where('date', isGreaterThanOrEqualTo: '').snapshots();
        _fluxVentes = Rx.combineLatest2(
          recentes,
          anciennes,
          (QuerySnapshot<Map<String, dynamic>> a, QuerySnapshot<Map<String, dynamic>> b) =>
              <QueryDocumentSnapshot>[...a.docs, ...b.docs],
        ).shareReplay(maxSize: 1);
      }
      ventesStream = _fluxVentes;
    }

    final dfJour = DateFormat('d MMM yyyy', 'fr_FR');
    final libellePeriode = _jour(dateRange.start) == _jour(dateRange.end)
        ? dfJour.format(dateRange.start)
        : 'du ${dfJour.format(dateRange.start)} au ${dfJour.format(dateRange.end)}';

    final libelle = (boutiques.length < 2)
        ? libellePeriode
        : '$libellePeriode • ${nomBoutique ?? 'Toutes les boutiques'}';

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF121418) : const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text(
          'Compte de résultat',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: _bleuNuit,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Center(child: SelecteurBoutique(entrepriseId: entrepriseId)),
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            icon: const Icon(Icons.ios_share_rounded, color: Colors.white),
            tooltip: 'Exporter',
            onSelected: (v) => _exporter(v, fmt, currency),
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'excel',
                child: Row(children: [
                  Icon(Icons.table_chart, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Exporter vers Excel'),
                ]),
              ),
              PopupMenuItem(
                value: 'pdf',
                child: Row(children: [
                  Icon(Icons.picture_as_pdf, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Imprimer / PDF'),
                ]),
              ),
            ],
          ),
        ],
      ),
      body: entrepriseId.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 1. SÉLECTEUR DE PÉRIODE
                Container(
                  color: _bleuNuit,
                  padding: const EdgeInsets.only(top: 4, bottom: 12),
                  child: SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: periodes.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final p = periodes[index];
                        final selected = _selectedPeriodeIndex == index;
                        return InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            if (p.isCalendar) {
                              _ouvrirDateRangePicker(index);
                            } else {
                              setState(() => _selectedPeriodeIndex = index);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: selected ? Colors.white : Colors.white.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (p.isCalendar) ...[
                                  Icon(Icons.calendar_month_rounded,
                                      size: 15, color: selected ? _bleuNuit : Colors.white),
                                  const SizedBox(width: 6),
                                ],
                                Text(
                                  p.label,
                                  style: TextStyle(
                                    color: selected ? _bleuNuit : Colors.white,
                                    fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                                    fontSize: 12,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // 2. CALCUL EN TEMPS RÉEL
                Expanded(
                  child: depensesAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Center(
                      child: Text('Erreur dépenses : $err', style: const TextStyle(color: Colors.grey)),
                    ),
                    data: (toutesLesDepenses) => StreamBuilder<QuerySnapshot>(
                      stream: produitsStream,
                      builder: (context, snapProduits) => StreamBuilder<List<QueryDocumentSnapshot>>(
                        stream: ventesStream,
                        builder: (context, snapVentes) {
                          if (snapVentes.hasError || snapProduits.hasError) {
                            final erreur = snapVentes.error ?? snapProduits.error;
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  'Impossible de charger les données : $erreur',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.red.shade700),
                                ),
                              ),
                            );
                          }
                          if (snapVentes.connectionState == ConnectionState.waiting ||
                              snapProduits.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          final produits = snapProduits.data?.docs ?? [];
                          // 🏬 Ventes et dépenses de la boutique choisie
                          // (sans boutique = boutique principale)
                          final ventes = (snapVentes.data ?? []).where((d) {
                            if (boutique == null) return true;
                            final m = (d.data() as Map<String, dynamic>?) ?? const {};
                            final b = (m['boutiqueId'] ?? '').toString();
                            return (b.isEmpty ? 'principale' : b) == boutique;
                          }).toList();
                          final depensesBoutique = toutesLesDepenses.where((dep) {
                            if (boutique == null) return true;
                            final b = ((dep as dynamic).boutiqueId ?? '').toString();
                            return (b.isEmpty ? 'principale' : b) == boutique;
                          }).toList();

                          final r = FinancialCalculationService.computePL(
                            toutesLesDepenses: depensesBoutique,
                            produitsDocs: produits,
                            ventesDocs: ventes,
                            dateRange: dateRange,
                            entrepriseId: entrepriseId,
                          );
                          final prec = FinancialCalculationService.computePL(
                            toutesLesDepenses: depensesBoutique,
                            produitsDocs: produits,
                            ventesDocs: ventes,
                            dateRange: rangePrec,
                            entrepriseId: entrepriseId,
                          );

                          // 🏬 Comparatif des boutiques (quand « Toutes » est choisi)
                          final comparatif =
                              <({String id, String nom, FinancialCalculationResult r})>[];
                          if (boutique == null && boutiques.length >= 2) {
                            String bDe(Object? v) {
                              final s = (v ?? '').toString();
                              return s.isEmpty ? 'principale' : s;
                            }

                            final ids = <String>{'principale', ...boutiques.map((b) => b.id)};
                            for (final id in ids) {
                              final vB = (snapVentes.data ?? []).where((d) {
                                final m = (d.data() as Map<String, dynamic>?) ?? const {};
                                return bDe(m['boutiqueId']) == id;
                              }).toList();
                              final dB = toutesLesDepenses
                                  .where((dep) => bDe((dep as dynamic).boutiqueId) == id)
                                  .toList();
                              final rb = FinancialCalculationService.computePL(
                                toutesLesDepenses: dB,
                                produitsDocs: produits,
                                ventesDocs: vB,
                                dateRange: dateRange,
                                entrepriseId: entrepriseId,
                              );
                              final nom = boutiques
                                      .where((b) => b.id == id)
                                      .map((b) => b.nom)
                                      .firstOrNull ??
                                  (id == 'principale' ? 'Boutique principale' : id);
                              comparatif.add((id: id, nom: nom, r: rb));
                            }
                          }

                          _dernier = r;
                          _dernierComparatif = comparatif;
                          _derniersProduits = produits;
                          _derniereBoutique = boutique;
                          _dernierePeriode = libelle;
                          _ventesToutes = snapVentes.data ?? const [];
                          _ventesAffichees = ventes;
                          _depensesToutes = toutesLesDepenses;
                          _depensesAffichees = depensesBoutique;
                          _periodeAffichee = dateRange;
                          _nomsBoutiques = {for (final b in boutiques) b.id: b.nom};

                          return ListView(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                            children: [
                              // 🔎 Rechercher un client
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1C1F26) : Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                ),
                                icon: const Icon(Icons.person_search_rounded),
                                label: const Text('Rechercher un client'),
                                onPressed: () => RechercheClientSheet.ouvrir(
                                  context,
                                  entrepriseId: entrepriseId,
                                  ventes: ventes,
                                  periode: dateRange,
                                  libellePeriode: libelle,
                                  fmt: fmt,
                                  currency: currency,
                                ),
                              ),
                              const SizedBox(height: 14),
                              _carteResultat(r, prec, fmt, currency, libelle),
                              const SizedBox(height: 14),
                              _indicateurs(r, prec, fmt, currency),
                              const SizedBox(height: 10),
                              // 📊 Encaissé / crédits
                              Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(14),
                                      onTap: () => _ouvrirEncaisse(context, fmt, currency),
                                      child: _tuile(
                                      icone: Icons.payments_rounded,
                                      couleur: _vert,
                                      titre: 'Encaissé',
                                      valeur: fmt(r.encaisse),
                                      sousTitre: '$currency • payé à la vente',
                                    ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(14),
                                      onTap: () => _ouvrirCredits(context, fmt, currency),
                                      child: _tuile(
                                      icone: Icons.schedule_rounded,
                                      couleur: _rouge,
                                      titre: 'Crédits accordés',
                                      valeur: fmt(r.creditsAccordes),
                                      sousTitre: '$currency • reste à payer',
                                    ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              _titreSection('Compte de résultat', 'Touchez une ligne pour le détail'),
                              const SizedBox(height: 10),
                              _tableau(context, r, fmt, currency),
                              // 🏬 Par boutique
                              if (comparatif.isNotEmpty) ...[
                                const SizedBox(height: 20),
                                _titreSection('Par boutique', 'Toutes les boutiques'),
                                const SizedBox(height: 10),
                                _comparatif(comparatif, r, produits, fmt, currency),
                              ],
                              // 👤 Par vendeur
                              const SizedBox(height: 20),
                              _titreSection('Par vendeur', '${r.nombreVentes} vente(s)'),
                              const SizedBox(height: 10),
                              _vendeurs(r, fmt, currency),
                              // 📦 Produits
                              const SizedBox(height: 20),
                              _titreSection('Produits les plus vendus', 'Top 15'),
                              const SizedBox(height: 10),
                              _produitsVendus(r, fmt, currency),
                              const SizedBox(height: 20),
                              _titreSection('Ne bougent pas', 'En stock, aucune vente'),
                              const SizedBox(height: 10),
                              _dormants(produits, r, boutique, fmt, currency),
                              const SizedBox(height: 14),
                              Text(
                                'Montants en $currency • Comparaison avec la période précédente de même durée.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 11, color: (Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade600)),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // ------------------------------------------------------------------
  // WIDGETS
  // ------------------------------------------------------------------

  /// Variation en % par rapport à la période précédente (null si non calculable)
  static double? _variation(double actuel, double precedent) {
    if (precedent.abs() < 0.005) return null;
    return (actuel - precedent) / precedent.abs() * 100;
  }

  Widget _badgeVariation(double? v, {bool surFondCouleur = false}) {
    if (v == null) {
      return Text('— vs période préc.',
          style: TextStyle(
              fontSize: 11, color: surFondCouleur ? Colors.white70 : (Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade600)));
    }
    final hausse = v >= 0;
    final couleur = surFondCouleur ? Colors.white : (hausse ? _vert : _rouge);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(hausse ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            size: 13, color: couleur),
        const SizedBox(width: 2),
        Text(
          '${v.abs().toStringAsFixed(v.abs() >= 100 ? 0 : 1)} % vs période préc.',
          style: TextStyle(fontSize: 11, color: couleur, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _carteResultat(FinancialCalculationResult r, FinancialCalculationResult prec,
      String Function(double) fmt, String currency, String libellePeriode) {
    final aucuneActivite = r.nombreVentes == 0 && r.totalDepenses == 0;
    final couleur = aucuneActivite ? Colors.blueGrey.shade600 : (r.isProfit ? _vert : _rouge);
    final message = aucuneActivite
        ? 'Aucune activité sur cette période'
        : (r.isProfit ? 'Bénéfice' : 'Perte');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [couleur, Color.lerp(couleur, Colors.black, 0.25)!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: couleur.withValues(alpha: 0.30), blurRadius: 14, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('RÉSULTAT NET',
                  style: TextStyle(
                      color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(message,
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '${fmt(r.beneficeNet)} $currency',
              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 4),
          Text(libellePeriode, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 14),
          Container(height: 1, color: Colors.white24),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Marge nette', style: TextStyle(color: Colors.white70, fontSize: 11)),
                    const SizedBox(height: 2),
                    Text('${r.tauxMargeNette.toStringAsFixed(1)} %',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              _badgeVariation(_variation(r.beneficeNet, prec.beneficeNet), surFondCouleur: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _indicateurs(FinancialCalculationResult r, FinancialCalculationResult prec,
      String Function(double) fmt, String currency) {
    return Row(
      children: [
        Expanded(
          child: _tuile(
            icone: Icons.storefront_rounded,
            couleur: Colors.teal,
            titre: "CA net",
            valeur: fmt(r.chiffreAffaires),
            sousTitre: currency,
            variation: _variation(r.chiffreAffaires, prec.chiffreAffaires),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _tuile(
            icone: Icons.percent_rounded,
            couleur: Colors.indigo,
            titre: 'Marge brute',
            valeur: '${r.tauxMargeBrute.toStringAsFixed(1)} %',
            sousTitre: '${fmt(r.margeBrute)} $currency',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _tuile(
            icone: Icons.receipt_rounded,
            couleur: Colors.orange.shade800,
            titre: 'Ventes',
            valeur: '${r.nombreVentes}',
            sousTitre: 'Panier ${fmt(r.panierMoyen)}',
          ),
        ),
      ],
    );
  }

  Widget _tuile({
    required IconData icone,
    required Color couleur,
    required String titre,
    required String valeur,
    required String sousTitre,
    double? variation,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1C1F26) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, size: 16, color: couleur),
              const SizedBox(width: 6),
              Expanded(
                child: Text(titre,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade700, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(valeur,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _encre)),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(sousTitre, style: TextStyle(fontSize: 10, color: (Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade600))),
          ),
          if (variation != null) ...[
            const SizedBox(height: 4),
            FittedBox(fit: BoxFit.scaleDown, child: _badgeVariation(variation)),
          ],
        ],
      ),
    );
  }

  Widget _titreSection(String titre, String aide) {
    return Row(
      children: [
        Text(titre,
            style: TextStyle(color: _encre, fontSize: 16, fontWeight: FontWeight.bold)),
        const Spacer(),
        Text(aide, style: TextStyle(fontSize: 11, color: (Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade600))),
      ],
    );
  }

  Widget _tableau(BuildContext context, FinancialCalculationResult r,
      String Function(double) fmt, String currency) {
    final lignes = <Widget>[
      _ligne(
        libelle: 'Ventes brutes',
        montant: r.ventesBrutes,
        fmt: fmt,
        onTap: () => _detailVentes(context, r, fmt, currency),
      ),
      if (r.retoursAnnulations > 0.005)
        _ligne(
          libelle: 'Retours et annulations',
          montant: -r.retoursAnnulations,
          fmt: fmt,
          onTap: () => _detailSimple(context, 'Retours et annulations', r.detailsRetoursList,
              fmt, currency, negatif: true, icone: Icons.assignment_return_rounded),
        ),
      _sousTotal(libelle: "CHIFFRE D'AFFAIRES NET", montant: r.chiffreAffaires, fmt: fmt),
      _ligne(
        libelle: 'Coût des marchandises vendues',
        montant: -r.coutAchatStockVendu,
        fmt: fmt,
        onTap: () => _detailCout(context, r, fmt, currency),
      ),
      _sousTotal(
        libelle: 'MARGE BRUTE',
        complement: '${r.tauxMargeBrute.toStringAsFixed(1)} %',
        montant: r.margeBrute,
        fmt: fmt,
        onTap: () => _detailMarge(context, r, fmt, currency),
      ),
      if (r.autresProduits > 0.005)
        _ligne(
          libelle: 'Autres produits (acomptes conservés)',
          montant: r.autresProduits,
          fmt: fmt,
          onTap: () => _detailSimple(context, 'Acomptes conservés', r.detailsAutresProduitsList,
              fmt, currency, icone: Icons.savings_rounded),
        ),
      _ligne(
        libelle: 'Charges et dépenses',
        montant: -r.totalDepenses,
        fmt: fmt,
        onTap: () => _detailDepenses(context, r, fmt, currency),
      ),
      if (r.pertes > 0.005)
        _ligne(
          libelle: 'Pertes (articles abîmés)',
          montant: -r.pertes,
          fmt: fmt,
          onTap: () => _detailSimple(context, 'Pertes : articles abîmés', r.detailsPertesList,
              fmt, currency, negatif: true, icone: Icons.broken_image_outlined),
        ),
      _total(r, fmt, currency),
    ];

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1C1F26) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(children: lignes),
    );
  }

  Widget _ligne({
    required String libelle,
    required double montant,
    required String Function(double) fmt,
    VoidCallback? onTap,
  }) {
    final negatif = montant < -0.005;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2A2E37) : Colors.grey.shade200)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(libelle, style: TextStyle(fontSize: 14, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade300 : Colors.grey.shade800)),
            ),
            Text(
              negatif ? '− ${fmt(-montant)}' : fmt(montant),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: negatif ? _rouge : _encre,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: onTap == null ? Colors.transparent : Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _sousTotal({
    required String libelle,
    required double montant,
    required String Function(double) fmt,
    String? complement,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF232733) : const Color(0xFFF1F5F9),
          border: Border(bottom: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF343944) : Colors.grey.shade300)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(libelle,
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w800, color: _encre, letterSpacing: 0.3)),
                  ),
                  if (complement != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.indigo.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(complement,
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.bold, color: Colors.indigo.shade700)),
                    ),
                  ],
                ],
              ),
            ),
            Text(
              montant < -0.005 ? '− ${fmt(-montant)}' : fmt(montant),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: montant < -0.005 ? _rouge : _encre,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: onTap == null ? Colors.transparent : Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _total(FinancialCalculationResult r, String Function(double) fmt, String currency) {
    final couleur = r.isProfit ? _vert : _rouge;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      color: couleur.withValues(alpha: 0.08),
      child: Row(
        children: [
          Expanded(
            child: Text('RÉSULTAT NET',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: _encre, letterSpacing: 0.5)),
          ),
          Text(
            '${r.beneficeNet < -0.005 ? '− ${fmt(-r.beneficeNet)}' : fmt(r.beneficeNet)} $currency',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: couleur,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 22),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // 📊 RAPPORT DU PATRON : boutiques, vendeurs, produits
  // ------------------------------------------------------------------
  static double _n(Object? v) {
    if (v is num) return v.toDouble();
    return double.tryParse((v ?? '').toString().replaceAll(',', '.')) ?? 0;
  }

  /// Stock d'un produit dans une boutique (null = toutes les boutiques)
  static double _stockDans(Map<String, dynamic> p, String? b) {
    final total = _n(p['quantite'] ?? p['stock']);
    if (b == null) return total;
    final stocks = p['stocks'] is Map ? p['stocks'] as Map : const {};
    if (b != 'principale') return _n(stocks[b]);
    var autres = 0.0;
    stocks.forEach((k, v) {
      if (k != 'principale') autres += _n(v);
    });
    final reste = total - autres;
    return reste < 0 ? 0 : reste;
  }

  /// Produits vendus : nom -> [quantité, montant], du plus vendu au moins vendu
  static List<MapEntry<String, List<double>>> _topProduits(FinancialCalculationResult r) {
    final parNom = <String, List<double>>{};
    for (final it in r.detailsVentesList) {
      final p = parNom.putIfAbsent((it['nom'] ?? '').toString(), () => [0, 0]);
      p[0] += _n(it['qte']);
      p[1] += _n(it['total']);
    }
    return parNom.entries.toList()..sort((a, b) => b.value[1].compareTo(a.value[1]));
  }

  /// Produits en stock sans vente sur la période (le plus d'argent immobilisé d'abord)
  static List<({String nom, String code, double qte, double valeur})> _listeDormants(
      List<QueryDocumentSnapshot> produits, FinancialCalculationResult r, String? boutique) {
    final vendus = r.detailsVentesList
        .map((it) => (it['nom'] ?? '').toString().trim().toLowerCase())
        .toSet();
    final liste = <({String nom, String code, double qte, double valeur})>[];
    for (final d in produits) {
      final p = (d.data() as Map<String, dynamic>?) ?? const <String, dynamic>{};
      final q = _stockDans(p, boutique);
      if (q <= 0) continue;
      final nom = (p['nom'] ?? '').toString();
      if (vendus.contains(nom.trim().toLowerCase())) continue;
      liste.add((
        nom: nom,
        code: (p['codeBarre'] ?? '').toString().trim(),
        qte: q,
        valeur: q * _n(p['prixAchat'] ?? p['prix_achat']),
      ));
    }
    return liste..sort((a, b) => b.valeur.compareTo(a.valeur));
  }

  /// Valeur du stock au prix d'achat
  static double _valeurStock(List<QueryDocumentSnapshot> produits, String? b) {
    var s = 0.0;
    for (final d in produits) {
      final p = (d.data() as Map<String, dynamic>?) ?? const <String, dynamic>{};
      final q = _stockDans(p, b);
      if (q > 0) s += q * _n(p['prixAchat'] ?? p['prix_achat']);
    }
    return s;
  }

  Widget _carteBlanche(List<Widget> enfants) => Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1C1F26) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: enfants),
      );

  Widget _aucun() => Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Aucune donnée sur cette période',
            style: TextStyle(color: (Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade600))),
      );

  Widget _petit(String t, String v) => Text.rich(TextSpan(children: [
        TextSpan(text: '$t : ', style: TextStyle(fontSize: 11, color: (Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade600))),
        TextSpan(
            text: v,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _encre)),
      ]));

  Widget _blocBoutique(String nom, FinancialCalculationResult x, double stock,
      String Function(double) fmt, String currency,
      {bool total = false, VoidCallback? onTap}) {
    final couleur = x.beneficeNet >= 0 ? _vert : _rouge;
    return InkWell(
      onTap: onTap,
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? (total ? const Color(0xFF232733) : const Color(0xFF1C1F26))
            : (total ? const Color(0xFFF1F5F9) : Colors.white),
        border: Border(bottom: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2A2E37) : Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(total ? Icons.functions_rounded : Icons.storefront_rounded,
                  size: 16, color: _encre),
              const SizedBox(width: 6),
              Expanded(
                child: Text(nom,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontWeight: total ? FontWeight.w900 : FontWeight.bold,
                        color: _encre)),
              ),
              Text(
                '${x.beneficeNet < -0.005 ? '− ${fmt(-x.beneficeNet)}' : fmt(x.beneficeNet)} $currency',
                style: TextStyle(fontWeight: FontWeight.w800, color: couleur),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              _petit('CA', fmt(x.chiffreAffaires)),
              _petit('Ventes', '${x.nombreVentes}'),
              _petit('Encaissé', fmt(x.encaisse)),
              _petit('Crédits', fmt(x.creditsAccordes)),
              _petit('Dépenses', fmt(x.totalDepenses)),
              _petit('Stock (achat)', fmt(stock)),
            ],
          ),
        ],
      ),
    ),
    );
  }

  Widget _comparatif(
      List<({String id, String nom, FinancialCalculationResult r})> liste,
      FinancialCalculationResult total,
      List<QueryDocumentSnapshot> produits,
      String Function(double) fmt,
      String currency) {
    final tri = [...liste]..sort((a, b) => b.r.chiffreAffaires.compareTo(a.r.chiffreAffaires));
    return _carteBlanche([
      for (final e in tri)
        _blocBoutique(e.nom, e.r, _valeurStock(produits, e.id), fmt, currency,
            onTap: () => _ouvrirBoutique(context, e.id, e.nom, fmt, currency)),
      _blocBoutique('TOTAL', total, _valeurStock(produits, null), fmt, currency,
          total: true,
          onTap: () => _ouvrirBoutique(context, null, 'Toutes les boutiques', fmt, currency)),
    ]);
  }

  Widget _vendeurs(FinancialCalculationResult r, String Function(double) fmt, String currency) {
    final tri = r.ventesParVendeur.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    if (tri.isEmpty) return _carteBlanche([_aucun()]);
    final max = tri.first.value <= 0 ? 1.0 : tri.first.value;
    return _carteBlanche([
      for (final e in tri)
        InkWell(
          onTap: () => _ouvrirVendeur(context, e.key, fmt, currency),
          child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.person_rounded, size: 16, color: Colors.indigo),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(e.key,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  Text('${r.nbVentesParVendeur[e.key] ?? 0} vente(s) • ',
                      style: TextStyle(fontSize: 12, color: (Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade600))),
                  Text('${fmt(e.value)} $currency',
                      style: TextStyle(fontWeight: FontWeight.bold, color: _encre)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (e.value / max).clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2A2E37) : Colors.grey.shade200,
                  color: Colors.indigo,
                ),
              ),
            ],
          ),
        ),
        ),
    ]);
  }

  Widget _produitsVendus(
      FinancialCalculationResult r, String Function(double) fmt, String currency) {
    final parNom = <String, List<double>>{};
    for (final it in r.detailsVentesList) {
      final p = parNom.putIfAbsent((it['nom'] ?? '').toString(), () => [0, 0]);
      p[0] += _n(it['qte']);
      p[1] += _n(it['total']);
    }
    final tri = parNom.entries.toList()..sort((a, b) => b.value[1].compareTo(a.value[1]));
    if (tri.isEmpty) return _carteBlanche([_aucun()]);
    return _carteBlanche([
      for (var i = 0; i < tri.length && i < 15; i++)
        ListTile(
          dense: true,
          leading: CircleAvatar(
            radius: 13,
            backgroundColor: Colors.teal.withValues(alpha: 0.12),
            child: Text('${i + 1}',
                style: const TextStyle(
                    fontSize: 11, color: Colors.teal, fontWeight: FontWeight.bold)),
          ),
          title: Text(tri[i].key, overflow: TextOverflow.ellipsis),
          subtitle: Text(
              '${tri[i].value[0].toStringAsFixed(tri[i].value[0] % 1 == 0 ? 0 : 1)} pièce(s)'),
          trailing: Text('${fmt(tri[i].value[1])} $currency',
              style: TextStyle(fontWeight: FontWeight.bold, color: _encre)),
        ),
      if (tri.length > 15)
        Padding(
          padding: const EdgeInsets.all(10),
          child: Text('… et ${tri.length - 15} autre(s)',
              style: TextStyle(fontSize: 12, color: (Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade600))),
        ),
    ]);
  }

  Widget _dormants(List<QueryDocumentSnapshot> produits, FinancialCalculationResult r,
      String? boutique, String Function(double) fmt, String currency) {
    final vendus = r.detailsVentesList
        .map((it) => (it['nom'] ?? '').toString().trim().toLowerCase())
        .toSet();
    final liste = <({String nom, String code, double qte, double valeur})>[];
    for (final d in produits) {
      final p = (d.data() as Map<String, dynamic>?) ?? const <String, dynamic>{};
      final q = _stockDans(p, boutique);
      if (q <= 0) continue;
      final nom = (p['nom'] ?? '').toString();
      if (vendus.contains(nom.trim().toLowerCase())) continue;
      liste.add((
        nom: nom,
        code: (p['codeBarre'] ?? '').toString().trim(),
        qte: q,
        valeur: q * _n(p['prixAchat'] ?? p['prix_achat']),
      ));
    }
    liste.sort((a, b) => b.valeur.compareTo(a.valeur));
    if (liste.isEmpty) {
      return _carteBlanche([
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Tous les produits en stock se sont vendus 👍',
              style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade700)),
        ),
      ]);
    }
    final valeurTotale = liste.fold<double>(0, (s, e) => s + e.valeur);
    return _carteBlanche([
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
        child: Text(
          "${liste.length} produit(s) • ${fmt(valeurTotale)} $currency immobilisés (prix d'achat)",
          style: TextStyle(
              fontSize: 12, color: Colors.orange.shade900, fontWeight: FontWeight.w600),
        ),
      ),
      for (final e in liste.take(20))
        ListTile(
          dense: true,
          leading: Icon(Icons.hourglass_bottom_rounded, color: Colors.orange.shade700),
          title: Text('${e.code.isEmpty ? '' : '${e.code} · '}${e.nom}',
              overflow: TextOverflow.ellipsis),
          subtitle: Text('Stock : ${e.qte.toStringAsFixed(e.qte % 1 == 0 ? 0 : 1)}'),
          trailing: Text('${fmt(e.valeur)} $currency',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade900)),
        ),
      if (liste.length > 20)
        Padding(
          padding: const EdgeInsets.all(10),
          child: Text('… et ${liste.length - 20} autre(s)',
              style: TextStyle(fontSize: 12, color: (Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade600))),
        ),
    ]);
  }

  // ------------------------------------------------------------------
  // 📋 DÉTAILS TOUCHABLES : boutique, vendeur, encaissé, crédits
  // ------------------------------------------------------------------
  void _ouvrirEncaisse(BuildContext context, String Function(double) fmt, String currency) {
    final p = _periodeAffichee;
    if (p == null) return;
    DetailsRapport.ventes(
      context,
      titre: 'Encaissé',
      ventes: DetailsRapport.ventesPeriode(_ventesAffichees, p,
          garder: (m) => DetailsRapport.encaisseDe(m) > 0.005),
      fmt: fmt,
      currency: currency,
      noms: _nomsBoutiques,
      mode: 'encaisse',
    );
  }

  void _ouvrirCredits(BuildContext context, String Function(double) fmt, String currency) {
    final p = _periodeAffichee;
    if (p == null) return;
    DetailsRapport.ventes(
      context,
      titre: 'Qui doit encore',
      ventes: DetailsRapport.ventesPeriode(_ventesAffichees, p,
          garder: (m) => _n(m['resteAPayer']) > 0.005),
      fmt: fmt,
      currency: currency,
      noms: _nomsBoutiques,
      mode: 'credit',
    );
  }

  void _ouvrirBoutique(BuildContext context, String? id, String nom,
      String Function(double) fmt, String currency) {
    final p = _periodeAffichee;
    if (p == null) return;
    DetailsRapport.boutique(
      context,
      titre: nom,
      ventes: DetailsRapport.ventesPeriode(_ventesToutes, p,
          garder: id == null ? null : (m) => DetailsRapport.boutiqueDe(m['boutiqueId']) == id),
      depenses: DetailsRapport.depensesPeriode(_depensesToutes, p, boutique: id),
      fmt: fmt,
      currency: currency,
      noms: _nomsBoutiques,
    );
  }

  void _ouvrirVendeur(BuildContext context, String vendeur,
      String Function(double) fmt, String currency) {
    final p = _periodeAffichee;
    if (p == null) return;
    DetailsRapport.ventes(
      context,
      titre: vendeur,
      ventes: DetailsRapport.ventesPeriode(_ventesAffichees, p,
          garder: (m) => DetailsRapport.vendeurDe(m) == vendeur),
      fmt: fmt,
      currency: currency,
      noms: _nomsBoutiques,
    );
  }

  // ------------------------------------------------------------------
  // DÉTAILS (feuilles du bas)
  // ------------------------------------------------------------------
  static String _date(dynamic d) =>
      d is DateTime ? DateFormat('dd/MM/yyyy', 'fr_FR').format(d) : '';

  Widget _vide() => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text('Aucune donnée sur cette période', style: TextStyle(color: Colors.white70)),
        ),
      );

  void _detailVentes(BuildContext context, FinancialCalculationResult r,
      String Function(double) fmt, String currency) {
    DetailsBottomSheet.afficher(
      context: context,
      titre: 'Ventes de la période',
      enfants: r.detailsVentesList.isEmpty
          ? [_vide()]
          : r.detailsVentesList
              .map((item) => ListTile(
                    dense: true,
                    leading: const Icon(Icons.shopping_bag, color: Colors.tealAccent),
                    title: Text('${item['nom']} (x${item['qte']})',
                        style: const TextStyle(color: Colors.white)),
                    subtitle: Text(_date(item['date']), style: TextStyle(color: Colors.grey.shade400)),
                    trailing: Text('${fmt(item['total'] as double)} $currency',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ))
              .toList(),
    );
  }

  void _detailCout(BuildContext context, FinancialCalculationResult r,
      String Function(double) fmt, String currency) {
    DetailsBottomSheet.afficher(
      context: context,
      titre: 'Coût des marchandises vendues',
      enfants: r.detailsCoutAchatList.isEmpty
          ? [_vide()]
          : r.detailsCoutAchatList
              .map((item) => ListTile(
                    dense: true,
                    leading: const Icon(Icons.inventory_2_outlined, color: Colors.orangeAccent),
                    title: Text('${item['nom']} (x${item['qte']})',
                        style: const TextStyle(color: Colors.white)),
                    subtitle: Text('Prix d\'achat unitaire : ${fmt(item['prixAchatUnit'] as double)} $currency',
                        style: TextStyle(color: Colors.grey.shade400)),
                    trailing: Text('− ${fmt(item['total'] as double)} $currency',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                  ))
              .toList(),
    );
  }

  void _detailMarge(BuildContext context, FinancialCalculationResult r,
      String Function(double) fmt, String currency) {
    DetailsBottomSheet.afficher(
      context: context,
      titre: 'Marge par article',
      enfants: r.detailsMargeList.isEmpty
          ? [_vide()]
          : r.detailsMargeList.map((item) {
              final double m = (item['marge'] as num).toDouble();
              return ListTile(
                dense: true,
                leading: Icon(Icons.show_chart, color: m >= 0 ? Colors.tealAccent : Colors.redAccent),
                title: Text('${item['nom']} (x${item['qte']})', style: const TextStyle(color: Colors.white)),
                subtitle: Text(
                  'Vente : ${fmt((item['totalVente'] as num).toDouble())} | Achat : ${fmt((item['totalAchat'] as num).toDouble())}',
                  style: TextStyle(color: Colors.grey.shade400),
                ),
                trailing: Text('${fmt(m)} $currency',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: m >= 0 ? Colors.tealAccent : Colors.redAccent)),
              );
            }).toList(),
    );
  }

  void _detailDepenses(BuildContext context, FinancialCalculationResult r,
      String Function(double) fmt, String currency) {
    final entrees = r.depensesParCategorie.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    DetailsBottomSheet.afficher(
      context: context,
      titre: 'Charges et dépenses par catégorie',
      enfants: entrees.isEmpty
          ? [_vide()]
          : entrees.map((e) {
              final part = r.totalDepenses > 0 ? e.value / r.totalDepenses * 100 : 0.0;
              return ListTile(
                dense: true,
                leading: const Icon(Icons.money_off, color: Colors.redAccent),
                title: Text(e.key, style: const TextStyle(color: Colors.white)),
                subtitle: Text('${part.toStringAsFixed(0)} % des charges',
                    style: TextStyle(color: Colors.grey.shade400)),
                trailing: Text('− ${fmt(e.value)} $currency',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
              );
            }).toList()
        ..addAll(_periodeAffichee == null
            ? const <Widget>[]
            : DetailsRapport.lignesDepenses(
                DetailsRapport.depensesPeriode(_depensesAffichees, _periodeAffichee!),
                fmt,
                currency)),
    );
  }

  void _detailSimple(BuildContext context, String titre, List<Map<String, dynamic>> items,
      String Function(double) fmt, String currency,
      {bool negatif = false, IconData icone = Icons.info_outline}) {
    DetailsBottomSheet.afficher(
      context: context,
      titre: titre,
      enfants: items.isEmpty
          ? [_vide()]
          : items
              .map((item) => ListTile(
                    dense: true,
                    leading: Icon(icone, color: negatif ? Colors.redAccent : Colors.tealAccent),
                    title: Text('${item['nom']}', style: const TextStyle(color: Colors.white)),
                    subtitle: Text(_date(item['date']), style: TextStyle(color: Colors.grey.shade400)),
                    trailing: Text(
                      '${negatif ? '− ' : ''}${fmt((item['total'] as num).toDouble())} $currency',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: negatif ? Colors.redAccent : Colors.tealAccent),
                    ),
                  ))
              .toList(),
    );
  }
}
