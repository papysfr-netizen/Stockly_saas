// lib/core/widgets/sauvegarde_card.dart
//
// 💾 SAUVEGARDE COMPLÈTE (propriétaire)
// Lit toutes les données de l'entreprise sur le serveur et les met dans
// un seul fichier .json à garder hors du téléphone (WhatsApp, Drive…).
// Ne modifie RIEN dans la base.

import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Parties de l'entreprise à sauvegarder (celles qui n'existent pas sont ignorées)
const _sousCollections = [
  'produits',
  'ventes',
  'creances',
  'dettes',
  'ecritures_comptables',
  'comptes_clients',
  'boutiques',
  'transferts',
  'retours',
  'clients',
  'fournisseurs',
  'mouvements_stock',
  'livraisons',
  'inventaires',
  'categories',
];

/// Collections générales filtrées par entreprise
const _collectionsGenerales = ['depenses', 'users'];

class SauvegardeCard extends StatefulWidget {
  final String entrepriseId;
  const SauvegardeCard({super.key, required this.entrepriseId});

  @override
  State<SauvegardeCard> createState() => _SauvegardeCardState();
}

class _SauvegardeCardState extends State<SauvegardeCard> {
  bool _enCours = false;
  String _etape = '';

  /// Rend une valeur Firestore lisible dans un fichier texte (JSON)
  static Object? _propre(Object? v) {
    if (v is Timestamp) return {'_date': v.toDate().toIso8601String()};
    if (v is DateTime) return {'_date': v.toIso8601String()};
    if (v is GeoPoint) return {'_lat': v.latitude, '_lng': v.longitude};
    if (v is DocumentReference) return {'_ref': v.path};
    if (v is Map) return v.map((k, x) => MapEntry(k.toString(), _propre(x)));
    if (v is List) return v.map(_propre).toList();
    if (v is Blob) return null;
    return v;
  }

  static String _deux(int n) => n.toString().padLeft(2, '0');

  Future<List<Map<String, dynamic>>> _lire(Query<Map<String, dynamic>> q) async {
    final snap = await q
        .get(GetOptions(source: Source.server))
        .timeout(const Duration(seconds: 60));
    return [
      for (final d in snap.docs)
        {'_id': d.id, ...(_propre(d.data()) as Map<String, dynamic>)},
    ];
  }

  void _etapeEnCours(String texte) {
    if (mounted) setState(() => _etape = texte);
  }

  Future<void> _sauvegarder() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _enCours = true;
      _etape = 'Préparation…';
    });
    try {
      final db = FirebaseFirestore.instance;
      final ent = db.collection('entreprises').doc(widget.entrepriseId);

      // Internet obligatoire : on lit la fiche de l'entreprise sur le serveur
      final entDoc = await ent
          .get(GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 20));

      final maintenant = DateTime.now();
      final donnees = <String, dynamic>{
        'application': 'Stockly Pro',
        'format': 1,
        'creeLe': maintenant.toIso8601String(),
        'entrepriseId': widget.entrepriseId,
        'entreprise': _propre(entDoc.data()),
      };
      final compte = <String, int>{};
      final nonLues = <String>[];

      for (final c in _sousCollections) {
        _etapeEnCours('Lecture : $c…');
        try {
          final docs = await _lire(ent.collection(c));
          if (docs.isNotEmpty) {
            donnees[c] = docs;
            compte[c] = docs.length;
          }
        } catch (e) {
          debugPrint('Sauvegarde $c : $e');
          nonLues.add(c);
        }
      }
      for (final c in _collectionsGenerales) {
        _etapeEnCours('Lecture : $c…');
        try {
          final docs = await _lire(
              db.collection(c).where('entrepriseId', isEqualTo: widget.entrepriseId));
          if (docs.isNotEmpty) {
            donnees[c] = docs;
            compte[c] = docs.length;
          }
        } catch (e) {
          debugPrint('Sauvegarde $c : $e');
          nonLues.add(c);
        }
      }

      _etapeEnCours('Création du fichier…');
      final nom = 'Sauvegarde_Stockly_${maintenant.year}-${_deux(maintenant.month)}-'
          '${_deux(maintenant.day)}_${_deux(maintenant.hour)}h${_deux(maintenant.minute)}.json';
      final dossier = await getTemporaryDirectory();
      final fichier = File('${dossier.path}/$nom');
      await fichier.writeAsString(const JsonEncoder.withIndent(' ').convert(donnees));

      final total = compte.values.fold<int>(0, (s, n) => s + n);
      if (!mounted) return;
      setState(() => _enCours = false);

      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('💾 Sauvegarde prête'),
          content: SingleChildScrollView(
            child: Text(
              '$total documents sauvegardés :\n'
              '${compte.entries.map((e) => '• ${e.key} : ${e.value}').join('\n')}'
              '${nonLues.isEmpty ? '' : '\n\n⚠️ Non lus : ${nonLues.join(', ')}'}'
              '\n\nEnvoyez maintenant le fichier sur WhatsApp ou Google Drive '
              "et gardez-le en lieu sûr (il contient des données privées).",
            ),
          ),
          actions: [
            ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Envoyer')),
          ],
        ),
      );

      await Share.shareXFiles(
        [XFile(fichier.path)],
        subject: 'Sauvegarde Stockly',
        text: 'Sauvegarde complète Stockly du '
            '${_deux(maintenant.day)}/${_deux(maintenant.month)}/${maintenant.year}',
      );
    } catch (e) {
      if (mounted) setState(() => _enCours = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Sauvegarde impossible (internet nécessaire) : $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.backup_rounded, color: Color(0xFF0052FF)),
        title: const Text('💾 Sauvegarde complète',
            style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(_enCours
            ? _etape
            : 'Toutes les données dans un fichier à garder (WhatsApp, Drive). '
                'Conseil : chaque semaine et avant une grosse opération.'),
        trailing: _enCours
            ? const SizedBox(
                width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.chevron_right),
        onTap: _enCours ? null : _sauvegarder,
      ),
    );
  }
}
