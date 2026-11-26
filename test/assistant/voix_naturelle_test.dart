import 'package:flutter_test/flutter_test.dart';
import 'package:stockly_saas/features/assistant/voix_naturelle.dart';

void main() {
  test('choisirVoix : voix réseau française, jamais une voix non installée', () {
    final voix = [
      {'name': 'en-us-x-sfg-network', 'locale': 'en-US', 'quality': 'very high', 'network_required': '1', 'features': ''},
      {'name': 'fr-fr-x-frb-local', 'locale': 'fr-FR', 'quality': 'high', 'network_required': '0', 'features': ''},
      {'name': 'fr-fr-x-frc-network', 'locale': 'fr-FR', 'quality': 'very high', 'network_required': '1', 'features': ''},
      {'name': 'fr-fr-x-frd-network', 'locale': 'fr-FR', 'quality': 'very high', 'network_required': '1', 'features': 'notInstalled'},
      {'name': 'fr-ca-x-caa-network', 'locale': 'fr-CA', 'quality': 'very high', 'network_required': '1', 'features': ''},
    ];
    expect(VoixNaturelle.choisirVoix(voix, ['fr-FR', 'fr'])!['name'], 'fr-fr-x-frc-network');
    // hors connexion : la meilleure voix locale
    expect(VoixNaturelle.choisirVoix(voix, ['fr-FR', 'fr'], enLigne: false)!['name'], 'fr-fr-x-frb-local');
    expect(VoixNaturelle.choisirVoix(voix, ['sw-KE']), isNull);
    expect(VoixNaturelle.choisirVoix(const [], ['fr-FR']), isNull);
  });

  test('preparer : montants, milliers, puces et parenthèses', () {
    final s = VoixNaturelle.preparer(
        'Aujourd\'hui, votre bénéfice net est de 14,00 \$ (soit environ 34 160 FC).\n• Riz : 5 sacs\n• Huile 🛢️', 'fr');
    expect(s, contains('14 dollars'));
    expect(s, contains('34160 francs congolais'));
    expect(s, isNot(contains('•')));
    expect(s, isNot(contains('(')));
    expect(s, contains('Riz : 5 sacs.'));
    expect(s, endsWith('Huile.'));
    expect(VoixNaturelle.preparer('Sales: \$1,250.00', 'en'), contains('1,250 dollars'));
  });
}
