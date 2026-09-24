import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

class CurrencyService {
  static const String _baseUrl = 'https://open.er-api.com/v6/latest';

  /// Récupère les taux de change avec gestion de timeout et de secours
  static Future<Map<String, double>> fetchExchangeRates({String base = 'USD'}) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/$base'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (data['result'] == 'success' && data['rates'] != null) {
          final Map<String, dynamic> rates = data['rates'];
          return rates.map((key, value) => MapEntry(key, (value as num).toDouble()));
        }
      }
      debugPrint('Réponse API non valide (Status: ${response.statusCode})');
    } on TimeoutException {
      debugPrint('Timeout lors de la récupération des taux de change.');
    } catch (e) {
      debugPrint('Erreur lors de la récupération des taux de change : $e');
    }

    // Taux de secours en cas de panne réseau ou de délai dépassé
    return const {
      'USD': 1.0,
      'EUR': 0.92,
      'CDF': 2850.0,
      'XOF': 600.0,
    };
  }
}

// ============================================================================
// PROVIDER RIVERPOD POUR L'APPLICATION
// ============================================================================

/// Provider pour charger et mettre en cache les taux de change
final exchangeRatesProvider = FutureProvider<Map<String, double>>((ref) async {
  return CurrencyService.fetchExchangeRates();
});