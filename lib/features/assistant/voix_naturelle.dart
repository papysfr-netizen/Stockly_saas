// 🗣️ Voix plus naturelle pour « Demandez à Nguli »
//
// 1. choisirVoix : parmi les voix installées sur le téléphone, prend la plus naturelle
//    (voix « réseau » de Google = neuronales, puis qualité très haute / haute),
//    dans la bonne langue, et jamais une voix « non installée ».
// 2. preparer : réécrit le texte pour l'oreille (puces, $, FC, milliers, émojis…)
//    — un moteur vocal qui lit « • 14,00 $ (34 160 FC) » sonne comme un robot.

class VoixNaturelle {
  VoixNaturelle._();

  static int _qualite(String q) => switch (q) {
        'very high' => 4,
        'high' => 3,
        'normal' => 2,
        'low' => 1,
        _ => 0,
      };

  /// [voix] : liste rendue par FlutterTts.getVoices ; [langues] : par ordre de préférence
  /// (ex. ['fr-FR', 'fr']). Renvoie {name, locale} à passer à setVoice, ou null.
  static Map<String, String>? choisirVoix(List<dynamic> voix, List<String> langues, {bool enLigne = true}) {
    Map<String, String>? meilleure;
    var meilleurScore = -1;
    for (final v in voix) {
      if (v is! Map) continue;
      final nom = (v['name'] ?? '').toString();
      final locale = (v['locale'] ?? '').toString().replaceAll('_', '-');
      if (nom.isEmpty || locale.isEmpty) continue;
      final features = (v['features'] ?? '').toString().toLowerCase();
      if (features.contains('notinstalled')) continue;
      final reseau = v['network_required'] == '1' || nom.toLowerCase().contains('network');
      if (reseau && !enLigne) continue;

      // Langue : correspondance exacte d'abord, puis même langue (fr-CA pour fr-FR…)
      var rangLangue = -1;
      for (var i = 0; i < langues.length; i++) {
        final l = langues[i].toLowerCase();
        final loc = locale.toLowerCase();
        if (loc == l) {
          rangLangue = (langues.length - i) * 2 + 1;
          break;
        }
        if (loc.split('-').first == l.split('-').first) {
          rangLangue = (langues.length - i) * 2;
          break;
        }
      }
      if (rangLangue < 0) continue;

      final score = rangLangue * 100 + (reseau ? 20 : 0) + _qualite((v['quality'] ?? '').toString()) * 4;
      if (score > meilleurScore) {
        meilleurScore = score;
        meilleure = {'name': nom, 'locale': (v['locale'] ?? '').toString()};
      }
    }
    return meilleure;
  }

  /// Texte réécrit pour être LU à voix haute dans [langue] ('fr', 'en', 'sw', 'ln')
  static String preparer(String texte, String langue) {
    final fr = langue != 'en' && langue != 'sw';
    final dollars = switch (langue) { 'en' => 'dollars', 'sw' => 'dola', _ => 'dollars' };
    final francs = switch (langue) { 'en' => 'Congolese francs', 'sw' => 'faranga za Kongo', _ => 'francs congolais' };

    var s = texte
        .replaceAll('**', '')
        .replaceAll(RegExp(r'^#+\s*', multiLine: true), '')
        // émojis et pictogrammes
        .replaceAll(RegExp(r'[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{2B00}-\u{2BFF}\u{FE0F}]', unicode: true), '')
        // puces → petite pause
        .replaceAll(RegExp(r'^\s*[•\-–]\s*', multiLine: true), '')
        // espaces de milliers (34 160 → 34160) : sinon « trente-quatre… cent soixante »
        .replaceAllMapped(RegExp(r'(\d)[\s  ](?=\d{3}\b)'), (m) => m[1]!)
        .replaceAllMapped(RegExp(r'(\d)[\s  ](?=\d{3}\b)'), (m) => m[1]!)
        // ,00 / .00 inutiles
        .replaceAll(RegExp(r'(?<=\d)[.,]00\b'), '');

    // Montants : « 14 $ », « $14 », « 14$ » → « 14 dollars » ; « 34160 FC » → « 34160 francs congolais »
    s = s
        .replaceAllMapped(RegExp(r'\$\s?(\d[\d.,]*)'), (m) => '${m[1]} $dollars')
        .replaceAllMapped(RegExp(r'(\d[\d.,]*)\s?\$'), (m) => '${m[1]} $dollars')
        .replaceAllMapped(RegExp(r'(\d[\d.,]*)\s?(FC|CDF|Fc)\b'), (m) => '${m[1]} $francs')
        .replaceAll(r'$', ' $dollars ');
    if (fr) s = s.replaceAll(RegExp(r'\bsoit environ\b'), 'soit à peu près');

    // Parenthèses → virgules (le moteur les lit mieux comme une incise)
    s = s.replaceAll('(', ', ').replaceAll(')', ', ');

    // Une ligne = une phrase (pause naturelle)
    final lignes = [
      for (final l in s.split('\n'))
        if (l.trim().isNotEmpty) l.trim(),
    ];
    s = lignes.map((l) => RegExp(r'[.!?:;,]$').hasMatch(l) ? l : '$l.').join(' ');
    return s
        .replaceAll(RegExp(r'\s*,\s*,'), ',')
        .replaceAll(RegExp(r',\s*\.'), '.')
        .replaceAllMapped(RegExp(r'\s+([.,!?])'), (m) => m[1]!)
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();
  }
}
