# Gestion École

Application Flutter + Firebase de gestion d'établissement scolaire (Android, iOS, Web),
conçue pour le système scolaire de la **RD Congo** (maternelle, primaire, secondaire).

## Fonctionnalités

| Module | Contenu |
|---|---|
| **Tableau de bord** | Effectifs, encaissements du mois, reste à recouvrer, taux de présence du jour |
| **Élèves & classes** | Inscriptions (matricule automatique), fiches élèves, classes par cycle, niveau et section/option, branches et maxima |
| **Frais de scolarité** | Encaissement, reçus PDF numérotés, journal par période, liste des impayés |
| **Import Excel** | Classes, branches, enseignants et élèves depuis un modèle, vérifiés avant tout enregistrement ; parents invités automatiquement |
| **Exports Excel** | Palmarès et notes d'une classe ; impayés, recouvrement par classe et journal des encaissements |
| **Rappels d'impayés** | SMS ou WhatsApp, un par un depuis le téléphone ou en masse via Twilio, avec historique |
| **Notes & bulletins** | Saisie par période et examen, totaux, pourcentages, places, application et conduite, bulletins PDF |
| **Emplois du temps** | Grille par classe (branche, enseignant, salle), vue par enseignant, conflits bloqués, volume horaire, impression PDF |
| **Absences & remplacements** | Absences d'enseignants, cours touchés calculés, remplaçants libres proposés, étude ou annulation, bilan par enseignant |
| **Suivi des absences** | Alerte immédiate au parent (SMS / WhatsApp), justifications (école ou parent), élèves à suivre, bilan Excel |
| **Présences** | Appel quotidien (présent / retard / absent), historique par élève |
| **Enseignants** | Fiches, classes confiées, création de compte |
| **Espace parents** | Notes, absences et paiements de leurs enfants |

## Système d'évaluation (RD Congo)

| Élément | Fonctionnement |
|---|---|
| Périodes | 1re et 2e période + examen du 1er semestre ; 3e et 4e période + examen du 2e semestre |
| Points | Chaque branche a un **maxima** par période ; l'examen est noté sur **le double** |
| Résultats | Totaux par période, par semestre (TOT. S1, TOT. S2) et total général (T.G.), en pourcentage |
| Place | Rang dans la classe pour chaque colonne ; les ex æquo partagent la même place |
| Application / conduite | Élite, Très bon, Bon, Assez bon, Médiocre, Mauvais, saisies par période |
| Maternelle | Pas de points : cotes A (acquis), ECA (en cours d'acquisition), NA (non acquis), par période |
| Décision proposée | ≥ 50 % sans branche en échec : admis(e) ; ≥ 50 % avec branche(s) < 50 % : seconde session ; < 50 % : ajourné(e). À valider par le conseil de classe |

Le bulletin PDF reprend la présentation congolaise : branches, maxima, P1, P2, EX1, TOT. S1, P3, P4, EX2, TOT. S2, T.G.,
puis maxima généraux, totaux, pourcentage, place, application et conduite.

Un système « trimestres, notes sur 20 avec coefficients » reste disponible dans **Paramètres** pour d'autres pays.
Valeurs par défaut d'une nouvelle école : devise USD (modifiable en CDF), indicatif +243.

## Emplois du temps

- **Grille horaire** : Paramètres → une heure de cours par ligne (`07:30-08:20`…), récréation omise ; option samedi.
- **Saisie** (direction) : Emploi du temps → Par classe → toucher une case → branche, enseignant, salle.
  L'enseignant habituel de la branche est proposé par défaut.
- **Conflits bloqués** : un enseignant ou une salle déjà occupés au même moment dans une autre classe.
- **Consultation** : l'enseignant voit « Mon emploi du temps » (son compte est relié à sa fiche par l'e-mail
  ou le téléphone), le parent voit celui de la classe sur la fiche de son enfant, le secrétariat voit tout.
- **Volume horaire** hebdomadaire par branche (classe) et total par enseignant ; **impression PDF** A4 paysage.
- Sur téléphone, affichage jour par jour ; sur grand écran, grille complète.

## Absences d'enseignants et remplacements

1. **Déclarer** (direction ou secrétariat) : Absences & remplacements → Absences déclarées → *Déclarer une absence*
   (enseignant, du… au…, motif, justifiée). Les cours touchés sont calculés à partir de l'emploi du temps
   et enregistrés « à pourvoir ».
2. **Traiter, jour par jour** : onglet *Remplacements du jour* → toucher un cours → choisir :
   - un **remplaçant** parmi les enseignants **libres à cette heure** (ni en cours, ni absents, ni déjà en remplacement),
     les plus pertinents d'abord : enseigne la même branche, connaît la classe, puis le moins chargé ce jour ;
   - **étude surveillée** ou **cours annulé**.
3. **Informer** : le remplaçant voit « Remplacements à assurer » dans son emploi du temps ; les parents voient
   « Changements à venir » dans l'emploi du temps de la classe ; le tableau de bord affiche les enseignants absents
   et les cours à pourvoir du jour.
4. **Bilan** par enseignant : jours d'absence, cours touchés, cours non assurés.

**Prévenir le remplaçant** :
- *automatiquement* (Paramètres → « Prévenir automatiquement les remplaçants » : SMS ou WhatsApp) : dès qu'un
  remplaçant est désigné, la Cloud Function `notifierRemplacant` lui envoie le message ; s'il perd le cours
  (autre remplaçant, étude, annulation, absence supprimée), il reçoit une annulation. Le résultat
  (envoyé, échec, pas de numéro) s'affiche sous le cours ; l'historique est dans `notifications` ;
- *manuellement* : icône d'envoi sur un cours remplacé → SMS ou WhatsApp s'ouvre avec le message rédigé.

Le numéro utilisé est celui de la fiche enseignant. Pour WhatsApp hors fenêtre de 24 h, créez deux modèles
approuvés et renseignez `TWILIO_WHATSAPP_REMPLACEMENT_SID` et `TWILIO_WHATSAPP_ANNULATION_SID`
(variables `{{1}}` enseignant, `{{2}}` date, `{{3}}` heure, `{{4}}` classe, `{{5}}` branche, `{{6}}` école).

Supprimer une absence supprime aussi ses remplacements. Si l'emploi du temps change après la déclaration,
supprimez puis redéclarez l'absence pour recalculer les cours touchés.

## Absences des élèves (école buissonnière)

1. **Alerte immédiate au parent** : Paramètres → « Prévenir le parent dès que son enfant est noté absent » (SMS ou
   WhatsApp). Dès l'enregistrement de l'appel, la Cloud Function `alerterParentAbsence` envoie au parent :
   « Bonjour M. Kabeya, KABEYA Jean (5e année A) est noté(e) absent(e) le lundi 30/11. Merci de contacter l'école
   ou de justifier l'absence. » Le résultat (prévenu, échec, pas de numéro) s'affiche sur l'écran d'appel.
   Les retards ne déclenchent pas d'alerte. Sans Twilio : bouton d'envoi sur l'écran d'appel (SMS / WhatsApp du téléphone).
2. **Justification** : la direction ou le secrétariat justifie une absence (motif, remarque) depuis la fiche de
   l'élève. Le parent peut proposer une justification depuis son espace ; l'école l'accepte ou la refuse
   (Suivi des absences → Justificatifs). Refaire l'appel n'efface pas une justification.
3. **Élèves à suivre** : au-delà d'un seuil (3 par défaut, réglable) d'absences **non justifiées** sur 30 jours,
   l'élève apparaît dans Suivi des absences → Élèves à suivre, avec le contact du parent, et au tableau de bord.
4. **Bilan** : par mois ou sur l'année, par classe ; export Excel (par élève, par classe, détail).
   Le bulletin indique « Absences : X (dont Y non justifiées) · Retards : Z ».

Modèle WhatsApp facultatif : `TWILIO_WHATSAPP_ABSENCE_SID` (variables `{{1}}` parent, `{{2}}` élève,
`{{3}}` classe, `{{4}}` date, `{{5}}` école).

## Import depuis Excel

Paramètres → **Importer depuis Excel** (direction) :
1. *Télécharger le modèle* : feuilles Mode d'emploi, Classes, Branches, Enseignants, Élèves.
2. Le remplir (Excel, Google Sheets, WPS, LibreOffice…), une ligne par élément ; colonnes * obligatoires.
3. *Importer un fichier* : tout est vérifié **avant** d'écrire (champs obligatoires, classe inconnue, cycle,
   maxima, téléphone, e-mail, date, sexe, doublons). Les erreurs sont listées avec leur ligne Excel et rien n'est
   importé tant qu'il en reste ; les éléments déjà présents sont signalés et ignorés.
4. Après confirmation : matricules attribués automatiquement (sauf s'ils sont fournis), comptes des enseignants
   et invitations des parents créés ; frères et sœurs regroupés sous une même invitation.

## Logo et en-tête de chaque école

Chaque école configure les siens, sans intervention technique : Paramètres → Informations de l'école.
- **Logo** : *Choisir le logo* (PNG, JPEG, WebP…) ; l'image est réduite à 300 px et enregistrée dans la fiche de
  l'école. Il apparaît sur les bulletins, les reçus, les emplois du temps et en haut du menu.
- **Lignes d'en-tête officielles** (une par ligne : ministère, province éducationnelle, sous-division…) et
  **code de l'école**, imprimés sous « République démocratique du Congo ».

## Apparence

Paramètres → Apparence : Automatique (selon le téléphone), Clair ou Sombre, mémorisé sur l'appareil.

## Exports Excel

| Export | Où | Contenu (une feuille par onglet) |
|---|---|---|
| **Palmarès et notes** | Notes & bulletins → Résultats → *Exporter* | **Palmarès** : place, matricule, élève, pourcentage par colonne (P1… T.G.), décision proposée, moyenne de la classe ; puis une feuille par période, semestre et total général : points par branche (avec maxima), total, maxima, pourcentage, place, application et conduite. Maternelle : une feuille de cotes par période |
| **Impayés** | Frais de scolarité → Impayés → *Exporter (Excel)* | **Impayés** : classe, élève, parent, téléphone, frais, payé, reste, dernier rappel ; **Par classe** : effectif, attendu, encaissé, reste, taux de recouvrement ; **Encaissements** : journal complet des reçus |

Les nombres sont de vraies valeurs (tri, filtres, formules possibles). Seules les périodes déjà notées ont leur feuille.
Sur le web, le fichier se télécharge ; sur téléphone, le menu de partage s'ouvre (WhatsApp, e-mail, Drive, Fichiers…).

## Rôles

| Rôle | Accès |
|---|---|
| Direction (`admin`) | Tout |
| Secrétariat / comptable | Élèves, paiements, invitations de parents |
| Enseignant | Élèves, notes et appel **de ses classes uniquement** |
| Parent | Fiches, notes, absences et paiements **de ses enfants uniquement** |

Ces droits sont appliqués côté serveur par `firestore.rules`, pas seulement dans l'interface.

## Comment les comptes sont créés

On se connecte **par numéro de téléphone** (code reçu par SMS) ou **par e-mail** et mot de passe.

1. Le fondateur se connecte puis choisit « Créer l'école » : il devient Direction.
2. La direction invite le personnel (Paramètres → Inviter, avec un e-mail **ou** un numéro) et les
   enseignants (menu Enseignants, avec leur e-mail et/ou leur téléphone).
3. Le parent est invité automatiquement quand son téléphone ou son e-mail est saisi sur la fiche de l'élève.
4. Chaque invité se connecte avec **ce numéro ou cet e-mail** et rejoint l'école avec le bon rôle.

Les numéros saisis sans indicatif utilisent celui du pays de l'école (Paramètres, +243 par défaut) : `081 234 5678` devient `+243812345678`.

## Rappels d'impayés

Depuis **Frais de scolarité → Impayés** (ou la fiche d'un élève), deux façons de relancer :

| Mode | Fonctionnement | Configuration |
|---|---|---|
| **Depuis ce téléphone** | Ouvre l'application SMS ou WhatsApp avec le message déjà rédigé ; l'utilisateur appuie sur Envoyer | Aucune, gratuit |
| **Automatique** | « Relancer tous par SMS / WhatsApp » envoie les messages via Twilio, sans intervention | Cloud Function + compte Twilio (voir ci-dessous) |

- Le texte du message se modifie dans **Paramètres** (variables `{parent}`, `{eleve}`, `{classe}`, `{montant}`, `{ecole}`).
- Un élève n'est pas relancé deux fois par le même canal en moins de 24 h (sauf si l'envoi précédent a échoué).
- Chaque rappel est enregistré ; la liste des impayés indique la date de la dernière relance.

### Activer l'envoi automatique (Twilio)

Les clés Twilio restent côté serveur (Cloud Function `functions/`) : elles ne sont jamais intégrées à l'application.
Le projet Firebase doit être au forfait **Blaze** (paiement à l'usage) pour déployer des fonctions.

```bash
cd ecole_app/functions && npm install
firebase functions:secrets:set TWILIO_ACCOUNT_SID
firebase functions:secrets:set TWILIO_AUTH_TOKEN
firebase deploy --only functions
# Au premier déploiement, Firebase demande :
#   TWILIO_SMS_FROM              numéro Twilio (+1…) ou Messaging Service (MG…) ; un « Sender ID »
#                                alphanumérique (nom de l'école) est possible dans de nombreux pays d'Afrique
#   TWILIO_WHATSAPP_FROM         numéro WhatsApp Business connecté à Twilio
#   TWILIO_WHATSAPP_CONTENT_SID  (facultatif) modèle WhatsApp approuvé, HX…
```

**WhatsApp :** Meta n'autorise un message libre que dans les 24 h suivant un message du parent.
Pour relancer à tout moment, créez dans Twilio (Content Template Builder) un modèle de catégorie
« Utility », faites-le approuver, et renseignez son identifiant dans `TWILIO_WHATSAPP_CONTENT_SID`.
Variables du modèle : `{{1}}` parent, `{{2}}` élève, `{{3}}` montant, `{{4}}` école.
Pour vos essais, le *WhatsApp Sandbox* de Twilio fonctionne sans modèle.

## Connexion par téléphone : configuration Firebase

1. Console Firebase → Authentication → Méthodes de connexion → activer **Téléphone** (et E-mail/Mot de passe).
2. **Android :** ajouter les empreintes SHA-1 et SHA-256 de la clé de signature dans les paramètres
   de l'application Android (`cd android && ./gradlew signingReport`), puis retélécharger la configuration.
3. **iOS :** activer les notifications push (APNs) ou le reCAPTCHA de secours, comme indiqué dans la documentation FlutterFire.
4. **Web :** ajouter le domaine du site dans Authentication → Paramètres → Domaines autorisés.
5. Pour tester sans envoyer de vrais SMS : Authentication → Téléphone → « Numéros de téléphone pour les tests ».

L'envoi des codes SMS de connexion est facturé par Firebase au-delà du quota gratuit (forfait Blaze).

## Démonstration (sans Firebase)

`lib/main_demo.dart` lance l'application réelle avec une **école fictive en mémoire**
(classes, élèves, notes, paiements, emplois du temps, absences d'enseignants) et un choix de rôle
à l'ouverture. Rien n'est enregistré ni envoyé.

```bash
flutter run -d chrome -t lib/main_demo.dart                       # en local
flutter build web -t lib/main_demo.dart --no-web-resources-cdn --pwa-strategy=none -o build/demo
```

La version web est autonome (moteur graphique et polices inclus). `demo_web/page.html` est la page
d'accueil utilisée pour la publier. La base en mémoire vient d'une copie corrigée de
`fake_cloud_firestore` (`third_party/`, voir `MODIFICATIONS.md`).

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
flutter test                      # calculs, bulletins PDF, exports Excel (relus après génération), rappels
cd test_rules && npm install && npm test   # règles de sécurité Firestore (émulateur, Java requis)
cd functions && npm test                    # logique des rappels (numéros, messages, appel Twilio simulé)
cd functions && npm run test:emulateur      # Cloud Functions de bout en bout : rappels, notifications de remplacement
```

## Structure des données (Firestore)

```
users/{uid}                         profil : e-mail/téléphone, rôle, ecoleId, classeIds, eleveIds
invitations/{email | +téléphone}    invitation en attente
ecoles/{ecoleId}                    nom, adresse, devise, année scolaire
  ├─ classes, matieres, enseignants
  ├─ eleves                         élèves (archivés avec actif = false)
  ├─ paiements                      non modifiables, annulables par la direction
  ├─ notes                          id = {eleve}_{branche}_{période} : points ou cote
  ├─ comportements                  application et conduite par élève et par période
  ├─ creneaux                       emploi du temps : id = {classe}_{jour}_{heure}
  ├─ absencesEnseignants            absences déclarées (du… au…, motif)
  ├─ remplacements                  un cours touché par date : à pourvoir, remplacé, étude, annulé
  ├─ notifications                  SMS / WhatsApp envoyés aux remplaçants (écrit par le serveur)
  ├─ presences                      une feuille d'appel par classe et par jour
  ├─ absences                       une fiche par absence/retard (lue par les parents)
  ├─ rappels                        historique des rappels d'impayés (manuels et automatiques)
  └─ meta/compteurs                 numérotation des matricules et des reçus
```
