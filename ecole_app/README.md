# Gestion École

Application Flutter + Firebase de gestion d'établissement scolaire (Android, iOS, Web).

## Fonctionnalités

| Module | Contenu |
|---|---|
| **Tableau de bord** | Effectifs, encaissements du mois, reste à recouvrer, taux de présence du jour |
| **Élèves & classes** | Inscriptions (matricule automatique), fiches élèves, classes, matières et coefficients |
| **Frais de scolarité** | Encaissement, reçus PDF numérotés, journal par période, liste des impayés |
| **Rappels d'impayés** | SMS ou WhatsApp, un par un depuis le téléphone ou en masse via Twilio, avec historique |
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

On se connecte **par numéro de téléphone** (code reçu par SMS) ou **par e-mail** et mot de passe.

1. Le fondateur se connecte puis choisit « Créer l'école » : il devient Direction.
2. La direction invite le personnel (Paramètres → Inviter, avec un e-mail **ou** un numéro) et les
   enseignants (menu Enseignants, avec leur e-mail et/ou leur téléphone).
3. Le parent est invité automatiquement quand son téléphone ou son e-mail est saisi sur la fiche de l'élève.
4. Chaque invité se connecte avec **ce numéro ou cet e-mail** et rejoint l'école avec le bon rôle.

Les numéros saisis sans indicatif utilisent celui du pays de l'école (Paramètres, +225 par défaut).

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
cd functions && npm test                    # logique des rappels (numéros, messages, appel Twilio simulé)
cd functions && npm run test:emulateur      # Cloud Function de bout en bout (émulateur, CLI firebase requise)
```

## Structure des données (Firestore)

```
users/{uid}                         profil : e-mail/téléphone, rôle, ecoleId, classeIds, eleveIds
invitations/{email | +téléphone}    invitation en attente
ecoles/{ecoleId}                    nom, adresse, devise, année scolaire
  ├─ classes, matieres, enseignants
  ├─ eleves                         élèves (archivés avec actif = false)
  ├─ paiements                      non modifiables, annulables par la direction
  ├─ notes                          id = {eleve}_{matiere}_T{trimestre}
  ├─ presences                      une feuille d'appel par classe et par jour
  ├─ absences                       une fiche par absence/retard (lue par les parents)
  ├─ rappels                        historique des rappels d'impayés (manuels et automatiques)
  └─ meta/compteurs                 numérotation des matricules et des reçus
```
