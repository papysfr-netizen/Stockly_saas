// lib/views/financial_analysis/widgets/recherche_client_sheet.dart
//
// 🔎 RECHERCHE D'UN CLIENT (onglet Rapport)
// Achats sur la période, ce qu'il doit, ses dettes et ses paiements.
// Lecture seulement.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RechercheClientSheet extends StatefulWidget {
  final String entrepriseId;
  final List<QueryDocumentSnapshot> ventes;
  final DateTimeRange periode;
  final String libellePeriode;
  final String Function(double) fmt;
  final String currency;

  const RechercheClientSheet({
    super.key,
    required this.entrepriseId,
    required this.ventes,
    required this.periode,
    required this.libellePeriode,
    required this.fmt,
    required this.currency,
  });

  static Future<void> ouvrir(
    BuildContext context, {
    required String entrepriseId,
    required List<QueryDocumentSnapshot> ventes,
    required DateTimeRange periode,
    required String libellePeriode,
    required String Function(double) fmt,
    required String currency,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RechercheClientSheet(
        entrepriseId: entrepriseId,
        ventes: ventes,
        periode: periode,
        libellePeriode: libellePeriode,
        fmt: fmt,
        currency: currency,
      ),
    );
  }

  @override
  State<RechercheClientSheet> createState() => _RechercheClientSheetState();
}

class _RechercheClientSheetState extends State<RechercheClientSheet> {
  static const Color _bleuNuit = Color(0xFF1E293B);
  // 🌙 Mode sombre
  bool get _sombre => Theme.of(context).brightness == Brightness.dark;
  Color get _fondPage => _sombre ? const Color(0xFF121418) : const Color(0xFFF3F4F6);
  Color get _fondCarte => _sombre ? const Color(0xFF1C1F26) : Colors.white;
  Color get _fondChamp => _sombre ? const Color(0xFF22262E) : Colors.white;
  Color _pastel(Color clair, Color base) => _sombre ? base.withValues(alpha: 0.22) : clair;
  Color get _encre => _sombre ? Colors.white : _bleuNuit;
  static const Color _vert = Color(0xFF0F9D58);
  static const Color _rouge = Color(0xFFD93025);

  final _ctrl = TextEditingController();
  String _q = '';
  String? _client;
  List<Map<String, dynamic>> _creances = const [];
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _chargerCreances();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _chargerCreances() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('entreprises')
          .doc(widget.entrepriseId)
          .collection('creances')
          .get()
          .timeout(const Duration(seconds: 15));
      _creances = [
        for (final d in snap.docs) {'_id': d.id, ...d.data()},
      ];
    } catch (e) {
      debugPrint('Recherche client : créances non lues : $e');
    }
    if (mounted) setState(() => _chargement = false);
  }

  // ---------- Petits outils ----------
  static String _cle(Object? s) => (s ?? '').toString().trim().toLowerCase();

  static double _n(Object? v) {
    if (v is num) return v.toDouble();
    return double.tryParse((v ?? '').toString().replaceAll(',', '.')) ?? 0;
  }

  static DateTime? _d(Object? v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    return null;
  }

  static String _nomVente(Map m) => (m['nomClient'] ?? m['clientNom'] ?? '').toString().trim();
  static String _nomCreance(Map m) => (m['nomTiers'] ?? m['nomClient'] ?? '').toString().trim();
  static bool _divers(String n) => n.isEmpty || n.toLowerCase() == 'client divers';

  List<Map<String, dynamic>> get _ventesMaps => [
        for (final v in widget.ventes) (v.data() as Map<String, dynamic>?) ?? <String, dynamic>{},
      ];

  /// Tous les clients connus (ventes + dettes), sans doublon
  List<String> _tousLesClients() {
    final noms = <String, String>{};
    for (final m in _ventesMaps) {
      final n = _nomVente(m);
      if (!_divers(n)) noms.putIfAbsent(_cle(n), () => n);
    }
    for (final c in _creances) {
      if ((c['type'] ?? 'client').toString() != 'client') continue;
      final n = _nomCreance(c);
      if (!_divers(n)) noms.putIfAbsent(_cle(n), () => n);
    }
    return noms.values.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  // ---------- Interface ----------
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(
        color: _fondPage,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
            child: Row(
              children: [
                if (_client != null)
                  IconButton(
                    tooltip: 'Autres clients',
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => setState(() => _client = null),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_client ?? '🔎 Rechercher un client',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold, color: _encre)),
                      Text(widget.libellePeriode,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          if (_client == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                controller: _ctrl,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'Nom du client…',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: _fondChamp,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
                onChanged: (v) => setState(() => _q = v),
              ),
            ),
          Expanded(child: _client == null ? _liste() : _fiche(_client!)),
        ],
      ),
    );
  }

  Widget _liste() {
    final q = _cle(_q);
    final tous = _tousLesClients();
    final trouves = q.isEmpty ? tous : tous.where((n) => n.toLowerCase().contains(q)).toList();
    if (trouves.isEmpty) {
      return Center(
        child: Text(_chargement ? 'Chargement…' : 'Aucun client trouvé',
            style: TextStyle(color: Colors.grey.shade600)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: trouves.length > 100 ? 100 : trouves.length,
      itemBuilder: (context, i) {
        final n = trouves[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 6),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.indigo.withValues(alpha: 0.12),
              child: Text(n.characters.first.toUpperCase(),
                  style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
            ),
            title: Text(n),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => setState(() => _client = n),
          ),
        );
      },
    );
  }

  Widget _stat(String titre, String valeur, Color couleur) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: _fondCarte, borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titre, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(valeur,
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800, color: couleur)),
              ),
            ],
          ),
        ),
      );

  Widget _titre(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
        child: Text(t,
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold, color: _encre)),
      );

  Widget _fiche(String nom) {
    final fmt = widget.fmt;
    final cur = widget.currency;
    final k = _cle(nom);
    final df = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');
    final dfJour = DateFormat('dd/MM/yyyy', 'fr_FR');

    final p = widget.periode;
    final debut = DateTime(p.start.year, p.start.month, p.start.day);
    final finExcl = DateTime(p.end.year, p.end.month, p.end.day + 1);

    final toutes = _ventesMaps.where((m) => _cle(_nomVente(m)) == k).toList();
    final achats = toutes.where((m) {
      final d = _d(m['date'] ?? m['createdAt']);
      return d != null && !d.isBefore(debut) && d.isBefore(finExcl);
    }).toList()
      ..sort((a, b) => (_d(b['date'] ?? b['createdAt']) ?? debut)
          .compareTo(_d(a['date'] ?? a['createdAt']) ?? debut));

    double total = 0, paye = 0, reste = 0;
    for (final m in achats) {
      total += _n(m['montantTotal'] ?? m['total']) -
          _n(m['montantRetourne']) -
          _n(m['montantAnnule']);
      paye += _n(m['montantPaye']);
      reste += _n(m['resteAPayer']);
    }
    final tel = toutes
        .map((m) => (m['telephoneClient'] ?? '').toString().trim())
        .firstWhere((t) => t.isNotEmpty, orElse: () => '');

    final dettes = _creances.where((c) => _cle(_nomCreance(c)) == k).toList()
      ..sort((a, b) => _n(b['montantReste']).compareTo(_n(a['montantReste'])));
    final doitEnTout = dettes.fold<double>(
        0, (s, c) => s + (_n(c['montantReste']) > 0.005 ? _n(c['montantReste']) : 0));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        if (tel.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              const Icon(Icons.phone_rounded, size: 16, color: Colors.teal),
              const SizedBox(width: 6),
              Text(tel, style: const TextStyle(fontWeight: FontWeight.w600)),
            ]),
          ),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: doitEnTout > 0.005 ? _rouge.withValues(alpha: 0.08) : _vert.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(children: [
            Icon(doitEnTout > 0.005 ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
                color: doitEnTout > 0.005 ? _rouge : _vert),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _chargement
                    ? 'Chargement des dettes…'
                    : doitEnTout > 0.005
                        ? 'Doit en tout : ${fmt(doitEnTout)} $cur'
                        : 'Ne doit rien',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: doitEnTout > 0.005 ? _rouge : _vert),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 10),
        Row(children: [
          _stat('Achats (période)', '${achats.length} • ${fmt(total)}', _encre),
          const SizedBox(width: 8),
          _stat('Payé', fmt(paye), _vert),
          const SizedBox(width: 8),
          _stat('Reste', fmt(reste), reste > 0.005 ? _rouge : _encre),
        ]),

        // ----- Achats -----
        _titre('Achats sur la période'),
        if (achats.isEmpty)
          Text('Aucun achat sur cette période.', style: TextStyle(color: Colors.grey.shade600)),
        for (final m in achats)
          Card(
            margin: const EdgeInsets.only(bottom: 6),
            child: ListTile(
              dense: true,
              leading: const Icon(Icons.shopping_bag_outlined, color: Colors.teal),
              title: Text(
                ((m['articles'] ?? m['produits'] ?? m['items']) is List
                        ? ((m['articles'] ?? m['produits'] ?? m['items']) as List)
                            .whereType<Map>()
                            .map((a) => '${_n(a['quantite'] ?? a['qte'] ?? 1).toStringAsFixed(0)} × ${a['nom'] ?? a['name'] ?? ''}')
                            .join(', ')
                        : 'Vente')
                    .toString(),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(_d(m['date'] ?? m['createdAt']) == null
                  ? ''
                  : df.format(_d(m['date'] ?? m['createdAt'])!)),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(fmt(_n(m['montantTotal'] ?? m['total'])),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (_n(m['resteAPayer']) > 0.005)
                    Text('reste ${fmt(_n(m['resteAPayer']))}',
                        style: const TextStyle(fontSize: 11, color: _rouge)),
                ],
              ),
            ),
          ),

        // ----- Dettes et paiements -----
        _titre('Dettes et paiements (toutes périodes)'),
        if (!_chargement && dettes.isEmpty)
          Text('Aucune dette enregistrée.', style: TextStyle(color: Colors.grey.shade600)),
        for (final c in dettes)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(
                        'Crédit de ${fmt(_n(c['montantInitial']))} $cur'
                        '${_d(c['dateCreation'] ?? c['createdAt']) == null ? '' : ' • ${dfJour.format(_d(c['dateCreation'] ?? c['createdAt'])!)}'}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      _n(c['montantReste']) > 0.005
                          ? 'reste ${fmt(_n(c['montantReste']))}'
                          : 'soldé ✔',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _n(c['montantReste']) > 0.005 ? _rouge : _vert),
                    ),
                  ]),
                  if ((c['note'] ?? '').toString().trim().isNotEmpty &&
                      !(c['note'] ?? '').toString().startsWith('Créance issue de la vente'))
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('« ${(c['note']).toString().trim()} »',
                          style: TextStyle(
                              fontStyle: FontStyle.italic, color: Colors.grey.shade700)),
                    ),
                  if (c['paiements'] is List)
                    for (final pm in (c['paiements'] as List).whereType<Map>())
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(children: [
                          const Icon(Icons.check_circle_rounded, size: 14, color: _vert),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${_d(pm['date']) == null ? '' : df.format(_d(pm['date'])!)}'
                              '${(pm['parNom'] ?? '').toString().trim().isEmpty ? '' : ' • ${pm['parNom']}'}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                            ),
                          ),
                          Text('+ ${fmt(_n(pm['montant']))}',
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold, color: _vert)),
                        ]),
                      ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
