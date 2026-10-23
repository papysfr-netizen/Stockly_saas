import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stockly_saas/core/services/journal_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/depense.dart';
import 'user_role_provider.dart';

/// Repository gérant les opérations Firestore pour les dépenses.
/// Chaque dépense crée aussi son écriture comptable (SYSCOHADA) :
///   Débit  : compte de charge (classe 6) selon la catégorie
///   Crédit : caisse 571000 (ou banque 521000)
class DepenseRepository {
  final FirebaseFirestore _firestore;

  /// Délai au-delà duquel on considère que l'on est hors ligne :
  /// Firestore garde alors l'écriture et l'envoie au retour du réseau.
  static const Duration _delai = Duration(seconds: 5);

  DepenseRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // Outils internes
  // ---------------------------------------------------------------------------

  /// Référence de l'écriture comptable liée à une dépense : DEP-{idDepense}
  DocumentReference<Map<String, dynamic>> _refEcriture(
      String entrepriseId, String depenseId) {
    return _firestore
        .collection('entreprises')
        .doc(entrepriseId)
        .collection('ecritures_comptables')
        .doc('DEP-$depenseId');
  }

  /// Met un texte en minuscules et retire les accents (pour comparer).
  static String _simplifier(String texte) {
    const avec = 'àâäáãéèêëíìîïóòôöõúùûüçñ';
    const sans = 'aaaaaeeeeiiiiooooouuuucn';
    var resultat = texte.toLowerCase();
    for (var i = 0; i < avec.length; i++) {
      resultat = resultat.replaceAll(avec[i], sans[i]);
    }
    return resultat;
  }

  /// Compte de charge (classe 6) selon la catégorie de la dépense.
  static MapEntry<String, String> _compteCharge(String categorie) {
    final c = _simplifier(categorie);
    if (c.contains('electric') || c.contains('eau') || c.contains('energie')) {
      return const MapEntry('605000', 'Autres achats (eau, électricité)');
    }
    if (c.contains('transport') || c.contains('carbur')) {
      return const MapEntry('618000', 'Autres frais de transport');
    }
    if (c.contains('loyer') || c.contains('location')) {
      return const MapEntry('622000', 'Locations et charges locatives');
    }
    if (c.contains('salaire') || c.contains('personnel') || c.contains('paie')) {
      return const MapEntry('661000', 'Rémunérations du personnel');
    }
    if (c.contains('telephon') ||
        c.contains('internet') ||
        c.contains('communication')) {
      return const MapEntry('628000', 'Frais de télécommunications');
    }
    if (c.contains('entretien') ||
        c.contains('reparation') ||
        c.contains('maintenance')) {
      return const MapEntry('624000', 'Entretien, réparations et maintenance');
    }
    if (c.contains('impot') || c.contains('taxe')) {
      return const MapEntry('640000', 'Impôts et taxes');
    }
    return const MapEntry('638000', 'Autres charges externes');
  }

  /// Compte de trésorerie selon le moyen de paiement.
  static MapEntry<String, String> _compteTresorerie(String methodePaiement) {
    final m = _simplifier(methodePaiement);
    if (m.contains('banq') ||
        m.contains('bank') ||
        m.contains('virement') ||
        m.contains('cheque')) {
      return const MapEntry('521000', 'Banques');
    }
    return const MapEntry('571000', 'Caisse');
  }

  /// Contenu de l'écriture comptable d'une dépense
  /// (même format que les écritures de la caisse).
  static Map<String, dynamic> _ecriture(Depense d) {
    final charge = _compteCharge(d.categorie);
    final tresorerie = _compteTresorerie(d.methodePaiement);
    return {
      'id': 'DEP-${d.id}',
      'entrepriseId': d.entrepriseId,
      'reference': d.id,
      'type': 'depense',
      'description': 'Dépense : ${d.titre} (${d.categorie})',
      'date': d.date,
      'lines': [
        {
          'accountCode': charge.key,
          'accountLabel': charge.value,
          'debit': d.montant,
          'credit': 0.0,
        },
        {
          'accountCode': tresorerie.key,
          'accountLabel': tresorerie.value,
          'debit': 0.0,
          'credit': d.montant,
        },
      ],
      'montantEncaisse': 0.0,
    };
  }

  /// 📒 Texte du journal pour une dépense (description, catégorie…)
  static String _texteJournal(Map<String, dynamic>? j) {
    if (j == null) return '';
    final morceaux = <String>[];
    for (final cle in const ['description', 'libelle', 'motif', 'titre', 'categorie', 'beneficiaire']) {
      final v = (j[cle] ?? '').toString().trim();
      if (v.isNotEmpty && !morceaux.contains(v)) morceaux.add(v);
    }
    return morceaux.join(' · ');
  }

  static String _boutiqueJournal(Map<String, dynamic>? j) {
    final b = (j?['boutiqueId'] ?? '').toString();
    return b.isEmpty ? 'principale' : b;
  }

  /// Une dépense peut être comptabilisée si elle a une entreprise et un montant.
  static bool _peutComptabiliser(Depense d) =>
      d.entrepriseId.isNotEmpty && d.montant > 0;

  /// Envoie le lot d'écritures. Hors ligne : enregistré sur le téléphone,
  /// envoyé automatiquement au retour du réseau.
  Future<void> _valider(WriteBatch batch) async {
    try {
      await batch.commit().timeout(_delai);
    } on TimeoutException {
      debugPrint(
          '[Stockly] Hors ligne : dépense gardée sur le téléphone, envoi au retour du réseau.');
    }
  }

  // ---------------------------------------------------------------------------
  // Opérations publiques
  // ---------------------------------------------------------------------------

  /// Ajoute une nouvelle dépense + son écriture comptable.
  Future<void> ajouterDepense(Depense depense) async {
    final docRef = _firestore.collection('depenses').doc();
    final avecId = depense.copyWith(id: docRef.id);
    final comptabiliser = _peutComptabiliser(avecId);
    final nouvelleDepense = avecId.copyWith(comptabilise: comptabiliser);

    final batch = _firestore.batch();
    batch.set(docRef, nouvelleDepense.toJson());
    if (comptabiliser) {
      batch.set(
        _refEcriture(nouvelleDepense.entrepriseId, nouvelleDepense.id),
        _ecriture(nouvelleDepense),
      );
    }
    await _valider(batch);

    // 📒 Journal « qui a fait quoi »
    final json = nouvelleDepense.toJson();
    unawaited(noterJournal(
      entrepriseId: nouvelleDepense.entrepriseId,
      action: ActionsJournal.depense,
      details: 'Ajoutée · ${_texteJournal(json)}',
      boutiqueId: _boutiqueJournal(json),
      montant: nouvelleDepense.montant,
      reference: nouvelleDepense.id,
    ));
  }

  /// Met à jour une dépense existante + son écriture comptable.
  Future<void> modifierDepense(Depense depense) async {
    if (depense.id.isEmpty) return;

    final comptabiliser = _peutComptabiliser(depense);
    final maj = depense.copyWith(comptabilise: comptabiliser);

    final batch = _firestore.batch();
    batch.update(_firestore.collection('depenses').doc(maj.id), maj.toJson());

    if (comptabiliser) {
      batch.set(_refEcriture(maj.entrepriseId, maj.id), _ecriture(maj));
    } else if (maj.entrepriseId.isNotEmpty) {
      batch.delete(_refEcriture(maj.entrepriseId, maj.id));
    }
    await _valider(batch);

    // 📒 Journal « qui a fait quoi »
    final json = maj.toJson();
    unawaited(noterJournal(
      entrepriseId: maj.entrepriseId,
      action: ActionsJournal.depense,
      details: 'Modifiée · ${_texteJournal(json)}',
      boutiqueId: _boutiqueJournal(json),
      montant: maj.montant,
      reference: maj.id,
    ));
  }

  /// Supprime une dépense + son écriture comptable.
  Future<void> supprimerDepense(String id) async {
    if (id.isEmpty) return;
    final depenseRef = _firestore.collection('depenses').doc(id);

    // On lit la dépense pour connaître son entreprise (serveur, sinon cache).
    String entrepriseId = '';
    Map<String, dynamic>? donnees; // 📒 pour le journal
    try {
      final snap = await depenseRef.get().timeout(_delai);
      donnees = snap.data();
      entrepriseId = snap.data()?['entrepriseId']?.toString() ?? '';
    } catch (_) {
      try {
        final snap =
            await depenseRef.get(const GetOptions(source: Source.cache));
        donnees = snap.data();
        entrepriseId = snap.data()?['entrepriseId']?.toString() ?? '';
      } catch (_) {
        // Introuvable : on supprime au moins la dépense.
      }
    }

    final batch = _firestore.batch();
    batch.delete(depenseRef);
    if (entrepriseId.isNotEmpty) {
      batch.delete(_refEcriture(entrepriseId, id));
    }
    await _valider(batch);

    // 📒 Journal « qui a fait quoi »
    final m = donnees?['montant'];
    unawaited(noterJournal(
      entrepriseId: entrepriseId,
      action: ActionsJournal.depense,
      details: 'Supprimée · ${_texteJournal(donnees)}',
      boutiqueId: _boutiqueJournal(donnees),
      montant: m is num ? m : null,
      reference: id,
    ));
  }
}

/// Provider du repository des dépenses
final depenseRepositoryProvider = Provider<DepenseRepository>((ref) {
  return DepenseRepository();
});

/// StreamProvider écoutant en temps réel les dépenses de l'entreprise courante
final depensesStreamProvider = StreamProvider<List<Depense>>((ref) {
  // On écoute uniquement 'entrepriseId' : le flux ne se relance pas
  // si d'autres champs du profil changent.
  final entrepriseId = ref.watch(
    userProfileProvider.select(
      (asyncProfile) => asyncProfile.value?.entrepriseId ?? '',
    ),
  );

  if (entrepriseId.isEmpty) {
    return Stream.value(const []);
  }

  return FirebaseFirestore.instance
      .collection('depenses')
      .where('entrepriseId', isEqualTo: entrepriseId)
      .orderBy('date', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => Depense.fromJson(doc.data(), doc.id))
          .toList());
});