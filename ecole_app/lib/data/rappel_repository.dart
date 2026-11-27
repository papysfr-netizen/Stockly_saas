import 'package:cloud_functions/cloud_functions.dart';

import '../services/rappels.dart';

/// Envoi automatique des rappels (SMS / WhatsApp) par la Cloud Function
/// `envoyerRappels`, qui détient les clés Twilio : elles ne sont jamais dans l'application.
class RappelRepository {
  RappelRepository(this._functions);
  final FirebaseFunctions _functions;

  Future<ResultatRappels> envoyer({
    required String ecoleId,
    required CanalRappel canal,
    List<String>? eleveIds,
  }) async {
    final res = await _functions.httpsCallable('envoyerRappels').call<Map<String, dynamic>>({
      'ecoleId': ecoleId,
      'canal': canal.name,
      if (eleveIds != null) 'eleveIds': eleveIds,
    });
    return ResultatRappels.fromMap(Map<String, dynamic>.from(res.data));
  }
}
