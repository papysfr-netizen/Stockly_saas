import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/format.dart';
import '../models/app_user.dart';
import '../models/classe.dart';
import '../models/ecole.dart';
import '../models/emploi_du_temps.dart';
import '../models/remplacement.dart';
import '../models/eleve.dart';
import '../models/scolarite.dart';

/// Accès aux données d'une école : `ecoles/{ecoleId}/...`
class SchoolRepository {
  SchoolRepository(this._db, this.ecoleId);
  final FirebaseFirestore _db;
  final String ecoleId;

  DocumentReference<Map<String, dynamic>> get _ecole => _db.collection('ecoles').doc(ecoleId);
  CollectionReference<Map<String, dynamic>> _col(String name) => _ecole.collection(name);

  // ---------------- École ----------------
  Stream<Ecole> ecole() => _ecole.snapshots().map(Ecole.fromDoc);
  Future<void> majEcole(Ecole e) => _ecole.set(e.toMap(), SetOptions(merge: true));

  // ---------------- Classes & matières ----------------
  Stream<List<Classe>> classes() =>
      _col('classes').orderBy('nom').snapshots().map((s) => s.docs.map(Classe.fromDoc).toList());

  Future<void> enregistrerClasse(Classe c) => c.id.isEmpty
      ? _col('classes').add(c.toMap())
      : _col('classes').doc(c.id).set(c.toMap(), SetOptions(merge: true));

  Future<void> supprimerClasse(String id) => _col('classes').doc(id).delete();

  Stream<List<Matiere>> matieres(String classeId) => _col('matieres')
      .where('classeId', isEqualTo: classeId)
      .snapshots()
      .map((s) => s.docs.map(Matiere.fromDoc).toList()..sort((a, b) => a.nom.compareTo(b.nom)));

  Future<void> enregistrerMatiere(Matiere m) => m.id.isEmpty
      ? _col('matieres').add(m.toMap())
      : _col('matieres').doc(m.id).set(m.toMap(), SetOptions(merge: true));

  /// Noms de toutes les branches de l'école (id → nom).
  Stream<Map<String, String>> nomsMatieres() => _col('matieres')
      .snapshots()
      .map((s) => {for (final d in s.docs) d.id: (d.data()['nom'] ?? '') as String});

  Future<void> supprimerMatiere(String id) => _col('matieres').doc(id).delete();

  // ---------------- Élèves ----------------
  Stream<List<Eleve>> eleves({String? classeId}) {
    Query<Map<String, dynamic>> q = _col('eleves').where('actif', isEqualTo: true);
    if (classeId != null) q = q.where('classeId', isEqualTo: classeId);
    return q.snapshots().map((s) => s.docs.map(Eleve.fromDoc).toList()
      ..sort((a, b) => a.nomComplet.compareTo(b.nomComplet)));
  }

  Stream<Eleve?> eleve(String id) =>
      _col('eleves').doc(id).snapshots().map((d) => d.exists ? Eleve.fromDoc(d) : null);

  Future<String> enregistrerEleve(Eleve e) async {
    if (e.id.isNotEmpty) {
      await _col('eleves').doc(e.id).set(e.toMap(), SetOptions(merge: true));
      return e.id;
    }
    final ref = _col('eleves').doc();
    final matricule = e.matricule.isNotEmpty ? e.matricule : await _prochainNumero('matricule', 'EL');
    await ref.set(Eleve(
      id: ref.id,
      matricule: matricule,
      nom: e.nom,
      prenom: e.prenom,
      classeId: e.classeId,
      dateNaissance: e.dateNaissance,
      sexe: e.sexe,
      parentNom: e.parentNom,
      parentTelephone: e.parentTelephone,
      parentEmail: e.parentEmail,
    ).toMap());
    return ref.id;
  }

  /// Retire l'élève des listes sans effacer son historique.
  Future<void> archiverEleve(String id) => _col('eleves').doc(id).update({'actif': false});

  /// Donne au parent l'accès à la fiche de l'élève, pour chacun de ses
  /// identifiants (e-mail en minuscules, téléphone en E.164) : met à jour son
  /// compte s'il existe déjà, sinon crée/complète une invitation.
  Future<void> lierParent({
    required List<String> identifiants,
    required String nom,
    required String eleveId,
  }) async {
    for (final id in identifiants.where((i) => i.isNotEmpty)) {
      final compte = await _compte(id);
      if (compte != null) {
        await compte.update({'eleveIds': FieldValue.arrayUnion([eleveId])});
        continue;
      }
      await _db.collection('invitations').doc(id).set({
        'identifiant': id,
        'nom': nom,
        'role': Role.parent.name,
        'ecoleId': ecoleId,
        'eleveIds': FieldValue.arrayUnion([eleveId]),
        'creeLe': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  /// Compte de l'école dont l'e-mail ou le téléphone vaut [identifiant].
  Future<DocumentReference<Map<String, dynamic>>?> _compte(String identifiant) async {
    final champ = identifiant.startsWith('+') ? 'telephone' : 'email';
    final r = await _db
        .collection('users')
        .where('ecoleId', isEqualTo: ecoleId)
        .where(champ, isEqualTo: identifiant)
        .limit(1)
        .get();
    return r.docs.isEmpty ? null : r.docs.first.reference;
  }

  // ---------------- Enseignants & comptes ----------------
  Stream<List<Enseignant>> enseignants() => _col('enseignants')
      .orderBy('nom')
      .snapshots()
      .map((s) => s.docs.map(Enseignant.fromDoc).toList());

  /// Enregistre l'enseignant et, pour son e-mail et/ou son téléphone, lui
  /// donne un compte (ou met à jour ses classes s'il en a déjà un).
  Future<void> enregistrerEnseignant(Enseignant e, {required List<String> identifiants}) async {
    final ref = e.id.isEmpty ? _col('enseignants').doc() : _col('enseignants').doc(e.id);
    await ref.set(e.toMap(), SetOptions(merge: true));
    for (final id in identifiants.where((i) => i.isNotEmpty)) {
      final compte = await _compte(id);
      if (compte != null) {
        await compte.update({'classeIds': e.classeIds});
      } else {
        await inviter(Invitation(
          identifiant: id,
          nom: e.nomComplet,
          role: Role.enseignant,
          ecoleId: ecoleId,
          classeIds: e.classeIds,
        ));
      }
    }
  }

  Future<void> supprimerEnseignant(String id) => _col('enseignants').doc(id).delete();

  Future<void> inviter(Invitation inv) =>
      _db.collection('invitations').doc(inv.identifiant).set(inv.toMap());

  Stream<List<Invitation>> invitations() => _db
      .collection('invitations')
      .where('ecoleId', isEqualTo: ecoleId)
      .snapshots()
      .map((s) => s.docs.map((d) => Invitation.fromMap(d.id, d.data())).toList());

  Future<void> annulerInvitation(String identifiant) =>
      _db.collection('invitations').doc(identifiant).delete();

  Stream<List<AppUser>> utilisateurs() => _db
      .collection('users')
      .where('ecoleId', isEqualTo: ecoleId)
      .snapshots()
      .map((s) => s.docs.map(AppUser.fromDoc).toList());

  // ---------------- Paiements ----------------
  Stream<List<Paiement>> paiements({String? eleveId}) {
    Query<Map<String, dynamic>> q = _col('paiements');
    if (eleveId != null) q = q.where('eleveId', isEqualTo: eleveId);
    return q.snapshots().map((s) =>
        s.docs.map(Paiement.fromDoc).toList()..sort((a, b) => b.date.compareTo(a.date)));
  }

  Future<Paiement> encaisser(Paiement p) async {
    final ref = _col('paiements').doc();
    final numero = await _prochainNumero('recu', 'R');
    final complet = Paiement(
      id: ref.id,
      eleveId: p.eleveId,
      classeId: p.classeId,
      montant: p.montant,
      motif: p.motif,
      mode: p.mode,
      date: p.date,
      recuNumero: numero,
      encaissePar: p.encaissePar,
    );
    await ref.set(complet.toMap());
    return complet;
  }

  Future<void> annulerPaiement(String id) => _col('paiements').doc(id).delete();

  // ---------------- Notes ----------------
  /// Toutes les évaluations d'une classe (toutes périodes).
  Stream<List<Note>> notesClasse(String classeId) => _col('notes')
      .where('classeId', isEqualTo: classeId)
      .snapshots()
      .map((s) => s.docs.map(Note.fromDoc).toList());

  Stream<List<Note>> notesEleve(String eleveId) => _col('notes')
      .where('eleveId', isEqualTo: eleveId)
      .snapshots()
      .map((s) => s.docs.map(Note.fromDoc).toList());

  /// Enregistre les points d'une branche pour une période ; `null` efface.
  Future<void> enregistrerNotes({
    required String classeId,
    required String matiereId,
    required String periode,
    required double sur,
    required Map<String, double?> valeurs,
  }) =>
      _ecrireNotes(matiereId, periode, valeurs.map((eleveId, v) => MapEntry(
          eleveId,
          v == null
              ? null
              : Note(id: '', eleveId: eleveId, classeId: classeId, matiereId: matiereId, periode: periode, valeur: v, sur: sur))));

  /// Enregistre les cotes (maternelle) d'une branche pour une période.
  Future<void> enregistrerCotes({
    required String classeId,
    required String matiereId,
    required String periode,
    required Map<String, String?> cotes,
  }) =>
      _ecrireNotes(matiereId, periode, cotes.map((eleveId, c) => MapEntry(
          eleveId,
          c == null
              ? null
              : Note(id: '', eleveId: eleveId, classeId: classeId, matiereId: matiereId, periode: periode, cote: c, sur: 0))));

  Future<void> _ecrireNotes(String matiereId, String periode, Map<String, Note?> notes) async {
    final batch = _db.batch();
    notes.forEach((eleveId, n) {
      final ref = _col('notes').doc(Note.docId(eleveId, matiereId, periode));
      n == null ? batch.delete(ref) : batch.set(ref, n.toMap());
    });
    await batch.commit();
  }

  // ---------------- Application & conduite ----------------
  Stream<List<Comportement>> comportementsClasse(String classeId) => _col('comportements')
      .where('classeId', isEqualTo: classeId)
      .snapshots()
      .map((s) => s.docs.map(Comportement.fromDoc).toList());

  Stream<List<Comportement>> comportementsEleve(String eleveId) => _col('comportements')
      .where('eleveId', isEqualTo: eleveId)
      .snapshots()
      .map((s) => s.docs.map(Comportement.fromDoc).toList());

  Future<void> enregistrerComportements({
    required String classeId,
    required String periode,
    required Map<String, ({String application, String conduite})> valeurs,
  }) async {
    final batch = _db.batch();
    valeurs.forEach((eleveId, v) {
      batch.set(_col('comportements').doc(Comportement.docId(eleveId, periode)), {
        'eleveId': eleveId,
        'classeId': classeId,
        'periode': periode,
        'application': v.application,
        'conduite': v.conduite,
      });
    });
    await batch.commit();
  }

  // ---------------- Emploi du temps ----------------
  /// Tous les créneaux de l'école (nécessaire pour détecter les conflits
  /// d'enseignants et de salles entre classes).
  Stream<List<Creneau>> creneaux() =>
      _col('creneaux').snapshots().map((s) => s.docs.map(Creneau.fromDoc).toList());

  Future<void> enregistrerCreneau(Creneau c) =>
      _col('creneaux').doc(Creneau.docId(c.classeId, c.jour, c.plage)).set(c.toMap());

  Future<void> supprimerCreneau(String id) => _col('creneaux').doc(id).delete();

  // ---------------- Absences d'enseignants & remplacements ----------------
  Stream<List<AbsenceEnseignant>> absencesEnseignants() => _col('absencesEnseignants')
      .snapshots()
      .map((s) => s.docs.map(AbsenceEnseignant.fromDoc).toList()..sort((a, b) => b.debut.compareTo(a.debut)));

  /// Enregistre l'absence et un remplacement « à pourvoir » par cours touché.
  /// Un cours déjà traité (par une absence qui se chevauche) n'est pas écrasé.
  Future<int> declarerAbsence(AbsenceEnseignant a, List<Remplacement> Function(String absenceId) cours) async {
    final ref = a.id.isEmpty ? _col('absencesEnseignants').doc() : _col('absencesEnseignants').doc(a.id);
    final touches = cours(ref.id);
    final existants = (await _col('remplacements').where('enseignantAbsentId', isEqualTo: a.enseignantId).get())
        .docs
        .map((d) => d.id)
        .toSet();
    final batch = _db.batch()..set(ref, {...a.toMap(), 'creeLe': FieldValue.serverTimestamp()});
    var n = 0;
    for (final r in touches.where((r) => !existants.contains(r.id))) {
      batch.set(_col('remplacements').doc(r.id), r.toMap());
      n++;
    }
    await batch.commit();
    return n;
  }

  /// Supprime l'absence et les remplacements qui en découlent.
  Future<void> supprimerAbsence(String id) async {
    final lies = await _col('remplacements').where('absenceId', isEqualTo: id).get();
    final batch = _db.batch()..delete(_col('absencesEnseignants').doc(id));
    for (final d in lies.docs) {
      batch.delete(d.reference);
    }
    await batch.commit();
  }

  Stream<List<Remplacement>> remplacementsDuJour(String jourIso) => _col('remplacements')
      .where('date', isEqualTo: jourIso)
      .snapshots()
      .map((s) => s.docs.map(Remplacement.fromDoc).toList()..sort((a, b) => a.plage.compareTo(b.plage)));

  /// Remplacements de toute l'année (bilans, compteurs).
  Stream<List<Remplacement>> remplacements() =>
      _col('remplacements').snapshots().map((s) => s.docs.map(Remplacement.fromDoc).toList());

  Stream<List<Remplacement>> remplacementsClasse(String classeId) => _col('remplacements')
      .where('classeId', isEqualTo: classeId)
      .snapshots()
      .map((s) => s.docs.map(Remplacement.fromDoc).toList());

  Stream<List<Remplacement>> remplacementsAssures(String enseignantId) => _col('remplacements')
      .where('remplacantId', isEqualTo: enseignantId)
      .snapshots()
      .map((s) => s.docs.map(Remplacement.fromDoc).toList());

  Future<void> deciderRemplacement(String id, StatutRemplacement statut, {Enseignant? remplacant}) =>
      _col('remplacements').doc(id).update({
        'statut': statut.name,
        'remplacantId': statut == StatutRemplacement.remplace ? remplacant!.id : null,
        'remplacantNom': statut == StatutRemplacement.remplace ? remplacant!.nomComplet : '',
      });

  // ---------------- Présences ----------------
  Stream<FeuillePresence?> feuillePresence(String classeId, DateTime date) => _col('presences')
      .doc(FeuillePresence.docId(classeId, date))
      .snapshots()
      .map((d) => d.exists ? FeuillePresence.fromDoc(d) : null);

  Stream<List<FeuillePresence>> presencesDuJour(DateTime date) => _col('presences')
      .where('jour', isEqualTo: isoDay(date))
      .snapshots()
      .map((s) => s.docs.map(FeuillePresence.fromDoc).toList());

  /// Enregistre l'appel et tient à jour une fiche d'absence par élève
  /// (`absences/`) — c'est elle que consultent les parents.
  Future<void> enregistrerPresences(FeuillePresence f, String saisiPar) async {
    final batch = _db.batch();
    batch.set(_col('presences').doc(FeuillePresence.docId(f.classeId, f.date)),
        {...f.toMap(), 'saisiPar': saisiPar});
    f.statuts.forEach((eleveId, statut) {
      final ref = _col('absences').doc('${FeuillePresence.docId(f.classeId, f.date)}_$eleveId');
      if (statut == StatutPresence.present) {
        batch.delete(ref);
      } else {
        batch.set(ref, {
          'eleveId': eleveId,
          'classeId': f.classeId,
          'date': Timestamp.fromDate(DateTime(f.date.year, f.date.month, f.date.day)),
          'statut': statut.name,
        });
      }
    });
    await batch.commit();
  }

  Stream<List<({DateTime date, StatutPresence statut})>> absencesEleve(String eleveId) =>
      _col('absences').where('eleveId', isEqualTo: eleveId).snapshots().map((s) => s.docs
          .map((d) => (
                date: (d['date'] as Timestamp).toDate(),
                statut: StatutPresenceX.parse(d['statut'] as String?),
              ))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date)));

  // ---------------- Rappels d'impayés ----------------
  /// Date du dernier rappel envoyé à chaque élève.
  Stream<Map<String, DateTime>> derniersRappels() => _col('rappels')
      .orderBy('date', descending: true)
      .limit(500)
      .snapshots()
      .map((s) {
        final r = <String, DateTime>{};
        for (final d in s.docs) {
          final date = readDate(d['date']);
          if (date != null) r.putIfAbsent(d['eleveId'] as String, () => date);
        }
        return r;
      });

  /// Trace un rappel envoyé depuis le téléphone (SMS / WhatsApp manuel).
  Future<void> noterRappelManuel({
    required String eleveId,
    required String canal,
    required String telephone,
    required double montant,
    required String par,
  }) =>
      _col('rappels').add({
        'eleveId': eleveId,
        'canal': canal,
        'mode': 'manuel',
        'telephone': telephone,
        'montant': montant,
        'statut': 'ouvert',
        'par': par,
        'date': FieldValue.serverTimestamp(),
      });

  // ---------------- Utilitaires ----------------
  Future<String> _prochainNumero(String compteur, String prefixe) async {
    final ref = _ecole.collection('meta').doc('compteurs');
    final n = await _db.runTransaction<int>((tx) async {
      final snap = await tx.get(ref);
      final courant = ((snap.data() ?? const {})[compteur] as num?)?.toInt() ?? 0;
      tx.set(ref, {compteur: courant + 1}, SetOptions(merge: true));
      return courant + 1;
    });
    return '$prefixe${DateTime.now().year}-${n.toString().padLeft(5, '0')}';
  }
}
