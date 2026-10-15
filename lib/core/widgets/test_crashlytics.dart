import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stockly_saas/core/providers/user_role_provider.dart';
import 'package:stockly_saas/l10n/app_localizations.dart';

/// 🐞 Bouton du patron : envoie un faux rapport d'erreur à Crashlytics
/// pour vérifier que les rapports arrivent bien dans la console Firebase.
class TestCrashlyticsBouton extends ConsumerWidget {
  const TestCrashlyticsBouton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profil = ref.watch(userProfileProvider).value;
    if (profil == null || !profil.role.isOwner) return const SizedBox.shrink();
    final t = AppLocalizations.of(context);

    return Center(
      child: TextButton.icon(
        icon: const Icon(Icons.bug_report_outlined, size: 18),
        label: Text(t.crashTest),
        onPressed: () async {
          final messenger = ScaffoldMessenger.of(context);
          if (kDebugMode) {
            messenger.showSnackBar(SnackBar(
              content: Text(t.crashDebugOnly),
            ));
            return;
          }
          await FirebaseCrashlytics.instance.recordError(
            Exception('Rapport de test Stockly Pro'),
            StackTrace.current,
            reason: 'Bouton de test (Paramètres)',
          );
          await FirebaseCrashlytics.instance.sendUnsentReports();
          messenger.showSnackBar(SnackBar(
            content: Text(t.crashSent),
            backgroundColor: Colors.green,
          ));
        },
      ),
    );
  }
}
