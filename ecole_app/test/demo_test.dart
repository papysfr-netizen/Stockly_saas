import 'package:ecole_app/data/school_repository.dart';
import 'package:ecole_app/demo/donnees_demo.dart';
import 'package:ecole_app/models/remplacement.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR'));

  test("l'école de démonstration se remplit sans erreur", () async {
    final db = FakeFirebaseFirestore();
    await remplirEcoleDemo(db, maintenant: DateTime(2026, 11, 30)); // un lundi
    final repo = SchoolRepository(db, ecoleDemo);
    expect(await repo.classes().first, hasLength(4));
    expect(await repo.eleves().first, hasLength(24));
    expect((await repo.notesClasse('p5A').first).length, 7 * 7 * 3);
    expect(await repo.creneaux().first, isNotEmpty);
    final remp = await repo.remplacementsDuJour('2026-11-30').first;
    expect(remp, isNotEmpty);
    expect(remp.where((r) => r.statut == StatutRemplacement.remplace), hasLength(1));
    expect(remp.where((r) => r.statut == StatutRemplacement.aPourvoir), isNotEmpty);
  });
}
