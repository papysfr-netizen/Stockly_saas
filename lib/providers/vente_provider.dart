// lib/providers/vente_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/payment_method.dart';
import '../models/vente.dart';
import '../repositories/vente_repository.dart';
import 'cart_provider.dart';
import 'produit_provider.dart';

/// Injection du Repository (Immuable)
final venteRepositoryProvider = Provider<VenteRepository>((ref) {
  return VenteRepository();
});

/// Flux réactif des ventes multi-tenant
final ventesStreamProvider = StreamProvider<List<Vente>>((ref) {
  final entrepriseId = ref.watch(entrepriseIdProvider).valueOrNull;

  if (entrepriseId == null || entrepriseId.isEmpty) {
    return Stream.value([]);
  }

  final repository = ref.watch(venteRepositoryProvider);
  return repository.getVentes(entrepriseId);
});

/// Flux réactif des dettes / créances clients
final dettesStreamProvider = StreamProvider<List<Vente>>((ref) {
  final entrepriseId = ref.watch(entrepriseIdProvider).valueOrNull;

  if (entrepriseId == null || entrepriseId.isEmpty) {
    return Stream.value([]);
  }

  final repository = ref.watch(venteRepositoryProvider);
  return repository.getDettes(entrepriseId);
});

/// Controller d'action pour l'enregistrement et le règlement des ventes
final venteControllerProvider =
    AsyncNotifierProvider<VenteController, void>(VenteController.new);

class VenteController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Enregistre une transaction de vente avec décrémentation de stock et écriture comptable
  Future<void> enregistrerVente({
    required Vente vente,
    required List<CartItem> cartItems,
    required String entrepriseId,
    required String userId,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(venteRepositoryProvider);
      await repository.enregistrerVente(
        vente: vente,
        cartItems: cartItems,
        entrepriseId: entrepriseId,
        userId: userId,
      );
    });
  }

  /// Traite le règlement partiel ou total d'une créance client
  Future<void> reglerDette({
    required String entrepriseId,
    required String venteId,
    required double montantAcompte,
    required String userId,
    PaymentMethod paymentMethod = PaymentMethod.cash,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(venteRepositoryProvider);
      await repository.reglerDette(
        entrepriseId: entrepriseId,
        venteId: venteId,
        montantAcompte: montantAcompte,
        userId: userId,
        paymentMethod: paymentMethod,
      );
    });
  }
}