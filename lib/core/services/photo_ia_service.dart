import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// 📷🤖 Lecture d'une photo de packing list / facture par l'IA (Gemini, via Firebase AI Logic) — version 2.
/// Renvoie les produits au même format que l'import Excel :
///   {ligne, nom, codeBarre, quantite, prixAchat, prixVente}  (prix en dollars)
class PhotoIaService {
  /// Modèle conseillé par Firebase (utilisable sans plan payant)
  static const String modele = 'gemini-3.8-flash';

  /// Dernière lecture : monnaie du document et frais d'arrivage (fret…), convertis en dollars
  static String derniereDevise = 'USD';
  static double derniersFrais = 0;

  static const String _consigne = '''
Tu lis la PHOTO (ou la capture d'écran) d'une packing list, d'une facture ou d'un bon de livraison
de fournisseur, pour une boutique en RD Congo (balles de vêtements, articles divers).
Le document peut être en chinois, en anglais ou en français.

Rends :
- devise : la monnaie des prix, en code ISO (USD, CNY, EUR, CDF…). Indices : \$ ou USD = USD ; 元, ¥, RMB = CNY.
- frais : le total des frais écrits à part (fret maritime 海运费, transport, douane…), sinon 0.
- produits : une entrée par ligne de produit :
  - code : le code / la référence de la ligne (ex : A02). Vide s'il n'y en a pas.
  - nom : la désignation de l'article.
    Si elle est écrite en ANGLAIS ou en FRANÇAIS : recopie-la TELLE QUELLE (même orthographe, ne traduis pas).
    Si elle est en CHINOIS (ou une autre langue) : traduis-la en ANGLAIS, courte et claire,
    sans garder le chinois (ex : 棉半身裙 -> « cotton skirt », 女牛仔裤 -> « ladies jeans pant »).
    S'il y a à la fois un nom chinois et un nom anglais sur la ligne, prends le nom anglais.
  - quantite : le nombre d'unités livrées (balles, sacs, cartons ou pièces : colonne quantité,
    数量, QUANTITY, SACKS…). Nombre entier. Ce n'est PAS le poids en kilos.
  - prixAchat : le prix d'achat d'UNE unité de quantite (une balle, un sac ou une pièce).
    S'il y a un montant total pour la ligne, calcule prixAchat = montant total ÷ quantite
    (ex : 16200 ÷ 18 = 900). Ne prends JAMAIS un prix au kilo comme prixAchat.
  - prixVente : le prix de vente unitaire s'il est écrit, sinon 0.

Règles :
- N'invente rien. Un chiffre illisible = 0.
- Ignore les lignes de total, sous-total, frais, en-têtes, signatures, lignes vides,
  et toutes les lignes placées APRÈS la ligne de total.
- Nombres sans symbole de monnaie ni espace ; la virgule décimale devient un point (ex : 12.5).
- Si le document ne contient pas de liste de produits, rends une liste vide.
''';

  /// Demande la source (appareil photo ou galerie), lit la photo, et renvoie les produits (en dollars).
  /// null = annulé ou erreur (un message est affiché).
  static Future<List<Map<String, dynamic>>?> lirePhoto(BuildContext context) async {
    derniereDevise = 'USD';
    derniersFrais = 0;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: const Text('Prendre une photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Choisir une image ou une capture'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null || !context.mounted) return null;

    final XFile? photo;
    try {
      // Photo allégée : plus rapide à envoyer en 4G, toujours lisible par l'IA
      photo = await ImagePicker().pickImage(source: source, maxWidth: 1600, maxHeight: 3200, imageQuality: 75);
    } catch (e) {
      if (context.mounted) _message(context, "Impossible d'ouvrir l'appareil photo : $e");
      return null;
    }
    if (photo == null || !context.mounted) return null;
    final bytes = await photo.readAsBytes();
    if (!context.mounted) return null;
    final mime = photo.mimeType ?? (photo.name.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg');

    final navigateur = Navigator.of(context, rootNavigator: true);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 18),
            Expanded(
              child: Text("🤖 L'IA lit le document…\n"
                  'Un grand tableau peut prendre jusqu\'à 2 minutes. Gardez l\'application ouverte.'),
            ),
          ],
        ),
      ),
    );

    List<Map<String, dynamic>> produits;
    try {
      try {
        produits = await analyser(bytes, mime);
      } catch (e) {
        // Connexion coupée : un 2e essai automatique
        if (!_coupure(e)) rethrow;
        await Future<void>.delayed(const Duration(seconds: 2));
        produits = await analyser(bytes, mime);
      }
      navigateur.pop();
    } catch (e) {
      navigateur.pop();
      if (context.mounted) {
        final s = e.toString();
        final texte = s.contains('Timeout')
            ? "L'IA a mis trop de temps. Essayez une photo d'une partie du tableau (20 à 25 lignes), ou une meilleure connexion."
            : (_coupure(e)
                ? "La connexion internet s'est coupée pendant l'envoi. Réessayez avec un meilleur réseau."
                : "L'IA n'a pas pu lire le document. Détail : $s");
        _message(context, texte);
      }
      return null;
    }
    if (!context.mounted) return null;
    if (produits.isEmpty) {
      _message(context, "L'IA n'a trouvé aucun produit. Essayez une photo plus nette, bien droite.");
      return null;
    }

    // 💱 Prix dans une autre monnaie : conversion en dollars
    final devise = derniereDevise.trim().toUpperCase();
    if (devise.isNotEmpty && devise != 'USD' && devise != r'$') {
      final taux = await _demanderTaux(context, devise);
      if (taux == null) return null;
      double arrondi(double v) => (v * 100).roundToDouble() / 100;
      for (final p in produits) {
        p['prixAchat'] = arrondi((p['prixAchat'] as double) / taux);
        p['prixVente'] = arrondi((p['prixVente'] as double) / taux);
      }
      derniersFrais = arrondi(derniersFrais / taux);
    }
    return produits;
  }

  /// Envoie l'image à l'IA et convertit sa réponse en lignes d'import (dans la monnaie du document).
  static Future<List<Map<String, dynamic>>> analyser(Uint8List bytes, String mimeType) async {
    final schema = Schema.object(
      properties: {
        'devise': Schema.string(),
        'frais': Schema.number(),
        'produits': Schema.array(
          items: Schema.object(
            properties: {
              'code': Schema.string(),
              'nom': Schema.string(),
              'quantite': Schema.integer(),
              'prixAchat': Schema.number(),
              'prixVente': Schema.number(),
            },
            optionalProperties: ['code', 'prixAchat', 'prixVente'],
          ),
        ),
      },
      optionalProperties: ['devise', 'frais'],
    );

    final model = FirebaseAI.googleAI().generativeModel(
      model: modele,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: schema,
        temperature: 0,
      ),
    );

    final reponse = await model.generateContent([
      Content.multi([TextPart(_consigne), InlineDataPart(mimeType, bytes)]),
    ]).timeout(const Duration(seconds: 150));

    final texte = (reponse.text ?? '').trim();
    if (texte.isEmpty) return [];
    final donnees = jsonDecode(texte);
    if (donnees is! Map) return [];

    double nombre(dynamic v) => v is num ? v.toDouble() : double.tryParse('${v ?? ''}'.replaceAll(',', '.')) ?? 0.0;

    derniereDevise = (donnees['devise'] ?? 'USD').toString();
    derniersFrais = nombre(donnees['frais']);

    final liste = donnees['produits'] as List? ?? const [];
    final produits = <Map<String, dynamic>>[];
    var n = 0;
    for (final p in liste.whereType<Map>()) {
      final nom = (p['nom'] ?? '').toString().trim();
      if (nom.isEmpty) continue;
      n++;
      produits.add({
        'ligne': n,
        'nom': nom,
        'codeBarre': (p['code'] ?? '').toString().trim(),
        'quantite': nombre(p['quantite']).round(),
        'prixAchat': nombre(p['prixAchat']),
        'prixVente': nombre(p['prixVente']),
      });
    }
    return produits;
  }

  static bool _coupure(Object e) {
    final s = e.toString();
    return s.contains('ClientException') ||
        s.contains('SocketException') ||
        s.contains('connection abort') ||
        s.contains('Connection reset') ||
        s.contains('Connection closed');
  }

  static Future<double?> _demanderTaux(BuildContext context, String devise) async {
    final ctrl = TextEditingController();
    final nom = switch (devise) {
      'CNY' || 'RMB' => ' (yuans chinois)',
      'EUR' => ' (euros)',
      'CDF' => ' (francs congolais)',
      _ => '',
    };
    final taux = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Prix dans une autre monnaie'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Les prix de ce document sont en $devise$nom.\n'
                'Combien de $devise pour 1 \$ ? Les prix seront convertis en dollars.'),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: '1 \$ = … $devise'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text.replaceAll(',', '.').trim());
              if (v != null && v > 0) Navigator.pop(ctx, v);
            },
            child: const Text('Convertir'),
          ),
        ],
      ),
    );
    Future.delayed(const Duration(milliseconds: 500), ctrl.dispose);
    return taux;
  }

  static void _message(BuildContext context, String texte) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texte), backgroundColor: Colors.orange.shade800, duration: const Duration(seconds: 7)),
    );
  }
}
