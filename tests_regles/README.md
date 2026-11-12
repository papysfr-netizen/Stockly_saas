# Tests des règles de sécurité Firestore

Ces tests vérifient automatiquement `../firestore.rules` : chaque test joue un
personnage (patron, gérant, caissier, concurrent…) qui essaie une action, et
contrôle que le serveur l'accepte ou la refuse.

**À lancer avant chaque envoi de nouvelles règles sur Firebase.**

## Lancer les tests

Il faut Node.js et Java installés.

```bash
cd tests_regles
npm install      # la première fois seulement
npm test
```

Le résultat se termine par `# pass 28` / `# fail 0` quand tout va bien.
Les lignes `PERMISSION_DENIED` affichées pendant les tests sont normales :
ce sont les tentatives que les règles doivent refuser.
