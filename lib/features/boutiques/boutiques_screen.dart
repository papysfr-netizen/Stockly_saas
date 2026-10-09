// lib/features/boutiques/boutiques_screen.dart
//
// 🏬 MULTI-BOUTIQUES — Étape 1 : créer et gérer les boutiques (Propriétaire).
//
// Données : entreprises/{entrepriseId}/boutiques/{boutiqueId}
//   nom, adresse, telephone, estPrincipale, actif, createdAt, updatedAt
//
// La boutique principale a TOUJOURS l'identifiant « principale ».
// Son stock = stock total actuel − stock des autres boutiques (étapes suivantes).
// Rien n'est changé dans les produits, les ventes ni le stock à cette étape.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BoutiquesService {
  static const String idPrincipale = 'principale';

  static CollectionReference<Map<String, dynamic>> collection(String entrepriseId) =>
      FirebaseFirestore.instance
          .collection('entreprises')
          .doc(entrepriseId)
          .collection('boutiques');

  /// Crée la « Boutique principale » si elle n'existe pas encore (sans rien écraser).
  static Future<void> assurerPrincipale(String entrepriseId) async {
    final ref = collection(entrepriseId).doc(idPrincipale);
    try {
      final doc = await ref.get().timeout(const Duration(seconds: 5));
      if (doc.exists) return;
    } catch (_) {
      // hors ligne : on tente quand même la création ci-dessous (merge = sans danger)
    }
    await ref.set({
      'nom': 'Boutique principale',
      'adresse': '',
      'telephone': '',
      'estPrincipale': true,
      'actif': true,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> ajouter(String entrepriseId,
      {required String nom, String adresse = '', String telephone = ''}) {
    return collection(entrepriseId).add({
      'nom': nom.trim(),
      'adresse': adresse.trim(),
      'telephone': telephone.trim(),
      'estPrincipale': false,
      'actif': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> modifier(String entrepriseId, String id,
      {required String nom, String adresse = '', String telephone = ''}) {
    return collection(entrepriseId).doc(id).update({
      'nom': nom.trim(),
      'adresse': adresse.trim(),
      'telephone': telephone.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> changerActif(String entrepriseId, String id, bool actif) {
    return collection(entrepriseId).doc(id).update({
      'actif': actif,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

// ======================= CARTE DANS LES PARAMÈTRES =======================
class MesBoutiquesCard extends StatelessWidget {
  final String entrepriseId;
  const MesBoutiquesCard({super.key, required this.entrepriseId});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Colors.indigo.shade50,
          child: Icon(Icons.storefront_rounded, color: Colors.indigo.shade700),
        ),
        title: const Text('Mes boutiques', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text('Créer et gérer vos points de vente'),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: entrepriseId.isEmpty
            ? null
            : () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => BoutiquesScreen(entrepriseId: entrepriseId)),
                ),
      ),
    );
  }
}

// ======================= ÉCRAN « MES BOUTIQUES » =======================
class BoutiquesScreen extends StatefulWidget {
  final String entrepriseId;
  const BoutiquesScreen({super.key, required this.entrepriseId});

  @override
  State<BoutiquesScreen> createState() => _BoutiquesScreenState();
}

class _BoutiquesScreenState extends State<BoutiquesScreen> {
  static const Color _bleuNuit = Color(0xFF1E293B);

  @override
  void initState() {
    super.initState();
    BoutiquesService.assurerPrincipale(widget.entrepriseId).catchError((_) {});
  }

  Future<void> _formulaire({String? id, Map<String, dynamic>? data}) async {
    final nomCtrl = TextEditingController(text: data?['nom']?.toString() ?? '');
    final adresseCtrl = TextEditingController(text: data?['adresse']?.toString() ?? '');
    final telCtrl = TextEditingController(text: data?['telephone']?.toString() ?? '');
    final formKey = GlobalKey<FormState>();
    final messenger = ScaffoldMessenger.of(context);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(id == null ? 'Nouvelle boutique' : 'Modifier la boutique'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nomCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nom de la boutique *',
                    hintText: 'Ex : Boutique Birere',
                    prefixIcon: Icon(Icons.storefront_rounded),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().length < 2) ? 'Entrez un nom (2 lettres minimum)' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: adresseCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Adresse (facultatif)',
                    prefixIcon: Icon(Icons.place_outlined),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: telCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Téléphone (facultatif)',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() == true) Navigator.pop(ctx, true);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    if (ok != true) return;
    try {
      if (id == null) {
        await BoutiquesService.ajouter(widget.entrepriseId,
            nom: nomCtrl.text, adresse: adresseCtrl.text, telephone: telCtrl.text);
        messenger.showSnackBar(
          SnackBar(content: Text('Boutique « ${nomCtrl.text.trim()} » créée'), backgroundColor: Colors.green),
        );
      } else {
        await BoutiquesService.modifier(widget.entrepriseId, id,
            nom: nomCtrl.text, adresse: adresseCtrl.text, telephone: telCtrl.text);
        messenger.showSnackBar(
          const SnackBar(content: Text('Boutique modifiée'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _changerActif(String id, String nom, bool actif) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await BoutiquesService.changerActif(widget.entrepriseId, id, actif);
      messenger.showSnackBar(SnackBar(
        content: Text(actif ? '« $nom » réactivée' : '« $nom » désactivée'),
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Mes boutiques', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: _bleuNuit,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _bleuNuit,
        foregroundColor: Colors.white,
        onPressed: () => _formulaire(),
        icon: const Icon(Icons.add_business_rounded),
        label: const Text('Nouvelle boutique'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: BoutiquesService.collection(widget.entrepriseId).snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Impossible de charger les boutiques : ${snap.error}',
                    textAlign: TextAlign.center, style: TextStyle(color: Colors.red.shade700)),
              ),
            );
          }
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snap.data!.docs.toList()
            ..sort((a, b) {
              // La principale d'abord, puis par ordre alphabétique
              final pa = a.id == BoutiquesService.idPrincipale ? 0 : 1;
              final pb = b.id == BoutiquesService.idPrincipale ? 0 : 1;
              if (pa != pb) return pa - pb;
              return (a.data()['nom'] ?? '').toString().toLowerCase()
                  .compareTo((b.data()['nom'] ?? '').toString().toLowerCase());
            });

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, color: Colors.blue.shade700),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Votre stock actuel appartient à la boutique principale. '
                        'Le stock par boutique, les transferts et les prix par boutique '
                        'arriveront dans les prochaines mises à jour.',
                        style: TextStyle(fontSize: 13, color: Colors.blue.shade900),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              for (final d in docs) _carte(d.id, d.data()),
            ],
          );
        },
      ),
    );
  }

  Widget _carte(String id, Map<String, dynamic> data) {
    final nom = (data['nom'] ?? 'Sans nom').toString();
    final adresse = (data['adresse'] ?? '').toString();
    final tel = (data['telephone'] ?? '').toString();
    final principale = id == BoutiquesService.idPrincipale;
    final actif = data['actif'] != false;

    return Opacity(
      opacity: actif ? 1 : 0.55,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: principale ? Colors.indigo.shade200 : Colors.black12),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          leading: CircleAvatar(
            backgroundColor: principale ? Colors.indigo.shade700 : Colors.teal.shade50,
            child: Icon(
              principale ? Icons.star_rounded : Icons.storefront_rounded,
              color: principale ? Colors.white : Colors.teal.shade700,
            ),
          ),
          title: Row(
            children: [
              Flexible(
                child: Text(nom,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: _bleuNuit)),
              ),
              if (principale) ...[
                const SizedBox(width: 8),
                _badge('Principale', Colors.indigo),
              ],
              if (!actif) ...[
                const SizedBox(width: 8),
                _badge('Désactivée', Colors.grey),
              ],
            ],
          ),
          subtitle: Text(
            [if (adresse.isNotEmpty) adresse, if (tel.isNotEmpty) tel].join(' • ').isEmpty
                ? 'Aucune adresse'
                : [if (adresse.isNotEmpty) adresse, if (tel.isNotEmpty) tel].join(' • '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'modifier') _formulaire(id: id, data: data);
              if (v == 'desactiver') _changerActif(id, nom, false);
              if (v == 'activer') _changerActif(id, nom, true);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'modifier', child: Text('Modifier')),
              if (!principale && actif)
                const PopupMenuItem(value: 'desactiver', child: Text('Désactiver')),
              if (!principale && !actif)
                const PopupMenuItem(value: 'activer', child: Text('Réactiver')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(String texte, MaterialColor couleur) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: couleur.shade50,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(texte,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: couleur.shade700)),
    );
  }
}
