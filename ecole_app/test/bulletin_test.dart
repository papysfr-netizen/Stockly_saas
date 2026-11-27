import 'dart:io';

import 'package:ecole_app/core/evaluation.dart';
import 'package:ecole_app/models/classe.dart';
import 'package:ecole_app/models/ecole.dart';
import 'package:ecole_app/models/eleve.dart';
import 'package:ecole_app/models/emploi_du_temps.dart';
import 'package:ecole_app/models/scolarite.dart';
import 'package:ecole_app/services/calculs.dart';
import 'package:ecole_app/services/pdf_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Génère des bulletins d'exemple. Avec BULLETIN_DIR=<dossier>, les PDF y sont écrits.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => initializeDateFormatting('fr_FR'));

  const ecole = Ecole(id: 'e', nom: 'Complexe scolaire Les Bâtisseurs', adresse: 'Av. Kasa-Vubu 12, Kinshasa/Kalamu',
      telephone: '+243 81 234 5678', anneeScolaire: '2026-2027');
  final eleve = Eleve(id: 'a', matricule: 'EL2026-00012', nom: 'MBUYI', prenom: 'Grâce', classeId: 'c', sexe: 'F',
      dateNaissance: DateTime(2015, 3, 14));

  Future<void> ecrire(String nom, Future<List<int>> f) async {
    final bytes = await f;
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    final dir = Platform.environment['BULLETIN_DIR'];
    if (dir != null) File('$dir/$nom.pdf').writeAsBytesSync(bytes);
  }

  test('bulletin primaire RD Congo', () async {
    const classe = Classe(id: 'c', nom: '5e A', cycle: Cycle.primaire, niveau: '5e année');
    const branches = [
      Matiere(id: 'fr', classeId: 'c', nom: 'Français', maxima: 40),
      Matiere(id: 'ca', classeId: 'c', nom: 'Calcul', maxima: 40),
      Matiere(id: 'li', classeId: 'c', nom: 'Lingala', maxima: 20),
      Matiere(id: 'ec', classeId: 'c', nom: 'Éducation civique et morale', maxima: 10),
      Matiere(id: 'ge', classeId: 'c', nom: 'Géographie', maxima: 10),
      Matiere(id: 'hi', classeId: 'c', nom: 'Histoire', maxima: 10),
    ];
    final periodes = periodesPour(SystemeEvaluation.rdc, Cycle.primaire).take(3); // 1er semestre seulement
    final notes = <Note>[];
    var k = 0;
    for (final e in ['a', 'b', 'c']) {
      for (final m in branches) {
        for (final p in periodes) {
          final max = m.maximaPour(p);
          final ratio = (e == 'a' ? 0.78 : e == 'b' ? 0.62 : 0.45) + (k++ % 5) * 0.03;
          notes.add(Note(id: '', eleveId: e, classeId: 'c', matiereId: m.id, periode: p.code,
              valeur: (max * ratio).roundToDouble(), sur: max));
        }
      }
    }
    await ecrire('bulletin_primaire', PdfService.bulletin(
      ecole: ecole, eleve: eleve, classe: classe, matieres: branches, eleveIds: ['a', 'b', 'c'],
      ev: Evaluations(notes), absences: 2,
      comportements: const [Comportement('a', 'P1', 'Très bon', 'Élite'), Comportement('a', 'P2', 'Bon', 'Très bon')],
    ));
  });

  test('bulletin maternelle', () async {
    const classe = Classe(id: 'c', nom: '3e maternelle', cycle: Cycle.maternelle);
    const branches = [
      Matiere(id: 'la', classeId: 'c', nom: 'Langage'),
      Matiere(id: 'gr', classeId: 'c', nom: 'Graphisme'),
      Matiere(id: 'ma', classeId: 'c', nom: 'Activités mathématiques'),
    ];
    final notes = [
      for (final (i, m) in branches.indexed)
        for (final p in ['P1', 'P2'])
          Note(id: '', eleveId: 'a', classeId: 'c', matiereId: m.id, periode: p, cote: ['A', 'ECA', 'NA'][(i + p.length) % 3], sur: 0),
    ];
    await ecrire('bulletin_maternelle', PdfService.bulletin(
      ecole: ecole, eleve: eleve, classe: classe, matieres: branches, eleveIds: ['a'],
      ev: Evaluations(notes), absences: 0, comportements: const [],
    ));
  });

  test("emploi du temps d'une classe", () async {
    final noms = {'fr': 'Français', 'ca': 'Calcul', 'li': 'Lingala', 'ec': 'Éducation civique'};
    final creneaux = [
      for (final (j, p, m) in [
        (1, '07:30-08:20', 'fr'), (1, '08:20-09:10', 'ca'), (2, '07:30-08:20', 'ca'), (2, '10:15-11:05', 'li'),
        (3, '07:30-08:20', 'fr'), (4, '09:10-10:00', 'ec'), (5, '11:55-12:45', 'li'),
      ])
        Creneau(id: '', classeId: 'c', jour: j, plage: p, matiereId: m, enseignantNom: m == 'li' ? 'M. Ilunga' : 'Mme Kasongo',
            salle: m == 'ca' ? 'B2' : ''),
    ];
    await ecrire('emploi_du_temps', PdfService.emploiDuTemps(
      ecole: ecole,
      titre: 'Emploi du temps — 5e A',
      creneaux: creneaux,
      contenu: (c) => (titre: noms[c.matiereId]!, detail: [c.enseignantNom, if (c.salle.isNotEmpty) 'Salle ${c.salle}'].join(' · ')),
    ));
  });
}
