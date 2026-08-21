import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// Provider Riverpod donnant accès à l'instance configurée de TwilioService
final twilioServiceProvider = Provider<TwilioService>((ref) {
  return TwilioService();
});

class TwilioService {
  final String accountSid;
  final String authToken;
  final String twilioPhoneNumber;
  final http.Client _client;

  TwilioService({
    this.accountSid = const String.fromEnvironment(
      'TWILIO_ACCOUNT_SID',
      defaultValue: 'VOTRE_ACCOUNT_SID_TWILIO',
    ),
    this.authToken = const String.fromEnvironment(
      'TWILIO_AUTH_TOKEN',
      defaultValue: 'VOTRE_AUTH_TOKEN_TWILIO',
    ),
    this.twilioPhoneNumber = const String.fromEnvironment(
      'TWILIO_PHONE_NUMBER',
      defaultValue: 'VOTRE_NUMERO_TWILIO',
    ),
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// Envoie un SMS via l'API REST Twilio
  Future<bool> sendSMS({
    required String toPhone,
    required String messageText,
  }) async {
    if (accountSid.startsWith('VOTRE_') || authToken.startsWith('VOTRE_')) {
      debugPrint('Erreur Twilio : Clés d\'API ou identifiants non configurés.');
      return false;
    }

    final url = Uri.parse(
      'https://api.twilio.com/2010-04-01/Accounts/$accountSid/Messages.json',
    );

    final basicAuth = 'Basic ${base64Encode(utf8.encode('$accountSid:$authToken'))}';

    try {
      final response = await _client.post(
        url,
        headers: {
          'Authorization': basicAuth,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'To': toPhone,
          'From': twilioPhoneNumber,
          'Body': messageText,
        },
      );

      if (response.statusCode == 201) {
        debugPrint('SMS Twilio envoyé avec succès.');
        return true;
      } else {
        debugPrint('Erreur Twilio (${response.statusCode}) : ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Erreur réseau Twilio : $e');
      return false;
    }
  }

  /// Alias de compatibilité
  Future<bool> sendSms({
    required String to,
    required String message,
  }) =>
      sendSMS(toPhone: to, messageText: message);

  /// Méthode statique conservée pour la rétrocompatibilité globale
  static Future<bool> staticSendSMS({
    required String toPhone,
    required String messageText,
  }) {
    return TwilioService().sendSMS(toPhone: toPhone, messageText: messageText);
  }
}