# Carte du code de Nguli

Ce document décrit ce que fait chaque partie de l'application, ce qui a déjà
été relu en détail, et les problèmes connus. Il est mis à jour à chaque
séance de relecture.

- **Code réel** : environ 34 000 lignes de Dart (`lib/`).
- **Traductions générées** : environ 15 000 lignes (`lib/l10n/app_localizations*.dart`).
  Elles sont produites automatiquement à partir des fichiers `.arb` :
  **ne jamais les modifier à la main**, modifier les `.arb` puis lancer `flutter gen-l10n`.

## Légende

- ✅ relu en entier
- 🟡 relu en partie (les fonctions principales)
- ⬜ pas encore relu

## Les modules

| Module | Fichiers | Lignes | Rôle | Relu |
|---|---:|---:|---|:---:|
| `lib/main.dart` | 1 | 479 | Démarrage, Firebase, hors ligne, langues, thème | 🟡 |
| `lib/views/caisse` | 5 | 2 790 | Caisse : produits, panier, prix négocié, **paiement** | ✅ |
| `lib/views/financial_analysis` | 5 | 2 638 | Rapport (compte de résultat, marges, recherche client) | ⬜ |
| `lib/screens` | 10 | 2 293 | Paramètres, équipe, bon de livraison | ⬜ |
| `lib/core/models` | 7 | 1 314 | Produit, vente, dette, dépense, utilisateur | 🟡 |
| `lib/core/services` | 18 | 3 482 | Reçus, PDF, Excel, IA photo, journal, équipe | 🟡 |
| `lib/core/providers` | 9 | 1 879 | Devises, rôles et autorisations, dépenses, panier | 🟡 |
| `lib/core/widgets` | 6 | 2 010 | Fiche produit, scanner, sauvegarde | ⬜ |
| `lib/core/utils` | 2 | 61 | Calcul du paiement, lecture des montants | ✅ |
| `lib/repositories` | 1 | 131 | Lecture/écriture des produits | ⬜ |
| `lib/features/accounting` | 3 | 1 058 | Écritures SYSCOHADA | 🟡 |
| `lib/features/aide` | 1 | 1 036 | Écran d'aide | ⬜ |
| `lib/features/auth` | 1 | 86 | Connexion | ⬜ |
| `lib/features/boutiques` | 5 | 1 698 | Multi-boutiques, transferts, prix par boutique | 🟡 |
| `lib/features/cloture` | 2 | 930 | Clôture de caisse (écrit en novembre 2026) | ✅ |
| `lib/features/comptes_clients` | 3 | 1 093 | Comptes de dépôt des clients | 🟡 |
| `lib/features/debts` | 11 | 5 675 | Dettes, crédit, dépenses, comptabilité, accueil stock, connexion/inscription | 🟡 |
| `lib/features/import` | 1 | 432 | Aperçu d'import (Excel, photo IA) | ⬜ |
| `lib/features/journal` | 1 | 366 | Journal « qui a fait quoi » | 🟡 |
| `lib/features/livraisons` | 1 | 936 | Ventes à livrer | ⬜ |
| `lib/features/shell` | 4 | 1 523 | Accueil, navigation, résumé du jour | 🟡 |
| `lib/features/ventes` | 3 | 1 779 | Historique, retours et annulations | 🟡 |

## Ce qui protège l'application

- `firestore.rules` : règles de sécurité du serveur (rôles, boutiques, ventes
  impossibles à modifier, crédit nominatif, clôture…).
- `tests_regles/` : tests automatiques de ces règles (`npm test`).
- `test/` : tests des calculs (paiement, devises, comptabilité, clôture).
- `.github/workflows/apk.yml` : à chaque envoi, lance les tests puis fabrique
  l'APK signé.

## Problèmes connus (à traiter)

1. **Prix non vérifié par le serveur** : une application modifiée pourrait
   vendre à un faux prix. Solution : une fonction serveur (forfait Blaze).
2. **Montants en `double`** et monnaie rendue sans indication de la monnaie
   ($ ou FC) : écarts d'arrondi possibles, pas de suivi du tiroir par monnaie.
3. **Comptabilité** : lit toutes les écritures pour le bilan (coût Firebase
   qui grandit avec l'historique). Solution : totaux par mois.
4. **Fichiers trop gros** : `financial_analysis_screen.dart` (1 481 lignes),
   `paiement_dialog.dart` (1 300), `add_product_modal.dart` (1 035),
   `aide_screen.dart` (1 036) : écran et calculs mélangés.
5. **Rangement à moitié fait** : `features/debts` contient aussi la connexion,
   l'inscription, l'accueil du stock, la comptabilité et les dépenses.
6. **Environ 225 textes écrits en dur** (non traduits).
7. **Environ 55 `catch (_)` silencieux** : des erreurs disparaissent sans trace.
8. **Avertissement `use_build_context_synchronously` désactivé** dans
   `analysis_options.yaml` : risque de plantage après un écran fermé.

## Notes de relecture

### Caisse (`lib/views/caisse`, relue en entier)

- `caisse_screen.dart` : écran, bandeau de la boutique de vente, export du catalogue.
- `widgets/produits_view.dart` : tuiles des produits (toucher = +1, appui long =
  quantité/prix), scanner, **le seul panier** (`PanierView`, téléphone et tablette)
  et `ouvrirPaiementCaisse`.
- `dialogs/ajout_panier_dialog.dart` : quantité et prix d'un produit.
- `dialogs/prix_negocie_dialog.dart` : prix négocié d'une ligne du panier.
- `dialogs/paiement_dialog.dart` (≈ 1 100 lignes) : fenêtre de paiement, reçu,
  WhatsApp/SMS, bouton facultatif « Bon de livraison ».
- `lib/features/ventes/vente_service.dart` : **enregistrement de la vente**
  (vente, écriture comptable, coût des marchandises, créance, compte client,
  stock), préparé sans Firebase puis écrit en un seul lot. Testé par
  `test/ventes/vente_service_test.dart` (12 cas).
- Panier : `lib/core/providers/cart_provider.dart`.

Corrigé lors de la relecture : taux du franc modifiable par n'importe quel
caissier (crayon de la barre du haut) ; champ « francs » absent quand
l'affichage est en dollars ; deuxième panier (tablette) en double ; vieille
fiche « nouveau produit » (virgule lue comme 0, sans boutique) remplacée par
la fiche complète ; prix saisis avec espaces ; textes en dur de l'écran caisse ;
export du catalogue avec le stock de la boutique.

Reste à faire :
- La monnaie rendue n'indique pas sa monnaie ($ ou FC).

## Déjà corrigé

- Failles du stock (règles), virgule à la caisse, crédit sans nom/téléphone,
  rapport de plantages, clôture de caisse, lectures Firebase de l'accueil et
  du crédit, purge dangereuse du journal dans « Synchroniser »,
  6 bibliothèques inutiles et 1 fichier mort retirés.

## Ordre de relecture prévu

1. `lib/views/caisse` (le cœur : là où l'argent entre)
2. `lib/features/ventes` et `lib/features/livraisons`
3. `lib/features/debts` et `lib/features/comptes_clients`
4. `lib/core` (modèles, services, providers, widgets)
5. `lib/features/boutiques`, `import`, `journal`
6. `lib/views/financial_analysis` et `lib/features/accounting`
7. `lib/screens`, `shell`, `auth`, `aide`, `main.dart`
