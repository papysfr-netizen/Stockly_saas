import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stockly_saas/core/widgets/chargement_squelette.dart';
import 'package:stockly_saas/core/widgets/liste_paresseuse.dart';
import 'package:stockly_saas/core/widgets/recherche_differee.dart';

class _Recherche extends StatefulWidget {
  const _Recherche();
  @override
  State<_Recherche> createState() => _RechercheState();
}

class _RechercheState extends State<_Recherche> with RechercheDifferee<_Recherche> {
  String q = '';
  int filtrages = 0;
  @override
  Widget build(BuildContext context) => Column(children: [
        TextField(onChanged: (v) => differer(() => setState(() {
              q = v;
              filtrages++;
            }))),
        Text('q=$q n=$filtrages'),
      ]);
}

void main() {
  testWidgets('squelette : page entière, petite zone, colonne sans limite', (t) async {
    for (final w in [
      const ChargementSquelette(),
      const SizedBox(height: 80, child: ChargementSquelette(grille: true)),
      const SingleChildScrollView(child: Column(children: [ChargementSquelette()])),
    ]) {
      await t.pumpWidget(MaterialApp(home: Scaffold(body: w)));
      await t.pump(const Duration(milliseconds: 500));
      expect(t.takeException(), isNull);
    }
  });

  testWidgets('liste paresseuse : en-tête + seulement les lignes visibles', (t) async {
    var construites = 0;
    await t.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ListeParesseuse(
          avant: const [Text('En-tête')],
          elements: List.generate(500, (i) => i),
          construire: (_, i) {
            construites++;
            return SizedBox(height: 60, child: Text('Ligne $i'));
          },
          apres: const [Text('Fin')],
        ),
      ),
    ));
    expect(find.text('En-tête'), findsOneWidget);
    expect(find.text('Ligne 0'), findsOneWidget);
    expect(construites, lessThan(30)); // pas 500
  });

  testWidgets('recherche différée : un seul filtrage après la frappe', (t) async {
    await t.pumpWidget(const MaterialApp(home: Scaffold(body: _Recherche())));
    for (final s in ['r', 'ri', 'riz']) {
      await t.enterText(find.byType(TextField), s);
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('q= n=0'), findsOneWidget);
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('q=riz n=1'), findsOneWidget);
  });
}
