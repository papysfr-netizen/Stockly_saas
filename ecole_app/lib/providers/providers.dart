import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../data/rappel_repository.dart';
import '../data/school_repository.dart';
import '../models/app_user.dart';
import '../models/classe.dart';
import '../models/ecole.dart';
import '../models/eleve.dart';
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

final notesClasseProvider = StreamProvider.family<List<Note>, (String, int)>(
    (ref, k) => ref.watch(schoolRepoProvider).notesClasse(k.$1, k.$2));

final absencesEleveProvider = StreamProvider.family(
    (ref, String eleveId) => ref.watch(schoolRepoProvider).absencesEleve(eleveId));

final enseignantsProvider =
    StreamProvider<List<Enseignant>>((ref) => ref.watch(schoolRepoProvider).enseignants());

final presencesDuJourProvider = StreamProvider<List<FeuillePresence>>(
    (ref) => ref.watch(schoolRepoProvider).presencesDuJour(DateTime.now()));

final rappelRepoProvider = Provider(
    (ref) => RappelRepository(FirebaseFunctions.instanceFor(region: 'europe-west1')));

final derniersRappelsProvider =
    StreamProvider<Map<String, DateTime>>((ref) => ref.watch(schoolRepoProvider).derniersRappels());
