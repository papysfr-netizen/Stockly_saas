# Constitution de l'Architecture & Principes Directeurs : Stockly SaaS

## 1. Vision & Architecture Globale
* **Architecture Feature-First & Clean Architecture :** Le projet est découpé par modules autonomes (POS/Caisse, Inventaire, Microfinance/IFP, E-commerce, Analytics). Chaque feature contient ses propres couches `domain`, `data`, et `presentation`.
* **Gestion d'État Moderne :** Utilisation stricte de **Flutter Riverpod** (avec codegen / `AsyncNotifier`) pour un flux de données réactif, prévisible et testable.
* **Multi-tenant Isolation :** Chaque entreprise/organisation dispose d'une isolation stricte de ses données Firestore (`/organizations/{orgId}/...`). Aucune fuite de données inter-entreprises n'est tolérée.

## 2. Intégrité Financière & Rigueur Comptable (Microfinance & Caisse)
* **Immutabilité des Écritures :** Toute opération financière (dépôt, retrait, octroi de crédit, encaissement caisse) est **immutative**. Aucune suppression ou modification directe : toute correction passe par une écriture de contrepassation (journal comptable).
* **Comptabilité en Partie Double :** Les mouvements d'épargne et de crédit respectent le principe d'équilibre débit/crédit.
* **Validation Serveur Obligatoire (Cloud Functions) :** Les calculs d'intérêts, les échéanciers de remboursement et le déboursement de crédits ne doivent jamais être calculés côté client. Ils sont exécutés de manière atomique via transactions Firestore ou Cloud Functions.

## 3. Stratégie Offline-First & Résilience Réseau
* **Opérationnalité Hors-Ligne (POS & Vente) :** La caisse et la gestion du stock physique doivent fonctionner sans connexion Internet grâce à la persistance locale Firestore et un système de file d'attente de synchronisation (`SyncQueue`).
* **Résolution des Conflits :** En cas de vente simultanée hors-ligne et en ligne, la règle du stock physique prévaut, avec notification immédiate des réajustements.

## 4. Couche d'Intelligence & Brique IA
* **Scoring de Crédit Intelligent :** Intégration d'algorithmes d'analyse du comportement de remboursement et du volume de ventes du commerçant pour recommander les plafonds de crédit.
* **Gestion Prédictive des Stocks :** Analyse automatique du rythme de vente pour déclencher des alertes de réapprovisionnement intelligentes et éviter les ruptures.
* **Assistant IA Unifié :** Reporting financier interactif en langage naturel pour les gestionnaires et commerçants.

## 5. UI/UX & Accessibilité Moderne
* **Design System Material 3 Adaptatif :** Interface responsive conçue pour Mobile, Tablette et Desktop (Point de Vente tactile).
* **Clarté & Inclusivité :** Interface épurée avec prise en charge visuelle forte (icônes explicites, retours haptiques/sonores lors des encaissements) adaptée à tous les niveaux d'utilisateurs.
* **Indicateurs d'État Réseau & Synchronisation :** Statut visuel clair (En ligne / Hors ligne / Synchronisation en cours).

## 6. Qualité de Code & Sécurité
* **Strict Typing & Linting :** Conformité aux règles `very_good_analysis`.
* **Règles de Sécurité Firebase Stricte :** Contrôle d'accès basé sur les rôles (RBAC : Admin, Caissier, Agent de Crédit, Client E-commerce).
* **Audit Trail :** Traçabilité complète de chaque action utilisateur (qui a fait quoi, quand et depuis quel appareil).

## 7. Performance Extrême & Réactivité Zero-Latence
* **Mise à Jour Optimiste (Optimistic UI) :** L'interface réagit instantanément aux actions utilisateur (encaissement, mise à jour du stock) sans attendre le retour serveur, avec rollback automatique sécurisé en cas d'échec.
* **Optimisation des Ressources & Requêtes :** Mise en cache locale agressive, compression à la volée des images produits et regroupement (batching) des requêtes Firestore pour économiser la bande passante.

## 8. Observabilité, Télémesure & Résilience (SRE)
* **Monitoring Proactif :** Traçabilité en temps réel des erreurs et bugs via Firebase Crashlytics pour détecter et corriger les anomalies instantanément.
* **Haute Disponibilité (SLA 99.9%) :** Architecture conçue pour garantir une continuité de service constante avec contrôle permanent des métriques clés.

## 9. Sécurité Renforcée, Chiffrement & Conformité
* **Chiffrement Avancé :** Chiffrement des données financières et identités clients au repos (AES-256) et en transit (TLS 1.3).
* **Sauvegardes & Reprise après Sinistre (PCA/PRA) :** Sauvegardes automatisées quotidiennes et mécanismes de restauration rapide pour assurer une sécurité de niveau bancaire.
* **Conformité Réglementaire :** Respect strict des normes financières locales (pistes d'audit fiscales, archivage des reçus, traçabilité des opérations).

## 10. Écosystème Ouvert, Communication Omnicanale & Extensibilité
* **Messagerie & Notifications Omnicanales (SMS, WhatsApp, Push) :** Envoi automatisé et sécurisé de reçus de vente, confirmation de transactions, rappels d'échéances de crédit et alertes de stock via SMS et WhatsApp (intégration API Twilio / Meta WhatsApp Business) ainsi que par notifications push in-app.
* **Support Matériel & Payment Gateways :** Prise en charge fluide des périphériques physiques (imprimantes thermiques Bluetooth/USB, scanners de codes-barres, TPE) et intégration directe des passerelles Mobile Money (M-Pesa, Orange Money, Airtel Money).
* **Architecture Modulaire (Feature Toggling) :** Activation/désactivation dynamique des fonctionnalités selon la formule d'abonnement SaaS souscrite par l'utilisateur.