import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// 📷🤖 Lecture d'une photo de facture / packing list par l'IA (Gemini, via Firebase AI Logic).
/// Renvoie les produits au même format que l'import Excel :
///   {ligne, nom, codeBarre, quantite, prixAchat, prixVente}
class PhotoIaService {
  /// Modèle conseillé par Firebase (utilisable sans plan payant)
  static const String modele = 'gemini-3.8-flash';

  static const String _consigne = '''
Tu lis la PHOTO d'une facture, d'un bon de livraison ou d'une packing list de fournisseur
pour une boutique (vêtements, articles divers) en RD Congo.

Rends la liste des produits, une entrée par ligne de produit :
- code : le code / la référence de l'article tel qu'écrit (vide s'il n'y en a pas)
- nom : la désignation de l'article, telle qu'écrite (sans inventer)
- quantite : le nombre de pièces (entier). Si la ligne donne des cartons ET des pièces, prends les PIÈCES.
- prixAchat : le prix UNITAIRE d'achat s'il est écrit, sinon 0
- prixVente : le prix unitaire de vente s'il est écrit, sinon 0

Règles :
- N'invente rien. Si un chiffre est illisible, mets 0.
- Ignore les lignes de total, sous-total, transport, taxes, signatures et en-têtes.
- Les nombres sont écrits sans symbole de monnaie ni espace (ex : 12.5).
- Si la photo ne contient pas de liste de produits, rends une liste vide.
''';

  /// Demande la source (appareil photo ou galerie), lit la photo, et renvoie les produits.
  /// null = annulé ou erreur (un message est affiché).
  static Future<List<Map<String, dynamic>>?> lirePhoto(BuildContext context) async {
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
              title: const Text('Choisir une image'),
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
      photo = await ImagePicker().pickImage(source: source, maxWidth: 2200, imageQuality: 85);
    } catch (e) {
      if (context.mounted) _message(context, "Impossible d'ouvrir l'appareil photo : $e");
      return null;
    }
    if (photo == null || !context.mounted) return null;
    final bytes = await photo.readAsBytes();
    if (!context.mounted) return null;

    final navigateur = Navigator.of(context, rootNavigator: true);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 18),
            Expanded(child: Text("🤖 L'IA lit la photo…\nCela peut prendre jusqu'à une minute.")),
          ],
        ),
      ),
    );

    try {
      final produits = await analyser(bytes, photo.mimeType ?? 'image/jpeg');
      navigateur.pop();
      if (!context.mounted) return null;
      if (produits.isEmpty) {
        _message(context, "L'IA n'a trouvé aucun produit sur cette photo. Essayez une photo plus nette, bien droite.");
        return null;
      }
      return produits;
    } catch (e) {
      navigateur.pop();
      if (context.mounted) {
        _message(context, "L'IA n'a pas pu lire la photo (internet nécessaire). Détail : $e");
      }
      return null;
    }
  }

  /// Envoie l'image à l'IA et convertit sa réponse en lignes d'import.
  static Future<List<Map<String, dynamic>>> analyser(Uint8List bytes, String mimeType) async {
    final schema = Schema.object(properties: {
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
    });

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
    ]).timeout(const Duration(seconds: 90));

    final texte = (reponse.text ?? '').trim();
    if (texte.isEmpty) return [];
    final donnees = jsonDecode(texte);
    final liste = donnees is Map ? (donnees['produits'] as List? ?? const []) : const [];

    double nombre(dynamic v) => v is num ? v.toDouble() : double.tryParse('${v ?? ''}'.replaceAll(',', '.')) ?? 0.0;

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

  static void _message(BuildContext context, String texte) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texte), backgroundColor: Colors.orange.shade800, duration: const Duration(seconds: 6)),
    );
  }
}
