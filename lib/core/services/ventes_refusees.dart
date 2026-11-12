import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'rapport_erreurs.dart';

/// 🚨 Ventes envoyées hors ligne puis REFUSÉES par le serveur (règles de sécurité…).
/// Sans cette liste, elles disparaîtraient du téléphone sans prévenir.
class VentesRefusees {
  static const String _cle = 'ventes_refusees';
  static final ValueNotifier<int> changement = ValueNotifier<int>(0);

  static Future<void> noter(String venteId, String facture, double montant, String erreur) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final liste = prefs.getStringList(_cle) ?? <String>[];
      liste.add(jsonEncode({
        'id': venteId,
        'facture': facture,
        'montant': montant,
        'erreur': erreur,
        'date': DateTime.now().toIso8601String(),
      }));
      await prefs.setStringList(_cle, liste);
      changement.value++;
    } catch (_) {}
    // 🩺 Prévenir aussi le développeur (rapport de plantages)
    await RapportErreurs.envoyer(
      'Vente refusée par le serveur ($facture, $montant \$) : $erreur',
      null,
      contexte: 'vente refusée $venteId',
    );
  }

  static Future<List<Map<String, dynamic>>> lire() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return (prefs.getStringList(_cle) ?? const <String>[])
          .map((s) => Map<String, dynamic>.from(jsonDecode(s) as Map))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<void> effacer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cle);
    } catch (_) {}
    changement.value++;
  }
}

/// Carte rouge sur l'Accueil quand des ventes ont été refusées.
class AlerteVentesRefusees extends StatelessWidget {
  const AlerteVentesRefusees({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: VentesRefusees.changement,
      builder: (context, valeur, enfant) => FutureBuilder<List<Map<String, dynamic>>>(
        future: VentesRefusees.lire(),
        builder: (context, snap) {
          final liste = snap.data ?? const <Map<String, dynamic>>[];
          if (liste.isEmpty) return const SizedBox.shrink();
          final total = liste.fold<double>(0, (s, v) => s + ((v['montant'] as num?)?.toDouble() ?? 0));
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.shade400),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🚨 ${liste.length} vente(s) refusée(s) par le serveur',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade400, fontSize: 15),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Elles ne sont PAS enregistrées (total ${total.toStringAsFixed(2)} \$). '
                    "Refaites-les à la caisse, et mettez l'application à jour.",
                  ),
                  const SizedBox(height: 6),
                  for (final v in liste.take(5))
                    Text('• Facture ${v['facture']} — ${((v['montant'] as num?) ?? 0).toStringAsFixed(2)} \$',
                        style: const TextStyle(fontSize: 13)),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => VentesRefusees.effacer(),
                      child: const Text("C'est noté, effacer"),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
