// lib/features/debts/widgets/debt_list_view.dart
//
// Liste professionnelle des créances clients / dettes fournisseurs :
//  - carte de synthèse (total, nombre de dossiers, montant en retard)
//  - recherche (nom, facture, téléphone) + filtres
//  - cartes avec barre de progression, âge de la dette,
//    boutons « Encaisser / Payer » et « Relancer » (WhatsApp)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stockly_saas/core/providers/user_role_provider.dart';
import 'package:stockly_saas/features/boutiques/boutique_provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:stockly_saas/core/models/dette.dart';
import 'debt_dialogs.dart';
import 'debt_detail_sheet.dart';
import 'package:stockly_saas/core/services/messages_clients.dart';
import 'package:stockly_saas/l10n/app_localizations.dart';

enum _Filtre { enCours, recentes, enRetard, partielles, soldees }

class DebtListView extends ConsumerStatefulWidget {
  final String entrepriseId;
  final List<Dette> liste;
  final TypeDette type;
  final String currency;

  const DebtListView({
    super.key,
    required this.entrepriseId,
    required this.liste,
    required this.type,
    required this.currency,
  });

  @override
  ConsumerState<DebtListView> createState() => _DebtListViewState();
}

class _DebtListViewState extends ConsumerState<DebtListView> {
  static const Color _bleuNuit = Color(0xFF1E293B);
  static const Color _vert = Color(0xFF0F9D58);
  static const Color _rouge = Color(0xFFD93025);
  static const int _joursRetard = 30;

  final TextEditingController _recherche = TextEditingController();
  String _texte = '';
  _Filtre _filtre = _Filtre.enCours;

  final NumberFormat _nf = NumberFormat('#,##0.00', 'fr_FR');

  bool get _isClient => widget.type == TypeDette.client;

  /// 🏬 Anciennes dettes sans boutique : déjà rattrapées pour ce type pendant cette session ?
  static final Set<TypeDette> _rattrapes = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _rattraperBoutiques());
  }

  /// 🏬 Le PATRON ouvre l'écran : chaque ancienne dette sans boutique reçoit
  /// la boutique de sa vente (sinon « principale »). Une fois par session.
  Future<void> _rattraperBoutiques() async {
    if (!mounted || _rattrapes.contains(widget.type)) return;
    final profil = ref.read(userProfileProvider).value;
    if (profil == null || !profil.role.isOwner) return;
    _rattrapes.add(widget.type);
    final ent = FirebaseFirestore.instance.collection('entreprises').doc(widget.entrepriseId);
    final collection = widget.type == TypeDette.client ? 'creances' : 'dettes';
    for (final d in widget.liste) {
      if (d.boutiqueId.isNotEmpty || d.id.isEmpty) continue;
      var b = 'principale';
      try {
        final vid = venteLiee(d);
        if (vid.isNotEmpty) {
          final v = await ent.collection('ventes').doc(vid).get().timeout(const Duration(seconds: 6));
          final bv = (v.data()?['boutiqueId'] ?? '').toString();
          if (bv.isNotEmpty) b = bv;
        }
        await ent.collection(collection).doc(d.id).update({'boutiqueId': b});
      } catch (_) {
        // Pas de réseau : on réessaiera à la prochaine ouverture de l'application
        _rattrapes.remove(widget.type);
        return;
      }
    }
  }

  @override
  void dispose() {
    _recherche.dispose();
    super.dispose();
  }

  String _m(double v) => '${_nf.format(v)} ${widget.currency}';

  AppLocalizations get _t => AppLocalizations.of(context);

  int _age(Dette d) => DateTime.now().difference(d.dateCreation).inDays;

  /// En retard : échéance dépassée, ou plus de 30 jours sans être soldée.
  bool _enRetard(Dette d) => !d.estSolde && (d.estEnRetard || _age(d) > _joursRetard);

  String _ageTexte(Dette d) {
    final j = _age(d);
    if (j <= 0) return _t.ageToday;
    if (j == 1) return _t.ageYesterday;
    if (j < 30) return _t.ageDays(j);
    final mois = j ~/ 30;
    return _t.ageMonths(mois);
  }

  bool _correspond(Dette d) {
    switch (_filtre) {
      case _Filtre.enCours:
        if (d.estSolde) return false;
        break;
      case _Filtre.recentes:
        if (d.estSolde || _age(d) > _joursRetard) return false;
        break;
      case _Filtre.enRetard:
        if (!_enRetard(d)) return false;
        break;
      case _Filtre.partielles:
        if (d.estSolde || d.acomptePaye <= 0.005) return false;
        break;
      case _Filtre.soldees:
        if (!d.estSolde) return false;
        break;
    }
    if (_texte.isEmpty) return true;
    final t = _texte.toLowerCase();
    return d.nomTiers.toLowerCase().contains(t) ||
        d.numeroFacture.toLowerCase().contains(t) ||
        d.telephone.contains(t);
  }

  // ------------------------------------------------------------------
  // 📋 FICHE DE DÉTAIL
  // ------------------------------------------------------------------
  void _ouvrirDetail(Dette d) {
    DetteDetailSheet.ouvrir(
      context,
      entrepriseId: widget.entrepriseId,
      dette: d,
      format: _m,
      onEncaisser: () => DebtDialogs.afficherPaiement(
          context, ref, widget.entrepriseId, d, widget.currency),
      onRelancer: () => _relancer(d),
    );
  }

  // ------------------------------------------------------------------
  // RELANCE WHATSAPP
  // ------------------------------------------------------------------
  Future<void> _relancer(Dette d) async {
    // 💬 Langue DU CLIENT (par défaut : langue de l'application)
    final langue = await MessagesClients.choisirLangue(
      context,
      defaut: Localizations.localeOf(context).languageCode,
    );
    if (langue == null || !mounted) return;
    final date = DateFormat('dd/MM/yyyy', 'fr_FR').format(d.dateCreation);
    final message = _isClient
        ? MessagesClients.relanceClient(
            langue: langue,
            nom: d.nomTiers,
            reste: _m(d.montantReste),
            date: date,
            numero: d.numeroFacture,
            total: _m(d.montantInitial),
            paye: _m(d.acomptePaye),
          )
        : MessagesClients.relanceFournisseur(
            langue: langue,
            nom: d.nomTiers,
            reste: _m(d.montantReste),
            date: date,
            numero: d.numeroFacture,
          );

    // Numéro : chiffres seulement, 0 au début -> 243 (RDC)
    var tel = d.telephone.replaceAll(RegExp(r'[^0-9]'), '');
    if (tel.startsWith('0')) tel = '243${tel.substring(1)}';

    final uri = Uri.parse(
        'https://wa.me/${tel.length >= 9 ? tel : ''}?text=${Uri.encodeComponent(message)}');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t.whatsAppError)),
      );
    }
  }

  // ------------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    // 🏬 Seulement les dettes de la boutique affichée (sans boutique = principale)
    final boutique = ref.watch(boutiqueActiveProvider);
    final liste = boutique == null
        ? widget.liste
        : widget.liste
            .where((d) => (d.boutiqueId.isEmpty ? 'principale' : d.boutiqueId) == boutique)
            .toList();
    final ouvertes = liste.where((d) => !d.estSolde).toList();
    final total = ouvertes.fold<double>(0, (s, d) => s + d.montantReste);
    final enRetard = ouvertes.where(_enRetard).toList();
    final totalRetard = enRetard.fold<double>(0, (s, d) => s + d.montantReste);
    final nbTiers = ouvertes.map((d) => d.nomTiers.trim().toLowerCase()).toSet().length;

    final visibles = liste.where(_correspond).toList()
      ..sort((a, b) {
        // Les plus anciennes (et non soldées) d'abord
        if (a.estSolde != b.estSolde) return a.estSolde ? 1 : -1;
        return a.dateCreation.compareTo(b.dateCreation);
      });

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        _synthese(total, ouvertes.length, nbTiers, totalRetard, enRetard.length),
        const SizedBox(height: 14),
        _barreRecherche(),
        const SizedBox(height: 10),
        _filtres(),
        const SizedBox(height: 12),
        if (liste.isEmpty)
          _etatVide(
            _isClient ? Icons.handshake_outlined : Icons.local_shipping_outlined,
            _isClient ? _t.debtEmptyClients : _t.debtEmptySuppliers,
            _isClient
                ? _t.debtEmptyClientsHint
                : _t.debtEmptySuppliersHint,
          )
        else if (visibles.isEmpty)
          _etatVide(Icons.search_off_rounded, _t.noResults,
              _t.noResultsHint)
        else
          ...visibles.map(_carte),
      ],
    );
  }

  // ------------------------------------------------------------------
  // WIDGETS
  // ------------------------------------------------------------------
  Widget _synthese(double total, int nbDossiers, int nbTiers, double totalRetard, int nbRetard) {
    final couleur = _isClient ? const Color(0xFF1565C0) : const Color(0xFFB71C1C);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [couleur, Color.lerp(couleur, Colors.black, 0.3)!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: couleur.withValues(alpha: 0.28), blurRadius: 14, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_isClient ? Icons.call_received_rounded : Icons.call_made_rounded,
                  color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Text(
                _isClient ? _t.debtToCollect : _t.debtToPay,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(_m(total),
                style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: Colors.white24),
          const SizedBox(height: 12),
          Row(
            children: [
              _infoSynthese('$nbDossiers', _t.debtOpenFiles(nbDossiers)),
              _infoSynthese('$nbTiers', _isClient ? _t.debtClientsCount(nbTiers) : _t.debtSuppliersCount(nbTiers)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _nf.format(totalRetard),
                        style: TextStyle(
                          color: totalRetard > 0.005 ? const Color(0xFFFFD54F) : Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(_t.debtLateCount(nbRetard),
                        style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoSynthese(String valeur, String libelle) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(valeur,
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          Text(libelle, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _barreRecherche() {
    return TextField(
      controller: _recherche,
      onChanged: (v) => setState(() => _texte = v.trim()),
      decoration: InputDecoration(
        hintText: _isClient
            ? _t.debtSearchClients
            : _t.debtSearchSuppliers,
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _texte.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  _recherche.clear();
                  setState(() => _texte = '');
                },
              ),
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  Widget _filtres() {
    final libelles = {
      _Filtre.enCours: _t.filterOngoing,
      _Filtre.recentes: _t.filterRecent,
      _Filtre.enRetard: _t.filterLate,
      _Filtre.partielles: _t.filterPartial,
      _Filtre.soldees: _t.filterSettled,
    };
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final f in _Filtre.values) ...[
            ChoiceChip(
              label: Text(libelles[f]!),
              selected: _filtre == f,
              onSelected: (_) => setState(() => _filtre = f),
              selectedColor: _bleuNuit,
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _filtre == f ? Colors.white : _bleuNuit,
              ),
              showCheckmark: false,
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _etatVide(IconData icone, String titre, String texte) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: Colors.grey.shade200,
            child: Icon(icone, size: 34, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 14),
          Text(titre,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _bleuNuit)),
          const SizedBox(height: 6),
          Text(texte,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _carte(Dette d) {
    final retard = _enRetard(d);
    final pct = d.pourcentagePaye;

    final Color couleurStatut;
    final String libelleStatut;
    if (d.estSolde) {
      couleurStatut = _vert;
      libelleStatut = _t.statusSettled;
    } else if (retard) {
      couleurStatut = _rouge;
      libelleStatut = _t.filterLate;
    } else if (d.acomptePaye > 0.005) {
      couleurStatut = Colors.orange.shade800;
      libelleStatut = _t.statusPartial;
    } else {
      couleurStatut = Colors.blueGrey.shade600;
      libelleStatut = _t.statusUnpaid;
    }

    final initiale = d.nomTiers.trim().isEmpty ? '?' : d.nomTiers.trim()[0].toUpperCase();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _ouvrirDetail(d),
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: couleurStatut, width: 4)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ligne 1 : avatar, nom, reste
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: couleurStatut.withValues(alpha: 0.12),
                  child: Text(initiale,
                      style: TextStyle(color: couleurStatut, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d.nomTiers,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold, color: _bleuNuit)),
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (d.numeroFacture.isNotEmpty) _t.invoiceShort(d.numeroFacture),
                          _ageTexte(d),
                        ].join(' • '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      d.estSolde ? _nf.format(d.montantInitial) : _nf.format(d.montantReste),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: d.estSolde ? _vert : _rouge,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: couleurStatut.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(libelleStatut,
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.bold, color: couleurStatut)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Ligne 2 : progression du paiement
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 7,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(d.estSolde ? _vert : Colors.teal),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _t.paidOf(_nf.format(d.acomptePaye), _m(d.montantInitial)),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text('${(pct * 100).toStringAsFixed(0)} %',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _bleuNuit)),
              ],
            ),

            // Ligne 3 : échéance / dernier paiement / note
            if (d.dateEcheance != null || d.dernierPaiement != null || motifDette(d).isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  if (d.dateEcheance != null)
                    _petiteInfo(
                      Icons.event_rounded,
                      _t.debtDueDate(DateFormat('dd/MM/yyyy').format(d.dateEcheance!)),
                      couleur: d.estEnRetard ? _rouge : null,
                    ),
                  if (d.dernierPaiement != null)
                    _petiteInfo(Icons.history_rounded,
                        _t.lastPayment(DateFormat('dd/MM/yyyy').format(d.dernierPaiement!))),
                  if (motifDette(d).isNotEmpty) _petiteInfo(Icons.notes_rounded, motifDette(d)),
                ],
              ),
            ],

            // Ligne 4 : actions
            if (!d.estSolde) ...[
              const SizedBox(height: 4),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    tooltip: _t.ddDetails,
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _ouvrirDetail(d),
                    icon: const Icon(Icons.receipt_long_rounded, color: _bleuNuit),
                  ),
                  TextButton.icon(
                    onPressed: () => _relancer(d),
                    icon: const Icon(Icons.chat_rounded, size: 18, color: Color(0xFF25D366)),
                    label: Text(_isClient ? _t.remind : _t.message,
                        style: const TextStyle(color: Color(0xFF128C7E), fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 4),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: _bleuNuit,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => DebtDialogs.afficherPaiement(
                        context, ref, widget.entrepriseId, d, widget.currency),
                    icon: const Icon(Icons.payments_rounded, size: 18),
                    label: Text(_isClient ? _t.collect : _t.pay),
                  ),
                ],
              ),
            ] else
              const SizedBox(height: 6),
          ],
        ),
      ),
    ),
    );
  }

  Widget _petiteInfo(IconData icone, String texte, {Color? couleur}) {
    final c = couleur ?? Colors.grey.shade600;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icone, size: 13, color: c),
        const SizedBox(width: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 240),
          child: Text(texte,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11.5, color: c, fontWeight: couleur != null ? FontWeight.bold : null)),
        ),
      ],
    );
  }
}
