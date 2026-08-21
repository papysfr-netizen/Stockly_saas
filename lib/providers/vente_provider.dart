import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/vente_repository.dart';
import '../models/vente.dart';
import 'produit_provider.dart';

/// Provider d'injection du Repository (Immuable)
final venteRepositoryProvider = Provider<VenteRepository>((ref) {
  return VenteRepository();
});

/// Flux réactif des ventes multi-tenant (Offline-First)
final ventesStreamProvider = StreamProvider<List<Vente>>((ref) async* {
  // 1. Observation propre de l'organisation courante
  final entrepriseId = await ref.watch(entrepriseIdProvider.future);

  if (entrepriseId == null || entrepriseId.isEmpty) {
    yield [];
    return;
  }

  // 2. Émission du flux Firestore avec gestion du cache local
  final repository = ref.watch(venteRepositoryProvider);
  yield* repository.getVentes(entrepriseId);
});

/// Flux réactif des dettes / créances clients
final dettesStreamProvider = StreamProvider<List<Vente>>((ref) async* {
  final entrepriseId = await ref.watch(entrepriseIdProvider.future);

  if (entrepriseId == null || entrepriseId.isEmpty) {
    yield [];
    return;
  }

  final repository = ref.watch(venteRepositoryProvider);
  yield* repository.getDettes(entrepriseId);
});