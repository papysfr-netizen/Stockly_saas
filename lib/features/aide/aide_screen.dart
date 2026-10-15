// ============================================================================
// 📖 GUIDE D'UTILISATION (dans l'application, marche SANS internet)
//  - Rubriques à ouvrir d'un geste, étapes numérotées, astuces
//  - Recherche : « dette », « taux », « imprimer »…
//  - Ouvert depuis Paramètres (carte « Guide d'utilisation ») et l'Accueil (« Aide »)
// ============================================================================
import 'package:flutter/material.dart';

import 'package:stockly_saas/l10n/app_localizations.dart';

const _vert = Color(0xFF0B7A5A);

class _Rubrique {
  final String titre;
  final IconData icone;
  final Color couleur;
  final List<String> etapes;
  final String? astuce;
  final bool patron; // réservé au patron / gérant

  const _Rubrique({
    required this.titre,
    required this.icone,
    required this.couleur,
    required this.etapes,
    this.astuce,
    this.patron = false,
  });

  bool contient(String mot) {
    final m = mot.toLowerCase();
    return titre.toLowerCase().contains(m) ||
        etapes.any((e) => e.toLowerCase().contains(m)) ||
        (astuce?.toLowerCase().contains(m) ?? false);
  }
}

const List<_Rubrique> _rubriques = [
  _Rubrique(
    titre: "Découvrir l'Accueil",
    icone: Icons.home_rounded,
    couleur: _vert,
    etapes: [
      "L'Accueil montre la journée : ventes, argent encaissé, crédits et dépenses.",
      'En haut, le taux du jour « 1 \$ = … FC ». Touchez-le pour le changer.',
      'Les 4 gros boutons ouvrent : Caisse, Dépense, Crédit et Stock.',
      'Plus bas : les choses à faire (clients qui doivent, produits presque finis) et les ventes du jour.',
      'Le patron choisit la boutique à afficher en haut à droite.',
    ],
    astuce: "Les chiffres de l'Accueil se mettent à jour tout seuls après chaque vente.",
  ),
  _Rubrique(
    titre: 'Faire une vente (caisse)',
    icone: Icons.point_of_sale_rounded,
    couleur: _vert,
    etapes: [
      'Ouvrez la Caisse.',
      'Touchez un produit : il est ajouté au panier (1 pièce). Touchez encore pour en ajouter.',
      'Appui LONG sur un produit : choisir la quantité (et le prix si vous en avez le droit).',
      'Touchez le gros bouton vert « Encaisser ».',
      "Tapez ce que le client donne en dollars et/ou en francs. L'application calcule la monnaie à rendre.",
      'Validez. La vente est enregistrée, le stock baisse et le reçu peut sortir.',
    ],
    astuce: 'Vous pouvez aussi scanner le code-barres du produit avec la caméra.',
  ),
  _Rubrique(
    titre: 'Changer le prix (négociation)',
    icone: Icons.sell_rounded,
    couleur: Colors.orange,
    etapes: [
      'Ajoutez le produit au panier, puis ouvrez le panier.',
      'Touchez la ligne du produit : la fenêtre « Prix pour … » s\'ouvre.',
      'Tapez le prix accordé au client et touchez « Valider ».',
      'La ligne affiche alors « Prix normal : … » en orange.',
      'Pour revenir au prix normal : touchez la ligne puis « Prix normal ».',
    ],
    astuce: "Il faut l'autorisation « Remises et retraits ». Sous le prix d'achat, un message rouge « Vente à perte » prévient. Le patron voit le total des remises sur l'Accueil.",
  ),
  _Rubrique(
    titre: 'Vendre à crédit ou avec un acompte',
    icone: Icons.receipt_long_rounded,
    couleur: Colors.indigo,
    etapes: [
      'Faites la vente comme d\'habitude jusqu\'à « Encaisser ».',
      'Tapez le nom et le numéro de téléphone du client (obligatoire pour un crédit).',
      'Tapez seulement ce que le client paie maintenant (ou 0).',
      'Validez : le reste devient une dette du client, visible dans « Crédit ».',
    ],
    astuce: 'Avec le numéro de téléphone, le client peut recevoir un message WhatsApp ou SMS avec le reste à payer.',
  ),
  _Rubrique(
    titre: 'Encaisser une dette',
    icone: Icons.menu_book_rounded,
    couleur: Colors.indigo,
    etapes: [
      'Ouvrez « Crédit » puis la dette du client.',
      'Touchez le règlement, tapez le montant reçu et le mode de paiement.',
      'Touchez « Valider le Règlement ». Le reste à payer diminue.',
      'Si le client donne PLUS que sa dette, l\'application propose de mettre le surplus sur son compte client.',
    ],
    astuce: 'Le surplus ne peut aller sur un compte client que si la dette a un numéro de téléphone.',
  ),
  _Rubrique(
    titre: 'Comptes clients (argent déposé)',
    icone: Icons.account_balance_wallet_rounded,
    couleur: Colors.teal,
    etapes: [
      'Ouvrez « Comptes clients » (Accueil, rubrique « Plus »).',
      'Dépôt : le client laisse de l\'argent d\'avance. Il est gardé sur son compte (lié à son numéro).',
      'À la caisse, le solde du client peut payer tout ou une partie de son achat.',
      "Retrait : rendre de l'argent au client (autorisation « Remises et retraits »).",
    ],
  ),
  _Rubrique(
    titre: 'Marchandise à retirer plus tard',
    icone: Icons.local_shipping_rounded,
    couleur: Colors.deepPurple,
    etapes: [
      'À l\'encaissement, choisissez que le client retire la marchandise plus tard.',
      'La vente apparaît dans « À livrer » avec la date limite de retrait.',
      'Quand le client vient chercher, ouvrez « À livrer » et marquez la vente comme livrée.',
    ],
  ),
  _Rubrique(
    titre: 'Noter une dépense',
    icone: Icons.upload_rounded,
    couleur: Colors.red,
    etapes: [
      'Touchez « Dépense » sur l\'Accueil.',
      'Tapez le montant et le motif (transport, loyer, électricité…).',
      'Enregistrez : la dépense baisse « l\'argent en caisse du jour ».',
    ],
    astuce: 'Les dépenses sont réservées au patron et au gérant.',
    patron: true,
  ),
  _Rubrique(
    titre: 'Le stock',
    icone: Icons.inventory_2_rounded,
    couleur: Color(0xFF0052FF),
    etapes: [
      'Ouvrez « Stock » pour voir les produits et les quantités de votre boutique.',
      'Ajoutez un produit avec son nom, son prix d\'achat, son prix de vente et sa quantité.',
      'Vous pouvez importer une liste Excel (packing list) : l\'application reconnaît les colonnes.',
      'Les produits presque finis apparaissent dans « À faire aujourd\'hui » sur l\'Accueil.',
    ],
    astuce: "Ajouter, modifier ou supprimer un produit demande l'autorisation « Gérer le stock ».",
    patron: true,
  ),
  _Rubrique(
    titre: 'Transférer entre boutiques',
    icone: Icons.swap_horiz_rounded,
    couleur: Colors.brown,
    etapes: [
      'Ouvrez l\'écran des transferts depuis le Stock.',
      'Choisissez la boutique de départ et celle d\'arrivée.',
      'Choisissez les produits et les quantités (ou « Tout transférer »).',
      'Validez : le stock baisse dans une boutique et monte dans l\'autre.',
    ],
    patron: true,
  ),
  _Rubrique(
    titre: 'Retour ou annulation de vente',
    icone: Icons.assignment_return_rounded,
    couleur: Colors.deepOrange,
    etapes: [
      'Ouvrez « Ventes » (Accueil, rubrique « Plus ») et retrouvez la vente.',
      'Choisissez le retour (ou l\'annulation) et les articles concernés.',
      'Le stock remonte. L\'argent peut être rendu ou mis sur le compte du client.',
    ],
    astuce: "Il faut l'autorisation « Retours et annulations ».",
  ),
  _Rubrique(
    titre: 'Le taux du dollar',
    icone: Icons.currency_exchange_rounded,
    couleur: _vert,
    etapes: [
      'Touchez « 1 \$ = … FC » en haut de l\'Accueil.',
      'Tapez le nouveau taux et touchez « Enregistrer ».',
      'Tous les téléphones de la MÊME boutique reçoivent ce taux automatiquement.',
      'Chaque boutique a son propre taux (par exemple Goma et Kalemie).',
    ],
    astuce: 'Le patron qui regarde « Toutes les boutiques » change seulement le taux de son téléphone.',
  ),
  _Rubrique(
    titre: 'Imprimer le reçu',
    icone: Icons.print_rounded,
    couleur: Colors.blueGrey,
    etapes: [
      'Paramètres → carte « Imprimante ».',
      'Choisissez la largeur du papier : 58 mm (petite) ou 80 mm (grande).',
      "Choisissez : le reçu « S'imprime » ou « Est envoyé en PDF » (WhatsApp…).",
      "Touchez « Imprimer un reçu d'essai » pour vérifier.",
      'À la caisse, cochez « Imprimer le reçu » avant de valider la vente.',
    ],
    astuce: "Le reçu s'imprime aussi sans internet.",
  ),
  _Rubrique(
    titre: 'Résumé du soir par WhatsApp',
    icone: Icons.send_rounded,
    couleur: Color(0xFF25D366),
    etapes: [
      'Sur l\'Accueil, touchez « Envoyer le résumé du jour ».',
      'WhatsApp s\'ouvre avec le message déjà écrit (ventes, encaissé, crédit, dépenses…).',
      'Choisissez le contact du patron et envoyez.',
    ],
  ),
  _Rubrique(
    titre: "L'équipe et les autorisations",
    icone: Icons.groups_rounded,
    couleur: Colors.purple,
    etapes: [
      'Paramètres → « Équipe » (patron seulement).',
      'Ajoutez un employé et choisissez son rôle : gérant ou caissier.',
      'Choisissez sa boutique de travail.',
      'Activez ou désactivez ses autorisations : voir les finances, gérer le stock, retours, remises et retraits…',
    ],
    patron: true,
  ),
  _Rubrique(
    titre: 'Travailler sans internet',
    icone: Icons.wifi_off_rounded,
    couleur: Colors.grey,
    etapes: [
      'Vous pouvez vendre même sans réseau.',
      'Les ventes sont gardées dans le téléphone et envoyées dès le retour d\'internet.',
      "Ne désinstallez pas l'application et ne vous déconnectez pas avant le retour du réseau.",
    ],
    astuce: 'Rallumez les données de temps en temps dans la journée pour que tout parte au serveur.',
  ),
  _Rubrique(
    titre: 'Problèmes fréquents',
    icone: Icons.help_rounded,
    couleur: Colors.red,
    etapes: [
      '« Vente NON enregistrée » : le serveur a refusé. Ne donnez pas la marchandise, prévenez le patron.',
      '« Trop élevé » sur une dette : le montant dépasse ce que le client doit.',
      '« Limite du stock atteinte » : il n\'y a plus assez de pièces dans votre boutique.',
      'Mot de passe oublié ou à changer : Paramètres → « Mon compte ».',
      "Un chiffre semble faux : vérifiez d'abord la boutique choisie en haut de l'Accueil.",
    ],
  ),
];

/// 📖 Écran du guide
class AideScreen extends StatefulWidget {
  const AideScreen({super.key});

  @override
  State<AideScreen> createState() => _AideScreenState();
}

class _AideScreenState extends State<AideScreen> {
  String _recherche = '';

  @override
  Widget build(BuildContext context) {
    final liste = _recherche.trim().isEmpty
        ? _rubriques
        : _rubriques.where((r) => r.contient(_recherche.trim())).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F7),
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).guideTitle),
        backgroundColor: _vert,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context).guideSearch,
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            onChanged: (v) => setState(() => _recherche = v),
          ),
          const SizedBox(height: 12),
          if (liste.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                AppLocalizations.of(context).guideNotFound(_recherche),
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),
          for (final r in liste) _CarteRubrique(rubrique: r, ouverte: _recherche.trim().isNotEmpty),
        ],
      ),
    );
  }
}

class _CarteRubrique extends StatelessWidget {
  final _Rubrique rubrique;
  final bool ouverte;

  const _CarteRubrique({required this.rubrique, required this.ouverte});

  @override
  Widget build(BuildContext context) {
    final r = rubrique;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: PageStorageKey('${r.titre}-$ouverte'),
          initiallyExpanded: ouverte,
          leading: CircleAvatar(
            backgroundColor: r.couleur.withValues(alpha: 0.12),
            child: Icon(r.icone, color: r.couleur),
          ),
          title: Text(r.titre, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: r.patron
              ? Text(AppLocalizations.of(context).guideOwnerOnly, style: TextStyle(fontSize: 12, color: Colors.grey.shade600))
              : null,
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < r.etapes.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 11,
                      backgroundColor: r.couleur,
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(r.etapes[i], style: const TextStyle(height: 1.35))),
                  ],
                ),
              ),
            if (r.astuce != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_rounded, color: Colors.amber.shade800, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(r.astuce!, style: const TextStyle(height: 1.35))),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 📖 Carte « Guide d'utilisation » des Paramètres
class AideCard extends StatelessWidget {
  const AideCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0x1F0B7A5A),
          child: Icon(Icons.menu_book_rounded, color: _vert),
        ),
        title: Text(AppLocalizations.of(context).guideTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(AppLocalizations.of(context).guideSubtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AideScreen()),
        ),
      ),
    );
  }
}
