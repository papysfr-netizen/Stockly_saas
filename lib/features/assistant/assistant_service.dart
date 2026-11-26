// ✨ « DEMANDEZ À NGULI » : le patron pose une question, l'IA répond avec SES chiffres
//
// Économe : à l'ouverture, on lit UNE fois les 30 derniers jours (ventes, dépenses)
// et ce qui est dû (dettes en cours). On en fait un petit résumé (quelques Ko),
// envoyé à l'IA avec chaque question. Le catalogue vient du flux déjà ouvert.
// Pas de téléphone de client dans le résumé : seulement les noms.
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ai/firebase_ai.dart';
// ThinkingConfig n'est pas encore exporté par firebase_ai 2.3.0
// ignore: implementation_imports
import 'package:firebase_ai/src/api.dart' show ThinkingConfig;

import '../../core/models/produit.dart';
import '../../core/services/argent_vente.dart';
import '../../core/services/photo_ia_service.dart';
import 'package:stockly_saas/core/services/protection_app.dart';

class AssistantService {
  AssistantService._();

  static const int jours = 30;

  static double _n(dynamic v) => v is num ? v.toDouble() : double.tryParse('${v ?? ''}') ?? 0.0;
  static double _r(double v) => (v * 100).roundToDouble() / 100;

  static DateTime? _date(dynamic d) {
    if (d is Timestamp) return d.toDate();
    if (d is DateTime) return d;
    if (d is String) return DateTime.tryParse(d);
    return null;
  }

  static String _jour(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static List<Map<String, dynamic>> _top(Map<String, double> m, int n, String cle, String valeur) {
    final liste = m.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return [for (final e in liste.take(n)) {cle: e.key, valeur: _r(e.value)}];
  }

  /// Résumé des chiffres de la boutique (pur : testable sans Firebase)
  static Map<String, dynamic> resumer({
    required DateTime maintenant,
    required List<Map<String, dynamic>> ventes,
    required List<Map<String, dynamic>> creances,
    required List<Map<String, dynamic>> dettesFournisseurs,
    required List<Map<String, dynamic>> depenses,
    required List<Produit> produits,
    Map<String, String> nomsBoutiques = const {},
    double tauxCDF = 0,
  }) {
    double ca = 0, cout = 0, encaisse = 0, credit = 0;
    final parJour = <String, double>{};
    final margeJour = <String, double>{};
    final parVendeur = <String, double>{};
    final parBoutique = <String, double>{};
    final qteProduit = <String, double>{};
    final caProduit = <String, double>{};
    final vendusParId = <String, double>{};
    var nombre = 0;

    for (final v in ventes) {
      final d = _date(v['date']);
      if (d == null) continue;
      final net = _n(v['montantTotal']) - _n(v['montantRetourne']) - _n(v['montantAnnule']);
      nombre++;
      ca += net;
      cout += ArgentVente.coutNet(v); // retours déduits, comme le Rapport
      credit += _n(v['resteAPayer']);
      encaisse += net - _n(v['resteAPayer']);
      parJour[_jour(d)] = (parJour[_jour(d)] ?? 0) + net;
      margeJour[_jour(d)] = (margeJour[_jour(d)] ?? 0) + net - ArgentVente.coutNet(v);
      final vendeur = (v['vendeurNom'] ?? '').toString();
      if (vendeur.isNotEmpty) parVendeur[vendeur] = (parVendeur[vendeur] ?? 0) + net;
      final b = (v['boutiqueId'] ?? '').toString();
      final nomB = nomsBoutiques[b] ?? (b.isEmpty || b == 'principale' ? 'Boutique principale' : b);
      parBoutique[nomB] = (parBoutique[nomB] ?? 0) + net;
      for (final a in (v['articles'] as List?) ?? const []) {
        if (a is! Map) continue;
        final nom = (a['nom'] ?? '').toString();
        final q = _n(a['quantite']);
        qteProduit[nom] = (qteProduit[nom] ?? 0) + q;
        caProduit[nom] = (caProduit[nom] ?? 0) + _n(a['prixUnitaire']) * q;
        final id = (a['produitId'] ?? '').toString();
        if (id.isNotEmpty) vendusParId[id] = (vendusParId[id] ?? 0) + q;
      }
    }

    // 📦 Stock : bas (avec jours restants au rythme des 30 jours), ruptures, dormants
    final faibles = <Map<String, dynamic>>[];
    final dormants = <Map<String, dynamic>>[];
    double valeurStock = 0;
    for (final p in produits) {
      valeurStock += p.quantite * p.prixAchat;
      final vendus = vendusParId[p.id] ?? 0;
      final parJourMoyen = vendus / jours;
      final joursRestants = parJourMoyen > 0 ? (p.quantite / parJourMoyen).floor() : null;
      if (p.quantite <= p.seuilAlerte || (joursRestants != null && joursRestants <= 10)) {
        faibles.add({
          'nom': p.nom,
          'stock': p.quantite,
          'vendus30j': vendus.round(),
          if (joursRestants != null) 'joursRestants': joursRestants,
        });
      }
      if (vendus == 0 && p.quantite > 0) {
        dormants.add({'nom': p.nom, 'stock': p.quantite, 'valeurAchat': _r(p.quantite * p.prixAchat)});
      }
    }
    faibles.sort((a, b) => ((a['joursRestants'] ?? 0) as int).compareTo((b['joursRestants'] ?? 0) as int));
    dormants.sort((a, b) => (b['valeurAchat'] as double).compareTo(a['valeurAchat'] as double));

    Map<String, dynamic> resumeDettes(List<Map<String, dynamic>> liste, String nomCle) {
      final parNom = <String, double>{};
      for (final c in liste) {
        final nom = (c[nomCle] ?? c['nomTiers'] ?? c['nomClient'] ?? '').toString();
        final reste = _n(c['montantReste'] ?? c['montantRestant']);
        if (reste <= 0.005) continue;
        parNom[nom] = (parNom[nom] ?? 0) + reste;
      }
      return {
        'total': _r(parNom.values.fold(0.0, (s, v) => s + v)),
        'nombre': parNom.length,
        'plusGros': _top(parNom, 15, 'nom', 'reste'),
      };
    }

    final parCategorie = <String, double>{};
    final depenseJour = <String, double>{};
    for (final d in depenses) {
      final c = (d['categorie'] ?? 'Autre').toString();
      parCategorie[c] = (parCategorie[c] ?? 0) + _n(d['montant']);
      final dd = _date(d['date']);
      if (dd != null) depenseJour[_jour(dd)] = (depenseJour[_jour(dd)] ?? 0) + _n(d['montant']);
    }

    // 📅 Totaux déjà calculés par période (l'IA n'a qu'à les lire, pas à additionner)
    final aujourdhui = DateTime(maintenant.year, maintenant.month, maintenant.day);
    final lundi = aujourdhui.subtract(Duration(days: aujourdhui.weekday - 1));
    Map<String, dynamic> periode(DateTime debut, DateTime fin) {
      double ventesP = 0, margeP = 0, depensesP = 0;
      for (var j = debut; !j.isAfter(fin); j = DateTime(j.year, j.month, j.day + 1)) {
        ventesP += parJour[_jour(j)] ?? 0;
        margeP += margeJour[_jour(j)] ?? 0;
        depensesP += depenseJour[_jour(j)] ?? 0;
      }
      return {
        'du': _jour(debut),
        'au': _jour(fin),
        'ventesNettes': _r(ventesP),
        'margeBrute': _r(margeP),
        'depenses': _r(depensesP),
        'beneficeNet': _r(margeP - depensesP),
      };
    }
    final debut30 = aujourdhui.subtract(const Duration(days: jours - 1));
    DateTime borne(DateTime d) => d.isBefore(debut30) ? debut30 : d;
    final periodes = {
      'aujourdhui': periode(aujourdhui, aujourdhui),
      'hier': periode(aujourdhui.subtract(const Duration(days: 1)), aujourdhui.subtract(const Duration(days: 1))),
      'cetteSemaine (depuis lundi)': periode(borne(lundi), aujourdhui),
      'semaineDerniere': periode(borne(lundi.subtract(const Duration(days: 7))), lundi.subtract(const Duration(days: 1))),
      '7derniersJours': periode(aujourdhui.subtract(const Duration(days: 6)), aujourdhui),
      'ceMois (depuis le 1er)': periode(borne(DateTime(aujourdhui.year, aujourdhui.month)), aujourdhui),
      '30derniersJours': periode(debut30, aujourdhui),
    };

    return {
      'aujourdhui': _jour(maintenant),
      'periode': 'les $jours derniers jours',
      'parPeriode': periodes,
      'devise': 'USD',
      if (tauxCDF > 0) 'taux': '1 USD = ${tauxCDF.round()} FC',
      'ventes': {
        'nombre': nombre,
        'chiffreAffairesNet': _r(ca),
        'coutMarchandises': _r(cout),
        'margeBrute': _r(ca - cout),
        'encaisse': _r(encaisse),
        'creditAccorde': _r(credit),
        'parJour': {for (final e in (parJour.entries.toList()..sort((a, b) => a.key.compareTo(b.key)))) e.key: _r(e.value)},
        'parVendeur': _top(parVendeur, 15, 'vendeur', 'montant'),
        'parBoutique': _top(parBoutique, 10, 'boutique', 'montant'),
        'produitsLesPlusVendus': [
          for (final e in (qteProduit.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).take(25))
            {'nom': e.key, 'quantite': e.value.round(), 'montant': _r(caProduit[e.key] ?? 0)},
        ],
      },
      'stock': {
        'nombreProduits': produits.length,
        'valeurAchat': _r(valeurStock),
        'aRecommander': faibles.take(30).toList(),
        'neBougentPas': dormants.take(20).toList(),
      },
      'clientsQuiDoivent': resumeDettes(creances, 'nomTiers'),
      'jeDoisAuxFournisseurs': resumeDettes(dettesFournisseurs, 'nomTiers'),
      'depenses': {
        'total': _r(parCategorie.values.fold(0.0, (s, v) => s + v)),
        'parCategorie': _top(parCategorie, 12, 'categorie', 'montant'),
      },
    };
  }

  /// Lit les données (une fois) et fabrique le résumé
  static Future<Map<String, dynamic>> charger({
    required String entrepriseId,
    required List<Produit> produits,
    Map<String, String> nomsBoutiques = const {},
    double tauxCDF = 0,
  }) async {
    final db = FirebaseFirestore.instance;
    final ent = db.collection('entreprises').doc(entrepriseId);
    final maintenant = DateTime.now();
    final debut = Timestamp.fromDate(DateTime(maintenant.year, maintenant.month, maintenant.day)
        .subtract(const Duration(days: jours - 1)));
    final res = await Future.wait<QuerySnapshot<Map<String, dynamic>>?>([
      ent.collection('ventes').where('date', isGreaterThanOrEqualTo: debut).get(),
      ent.collection('creances').where('montantReste', isGreaterThan: 0).get(),
      ent.collection('dettes').where('montantReste', isGreaterThan: 0).get(),
      // Dépenses : réservées au gérant / patron (sinon : liste vide, pas d'erreur)
      db
          .collection('depenses')
          .where('entrepriseId', isEqualTo: entrepriseId)
          .orderBy('date', descending: true) // même index que l'écran Dépenses
          .where('date', isGreaterThanOrEqualTo: debut)
          .get()
          .then<QuerySnapshot<Map<String, dynamic>>?>((s) => s, onError: (_) => null),
    ]);
    List<Map<String, dynamic>> donnees(QuerySnapshot<Map<String, dynamic>>? s) =>
        s == null ? const [] : [for (final d in s.docs) d.data()];
    return resumer(
      maintenant: maintenant,
      ventes: donnees(res[0]),
      creances: donnees(res[1]),
      dettesFournisseurs: donnees(res[2]),
      depenses: donnees(res[3]),
      produits: produits,
      nomsBoutiques: nomsBoutiques,
      tauxCDF: tauxCDF,
    );
  }

  static String _langue(String code) => switch (code) {
        'en' => 'English',
        'sw' => 'Kiswahili (comme on le parle dans l\'Est de la RD Congo)',
        'ln' => 'Lingala',
        _ => 'français',
      };

  /// Consigne donnée à l'IA : langue, règles, et les données de la boutique
  static String _consigne(Map<String, dynamic> resume, String langue) => '''
Tu es l'assistant de gestion de Nguli, une application de caisse et de stock pour une boutique en RD Congo.
Tu réponds au patron, en ${_langue(langue)}, de façon courte, claire et polie (5 phrases au plus,
ou une petite liste). Les montants sont en dollars (\$) ; donne l'équivalent en francs si le taux est fourni
et que c'est utile.

Règles :
- Utilise UNIQUEMENT les données JSON ci-dessous (${resume['periode']}). N'invente aucun chiffre.
- Si la question porte sur une période ou une information absente, dis-le simplement.
- Pour « que recommander ? » : utilise stock.aRecommander (joursRestants = jours avant rupture au rythme actuel).
- Pour aujourd'hui, hier, cette semaine, la semaine dernière, 7 jours, ce mois : utilise parPeriode
  (déjà calculé : ventes nettes, marge brute, dépenses, bénéfice net = ce qui a été « gagné »).
- « Aujourd'hui » = ${resume['aujourdhui']}. Pour un autre jour précis : ventes.parJour.
- Pas de conseil juridique ou fiscal ; reste sur la gestion de la boutique.
- Écris du TEXTE SIMPLE, sans mise en forme markdown : pas d'astérisques (*), pas de #.
  Pour une liste, commence chaque ligne par « • ».

DONNÉES :
${jsonEncode(resume)}
''';

  /// 🎤 Question posée À VOIX HAUTE : l'IA écoute l'audio (français, anglais, swahili,
  /// lingala…), écrit la question entendue et y répond. Renvoie (question, réponse).
  static Future<(String, String)> demanderAudio({
    required Map<String, dynamic> resume,
    required Uint8List audio,
    required String mimeType,
    required String langue,
    List<(String, String)> historique = const [],
  }) async {
    GenerativeModel modelePour(String nom, bool sansReflexion) => ProtectionApp.ia().generativeModel(
      model: nom,
      systemInstruction: Content.system(_consigne(resume, langue)),
      generationConfig: GenerationConfig(
        temperature: 0.2,
        thinkingConfig: sansReflexion ? ThinkingConfig(thinkingBudget: 0) : null,
        responseMimeType: 'application/json',
        responseSchema: Schema.object(properties: {
          'question': Schema.string(),
          'reponse': Schema.string(),
        }),
      ),
    );
    final contenu = <Content>[
      ..._historique(historique),
      Content.multi([
        TextPart('La question du patron est dans cet audio (il peut parler français, anglais, '
            'swahili ou lingala, ou mélanger). Écris dans « question » ce que tu as entendu, '
            'dans sa langue, puis réponds dans « reponse » en suivant tes règles.'),
        InlineDataPart(mimeType, audio),
      ]),
    ];
    final reponse = await _essayer((nom, sansReflexion) =>
        modelePour(nom, sansReflexion).generateContent(contenu).timeout(const Duration(seconds: 40)));
    final donnees = jsonDecode((reponse.text ?? '{}').trim());
    if (donnees is! Map) return ('', '');
    return ((donnees['question'] ?? '').toString().trim(), (donnees['reponse'] ?? '').toString().trim());
  }

  /// Les 6 derniers échanges complets (une réponse vide serait refusée par l'IA)
  static List<Content> _historique(List<(String, String)> historique) {
    final complets = [for (final e in historique) if (e.$1.trim().isNotEmpty && e.$2.trim().isNotEmpty) e];
    final recents = complets.length > 6 ? complets.sublist(complets.length - 6) : complets;
    return [
      for (final (q, r) in recents) ...[
        Content.text(q),
        Content.model([TextPart(r)]),
      ],
    ];
  }

  /// Pose une question à l'IA avec le résumé ; [historique] = échanges précédents (question, réponse)
  ///
  /// ⚡ La réponse arrive AU FUR ET À MESURE (chaque élément = le texte reçu jusque-là),
  ///    sans « réflexion » préalable de l'IA : bien plus rapide pour ces questions simples.
  static Stream<String> demander({
    required Map<String, dynamic> resume,
    required String question,
    required String langue,
    List<(String, String)> historique = const [],
  }) async* {
    final contenu = <Content>[..._historique(historique), Content.text(question)];
    Object? derniere;
    for (final (nom, sansReflexion, attendre) in _tentatives()) {
      if (attendre) await Future<void>.delayed(const Duration(milliseconds: 1500));
      final model = ProtectionApp.ia().generativeModel(
        model: nom,
        systemInstruction: Content.system(_consigne(resume, langue)),
        generationConfig: GenerationConfig(
          temperature: 0.2,
          thinkingConfig: sansReflexion ? ThinkingConfig(thinkingBudget: 0) : null,
        ),
      );
      final morceaux = StringBuffer();
      try {
        await for (final r in model.generateContentStream(contenu).timeout(const Duration(seconds: 45))) {
          final texte = r.text;
          if (texte == null || texte.isEmpty) continue;
          morceaux.write(texte);
          yield morceaux.toString();
        }
        return;
      } catch (e) {
        // Déjà une partie de la réponse : on garde ce qu'on a
        if (morceaux.isNotEmpty || !_onPeutReessayer(e)) rethrow;
        derniere = e;
      }
    }
    throw derniere ?? StateError('IA indisponible');
  }

  /// 🔁 Ordre des essais : (modèle, sans réflexion ?, attendre avant ?).
  ///    Chaque modèle : d'abord « sans réflexion » (rapide) ; s'il refuse ce réglage
  ///    (« invalid argument »), le même modèle avec ses réglages par défaut.
  ///    Le premier modèle a droit à une 2e chance après 1,5 s (saturation passagère).
  static List<(String, bool, bool)> _tentatives() => [
        for (var i = 0; i < PhotoIaService.modelesAssistant.length; i++) ...[
          (PhotoIaService.modelesAssistant[i], true, false),
          (PhotoIaService.modelesAssistant[i], false, false),
          if (i == 0) (PhotoIaService.modelesAssistant[i], false, true),
        ],
      ];

  /// Erreur pour laquelle un autre essai a du sens
  static bool _onPeutReessayer(Object e) =>
      PhotoIaService.surcharge(e) || e.toString().toLowerCase().contains('invalid argument');

  static Future<T> _essayer<T>(Future<T> Function(String nom, bool sansReflexion) appel) async {
    Object? derniere;
    for (final (nom, sansReflexion, attendre) in _tentatives()) {
      if (attendre) await Future<void>.delayed(const Duration(milliseconds: 1500));
      try {
        return await appel(nom, sansReflexion);
      } catch (e) {
        if (!_onPeutReessayer(e)) rethrow;
        derniere = e;
      }
    }
    throw derniere ?? StateError('IA indisponible');
  }

  /// Raison courte d'un échec (affichée pour pouvoir corriger)
  static String raison(Object e) {
    var s = e.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
    if (s.length > 160) s = '${s.substring(0, 160)}…';
    return s;
  }
}
