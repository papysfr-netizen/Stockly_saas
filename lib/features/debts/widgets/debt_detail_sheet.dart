// 🌙 mode sombre automatique
// lib/features/debts/widgets/debt_detail_sheet.dart
//
// 📋 Fiche de détail d'une dette / créance :
//  - client, téléphone, facture, date, vendeur
//  - articles achetés (lus dans la vente liée)
//  - montants, échéance, dernier paiement, motif
//  - boutons : Encaisser / Payer, Relancer, Appeler, Facture PDF

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:stockly_saas/core/models/dette.dart';
import 'package:stockly_saas/core/providers/settings_provider.dart' show settingsProvider;
import 'package:stockly_saas/core/services/facture_pdf_service.dart';
import 'package:stockly_saas/core/utils/currency_extension.dart';
import 'package:stockly_saas/l10n/app_localizations.dart';

/// Motif lisible : la note automatique « Créance issue de la vente #… » est ignorée.
String motifDette(Dette d) {
  final n = d.note.trim();
  if (n.startsWith('Créance issue de la vente')) return '';
  return n;
}

/// Identifiant complet de la vente liée ('' si la dette a été ajoutée à la main).
String venteLiee(Dette d) {
  if (d.venteId.isNotEmpty) return d.venteId;
  // Anciennes créances : le numéro de facture contenait l'identifiant complet
  return d.numeroFacture.length > 8 ? d.numeroFacture : '';
}

class DetteDetailSheet extends ConsumerStatefulWidget {
  final String entrepriseId;
  final Dette dette;
  final String Function(double) format;
  final VoidCallback onEncaisser;
  final VoidCallback onRelancer;

  const DetteDetailSheet({
    super.key,
    required this.entrepriseId,
    required this.dette,
    required this.format,
    required this.onEncaisser,
    required this.onRelancer,
  });

  /// Ouvre la fiche en bas de l'écran
  static Future<void> ouvrir(
    BuildContext context, {
    required String entrepriseId,
    required Dette dette,
    required String Function(double) format,
    required VoidCallback onEncaisser,
    required VoidCallback onRelancer,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1C1F26)
          : Colors.white, // 🌙
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DetteDetailSheet(
        entrepriseId: entrepriseId,
        dette: dette,
        format: format,
        onEncaisser: onEncaisser,
        onRelancer: onRelancer,
      ),
    );
  }

  @override
  ConsumerState<DetteDetailSheet> createState() => _DetteDetailSheetState();
}

class _DetteDetailSheetState extends ConsumerState<DetteDetailSheet> {
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

  late final Future<Map<String, dynamic>?> _vente = _chargerVente();

  Dette get _d => widget.dette;

  static double _num(dynamic v) => v is num ? v.toDouble() : 0.0;

  String get _numeroCourt => _d.numeroFacture.length > 8
      ? _d.numeroFacture.substring(0, 8).toUpperCase()
      : _d.numeroFacture;

  /// Lit la vente liée (articles, vendeur…). null = pas de vente (dette manuelle).
  Future<Map<String, dynamic>?> _chargerVente() async {
    final id = venteLiee(_d);
    if (id.isEmpty || _d.type != TypeDette.client) return null;
    final doc = await FirebaseFirestore.instance
        .collection('entreprises')
        .doc(widget.entrepriseId)
        .collection('ventes')
        .doc(id)
        .get();
    return doc.exists ? doc.data() : null;
  }

  Future<void> _appeler() async {
    final tel = _d.telephone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (tel.isEmpty) return;
    await launchUrl(Uri(scheme: 'tel', path: tel));
  }

  Future<void> _facturePdf(Map<String, dynamic> vente) async {
    final t = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final boutique = ref.read(settingsProvider);
    String formatPrix(double v) => ref.formatPrice(v);
    try {
      final brut = vente['articles'];
      final lignes = (brut is List ? brut : const [])
          .whereType<Map>()
          .map((a) => LigneDocument(
                nom: (a['nom'] ?? '').toString(),
                quantite: _num(a['quantite']).toInt(),
                prixUnitaire: _num(a['prixUnitaire']),
              ))
          .toList();
      final date = vente['date'];
      final octets = await FacturePdfService.construire(
        type: TypeDocument.facture,
        numero: _numeroCourt,
        date: date is Timestamp ? date.toDate() : _d.dateCreation,
        boutique: boutique,
        nomClient: _d.nomTiers,
        telephoneClient: _d.telephone,
        lignes: lignes,
        formatPrix: formatPrix,
        montantPaye: _d.acomptePaye,
        resteAPayer: _d.montantReste,
        vendeur: (vente['vendeurNom'] ?? '').toString(),
        livreur: (vente['livreParNom'] ?? '').toString(),
      );
      await FacturePdfService.partager(octets, 'Facture_$_numeroCourt.pdf');
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(t.histInvoiceError('$e')), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final d = _d;
    final estClient = d.type == TypeDette.client;
    final motif = motifDette(d);
    final jour = DateFormat('dd/MM/yyyy');
    final initiale = d.nomTiers.trim().isEmpty ? '?' : d.nomTiers.trim()[0].toUpperCase();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (ctx, scroll) => FutureBuilder<Map<String, dynamic>?>(
        future: _vente,
        builder: (ctx, snap) {
          final vente = snap.data;
          return ListView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ---- Client
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: _bleuNuit.withValues(alpha: 0.08),
                    child: Text(initiale,
                        style: TextStyle(color: _encre, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d.nomTiers,
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold, color: _encre)),
                        if (d.telephone.isNotEmpty)
                          Text(d.telephone, style: TextStyle(color: (Theme.of(context).brightness == Brightness.dark ? Colors.grey[400]! : Colors.grey[700]!))),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  if (_numeroCourt.isNotEmpty)
                    _info(Icons.receipt_long_rounded, t.invoiceShort(_numeroCourt)),
                  _info(Icons.calendar_today_rounded,
                      t.ddDate(DateFormat('dd/MM/yyyy HH:mm').format(d.dateCreation))),
                  if (vente != null && (vente['vendeurNom'] ?? '').toString().trim().isNotEmpty)
                    _info(Icons.person_outline,
                        '${t.histSoldBy} : ${(vente['vendeurNom'] ?? '').toString().trim()}'),
                ],
              ),
              const SizedBox(height: 14),

              // ---- Montants
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1C1F26) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    _ligne(t.histTotal, widget.format(d.montantInitial)),
                    _ligne(t.histPaid, widget.format(d.acomptePaye), couleur: _vert),
                    _ligne(t.histToPay, widget.format(d.montantReste),
                        couleur: d.estSolde ? _vert : _rouge, gras: true),
                    if (d.dateEcheance != null || d.dernierPaiement != null) ...[
                      const Divider(height: 16),
                      if (d.dateEcheance != null)
                        _info(Icons.event_rounded, t.debtDueDate(jour.format(d.dateEcheance!)),
                            couleur: d.estEnRetard ? _rouge : null),
                      if (d.dernierPaiement != null)
                        _info(Icons.history_rounded, t.lastPayment(jour.format(d.dernierPaiement!))),
                    ],
                  ],
                ),
              ),

              // ---- Historique des paiements
              const SizedBox(height: 16),
              Text(t.ddPayments, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              ..._historique(t),

              // ---- Motif
              if (motif.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(t.ddMotif, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(motif),
              ],

              // ---- Articles
              if (estClient) ...[
                const SizedBox(height: 16),
                Text(t.histItems, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                if (snap.connectionState == ConnectionState.waiting)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: LinearProgressIndicator(),
                  )
                else if (snap.hasError)
                  Text(t.ddItemsError, style: TextStyle(color: Colors.red.shade700))
                else if (vente == null)
                  Text(t.ddNoItems, style: TextStyle(color: (Theme.of(context).brightness == Brightness.dark ? Colors.grey[400]! : Colors.grey[600]!)))
                else
                  ..._articles(t, vente),
              ],

              // ---- Boutons
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (!d.estSolde)
                    FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: _bleuNuit),
                      icon: const Icon(Icons.payments_rounded, size: 18),
                      label: Text(estClient ? t.collect : t.pay),
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onEncaisser();
                      },
                    ),
                  if (!d.estSolde)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.chat_rounded, size: 18, color: Color(0xFF25D366)),
                      label: Text(estClient ? t.remind : t.message),
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onRelancer();
                      },
                    ),
                  if (d.telephone.trim().isNotEmpty)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.call_rounded, size: 18),
                      label: Text(t.ddCall),
                      onPressed: _appeler,
                    ),
                  if (vente != null)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                      label: Text(t.ddPdf),
                      onPressed: () => _facturePdf(vente),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  String _methode(AppLocalizations t, String m) {
    switch (m) {
      case 'cash':
        return t.debtCashDesk;
      case 'bankTransfer':
        return t.payTransfer;
      case 'check':
        return t.debtCheck;
      case 'mobileMoney':
        return 'Mobile Money';
      default:
        return m;
    }
  }

  /// Historique des paiements (+ « payé avant » pour ce qui date d'avant l'historique)
  List<Widget> _historique(AppLocalizations t) {
    int quand(Map<String, dynamic> p) {
      final v = p['date'];
      return v is Timestamp ? v.millisecondsSinceEpoch : 0;
    }

    final liste = [..._d.paiements]..sort((a, b) => quand(a).compareTo(quand(b)));
    final dansHistorique = liste.fold<double>(0, (s, p) => s + _num(p['montant']));
    final avant = _d.acomptePaye - dansHistorique;
    final format = DateFormat('dd/MM/yyyy HH:mm');

    if (liste.isEmpty && avant <= 0.005) {
      return [Text(t.ddNoPayments, style: TextStyle(color: (Theme.of(context).brightness == Brightness.dark ? Colors.grey[400]! : Colors.grey[600]!)))];
    }
    return [
      if (avant > 0.005) _paiementLigne(t.ddPaidBefore, '', avant),
      for (final p in liste)
        _paiementLigne(
          p['date'] is Timestamp ? format.format((p['date'] as Timestamp).toDate()) : '—',
          [
            _methode(t, (p['methode'] ?? '').toString()),
            (p['parNom'] ?? '').toString().trim(),
          ].where((s) => s.isNotEmpty).join(' • '),
          _num(p['montant']),
        ),
    ];
  }

  Widget _paiementLigne(String titre, String detail, double montant) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, size: 16, color: _vert),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titre, style: const TextStyle(fontWeight: FontWeight.w600)),
                if (detail.isNotEmpty)
                  Text(detail, style: TextStyle(fontSize: 12, color: (Theme.of(context).brightness == Brightness.dark ? Colors.grey[400]! : Colors.grey[600]!))),
              ],
            ),
          ),
          Text('+ ${widget.format(montant)}',
              style: const TextStyle(color: _vert, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  List<Widget> _articles(AppLocalizations t, Map<String, dynamic> vente) {
    final brut = vente['articles'];
    final articles = (brut is List ? brut : const []).whereType<Map>().toList();
    if (articles.isEmpty) {
      return [Text(t.ddNoItems, style: TextStyle(color: (Theme.of(context).brightness == Brightness.dark ? Colors.grey[400]! : Colors.grey[600]!)))];
    }
    final remise = _num(vente['remiseTotale']);
    return [
      for (final a in articles)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              Expanded(
                child: Text('${_num(a['quantite']).toInt()} × ${(a['nom'] ?? '').toString()}'),
              ),
              Text(widget.format(_num(a['totalItem']))),
            ],
          ),
        ),
      if (remise > 0.005)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(t.ddDiscount(widget.format(remise)),
              style: TextStyle(fontSize: 12, color: Colors.orange.shade800)),
        ),
    ];
  }

  Widget _ligne(String titre, String valeur, {Color? couleur, bool gras = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(titre)),
          Text(
            valeur,
            style: TextStyle(
              color: couleur ?? _encre,
              fontWeight: gras ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _info(IconData icone, String texte, {Color? couleur}) {
    final c = couleur ?? (Theme.of(context).brightness == Brightness.dark ? Colors.grey[400]! : Colors.grey[700]!);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 14, color: c),
          const SizedBox(width: 4),
          Flexible(child: Text(texte, style: TextStyle(fontSize: 12.5, color: c))),
        ],
      ),
    );
  }
}
