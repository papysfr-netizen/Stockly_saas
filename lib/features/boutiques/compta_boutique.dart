// lib/features/boutiques/compta_boutique.dart
//
// 🏬 COMPTABILITÉ PAR BOUTIQUE
//  - infosEcritures : boutique et référence de chaque écriture (rempli par
//    ecrituresComptablesProvider à chaque mise à jour)
//  - rattraperBoutiquesEcritures : donne une boutique aux anciennes écritures

import 'package:cloud_firestore/cloud_firestore.dart';

/// id de l'écriture -> (boutique, référence)   ('' = pas encore de boutique)
final Map<String, ({String boutique, String reference})> infosEcritures = {};

/// Noté à chaque lecture des écritures
void noterInfosEcriture(String id, Object? data) {
  final m = data is Map ? data : const {};
  infosEcritures[id] = (
    boutique: (m['boutiqueId'] ?? '').toString(),
    reference: (m['reference'] ?? '').toString(),
  );
}

/// Boutique d'une écriture (sans boutique = principale)
String boutiqueEcriture(String id) {
  final b = infosEcritures[id]?.boutique ?? '';
  return b.isEmpty ? 'principale' : b;
}

bool _rattrapageFait = false;

/// 🏬 Les anciennes écritures sans boutique reçoivent celle de leur
/// vente / dette / dépense d'origine (sinon « principale »). Une fois par session.
Future<void> rattraperBoutiquesEcritures(String entrepriseId) async {
  if (_rattrapageFait || entrepriseId.isEmpty) return;
  _rattrapageFait = true;
  final db = FirebaseFirestore.instance;
  final ent = db.collection('entreprises').doc(entrepriseId);
  final serveur = GetOptions(source: Source.server);
  try {
    // Pas de réseau : on arrête tout de suite (on réessaiera plus tard)
    await ent.get(serveur).timeout(const Duration(seconds: 8));
    final snap = await ent
        .collection('ecritures_comptables')
        .get(serveur)
        .timeout(const Duration(seconds: 40));

    final boutiques = <String, String>{}; // id écriture -> boutique
    final aFaire = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    for (final doc in snap.docs) {
      final b = (doc.data()['boutiqueId'] ?? '').toString();
      if (b.isNotEmpty) {
        boutiques[doc.id] = b;
      } else {
        aFaire.add(doc);
      }
    }
    if (aFaire.isEmpty) return;

    // Lit un document sans jamais planter (introuvable / refusé -> '')
    Future<String> lire(DocumentReference<Map<String, dynamic>> r) async {
      try {
        final d = await r.get().timeout(const Duration(seconds: 8));
        if (!d.exists) return '';
        final b = (d.data()?['boutiqueId'] ?? '').toString();
        return b.isEmpty ? 'principale' : b;
      } catch (_) {
        return '';
      }
    }

    final cache = <String, String>{}; // référence -> boutique
    Future<String> chercher(String reference) async {
      if (reference.isEmpty || reference.contains('/')) return 'principale';
      final dejaVu = cache[reference];
      if (dejaVu != null) return dejaVu;
      var b = '';
      for (final col in ['ventes', 'creances', 'dettes']) {
        b = await lire(ent.collection(col).doc(reference));
        if (b.isNotEmpty) break;
      }
      if (b.isEmpty) b = await lire(db.collection('depenses').doc(reference));
      if (b.isEmpty) b = 'principale';
      cache[reference] = b;
      return b;
    }

    String ref(QueryDocumentSnapshot<Map<String, dynamic>> d) =>
        (d.data()['reference'] ?? '').toString();

    // 1) Écritures normales (par paquets de 20 lectures en même temps)
    final normales = aFaire.where((d) => !ref(d).startsWith('EXT-')).toList();
    for (var i = 0; i < normales.length; i += 20) {
      final paquet = normales.skip(i).take(20).toList();
      final res = await Future.wait(paquet.map((d) => chercher(ref(d))));
      for (var j = 0; j < paquet.length; j++) {
        boutiques[paquet[j].id] = res[j];
      }
    }
    // 2) Extournes : même boutique que l'écriture annulée
    for (final d in aFaire.where((d) => ref(d).startsWith('EXT-'))) {
      boutiques[d.id] = boutiques[ref(d).substring(4)] ?? 'principale';
    }

    // 3) Enregistrement par paquets de 400
    for (var i = 0; i < aFaire.length; i += 400) {
      final batch = db.batch();
      for (final d in aFaire.skip(i).take(400)) {
        batch.update(d.reference, {'boutiqueId': boutiques[d.id] ?? 'principale'});
      }
      await batch.commit().timeout(const Duration(seconds: 30));
    }
  } catch (_) {
    // Pas de réseau ou refus : on réessaiera à la prochaine ouverture
    _rattrapageFait = false;
  }
}
