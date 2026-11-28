import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image/image.dart' as img;

import '../core/evaluation.dart';
import '../core/format.dart';
import '../data/school_repository.dart';
import '../models/app_user.dart';
import '../models/remplacement.dart';
import '../models/scolarite.dart';
import '../services/emploi_du_temps.dart';
import '../services/remplacements.dart';

/// École fictive pour la démonstration. Toutes les données sont inventées.
const ecoleDemo = 'demo';

const _emailParent = 'parent.mbuyi@demo.cd';
const _emailKasongo = 'm.kasongo@demo.cd';

final utilisateursDemo = <Role, AppUser>{
  Role.admin: const AppUser(
      uid: 'u-direction', nom: 'Mme Nsimba (préfète)', role: Role.admin, ecoleId: ecoleDemo, email: 'direction@demo.cd'),
  Role.secretariat: const AppUser(
      uid: 'u-secretariat', nom: 'M. Kalala (économe)', role: Role.secretariat, ecoleId: ecoleDemo, email: 'econome@demo.cd'),
  Role.enseignant: const AppUser(
      uid: 'u-kasongo', nom: 'Marie KASONGO', role: Role.enseignant, ecoleId: ecoleDemo, email: _emailKasongo,
      classeIds: ['p5A']),
  Role.parent: const AppUser(
      uid: 'u-parent', nom: 'M. Mbuyi (parent)', role: Role.parent, ecoleId: ecoleDemo, email: _emailParent,
      eleveIds: ['p5A-1', 'h2S-2']),
};

/// Petit générateur déterministe : la démo est identique à chaque ouverture.
class _Alea {
  _Alea(this._x);
  int _x;
  double suivant() {
    _x = (_x * 1103515245 + 12345) & 0x7fffffff;
    return _x / 0x7fffffff;
  }
}

Future<void> remplirEcoleDemo(FirebaseFirestore db, {DateTime? maintenant}) async {
  final now = maintenant ?? DateTime.now();
  final e = db.collection('ecoles').doc(ecoleDemo);
  final repo = SchoolRepository(db, ecoleDemo);
  final alea = _Alea(42);

  await e.set({
    'nom': 'Complexe scolaire La Référence',
    'adresse': 'Av. de la Libération 45, Kinshasa/Lingwala',
    'telephone': '+243 81 000 0000',
    'devise': 'USD',
    'anneeScolaire': '2026-2027',
    'systeme': 'rdc',
    'indicatif': '+243',
    'plagesHoraires': plagesParDefaut,
    'samedi': false,
    'notificationRemplacement': 'sms',
    'alerteAbsence': 'sms',
    'seuilAbsences': 3,
    'proprietaire': 'u-direction',
    'enTete': "Ministère de l'Éducation\nProvince éducationnelle Kinshasa-Lukunga",
    'codeEcole': 'KIN-LUK-0457',
    'logo': base64Encode(logoDemo()),
  });
  for (final u in utilisateursDemo.values) {
    await db.collection('users').doc(u.uid).set(u.toMap());
  }

  // ---- Classes
  final classes = {
    'mat3': {'nom': '3e maternelle', 'cycle': 'maternelle', 'niveau': '3e maternelle', 'fraisScolarite': 250},
    'p5A': {'nom': '5e année A', 'cycle': 'primaire', 'niveau': '5e année', 'fraisScolarite': 300},
    'p6A': {'nom': '6e année A', 'cycle': 'primaire', 'niveau': '6e année', 'fraisScolarite': 320},
    'h2S': {
      'nom': '2e humanité Scientifique',
      'cycle': 'secondaire',
      'niveau': '2e humanité',
      'section': 'Scientifique',
      'fraisScolarite': 450
    },
  };
  for (final c in classes.entries) {
    await e.collection('classes').doc(c.key).set(c.value);
  }

  // ---- Branches (maxima par période ; l'examen vaut le double)
  const primaire = [
    ('fr', 'Français', 40), ('ca', 'Calcul', 40), ('li', 'Lingala', 20), ('sc', 'Sciences', 20),
    ('ge', 'Géographie', 10), ('hi', 'Histoire', 10), ('ec', 'Éducation civique et morale', 10),
  ];
  const humanites = [
    ('ma', 'Mathématiques', 50), ('ph', 'Physique', 40), ('ch', 'Chimie', 30), ('bi', 'Biologie', 30),
    ('fr', 'Français', 40), ('an', 'Anglais', 20),
  ];
  const maternelle = [('la', 'Langage', 10), ('gr', 'Graphisme', 10), ('am', 'Activités mathématiques', 10), ('ev', 'Éveil', 10)];
  final branches = {'mat3': maternelle, 'p5A': primaire, 'p6A': primaire, 'h2S': humanites};
  for (final c in branches.entries) {
    for (final (id, nom, max) in c.value) {
      await e.collection('matieres').doc('${c.key}-$id').set({'classeId': c.key, 'nom': nom, 'maxima': max, 'coefficient': 1});
    }
  }

  // ---- Enseignants
  const enseignants = [
    ('kas', 'KASONGO', 'Marie', '0812345601', _emailKasongo, 'Titulaire', ['p5A']),
    ('mbu', 'MBUYI', 'Paul', '0812345602', 'p.mbuyi@demo.cd', 'Titulaire', ['p6A']),
    ('tsh', 'TSHIBANDA', 'Rose', '0991234503', 'r.tshibanda@demo.cd', 'Mathématiques', ['h2S']),
    ('ilu', 'ILUNGA', 'Jean', '0991234504', 'j.ilunga@demo.cd', 'Physique', ['h2S']),
    ('luk', 'LUKUSA', 'Grâce', '0851234505', 'g.lukusa@demo.cd', 'Maternelle', ['mat3']),
  ];
  for (final (id, nom, prenom, tel, mail, spec, cls) in enseignants) {
    await e.collection('enseignants').doc(id).set(
        {'nom': nom, 'prenom': prenom, 'telephone': tel, 'email': mail, 'specialite': spec, 'classeIds': cls});
  }

  // ---- Élèves
  const noms = {
    'mat3': [('NGALULA', 'Divine', 'F'), ('KABAMBA', 'Josué', 'M'), ('MWAMBA', 'Merveille', 'F'), ('BOLAMBA', 'Christ', 'M'), ('KAPINGA', 'Exaucée', 'F')],
    'p5A': [('MBUYI', 'Grâce', 'F'), ('KABEYA', 'Jean', 'M'), ('NZUZI', 'Ruth', 'F'), ('MULUMBA', 'Patrick', 'M'), ('KAPEND', 'Sarah', 'F'), ('LUBOYA', 'David', 'M'), ('MASIKA', 'Esther', 'F')],
    'p6A': [('TSHILOMBO', 'Daniel', 'M'), ('KAZADI', 'Naomie', 'F'), ('MPIANA', 'Joël', 'M'), ('BIAYA', 'Rebecca', 'F'), ('NKULU', 'Samuel', 'M'), ('KALENGA', 'Prisca', 'F')],
    'h2S': [('ILUNGA', 'Benjamin', 'M'), ('MBUYI', 'Héritier', 'M'), ('MUJINGA', 'Sandra', 'F'), ('KANKU', 'Fiston', 'M'), ('MBOMBO', 'Gloria', 'F'), ('KAYEMBE', 'Cédric', 'M')],
  };
  var matricule = 0;
  final eleves = <String, List<String>>{};
  for (final c in noms.entries) {
    for (final (i, (nom, prenom, sexe)) in c.value.indexed) {
      final id = '${c.key}-${i + 1}';
      eleves.putIfAbsent(c.key, () => []).add(id);
      final parent = id == 'p5A-1' || id == 'h2S-2';
      await e.collection('eleves').doc(id).set({
        'matricule': 'EL2026-${(++matricule).toString().padLeft(5, '0')}',
        'nom': nom,
        'prenom': prenom,
        'sexe': sexe,
        'classeId': c.key,
        'dateNaissance': Timestamp.fromDate(DateTime(c.key == 'h2S' ? 2010 : c.key == 'mat3' ? 2021 : 2015, 1 + i, 3 + i * 3)),
        'parentNom': parent ? 'M. Mbuyi' : 'Parent de $prenom',
        'parentTelephone': '08${(1 + i % 5)}${(1234500 + matricule * 37).toString()}',
        'parentEmail': parent ? _emailParent : '',
        'actif': true,
        'dateInscription': Timestamp.fromDate(DateTime(2026, 9, 1)),
      });
    }
  }
  await e.collection('meta').doc('compteurs').set({'matricule': matricule});

  // ---- Notes du 1er semestre (P1, P2, examen) ; cotes en maternelle
  final periodes = periodesPour(SystemeEvaluation.rdc, Cycle.primaire).where((p) => p.semestre == 1);
  final batch = db.batch();
  for (final c in ['p5A', 'p6A', 'h2S']) {
    for (final (i, el) in eleves[c]!.indexed) {
      final niveau = 0.45 + (i * 0.37 % 1) * 0.45; // entre 45 % et 90 %
      for (final (bid, _, max) in branches[c]!) {
        for (final p in periodes) {
          final sur = p.examen ? max * 2.0 : max.toDouble();
          final v = (sur * (niveau + (alea.suivant() - 0.5) * 0.2)).clamp(0, sur).roundToDouble();
          batch.set(e.collection('notes').doc(Note.docId(el, '$c-$bid', p.code)), {
            'eleveId': el, 'classeId': c, 'matiereId': '$c-$bid', 'periode': p.code, 'valeur': v, 'sur': sur,
          });
        }
      }
      for (final p in ['P1', 'P2']) {
        const echelle = echelleComportement;
        batch.set(e.collection('comportements').doc(Comportement.docId(el, p)), {
          'eleveId': el, 'classeId': c, 'periode': p,
          'application': echelle[(i + p.length) % 4], 'conduite': echelle[i % 3],
        });
      }
    }
  }
  for (final (i, el) in eleves['mat3']!.indexed) {
    for (final (j, (bid, _, _)) in maternelle.indexed) {
      for (final p in ['P1', 'P2']) {
        batch.set(e.collection('notes').doc(Note.docId(el, 'mat3-$bid', p)), {
          'eleveId': el, 'classeId': 'mat3', 'matiereId': 'mat3-$bid', 'periode': p, 'sur': 0,
          'cote': const ['A', 'A', 'ECA', 'A', 'NA'][(i + j + p.length) % 5],
        });
      }
    }
  }
  await batch.commit();

  // ---- Paiements : soldés, partiels, rien payé
  var recu = 0;
  final modes = ['Espèces', 'M-Pesa', 'Airtel Money', 'Orange Money'];
  for (final c in classes.entries) {
    final frais = (c.value['fraisScolarite'] as int).toDouble();
    for (final (i, el) in eleves[c.key]!.indexed) {
      final part = const [1.0, 0.66, 0.33, 1.0, 0.0, 0.5, 0.66][i % 7];
      final tranches = part == 0 ? 0 : (part * 3).round();
      for (var t = 0; t < tranches; t++) {
        final date = DateTime(2026, 9 + t, 5 + i);
        await e.collection('paiements').add({
          'eleveId': el, 'classeId': c.key, 'montant': (frais / 3).roundToDouble(),
          'motif': 'Minerval — ${t + 1}${t == 0 ? 're' : 'e'} tranche', 'mode': modes[(i + t) % 4],
          'date': Timestamp.fromDate(date.isAfter(now) ? now : date),
          'recuNumero': 'R2026-${(++recu).toString().padLeft(5, '0')}', 'encaissePar': 'M. Kalala',
        });
      }
    }
  }
  await e.collection('meta').doc('compteurs').set({'recu': recu}, SetOptions(merge: true));
  await e.collection('rappels').add({
    'eleveId': 'p5A-5', 'canal': 'whatsapp', 'mode': 'manuel', 'telephone': '+243812345678', 'montant': 300.0,
    'statut': 'ouvert', 'par': 'M. Kalala', 'date': Timestamp.fromDate(now.subtract(const Duration(days: 3))),
  });

  // ---- Emplois du temps
  final profs = {'mat3': ['luk'], 'p5A': ['kas'], 'p6A': ['mbu'], 'h2S': ['tsh', 'ilu']};
  for (final c in branches.keys) {
    final bs = branches[c]!;
    var k = 0;
    for (final jour in [1, 2, 3, 4, 5]) {
      for (final (pi, plage) in plagesParDefaut.indexed) {
        if (c == 'mat3' && pi >= 4) continue; // la maternelle finit plus tôt
        if (c == 'p6A' && pi == 2) continue; // une heure libre
        final (bid, _, _) = bs[(k++ + jour) % bs.length];
        String prof;
        if (c == 'h2S') {
          prof = (bid == 'ma' || bid == 'an' || bid == 'bi') ? 'tsh' : 'ilu';
        } else {
          prof = profs[c]!.first;
        }
        final ens = enseignants.firstWhere((x) => x.$1 == prof);
        await e.collection('creneaux').doc('${c}_${jour}_${plage.replaceAll(':', '')}').set({
          'classeId': c, 'jour': jour, 'plage': plage, 'matiereId': '$c-$bid',
          'enseignantId': prof, 'enseignantNom': '${ens.$3} ${ens.$2}', 'salle': c == 'h2S' && bid == 'ch' ? 'Labo' : '',
        });
      }
    }
  }

  // ---- Appel du jour (si jour de cours)
  if (now.weekday <= 5) {
    await repo.enregistrerPresences(
      FeuillePresence(classeId: 'p5A', date: now, statuts: {
        for (final (i, el) in eleves['p5A']!.indexed)
          el: i == 3 ? StatutPresence.absent : i == 5 ? StatutPresence.retard : StatutPresence.present,
      }),
      'Marie KASONGO',
    );
  }

  // ---- Historique d'absences d'élèves (30 derniers jours de cours)
  final joursPasses = <DateTime>[];
  for (var d = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1)); joursPasses.length < 20;
      d = d.subtract(const Duration(days: 1))) {
    if (d.weekday <= 5) joursPasses.add(d);
  }
  Future<void> absenceEleve(String eleve, String classe, int ilYA,
      {bool justifiee = false, String motif = '', Map<String, dynamic>? parent, String statut = 'absent'}) async {
    final d = joursPasses[ilYA];
    await e.collection('absences').doc('${FeuillePresence.docId(classe, d)}_$eleve').set({
      'eleveId': eleve, 'classeId': classe, 'date': Timestamp.fromDate(d), 'jour': isoDay(d), 'statut': statut,
      if (justifiee) ...{'justifiee': true, 'motif': motif, 'justifiePar': 'M. Kalala'},
      if (parent != null) 'justificationParent': parent,
      if (statut == 'absent') 'alerte': {'statut': 'envoye', 'canal': 'sms'},
    });
  }
  // Deux élèves à suivre (absences répétées non justifiées).
  for (final j in [1, 4, 6, 11]) {
    await absenceEleve('p6A-3', 'p6A', j);
  }
  for (final j in [2, 3, 9]) {
    await absenceEleve('h2S-4', 'h2S', j);
  }
  // Absences justifiées, retards, justification de parent en attente.
  await absenceEleve('p5A-2', 'p5A', 5, justifiee: true, motif: 'Maladie');
  await absenceEleve('p5A-2', 'p5A', 6, justifiee: true, motif: 'Maladie');
  await absenceEleve('p6A-1', 'p6A', 2, statut: 'retard');
  await absenceEleve('p5A-6', 'p5A', 3, statut: 'retard');
  await absenceEleve('h2S-2', 'h2S', 2, parent: {'motif': 'Rendez-vous médical', 'message': 'Consultation à la clinique Ngaliema.'});
  await absenceEleve('p5A-1', 'p5A', 7); // le parent de démo peut la justifier lui-même

  // ---- Absence d'un enseignant le prochain jour de cours, avec remplacements
  var jourAbsence = DateTime(now.year, now.month, now.day);
  while (jourAbsence.weekday > 5) {
    jourAbsence = jourAbsence.add(const Duration(days: 1));
  }
  final creneaux = await repo.creneaux().first;
  final absence = AbsenceEnseignant(
    id: 'abs-ilunga',
    enseignantId: 'ilu',
    enseignantNom: 'Jean ILUNGA',
    debut: isoDay(jourAbsence),
    fin: isoDay(jourAbsence),
    motif: 'Formation',
    justifiee: true,
    note: 'Séminaire de physique au bureau de la sous-division',
  );
  await repo.declarerAbsence(absence, (id) => coursTouches(absence: absence, creneaux: creneaux, jours: [1, 2, 3, 4, 5]));
  final touches = await repo.remplacementsDuJour(isoDay(jourAbsence)).first;
  if (touches.isNotEmpty) {
    await e.collection('remplacements').doc(touches.first.id).update({
      'statut': 'remplace', 'remplacantId': 'tsh', 'remplacantNom': 'Rose TSHIBANDA',
      'notification': {'statut': 'envoye', 'canal': 'sms', 'enseignantId': 'tsh'},
    });
  }
  if (touches.length > 1) {
    await e.collection('remplacements').doc(touches[1].id).update({'statut': 'etude'});
  }
}

/// Écusson fictif pour la démonstration : cercle bleu, livre ouvert, initiales.
List<int> logoDemo() {
  final im = img.Image(width: 200, height: 200, numChannels: 4);
  final bleu = img.ColorRgba8(30, 90, 168, 255);
  final or = img.ColorRgba8(232, 180, 40, 255);
  final blanc = img.ColorRgba8(255, 255, 255, 255);
  img.fillCircle(im, x: 100, y: 100, radius: 96, color: or);
  img.fillCircle(im, x: 100, y: 100, radius: 88, color: bleu);
  // Livre ouvert
  img.fillRect(im, x1: 52, y1: 58, x2: 98, y2: 112, color: blanc);
  img.fillRect(im, x1: 102, y1: 58, x2: 148, y2: 112, color: blanc);
  for (var y = 68; y <= 102; y += 9) {
    img.drawLine(im, x1: 58, y1: y, x2: 92, y2: y, color: bleu);
    img.drawLine(im, x1: 108, y1: y, x2: 142, y2: y, color: bleu);
  }
  img.drawString(im, 'LR', font: img.arial48, x: 72, y: 120, color: or);
  return img.encodePng(im);
}
