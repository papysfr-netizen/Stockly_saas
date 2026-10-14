import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'user_role_provider.dart';
import 'package:stockly_saas/features/boutiques/boutique_provider.dart';

// ============================================================================
// MODÈLES DE DONNÉES
// ============================================================================

/// Entrée immuable pour le journal d'audit des variations de taux
@immutable
class RateChangeLog {
  final String currencyCode;
  final double oldRate;
  final double newRate;
  final DateTime timestamp;
  final String modifiedBy;

  const RateChangeLog({
    required this.currencyCode,
    required this.oldRate,
    required this.newRate,
    required this.timestamp,
    this.modifiedBy = 'Caissier',
  });

  Map<String, dynamic> toMap() {
    return {
      'currencyCode': currencyCode,
      'oldRate': oldRate,
      'newRate': newRate,
      'timestamp': timestamp.toIso8601String(),
      'modifiedBy': modifiedBy,
    };
  }

  factory RateChangeLog.fromMap(Map<String, dynamic> map) {
    return RateChangeLog(
      currencyCode: map['currencyCode']?.toString() ?? 'CDF',
      oldRate: (map['oldRate'] as num?)?.toDouble() ?? 0.0,
      newRate: (map['newRate'] as num?)?.toDouble() ?? 0.0,
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'].toString())
          : DateTime.now(),
      modifiedBy: map['modifiedBy']?.toString() ?? 'Caissier',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RateChangeLog &&
          runtimeType == other.runtimeType &&
          currencyCode == other.currencyCode &&
          oldRate == other.oldRate &&
          newRate == other.newRate &&
          timestamp == other.timestamp &&
          modifiedBy == other.modifiedBy;

  @override
  int get hashCode => Object.hash(
        currencyCode,
        oldRate,
        newRate,
        timestamp,
        modifiedBy,
      );
}

/// Information immuable sur une devise
@immutable
class CurrencyInfo {
  final String code;
  final String symbol;
  final String name;
  final double rateToUSD;
  final int decimalDigits;

  const CurrencyInfo({
    required this.code,
    required this.symbol,
    required this.name,
    required this.rateToUSD,
    this.decimalDigits = 2,
  });

  CurrencyInfo copyWith({
    String? code,
    String? symbol,
    String? name,
    double? rateToUSD,
    int? decimalDigits,
  }) {
    return CurrencyInfo(
      code: code ?? this.code,
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      rateToUSD: rateToUSD ?? this.rateToUSD,
      decimalDigits: decimalDigits ?? this.decimalDigits,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CurrencyInfo &&
          runtimeType == other.runtimeType &&
          code == other.code &&
          symbol == other.symbol &&
          name == other.name &&
          rateToUSD == other.rateToUSD &&
          decimalDigits == other.decimalDigits;

  @override
  int get hashCode =>
      Object.hash(code, symbol, name, rateToUSD, decimalDigits);

  @override
  String toString() => '$code ($symbol) @ $rateToUSD';
}

/// État immuable de la gestion des devises
@immutable
class CurrencyState {
  final String activeCurrency;
  final double bccCdfRate;
  final Map<String, CurrencyInfo> currencies;

  const CurrencyState({
    required this.activeCurrency,
    required this.bccCdfRate,
    required this.currencies,
  });

  /// Récupère les métadonnées de la devise active (fallback USD si introuvable)
  CurrencyInfo get activeCurrencyInfo =>
      currencies[activeCurrency] ??
      currencies['USD'] ??
      const CurrencyInfo(
        code: 'USD',
        symbol: '\$',
        name: 'Dollar Américain',
        rateToUSD: 1.0,
      );

  /// Convertit un montant de base USD vers la devise active
  double convertFromUSD(double amountInUSD) {
    return amountInUSD * activeCurrencyInfo.rateToUSD;
  }

  /// Formate un montant de base USD selon les conventions de la devise active
  String formatPrice(double amountInUSD) {
    final info = activeCurrencyInfo;
    final double converted = convertFromUSD(amountInUSD);

    return '${converted.toStringAsFixed(info.decimalDigits)} ${info.symbol}';
  }

  CurrencyState copyWith({
    String? activeCurrency,
    double? bccCdfRate,
    Map<String, CurrencyInfo>? currencies,
  }) {
    return CurrencyState(
      activeCurrency: activeCurrency ?? this.activeCurrency,
      bccCdfRate: bccCdfRate ?? this.bccCdfRate,
      currencies: currencies ?? this.currencies,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CurrencyState &&
          runtimeType == other.runtimeType &&
          activeCurrency == other.activeCurrency &&
          bccCdfRate == other.bccCdfRate &&
          mapEquals(currencies, other.currencies);

  @override
  int get hashCode => Object.hash(
        activeCurrency,
        bccCdfRate,
        Object.hashAll(currencies.entries),
      );
}

// ============================================================================
// NOTIFIERS & CONTROLLERS
// ============================================================================

/// Controller pour l'historique d'audit des taux de change
class ExchangeRateHistoryNotifier extends Notifier<List<RateChangeLog>> {
  static const String _prefLogsKey = 'exchange_rate_logs_v1';

  @override
  List<RateChangeLog> build() {
    _loadLogs();
    return const [];
  }

  Future<void> _loadLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_prefLogsKey);
      if (data != null && data.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(data);
        state = decoded.map((e) => RateChangeLog.fromMap(e)).toList();
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des logs de taux : $e');
    }
  }

  /// Enregistre une modification de taux dans l'historique avec persistance
  Future<void> logRateChange({
    required String currencyCode,
    required double oldRate,
    required double newRate,
    String modifiedBy = 'Caissier',
  }) async {
    if (oldRate == newRate) return;

    final log = RateChangeLog(
      currencyCode: currencyCode,
      oldRate: oldRate,
      newRate: newRate,
      timestamp: DateTime.now(),
      modifiedBy: modifiedBy,
    );

    state = [log, ...state]; // Place l'entrée la plus récente en premier

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefLogsKey,
        jsonEncode(state.map((e) => e.toMap()).toList()),
      );
    } catch (e) {
      debugPrint('Erreur de sauvegarde du log de taux : $e');
    }
  }
}

/// Controller de gestion monétaire complet avec persistance, traçabilité et synchro API
class CurrencyNotifier extends Notifier<CurrencyState> {
  static const double _defaultBccRate = 2850.0;
  static const String _prefActiveCurrency = 'active_currency_code';
  static const String _prefCdfRate = 'cdf_exchange_rate';
  static const String _champTaux = 'tauxCDF';

  /// true dès que le taux de l'entreprise est arrivé de Firestore
  /// (il passe alors avant le taux gardé dans le téléphone)
  bool _tauxServeurRecu = false;

  @override
  CurrencyState build() {
    _tauxServeurRecu = false;
    final entrepriseId = ref.watch(entrepriseIdProvider);
    final boutiqueId = ref.watch(boutiqueActiveProvider);

    _loadPersistedPreferences();

    // 🔄 Taux partagé PAR BOUTIQUE : entreprises/{id}/boutiques/{boutique}, champ 'tauxCDF'
    //    (patron sur « Toutes les boutiques » : taux du téléphone seulement)
    if (entrepriseId.isNotEmpty && boutiqueId != null) {
      final abonnement = FirebaseFirestore.instance
          .collection('entreprises')
          .doc(entrepriseId)
          .collection('boutiques')
          .doc(boutiqueId)
          .snapshots()
          .listen(
        (doc) {
          final taux = (doc.data()?[_champTaux] as num?)?.toDouble();
          if (taux != null && taux > 0) _appliquerTauxServeur(taux);
        },
        onError: (e) =>
            debugPrint('[Stockly] Lecture du taux partagé impossible : $e'),
      );
      ref.onDispose(abonnement.cancel);
    }

    return CurrencyState(
      activeCurrency: 'USD',
      bccCdfRate: _defaultBccRate,
      currencies: _initialCurrencies(_defaultBccRate),
    );
  }

  /// Chargement automatique des choix enregistrés en cache local
  Future<void> _loadPersistedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCurrency = prefs.getString(_prefActiveCurrency) ?? 'USD';
    final savedCdfRate = _tauxServeurRecu
        ? state.bccCdfRate
        : (prefs.getDouble(_prefCdfRate) ?? _defaultBccRate);

    // Mise à jour interne du taux initial sans enregistrer un faux log d'audit
    final cdfInfo = state.currencies['CDF']?.copyWith(rateToUSD: savedCdfRate);
    if (cdfInfo != null) {
      final updatedMap = {...state.currencies, 'CDF': cdfInfo};
      state = state.copyWith(
        activeCurrency: savedCurrency,
        bccCdfRate: savedCdfRate,
        currencies: updatedMap,
      );
    }
  }

  /// Applique le taux reçu de l'entreprise (sans écrire dans l'historique)
  Future<void> _appliquerTauxServeur(double taux) async {
    _tauxServeurRecu = true;
    final cdf = state.currencies['CDF'];
    if (cdf == null || cdf.rateToUSD == taux) return;

    state = state.copyWith(
      bccCdfRate: taux,
      currencies: {...state.currencies, 'CDF': cdf.copyWith(rateToUSD: taux)},
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_prefCdfRate, taux);
    } catch (e) {
      debugPrint('[Stockly] Taux partagé non gardé sur le téléphone : $e');
    }
  }

  /// Envoie le nouveau taux aux téléphones de LA BOUTIQUE (Firestore)
  Future<void> _envoyerTauxServeur(double taux, String modifiedBy) async {
    final entrepriseId = ref.read(entrepriseIdProvider);
    final boutiqueId = ref.read(boutiqueActiveProvider);
    if (entrepriseId.isEmpty) return;
    if (boutiqueId == null) {
      debugPrint('[Stockly] Taux gardé sur ce téléphone (aucune boutique choisie)');
      return;
    }
    final uid = ref.read(userProfileProvider).value?.uid ?? '';

    try {
      await FirebaseFirestore.instance
          .collection('entreprises')
          .doc(entrepriseId)
          .collection('boutiques')
          .doc(boutiqueId)
          .set({
            _champTaux: taux,
            'tauxCDFDate': FieldValue.serverTimestamp(),
            'tauxCDFPar': modifiedBy,
            'tauxCDFParUid': uid,
          }, SetOptions(merge: true))
          .timeout(const Duration(seconds: 5));
      debugPrint('[Stockly] Taux $taux envoyé à la boutique $boutiqueId');
    } on TimeoutException {
      debugPrint('[Stockly] Taux gardé sur le téléphone, envoi en attente du réseau');
    } catch (e) {
      debugPrint('[Stockly] Taux NON partagé : $e');
    }
  }

  static Map<String, CurrencyInfo> _initialCurrencies(double cdfRate) {
    return {
      'USD': const CurrencyInfo(code: 'USD', symbol: '\$', name: 'Dollar Américain', rateToUSD: 1.0, decimalDigits: 2),
      'CDF': CurrencyInfo(code: 'CDF', symbol: 'FC', name: 'Franc Congolais (BCC)', rateToUSD: cdfRate, decimalDigits: 0),
      'EUR': const CurrencyInfo(code: 'EUR', symbol: '€', name: 'Euro', rateToUSD: 0.92, decimalDigits: 2),
      'XOF': const CurrencyInfo(code: 'XOF', symbol: 'FCFA', name: 'Franc CFA (UEMOA)', rateToUSD: 605.0, decimalDigits: 0),
      'XAF': const CurrencyInfo(code: 'XAF', symbol: 'FCFA', name: 'Franc CFA (CEMAC)', rateToUSD: 605.0, decimalDigits: 0),
      'KES': const CurrencyInfo(code: 'KES', symbol: 'KSh', name: 'Shilling Kényan', rateToUSD: 129.0, decimalDigits: 2),
      'RWF': const CurrencyInfo(code: 'RWF', symbol: 'FRw', name: 'Franc Rwandais', rateToUSD: 1350.0, decimalDigits: 0),
      'UGX': const CurrencyInfo(code: 'UGX', symbol: 'USh', name: 'Shilling Ougandais', rateToUSD: 3700.0, decimalDigits: 0),
      'TZS': const CurrencyInfo(code: 'TZS', symbol: 'TSh', name: 'Shilling Tanzanien', rateToUSD: 2700.0, decimalDigits: 0),
      'ZAR': const CurrencyInfo(code: 'ZAR', symbol: 'R', name: 'Rand Sud-Africain', rateToUSD: 18.2, decimalDigits: 2),
      'AOA': const CurrencyInfo(code: 'AOA', symbol: 'Kz', name: 'Kwanza Angolais', rateToUSD: 910.0, decimalDigits: 2),
      'NGN': const CurrencyInfo(code: 'NGN', symbol: '₦', name: 'Naira Nigérian', rateToUSD: 1600.0, decimalDigits: 2),
      'GBP': const CurrencyInfo(code: 'GBP', symbol: '£', name: 'Livre Sterling', rateToUSD: 0.78, decimalDigits: 2),
      'CAD': const CurrencyInfo(code: 'CAD', symbol: 'C\$', name: 'Dollar Canadien', rateToUSD: 1.36, decimalDigits: 2),
      'CHF': const CurrencyInfo(code: 'CHF', symbol: 'CHF', name: 'Franc Suisse', rateToUSD: 0.89, decimalDigits: 2),
      'CNY': const CurrencyInfo(code: 'CNY', symbol: '¥', name: 'Yuan Chinois', rateToUSD: 7.25, decimalDigits: 2),
      'INR': const CurrencyInfo(code: 'INR', symbol: '₹', name: 'Roupie Indienne', rateToUSD: 83.5, decimalDigits: 2),
      'AED': const CurrencyInfo(code: 'AED', symbol: 'AED', name: 'Dirham Émirats', rateToUSD: 3.67, decimalDigits: 2),
      'SAR': const CurrencyInfo(code: 'SAR', symbol: 'SAR', name: 'Riyal Saoudien', rateToUSD: 3.75, decimalDigits: 2),
      'JPY': const CurrencyInfo(code: 'JPY', symbol: '¥', name: 'Yen Japonais', rateToUSD: 155.0, decimalDigits: 0),
    };
  }

  /// Bascule la devise d'affichage globale et persiste le choix
  void setCurrency(String code) async {
    if (state.currencies.containsKey(code)) {
      state = state.copyWith(activeCurrency: code);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefActiveCurrency, code);
    }
  }

  /// Met à jour le taux de change de la devise locale (CDF) ou de la devise active
  void updateExchangeRate(double newRate, {String modifiedBy = 'Caissier'}) {
    final targetCode = state.activeCurrency == 'USD' ? 'CDF' : state.activeCurrency;
    updateRate(targetCode, newRate, modifiedBy: modifiedBy);
  }

  /// Met à jour le taux de change d'une devise quelconque avec traçabilité d'audit
  void updateRate(
    String code,
    double newRate, {
    String modifiedBy = 'Caissier',
  }) async {
    if (newRate <= 0 || !state.currencies.containsKey(code)) return;

    final existing = state.currencies[code]!;
    final oldRate = existing.rateToUSD;

    if (oldRate == newRate) return; // Aucun changement

    final updatedCurrency = existing.copyWith(rateToUSD: newRate);
    final updatedCurrencies = {...state.currencies, code: updatedCurrency};

    state = state.copyWith(
      bccCdfRate: code == 'CDF' ? newRate : state.bccCdfRate,
      currencies: updatedCurrencies,
    );

    if (code == 'CDF') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_prefCdfRate, newRate);
      // 🔄 Partage avec tous les téléphones de l'entreprise
      unawaited(_envoyerTauxServeur(newRate, modifiedBy));
    }

    // Déclenche l'enregistrement automatique dans l'historique d'audit
    ref.read(rateHistoryProvider.notifier).logRateChange(
          currencyCode: code,
          oldRate: oldRate,
          newRate: newRate,
          modifiedBy: modifiedBy,
        );
  }

  /// Raccourci de mise à jour pour la Banque Centrale du Congo
  void updateBccRate(double newRate, {String modifiedBy = 'Banque Centrale'}) {
    updateRate('CDF', newRate, modifiedBy: modifiedBy);
  }

  /// Application par lots de plusieurs taux de change (ex: retour d'API)
  void batchUpdateRates(
    Map<String, double> rates, {
    String modifiedBy = 'Synchro API',
  }) {
    rates.forEach((code, newRate) {
      if (state.currencies.containsKey(code) && code != 'USD' && newRate > 0) {
        updateRate(code, newRate, modifiedBy: modifiedBy);
      }
    });
  }

  /// Ajoute ou met à jour une devise dynamiquement
  void addCurrency(CurrencyInfo currency, {String modifiedBy = 'Admin'}) {
    if (currency.rateToUSD <= 0) return;

    final existing = state.currencies[currency.code];
    final oldRate = existing?.rateToUSD ?? 0.0;

    final updatedCurrencies = {...state.currencies, currency.code: currency};

    state = state.copyWith(
      bccCdfRate:
          currency.code == 'CDF' ? currency.rateToUSD : state.bccCdfRate,
      currencies: updatedCurrencies,
    );

    if (oldRate != currency.rateToUSD) {
      ref.read(rateHistoryProvider.notifier).logRateChange(
            currencyCode: currency.code,
            oldRate: oldRate,
            newRate: currency.rateToUSD,
            modifiedBy: modifiedBy,
          );
    }
  }

  /// Supprime une devise (sauf USD et la devise active)
  void removeCurrency(String code) {
    if (code == 'USD' ||
        code == state.activeCurrency ||
        !state.currencies.containsKey(code)) {
      return;
    }

    final updatedCurrencies = Map<String, CurrencyInfo>.from(state.currencies)
      ..remove(code);

    state = state.copyWith(currencies: updatedCurrencies);
  }
}

// ============================================================================
// PROVIDERS RIVERPOD
// ============================================================================

/// Provider pour consulter l'historique des changements de taux
final rateHistoryProvider =
    NotifierProvider<ExchangeRateHistoryNotifier, List<RateChangeLog>>(
  ExchangeRateHistoryNotifier.new,
);

/// Provider principal de la gestion monétaire
final currencyProvider =
    NotifierProvider<CurrencyNotifier, CurrencyState>(CurrencyNotifier.new);

/// Provider dérivé : sélectionne uniquement la devise active
final activeCurrencyInfoProvider = Provider<CurrencyInfo>((ref) {
  return ref.watch(
    currencyProvider.select((state) => state.activeCurrencyInfo),
  );
});

/// Provider dérivé : sélectionne la liste de toutes les devises pour les menus
final availableCurrenciesProvider = Provider<List<CurrencyInfo>>((ref) {
  return ref.watch(
    currencyProvider.select((state) => state.currencies.values.toList()),
  );
});