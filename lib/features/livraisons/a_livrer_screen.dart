import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers/cart_provider.dart';
import '../../core/providers/entreprise_provider.dart';
import '../../core/utils/currency_extension.dart';
import '../../screens/bon_livraison_screen.dart';
import '../ventes/retour_vente_screen.dart';
import 'package:stockly_saas/core/services/journal_service.dart';
import '../ventes/restes_creances.dart';
import 'package:stockly_saas/l10n/app_localizations.dart';

// ============================================================================
// 🚚 VENTES À LIVRER (statutLivraison == 'Non livré')
// Une vente partiellement livrée reste 'Non livré' (avec livraisonPartielle = true)
// jusqu'à ce que toute la marchandise soit sortie ou annulée.
// Tri : les retards d'abord, puis par date limite la plus proche.
// ============================================================================
final ventesALivrerProvider = StreamProvider.family<
    List<QueryDocumentSnapshot<Map<String, dynamic>>>, String>((ref, entrepriseId) {
  if (entrepriseId.isEmpty) {
    return Stream.value(const <QueryDocumentSnapshot<Map<String, dynamic>>>[]);
  }
  return FirebaseFirestore.instance
      .collection('entreprises')
      .doc(entrepriseId)
      .collection('ventes')
      .where('statutLivraison', isEqualTo: 'Non livré')
      .snapshots()
      .map((snap) {
    final docs = snap.docs.toList();
    docs.sort((a, b) => _dateLimite(a.data()).compareTo(_dateLimite(b.data())));
    return docs;
  });
});

DateTime _dateDe(Map<String, dynamic> data) {
  final v = data['date'] ?? data['createdAt'];
  if (v is Timestamp) return v.toDate();
  return DateTime.now();
}

/// Date limite de retrait. Anciennes ventes sans date limite : 7 jours après la vente.
DateTime _dateLimite(Map<String, dynamic> data) {
  final v = data['dateLimiteLivraison'];
  if (v is Timestamp) return v.toDate();
  final d = _dateDe(data).add(const Duration(days: 7));
  return DateTime(d.year, d.month, d.day, 23, 59, 59);
}

bool _estEnRetard(Map<String, dynamic> data) =>
    DateTime.now().isAfter(_dateLimite(data));

String _deuxChiffres(int n) => n.toString().padLeft(2, '0');

String _formatDate(DateTime d) =>
    '${_deuxChiffres(d.day)}/${_deuxChiffres(d.month)}/${d.year} ${_deuxChiffres(d.hour)}:${_deuxChiffres(d.minute)}';

String _formatJour(DateTime d) =>
    '${_deuxChiffres(d.day)}/${_deuxChiffres(d.month)}/${d.year}';

double _nombre(dynamic v) => v is num ? v.toDouble() : 0.0;

int _entier(dynamic v) {
  if (v is num) return v.toInt();
  return int.tryParse('$v') ?? 0;
}

List<int> _listeEntiers(dynamic brut, int n) {
  final res = List<int>.filled(n, 0);
  if (brut is List) {
    for (var i = 0; i < n && i < brut.length; i++) {
      res[i] = _entier(brut[i]);
    }
  }
  return res;
}

/// Nom de l'utilisateur connecté (lu dans son profil : téléphone d'abord, puis serveur).
Future<String> _nomUtilisateurConnecte() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return '';
  final ref = FirebaseFirestore.instance.collection('users').doc(uid);
  try {
    final d = await ref.get(const GetOptions(source: Source.cache));
    final n = d.data()?['nom'];
    if (n is String && n.trim().isNotEmpty) return n.trim();
  } catch (_) {}
  try {
    final d = await ref.get().timeout(const Duration(seconds: 3));
    final n = d.data()?['nom'];
    if (n is String) return n.trim();
  } catch (_) {}
  return '';
}

// ============================================================================
// 🚚 BOUTON « À LIVRER » POUR L'ACCUEIL (pastille + rouge si retard)
// ============================================================================
class ALivrerNavButton extends ConsumerWidget {
  final String entrepriseId;
  const ALivrerNavButton({super.key, required this.entrepriseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docs = ref
            .watch(ventesALivrerProvider(entrepriseId))
            .whenOrNull(data: (d) => d) ??
        const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    final nb = docs.length;
    final nbRetard = docs.where((d) => _estEnRetard(d.data())).length;
    final t = AppLocalizations.of(context);

    final Color fond = nbRetard > 0
        ? Colors.red.shade300
        : (nb > 0 ? Colors.amber.shade200 : Colors.blueGrey.shade50);
    final Color texte = nbRetard > 0 ? Colors.white : Colors.brown.shade900;

    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: fond,
        foregroundColor: texte,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      ),
      icon: Badge(
        isLabelVisible: nb > 0,
        label: Text('$nb'),
        child: const Icon(Icons.local_shipping, size: 18),
      ),
      label: Text(
        nbRetard > 0 ? t.livButtonLate(nbRetard) : t.livTitle,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      ),
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ALivrerScreen(entrepriseId: entrepriseId),
        ),
      ),
    );
  }
}

// ============================================================================
// 🚚 ÉCRAN « À LIVRER »
// ============================================================================
class ALivrerScreen extends ConsumerWidget {
  final String entrepriseId;
  const ALivrerScreen({super.key, required this.entrepriseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(ventesALivrerProvider(entrepriseId));
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.livTitle),
        backgroundColor: Colors.amber.shade700,
        foregroundColor: Colors.white,
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(t.errorPrefix('$e'), textAlign: TextAlign.center),
          ),
        ),
        data: (docs) {
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.task_alt, size: 72, color: Colors.green.shade400),
                  const SizedBox(height: 12),
                  Text(
                    t.livNoneTitle,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(t.livNoneSub),
                ],
              ),
            );
          }

          final nbRetard = docs.where((d) => _estEnRetard(d.data())).length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 4),
                child: Text(
                  nbRetard > 0
                      ? t.livWaitingLate(docs.length, nbRetard)
                      : t.livWaiting(docs.length),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: nbRetard > 0 ? Colors.red : Colors.brown.shade800,
                  ),
                ),
              ),
              ...docs.map((d) => _CarteLivraison(
                    key: ValueKey(d.id),
                    entrepriseId: entrepriseId,
                    venteId: d.id,
                    data: d.data(),
                  )),
            ],
          );
        },
      ),
    );
  }
}

// ============================================================================
// 🚚 CARTE D'UNE LIVRAISON EN ATTENTE
// ============================================================================
class _CarteLivraison extends ConsumerStatefulWidget {
  final String entrepriseId;
  final String venteId;
  final Map<String, dynamic> data;

  const _CarteLivraison({
    super.key,
    required this.entrepriseId,
    required this.venteId,
    required this.data,
  });

  @override
  ConsumerState<_CarteLivraison> createState() => _CarteLivraisonState();
}

class _CarteLivraisonState extends ConsumerState<_CarteLivraison> {
  bool _enCours = false;

  AppLocalizations get _t => AppLocalizations.of(context);

  List<Map<String, dynamic>> get _articles {
    final brut = widget.data['articles'];
    if (brut is! List) return [];
    return brut.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// Quantités déjà remises au client, article par article.
  List<int> get _quantitesLivrees =>
      _listeEntiers(widget.data['quantitesLivrees'], _articles.length);

  /// Quantités annulées (jamais retirées), article par article.
  List<int> get _quantitesAnnulees =>
      _listeEntiers(widget.data['quantitesAnnulees'], _articles.length);

  /// Quantités restant à remettre, article par article.
  List<int> get _restes {
    final articles = _articles;
    final livrees = _quantitesLivrees;
    final annulees = _quantitesAnnulees;
    return List<int>.generate(articles.length, (i) {
      final r = _entier(articles[i]['quantite']) - livrees[i] - annulees[i];
      return r > 0 ? r : 0;
    });
  }

  /// Historique des sorties déjà faites.
  List<Map<String, dynamic>> get _sorties {
    final brut = widget.data['livraisons'];
    if (brut is! List) return [];
    return brut.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  String _numeroPropre(String telephone) {
    var n = telephone.replaceAll(RegExp(r'[^\d+]'), '');
    if (n.startsWith('+')) n = n.substring(1);
    // Numéro local RDC (ex : 0973...) → indicatif 243
    if (n.startsWith('0')) n = '243${n.substring(1)}';
    return n;
  }

  Future<void> _appeler(String telephone) async {
    final propre = telephone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (propre.isEmpty) return;
    try {
      await launchUrl(Uri.parse('tel:$propre'));
    } catch (e) {
      debugPrint("Impossible d'appeler : $e");
    }
  }

  Future<void> _relancerWhatsApp(String telephone) async {
    final client = (widget.data['nomClient'] ?? 'Client').toString();
    final boutique = ref.read(entrepriseProvider).nom;
    final limite = _dateLimite(widget.data);
    final enRetard = _estEnRetard(widget.data);
    final reste = resteReel(widget.data, widget.venteId);
    final articles = _articles;
    final restes = _restes;
    final dejaSorti = _quantitesLivrees.any((q) => q > 0);

    final listeRestante = [
      for (var i = 0; i < articles.length; i++)
        if (restes[i] > 0) '${restes[i]} × ${articles[i]['nom']}',
    ].join(', ');

    final message = StringBuffer(dejaSorti
        ? 'Bonjour $client, le reste de votre marchandise ($listeRestante) vous attend chez $boutique. '
        : 'Bonjour $client, votre marchandise ($listeRestante) vous attend chez $boutique. ');
    if (enRetard) {
      message.write(
          'La date de retrait (${_formatJour(limite)}) est dépassée : merci de passer la récupérer au plus vite. ');
    } else {
      message.write('Merci de passer la retirer avant le ${_formatJour(limite)}. ');
    }
    if (reste > 0.005) {
      message.write('Reste à payer : ${ref.formatPrice(reste)}. ');
    }
    message.write('Merci !');

    final uri = Uri.parse(
        'https://wa.me/${_numeroPropre(telephone)}?text=${Uri.encodeComponent(message.toString())}');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t.livNoWhatsapp)),
      );
    }
  }

  // ==========================================================================
  // ✖️ ANNULATION (marchandise jamais retirée)
  // ==========================================================================
  void _annuler() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RetourVenteScreen(
          entrepriseId: widget.entrepriseId,
          venteId: widget.venteId,
          data: widget.data,
          annulation: true,
        ),
      ),
    );
  }

  // ==========================================================================
  // REMISE DE LA MARCHANDISE (totale ou partielle)
  // ==========================================================================
  Future<void> _marquerLivre() async {
    final client = (widget.data['nomClient'] ?? 'Client').toString();
    final telephone = (widget.data['telephoneClient'] ?? '').toString();
    final resteAPayer = resteReel(widget.data, widget.venteId);
    final articles = _articles;
    final dejaLivrees = _quantitesLivrees;
    final annulees = _quantitesAnnulees;
    final restes = _restes;
    final totalReste = restes.fold<int>(0, (s, r) => s + r);

    // Par défaut : tout ce qui reste est remis maintenant.
    final aRemettre = List<int>.from(restes);

    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) {
          final totalMaintenant = aRemettre.fold<int>(0, (s, q) => s + q);
          final resteApres = totalReste - totalMaintenant;

          return AlertDialog(
            title: Text(_t.livHandOverTitle),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_t.livClient(client), style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    _t.livWhatNow,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 8),
                  if (totalReste == 0) Text(_t.livAllGiven),
                  for (var i = 0; i < articles.length; i++)
                    if (restes[i] > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${articles[i]['nom']}',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    dejaLivrees[i] > 0
                                        ? _t.livRemainDone(restes[i], dejaLivrees[i])
                                        : _t.livToHand(restes[i]),
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: aRemettre[i] > 0
                                  ? () => setD(() => aRemettre[i]--)
                                  : null,
                            ),
                            SizedBox(
                              width: 28,
                              child: Text(
                                '${aRemettre[i]}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: aRemettre[i] < restes[i]
                                  ? () => setD(() => aRemettre[i]++)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                  if (totalReste > 0) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: resteApres > 0 ? Colors.orange.shade50 : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        totalMaintenant == 0
                            ? _t.livChooseOne
                            : resteApres > 0
                                ? _t.livPartialAfter(resteApres)
                                : _t.livComplete,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: resteApres > 0 ? Colors.orange.shade900 : Colors.green.shade800,
                        ),
                      ),
                    ),
                  ],
                  if (resteAPayer > 0.005) ...[
                    const SizedBox(height: 12),
                    Text(
                      _t.livWarnUnpaid(ref.formatPrice(resteAPayer)),
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(_t.cancel),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                ),
                onPressed: (totalMaintenant > 0 || totalReste == 0)
                    ? () => Navigator.pop(ctx, true)
                    : null,
                child: Text(resteApres > 0 ? _t.livValidateExit : _t.livAllDelivered),
              ),
            ],
          );
        },
      ),
    );

    if (confirme != true || !mounted) return;
    final t = _t;

    setState(() => _enCours = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final nomLivreur = await _nomUtilisateurConnecte();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final maintenant = Timestamp.now();

    final nouvellesLivrees = List<int>.generate(
        articles.length, (i) => dejaLivrees[i] + aRemettre[i]);
    var toutLivre = true;
    for (var i = 0; i < articles.length; i++) {
      if (nouvellesLivrees[i] + annulees[i] < _entier(articles[i]['quantite'])) {
        toutLivre = false;
      }
    }
    final restantApres =
        totalReste - aRemettre.fold<int>(0, (s, q) => s + q);

    final sortieArticles = <Map<String, dynamic>>[
      for (var i = 0; i < articles.length; i++)
        if (aRemettre[i] > 0)
          {
            'produitId': (articles[i]['produitId'] ?? '').toString(),
            'nom': (articles[i]['nom'] ?? '').toString(),
            'quantite': aRemettre[i],
          },
    ];

    final miseAJour = <String, dynamic>{
      'quantitesLivrees': nouvellesLivrees,
      'livraisonPartielle': !toutLivre,
      if (sortieArticles.isNotEmpty)
        'livraisons': FieldValue.arrayUnion([
          {
            'date': maintenant,
            'par': uid,
            'parNom': nomLivreur,
            'articles': sortieArticles,
          }
        ]),
      if (toutLivre) ...{
        'statutLivraison': 'Livré',
        'dateLivraison': maintenant,
        'livrePar': uid,
        'livreParNom': nomLivreur,
      },
    };

    final venteRef = FirebaseFirestore.instance
        .collection('entreprises')
        .doc(widget.entrepriseId)
        .collection('ventes')
        .doc(widget.venteId);

    bool horsLigne = false;
    try {
      await venteRef.update(miseAJour).timeout(const Duration(seconds: 5));
    } on TimeoutException {
      horsLigne = true; // gardé sur le téléphone, envoyé au retour d'internet
    } catch (e) {
      if (mounted) setState(() => _enCours = false);
      messenger.showSnackBar(
        SnackBar(content: Text(t.errorPrefix('$e')), backgroundColor: Colors.red),
      );
      return;
    }

    if (mounted) setState(() => _enCours = false);

    // 📒 Journal : qui a remis quoi (n'empêche jamais la livraison)
    if (sortieArticles.isNotEmpty) {
      unawaited(noterJournal(
        entrepriseId: widget.entrepriseId,
        action: ActionsJournal.livraison,
        details: 'Facture ${widget.venteId.length >= 8 ? widget.venteId.substring(0, 8).toUpperCase() : widget.venteId}'
            ' · $client · '
            '${sortieArticles.map((a) => '${a['quantite']} × ${a['nom']}').join(', ')}'
            '${toutLivre ? ' · tout est livré' : ' · livré en partie'}',
        boutiqueId: (widget.data['boutiqueId'] ?? '').toString(),
        reference: widget.venteId,
      ));
    }

    final String texte;
    if (horsLigne) {
      texte = t.livSavedOffline;
    } else if (toutLivre) {
      texte = t.livCompleteSaved(client);
    } else {
      texte = t.livPartialSaved(restantApres);
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(texte),
        backgroundColor: horsLigne
            ? Colors.orange.shade800
            : (toutLivre ? Colors.green.shade700 : Colors.blue.shade700),
      ),
    );

    if (sortieArticles.isEmpty) return;

    // Bon de livraison : seulement ce qui sort aujourd'hui
    final itemsBL = <CartItem>[
      for (var i = 0; i < articles.length; i++)
        if (aRemettre[i] > 0)
          CartItem(
            id: (articles[i]['produitId'] ?? '').toString(),
            nom: (articles[i]['nom'] ?? '').toString(),
            prix: _nombre(articles[i]['prixUnitaire']),
            quantite: aRemettre[i],
            stock: 0,
          ),
    ];

    navigator.push(
      MaterialPageRoute(
        builder: (_) => BonLivraisonScreen(
          entrepriseId: widget.entrepriseId,
          nomClient: client,
          adresseClient: '',
          telephoneClient: telephone,
          articles: itemsBL,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 💳 Suit les paiements de dette : le reste se met à jour tout seul
    ref.watch(restesCreancesProvider(widget.entrepriseId));
    final client = (widget.data['nomClient'] ?? 'Client').toString();
    final telephone = (widget.data['telephoneClient'] ?? '').toString();
    final vendeurNom = (widget.data['vendeurNom'] ?? '').toString();
    final total = _nombre(widget.data['montantTotal']);
    final reste = resteReel(widget.data, widget.venteId);
    final date = _dateDe(widget.data);
    final limite = _dateLimite(widget.data);
    final maintenant = DateTime.now();
    final enRetard = maintenant.isAfter(limite);
    final articles = _articles;
    final livrees = _quantitesLivrees;
    final annulees = _quantitesAnnulees;
    final restes = _restes;
    final sorties = _sorties;
    final partielle = livrees.any((q) => q > 0);
    final t = _t;

    // Jours de retard, ou jours restants
    final debutAujourdhui = DateTime(maintenant.year, maintenant.month, maintenant.day);
    final debutLimite = DateTime(limite.year, limite.month, limite.day);
    final ecartJours = debutLimite.difference(debutAujourdhui).inDays;

    final Color couleur;
    final String texteDelai;
    if (enRetard) {
      final retard = -ecartJours;
      couleur = Colors.red;
      texteDelai = retard <= 0
          ? t.livLatePassed(_formatJour(limite))
          : t.livLateDays(retard, _formatJour(limite));
    } else if (ecartJours <= 1) {
      couleur = Colors.orange.shade800;
      texteDelai = ecartJours == 0
          ? t.livPickToday(_formatJour(limite))
          : t.livPickTomorrow(_formatJour(limite));
    } else {
      couleur = Colors.blueGrey;
      texteDelai = t.livPickBefore(_formatJour(limite), ecartJours);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: couleur.withValues(alpha: enRetard ? 0.9 : 0.5),
          width: enRetard ? 2 : 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Client + appel
            Row(
              children: [
                const Icon(Icons.person, size: 20),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    client,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (telephone.isNotEmpty)
                  IconButton(
                    tooltip: t.livCall(telephone),
                    icon: const Icon(Icons.call, color: Colors.green),
                    onPressed: () => _appeler(telephone),
                  ),
              ],
            ),
            if (telephone.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 26, bottom: 4),
                child: Text(telephone, style: TextStyle(color: Colors.grey.shade700)),
              ),

            // Étiquette « Partiellement livré »
            if (partielle)
              Container(
                margin: const EdgeInsets.only(top: 2, bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue.shade300),
                ),
                child: Text(
                  t.livPartial,
                  style: TextStyle(
                    color: Colors.blue.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),

            // Délai
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 4, bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: couleur.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(enRetard ? Icons.warning_amber_rounded : Icons.event,
                      size: 16, color: couleur),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      texteDelai,
                      style: TextStyle(color: couleur, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 2),
              child: Text(
                vendeurNom.isEmpty
                    ? t.livSoldOn(_formatDate(date))
                    : t.livSoldOnBy(_formatDate(date), vendeurNom),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
              ),
            ),

            // Articles
            Text(
              partielle ? t.livStillToHand : t.livToHandColon,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            for (var i = 0; i < articles.length; i++)
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    restes[i] == 0
                        ? Text(
                            '✓ ${articles[i]['quantite']} × ${articles[i]['nom']} — ${t.livNothingToHand}',
                            style: TextStyle(color: Colors.grey.shade500),
                          )
                        : Text(
                            (livrees[i] > 0 || annulees[i] > 0)
                                ? '• ${restes[i]} × ${articles[i]['nom']}  ${t.livOutOf('${articles[i]['quantite']}')}'
                                : '• ${articles[i]['quantite']} × ${articles[i]['nom']}',
                          ),
                    if (livrees[i] > 0)
                      Text('   ${t.livHanded(livrees[i])}',
                          style: TextStyle(fontSize: 11, color: Colors.blue.shade700)),
                    if (annulees[i] > 0)
                      Text('   ✕ ${t.livCancelled(annulees[i])}',
                          style: TextStyle(fontSize: 11, color: Colors.red.shade700)),
                  ],
                ),
              ),

            // Historique des sorties
            if (sorties.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                t.livAlreadyOut,
                style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blue.shade800),
              ),
              for (final s in sorties)
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 2),
                  child: Text(
                    _texteSortie(s),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ),
            ],
            const SizedBox(height: 8),

            // Montants
            Text(t.retInvoiceAmount(ref.formatPrice(total)),
                style: TextStyle(color: Colors.grey.shade800)),
            if (reste > 0.005)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 6),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  t.livUnpaid(ref.formatPrice(reste)),
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
            const SizedBox(height: 12),

            // Boutons
            Row(
              children: [
                if (telephone.isNotEmpty) ...[
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green.shade800,
                          side: BorderSide(color: Colors.green.shade700),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => _relancerWhatsApp(telephone),
                        icon: const Icon(Icons.chat, size: 18),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(t.livRemind, maxLines: 1, softWrap: false),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 46,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _enCours ? null : _marquerLivre,
                      icon: _enCours
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check_circle),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          t.livMarkDelivered,
                          maxLines: 1,
                          softWrap: false,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Annulation (gérant et patron ; contrôlé dans l'écran)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
                onPressed: _enCours ? null : _annuler,
                icon: const Icon(Icons.cancel_outlined, size: 18),
                label: Text(t.retCancelTitle),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _texteSortie(Map<String, dynamic> s) {
    final d = s['date'];
    final quand = d is Timestamp ? _formatDate(d.toDate()) : '';
    final arts = s['articles'];
    final liste = arts is List
        ? arts
            .whereType<Map>()
            .map((a) => '${a['quantite']} × ${a['nom']}')
            .join(', ')
        : '';
    final par = (s['parNom'] ?? '').toString();
    return par.isEmpty ? '$quand : $liste' : '$quand : $liste ${_t.livBy(par)}';
  }
}