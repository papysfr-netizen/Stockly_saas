// lib/features/cloture/cloture_service.dart
//
// 🔒 CLÔTURE DE CAISSE (une par boutique et par jour)
//
//  - Le soir, quelqu'un compte le tiroir : billets en $ et en FC, plus le
//    Mobile Money reçu dans la journée. C'est un comptage « à l'aveugle » :
//    celui qui compte ne voit PAS le montant attendu.
//  - Le patron (ou « Voir les finances ») voit l'écart : compté − attendu.
//  - L'attendu est recalculé à la lecture, jusqu'à l'heure de la clôture,
//    par quelqu'un qui a le droit de tout lire (ventes, dettes, dépenses…).

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:stockly_saas/core/services/argent_vente.dart';

/// Moyen de paiement ramené à 3 familles
enum Famille { especes, mobile, autre }

class ClotureService {
  ClotureService._();

  static const String collectionNom = 'clotures';

  static CollectionReference<Map<String, dynamic>> collection(String entrepriseId) =>
      FirebaseFirestore.instance
          .collection('entreprises')
          .doc(entrepriseId)
          .collection(collectionNom);

  /// « 2026-11-14 » (date du téléphone)
  static String cleJour(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Une seule clôture par boutique et par jour : l'identifiant le garantit
  static String idCloture(String boutiqueId, DateTime jour) => '${boutiqueId}_${cleJour(jour)}';

  static double nombre(Object? v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', '.').replaceAll(' ', '')) ?? 0.0;
    return 0.0;
  }

  static DateTime? date(Object? v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  /// Espèces, Mobile Money ou autre (carte, virement, chèque, compte client…)
  static Famille famille(Object? methode) {
    final m = (methode ?? '').toString().toLowerCase();
    if (m.contains('mobile')) return Famille.mobile;
    if (m.isEmpty || m.contains('cash') || m.contains('espèce') || m.contains('espece')) {
      return Famille.especes;
    }
    return Famille.autre;
  }

  /// Une ancienne donnée sans boutique compte pour la boutique principale
  static bool memeBoutique(String boutiqueId, Object? b) {
    final s = (b ?? '').toString();
    return (s.isEmpty ? 'principale' : s) == boutiqueId;
  }

  // ================================================================
  // Lecture
  // ================================================================

  /// La clôture du jour pour cette boutique (null = pas encore clôturée)
  static Stream<DocumentSnapshot<Map<String, dynamic>>> ecouter(
          String entrepriseId, String boutiqueId, DateTime jour) =>
      collection(entrepriseId).doc(idCloture(boutiqueId, jour)).snapshots();

  /// Lecture rapide (cache d'abord) : la caisse est-elle clôturée ?
  static Future<bool> estCloturee(String entrepriseId, String boutiqueId, DateTime jour) async {
    final ref = collection(entrepriseId).doc(idCloture(boutiqueId, jour));
    try {
      final c = await ref.get(const GetOptions(source: Source.cache));
      if (c.exists) return true;
    } catch (_) {}
    try {
      final s = await ref.get().timeout(const Duration(seconds: 3));
      return s.exists;
    } catch (_) {
      return false;
    }
  }

  /// Le fond laissé pour demain par la dernière clôture de cette boutique
  static Future<({double usd, double cdf})> fondPropose(String entrepriseId, String boutiqueId) async {
    try {
      // Les 30 dernières clôtures (toutes boutiques), sans index spécial
      final s = await collection(entrepriseId)
          .orderBy('createdAt', descending: true)
          .limit(30)
          .get()
          .timeout(const Duration(seconds: 5));
      for (final doc in s.docs) {
        final d = doc.data();
        if (d['boutiqueId'] != boutiqueId) continue;
        return (usd: nombre(d['fondDemainUSD']), cdf: nombre(d['fondDemainCDF']));
      }
      return (usd: 0.0, cdf: 0.0);
    } catch (_) {
      return (usd: 0.0, cdf: 0.0);
    }
  }

  // ================================================================
  // Enregistrement
  // ================================================================

  /// Enregistre la clôture (une seule fois : ne peut plus être modifiée).
  /// Les montants sont ceux COMPTÉS ; l'attendu est calculé à la lecture.
  static Future<void> enregistrer({
    required String entrepriseId,
    required String boutiqueId,
    required DateTime jour,
    required String parNom,
    required double taux,
    required double fondUSD,
    required double fondCDF,
    required double compteUSD,
    required double compteCDF,
    required double compteMobile,
    required double fondDemainUSD,
    required double fondDemainCDF,
    required String note,
  }) async {
    final ref = collection(entrepriseId).doc(idCloture(boutiqueId, jour));
    await ref.set({
      'boutiqueId': boutiqueId,
      'jour': cleJour(jour),
      'parUid': FirebaseAuth.instance.currentUser?.uid ?? '',
      'parNom': parNom,
      'taux': taux,
      'fondUSD': fondUSD,
      'fondCDF': fondCDF,
      'compteUSD': compteUSD,
      'compteCDF': compteCDF,
      'compteMobile': compteMobile,
      'fondDemainUSD': fondDemainUSD,
      'fondDemainCDF': fondDemainCDF,
      'note': note.length > 300 ? note.substring(0, 300) : note,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ================================================================
  // Calcul de l'argent attendu (réservé à « Voir les finances »)
  // ================================================================

  /// Argent qui DEVRAIT être là entre [debut] et [fin] (en dollars).
  static Future<Attendu> calculerAttendu({
    required String entrepriseId,
    required String boutiqueId,
    required DateTime debut,
    required DateTime fin,
  }) async {
    final ent = FirebaseFirestore.instance.collection('entreprises').doc(entrepriseId);
    final depuis = Timestamp.fromDate(debut);
    bool dansPeriode(DateTime? d) => d != null && !d.isBefore(debut) && !d.isAfter(fin);

    final a = Attendu();

    // 1. Ventes : argent reçu à la vente (sans monnaie rendue ni compte client)
    final ventes = await ent.collection('ventes').where('date', isGreaterThanOrEqualTo: depuis).get();
    for (final doc in ventes.docs) {
      final v = doc.data();
      if (!memeBoutique(boutiqueId, v['boutiqueId'])) continue;
      final quand = date(v['date']);
      if (quand != null && quand.isAfter(fin)) {
        a.ventesApresCloture++;
        a.montantApresCloture += nombre(v['montantTotal']);
        continue;
      }
      if (!dansPeriode(quand)) continue;
      a.nombreVentes++;
      final argent = ArgentVente.cashALaVente(v);
      switch (famille(v['methodePaiement'])) {
        case Famille.especes:
          a.ventesEspeces += argent;
        case Famille.mobile:
          a.ventesMobile += argent;
        case Famille.autre:
          a.autres += argent;
      }
    }

    // 2. Dettes clients encaissées (entrées) et dettes fournisseurs payées (sorties)
    for (final col in const ['creances', 'dettes']) {
      final estClient = col == 'creances';
      QuerySnapshot<Map<String, dynamic>> s;
      try {
        s = await ent.collection(col).where('dernierPaiement', isGreaterThanOrEqualTo: depuis).get();
      } catch (_) {
        continue;
      }
      for (final doc in s.docs) {
        final c = doc.data();
        if (!memeBoutique(boutiqueId, c['boutiqueId'])) continue;
        final creation = c['dateCreation'] ?? c['createdAt'];
        final paiements = c['paiements'];
        if (paiements is! List) continue;
        for (final p in paiements.whereType<Map>()) {
          // Acompte donné à la vente : déjà compté dans la vente
          if (estClient && creation is Timestamp && p['date'] == creation) continue;
          if (!dansPeriode(date(p['date']))) continue;
          final montant = nombre(p['montant']);
          final f = famille(p['methode']);
          if (estClient) {
            if (f == Famille.especes) a.dettesEspeces += montant;
            if (f == Famille.mobile) a.dettesMobile += montant;
          } else {
            if (f == Famille.especes) a.fournisseursEspeces += montant;
            if (f == Famille.mobile) a.fournisseursMobile += montant;
          }
        }
      }
    }

    // 3. Dépenses de la boutique
    try {
      QuerySnapshot<Map<String, dynamic>> s;
      try {
        s = await FirebaseFirestore.instance
            .collection('depenses')
            .where('entrepriseId', isEqualTo: entrepriseId)
            .orderBy('date', descending: true)
            .where('date', isGreaterThanOrEqualTo: depuis)
            .get();
      } catch (_) {
        // Sans index : on lit tout et on trie ici
        s = await FirebaseFirestore.instance
            .collection('depenses')
            .where('entrepriseId', isEqualTo: entrepriseId)
            .get();
      }
      for (final doc in s.docs) {
        final d = doc.data();
        if (!memeBoutique(boutiqueId, d['boutiqueId'])) continue;
        if (!dansPeriode(date(d['date']))) continue;
        final montant = nombre(d['montant']);
        final f = famille(d['methodePaiement']);
        if (f == Famille.especes) a.depensesEspeces += montant;
        if (f == Famille.mobile) a.depensesMobile += montant;
      }
    } catch (_) {
      a.depensesIllisibles = true;
    }

    // 4. Remboursements en espèces des retours
    try {
      final s = await ent.collection('retours').where('date', isGreaterThanOrEqualTo: depuis).get();
      for (final doc in s.docs) {
        final r = doc.data();
        if ((r['modeRemboursement'] ?? '').toString() != 'especes') continue;
        if (!memeBoutique(boutiqueId, r['boutiqueId'])) continue;
        if (!dansPeriode(date(r['date']))) continue;
        a.remboursementsEspeces += nombre(r['montantRembourse']);
      }
    } catch (_) {}

    // 5. Comptes clients : dépôts (entrées) et retraits (sorties)
    //    (les comptes clients sont communs à toutes les boutiques)
    try {
      final comptes =
          await ent.collection('comptes_clients').where('updatedAt', isGreaterThanOrEqualTo: depuis).get();
      for (final c in comptes.docs) {
        final mv = await c.reference.collection('mouvements').where('date', isGreaterThanOrEqualTo: depuis).get();
        for (final m in mv.docs) {
          final d = m.data();
          if (!dansPeriode(date(d['date']))) continue;
          final type = (d['type'] ?? '').toString();
          final montant = nombre(d['montant']);
          final mobile = famille(d['methode']) == Famille.mobile;
          if (type == 'depot') {
            if (mobile) {
              a.depotsMobile += montant;
            } else {
              a.depotsEspeces += montant;
            }
          } else if (type == 'retrait') {
            if (mobile) {
              a.retraitsMobile += montant;
            } else {
              a.retraitsEspeces += montant;
            }
          }
        }
      }
    } catch (_) {}

    return a;
  }
}

/// Le détail de l'argent attendu (en dollars)
class Attendu {
  double ventesEspeces = 0, ventesMobile = 0, autres = 0;
  double dettesEspeces = 0, dettesMobile = 0;
  double fournisseursEspeces = 0, fournisseursMobile = 0;
  double depensesEspeces = 0, depensesMobile = 0;
  double remboursementsEspeces = 0;
  double depotsEspeces = 0, retraitsEspeces = 0, depotsMobile = 0, retraitsMobile = 0;
  int nombreVentes = 0;
  int ventesApresCloture = 0;
  double montantApresCloture = 0;
  bool depensesIllisibles = false;

  /// Espèces de la journée (sans le fond de caisse)
  double get especes =>
      ventesEspeces +
      dettesEspeces +
      depotsEspeces -
      depensesEspeces -
      fournisseursEspeces -
      remboursementsEspeces -
      retraitsEspeces;

  /// Mobile Money reçu dans la journée (net)
  double get mobile =>
      ventesMobile + dettesMobile + depotsMobile - depensesMobile - fournisseursMobile - retraitsMobile;
}

/// Résultat d'une clôture : compté − attendu
class ResultatCloture {
  final Map<String, dynamic> cloture;
  final Attendu attendu;
  ResultatCloture(this.cloture, this.attendu);

  double get taux {
    final t = ClotureService.nombre(cloture['taux']);
    return t > 0 ? t : 1;
  }

  double get fond =>
      ClotureService.nombre(cloture['fondUSD']) + ClotureService.nombre(cloture['fondCDF']) / taux;
  double get especesAttendues => fond + attendu.especes;
  double get especesComptees =>
      ClotureService.nombre(cloture['compteUSD']) + ClotureService.nombre(cloture['compteCDF']) / taux;
  double get ecartEspeces => especesComptees - especesAttendues;

  double get mobileAttendu => attendu.mobile;
  double get mobileCompte => ClotureService.nombre(cloture['compteMobile']);
  double get ecartMobile => mobileCompte - mobileAttendu;

  /// Écart toléré : moins de 50 centimes
  static bool juste(double ecart) => ecart.abs() < 0.5;
}
