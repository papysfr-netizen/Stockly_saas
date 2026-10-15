// ============================================================================
// 📖 GUIDE D'UTILISATION (dans l'application, marche SANS internet)
//  - En 4 langues : français, anglais, swahili, lingala
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

// 🇫🇷 Français
const List<_Rubrique> _rubriquesFr = [
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

// 🇬🇧 English
const List<_Rubrique> _rubriquesEn = [
  _Rubrique(
    titre: "Discover the Home screen",
    icone: Icons.home_rounded,
    couleur: _vert,
    etapes: [
      "Home shows your day: sales, money collected, credits and expenses.",
      "At the top, today's rate “1 \$ = … FC”. Tap it to change it.",
      "The 4 big buttons open: Checkout, Expense, Credit and Stock.",
      "Further down: things to do (customers who owe, products running out) and today's sales.",
      "The owner chooses which shop to show at the top right.",
    ],
    astuce: "The Home figures update by themselves after each sale.",
  ),
  _Rubrique(
    titre: "Make a sale (checkout)",
    icone: Icons.point_of_sale_rounded,
    couleur: _vert,
    etapes: [
      "Open Checkout.",
      "Tap a product: it is added to the cart (1 piece). Tap again to add more.",
      "LONG press a product: choose the quantity (and the price if you are allowed).",
      "Tap the big green “Checkout” button.",
      "Type what the customer gives in dollars and/or francs. The app calculates the change.",
      "Confirm. The sale is saved, the stock goes down and the receipt can be printed.",
    ],
    astuce: "You can also scan the product barcode with the camera.",
  ),
  _Rubrique(
    titre: "Change the price (bargaining)",
    icone: Icons.sell_rounded,
    couleur: Colors.orange,
    etapes: [
      "Add the product to the cart, then open the cart.",
      "Tap the product line: the “Price for …” window opens.",
      "Type the price agreed with the customer and tap “Confirm”.",
      "The line then shows “Normal price: …” in orange.",
      "To go back to the normal price: tap the line, then “Normal price”.",
    ],
    astuce: "You need the “Discounts and withdrawals” permission. Below the purchase price, a red “Selling at a loss” message warns you. The owner sees total discounts on Home.",
  ),
  _Rubrique(
    titre: "Sell on credit or with a deposit",
    icone: Icons.receipt_long_rounded,
    couleur: Colors.indigo,
    etapes: [
      "Make the sale as usual up to “Checkout”.",
      "Type the customer's name and phone number (required for credit).",
      "Type only what the customer pays now (or 0).",
      "Confirm: the rest becomes the customer's debt, shown in “Credit”.",
    ],
    astuce: "With the phone number, the customer can receive a WhatsApp or SMS message with the balance.",
  ),
  _Rubrique(
    titre: "Collect a debt",
    icone: Icons.menu_book_rounded,
    couleur: Colors.indigo,
    etapes: [
      "Open “Credit”, then the customer's debt.",
      "Tap “Collect”, type the amount received and the payment method.",
      "Tap “Confirm payment”. The balance goes down.",
      "If the customer gives MORE than the debt, the app offers to put the extra on their customer account.",
    ],
    astuce: "The extra can only go to a customer account if the debt has a phone number.",
  ),
  _Rubrique(
    titre: "Customer accounts (money deposited)",
    icone: Icons.account_balance_wallet_rounded,
    couleur: Colors.teal,
    etapes: [
      "Open “Customer accounts” (Home, “More” section).",
      "Deposit: the customer leaves money in advance. It is kept on their account (linked to their number).",
      "At checkout, the customer's balance can pay all or part of the purchase.",
      "Withdrawal: give money back to the customer (“Discounts and withdrawals” permission).",
    ],
  ),
  _Rubrique(
    titre: "Goods to pick up later",
    icone: Icons.local_shipping_rounded,
    couleur: Colors.deepPurple,
    etapes: [
      "At checkout, choose “Deliver later”.",
      "The sale appears in « À livrer » with the pickup deadline.",
      "When the customer comes, open « À livrer » and mark the sale as delivered.",
    ],
  ),
  _Rubrique(
    titre: "Record an expense",
    icone: Icons.upload_rounded,
    couleur: Colors.red,
    etapes: [
      "Tap “Expense” on Home.",
      "Type the amount and the reason (transport, rent, electricity…).",
      "Save: the expense lowers “Cash in the till today”.",
    ],
    astuce: "Expenses are reserved for the owner and the manager.",
    patron: true,
  ),
  _Rubrique(
    titre: "Stock",
    icone: Icons.inventory_2_rounded,
    couleur: Color(0xFF0052FF),
    etapes: [
      "Open “Stock” to see the products and quantities of your shop.",
      "Add a product with its name, purchase price, selling price and quantity.",
      "You can import an Excel list (packing list): the app recognises the columns.",
      "Products running out appear in “To do today” on Home.",
    ],
    astuce: "Adding, editing or deleting a product needs the “Manage stock” permission.",
    patron: true,
  ),
  _Rubrique(
    titre: "Transfer between shops",
    icone: Icons.swap_horiz_rounded,
    couleur: Colors.brown,
    etapes: [
      "Open the transfers screen from Stock.",
      "Choose the shop of departure and the shop of arrival.",
      "Choose the products and quantities (or “Transfer all”).",
      "Confirm: stock goes down in one shop and up in the other.",
    ],
    patron: true,
  ),
  _Rubrique(
    titre: "Sale return or cancellation",
    icone: Icons.assignment_return_rounded,
    couleur: Colors.deepOrange,
    etapes: [
      "Open “Sales” (Home, “More” section) and find the sale.",
      "Choose return (or cancellation) and the items concerned.",
      "Stock goes back up. The money can be refunded or put on the customer's account.",
    ],
    astuce: "You need the “Returns and cancellations” permission.",
  ),
  _Rubrique(
    titre: "The dollar rate",
    icone: Icons.currency_exchange_rounded,
    couleur: _vert,
    etapes: [
      "Tap “1 \$ = … FC” at the top of Home.",
      "Type the new rate and tap “Save”.",
      "All phones of the SAME shop receive this rate automatically.",
      "Each shop has its own rate (for example Goma and Kalemie).",
    ],
    astuce: "An owner viewing “All shops” only changes the rate on their own phone.",
  ),
  _Rubrique(
    titre: "Print the receipt",
    icone: Icons.print_rounded,
    couleur: Colors.blueGrey,
    etapes: [
      "Settings → “Printer” card.",
      "Choose the paper width: 58 mm (small) or 80 mm (large).",
      "Choose: the receipt “Is printed” or “Is sent as PDF” (WhatsApp…).",
      "Tap “Print a test receipt” to check.",
      "At checkout, tick “Print the receipt” before confirming the sale.",
    ],
    astuce: "The receipt also prints without internet.",
  ),
  _Rubrique(
    titre: "Evening summary by WhatsApp",
    icone: Icons.send_rounded,
    couleur: Color(0xFF25D366),
    etapes: [
      "On Home, tap “Send today's summary”.",
      "WhatsApp opens with the message already written (sales, collected, credit, expenses…).",
      "Choose the owner's contact and send.",
    ],
  ),
  _Rubrique(
    titre: "Team and permissions",
    icone: Icons.groups_rounded,
    couleur: Colors.purple,
    etapes: [
      "Settings → « Équipe » (owner only).",
      "Add an employee and choose their role: manager or cashier.",
      "Choose their shop.",
      "Turn their permissions on or off: see finances, manage stock, returns, discounts and withdrawals…",
    ],
    patron: true,
  ),
  _Rubrique(
    titre: "Working without internet",
    icone: Icons.wifi_off_rounded,
    couleur: Colors.grey,
    etapes: [
      "You can sell even without network.",
      "Sales are kept on the phone and sent as soon as internet is back.",
      "Do not uninstall the app or log out before the network comes back.",
    ],
    astuce: "Turn mobile data on from time to time during the day so everything reaches the server.",
  ),
  _Rubrique(
    titre: "Common problems",
    icone: Icons.help_rounded,
    couleur: Colors.red,
    etapes: [
      "“Sale NOT saved”: the server refused. Do not hand over the goods, tell the owner.",
      "“Too high” on a debt: the amount is more than what the customer owes.",
      "“Stock limit reached”: there are not enough pieces in your shop.",
      "Password forgotten or to change: Settings → “My account”.",
      "A number looks wrong: first check the shop chosen at the top of Home.",
    ],
  ),
];

// 🇹🇿 Kiswahili
const List<_Rubrique> _rubriquesSw = [
  _Rubrique(
    titre: "Kuelewa skrini ya Mwanzo",
    icone: Icons.home_rounded,
    couleur: _vert,
    etapes: [
      "Mwanzo inaonyesha siku yako: mauzo, pesa iliyopokelewa, mikopo na matumizi.",
      "Juu kuna bei ya dola ya leo « 1 \$ = … FC ». Iguse ili kuibadilisha.",
      "Vitufe 4 vikubwa vinafungua: Malipo, Matumizi, Mkopo na Bidhaa.",
      "Chini: ya kufanya (wateja wanaodaiwa, bidhaa zinazoisha) na mauzo ya leo.",
      "Mmiliki anachagua duka la kuonyesha juu upande wa kulia.",
    ],
    astuce: "Hesabu za Mwanzo zinasasishwa zenyewe baada ya kila mauzo.",
  ),
  _Rubrique(
    titre: "Kuuza (Malipo)",
    icone: Icons.point_of_sale_rounded,
    couleur: _vert,
    etapes: [
      "Fungua Malipo.",
      "Gusa bidhaa: inaongezwa kwenye kikapu (kipande 1). Gusa tena kuongeza.",
      "Bonyeza bidhaa kwa MUDA: chagua idadi (na bei ukiwa na ruhusa).",
      "Gusa kitufe kikubwa cha kijani « Lipisha ».",
      "Andika pesa anayotoa mteja kwa dola na/au faranga. Programu inahesabu chenji.",
      "Thibitisha. Mauzo yanahifadhiwa, stoo inapungua na risiti inaweza kuchapishwa.",
    ],
    astuce: "Unaweza pia kusoma msimbo pau wa bidhaa kwa kamera.",
  ),
  _Rubrique(
    titre: "Kubadilisha bei (mapatano)",
    icone: Icons.sell_rounded,
    couleur: Colors.orange,
    etapes: [
      "Ongeza bidhaa kwenye kikapu, kisha fungua kikapu.",
      "Gusa mstari wa bidhaa: dirisha « Bei ya … » linafunguka.",
      "Andika bei mliyokubaliana na mteja kisha gusa « Thibitisha ».",
      "Mstari unaonyesha « Bei ya kawaida : … » kwa rangi ya machungwa.",
      "Kurudi kwenye bei ya kawaida: gusa mstari kisha « Bei ya kawaida ».",
    ],
    astuce: "Unahitaji ruhusa ya « Punguzo na utoaji ». Chini ya bei ya kununua, ujumbe mwekundu « Unauza kwa hasara » unakuonya. Mmiliki anaona jumla ya punguzo kwenye Mwanzo.",
  ),
  _Rubrique(
    titre: "Kuuza kwa mkopo au kwa malipo ya sehemu",
    icone: Icons.receipt_long_rounded,
    couleur: Colors.indigo,
    etapes: [
      "Fanya mauzo kama kawaida hadi « Lipisha ».",
      "Andika jina na namba ya simu ya mteja (lazima kwa mkopo).",
      "Andika tu kiasi anacholipa mteja sasa (au 0).",
      "Thibitisha: kilichobaki kinakuwa deni la mteja, kinaonekana kwenye « Mkopo ».",
    ],
    astuce: "Kwa namba ya simu, mteja anaweza kupokea ujumbe wa WhatsApp au SMS wenye kiasi kilichobaki.",
  ),
  _Rubrique(
    titre: "Kupokea deni",
    icone: Icons.menu_book_rounded,
    couleur: Colors.indigo,
    etapes: [
      "Fungua « Mkopo », kisha deni la mteja.",
      "Gusa « Pokea », andika kiasi ulichopokea na njia ya malipo.",
      "Gusa « Thibitisha malipo ». Kiasi kinachodaiwa kinapungua.",
      "Mteja akitoa ZAIDI ya deni lake, programu inapendekeza kuweka ziada kwenye akaunti yake.",
    ],
    astuce: "Ziada inaweza kwenda kwenye akaunti ya mteja tu kama deni lina namba ya simu.",
  ),
  _Rubrique(
    titre: "Akaunti za wateja (pesa za akiba)",
    icone: Icons.account_balance_wallet_rounded,
    couleur: Colors.teal,
    etapes: [
      "Fungua « Akaunti za wateja » (Mwanzo, sehemu ya « Zaidi »).",
      "Kuweka: mteja anaacha pesa mapema. Inahifadhiwa kwenye akaunti yake (inayohusishwa na namba yake).",
      "Kwenye Malipo, salio la mteja linaweza kulipa ununuzi wote au sehemu.",
      "Kutoa: kumrudishia mteja pesa (ruhusa ya « Punguzo na utoaji »).",
    ],
  ),
  _Rubrique(
    titre: "Bidhaa za kuchukuliwa baadaye",
    icone: Icons.local_shipping_rounded,
    couleur: Colors.deepPurple,
    etapes: [
      "Wakati wa malipo, chagua « Itatolewa baadaye ».",
      "Mauzo yanaonekana kwenye « À livrer » pamoja na tarehe ya mwisho.",
      "Mteja akija kuchukua, fungua « À livrer » na uweke kuwa imetolewa.",
    ],
  ),
  _Rubrique(
    titre: "Kuandika matumizi",
    icone: Icons.upload_rounded,
    couleur: Colors.red,
    etapes: [
      "Gusa « Matumizi » kwenye Mwanzo.",
      "Andika kiasi na sababu (usafiri, kodi, umeme…).",
      "Hifadhi: matumizi yanapunguza « Pesa ya kasha leo ».",
    ],
    astuce: "Matumizi ni ya mmiliki na meneja tu.",
    patron: true,
  ),
  _Rubrique(
    titre: "Bidhaa (stoo)",
    icone: Icons.inventory_2_rounded,
    couleur: Color(0xFF0052FF),
    etapes: [
      "Fungua « Bidhaa » kuona bidhaa na idadi zake kwenye duka lako.",
      "Ongeza bidhaa kwa jina, bei ya kununua, bei ya kuuza na idadi.",
      "Unaweza kuingiza orodha ya Excel (packing list): programu inatambua safu.",
      "Bidhaa zinazoisha zinaonekana kwenye « Ya kufanya leo » kwenye Mwanzo.",
    ],
    astuce: "Kuongeza, kuhariri au kufuta bidhaa kunahitaji ruhusa ya « Kusimamia bidhaa ».",
    patron: true,
  ),
  _Rubrique(
    titre: "Kuhamisha kati ya maduka",
    icone: Icons.swap_horiz_rounded,
    couleur: Colors.brown,
    etapes: [
      "Fungua skrini ya uhamisho kutoka Bidhaa.",
      "Chagua duka la kutoka na duka la kufika.",
      "Chagua bidhaa na idadi (au « Hamisha zote »).",
      "Thibitisha: stoo inapungua kwenye duka moja na kuongezeka kwenye lingine.",
    ],
    patron: true,
  ),
  _Rubrique(
    titre: "Kurudisha au kufuta mauzo",
    icone: Icons.assignment_return_rounded,
    couleur: Colors.deepOrange,
    etapes: [
      "Fungua « Mauzo » (Mwanzo, sehemu ya « Zaidi ») na utafute mauzo.",
      "Chagua kurudisha (au kufuta) na bidhaa zinazohusika.",
      "Stoo inaongezeka. Pesa inaweza kurudishwa au kuwekwa kwenye akaunti ya mteja.",
    ],
    astuce: "Unahitaji ruhusa ya « Kurudisha na kufuta ».",
  ),
  _Rubrique(
    titre: "Bei ya dola",
    icone: Icons.currency_exchange_rounded,
    couleur: _vert,
    etapes: [
      "Gusa « 1 \$ = … FC » juu ya Mwanzo.",
      "Andika bei mpya kisha gusa « Hifadhi ».",
      "Simu zote za duka MOJA zinapokea bei hii zenyewe.",
      "Kila duka lina bei yake (kwa mfano Goma na Kalemie).",
    ],
    astuce: "Mmiliki anayeangalia « Maduka yote » anabadilisha bei kwenye simu yake tu.",
  ),
  _Rubrique(
    titre: "Kuchapisha risiti",
    icone: Icons.print_rounded,
    couleur: Colors.blueGrey,
    etapes: [
      "Mipangilio → kadi ya « Printa ».",
      "Chagua upana wa karatasi: 58 mm (ndogo) au 80 mm (kubwa).",
      "Chagua: risiti « Inachapishwa » au « Inatumwa kama PDF » (WhatsApp…).",
      "Gusa « Chapisha risiti ya majaribio » ili kuhakikisha.",
      "Kwenye Malipo, weka alama « Chapisha risiti » kabla ya kuthibitisha.",
    ],
    astuce: "Risiti inachapishwa hata bila mtandao.",
  ),
  _Rubrique(
    titre: "Muhtasari wa jioni kwa WhatsApp",
    icone: Icons.send_rounded,
    couleur: Color(0xFF25D366),
    etapes: [
      "Kwenye Mwanzo, gusa « Tuma muhtasari wa leo ».",
      "WhatsApp inafunguka na ujumbe tayari umeandikwa (mauzo, pesa, mkopo, matumizi…).",
      "Chagua namba ya mmiliki na utume.",
    ],
  ),
  _Rubrique(
    titre: "Timu na ruhusa",
    icone: Icons.groups_rounded,
    couleur: Colors.purple,
    etapes: [
      "Mipangilio → « Équipe » (mmiliki tu).",
      "Ongeza mfanyakazi na uchague kazi yake: meneja au mhudumu wa kasha.",
      "Chagua duka lake.",
      "Washa au zima ruhusa zake: kuona fedha, kusimamia bidhaa, kurudisha, punguzo na utoaji…",
    ],
    patron: true,
  ),
  _Rubrique(
    titre: "Kufanya kazi bila mtandao",
    icone: Icons.wifi_off_rounded,
    couleur: Colors.grey,
    etapes: [
      "Unaweza kuuza hata bila mtandao.",
      "Mauzo yanahifadhiwa kwenye simu na kutumwa mtandao ukirudi.",
      "Usiondoe programu wala kutoka kabla mtandao haujarudi.",
    ],
    astuce: "Washa data mara kwa mara mchana ili kila kitu kifike kwenye seva.",
  ),
  _Rubrique(
    titre: "Matatizo ya kawaida",
    icone: Icons.help_rounded,
    couleur: Colors.red,
    etapes: [
      "« Mauzo HAYAJAHIFADHIWA »: seva imekataa. Usitoe bidhaa, mjulishe mmiliki.",
      "« Kiasi kikubwa mno » kwenye deni: kiasi kinazidi anachodaiwa mteja.",
      "« Kikomo cha bidhaa kimefikiwa »: hakuna vipande vya kutosha kwenye duka lako.",
      "Nenosiri limesahaulika au la kubadilisha: Mipangilio → « Akaunti yangu ».",
      "Hesabu inaonekana si sahihi: kwanza angalia duka lililochaguliwa juu ya Mwanzo.",
    ],
  ),
];

// 🇨🇩 Lingala
const List<_Rubrique> _rubriquesLn = [
  _Rubrique(
    titre: "Koyeba Ebandeli",
    icone: Icons.home_rounded,
    couleur: _vert,
    etapes: [
      "Ebandeli emonisaka mokolo na yo: biteki, mbongo ezwami, ba niongo mpe bibimisi.",
      "Likolo, motuya ya dolare lelo « 1 \$ = … FC ». Simba yango mpo na kobongola.",
      "Ba bouton 4 ya minene efungolaka: Kesi, Mbimisi, Niongo mpe Biloko.",
      "Na se: oyo ya kosala (bakiliya bazali na niongo, biloko ezali kosila) mpe biteki ya lelo.",
      "Nkolo aponaka magazini ya komonisa na likolo, na loboko ya mobali.",
    ],
    astuce: "Mitango ya Ebandeli ebongwanaka yango moko sima ya eteki nyonso.",
  ),
  _Rubrique(
    titre: "Koteka (Kesi)",
    icone: Icons.point_of_sale_rounded,
    couleur: _vert,
    etapes: [
      "Fungola Kesi.",
      "Simba eloko: ekotisami na panier (moko). Simba lisusu mpo na kobakisa.",
      "Simba eloko ntango MOLAI: pona motango (mpe talo soki ozali na ndingisa).",
      "Simba bouton monene ya langi ya mayi ya pondu « Zwa mbongo ».",
      "Koma mbongo oyo mosombi apesi na dolare to na falanga. Application etangaka mbongo ya kozongisa.",
      "Ndima. Eteki ebombami, stock ekiti mpe resi ekoki kobima.",
    ],
    astuce: "Okoki mpe kotanga kode-barre ya eloko na kamera.",
  ),
  _Rubrique(
    titre: "Kobongola talo (boyokani)",
    icone: Icons.sell_rounded,
    couleur: Colors.orange,
    etapes: [
      "Bakisa eloko na panier, sima fungola panier.",
      "Simba molongo ya eloko: lininisa « Talo ya … » efungwami.",
      "Koma talo oyo boyokani na mosombi mpe simba « Ndima ».",
      "Molongo emonisaka « Talo ya momesano : … » na langi ya orange.",
      "Mpo na kozonga na talo ya momesano: simba molongo sima « Talo ya momesano ».",
    ],
    astuce: "Osengeli kozala na ndingisa « Bakitisi mpe kobimisa ». Soki talo ekiti na se ya talo ya kosomba, nsango ya motane « Ozali koteka na bobungisi » ekebisaka yo. Nkolo amonaka bakitisi nyonso na Ebandeli.",
  ),
  _Rubrique(
    titre: "Koteka na niongo to na kofuta ndambo",
    icone: Icons.receipt_long_rounded,
    couleur: Colors.indigo,
    etapes: [
      "Sala eteki lokola mbala nyonso kino « Zwa mbongo ».",
      "Koma kombo mpe nimero ya telefone ya mosombi (esengeli mpo na niongo).",
      "Koma kaka mbongo oyo mosombi afuti sikoyo (to 0).",
      "Ndima: oyo etikali ekomi niongo ya mosombi, emonanaka na « Niongo ».",
    ],
    astuce: "Na nimero ya telefone, mosombi akoki kozwa nsango ya WhatsApp to SMS na mbongo oyo etikali.",
  ),
  _Rubrique(
    titre: "Kozwa niongo",
    icone: Icons.menu_book_rounded,
    couleur: Colors.indigo,
    etapes: [
      "Fungola « Niongo », sima niongo ya mosombi.",
      "Simba « Zwa », koma mbongo ozwi mpe lolenge ya kofuta.",
      "Simba « Ndima kofuta ». Oyo etikali ekiti.",
      "Soki mosombi apesi KOLEKA niongo na ye, application elobaka ete otia oyo eleki na compte na ye.",
    ],
    astuce: "Oyo eleki ekoki kokende na compte ya mosombi kaka soki niongo ezali na nimero ya telefone.",
  ),
  _Rubrique(
    titre: "Ba compte ya bakiliya (mbongo ya kobomba)",
    icone: Icons.account_balance_wallet_rounded,
    couleur: Colors.teal,
    etapes: [
      "Fungola « Ba compte ya bakiliya » (Ebandeli, eteni « Plus »).",
      "Kotia: mosombi atikaka mbongo liboso. Ebombamaka na compte na ye (ekangami na nimero na ye).",
      "Na Kesi, mbongo ya mosombi ekoki kofuta esombeli nyonso to ndambo.",
      "Kobimisa: kozongisela mosombi mbongo (ndingisa « Bakitisi mpe kobimisa »).",
    ],
  ),
  _Rubrique(
    titre: "Biloko ya kozwa na nsima",
    icone: Icons.local_shipping_rounded,
    couleur: Colors.deepPurple,
    etapes: [
      "Na tango ya kofuta, pona « Ekopesama na nsima ».",
      "Eteki emonanaka na « À livrer » elongo na mokolo ya suka.",
      "Soki mosombi aye kozwa, fungola « À livrer » mpe tia ete epesami.",
    ],
  ),
  _Rubrique(
    titre: "Kokoma mbimisi",
    icone: Icons.upload_rounded,
    couleur: Colors.red,
    etapes: [
      "Simba « Mbimisi » na Ebandeli.",
      "Koma motango mpe ntina (transport, lokasio, courant…).",
      "Bomba: mbimisi ekitisaka « Mbongo na kesi lelo ».",
    ],
    astuce: "Bibimisi ezali kaka mpo na nkolo mpe mokambi.",
    patron: true,
  ),
  _Rubrique(
    titre: "Biloko (stock)",
    icone: Icons.inventory_2_rounded,
    couleur: Color(0xFF0052FF),
    etapes: [
      "Fungola « Biloko » mpo na komona biloko mpe mitango na magazini na yo.",
      "Bakisa eloko na kombo, talo ya kosomba, talo ya koteka mpe motango.",
      "Okoki kokotisa liste ya Excel (packing list): application eyebaka ba colonne.",
      "Biloko oyo ezali kosila emonanaka na « Oyo ya kosala lelo » na Ebandeli.",
    ],
    astuce: "Kobakisa, kobongisa to kolongola eloko esengeli ndingisa « Kokamba stock ».",
    patron: true,
  ),
  _Rubrique(
    titre: "Kotinda biloko na magazini mosusu",
    icone: Icons.swap_horiz_rounded,
    couleur: Colors.brown,
    etapes: [
      "Fungola ecran ya kotinda uta na Biloko.",
      "Pona magazini ya kobima mpe magazini ya kokoma.",
      "Pona biloko mpe mitango (to « Tinda nyonso »).",
      "Ndima: stock ekiti na magazini moko mpe emati na mosusu.",
    ],
    patron: true,
  ),
  _Rubrique(
    titre: "Kozongisa to koboma eteki",
    icone: Icons.assignment_return_rounded,
    couleur: Colors.deepOrange,
    etapes: [
      "Fungola « Biteki » (Ebandeli, eteni « Plus ») mpe luka eteki.",
      "Pona kozongisa (to koboma) mpe biloko oyo etali yango.",
      "Stock emati lisusu. Mbongo ekoki kozongisama to kotiama na compte ya mosombi.",
    ],
    astuce: "Osengeli kozala na ndingisa « Kozongisa mpe koboma ».",
  ),
  _Rubrique(
    titre: "Motuya ya dolare",
    icone: Icons.currency_exchange_rounded,
    couleur: _vert,
    etapes: [
      "Simba « 1 \$ = … FC » na likolo ya Ebandeli.",
      "Koma motuya ya sika mpe simba « Kobomba ».",
      "Ba telefone nyonso ya magazini MOKO ezwaka motuya oyo yango moko.",
      "Magazini moko na moko ezali na motuya na yango (ndakisa Goma mpe Kalemie).",
    ],
    astuce: "Nkolo oyo azali kotala « Ba magazini nyonso » abongolaka kaka motuya ya telefone na ye.",
  ),
  _Rubrique(
    titre: "Kobimisa resi",
    icone: Icons.print_rounded,
    couleur: Colors.blueGrey,
    etapes: [
      "Mibongiseli → carte « Masini ya kobimisa ».",
      "Pona monene ya papie: 58 mm (moke) to 80 mm (monene).",
      "Pona: resi « Ebimi na papie » to « Etindami lokola PDF » (WhatsApp…).",
      "Simba « Bimisa resi ya komeka » mpo na kotala.",
      "Na Kesi, tia elembo « Bimisa resi » liboso ya kondima eteki.",
    ],
    astuce: "Resi ebimaka ata internet ezali te.",
  ),
  _Rubrique(
    titre: "Bokuse ya mpokwa na WhatsApp",
    icone: Icons.send_rounded,
    couleur: Color(0xFF25D366),
    etapes: [
      "Na Ebandeli, simba « Tinda bokuse ya lelo ».",
      "WhatsApp efungwami na nsango esili kokomama (biteki, mbongo, niongo, bibimisi…).",
      "Pona nimero ya nkolo mpe tinda.",
    ],
  ),
  _Rubrique(
    titre: "Ekipe mpe ba ndingisa",
    icone: Icons.groups_rounded,
    couleur: Colors.purple,
    etapes: [
      "Mibongiseli → « Équipe » (kaka nkolo).",
      "Bakisa mosali mpe pona mosala na ye: mokambi to mosali ya kesi.",
      "Pona magazini na ye.",
      "Fungola to kanga ba ndingisa na ye: komona mbongo, kokamba stock, kozongisa, bakitisi mpe kobimisa…",
    ],
    patron: true,
  ),
  _Rubrique(
    titre: "Kosala mosala soki internet ezali te",
    icone: Icons.wifi_off_rounded,
    couleur: Colors.grey,
    etapes: [
      "Okoki koteka ata réseau ezali te.",
      "Biteki ebombamaka na telefone mpe etindamaka soki internet ezongi.",
      "Kolongola application te mpe kobima te liboso réseau ezonga.",
    ],
    astuce: "Fungola data mbala na mbala na moi mpo ete nyonso ekoma na serveur.",
  ),
  _Rubrique(
    titre: "Mikakatano oyo ebimaka mingi",
    icone: Icons.help_rounded,
    couleur: Colors.red,
    etapes: [
      "« Eteki EBOMBAMI TE »: serveur eboyi. Kopesa biloko te, yebisa nkolo.",
      "« Eleki mingi » na niongo: motango eleki oyo mosombi azali na niongo.",
      "« Ndelo ya stock ekoki »: biloko ekoki te na magazini na yo.",
      "Obosani mot de passe to olingi kobongola yango: Mibongiseli → « Compte na ngai ».",
      "Motango moko ezali lokola ebongi te: tala liboso magazini oyo eponami na likolo ya Ebandeli.",
    ],
  ),
];

/// Rubriques dans la langue de l'application (français par défaut)
List<_Rubrique> _rubriquesPour(BuildContext context) {
  switch (Localizations.localeOf(context).languageCode) {
    case 'en':
      return _rubriquesEn;
    case 'sw':
      return _rubriquesSw;
    case 'ln':
      return _rubriquesLn;
    default:
      return _rubriquesFr;
  }
}

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
    final rubriques = _rubriquesPour(context);
    final liste = _recherche.trim().isEmpty
        ? rubriques
        : rubriques.where((r) => r.contient(_recherche.trim())).toList();

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
