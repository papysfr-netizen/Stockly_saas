import 'package:ecole_app/models/emploi_du_temps.dart';
import 'package:ecole_app/screens/emploi_du_temps/grille.dart';
import 'package:ecole_app/services/emploi_du_temps.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final creneaux = [
    const Creneau(id: '1', classeId: 'c', jour: 1, plage: '07:30-08:20', matiereId: 'fr', enseignantNom: 'Mme Kasongo'),
    const Creneau(id: '2', classeId: 'c', jour: 3, plage: '10:15-11:05', matiereId: 'ca', salle: 'B2'),
  ];

  Future<List<(int, String, Creneau?)>> afficher(WidgetTester tester, Size taille) async {
    tester.view.physicalSize = taille;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final taps = <(int, String, Creneau?)>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ListView(children: [
          GrilleEmploiDuTemps(
            jours: const [1, 2, 3, 4, 5],
            plages: plagesParDefaut,
            creneaux: creneaux,
            contenu: (c) => (titre: c.matiereId == 'fr' ? 'Français' : 'Calcul', detail: c.enseignantNom),
            onTap: (j, p, c) => taps.add((j, p, c)),
          ),
        ]),
      ),
    ));
    return taps;
  }

  testWidgets('grand écran : grille complète', (tester) async {
    final taps = await afficher(tester, const Size(1200, 900));
    expect(find.byType(Table), findsOneWidget);
    expect(find.text('Lundi'), findsOneWidget);
    expect(find.text('Vendredi'), findsOneWidget);
    expect(find.text('Français'), findsOneWidget);
    expect(find.text('Calcul'), findsOneWidget);
    await tester.tap(find.text('Français'));
    expect(taps.single.$1, 1);
    expect(taps.single.$3?.id, '1');
    expect(tester.takeException(), isNull);
  });

  testWidgets('téléphone : un onglet par jour', (tester) async {
    final taps = await afficher(tester, const Size(390, 844));
    expect(find.byType(Table), findsNothing);
    expect(find.byType(Tab), findsNWidgets(5));
    await tester.tap(find.text('Mercredi'));
    await tester.pumpAndSettle();
    expect(find.text('Calcul'), findsOneWidget);
    await tester.tap(find.text('Calcul'));
    expect(taps.single.$2, '10:15-11:05');
    expect(tester.takeException(), isNull);
  });
}
