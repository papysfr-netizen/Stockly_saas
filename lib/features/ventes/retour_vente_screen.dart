import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/user_role_provider.dart';
import '../../core/services/utilisateur_service.dart';
import '../../core/utils/currency_extension.dart';
import '../comptes_clients/compte_client_service.dart';

// ============================================================================
// ↩️ RETOUR DE MARCHANDISE  /  ✖️ ANNULATION DE VENTE NON RETIRÉE
// - Gérant et patron seulement.
// - Retour : marchandise déjà remise au client ; après 7 jours, patron seulement.
//   Stock remis (sauf articles abîmés).
// - Annulation : marchandise jamais retirée ; tout revient en stock.
// - Dette du client diminuée d'abord, puis : espèces, avoir (versé sur le
//   COMPTE CLIENT), ou (annulation seulement) la boutique garde l'acompte.
// - Écritures comptables inverses (701 / 411 / 571, 419100 ou 758, et 311 / 603).
// ============================================================================

int _entier(dynamic v) {
  if (v is num) return v.toInt();
  return int.tryParse('$v') ?? 0;
}

double _nombre(dynamic v) => v is num ? v.toDouble() : 0.0;

double _arrondi(double v) => (v * 100).roundToDouble() / 100;

List<int> _liste(dynamic brut, int n) {
  final res = List<int>.filled(n, 0);
  if (brut is List) {
    for (var i = 0; i < n && i < brut.length; i++) {
      res[i] = _entier(brut[i]);
    }
  }
  return res;
}

String _deux(int n) => n.toString().padLeft(2, '0');
String _jour(DateTime d) => '${_deux(d.day)}/${_deux(d.month)}/${d.year}';

class RetourVenteScreen extends ConsumerStatefulWidget {
  final String entrepriseId;
  final String venteId;
  final Map<String, dynamic> data;

  /// true = annulation de marchandise jamais retirée ;
  /// false = retour de marchandise déjà remise au client.
  final bool annulation;

  const RetourVenteScreen({
    super.key,
    required this.entrepriseId,
    required this.venteId,
    required this.data,
    this.annulation = false,
  });

  @override
  ConsumerState<RetourVenteScreen> createState() => _RetourVenteScreenState();
}

class _RetourVenteScreenState extends ConsumerState<RetourVenteScreen> {
  static const int delaiJours = 7;

  late final List<Map<String, dynamic>> _articles;
  late final List<int> _livrees;
  late final List<int> _dejaRetournees;
  late final List<int> _dejaAnnulees;
  late final List<int> _max;
  late final List<int> _qte;
  late final List<bool> _abime;

  String _mode = 'especes';
  final _motifCtrl = TextEditingController();
  late final TextEditingController _telAvoirCtrl;
  bool _enCours = false;

  bool get _annulation => widget.annulation;
  Color get _couleur => _annulation ? Colors.red.shade800 : Colors.deepOrange.shade700;

  @override
  void initState() {
    super.initState();
    final brut = widget.data['articles'];
    _articles = brut is List
        ? brut.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
        : <Map<String, dynamic>>[];
    final n = _articles.length;

    // Quantités remises au client :
    // - liste « quantitesLivrees » si elle existe (livraisons partielles) ;
    // - sinon tout, si la vente est livrée (anciennes ventes comprises) ;
    // - sinon rien.
    final statut = (widget.data['statutLivraison'] ?? 'Livré').toString();
    final brutLivrees = widget.data['quantitesLivrees'];
    _livrees = brutLivrees is List
        ? _liste(brutLivrees, n)
        : List<int>.generate(
            n,
            (i) => (statut == 'Non livré' || statut == 'Annulé')
                ? 0
                : _entier(_articles[i]['quantite']),
          );

    _dejaRetournees = _liste(widget.data['quantitesRetournees'], n);
    _dejaAnnulees = _liste(widget.data['quantitesAnnulees'], n);

    _max = List<int>.generate(n, (i) {
      final q = _entier(_articles[i]['quantite']);
      final m = _annulation
          ? q - _livrees[i] - _dejaAnnulees[i] // jamais sorti, pas encore annulé
          : _livrees[i] - _dejaRetournees[i]; // sorti, pas encore retourné
      return m > 0 ? m : 0;
    });
    _qte = List<int>.filled(n, 0);
    _abime = List<bool>.filled(n, false);

    _telAvoirCtrl = TextEditingController(
        text: (widget.data['telephoneClient'] ?? '').toString());
  }

  @override
  void dispose() {
    _motifCtrl.dispose();
    _telAvoirCtrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- calculs
  DateTime get _dateVente {
    final v = widget.data['date'] ?? widget.data['createdAt'];
    return v is Timestamp ? v.toDate() : DateTime.now();
  }

  double get _montant {
    var t = 0.0;
    for (var i = 0; i < _articles.length; i++) {
      t += _qte[i] * _nombre(_articles[i]['prixUnitaire']);
    }
    return _arrondi(t);
  }

  double get _detteVente => _nombre(widget.data['resteAPayer']);

  double get _reductionPrevue => _arrondi(math.min(_montant, _detteVente));

  double get _aRembourserPrevu => _arrondi(_montant - _reductionPrevue);

  /// Un avoir doit être rattaché à un compte client (téléphone valide).
  bool get _avoirSansTelephone =>
      _mode == 'avoir' &&
      _aRembourserPrevu > 0.005 &&
      !CompteClientService.telephoneValide(_telAvoirCtrl.text);

  // ---------------------------------------------------------------- interface
  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_annulation ? 'Annuler la vente' : 'Retour de marchandise'),
        backgroundColor: _couleur,
        foregroundColor: Colors.white,
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (profile) => _corps(
          peutRetour: profile.peutFaireRetours,
          estPatron: profile.role.peutGererEquipe,
        ),
      ),
    );
  }

  Widget _message(IconData icone, String texte, {Color? couleur}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 64, color: couleur ?? Colors.grey.shade500),
            const SizedBox(height: 16),
            Text(texte, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15)),
          ],
        ),
      ),
    );
  }

  Widget _corps({required bool peutRetour, required bool estPatron}) {
    final client = (widget.data['nomClient'] ?? 'Client').toString();
    final dateVente = _dateVente;
    final jours = DateTime.now().difference(dateVente).inDays;
    final horsDelai = !_annulation && jours > delaiJours;

    if (!peutRetour) {
      return _message(
        Icons.lock_outline,
        _annulation
            ? 'Seuls le gérant et le patron peuvent annuler une vente.'
            : 'Seuls le gérant et le patron peuvent enregistrer un retour.',
      );
    }
    if (horsDelai && !estPatron) {
      return _message(
        Icons.timer_off_outlined,
        'Délai de retour dépassé : vente du ${_jour(dateVente)} '
        '(il y a $jours jours, limite $delaiJours jours).\n\n'
        'Seul le patron peut accepter ce retour.',
        couleur: Colors.red.shade300,
      );
    }
    if (_max.every((m) => m == 0)) {
      return _message(
        Icons.info_outline,
        _annulation
            ? 'Rien à annuler sur cette vente.\n\n'
                'Toute la marchandise a déjà été remise au client ou déjà annulée. '
                "S'il la rapporte, utilisez « Retour de marchandise »."
            : 'Rien à retourner sur cette vente.\n\n'
                "Soit tout a déjà été retourné, soit la marchandise n'a pas encore "
                'été remise au client (dans ce cas, utilisez « Annuler la vente »).',
      );
    }

    final montant = _montant;
    final reduction = _reductionPrevue;
    final aRembourser = _aRembourserPrevu;
    final motifOk = _motifCtrl.text.trim().isNotEmpty;

    final String explicationMode;
    switch (_mode) {
      case 'avoir':
        explicationMode =
            'Le montant est ajouté au compte client : il pourra l\'utiliser en Caisse.';
        break;
      case 'garder':
        explicationMode = "La boutique garde l'argent (acompte non remboursé).";
        break;
      default:
        explicationMode = "L'argent sort de la caisse.";
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
      children: [
        // En-tête
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(client, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Vente du ${_jour(dateVente)} (il y a $jours jour${jours > 1 ? 's' : ''})',
                    style: TextStyle(color: Colors.grey.shade700)),
                Text('Facture : ${ref.formatPrice(_nombre(widget.data['montantTotal']))}',
                    style: TextStyle(color: Colors.grey.shade700)),
                if (_detteVente > 0.005)
                  Text('Le client doit encore : ${ref.formatPrice(_detteVente)}',
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
        if (_annulation)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Text(
              'Marchandise jamais retirée par le client : elle revient en stock et la vente est annulée pour ces articles.',
              style: TextStyle(color: Colors.red.shade900),
            ),
          ),
        if (horsDelai)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade300),
            ),
            child: Text(
              'Hors délai ($jours jours) : retour accepté exceptionnellement par le patron.',
              style: TextStyle(color: Colors.orange.shade900, fontWeight: FontWeight.bold),
            ),
          ),
        const SizedBox(height: 14),
        Text(_annulation ? 'Articles à annuler' : 'Articles rapportés',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),

        // Articles
        for (var i = 0; i < _articles.length; i++)
          if (_max[i] > 0)
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${_articles[i]['nom']}',
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                              Text(
                                _annulation
                                    ? 'Prix : ${ref.formatPrice(_nombre(_articles[i]['prixUnitaire']))}'
                                        ' • non retiré : ${_max[i]}'
                                    : 'Prix : ${ref.formatPrice(_nombre(_articles[i]['prixUnitaire']))}'
                                        ' • retournable : ${_max[i]}'
                                        '${_dejaRetournees[i] > 0 ? ' (déjà retourné : ${_dejaRetournees[i]})' : ''}',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: _qte[i] > 0 ? () => setState(() => _qte[i]--) : null,
                        ),
                        SizedBox(
                          width: 28,
                          child: Text('${_qte[i]}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: _qte[i] < _max[i] ? () => setState(() => _qte[i]++) : null,
                        ),
                      ],
                    ),
                    if (!_annulation && _qte[i] > 0)
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Remettre en vente'),
                            selected: !_abime[i],
                            onSelected: (_) => setState(() => _abime[i] = false),
                          ),
                          ChoiceChip(
                            label: const Text('Abîmé (perte)'),
                            selected: _abime[i],
                            selectedColor: Colors.red.shade100,
                            onSelected: (_) => setState(() => _abime[i] = true),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),

        if (_annulation && _max.where((m) => m > 0).length > 1)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              icon: const Icon(Icons.select_all),
              label: const Text('Tout annuler'),
              onPressed: () => setState(() {
                for (var i = 0; i < _qte.length; i++) {
                  _qte[i] = _max[i];
                }
              }),
            ),
          ),

        // Motif
        const SizedBox(height: 12),
        TextField(
          controller: _motifCtrl,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: _annulation ? "Motif de l'annulation *" : 'Motif du retour *',
            hintText: _annulation
                ? 'Ex : client jamais venu, délai dépassé…'
                : 'Ex : mauvaise taille, défaut de fabrication…',
            border: const OutlineInputBorder(),
          ),
        ),

        // Résumé
        if (montant > 0) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _annulation
                      ? 'Montant annulé : ${ref.formatPrice(montant)}'
                      : 'Montant du retour : ${ref.formatPrice(montant)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                if (reduction > 0.005)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('Déduit de la dette du client : ${ref.formatPrice(reduction)}'),
                  ),
                if (aRembourser > 0.005) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 8),
                    child: Text(
                      _annulation
                          ? 'Déjà payé par le client : ${ref.formatPrice(aRembourser)}'
                          : 'À rendre au client : ${ref.formatPrice(aRembourser)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  SegmentedButton<String>(
                    segments: [
                      const ButtonSegment(
                        value: 'especes',
                        label: Text('Espèces'),
                        icon: Icon(Icons.payments_outlined),
                      ),
                      const ButtonSegment(
                        value: 'avoir',
                        label: Text('Avoir'),
                        icon: Icon(Icons.card_giftcard),
                      ),
                      if (_annulation)
                        const ButtonSegment(
                          value: 'garder',
                          label: Text('Garder'),
                          icon: Icon(Icons.store_outlined),
                        ),
                    ],
                    selected: {_mode},
                    onSelectionChanged: (s) => setState(() => _mode = s.first),
                  ),
                  const SizedBox(height: 4),
                  Text(explicationMode,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                  if (_mode == 'avoir') ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: _telAvoirCtrl,
                      keyboardType: TextInputType.phone,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Téléphone du compte client *',
                        prefixIcon: const Icon(Icons.account_balance_wallet),
                        isDense: true,
                        border: const OutlineInputBorder(),
                        errorText: _avoirSansTelephone
                            ? 'Un avoir a besoin du téléphone du client'
                            : null,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],

        const SizedBox(height: 18),
        SizedBox(
          height: 50,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _couleur,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: (montant > 0 && motifOk && !_avoirSansTelephone && !_enCours)
                ? _valider
                : null,
            icon: _enCours
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Icon(_annulation ? Icons.cancel_outlined : Icons.assignment_return),
            label: Text(
              montant <= 0
                  ? 'Choisissez les articles'
                  : _annulation
                      ? "Valider l'annulation (${ref.formatPrice(montant)})"
                      : 'Valider le retour (${ref.formatPrice(montant)})',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        if (montant > 0 && !motifOk)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('Indiquez le motif pour valider.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------- validation
  Future<void> _valider() async {
    final montant = _montant;
    final nbAbimes = [
      for (var i = 0; i < _articles.length; i++)
        if (_qte[i] > 0 && _abime[i]) _qte[i]
    ].fold<int>(0, (s, q) => s + q);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_annulation ? "Confirmer l'annulation" : 'Confirmer le retour'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < _articles.length; i++)
              if (_qte[i] > 0)
                Text('• ${_qte[i]} × ${_articles[i]['nom']}'
                    '${_abime[i] ? '  (abîmé)' : ''}'),
            const SizedBox(height: 10),
            Text('Montant : ${ref.formatPrice(montant)}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            if (nbAbimes > 0)
              Text('$nbAbimes pièce(s) abîmée(s) : ne reviennent pas en stock.',
                  style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
            if (_mode == 'avoir' && _aRembourserPrevu > 0.005)
              Text(
                'Avoir de ${ref.formatPrice(_aRembourserPrevu)} versé sur le compte ${_telAvoirCtrl.text.trim()}.',
                style: TextStyle(color: Colors.green.shade800, fontSize: 12),
              ),
            const SizedBox(height: 6),
            const Text('Cette opération ne peut pas être annulée.',
                style: TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Retour')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _couleur,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Valider'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _enregistrer();
  }

  /// Lit la créance liée à la vente : serveur d'abord, téléphone si pas d'internet.
  Future<DocumentSnapshot<Map<String, dynamic>>?> _lireCreance(
      CollectionReference<Map<String, dynamic>> creances) async {
    final requete = creances.where('venteId', isEqualTo: widget.venteId).limit(1);
    try {
      final q = await requete.get().timeout(const Duration(seconds: 4));
      return q.docs.isEmpty ? null : q.docs.first;
    } catch (_) {
      try {
        final q = await requete.get(const GetOptions(source: Source.cache));
        return q.docs.isEmpty ? null : q.docs.first;
      } catch (_) {
        return null;
      }
    }
  }

  Future<void> _enregistrer() async {
    setState(() => _enCours = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final db = FirebaseFirestore.instance;
    final entRef = db.collection('entreprises').doc(widget.entrepriseId);
    final venteRef = entRef.collection('ventes').doc(widget.venteId);
    final client = (widget.data['nomClient'] ?? 'Client').toString();
    final telephone = (widget.data['telephoneClient'] ?? '').toString();
    final telAvoir = _telAvoirCtrl.text.trim();
    final motif = _motifCtrl.text.trim();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final now = Timestamp.now();
    final n = _articles.length;
    final numeroFacture = widget.venteId.length >= 8
        ? widget.venteId.substring(0, 8).toUpperCase()
        : widget.venteId.toUpperCase();

    final nomAgent = await nomUtilisateurConnecte();
    final creanceDoc = await _lireCreance(entRef.collection('creances'));

    // Montants
    final montant = _montant;
    final detteActuelle = creanceDoc != null
        ? _nombre(creanceDoc.data()?['montantReste'])
        : _detteVente;
    final reduction = _arrondi(math.max(0, math.min(montant, detteActuelle)));
    final aRembourser = _arrondi(montant - reduction);
    final mode = aRembourser > 0.005 ? _mode : 'aucun';

    // Solde actuel du compte client (pour l'historique)
    final soldeAvantAvoir = mode == 'avoir'
        ? await CompteClientService.lireSolde(widget.entrepriseId, telAvoir)
        : 0.0;

    var coutRemisEnStock = 0.0;
    var coutAbime = 0.0;
    final lignes = <Map<String, dynamic>>[];
    for (var i = 0; i < n; i++) {
      if (_qte[i] <= 0) continue;
      final pa = _nombre(_articles[i]['prixAchat']);
      final abime = !_annulation && _abime[i];
      if (abime) {
        coutAbime += pa * _qte[i];
      } else {
        coutRemisEnStock += pa * _qte[i];
      }
      lignes.add({
        'produitId': (_articles[i]['produitId'] ?? '').toString(),
        'nom': (_articles[i]['nom'] ?? '').toString(),
        'quantite': _qte[i],
        'prixUnitaire': _nombre(_articles[i]['prixUnitaire']),
        'prixAchat': pa,
        'etat': abime ? 'abime' : 'revendable',
      });
    }
    coutRemisEnStock = _arrondi(coutRemisEnStock);
    coutAbime = _arrondi(coutAbime);

    final batch = db.batch();

    // 1. Fiche (historique)
    final retourRef = entRef.collection('retours').doc();
    batch.set(retourRef, {
      'id': retourRef.id,
      'type': _annulation ? 'annulation' : 'retour',
      'entrepriseId': widget.entrepriseId,
      'venteId': widget.venteId,
      'nomClient': client,
      'telephoneClient': telephone,
      'articles': lignes,
      'montant': montant,
      'reductionDette': reduction,
      'montantRembourse': (mode == 'especes' || mode == 'avoir') ? aRembourser : 0.0,
      'montantConserve': mode == 'garder' ? aRembourser : 0.0,
      'modeRemboursement': mode, // 'especes' | 'avoir' | 'garder' | 'aucun'
      'compteClient': mode == 'avoir' ? CompteClientService.normaliser(telAvoir) : null,
      'coutRemisEnStock': coutRemisEnStock,
      'coutAbime': coutAbime,
      'motif': motif,
      'date': now,
      'par': uid,
      'parNom': nomAgent,
    });

    // 2. Vente
    final nouveauReste = _arrondi(math.max(0, _detteVente - reduction));
    final venteMaj = <String, dynamic>{
      'dateDernierRetour': now,
      if (mode == 'garder' && aRembourser > 0.005)
        'montantConserve': FieldValue.increment(aRembourser),
      if (reduction > 0.005) 'resteAPayer': nouveauReste,
      if (reduction > 0.005 && nouveauReste <= 0.005) 'statutPaiement': 'Payé',
    };

    if (_annulation) {
      final nouvellesAnnulees = List<int>.generate(n, (i) => _dejaAnnulees[i] + _qte[i]);
      var plusRienALivrer = true;
      var toutAnnule = true;
      for (var i = 0; i < n; i++) {
        final q = _entier(_articles[i]['quantite']);
        if (_livrees[i] + nouvellesAnnulees[i] < q) plusRienALivrer = false;
        if (nouvellesAnnulees[i] < q) toutAnnule = false;
      }
      venteMaj.addAll({
        'quantitesAnnulees': nouvellesAnnulees,
        'montantAnnule': FieldValue.increment(montant),
        'statutAnnulation': toutAnnule ? 'total' : 'partiel',
        if (plusRienALivrer) 'statutLivraison': toutAnnule ? 'Annulé' : 'Livré',
        if (plusRienALivrer) 'livraisonPartielle': false,
      });
    } else {
      final nouvellesRetournees = List<int>.generate(n, (i) => _dejaRetournees[i] + _qte[i]);
      var toutRetourne = true;
      for (var i = 0; i < n; i++) {
        if (nouvellesRetournees[i] < _entier(_articles[i]['quantite'])) toutRetourne = false;
      }
      venteMaj.addAll({
        'quantitesRetournees': nouvellesRetournees,
        'montantRetourne': FieldValue.increment(montant),
        'statutRetour': toutRetourne ? 'total' : 'partiel',
        if (coutAbime > 0.005) 'coutAbimeRetours': FieldValue.increment(coutAbime),
      });
    }
    batch.update(venteRef, venteMaj);

    // 3. Créance du client
    if (creanceDoc != null && reduction > 0.005) {
      final nouveauCR = _arrondi(math.max(0, detteActuelle - reduction));
      batch.update(creanceDoc.reference, {
        'montantReste': nouveauCR,
        'statut': nouveauCR <= 0.005 ? 'paye' : 'partiel',
        'montantRetour': FieldValue.increment(reduction),
        'updatedAt': now,
      });
    }

    // 3 bis. 💰 Avoir versé sur le compte client
    if (mode == 'avoir') {
      CompteClientService.ajouterMouvement(
        batch,
        entrepriseId: widget.entrepriseId,
        telephone: telAvoir,
        nom: client == 'Client Divers' ? '' : client,
        type: 'avoir',
        delta: aRembourser,
        soldeAvant: soldeAvantAvoir,
        description: _annulation
            ? 'Avoir (annulation facture $numeroFacture)'
            : 'Avoir (retour facture $numeroFacture)',
        date: now,
        uid: uid,
        parNom: nomAgent,
        venteId: widget.venteId,
        retourId: retourRef.id,
      );
    }

    // 4. Écriture comptable inverse de la vente
    final lines = <Map<String, dynamic>>[
      {
        'accountCode': '701000',
        'accountLabel': _annulation
            ? 'Ventes de marchandises (annulation)'
            : 'Ventes de marchandises (retour)',
        'debit': montant,
        'credit': 0.0,
      },
      if (reduction > 0.005)
        {
          'accountCode': '411000',
          'accountLabel': 'Client (Créance) - $client',
          'debit': 0.0,
          'credit': reduction,
        },
      if (mode == 'especes')
        {
          'accountCode': '571000',
          'accountLabel': 'Caisse',
          'debit': 0.0,
          'credit': aRembourser,
        },
      if (mode == 'avoir')
        {
          'accountCode': CompteClientService.compteAvances,
          'accountLabel': '${CompteClientService.libelleAvances} - $client',
          'debit': 0.0,
          'credit': aRembourser,
        },
      if (mode == 'garder')
        {
          'accountCode': '758000',
          'accountLabel': 'Produits divers (acompte conservé) - $client',
          'debit': 0.0,
          'credit': aRembourser,
        },
    ];
    final ecritureRef = entRef.collection('ecritures_comptables').doc('RET-${retourRef.id}');
    batch.set(ecritureRef, {
      'id': ecritureRef.id,
      'entrepriseId': widget.entrepriseId,
      'reference': widget.venteId,
      'retourId': retourRef.id,
      'type': _annulation ? 'annulation' : 'retour',
      'description': _annulation
          ? 'Annulation de vente (non retirée) - $client ($motif)'
          : 'Retour de marchandise - $client ($motif)',
      'date': now,
      'lines': lines,
      'montantEncaisse': 0.0,
      'montantDecaisse': mode == 'especes' ? aRembourser : 0.0,
    });

    // 5. Coût des marchandises remises en stock (inverse de 603 / 311)
    if (coutRemisEnStock > 0.005) {
      final coutRef = entRef.collection('ecritures_comptables').doc('RETSTK-${retourRef.id}');
      batch.set(coutRef, {
        'id': coutRef.id,
        'entrepriseId': widget.entrepriseId,
        'reference': widget.venteId,
        'retourId': retourRef.id,
        'type': _annulation ? 'annulation' : 'retour',
        'description': 'Retour en stock (coût des marchandises) - $client',
        'date': now,
        'lines': [
          {
            'accountCode': '311000',
            'accountLabel': 'Stock de marchandises',
            'debit': coutRemisEnStock,
            'credit': 0.0,
          },
          {
            'accountCode': '603100',
            'accountLabel': 'Variation des stocks de marchandises',
            'debit': 0.0,
            'credit': coutRemisEnStock,
          },
        ],
        'montantEncaisse': 0.0,
      });
    }

    // 6. Stock : articles revendables (tous, pour une annulation)
    for (var i = 0; i < n; i++) {
      if (_qte[i] <= 0) continue;
      if (!_annulation && _abime[i]) continue;
      final id = (_articles[i]['produitId'] ?? '').toString();
      if (id.isEmpty) continue;
      batch.update(entRef.collection('produits').doc(id), {
        'quantite': FieldValue.increment(_qte[i]),
        'updatedAt': now,
      });
    }

    var horsLigne = false;
    try {
      await batch.commit().timeout(const Duration(seconds: 6));
    } on TimeoutException {
      horsLigne = true; // gardé sur le téléphone, envoyé au retour d'internet
    } catch (e) {
      if (mounted) setState(() => _enCours = false);
      messenger.showSnackBar(
        SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
      );
      return;
    }

    final debut = _annulation ? 'Annulation enregistrée.' : 'Retour enregistré.';
    final String texte;
    switch (mode) {
      case 'especes':
        texte = '$debut Rendez ${ref.formatPrice(aRembourser)} au client en espèces.';
        break;
      case 'avoir':
        texte = '$debut Avoir de ${ref.formatPrice(aRembourser)} ajouté au compte client '
            '(nouveau solde : ${ref.formatPrice(soldeAvantAvoir + aRembourser)}).';
        break;
      case 'garder':
        texte = '$debut Acompte de ${ref.formatPrice(aRembourser)} conservé par la boutique.';
        break;
      default:
        texte = '$debut Dette du client diminuée de ${ref.formatPrice(reduction)}.';
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(horsLigne ? "$texte (envoi dès le retour d'internet)" : texte),
        backgroundColor: horsLigne ? Colors.orange.shade800 : Colors.green.shade700,
        duration: const Duration(seconds: 6),
      ),
    );
    navigator.pop(true);
  }
}
