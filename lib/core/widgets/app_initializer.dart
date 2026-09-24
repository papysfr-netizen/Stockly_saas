import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stockly_saas/core/providers/currency_provider.dart';
import 'package:stockly_saas/core/services/currency_service.dart';

/// Widget wrapper chargé d'initialiser les services globaux au démarrage de l'application
class AppInitializer extends ConsumerWidget {
  final Widget child;

  const AppInitializer({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Écoute des taux distants via le service API et mise à jour du state
    ref.listen<AsyncValue<Map<String, double>>>(
      exchangeRatesProvider,
      (previous, next) {
        next.whenData((rates) {
          ref.read(currencyProvider.notifier).batchUpdateRates(rates);
        });
      },
    );

    return child;
  }
}