import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models/auth_state.dart';
import '../core/models/user_model.dart';
import '../features/debts/screens/providers/auth_controller.dart';
import '../features/debts/screens/home_screen.dart';
import '../features/debts/screens/login_screen.dart';
import '../features/debts/screens/pin_lock_screen.dart';

/// Passerelle d'authentification sécurisée, multi-tenant et basée sur les rôles (RBAC)
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posAuthState = ref.watch(authControllerProvider);

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text("Erreur d'authentification : ${authSnapshot.error}"),
            ),
          );
        }

        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final firebaseUser = authSnapshot.data;
        if (firebaseUser == null) {
          return const LoginScreen();
        }

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(firebaseUser.uid)
              .snapshots(),
          builder: (context, userSnapshot) {
            if (userSnapshot.hasError) {
              return Scaffold(
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      "Erreur lors du chargement du profil :\n${userSnapshot.error}",
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }

            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final rawData =
                userSnapshot.data?.data() as Map<String, dynamic>? ?? {};

            // Décodage typé via UserModel.fromMap (gestion native des 4 rôles et de l'entrepriseId)
            final currentUser = UserModel.fromMap(
              {
                ...rawData,
                'email': rawData['email'] ?? firebaseUser.email ?? '',
                'nom': rawData['nom'] ??
                    firebaseUser.displayName ??
                    'Utilisateur',
              },
              firebaseUser.uid,
            );

            final String expectedPin = rawData['pinCode']?.toString() ?? '0000';

            return switch (posAuthState) {
              PosUnauthenticated() => PinLockScreen(
                  expectedPin: expectedPin,
                  userRole: currentUser.role.name,
                ),
              PosLocked() => PinLockScreen(
                  expectedPin: expectedPin,
                  userRole: currentUser.role.name,
                ),
              PosUnlocked() => Listener(
                  onPointerDown: (_) {
                    ref
                        .read(authControllerProvider.notifier)
                        .registerUserActivity();
                  },
                  child: HomeScreen(
                    currentUser: currentUser,
                  ),
                ),
            };
          },
        );
      },
    );
  }
}