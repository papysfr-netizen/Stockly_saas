// lib/features/boutiques/boutique_provider.dart
//
// 🏬 MULTI-BOUTIQUES — Étape 2 : boutique de travail de chaque utilisateur.
//
//  - Un employé travaille dans SA boutique (users/{uid}.boutiqueId ;
//    vide = boutique principale).
//  - Le patron choisit la boutique à afficher (null = toutes les boutiques).

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stockly_saas/core/providers/user_role_provider.dart';
import 'boutiques_screen.dart';

class Boutique {
  final String id;
  final String nom;
  final bool actif;

  const Boutique({required this.id, required this.nom, required this.actif});

  bool get estPrincipale => id == BoutiquesService.idPrincipale;

  factory Boutique.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Boutique(
      id: doc.id,
      nom: (d['nom'] ?? 'Sans nom').toString(),
      actif: d['actif'] != false,
    );
  }
}

/// Toutes les boutiques de l'entreprise (principale d'abord, puis par nom).
final boutiquesProvider =
    StreamProvider.family<List<Boutique>, String>((ref, entrepriseId) {
  if (entrepriseId.isEmpty) return Stream.value(const <Boutique>[]);
  return BoutiquesService.collection(entrepriseId).snapshots().map((s) {
    final liste = s.docs.map(Boutique.fromDoc).toList()
      ..sort((a, b) {
        if (a.estPrincipale != b.estPrincipale) return a.estPrincipale ? -1 : 1;
        return a.nom.toLowerCase().compareTo(b.nom.toLowerCase());
      });
    return liste;
  });
});

/// Boutiques actives seulement.
final boutiquesActivesProvider = Provider.family<List<Boutique>, String>((ref, entrepriseId) {
  return ref.watch(boutiquesProvider(entrepriseId)).value?.where((b) => b.actif).toList() ??
      const [];
});

/// Choix du PATRON dans le sélecteur (null = toutes les boutiques).
final boutiqueChoisieProvider = StateProvider<String?>((ref) => null);

/// Boutique de travail effective :
///  - patron : son choix (null = toutes) ;
///  - employé : sa boutique (principale si aucune).
final boutiqueActiveProvider = Provider<String?>((ref) {
  final p = ref.watch(userProfileProvider).value;
  if (p == null || p.uid.isEmpty) return BoutiquesService.idPrincipale;
  // Le patron, ou un employé autorisé « Toutes les boutiques », choisit librement
  if (p.role.isOwner || p.peutToutesBoutiques) return ref.watch(boutiqueChoisieProvider);
  return p.boutiqueId.isEmpty ? BoutiquesService.idPrincipale : p.boutiqueId;
});

// ======================= ÉCRAN ÉQUIPE : CHOIX DE LA BOUTIQUE =======================
/// Menu « Boutique : … » sur la carte d'un employé (visible dès 2 boutiques actives).
class ChoixBoutiqueMembre extends ConsumerWidget {
  final String entrepriseId;
  final String uid;
  final String boutiqueId;
  final String nomMembre;

  const ChoixBoutiqueMembre({
    super.key,
    required this.entrepriseId,
    required this.uid,
    required this.boutiqueId,
    required this.nomMembre,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toutes = ref.watch(boutiquesProvider(entrepriseId)).value ?? const <Boutique>[];
    final valeur = boutiqueId.isEmpty ? BoutiquesService.idPrincipale : boutiqueId;
    final choix = toutes.where((b) => b.actif || b.id == valeur).toList();
    if (choix.where((b) => b.actif).length < 2) {
      return const SizedBox.shrink(); // une seule boutique : rien à choisir
    }
    final existe = choix.any((b) => b.id == valeur);

    return Row(
      children: [
        Icon(Icons.storefront_rounded, size: 20, color: Colors.indigo.shade400),
        const SizedBox(width: 8),
        const Text('Boutique :'),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButton<String>(
            isExpanded: true,
            value: existe ? valeur : null,
            hint: const Text('Choisir…'),
            items: [
              for (final b in choix)
                DropdownMenuItem(
                  value: b.id,
                  child: Text(
                    b.actif ? b.nom : '${b.nom} (désactivée)',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (id) async {
              if (id == null || id == valeur) return;
              final messenger = ScaffoldMessenger.of(context);
              final nomBoutique = choix.firstWhere((b) => b.id == id).nom;
              try {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .update({'boutiqueId': id});
                messenger.showSnackBar(SnackBar(
                  content: Text('$nomMembre travaille maintenant à « $nomBoutique »'),
                  backgroundColor: Colors.green,
                ));
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
                );
              }
            },
          ),
        ),
      ],
    );
  }
}

// ======================= SÉLECTEUR DU PATRON =======================
/// Petit bouton « 🏬 Toutes les boutiques ▾ » (patron seulement, dès 2 boutiques actives).
class SelecteurBoutique extends ConsumerWidget {
  final String entrepriseId;
  final Color couleurTexte;

  const SelecteurBoutique({
    super.key,
    required this.entrepriseId,
    this.couleurTexte = Colors.white,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profil = ref.watch(userProfileProvider).value;
    final actives = ref.watch(boutiquesActivesProvider(entrepriseId));
    if (profil == null ||
        !(profil.role.isOwner || profil.peutToutesBoutiques) ||
        actives.length < 2) {
      return const SizedBox.shrink();
    }

    final choisie = ref.watch(boutiqueChoisieProvider);
    final nom = choisie == null
        ? 'Toutes les boutiques'
        : actives.firstWhere(
            (b) => b.id == choisie,
            orElse: () => const Boutique(id: '', nom: 'Toutes les boutiques', actif: true),
          ).nom;

    return PopupMenuButton<String>(
      tooltip: 'Choisir la boutique',
      onSelected: (v) =>
          ref.read(boutiqueChoisieProvider.notifier).state = v == '*' ? null : v,
      itemBuilder: (_) => [
        CheckedPopupMenuItem(
          value: '*',
          checked: choisie == null,
          child: const Text('Toutes les boutiques'),
        ),
        const PopupMenuDivider(),
        for (final b in actives)
          CheckedPopupMenuItem(
            value: b.id,
            checked: choisie == b.id,
            child: Text(b.nom),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: couleurTexte.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.storefront_rounded, size: 15, color: couleurTexte),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 170),
              child: Text(
                nom,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: couleurTexte, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
            Icon(Icons.arrow_drop_down_rounded, size: 18, color: couleurTexte),
          ],
        ),
      ),
    );
  }
}

/// 🏬 Boutique où se fait une vente : employé = sa boutique ;
/// patron = boutique choisie (« Toutes les boutiques » = boutique principale).
extension BoutiqueVenteRef on WidgetRef {
  String get boutiqueVente => read(boutiqueActiveProvider) ?? BoutiquesService.idPrincipale;
}
