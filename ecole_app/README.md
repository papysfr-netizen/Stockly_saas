# Gestion École

Application Flutter + Firebase de gestion d'établissement scolaire (Android, iOS, Web).

## Fonctionnalités

| Module | Contenu |
|---|---|
| **Tableau de bord** | Effectifs, encaissements du mois, reste à recouvrer, taux de présence du jour |
| **Élèves & classes** | Inscriptions (matricule automatique), fiches élèves, classes, matières et coefficients |
| **Frais de scolarité** | Encaissement, reçus PDF numérotés, journal par période, liste des impayés |
| **Notes & bulletins** | Saisie par matière et trimestre, moyennes pondérées, rangs, bulletins PDF |
| **Présences** | Appel quotidien (présent / retard / absent), historique par élève |
| **Enseignants** | Fiches, classes confiées, création de compte |
| **Espace parents** | Notes, absences et paiements de leurs enfants |

## Rôles

| Rôle | Accès |
|---|---|
| Direction (`admin`) | Tout |
| Secrétariat / comptable | Élèves, paiements, invitations de parents |
| Enseignant | Élèves, notes et appel **de ses classes uniquement** |
| Parent | Fiches, notes, absences et paiements **de ses enfants uniquement** |

Ces droits sont appliqués côté serveur par `firestore.rules`, pas seulement dans l'interface.

## Comment les comptes sont créés

1. Le fondateur crée un compte en cochant « Je crée une nouvelle école » : il devient Direction.
2. La direction ajoute le personnel (Paramètres → Inviter) et les enseignants (menu Enseignants, avec leur e-mail).
3. Le parent est invité automatiquement quand son e-mail est saisi sur la fiche de l'élève.
4. Chaque invité crée ensuite son compte avec **le même e-mail** et rejoint l'école avec le bon rôle.

## Mise en route

```bash
cd ecole_app
flutter pub get

# Lier à votre projet Firebase (remplace lib/firebase_options.dart)
dart pub global activate flutterfire_cli
flutterfire configure

# Dans la console Firebase : activer Authentication > E-mail/Mot de passe et Firestore.
# Puis déployer les règles et index :
firebase deploy --only firestore

flutter run            # mobile
flutter run -d chrome  # web
```

## Tests

```bash
flutter test                      # calculs (moyennes, rangs, impayés)
cd test_rules && npm install && npm test   # règles de sécurité Firestore (émulateur, Java requis)
```

## Structure des données (Firestore)

```
users/{uid}                         profil : rôle, ecoleId, classeIds (enseignant), eleveIds (parent)
invitations/{email}                 invitation en attente
ecoles/{ecoleId}                    nom, adresse, devise, année scolaire
  ├─ classes, matieres, enseignants
  ├─ eleves                         élèves (archivés avec actif = false)
  ├─ paiements                      non modifiables, annulables par la direction
  ├─ notes                          id = {eleve}_{matiere}_T{trimestre}
  ├─ presences                      une feuille d'appel par classe et par jour
  ├─ absences                       une fiche par absence/retard (lue par les parents)
  └─ meta/compteurs                 numérotation des matricules et des reçus
```
