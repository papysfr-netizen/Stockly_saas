import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/evaluation.dart';
import '../core/telephone.dart';
import '../data/auth_repository.dart';
import '../data/rappel_repository.dart';
import '../data/school_repository.dart';
import '../models/absence_eleve.dart';
import '../models/app_user.dart';
import '../models/classe.dart';
import '../models/ecole.dart';
import '../models/eleve.dart';
import '../models/emploi_du_temps.dart';
import '../models/remplacement.dart';
import '../models/scolarite.dart';

final authRepoProvider = Provider(
    (ref) => AuthRepository(FirebaseAuth.instance, FirebaseFirestore.instance));

final authStateProvider = StreamProvider<User?>((ref) => ref.watch(authRepoProvider).authChanges());

final currentUserProvider = StreamProvider<AppUser?>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(null);
  return ref.watch(authRepoProvider).profil(user.uid);
});

/// Utilisateur connecté (à n'utiliser qu'une fois le profil chargé).
final meProvider = Provider<AppUser>((ref) => ref.watch(currentUserProvider).value!);

final schoolRepoProvider = Provider<SchoolRepository>(
    (ref) => SchoolRepository(FirebaseFirestore.instance, ref.watch(meProvider).ecoleId));

final ecoleProvider = StreamProvider<Ecole>((ref) => ref.watch(schoolRepoProvider).ecole());

/// Classes visibles par l'utilisateur (un enseignant ne voit que les siennes).
final classesProvider = StreamProvider<List<Classe>>((ref) {
  final me = ref.watch(meProvider);
  return ref
      .watch(schoolRepoProvider)
      .classes()
      .map((l) => l.where((c) => me.peutAccederClasse(c.id)).toList());
});

final toutesClassesProvider =
    StreamProvider<List<Classe>>((ref) => ref.watch(schoolRepoProvider).classes());

final matieresProvider = StreamProvider.family<List<Matiere>, String>(
    (ref, classeId) => ref.watch(schoolRepoProvider).matieres(classeId));

final elevesProvider = StreamProvider.family<List<Eleve>, String?>(
    (ref, classeId) => ref.watch(schoolRepoProvider).eleves(classeId: classeId));

final eleveProvider =
    StreamProvider.family<Eleve?, String>((ref, id) => ref.watch(schoolRepoProvider).eleve(id));

final paiementsProvider = StreamProvider.family<List<Paiement>, String?>(
    (ref, eleveId) => ref.watch(schoolRepoProvider).paiements(eleveId: eleveId));

final notesEleveProvider = StreamProvider.family<List<Note>, String>(
    (ref, eleveId) => ref.watch(schoolRepoProvider).notesEleve(eleveId));

final notesClasseProvider = StreamProvider.family<List<Note>, String>(
    (ref, classeId) => ref.watch(schoolRepoProvider).notesClasse(classeId));

final comportementsClasseProvider = StreamProvider.family<List<Comportement>, String>(
    (ref, classeId) => ref.watch(schoolRepoProvider).comportementsClasse(classeId));

final comportementsEleveProvider = StreamProvider.family<List<Comportement>, String>(
    (ref, eleveId) => ref.watch(schoolRepoProvider).comportementsEleve(eleveId));

/// Système d'évaluation de l'école (RD Congo par défaut).
final systemeProvider = Provider<SystemeEvaluation>(
    (ref) => ref.watch(ecoleProvider).valueOrNull?.systeme ?? SystemeEvaluation.rdc);

final absencesEleveProvider = StreamProvider.family<List<AbsenceEleve>, String>(
    (ref, eleveId) => ref.watch(schoolRepoProvider).absencesEleve(eleveId));

/// Absences de l'année scolaire en cours (depuis le 1er septembre).
final absencesAnneeProvider = StreamProvider<List<AbsenceEleve>>((ref) {
  final now = ref.watch(horlogeProvider)();
  final rentree = DateTime(now.month >= 9 ? now.year : now.year - 1, 9, 1);
  return ref.watch(schoolRepoProvider).absencesDepuis(rentree);
});

final enseignantsProvider =
    StreamProvider<List<Enseignant>>((ref) => ref.watch(schoolRepoProvider).enseignants());

final presencesDuJourProvider = StreamProvider<List<FeuillePresence>>(
    (ref) => ref.watch(schoolRepoProvider).presencesDuJour(DateTime.now()));

final rappelRepoProvider = Provider(
    (ref) => RappelRepository(FirebaseFunctions.instanceFor(region: 'europe-west1')));

final derniersRappelsProvider =
    StreamProvider<Map<String, DateTime>>((ref) => ref.watch(schoolRepoProvider).derniersRappels());

final creneauxProvider =
    StreamProvider<List<Creneau>>((ref) => ref.watch(schoolRepoProvider).creneaux());

/// Fiche enseignant correspondant au compte connecté (même e-mail ou même téléphone).
final monEnseignantProvider = Provider<Enseignant?>((ref) {
  final me = ref.watch(meProvider);
  if (me.role != Role.enseignant) return null;
  final indicatif = ref.watch(ecoleProvider).valueOrNull?.indicatif ?? '+243';
  final liste = ref.watch(enseignantsProvider).valueOrNull ?? const <Enseignant>[];
  return liste.where((e) {
    final mail = e.email.trim().toLowerCase();
    final tel = normaliserTelephone(e.telephone, indicatif: indicatif);
    return (mail.isNotEmpty && mail == me.email) || (tel != null && tel == me.telephone);
  }).firstOrNull;
});

final absencesEnseignantsProvider = StreamProvider<List<AbsenceEnseignant>>(
    (ref) => ref.watch(schoolRepoProvider).absencesEnseignants());

final remplacementsDuJourProvider = StreamProvider.family<List<Remplacement>, String>(
    (ref, jourIso) => ref.watch(schoolRepoProvider).remplacementsDuJour(jourIso));

final tousRemplacementsProvider =
    StreamProvider<List<Remplacement>>((ref) => ref.watch(schoolRepoProvider).remplacements());

final remplacementsClasseProvider = StreamProvider.family<List<Remplacement>, String>(
    (ref, classeId) => ref.watch(schoolRepoProvider).remplacementsClasse(classeId));

final remplacementsAssuresProvider = StreamProvider.family<List<Remplacement>, String>(
    (ref, enseignantId) => ref.watch(schoolRepoProvider).remplacementsAssures(enseignantId));

/// Noms de toutes les branches de l'école (id → nom), pour les écrans transversaux.
final nomsMatieresProvider =
    StreamProvider<Map<String, String>>((ref) => ref.watch(schoolRepoProvider).nomsMatieres());

/// Horloge (remplaçable dans les tests).
final horlogeProvider = Provider<DateTime Function()>((ref) => DateTime.now);
