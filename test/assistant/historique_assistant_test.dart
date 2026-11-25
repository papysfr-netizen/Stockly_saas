import 'package:flutter_test/flutter_test.dart';
import 'package:stockly_saas/features/assistant/historique_assistant.dart';

void main() {
  test('historique : ajout, remplacement, ordre, discussions vides ignorées, maximum', () {
    var liste = <Discussion>[];
    liste = HistoriqueAssistant.fusionner(liste, const Discussion(1, [('Ventes ?', '120 \$')]));
    liste = HistoriqueAssistant.fusionner(liste, const Discussion(2, [('Stock ?', ''), ('Qui doit ?', 'Mama')]));
    // la même discussion continue : remplacée, pas dupliquée
    liste = HistoriqueAssistant.fusionner(liste, const Discussion(1, [('Ventes ?', '120 \$'), ('Hier ?', '40 \$')]));
    // discussion sans aucune réponse : pas enregistrée
    liste = HistoriqueAssistant.fusionner(liste, const Discussion(3, [('Rien', '')]));

    expect(liste.map((d) => d.id), [2, 1]);
    expect(liste.last.echanges.length, 2);
    expect(liste.first.echanges, [('Qui doit ?', 'Mama')]); // l'échange sans réponse est retiré
    expect(liste.first.titre, 'Qui doit ?');

    final relu = HistoriqueAssistant.decoder(HistoriqueAssistant.encoder(liste));
    expect(relu.map((d) => d.id), [2, 1]);
    expect(relu.last.echanges.last, ('Hier ?', '40 \$'));

    for (var i = 10; i < 50; i++) {
      liste = HistoriqueAssistant.fusionner(liste, Discussion(i, [('q', 'r')]));
    }
    expect(liste.length, HistoriqueAssistant.maximum);
    expect(liste.first.id, 49);
    expect(HistoriqueAssistant.decoder('pas du json'), isEmpty);
  });
}
