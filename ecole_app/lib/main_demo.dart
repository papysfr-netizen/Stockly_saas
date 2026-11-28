import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/theme.dart';
import 'data/auth_repository.dart';
import 'data/rappel_repository.dart';
import 'data/school_repository.dart';
import 'demo/donnees_demo.dart';
import 'models/app_user.dart';
import 'providers/apparence.dart';
import 'providers/providers.dart';
import 'screens/home_shell.dart';
import 'services/rappels.dart';

/// Version de démonstration : l'application réelle, sans Firebase, avec une
/// école fictive en mémoire. Lancer : flutter run -t lib/main_demo.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Arbre d'accessibilité toujours actif : lecteurs d'écran et tests automatisés.
  SemanticsBinding.instance.ensureSemantics();
  await initializeDateFormatting('fr_FR');
  final db = FakeFirebaseFirestore();
  await remplirEcoleDemo(db);
  runApp(ProviderScope(
    overrides: [
      schoolRepoProvider.overrideWithValue(SchoolRepository(db, ecoleDemo)),
      meProvider.overrideWith((ref) => ref.watch(roleDemoProvider) ?? utilisateursDemo[Role.admin]!),
      authRepoProvider.overrideWith((ref) => _AuthDemo(ref)),
      rappelRepoProvider.overrideWithValue(_RappelsDemo()),
    ],
    child: const _AppDemo(),
  ));
}

final roleDemoProvider = StateProvider<AppUser?>((ref) => null);

class _AppDemo extends ConsumerWidget {
  const _AppDemo();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(roleDemoProvider);
    return MaterialApp(
      title: 'Gestion École — démo',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: ref.watch(apparenceProvider),
      locale: const Locale('fr', 'FR'),
      supportedLocales: const [Locale('fr', 'FR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => Column(children: [
        Material(
          color: context.etat.bandeau,
          textStyle: TextStyle(color: context.etat.surBandeau),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(children: [
                Icon(Icons.science_outlined, size: 18, color: context.etat.surBandeau),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    user == null ? 'Démonstration — données fictives' : 'Démo · ${user.role.label}',
                    style: TextStyle(fontSize: 13, color: context.etat.surBandeau),
                  ),
                ),
                if (user != null)
                  TextButton(
                    onPressed: () => ref.read(roleDemoProvider.notifier).state = null,
                    child: const Text('Changer de rôle'),
                  ),
              ]),
            ),
          ),
        ),
        Expanded(child: child!),
      ]),
      home: user == null ? const _ChoixRole() : HomeShell(key: ValueKey(user.uid)),
    );
  }
}

class _ChoixRole extends ConsumerWidget {
  const _ChoixRole();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const roles = [
      (Role.admin, Icons.account_balance_outlined, 'Tout voir : tableau de bord, élèves, frais, notes, emplois du temps, remplacements, paramètres.'),
      (Role.secretariat, Icons.point_of_sale_outlined, 'Inscriptions, encaissements, reçus, impayés et rappels, absences des enseignants.'),
      (Role.enseignant, Icons.co_present_outlined, 'Marie KASONGO, titulaire de la 5e année A : saisie des notes, appel, son emploi du temps.'),
      (Role.parent, Icons.family_restroom, 'M. Mbuyi, parent de deux élèves : notes, absences, paiements, emploi du temps.'),
    ];
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Icon(Icons.school, size: 56, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
              Text('Complexe scolaire La Référence',
                  textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              const Text("Choisissez un rôle pour découvrir l'application.", textAlign: TextAlign.center),
              const SizedBox(height: 20),
              for (final (role, icone, texte) in roles)
                Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Icon(icone, size: 32),
                    title: Text(role.label, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(texte),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => ref.read(roleDemoProvider.notifier).state = utilisateursDemo[role],
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                'Rien n\'est enregistré ni envoyé : les modifications disparaissent en rechargeant la page.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Déconnexion = retour au choix du rôle.
class _AuthDemo implements AuthRepository {
  _AuthDemo(this.ref);
  final Ref ref;
  @override
  Future<void> deconnexion() async => ref.read(roleDemoProvider.notifier).state = null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Aucun SMS n'est envoyé en démonstration.
class _RappelsDemo implements RappelRepository {
  @override
  Future<ResultatRappels> envoyer({required String ecoleId, required CanalRappel canal, List<String>? eleveIds}) async =>
      ResultatRappels(0, eleveIds?.length ?? 0, 0, 0, ["Démonstration : aucun ${canal.label} n'a été envoyé (${eleveIds?.length ?? 0} parent(s) auraient été relancés)."]);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
