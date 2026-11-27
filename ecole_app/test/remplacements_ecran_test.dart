import 'package:ecole_app/data/school_repository.dart';
import 'package:ecole_app/models/app_user.dart';
import 'package:ecole_app/providers/providers.dart';
import 'package:ecole_app/screens/remplacements/remplacements_screen.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Parcours complet sur une base Firestore simulée : déclarer l'absence,
/// voir le cours à pourvoir, choisir un remplaçant proposé.
void main() {
  setUpAll(() => initializeDateFormatting('fr_FR'));

  testWidgets('déclarer une absence puis désigner un remplaçant', (tester) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final db = FakeFirebaseFirestore();
    final e = db.collection('ecoles').doc('e');
    await e.set({'nom': 'CS Test', 'systeme': 'rdc'});
    await e.collection('classes').doc('c5A').set({'nom': '5e A', 'cycle': 'primaire'});
    await e.collection('classes').doc('c6A').set({'nom': '6e A', 'cycle': 'primaire'});
    await e.collection('matieres').doc('fr5').set({'classeId': 'c5A', 'nom': 'Français', 'maxima': 20});
    await e.collection('matieres').doc('fr6').set({'classeId': 'c6A', 'nom': 'Français', 'maxima': 20});
    for (final (id, prenom, nom) in [('kas', 'Marie', 'KASONGO'), ('ilu', 'Jean', 'ILUNGA'), ('mbu', 'Paul', 'MBUYI')]) {
      await e.collection('enseignants').doc(id).set({'nom': nom, 'prenom': prenom, 'classeIds': []});
    }
    Future<void> cours(String id, String classe, int jour, String matiere, String prof) =>
        e.collection('creneaux').doc(id).set({'classeId': classe, 'jour': jour, 'plage': '07:30-08:20', 'matiereId': matiere, 'enseignantId': prof});
    await cours('k1', 'c5A', 1, 'fr5', 'kas'); // Kasongo : lundi 7:30 en 5e A
    await cours('i1', 'c6A', 1, 'fr6', 'ilu'); // Ilunga occupé lundi 7:30
    await cours('m1', 'c6A', 2, 'fr6', 'mbu'); // Mbuyi enseigne le français, libre le lundi

    await tester.pumpWidget(ProviderScope(
      overrides: [
        meProvider.overrideWithValue(const AppUser(uid: 'u', nom: 'Directeur', role: Role.admin, ecoleId: 'e')),
        schoolRepoProvider.overrideWithValue(SchoolRepository(db, 'e')),
        horlogeProvider.overrideWithValue(() => DateTime(2026, 11, 30)), // un lundi
      ],
      child: const MaterialApp(home: Scaffold(body: RemplacementsScreen())),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Aucun cours touché par une absence ce jour-là.'), findsOneWidget);

    // 1. Déclarer l'absence de Marie KASONGO pour aujourd'hui.
    await tester.tap(find.text('Absences déclarées'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Déclarer une absence'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Marie KASONGO').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Déclarer'));
    await tester.pumpAndSettle();
    expect(find.textContaining('1 cours à pourvoir'), findsWidgets);
    expect(find.textContaining('1 cours touché(s), 1 à pourvoir'), findsOneWidget);

    // 2. Le cours apparaît « à pourvoir » dans l'onglet du jour.
    await tester.tap(find.text('Remplacements du jour'));
    await tester.pumpAndSettle();
    expect(find.text('07:30-08:20 · 5e A · Français'), findsOneWidget);
    expect(find.textContaining('À pourvoir'), findsOneWidget);

    // 3. Seul Paul MBUYI est proposé (Ilunga est en cours), avec la bonne raison.
    await tester.tap(find.text('07:30-08:20 · 5e A · Français'));
    await tester.pumpAndSettle();
    expect(find.text('Paul MBUYI'), findsOneWidget);
    expect(find.text('Jean ILUNGA'), findsNothing);
    expect(find.textContaining('Enseigne cette branche'), findsOneWidget);
    await tester.tap(find.text('Paul MBUYI'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Remplacé par Paul MBUYI'), findsOneWidget);
    final doc = await e.collection('remplacements').doc('2026-11-30_k1').get();
    expect(doc.data()?['statut'], 'remplace');
    expect(doc.data()?['remplacantId'], 'mbu');

    // 4. La fonction serveur écrit le résultat de l'envoi : il s'affiche.
    await e.collection('remplacements').doc('2026-11-30_k1').update({
      'notification': {'statut': 'envoye', 'canal': 'sms', 'enseignantId': 'mbu'},
    });
    await tester.pumpAndSettle();
    expect(find.textContaining('SMS envoyé au remplaçant'), findsOneWidget);

    // 5. Prévenir manuellement est proposé.
    await tester.tap(find.byTooltip('Prévenir le remplaçant'));
    await tester.pumpAndSettle();
    expect(find.text('Prévenir par SMS (depuis ce téléphone)'), findsOneWidget);
    expect(find.text('Prévenir par WhatsApp (depuis ce téléphone)'), findsOneWidget);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    // 6. Changer d'avis efface le statut d'envoi (il concernait l'ancienne décision).
    await tester.tap(find.text('07:30-08:20 · 5e A · Français'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Étude surveillée'));
    await tester.pumpAndSettle();
    expect(find.textContaining('SMS envoyé'), findsNothing);
    expect((await e.collection('remplacements').doc('2026-11-30_k1').get()).data()!.containsKey('notification'), isFalse);
    expect(tester.takeException(), isNull);
  });
}
