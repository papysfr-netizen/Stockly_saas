import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/user_role_provider.dart';

// ============================================================================
// 1. PROVIDERS & STREAMS (ISOLATION MULTI-TENANT)
// ============================================================================

/// Flux temps réel des membres d'équipe sous /organizations/{entrepriseId}/users
final orgTeamMembersStreamProvider =
    StreamProvider.family<List<QueryDocumentSnapshot>, String>((ref, entrepriseId) {
  if (entrepriseId.isEmpty) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('organizations')
      .doc(entrepriseId)
      .collection('users')
      .snapshots()
      .map((snapshot) => snapshot.docs);
});

/// Controller gérant les opérations sur les membres et leurs permissions
final teamManagementControllerProvider =
    AsyncNotifierProvider.family<TeamManagementController, void, String>(
  TeamManagementController.new,
);

class TeamManagementController extends FamilyAsyncNotifier<void, String> {
  @override
  Future<void> build(String arg) async {}

  /// Mise à jour d'une permission spécifique pour un collaborateur
  Future<void> updatePermission({
    required String userId,
    required String keyName,
    required bool newValue,
  }) async {
    final entrepriseId = arg;
    if (entrepriseId.isEmpty || userId.isEmpty) return;

    state = const AsyncValue.loading();
    try {
      await FirebaseFirestore.instance
          .collection('organizations')
          .doc(entrepriseId)
          .collection('users')
          .doc(userId)
          .update({
        'permissions.$keyName': newValue,
      });

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Ajout d'un nouveau membre dans la sous-collection de l'organisation
  Future<void> addTeamMember({
    required String nom,
    required String email,
    required String role,
  }) async {
    final entrepriseId = arg;
    if (entrepriseId.isEmpty) return;

    state = const AsyncValue.loading();
    try {
      final docRef = FirebaseFirestore.instance
          .collection('organizations')
          .doc(entrepriseId)
          .collection('users')
          .doc();

      await docRef.set({
        'uid': docRef.id,
        'nom': nom.trim(),
        'email': email.trim(),
        'entrepriseId': entrepriseId,
        'role': role,
        'permissions': {
          'canAddProduct': false,
          'canDeleteStock': false,
          'canViewReports': false,
          'canGiveDiscount': true,
        },
        'createdAt': FieldValue.serverTimestamp(),
      });

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}

// ============================================================================
// 2. ÉCRAN DE GESTION DE L'ÉQUIPE (PRESENTATION LAYER)
// ============================================================================

class GestionEquipeScreen extends ConsumerWidget {
  const GestionEquipeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return profileAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Gestion de l\'Équipe')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(title: const Text('Gestion de l\'Équipe')),
        body: Center(child: Text('Erreur : $err')),
      ),
      data: (profile) {
        final entrepriseId = profile.entrepriseId;
        final teamMembersAsync = ref.watch(orgTeamMembersStreamProvider(entrepriseId));
        final controllerState = ref.watch(teamManagementControllerProvider(entrepriseId));

        return Scaffold(
          appBar: AppBar(
            title: const Text('Gestion de l\'Équipe'),
          ),
          body: Stack(
            children: [
              if (!profile.role.isOwner)
                const Center(
                  child: Text(
                    'Accès réservé exclusivement au propriétaire de l\'entreprise.',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              else
                teamMembersAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Erreur : $err')),
                  data: (docs) {
                    if (docs.isEmpty) {
                      return const Center(child: Text('Aucun membre dans l\'équipe.'));
                    }

                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        final docId = docs[index].id;

                        final String nom = data['nom'] ?? 'Sans nom';
                        final String email = data['email'] ?? '';
                        final String role = data['role'] ?? 'caissier';
                        final Map<String, dynamic> permissions =
                            data['permissions'] as Map<String, dynamic>? ?? {};

                        final bool isOwnerItem = role == 'owner';

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: ExpansionTile(
                            leading: CircleAvatar(
                              backgroundColor: isOwnerItem ? Colors.amber : Colors.blue,
                              child: Text(
                                nom.isNotEmpty ? nom[0].toUpperCase() : '?',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(nom, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('$email • Rôle : ${role.toUpperCase()}'),
                            children: isOwnerItem
                                ? [
                                    const Padding(
                                      padding: EdgeInsets.all(12.0),
                                      child: Text(
                                        'Le propriétaire dispose de tous les droits d\'accès par défaut.',
                                        style: TextStyle(
                                          fontStyle: FontStyle.italic,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    )
                                  ]
                                : [
                                    const Divider(height: 1),
                                    _buildPermissionSwitch(
                                      ref: ref,
                                      entrepriseId: entrepriseId,
                                      docId: docId,
                                      label: 'Ajouter / Modifier des produits en stock',
                                      keyName: 'canAddProduct',
                                      currentValue: permissions['canAddProduct'] ?? false,
                                    ),
                                    _buildPermissionSwitch(
                                      ref: ref,
                                      entrepriseId: entrepriseId,
                                      docId: docId,
                                      label: 'Supprimer / Réinitialiser le stock',
                                      keyName: 'canDeleteStock',
                                      currentValue: permissions['canDeleteStock'] ?? false,
                                    ),
                                    _buildPermissionSwitch(
                                      ref: ref,
                                      entrepriseId: entrepriseId,
                                      docId: docId,
                                      label: 'Consulter les rapports financiers & bénéfices',
                                      keyName: 'canViewReports',
                                      currentValue: permissions['canViewReports'] ?? false,
                                    ),
                                    _buildPermissionSwitch(
                                      ref: ref,
                                      entrepriseId: entrepriseId,
                                      docId: docId,
                                      label: 'Accorder des remises en caisse',
                                      keyName: 'canGiveDiscount',
                                      currentValue: permissions['canGiveDiscount'] ?? false,
                                    ),
                                  ],
                          ),
                        );
                      },
                    );
                  },
                ),
              if (controllerState.isLoading)
                Container(
                  color: Colors.black26,
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
          floatingActionButton: profile.role.isOwner
              ? FloatingActionButton.extended(
                  icon: const Icon(Icons.person_add),
                  label: const Text('Nouveau Membre'),
                  onPressed: () => _afficherDialogAjoutMembre(context, ref, entrepriseId),
                )
              : null,
        );
      },
    );
  }

  Widget _buildPermissionSwitch({
    required WidgetRef ref,
    required String entrepriseId,
    required String docId,
    required String label,
    required String keyName,
    required bool currentValue,
  }) {
    return SwitchListTile(
      title: Text(label, style: const TextStyle(fontSize: 14)),
      value: currentValue,
      onChanged: (newValue) async {
        await ref
            .read(teamManagementControllerProvider(entrepriseId).notifier)
            .updatePermission(
              userId: docId,
              keyName: keyName,
              newValue: newValue,
            );
      },
    );
  }

  void _afficherDialogAjoutMembre(BuildContext context, WidgetRef ref, String entrepriseId) {
    final nomController = TextEditingController();
    final emailController = TextEditingController();
    String roleSelectionne = 'caissier';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Créer un accès employé'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nomController,
                      decoration: const InputDecoration(labelText: 'Nom complet'),
                    ),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: 'Email de connexion'),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: roleSelectionne,
                      decoration: const InputDecoration(labelText: 'Rôle'),
                      items: const [
                        DropdownMenuItem(value: 'caissier', child: Text('Caissier / Vendeur')),
                        DropdownMenuItem(value: 'admin', child: Text('Administrateur')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => roleSelectionne = val);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (emailController.text.trim().isNotEmpty &&
                        nomController.text.trim().isNotEmpty) {
                      await ref
                          .read(teamManagementControllerProvider(entrepriseId).notifier)
                          .addTeamMember(
                            nom: nomController.text,
                            email: emailController.text,
                            role: roleSelectionne,
                          );

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Collaborateur enregistré !')),
                        );
                      }
                    }
                  },
                  child: const Text('Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}