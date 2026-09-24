// lib/core/providers/dette_provider.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stockly_saas/core/models/dette.dart';
import 'package:stockly_saas/features/debts/repositories/dette_repository.dart';

/// État immuable de la gestion des dettes et créances
class DetteState {
  final List<Dette> creances;
  final List<Dette> dettesFournisseurs;
  final bool isLoading;
  final String? error;

  const DetteState({
    this.creances = const [],
    this.dettesFournisseurs = const [],
    this.isLoading = false,
    this.error,
  });

  double get totalCreances =>
      creances.fold(0.0, (sum, item) => sum + item.montantReste);

  double get totalDettesFournisseurs =>
      dettesFournisseurs.fold(0.0, (sum, item) => sum + item.montantReste);

  DetteState copyWith({
    List<Dette>? creances,
    List<Dette>? dettesFournisseurs,
    bool? isLoading,
    String? error,
  }) {
    return DetteState(
      creances: creances ?? this.creances,
      dettesFournisseurs: dettesFournisseurs ?? this.dettesFournisseurs,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier Riverpod synchronisé avec DetteRepository
class DetteNotifier extends StateNotifier<DetteState> {
  final DetteRepository _repository;
  final String entrepriseId;
  StreamSubscription? _subscription;

  DetteNotifier(this._repository, this.entrepriseId) : super(const DetteState()) {
    _initDettesStream();
  }

  void _initDettesStream() {
    if (entrepriseId.isEmpty) return;

    state = state.copyWith(isLoading: true);
    _subscription?.cancel();

    _subscription = _repository.getDettesStream(entrepriseId).listen(
      (dettesList) {
        final creances =
            dettesList.where((d) => d.type == TypeDette.client).toList();

        final dettesFournisseurs =
            dettesList.where((d) => d.type == TypeDette.fournisseur).toList();

        state = state.copyWith(
          creances: creances,
          dettesFournisseurs: dettesFournisseurs,
          isLoading: false,
          error: null,
        );
      },
      onError: (err) {
        state = state.copyWith(
          isLoading: false,
          error: err.toString(),
        );
      },
    );
  }

  /// Ajouter une dette/créance
  Future<void> ajouterDette({
    required String nomPartenaire,
    required double montant,
    required bool isClient,
    required String userId,
    String? numeroFacture,
    String? note,
    DateTime? dateEcheance,
  }) async {
    await _repository.ajouterDette(
      entrepriseId: entrepriseId,
      nomPartenaire: nomPartenaire,
      montant: montant,
      isClient: isClient,
      userId: userId,
      numeroFacture: numeroFacture,
      note: note,
      dateEcheance: dateEcheance,
    );
  }

  /// Effectuer un règlement autonome
  Future<void> reglerDetteAutonome({
    required String detteId,
    required String nomPartenaire,
    required double montantRegle,
    required double montantResteActuel,
    required bool isClient,
    required String userId,
    String compteTresorerie = '571000',
  }) async {
    await _repository.reglerDetteAutonome(
      detteId: detteId,
      entrepriseId: entrepriseId,
      nomPartenaire: nomPartenaire,
      montantRegle: montantRegle,
      montantResteActuel: montantResteActuel,
      isClient: isClient,
      userId: userId,
      compteTresorerie: compteTresorerie,
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

// ============================================================================
// PROVIDERS
// ============================================================================

final detteNotifierProvider =
    StateNotifierProvider.family<DetteNotifier, DetteState, String>(
        (ref, entrepriseId) {
  final repository = ref.watch(detteRepositoryProvider);
  return DetteNotifier(repository, entrepriseId);
});