import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CurrencyService {
  // API gratuite de taux de change en temps réel
  static const String _apiUrl = 'https://open.er-api.com/v6/latest/USD';

  static Future<Map<String, double>> fetchExchangeRates() async {
    try {
      final response = await http.get(Uri.parse(_apiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        Map<String, dynamic> rates = data['rates'];
        return rates.map((key, value) => MapEntry(key, (value as num).toDouble()));
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération des taux de change : $e');
    }
    // Taux de secours par défaut en cas d'absence de connexion
    return {'USD': 1.0, 'EUR': 0.92, 'CDF': 2850.0, 'XOF': 600.0};
  }
}