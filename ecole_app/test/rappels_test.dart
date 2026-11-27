import 'package:ecole_app/core/telephone.dart';
import 'package:ecole_app/services/rappels.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR'));

  test('normalisation des numéros (mêmes cas que functions/test)', () {
    expect(normaliserTelephone('07 07 12 34 56', indicatif: '+225'), '+2250707123456');
    expect(normaliserTelephone('77 123 45 67', indicatif: '+221'), '+221771234567');
    expect(normaliserTelephone('06 12 34 56 78', indicatif: '+33'), '+33612345678');
    expect(normaliserTelephone('00225 0707123456'), '+2250707123456');
    expect(normaliserTelephone('+229 97 00 00 00'), '+22997000000');
    expect(normaliserTelephone('081 234 5678'), '+243812345678'); // RD Congo par défaut
    expect(normaliserTelephone('abc'), isNull);
    expect(normaliserTelephone(''), isNull);
  });

  test('message de rappel', () {
    final m = messageRappel(
      modele: 'Bonjour {parent}, {eleve} ({classe}) : {montant}. {ecole} {inconnu}',
      parent: '',
      eleve: 'KONE Awa',
      classe: 'CM2',
      montant: 125000,
      devise: 'CDF',
      ecole: 'Les Lauriers',
    );
    expect(m, 'Bonjour cher parent, KONE Awa (CM2) : 125 000 CDF. Les Lauriers {inconnu}');
    expect(messageRappel(modele: '', parent: 'M. Kone', eleve: 'A', classe: 'B', montant: 1, devise: 'F', ecole: 'E'),
        startsWith('Bonjour M. Kone'));
  });

  test('liens SMS et WhatsApp', () {
    expect(lienRappel(CanalRappel.sms, '+2250707123456', 'Bonjour à vous').toString(),
        'sms:+2250707123456?body=Bonjour%20%C3%A0%20vous');
    expect(lienRappel(CanalRappel.whatsapp, '+2250707123456', 'Reste 5 000 FCFA & merci').toString(),
        'https://wa.me/2250707123456?text=Reste%205%20000%20FCFA%20%26%20merci');
  });
}
