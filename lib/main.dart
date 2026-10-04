import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'core/models/auth_state.dart';
import 'core/models/user_model.dart';
import 'features/debts/screens/providers/auth_controller.dart';
import 'core/providers/locale_provider.dart';
import 'features/debts/screens/home_screen.dart';
import 'features/debts/screens/login_screen.dart';
import 'features/debts/screens/pin_lock_screen.dart';
import 'core/widgets/app_initializer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Configuration avancée de la persistance Firestore Hors-Ligne
    if (!kIsWeb) {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    }
  } catch (e) {
    debugPrint("Erreur d'initialisation Firebase : $e");
  }

  runApp(const RacineApp());
}

// ============================================================================
// 🔄 RACINE : MÉMOIRE NEUVE À CHAQUE CHANGEMENT DE COMPTE
// Quand le compte connecté change (déconnexion, autre employé…),
// le ProviderScope reçoit une nouvelle clé : toute la mémoire de l'app
// (dettes, stock, équipe…) est recréée à neuf pour le nouveau compte.
// Plus de « permission-denied » hérité du compte précédent.
// ============================================================================
class RacineApp extends StatelessWidget {
  const RacineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      initialData: FirebaseAuth.instance.currentUser,
      builder: (context, snapshot) {
        final uid = snapshot.data?.uid ?? 'deconnecte';
        return ProviderScope(
          key: ValueKey('scope_$uid'),
          child: const AppInitializer(
            child: MyApp(),
          ),
        );
      },
    );
  }
}

// ============================================================================
// DÉLÉGUÉS DE SECOURS (FALLBACK) POUR LES LANGUES NON SUPPORTÉES PAR FLUTTER
// (ex : lingala). Ils ne servent QUE si Flutter ne connaît pas la langue ;
// sinon les délégués officiels (placés avant dans la liste) sont utilisés.
// ============================================================================
class FallbackMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const FallbackMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) async {
    return await GlobalMaterialLocalizations.delegate.load(const Locale('fr'));
  }

  @override
  bool shouldReload(FallbackMaterialLocalizationsDelegate old) => false;
}

class FallbackCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const FallbackCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<CupertinoLocalizations> load(Locale locale) async {
    return await GlobalCupertinoLocalizations.delegate.load(const Locale('fr'));
  }

  @override
  bool shouldReload(FallbackCupertinoLocalizationsDelegate old) => false;
}

class FallbackWidgetsLocalizationsDelegate
    extends LocalizationsDelegate<WidgetsLocalizations> {
  const FallbackWidgetsLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<WidgetsLocalizations> load(Locale locale) async {
    return await GlobalWidgetsLocalizations.delegate.load(const Locale('fr'));
  }

  @override
  bool shouldReload(FallbackWidgetsLocalizationsDelegate old) => false;
}

// ============================================================================
// APPLICATION PRINCIPALE (STYLE FINTECH & MATERIAL 3)
// ============================================================================
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);

    return MaterialApp(
      title: 'Stockly SaaS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0052FF),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 0.8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF0052FF), width: 1.5),
          ),
        ),
      ),
      locale: currentLocale,
      supportedLocales: LocaleNotifier.supportedLanguages
          .map((lang) => Locale(lang.code))
          .toList(),
      localizationsDelegates: const [
        // Nos traductions (fichiers lib/l10n/*.arb)
        AppLocalizations.delegate,
        // Traductions officielles de Flutter (boutons, calendriers...)
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        // Secours pour les langues que Flutter ne connaît pas (lingala)
        FallbackMaterialLocalizationsDelegate(),
        FallbackWidgetsLocalizationsDelegate(),
        FallbackCupertinoLocalizationsDelegate(),
      ],
      home: const AuthWrapper(),
    );
  }
}

// ============================================================================
// PASSERELLE D'AUTHENTIFICATION OPTIMISÉE POUR LE MODE HORS-LIGNE
// ============================================================================
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posAuthState = ref.watch(authControllerProvider);

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text("Erreur d'authentification : ${snapshot.error}"),
            ),
          );
        }

        // En mode hors-ligne, FirebaseAuth conserve le dernier utilisateur dans le cache local.
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const LoginScreen();
        }

        final firebaseUser = snapshot.data!;

        return StreamBuilder<DocumentSnapshot>(
          // includeMetadataChanges: true force l'émission immédiate des données du cache SQLite local
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(firebaseUser.uid)
              .snapshots(includeMetadataChanges: true),
          builder: (context, userSnapshot) {
            // Priorité absolue aux données disponibles (Cache ou Réseau)
            if (userSnapshot.hasData && userSnapshot.data != null) {
              final doc = userSnapshot.data!;
              final rawData = doc.data() as Map<String, dynamic>? ?? {};

              // ⛔ Compte désactivé par le propriétaire (même en cours d'utilisation)
              if (rawData['estActif'] == false) {
                return const _CompteDesactiveScreen();
              }

              // Décodage du modèle utilisateur
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
            }

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

            // Chargement uniquement si aucune donnée locale n'est encore disponible
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          },
        );
      },
    );
  }
}

// ============================================================================
// ⛔ ÉCRAN « COMPTE DÉSACTIVÉ »
// ============================================================================
class _CompteDesactiveScreen extends StatelessWidget {
  const _CompteDesactiveScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.block, size: 72, color: Colors.red.shade400),
              const SizedBox(height: 16),
              const Text(
                'Compte désactivé',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                "Le propriétaire de la boutique a désactivé ce compte.\n"
                "Contactez-le pour le réactiver.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => FirebaseAuth.instance.signOut(),
                icon: const Icon(Icons.logout),
                label: const Text('Retour à la connexion'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}