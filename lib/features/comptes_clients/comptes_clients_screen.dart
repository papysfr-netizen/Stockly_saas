import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers/entreprise_provider.dart';
import '../../core/providers/user_role_provider.dart';
import '../../core/utils/currency_extension.dart';
import 'compte_client_service.dart';

// ============================================================================
// 💰 COMPTES CLIENTS : liste, dépôts, retraits, historique, relevé WhatsApp
// ============================================================================

double _num(dynamic v) => v is num ? v.toDouble() : 0.0;

String _deux(int n) => n.toString().padLeft(2, '0');

String _formatDate(DateTime d) =>
    '${_deux(d.day)}/${_deux(d.month)}/${d.year} ${_deux(d.hour)}:${_deux(d.minute)}';

String _formatJour(DateTime d) => '${_deux(d.day)}/${_deux(d.month)}';

final comptesClientsProvider = StreamProvider.family<
    List<QueryDocumentSnapshot<Map<String, dynamic>>>, String>((ref, entrepriseId) {
  if (entrepriseId.isEmpty) {
    return Stream.value(const <QueryDocumentSnapshot<Map<String, dynamic>>>[]);
  }
  return FirebaseFirestore.instance
      .collection('entreprises')
      .doc(entrepriseId)
      .collection('comptes_clients')
      .snapshots()
      .map((snap) {
    final docs = snap.docs.toList();
    docs.sort((a, b) => _num(b.data()['solde']).compareTo(_num(a.data()['solde'])));
    return docs;
  });
});

// ============================================================================
// Dialogue commun : DÉPÔT ou RETRAIT
// ============================================================================
Future<void> ouvrirOperationCompte(
  BuildContext context,
  WidgetRef ref, {
  required String entrepriseId,
  required String type, // 'depot' | 'retrait'
  String telephone = '',
  String nom = '',
  double solde = 0,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final estDepot = type == 'depot';
  final telCtrl = TextEditingController(text: telephone);
  final nomCtrl = TextEditingController(text: nom);
  final montantCtrl = TextEditingController();
  var methode = 'Espèces';
  final telFixe = telephone.isNotEmpty;

  final resultat = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setD) {
        final montant =
            double.tryParse(montantCtrl.text.trim().replaceAll(',', '.')) ?? 0.0;
        final telOk = CompteClientService.telephoneValide(telCtrl.text);
        final depasse = !estDepot && montant > solde + 0.005;
        final valide = telOk && montant > 0 && !depasse;

        return AlertDialog(
          title: Text(estDepot ? 'Dépôt du client' : 'Retrait du client'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: telCtrl,
                  enabled: !telFixe,
                  keyboardType: TextInputType.phone,
                  onChanged: (_) => setD(() {}),
                  decoration: InputDecoration(
                    labelText: 'Téléphone du client *',
                    prefixIcon: const Icon(Icons.phone),
                    errorText: telCtrl.text.isNotEmpty && !telOk ? 'Numéro trop court' : null,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nomCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nom du client',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: montantCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setD(() {}),
                  decoration: InputDecoration(
                    labelText: 'Montant (\$) *',
                    prefixIcon: const Icon(Icons.attach_money),
                    errorText: depasse ? 'Plus que le solde disponible' : null,
                  ),
                ),
                if (!estDepot)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Solde disponible : ${ref.formatPrice(solde)}',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'Espèces',
                      label: Text('Espèces'),
                      icon: Icon(Icons.payments_outlined),
                    ),
                    ButtonSegment(
                      value: 'Mobile Money',
                      label: Text('Mobile Money'),
                      icon: Icon(Icons.phone_android),
                    ),
                  ],
                  selected: {methode},
                  onSelectionChanged: (s) => setD(() => methode = s.first),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: estDepot ? Colors.teal.shade700 : Colors.red.shade700,
                foregroundColor: Colors.white,
              ),
              onPressed: valide ? () => Navigator.pop(ctx, true) : null,
              child: Text(estDepot ? 'Enregistrer le dépôt' : 'Enregistrer le retrait'),
            ),
          ],
        );
      },
    ),
  );

  final tel = telCtrl.text.trim();
  final nomSaisi = nomCtrl.text.trim();
  final montant = double.tryParse(montantCtrl.text.trim().replaceAll(',', '.')) ?? 0.0;
  telCtrl.dispose();
  nomCtrl.dispose();
  montantCtrl.dispose();

  if (resultat != true) return;

  try {
    final enLigne = estDepot
        ? await CompteClientService.depot(
            entrepriseId: entrepriseId,
            telephone: tel,
            nom: nomSaisi,
            montant: montant,
            methode: methode,
          )
        : await CompteClientService.retrait(
            entrepriseId: entrepriseId,
            telephone: tel,
            nom: nomSaisi,
            montant: montant,
            methode: methode,
          );
    final texte = estDepot
        ? 'Dépôt de ${ref.formatPrice(montant)} enregistré.'
        : 'Retrait de ${ref.formatPrice(montant)} enregistré.';
    messenger.showSnackBar(
      SnackBar(
        content: Text(enLigne ? texte : "$texte (envoi dès le retour d'internet)"),
        backgroundColor: enLigne ? Colors.green.shade700 : Colors.orange.shade800,
      ),
    );
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: Colors.red,
      ),
    );
  }
}

// ============================================================================
// 💰 ÉCRAN LISTE
// ============================================================================
class ComptesClientsScreen extends ConsumerStatefulWidget {
  final String entrepriseId;
  const ComptesClientsScreen({super.key, required this.entrepriseId});

  @override
  ConsumerState<ComptesClientsScreen> createState() => _ComptesClientsScreenState();
}

class _ComptesClientsScreenState extends ConsumerState<ComptesClientsScreen> {
  final _rechercheCtrl = TextEditingController();
  String _recherche = '';

  @override
  void dispose() {
    _rechercheCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(comptesClientsProvider(widget.entrepriseId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comptes clients'),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nouveau dépôt'),
        onPressed: () => ouvrirOperationCompte(
          context,
          ref,
          entrepriseId: widget.entrepriseId,
          type: 'depot',
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              controller: _rechercheCtrl,
              onChanged: (v) => setState(() => _recherche = v.trim().toLowerCase()),
              decoration: const InputDecoration(
                hintText: 'Nom ou téléphone…',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur de chargement : $e')),
              data: (docs) {
                final filtres = docs.where((d) {
                  if (_recherche.isEmpty) return true;
                  final data = d.data();
                  final nom = (data['nom'] ?? '').toString().toLowerCase();
                  final tel = (data['telephone'] ?? '').toString().toLowerCase();
                  return nom.contains(_recherche) ||
                      tel.contains(_recherche) ||
                      d.id.contains(_recherche);
                }).toList();

                final totalDu =
                    docs.fold<double>(0, (s, d) => s + _num(d.data()['solde']));

                return Column(
                  children: [
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text('${docs.length} client(s) avec un compte',
                              style: TextStyle(color: Colors.grey.shade700)),
                          const SizedBox(height: 4),
                          Text(
                            'Argent des clients gardé : ${ref.formatPrice(totalDu)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.teal.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: filtres.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: Text(
                                  'Aucun compte client.\nAppuyez sur « Nouveau dépôt » pour en créer un.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 90),
                              itemCount: filtres.length,
                              itemBuilder: (context, i) {
                                final d = filtres[i];
                                final data = d.data();
                                final nom = (data['nom'] ?? '').toString();
                                final tel = (data['telephone'] ?? d.id).toString();
                                final solde = _num(data['solde']);
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.teal.shade100,
                                      child: Icon(Icons.account_balance_wallet,
                                          color: Colors.teal.shade800),
                                    ),
                                    title: Text(
                                      nom.isEmpty ? tel : nom,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: nom.isEmpty ? null : Text(tel),
                                    trailing: Text(
                                      ref.formatPrice(solde),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: solde > 0.005
                                            ? Colors.green.shade800
                                            : Colors.grey,
                                      ),
                                    ),
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => CompteClientDetailScreen(
                                          entrepriseId: widget.entrepriseId,
                                          compteId: d.id,
                                        ),
                                      ),
                                    ),
                                  ),
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

// ============================================================================
// 💰 ÉCRAN DÉTAIL D'UN COMPTE
// ============================================================================
class CompteClientDetailScreen extends ConsumerWidget {
  final String entrepriseId;
  final String compteId;

  const CompteClientDetailScreen({
    super.key,
    required this.entrepriseId,
    required this.compteId,
  });

  DocumentReference<Map<String, dynamic>> get _ref => FirebaseFirestore.instance
      .collection('entreprises')
      .doc(entrepriseId)
      .collection('comptes_clients')
      .doc(compteId);

  static const Map<String, String> _libelles = {
    'depot': 'Dépôt',
    'avoir': 'Avoir (retour)',
    'achat': 'Achat',
    'retrait': 'Retrait',
  };

  Future<void> _envoyerReleve(
    BuildContext context,
    WidgetRef ref, {
    required String nom,
    required double solde,
    required List<Map<String, dynamic>> mouvements,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final boutique = ref.read(entrepriseProvider).nom;
    final buffer = StringBuffer(
        'Bonjour ${nom.isEmpty ? '' : nom}, votre solde chez $boutique est de ${ref.formatPrice(solde)}.');
    if (mouvements.isNotEmpty) {
      buffer.write('\nDerniers mouvements :');
      for (final m in mouvements.take(5)) {
        final d = m['date'];
        final quand = d is Timestamp ? _formatJour(d.toDate()) : '';
        final signe = _num(m['sens']) < 0 ? '-' : '+';
        final type = _libelles[m['type']] ?? '';
        buffer.write('\n• $quand $type $signe${ref.formatPrice(_num(m['montant']))}');
      }
    }
    buffer.write('\nMerci de votre confiance !');

    final uri = Uri.parse(
        'https://wa.me/$compteId?text=${Uri.encodeComponent(buffer.toString())}');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Impossible d'ouvrir WhatsApp.")),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final peutRetirer = ref
            .watch(userProfileProvider)
            .whenOrNull(data: (p) => p.peutRemisesRetraits) ??
        false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compte client'),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _ref.snapshots(),
        builder: (context, snapCompte) {
          final compte = snapCompte.data?.data() ?? const <String, dynamic>{};
          final nom = (compte['nom'] ?? '').toString();
          final tel = (compte['telephone'] ?? compteId).toString();
          final solde = _num(compte['solde']);

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _ref
                .collection('mouvements')
                .orderBy('date', descending: true)
                .limit(100)
                .snapshots(),
            builder: (context, snapMvts) {
              final mouvements =
                  snapMvts.data?.docs.map((d) => d.data()).toList() ??
                      const <Map<String, dynamic>>[];

              return ListView(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
                children: [
                  // En-tête
                  Card(
                    color: Colors.teal.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(nom.isEmpty ? tel : nom,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          if (nom.isNotEmpty)
                            Text(tel, style: TextStyle(color: Colors.grey.shade700)),
                          const SizedBox(height: 10),
                          const Text('Solde disponible'),
                          Text(
                            ref.formatPrice(solde),
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text('Dépôt'),
                          onPressed: () => ouvrirOperationCompte(
                            context,
                            ref,
                            entrepriseId: entrepriseId,
                            type: 'depot',
                            telephone: tel,
                            nom: nom,
                            solde: solde,
                          ),
                        ),
                      ),
                      if (peutRetirer) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red.shade700,
                              side: BorderSide(color: Colors.red.shade300),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.remove),
                            label: const Text('Retrait'),
                            onPressed: solde > 0.005
                                ? () => ouvrirOperationCompte(
                                      context,
                                      ref,
                                      entrepriseId: entrepriseId,
                                      type: 'retrait',
                                      telephone: tel,
                                      nom: nom,
                                      solde: solde,
                                    )
                                : null,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green.shade800,
                      side: BorderSide(color: Colors.green.shade600),
                    ),
                    icon: const Icon(Icons.chat),
                    label: const Text('Envoyer le relevé par WhatsApp'),
                    onPressed: () => _envoyerReleve(
                      context,
                      ref,
                      nom: nom,
                      solde: solde,
                      mouvements: mouvements,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Historique',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  if (mouvements.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Aucun mouvement.', style: TextStyle(color: Colors.grey)),
                    ),
                  for (final m in mouvements) _LigneMouvement(m: m),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _LigneMouvement extends ConsumerWidget {
  final Map<String, dynamic> m;
  const _LigneMouvement({required this.m});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = (m['type'] ?? '').toString();
    final credit = _num(m['sens']) >= 0;
    final d = m['date'];
    final quand = d is Timestamp ? _formatDate(d.toDate()) : '';
    final par = (m['parNom'] ?? '').toString();

    final IconData icone;
    final Color couleur;
    switch (type) {
      case 'depot':
        icone = Icons.savings;
        couleur = Colors.green.shade700;
        break;
      case 'avoir':
        icone = Icons.card_giftcard;
        couleur = Colors.blue.shade700;
        break;
      case 'achat':
        icone = Icons.shopping_bag;
        couleur = Colors.orange.shade800;
        break;
      default:
        icone = Icons.outbox;
        couleur = Colors.red.shade700;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        dense: true,
        leading: Icon(icone, color: couleur),
        title: Text((m['description'] ?? '').toString()),
        subtitle: Text(par.isEmpty ? quand : '$quand • par $par'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${credit ? '+' : '-'}${ref.formatPrice(_num(m['montant']))}',
              style: TextStyle(fontWeight: FontWeight.bold, color: couleur),
            ),
            Text(
              'Solde : ${ref.formatPrice(_num(m['soldeApres']))}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
