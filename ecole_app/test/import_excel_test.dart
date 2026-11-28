import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';

import 'package:ecole_app/core/evaluation.dart';
import 'package:ecole_app/data/school_repository.dart';
import 'package:ecole_app/models/classe.dart';
import 'package:ecole_app/models/eleve.dart';
import 'package:ecole_app/services/import_excel.dart';
import 'package:excel/excel.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

/// Remplit le modèle officiel avec des lignes (chaînes ou nombres).
List<int> remplir(Map<String, List<List<Object?>>> lignes) {
  final x = Excel.decodeBytes(modeleImport());
  lignes.forEach((feuille, rows) {
    for (final r in rows) {
      x[feuille].appendRow([
        for (final v in r)
          switch (v) {
            null => null,
            int() => IntCellValue(v),
            double() => DoubleCellValue(v),
            DateTime() => DateCellValue.fromDateTime(v),
            _ => TextCellValue('$v'),
          },
      ]);
    }
  });
  final o = x.encode()!;
  final dir = Platform.environment['EXPORT_DIR'];
  if (dir != null) File('$dir/import_exemple.xlsx').writeAsBytesSync(o);
  return o;
}

PlanImport analyser(List<int> o, {List<Classe> classes = const [], List<Eleve> eleves = const []}) => analyserImport(o,
    classesExistantes: classes, branchesExistantes: const [], enseignantsExistants: const [], elevesExistants: eleves);

void main() {
  const existante = Classe(id: 'c6', nom: '6e A', cycle: Cycle.primaire, fraisScolarite: 320);

  test('le modèle vide se relit sans erreur', () {
    final x = Excel.decodeBytes(modeleImport());
    expect(x.tables.keys, containsAll(["Mode d'emploi", 'Classes', 'Branches', 'Enseignants', 'Élèves']));
    final p = analyser(modeleImport());
    expect(p.erreurs, isEmpty);
    expect(p.vide, isTrue);
    expect(p.importable, isFalse);
  });

  test('fichier invalide', () {
    expect(analyser([1, 2, 3]).erreurs.single.message, contains('pas un classeur Excel'));
  });

  test('analyse : créations, avertissements et erreurs avec leur ligne', () {
    final p = analyser(
      remplir({
        'Classes': [
          ['5e A', 'Primaire', '5e année', '', 300],
          ['2e humanité Sc', 'Secondaire', '2e humanité', 'Scientifique', '450,5'],
          ['6e A', '', '', '', ''], // existe déjà → avertissement
          ['7e B', 'Lycée', '', '', ''], // cycle inconnu
        ],
        'Branches': [
          ['5e A', 'Français', 40, null],
          ['5e A', 'Calcul', null, null], // maxima par défaut 10
          ['6e A', 'Lingala', 20, null], // classe existante
          ['8e Z', 'Anglais', 20, null], // classe inconnue
          ['5e A', 'Sciences', 'beaucoup', null], // maxima invalide
        ],
        'Enseignants': [
          ['kasongo', 'Marie', '081 234 5601', 'M.Kasongo@Ecole.cd', 'Titulaire', '5e A; 6e A'],
          ['ILUNGA', 'Jean', '12', '', '', ''], // téléphone invalide
        ],
        'Élèves': [
          ['5e A', 'mbuyi', 'Grâce', 'F', DateTime(2015, 3, 14), '', 'M. Mbuyi', '0812345678', ''],
          ['2e humanité Sc', 'MBUYI', 'Héritier', 'garçon', '02/05/2010', 'EL-99', 'M. Mbuyi', '0812345678', ''],
          ['5e A', 'KABEYA', 'Jean', 'X', '', '', '', '', ''], // sexe invalide
          ['5e A', 'NZUZI', 'Ruth', 'F', '31/02/2015', '', '', '', ''], // date impossible
          ['5e A', 'MBUYI', 'Grâce', 'F', '', '', '', '', ''], // doublon dans le fichier → avertissement
        ],
      }),
      classes: [existante],
    );
    expect(p.classes.map((c) => (c.nom, c.cycle, c.fraisScolarite, c.section)), [
      ('5e A', Cycle.primaire, 300.0, ''),
      ('2e humanité Sc', Cycle.secondaire, 450.5, 'Scientifique'),
    ]);
    expect(p.branches.map((b) => (b.$1, b.$2.nom, b.$2.maxima)), [('5e A', 'Français', 40.0), ('5e A', 'Calcul', 10.0), ('6e A', 'Lingala', 20.0)]);
    expect(p.enseignants.single.enseignant.nom, 'KASONGO');
    expect(p.enseignants.single.classesNoms, ['5e A', '6e A']);
    expect(p.enseignants.single.identifiants, ['m.kasongo@ecole.cd', '+243812345601']);
    expect(p.eleves.map((e) => '${e.eleve.nomComplet} ${e.eleve.sexe} ${e.classeNom}'),
        ['MBUYI Grâce F 5e A', 'MBUYI Héritier M 2e humanité Sc', 'NZUZI Ruth F 5e A']);
    expect(p.eleves[1].eleve.dateNaissance, DateTime(2010, 5, 2));
    expect(p.erreurs.map((e) => e.toString()), [
      'Classes, ligne 5 : cycle « Lycée » inconnu (Maternelle, Primaire ou Secondaire)',
      'Branches, ligne 5 : classe « 8e Z » inconnue (ajoutez-la dans la feuille Classes)',
      'Branches, ligne 6 : maxima « beaucoup » invalide',
      'Enseignants, ligne 3 : téléphone « 12 » invalide',
      'Élèves, ligne 4 : sexe « X » : indiquez M ou F',
      'Élèves, ligne 5 : date de naissance « 31/02/2015 » invalide (format 30/11/2015)',
    ]);
    expect(p.avertissements.map((e) => e.toString()), [
      'Classes, ligne 4 : « 6e A » existe déjà : elle est conservée telle quelle',
      'Élèves, ligne 6 : MBUYI Grâce est déjà inscrit(e) en 5e A : ignoré(e)',
    ]);
    expect(p.importable, isFalse);
  });

  test('import réel : écritures, matricules, enseignants et parents regroupés', () async {
    final db = FakeFirebaseFirestore();
    await db.collection('ecoles').doc('e').set({'nom': 'Test', 'indicatif': '+243'});
    await db.collection('ecoles').doc('e').collection('classes').doc('c6').set(existante.toMap());
    await db.collection('ecoles').doc('e').collection('meta').doc('compteurs').set({'matricule': 41});
    final repo = SchoolRepository(db, 'e');

    final plan = analyser(
      remplir({
        'Classes': [['5e A', 'Primaire', '5e année', '', 300]],
        'Branches': [['5e A', 'Français', 40, null], ['6e A', 'Calcul', 40, null]],
        'Enseignants': [['KASONGO', 'Marie', '0812345601', '', 'Titulaire', '5e A']],
        'Élèves': [
          ['5e A', 'MBUYI', 'Grâce', 'F', '', '', 'M. Mbuyi', '0812345678', ''],
          ['6e A', 'MBUYI', 'David', 'M', '', '', 'M. Mbuyi', '081 234 5678', ''], // même parent
          ['6e A', 'KABEYA', 'Jean', 'M', '', 'EL-PERSO-1', '', '', ''],
        ],
      }),
      classes: [existante],
    );
    expect(plan.erreurs, isEmpty);
    expect(plan.importable, isTrue);

    final etapes = <String>[];
    final r = await repo.appliquerImport(plan, progression: etapes.add);
    expect(r, (classes: 1, branches: 2, enseignants: 1, eleves: 3, parents: 1));
    expect(etapes.first, 'Classes…');

    final classes = await repo.classes().first;
    final id5 = classes.firstWhere((c) => c.nom == '5e A').id;
    final eleves = await repo.eleves().first;
    expect(eleves.map((e) => (e.nomComplet, e.classeId == id5 ? '5e A' : e.classeId)).toSet(),
        {('MBUYI Grâce', '5e A'), ('MBUYI David', 'c6'), ('KABEYA Jean', 'c6')});
    final annee = DateTime.now().year;
    expect(eleves.map((e) => e.matricule).toSet(), {'EL$annee-00042', 'EL$annee-00043', 'EL-PERSO-1'});
    expect((await db.doc('ecoles/e/meta/compteurs').get()).data()!['matricule'], 43);

    expect((await repo.matieres(id5).first).single.nom, 'Français');
    final ens = (await repo.enseignants().first).single;
    expect(ens.classeIds, [id5]);
    expect((await db.doc('invitations/+243812345601').get()).data()!['role'], 'enseignant');

    // Les deux enfants Mbuyi sous une seule invitation parent.
    final inv = (await db.doc('invitations/+243812345678').get()).data()!;
    expect(inv['role'], 'parent');
    expect((inv['eleveIds'] as List).length, 2);
  });

  test('fichier écrit avec des chemins internes absolus (autres logiciels)', () {
    // Reproduit un classeur enregistré par un autre logiciel (ex. openpyxl).
    final zip = ZipDecoder().decodeBytes(remplir({
      'Classes': [['5e A', 'Primaire', '', '', 300]],
    }));
    final sortie = Archive();
    for (final f in zip.files) {
      if (f.name == 'xl/_rels/workbook.xml.rels') {
        final t = utf8.decode(f.content as List<int>).replaceAll('Target="worksheets/', 'Target="/xl/worksheets/');
        expect(t, contains('Target="/xl/worksheets/'));
        final b = utf8.encode(t);
        sortie.addFile(ArchiveFile(f.name, b.length, b));
      } else if (f.name.startsWith('xl/worksheets/')) {
        // Case vide écrite comme un texte sans contenu, ajoutée à la 2e ligne.
        final avecVide = utf8
            .decode(f.content as List<int>)
            .replaceFirstMapped(RegExp(r'(<row r="2"[^>]*>)'), (m) => '${m[1]}<c r="Z2" t="inlineStr"/>');
        final b = utf8.encode(avecVide);
        sortie.addFile(ArchiveFile(f.name, b.length, b));
      } else {
        sortie.addFile(f);
      }
    }
    final absolu = ZipEncoder().encode(sortie)!;
    expect(() => Excel.decodeBytes(absolu), throwsA(anything)); // la lecture brute échoue…
    final p = analyser(absolu); // … mais l'import le lit
    expect(p.erreurs, isEmpty);
    expect(p.classes.single.nom, '5e A');
    expect(analyser([1, 2, 3]).erreurs.single.toString(), "Ce fichier n'est pas un classeur Excel (.xlsx) lisible.");
  });
}
