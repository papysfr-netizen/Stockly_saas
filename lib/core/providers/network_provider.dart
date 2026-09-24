import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// État de la connectivité réseau de l'application
enum NetworkStatus {
  online,
  offline;

  bool get isOnline => this == NetworkStatus.online;
  bool get isOffline => this == NetworkStatus.offline;
}

/// Provider pour injecter l'instance Connectivity (facilite les tests unitaires)
final connectivityProvider = Provider<Connectivity>((ref) {
  return Connectivity();
});

/// StreamProvider réactif suivant l'état de la connexion en temps réel
final networkStatusProvider = StreamProvider<NetworkStatus>((ref) async* {
  final connectivity = ref.watch(connectivityProvider);

  // 1. Vérification et émission immédiate du statut au lancement
  final initialResults = await connectivity.checkConnectivity();
  yield _mapResultsToStatus(initialResults);

  // 2. Écoute en continu des changements de statut (compatible connectivity_plus 6.x+)
  await for (final results in connectivity.onConnectivityChanged) {
    yield _mapResultsToStatus(results);
  }
});

/// Helper pour convertir la liste de résultats en état unique
NetworkStatus _mapResultsToStatus(List<ConnectivityResult> results) {
  if (results.isEmpty || results.contains(ConnectivityResult.none)) {
    return NetworkStatus.offline;
  }
  return NetworkStatus.online;
}