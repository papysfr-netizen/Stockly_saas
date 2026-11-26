# Activer Firebase App Check (le jour de la publication sur le Play Store)

App Check garantit que **seule la vraie application Nguli** peut utiliser Firebase
(données et IA). Le code est prêt mais **éteint** : il s'allume avec
`--dart-define=APP_CHECK=true` lors de la fabrication.

## Étapes (dans l'ordre)

1. **Play Console** → Nguli → *Intégrité de l'application* : relier le projet Google Cloud
   de Firebase à l'API Play Integrity.
2. **Play Console** → *Intégrité de l'application* → *Signature d'application* :
   copier l'empreinte **SHA-256** de la clé de signature de Google Play.
3. **Console Firebase** → *Paramètres du projet* → application Android : ajouter cette
   empreinte SHA-256.
4. **Console Firebase** → *App Check* → *Applications* → Android : choisir
   **Play Integrity** et enregistrer.
5. Fabriquer la version Play Store avec `--dart-define=APP_CHECK=true`
   (Claude met à jour le fichier `.github/workflows/apk.yml`).
6. **Console Firebase** → *App Check* → *API* : regarder pendant **quelques jours**
   la part des demandes « vérifiées ». Ne rien bloquer tant que la plupart des
   utilisateurs n'ont pas la nouvelle version.
7. Puis cliquer **Appliquer** (*Enforce*) pour **Cloud Firestore**, **Authentication**
   et **Firebase AI Logic**. À partir de là, une application modifiée est refusée.

⚠️ Après l'étape 7, les APK installées « à la main » (hors Play Store) ne pourront
plus se connecter. Les testeurs doivent passer par le Play Store (test fermé).

## Pour tester sur ordinateur (développeur)

En mode débogage, l'application affiche un « jeton de débogage » dans les journaux :
l'ajouter dans *App Check → Applications → ⋮ → Gérer les jetons de débogage*.
