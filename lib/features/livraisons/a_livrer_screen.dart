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

// ============================================================================
// 🚚 VENTES À LIVRER (statutLivraison == 'Non livré')
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
    '${_deuxChiffres(d.day)}/${_deuxChiffres(d.month)}/${d.year} à ${_deuxChiffres(d.hour)}:${_deuxChiffres(d.minute)}';

String _formatJour(DateTime d) =>
    '${_deuxChiffres(d.day)}/${_deuxChiffres(d.month)}/${d.year}';

double _nombre(dynamic v) => v is num ? v.toDouble() : 0.0;

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
        nbRetard > 0 ? 'À livrer ($nbRetard en retard)' : 'À livrer',
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('À livrer'),
        backgroundColor: Colors.amber.shade700,
        foregroundColor: Colors.white,
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Erreur de chargement : $e', textAlign: TextAlign.center),
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
                  const Text(
                    'Aucune livraison en attente',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text('Tous les clients ont reçu leur marchandise.'),
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
                      ? '${docs.length} client(s) en attente — dont $nbRetard en retard'
                      : '${docs.length} client(s) attendent leur marchandise',
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

  List<Map<String, dynamic>> get _articles {
    final brut = widget.data['articles'];
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
    final reste = _nombre(widget.data['resteAPayer']);
    final articles = _articles.map((a) => '${a['quantite']} × ${a['nom']}').join(', ');

    final message = StringBuffer(
        'Bonjour $client, votre marchandise ($articles) vous attend chez $boutique. ');
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
        const SnackBar(content: Text("Impossible d'ouvrir WhatsApp.")),
      );
    }
  }

  Future<void> _marquerLivre() async {
    final client = (widget.data['nomClient'] ?? 'Client').toString();
    final telephone = (widget.data['telephoneClient'] ?? '').toString();
    final reste = _nombre(widget.data['resteAPayer']);
    final articles = _articles;

    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la livraison'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Remettre à $client :', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...articles.map((a) => Text('• ${a['quantite']} × ${a['nom']}')),
            if (reste > 0.005) ...[
              const SizedBox(height: 12),
              Text(
                'Attention : il reste ${ref.formatPrice(reste)} à payer.',
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Oui, livré'),
          ),
        ],
      ),
    );

    if (confirme != true || !mounted) return;

    setState(() => _enCours = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final nomLivreur = await _nomUtilisateurConnecte();

    final venteRef = FirebaseFirestore.instance
        .collection('entreprises')
        .doc(widget.entrepriseId)
        .collection('ventes')
        .doc(widget.venteId);

    bool horsLigne = false;
    try {
      await venteRef.update({
        'statutLivraison': 'Livré',
        'dateLivraison': Timestamp.now(),
        'livrePar': FirebaseAuth.instance.currentUser?.uid,
        'livreParNom': nomLivreur,
      }).timeout(const Duration(seconds: 5));
    } on TimeoutException {
      horsLigne = true; // gardé sur le téléphone, envoyé au retour d'internet
    } catch (e) {
      if (mounted) setState(() => _enCours = false);
      messenger.showSnackBar(
        SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
      );
      return;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(horsLigne
            ? 'Livraison notée sur le téléphone. Envoi dès le retour d\'internet.'
            : 'Livraison enregistrée pour $client.'),
        backgroundColor: horsLigne ? Colors.orange.shade800 : Colors.green.shade700,
      ),
    );

    // Bon de livraison à remettre au client
    final itemsBL = articles
        .map((a) => CartItem(
              id: (a['produitId'] ?? '').toString(),
              nom: (a['nom'] ?? '').toString(),
              prix: _nombre(a['prixUnitaire']),
              quantite: (a['quantite'] is num) ? (a['quantite'] as num).toInt() : 0,
              stock: 0,
            ))
        .toList();

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
    final client = (widget.data['nomClient'] ?? 'Client').toString();
    final telephone = (widget.data['telephoneClient'] ?? '').toString();
    final vendeurNom = (widget.data['vendeurNom'] ?? '').toString();
    final total = _nombre(widget.data['montantTotal']);
    final reste = _nombre(widget.data['resteAPayer']);
    final date = _dateDe(widget.data);
    final limite = _dateLimite(widget.data);
    final maintenant = DateTime.now();
    final enRetard = maintenant.isAfter(limite);
    final articles = _articles;

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
          ? 'Délai dépassé (limite : ${_formatJour(limite)})'
          : 'Délai dépassé de $retard jour${retard > 1 ? 's' : ''} (limite : ${_formatJour(limite)})';
    } else if (ecartJours <= 1) {
      couleur = Colors.orange.shade800;
      texteDelai = ecartJours == 0
          ? "À retirer aujourd'hui (limite : ${_formatJour(limite)})"
          : 'À retirer avant demain soir (${_formatJour(limite)})';
    } else {
      couleur = Colors.blueGrey;
      texteDelai = 'À retirer avant le ${_formatJour(limite)} ($ecartJours jours restants)';
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
                    tooltip: 'Appeler $telephone',
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
                    ? 'Vendu le ${_formatDate(date)}'
                    : 'Vendu le ${_formatDate(date)} par $vendeurNom',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
              ),
            ),

            // Articles
            const Text('À remettre :', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            ...articles.map((a) => Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 2),
                  child: Text('• ${a['quantite']} × ${a['nom']}'),
                )),
            const SizedBox(height: 8),

            // Montants
            Text('Facture : ${ref.formatPrice(total)}',
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
                  'Reste à payer : ${ref.formatPrice(reste)} — à encaisser avant de livrer',
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => _relancerWhatsApp(telephone),
                        icon: const Icon(Icons.chat),
                        label: const Text('Relancer'),
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
                      label: const Text(
                        'Marquer comme livré',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}