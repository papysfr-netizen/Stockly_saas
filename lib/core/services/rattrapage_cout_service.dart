// lib/core/services/rattrapage_cout_service.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../features/accounting/services/accounting_journal_service.dart';

/// Résultat du rattrapage, affiché à l'utilisateur.
class ResultatRattrapage {
  final int ventesAnalysees;
  final int ventesRattrapees;
  final double coutTotal;
  final int articlesSansPrix;
  final bool enAttenteReseau;

  const ResultatRattrapage({
    required this.ventesAnalysees,
    required this.ventesRattrapees,
    required this.coutTotal,
    required this.articlesSansPrix,
    required this.enAttenteReseau,
  });
}

/// Crée l'écriture « Sortie de stock » (603100 / 311000) des anciennes ventes
/// qui n'en ont pas encore. Peut être relancé sans risque : l'écriture porte
/// l'identifiant STK-{idVente}, donc une vente n'est jamais comptée deux fois.
class RattrapageCoutService {
  static double _num(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString().replaceAll(',', '.') ?? '') ?? 0.0;
  }

  /// Lecture serveur (15 s max), sinon mémoire du téléphone.
  static Future<QuerySnapshot<Map<String, dynamic>>> _lire(
      Query<Map<String, dynamic>> requete) async {
    try {
      return await requete.get().timeout(const Duration(seconds: 15));
    } catch (_) {
      return await requete.get(const GetOptions(source: Source.cache));
    }
  }

  static Future<ResultatRattrapage> executer(String entrepriseId) async {
    final firestore = FirebaseFirestore.instance;
    final entRef = firestore.collection('entreprises').doc(entrepriseId);

    // 1. Prix d'achat actuels des produits (par identifiant et par nom)
    final produitsSnap = await _lire(entRef.collection('produits'));
    final Map<String, double> prixParId = {};
    final Map<String, double> prixParNom = {};
    for (final doc in produitsSnap.docs) {
      final data = doc.data();
      final prix = _num(data['prixAchat']);
      prixParId[doc.id] = prix;
      final nom = (data['nom'] ?? '').toString().trim().toLowerCase();
      if (nom.isNotEmpty) prixParNom[nom] = prix;
    }

    // 2. Écritures « Sortie de stock » déjà existantes
    final ecrituresSnap = await _lire(entRef.collection('ecritures_comptables'));
    final Set<String> dejaFaites = ecrituresSnap.docs
        .map((d) => d.id)
        .where((id) => id.startsWith('STK-'))
        .toSet();

    // 3. Toutes les ventes
    final ventesSnap = await _lire(entRef.collection('ventes'));

    WriteBatch batch = firestore.batch();
    int operations = 0;
    final List<Future<void>> envois = [];

    int rattrapees = 0;
    int sansPrix = 0;
    double coutTotal = 0.0;

    for (final venteDoc in ventesSnap.docs) {
      if (dejaFaites.contains('STK-${venteDoc.id}')) continue;

      final data = venteDoc.data();
      final dynamic brut = data['articles'] ?? data['produits'] ?? data['items'];
      final List<dynamic> articles = brut is List ? brut : const [];

      double cout = 0.0;
      for (final a in articles) {
        if (a is! Map) continue;
        final qte = _num(a['quantite'] ?? a['quantity'] ?? a['qte']);
        double prix = _num(a['prixAchat']);
        if (prix <= 0) {
          final id = (a['produitId'] ?? a['productId'] ?? a['id'])?.toString();
          if (id != null) prix = prixParId[id] ?? 0.0;
        }
        if (prix <= 0) {
          final nom = (a['nom'] ?? a['name'] ?? '').toString().trim().toLowerCase();
          prix = prixParNom[nom] ?? 0.0;
        }
        if (prix <= 0) sansPrix++;
        cout += prix * qte;
      }

      if (cout <= 0) continue;

      final client = (data['nomClient'] ?? data['clientNom'] ?? 'Client Divers').toString();
      final dynamic dateBrute = data['date'] ?? data['createdAt'];
      final dateVente = dateBrute is Timestamp ? dateBrute : Timestamp.now();

      final stkRef = entRef.collection('ecritures_comptables').doc('STK-${venteDoc.id}');
      batch.set(stkRef, {
        'id': stkRef.id,
        'entrepriseId': entrepriseId,
        'reference': venteDoc.id,
        'description': 'Sortie de stock (coût des marchandises, rattrapage) - $client',
        'date': dateVente,
        'rattrapage': true,
        'lines': [
          {
            'accountCode': '603100',
            'accountLabel': AccountingJournalService.getAccountLabel('603100'),
            'debit': cout,
            'credit': 0.0,
          },
          {
            'accountCode': '311000',
            'accountLabel': AccountingJournalService.getAccountLabel('311000'),
            'debit': 0.0,
            'credit': cout,
          },
        ],
        'montantEncaisse': 0.0,
      });
      batch.update(venteDoc.reference, {'coutMarchandises': cout});
      operations += 2;

      rattrapees++;
      coutTotal += cout;

      // Firestore limite un lot à 500 opérations
      if (operations >= 400) {
        envois.add(batch.commit());
        batch = firestore.batch();
        operations = 0;
      }
    }

    if (operations > 0) envois.add(batch.commit());

    // Hors ligne : tout est gardé sur le téléphone et envoyé plus tard.
    bool enAttente = false;
    try {
      await Future.wait(envois).timeout(const Duration(seconds: 20));
    } on TimeoutException {
      enAttente = true;
      debugPrint('[Nguli] Rattrapage gardé sur le téléphone, envoi en attente du réseau');
    }

    return ResultatRattrapage(
      ventesAnalysees: ventesSnap.docs.length,
      ventesRattrapees: rattrapees,
      coutTotal: coutTotal,
      articlesSansPrix: sansPrix,
      enAttenteReseau: enAttente,
    );
  }
}