// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Nguli';

  @override
  String get settings => 'Paramètres';

  @override
  String get storeInfo => 'Informations du magasin';

  @override
  String get storeName => 'Nom de la boutique';

  @override
  String get address => 'Adresse';

  @override
  String get phone => 'Téléphone';

  @override
  String get saveInfo => 'Enregistrer les informations';

  @override
  String get bccSection => 'Taux BCC & devise active';

  @override
  String get bccRate => 'Taux de change (BCC)';

  @override
  String get activeCurrency => 'Devise principale';

  @override
  String get appLanguage => 'Langue de l\'application';

  @override
  String get reportsExport => 'Exportation des données';

  @override
  String get exportExcel => 'Exporter le stock vers Excel';

  @override
  String get dbMaintenance => 'Maintenance';

  @override
  String get mergeDuplicates => 'Fusionner les doublons';

  @override
  String get teamManagement => 'Gestion de l\'équipe & permissions';

  @override
  String get teamManagementSubtitle =>
      'Ajouter des collaborateurs et gérer leurs droits';

  @override
  String get navAccueil => 'Accueil';

  @override
  String get navCaisse => 'Caisse';

  @override
  String get navStock => 'Stock';

  @override
  String get navRapport => 'Rapport';

  @override
  String get navParametres => 'Paramètres';

  @override
  String accHello(String prenom) {
    return 'Bonjour $prenom 👋';
  }

  @override
  String get tauxTitle => 'Taux du jour';

  @override
  String get cancel => 'Annuler';

  @override
  String get save => 'Enregistrer';

  @override
  String get accToday => 'AUJOURD\'HUI';

  @override
  String get accOfSales => 'de ventes';

  @override
  String get accCashed => 'Encaissé';

  @override
  String get accCredit => 'Crédit';

  @override
  String get accExpenses => 'Dépenses';

  @override
  String accCashInDrawer(String montant) {
    return 'Argent en caisse du jour : $montant';
  }

  @override
  String accDiscounts(String montant) {
    return 'Remises accordées : $montant';
  }

  @override
  String get accSendSummary => 'Envoyer le résumé du jour';

  @override
  String get accExpense => 'Dépense';

  @override
  String get accSales => 'Ventes';

  @override
  String get accClientAccounts => 'Comptes clients';

  @override
  String get accAccounting => 'Comptabilité';

  @override
  String get accHelp => 'Aide';

  @override
  String accTodaySales(int count) {
    return 'Ventes d\'aujourd\'hui ($count)';
  }

  @override
  String get accNoSales =>
      'Pas encore de vente aujourd\'hui.\nAppuyez sur « Caisse » pour commencer.';

  @override
  String get accClient => 'Client';

  @override
  String accRemaining(String montant) {
    return 'reste $montant';
  }

  @override
  String get accMainShop => 'Boutique principale';

  @override
  String get resMorning => 'Bonjour';

  @override
  String get resAfternoon => 'Bon après-midi';

  @override
  String get resEvening => 'Bonsoir';

  @override
  String get resNoSales =>
      'Pas encore de vente aujourd\'hui. Bonne journée de travail ! 💪';

  @override
  String get resTodayPrefix => 'Aujourd\'hui, ';

  @override
  String resSalesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ventes',
      one: '1 vente',
    );
    return '$_temp0';
  }

  @override
  String get resFor => ' pour ';

  @override
  String get resGained => '. Vous avez gagné ';

  @override
  String get resLoss => '. Pour l\'instant, perte de ';

  @override
  String get todoTitle => '📋 À faire aujourd\'hui';

  @override
  String get todoNothing => '✅ Rien d\'urgent. Tout est en ordre !';

  @override
  String todoOwes(String nom, String montant) {
    return '$nom vous doit $montant';
  }

  @override
  String todoOtherClients(int count) {
    return '…et $count autre(s) client(s)';
  }

  @override
  String todoOut(String nom) {
    return '$nom : épuisé';
  }

  @override
  String todoLow(int count, String nom) {
    return 'Il reste seulement $count $nom';
  }

  @override
  String todoOtherProducts(int count) {
    return '…et $count autre(s) produit(s) à recommander';
  }

  @override
  String get actSee => 'Voir';

  @override
  String get actAll => 'Tous';

  @override
  String get caisseNoCompany => 'Erreur : Aucune entreprise sélectionnée.';

  @override
  String caisseOutOfStock(String nom) {
    return '$nom est en rupture de stock !';
  }

  @override
  String caisseStockLimit(int count) {
    return 'Limite du stock atteinte ($count)';
  }

  @override
  String caisseAdded(String nom) {
    return '$nom ajouté au panier !';
  }

  @override
  String caisseNoBarcode(String code) {
    return 'Aucun produit trouvé pour le code : $code';
  }

  @override
  String get caisseSearch => 'Rechercher un produit…';

  @override
  String get caisseScan => 'Scanner un code-barres';

  @override
  String errorPrefix(String message) {
    return 'Erreur : $message';
  }

  @override
  String get caisseNoProducts =>
      'Aucun produit enregistré.\nAjoutez vos produits dans l\'onglet « Stock ».';

  @override
  String get caisseHint =>
      'Touchez un produit pour l\'ajouter • appui long : quantité';

  @override
  String get caisseNoMatch => 'Aucun produit ne correspond à votre recherche.';

  @override
  String caisseCheckout(String montant) {
    return 'Encaisser $montant';
  }

  @override
  String get caisseNoName => 'Sans nom';

  @override
  String get caisseOut => 'Épuisé';

  @override
  String get caissePriceNeedsPermission =>
      'Changer le prix demande l\'autorisation « Remises et retraits ».';

  @override
  String get cartTitle => 'Panier d\'achat';

  @override
  String get cartEmpty => 'Votre panier est vide';

  @override
  String cartCount(int count) {
    return 'Panier ($count références)';
  }

  @override
  String get cartClear => 'Vider le panier';

  @override
  String cartNormalPrice(String montant) {
    return 'Prix normal : $montant';
  }

  @override
  String get cartLoss => 'Vente à perte';

  @override
  String addTitle(String nom) {
    return 'Ajouter $nom';
  }

  @override
  String lossConfirm(String nom) {
    return 'Le prix de $nom est sous le prix d\'achat.\nVoulez-vous vraiment vendre à ce prix ?';
  }

  @override
  String get noCorrect => 'Non, corriger';

  @override
  String get yesSell => 'Oui, vendre';

  @override
  String stockAvailable(int count) {
    return 'Stock disponible : $count';
  }

  @override
  String unitPrice(String code) {
    return 'Prix unitaire ($code)';
  }

  @override
  String discountPerPiece(String montant) {
    return 'Remise : $montant par pièce';
  }

  @override
  String get fixedPrice =>
      'Prix fixe (autorisation « Remises et retraits » nécessaire)';

  @override
  String lossWithCost(String montant) {
    return 'Vente à perte ! Prix d\'achat : $montant';
  }

  @override
  String get lossBelowCost =>
      'Vente à perte : ce prix est sous le prix d\'achat.';

  @override
  String get qtyInvalid => 'Quantité invalide';

  @override
  String maxAvailable(int count) {
    return 'Max disponible : $count';
  }

  @override
  String get quantity => 'Quantité';

  @override
  String get subtotal => 'Sous-total :';

  @override
  String qtyOverStock(int count) {
    return 'Quantité supérieure au stock disponible ($count)';
  }

  @override
  String get outOfStockGeneric => 'Produit en rupture de stock !';

  @override
  String get sellAtLoss => 'Vendre à perte';

  @override
  String get add => 'Ajouter';

  @override
  String priceFor(String nom) {
    return 'Prix pour $nom';
  }

  @override
  String get agreedPrice => 'Prix accordé (par pièce)';

  @override
  String get normalPriceBtn => 'Prix normal';

  @override
  String get validate => 'Valider';

  @override
  String get payTitle => 'Finaliser la vente & Règlement';

  @override
  String get payClientName => 'Nom du Client';

  @override
  String get payPhone => 'Téléphone (ex: +243...)';

  @override
  String payClientAccount(String montant) {
    return 'Compte client : $montant';
  }

  @override
  String get payUse => 'Utiliser';

  @override
  String payPaidByAccount(String montant, String solde) {
    return 'Payé par le compte : $montant • Nouveau solde : $solde';
  }

  @override
  String get payMethod => 'Moyen';

  @override
  String get payStatus => 'Statut';

  @override
  String get payCash => 'Cash';

  @override
  String get payCard => 'Carte bancaire';

  @override
  String get payTransfer => 'Virement';

  @override
  String get payPaid => 'Payé';

  @override
  String get payDebt => 'Dette';

  @override
  String get payPartial => 'Paiement partiel';

  @override
  String get payInvoiceTotal => 'Total Facture :';

  @override
  String get payPaidByClientAccount => 'Payé par compte client :';

  @override
  String get payToCollect => 'À encaisser maintenant :';

  @override
  String payAllIn(String code) {
    return 'Tout en $code';
  }

  @override
  String payRestIn(String code) {
    return 'Reste en $code';
  }

  @override
  String payReceived(String code) {
    return 'Montant Perçu ($code)';
  }

  @override
  String get payRemaining => 'Reste dû :';

  @override
  String payChange(String code) {
    return 'Monnaie à rendre ($code) :';
  }

  @override
  String get payDelivery => 'Livraison';

  @override
  String get payDeliveredNow => 'Livré maintenant';

  @override
  String get payDeliverLater => 'À livrer plus tard';

  @override
  String get payPickupBefore => 'À retirer avant';

  @override
  String payDeadline(String date) {
    return 'Date limite : $date — le client apparaîtra dans « À livrer ».';
  }

  @override
  String payDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours',
      one: '1 jour',
    );
    return '$_temp0';
  }

  @override
  String get payReceiptActions => 'Actions pour le reçu :';

  @override
  String get payPrintReceipt => 'Imprimer le reçu thermique';

  @override
  String get paySendWhatsApp => 'Envoyer par WhatsApp';

  @override
  String get paySendSms => 'Envoyer par SMS';

  @override
  String get payValidate => 'Valider & Encaisser';

  @override
  String payBalanceChanged(String montant) {
    return 'Le solde du client a changé (disponible : $montant \$). Désactivez puis réactivez « Utiliser » pour recalculer.';
  }

  @override
  String get payNotSaved => 'Vente NON enregistrée';

  @override
  String payDenied(String code) {
    return 'Le serveur a refusé cette vente (droits insuffisants).\n\nRien n\'a été enregistré : ni la vente, ni le stock, ni la caisse.\nNe donnez pas encore la marchandise : prévenez le responsable.\n\nCode : $code';
  }

  @override
  String payNotSavedOther(String detail) {
    return 'Rien n\'a été enregistré.\n\n$detail';
  }

  @override
  String get payUnderstood => 'Compris';

  @override
  String get paySaved => 'Vente enregistrée avec succès !';

  @override
  String paySavedPickup(String date) {
    return 'Vente enregistrée — à retirer avant le $date.';
  }

  @override
  String payNewBalance(String montant) {
    return ' Nouveau solde du client : $montant.';
  }

  @override
  String payError(String message) {
    return 'Erreur lors de la validation : $message';
  }

  @override
  String get debtNewClient => 'Nouvelle Créance Client';

  @override
  String get debtNewSupplier => 'Nouvelle Dette Fournisseur';

  @override
  String get debtClientName => 'Nom du Client *';

  @override
  String get debtSupplierName => 'Nom du Fournisseur *';

  @override
  String get debtInvoiceRef => 'N° Facture / Référence';

  @override
  String get debtTotal => 'Montant Total *';

  @override
  String get debtAlreadyPaid => 'Montant déjà payé (paiement partiel)';

  @override
  String get debtPickDueDate => 'Sélectionner une date d\'échéance';

  @override
  String debtDueDate(String date) {
    return 'Échéance : $date';
  }

  @override
  String get debtNote => 'Motif (facultatif)';

  @override
  String get debtPaidOverTotal =>
      'Le montant déjà payé dépasse le montant total.';

  @override
  String debtPaymentTitle(String nom) {
    return 'Règlement : $nom';
  }

  @override
  String debtInvoiceNo(String numero) {
    return 'Facture N° : $numero';
  }

  @override
  String debtRemainingNow(String montant) {
    return 'Reste à payer actuel : $montant';
  }

  @override
  String get debtPaymentAmount => 'Montant du Règlement';

  @override
  String debtHelperSurplus(String montant) {
    return 'Reste : $montant. Un surplus peut aller sur son compte client.';
  }

  @override
  String debtMax(String montant) {
    return 'Maximum : $montant';
  }

  @override
  String get debtPaymentMode => 'Mode de paiement';

  @override
  String get debtCashDesk => 'Espèces (Caisse)';

  @override
  String get debtCheck => 'Chèque';

  @override
  String get debtEnterAmount => 'Saisissez un montant.';

  @override
  String debtTooHighNoPhone(String montant) {
    return 'Trop élevé. Maximum : $montant (client sans numéro : pas de compte client)';
  }

  @override
  String debtTooHigh(String montant) {
    return 'Trop élevé. Maximum : $montant';
  }

  @override
  String get debtGivesMore => 'Le client donne plus';

  @override
  String debtSurplusQuestion(
      String dette, String donne, String surplus, String nom) {
    return 'Dette : $dette\nDonné : $donne\n\nMettre $surplus sur le compte client de $nom ?\nIl pourra s\'en servir pour ses prochains achats.';
  }

  @override
  String get debtYesAccount => 'Oui, sur son compte';

  @override
  String debtSettled(String montant, String nom) {
    return 'Dette soldée. $montant mis sur le compte de $nom.';
  }

  @override
  String get debtPendingNet => ' (envoi dès le retour d\'internet)';

  @override
  String debtPaymentSaved(String montant) {
    return 'Règlement de $montant enregistré.';
  }

  @override
  String get debtValidatePayment => 'Valider le Règlement';

  @override
  String get debtScreenTitle => 'Créances & Dettes';

  @override
  String get debtExport => 'Exporter';

  @override
  String get debtExportExcel => 'Exporter vers Excel';

  @override
  String get debtPrintPdf => 'Imprimer / PDF';

  @override
  String get debtTabClients => 'Clients';

  @override
  String get debtTabSuppliers => 'Fournisseurs';

  @override
  String debtLoadError(String message) {
    return 'Erreur de chargement : $message';
  }

  @override
  String get debtAdd => 'Ajouter une dette';

  @override
  String get ageToday => 'Aujourd\'hui';

  @override
  String get ageYesterday => 'Hier';

  @override
  String ageDays(int count) {
    return 'Il y a $count jours';
  }

  @override
  String ageMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Il y a $count mois',
      one: 'Il y a 1 mois',
    );
    return '$_temp0';
  }

  @override
  String get whatsAppError => 'Impossible d\'ouvrir WhatsApp sur cet appareil.';

  @override
  String get debtEmptyClients => 'Aucune créance client';

  @override
  String get debtEmptySuppliers => 'Aucune dette fournisseur';

  @override
  String get debtEmptyClientsHint =>
      'Les ventes à crédit ou partielles apparaîtront ici automatiquement.';

  @override
  String get debtEmptySuppliersHint =>
      'Ajoutez ici ce que vous devez à vos fournisseurs avec le bouton « Ajouter une dette ».';

  @override
  String get noResults => 'Aucun résultat';

  @override
  String get noResultsHint => 'Essayez un autre filtre ou une autre recherche.';

  @override
  String get debtToCollect => 'À RECOUVRER (CLIENTS)';

  @override
  String get debtToPay => 'À PAYER (FOURNISSEURS)';

  @override
  String debtOpenFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'dossiers ouverts',
      one: 'dossier ouvert',
    );
    return '$_temp0';
  }

  @override
  String debtClientsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'clients',
      one: 'client',
    );
    return '$_temp0';
  }

  @override
  String debtSuppliersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'fournisseurs',
      one: 'fournisseur',
    );
    return '$_temp0';
  }

  @override
  String debtLateCount(int count) {
    return 'en retard ($count)';
  }

  @override
  String get debtSearchClients =>
      'Rechercher un client, une facture, un téléphone…';

  @override
  String get debtSearchSuppliers => 'Rechercher un fournisseur, une facture…';

  @override
  String get filterOngoing => 'En cours';

  @override
  String get filterRecent => 'Récentes (< 30 j)';

  @override
  String get filterLate => 'En retard';

  @override
  String get filterPartial => 'Partielles';

  @override
  String get filterSettled => 'Soldées';

  @override
  String get statusSettled => 'Soldée';

  @override
  String get statusPartial => 'Partiel';

  @override
  String get statusUnpaid => 'Non payée';

  @override
  String invoiceShort(String numero) {
    return 'Fact. $numero';
  }

  @override
  String paidOf(String paye, String total) {
    return 'Payé $paye sur $total';
  }

  @override
  String lastPayment(String date) {
    return 'Dernier paiement $date';
  }

  @override
  String get remind => 'Relancer';

  @override
  String get message => 'Message';

  @override
  String get collect => 'Encaisser';

  @override
  String get pay => 'Payer';

  @override
  String printFailed(String message) {
    return 'Impression impossible : $message';
  }

  @override
  String get printerTitle => 'Imprimante';

  @override
  String get printerPhoneOnly => 'Réglages de ce téléphone seulement';

  @override
  String get printerPaperWidth => 'Largeur du papier';

  @override
  String get printer58 => '58 mm (petite)';

  @override
  String get printer80 => '80 mm (grande)';

  @override
  String get printerAfterSale => 'Après une vente, le reçu…';

  @override
  String get printerPrints => 'S\'imprime';

  @override
  String get printerPrintsHint =>
      'Fenêtre d\'impression d\'Android (imprimante installée sur le téléphone)';

  @override
  String get printerPdf => 'Est envoyé en PDF';

  @override
  String get printerPdfHint =>
      'WhatsApp, Bluetooth, e-mail… (quand il n\'y a pas d\'imprimante)';

  @override
  String get printerTest => 'Imprimer un reçu d\'essai';

  @override
  String get crashTest => 'Tester les rapports d\'erreurs';

  @override
  String get crashDebugOnly =>
      'Les rapports ne partent que depuis l\'APK (pas au câble).';

  @override
  String get crashSent =>
      'Rapport de test envoyé. Il apparaît dans Firebase sous quelques minutes.';

  @override
  String get guideTitle => 'Guide d\'utilisation';

  @override
  String get guideSubtitle => 'Comment vendre, encaisser une dette, imprimer…';

  @override
  String get guideSearch => 'Chercher : dette, taux, imprimer…';

  @override
  String guideNotFound(String mot) {
    return 'Rien trouvé pour « $mot ».';
  }

  @override
  String get guideOwnerOnly => 'Patron / gérant';

  @override
  String stockDeleted(String nom) {
    return '« $nom » supprimé.';
  }

  @override
  String stockDeletedOffline(String nom) {
    return '« $nom » supprimé sur le téléphone. Envoi dès le retour d\'internet.';
  }

  @override
  String stockDeleteError(String message) {
    return 'Erreur lors de la suppression : $message';
  }

  @override
  String get stockAnalyzing => 'Analyse...';

  @override
  String stockImported(int count) {
    return '$count produit(s) importé(s) ou mis à jour avec succès !';
  }

  @override
  String stockImportError(String message) {
    return 'Erreur d\'importation : $message';
  }

  @override
  String stockConnected(String nom) {
    return 'Connecté: $nom';
  }

  @override
  String get stockImportTooltip => 'Importer Excel / CSV / Packing List';

  @override
  String get myAccount => 'Mon compte';

  @override
  String get changePassword => 'Changer mon mot de passe';

  @override
  String get logout => 'Se déconnecter';

  @override
  String get stockNoProduct => 'Aucun produit trouvé.';

  @override
  String get stockProducts => 'Produits';

  @override
  String get stockValue => 'Valeur Stock';

  @override
  String get stockCannotDelete => 'Suppression impossible';

  @override
  String stockCannotDeleteMsg(String nom, int count) {
    return '« $nom » a encore $count article(s) en stock.\n\nMettez d\'abord le stock à 0 (inventaire ou perte), pour que la perte reste visible dans les comptes.';
  }

  @override
  String get stockDeleteTitle => 'Supprimer le produit';

  @override
  String stockDeleteConfirm(String nom) {
    return 'Voulez-vous vraiment supprimer « $nom » ?\n\nCette action est définitive.';
  }

  @override
  String get delete => 'Supprimer';

  @override
  String get stockNewProduct => 'Nouveau Produit';

  @override
  String stockQty(int count) {
    return 'Stock: $count';
  }

  @override
  String get stockAlert => 'Alerte stock';

  @override
  String get edit => 'Modifier';

  @override
  String get prodDefaultName => 'Produit sans nom';

  @override
  String get prodBarcodeUsed => 'Code-barres déjà utilisé';

  @override
  String prodBarcodeUsedMsg(String nom, String stock, String prix) {
    return 'Ce code appartient déjà à :\n\n« $nom »\nStock : $stock  •  Prix : $prix \$\n\nVoulez-vous ouvrir ce produit pour le modifier (par exemple ajouter du stock) ?';
  }

  @override
  String get prodOpenThis => 'Ouvrir ce produit';

  @override
  String get prodNoCompany =>
      'Entreprise introuvable. Déconnectez-vous puis reconnectez-vous.';

  @override
  String get prodSavedOffline =>
      'Enregistré sur le téléphone. Il sera envoyé dès que internet revient.';

  @override
  String get prodUpdated => 'Produit mis à jour avec succès !';

  @override
  String get prodAdded => 'Produit ajouté avec succès !';

  @override
  String prodSaveError(String message) {
    return 'Erreur lors de l\'enregistrement : $message';
  }

  @override
  String get prodEditTitle => 'Modifier le produit';

  @override
  String get prodImportPacking => 'Importer Packing List (Excel / CSV)';

  @override
  String get prodOrManual => 'OU SAISIE MANUELLE';

  @override
  String get prodImageUrl => 'URL de l\'image';

  @override
  String get prodImageUrlOpt => 'URL de l\'image (optionnel)';

  @override
  String get prodName => 'Nom du produit *';

  @override
  String get prodNameHint => 'ex: T-Shirt Coton';

  @override
  String get prodNameRequired => 'Nom obligatoire';

  @override
  String get prodBarcode => 'Code-barres';

  @override
  String get prodBarcodeHint => 'Scanner / Saisir';

  @override
  String get prodCategory => 'Catégorie';

  @override
  String get prodBuyPrice => 'Prix d\'achat (\$)';

  @override
  String get prodInvalidPrice => 'Prix invalide';

  @override
  String get prodSellPrice => 'Prix vente (\$)*';

  @override
  String get prodPriceRequired => 'Prix requis';

  @override
  String get prodStock => 'Stock *';

  @override
  String get prodInitialStock => 'Stock initial *';

  @override
  String get prodStockRequired => 'Stock requis';

  @override
  String get prodWholeNumber => 'Nombre entier';

  @override
  String get prodAlertLevel => 'Seuil d\'alerte';

  @override
  String get prodSaving => 'Enregistrement...';

  @override
  String get prodUpdate => 'Mettre à jour';

  @override
  String get prodSave => 'Enregistrer le produit';

  @override
  String get msgLanguage => 'Langue du message';

  @override
  String get sumDays => 'lundi,mardi,mercredi,jeudi,vendredi,samedi,dimanche';

  @override
  String get sumAllShops => 'Toutes les boutiques';

  @override
  String sumSales(int count, String montant) {
    return 'Ventes : $count pour $montant';
  }

  @override
  String sumCollected(String montant) {
    return 'Encaissé : $montant';
  }

  @override
  String sumCredit(String montant) {
    return 'Crédit : $montant';
  }

  @override
  String sumExpenses(String montant) {
    return 'Dépenses : $montant';
  }

  @override
  String sumCash(String montant) {
    return '💵 Argent en caisse : $montant';
  }

  @override
  String sumProfit(String montant) {
    return '📈 Bénéfice : $montant';
  }

  @override
  String sumRate(String taux) {
    return 'Taux : 1 \$ = $taux FC';
  }

  @override
  String sumSentBy(String nom) {
    return 'Envoyé par $nom — Nguli';
  }

  @override
  String get logoutQuestion => 'Se déconnecter ?';

  @override
  String get logoutWarning =>
      'Vous devrez vous reconnecter avec votre e-mail et votre mot de passe.';

  @override
  String get exportDone => 'Exportation Excel terminée avec succès !';

  @override
  String exportError(String message) {
    return 'Erreur d\'exportation : $message';
  }

  @override
  String get attention => 'Attention';

  @override
  String get mergeConfirm =>
      'Voulez-vous vraiment fusionner les produits en double ? Cette action est irréversible.';

  @override
  String get mergeDone => 'Nettoyage des doublons terminé avec succès !';

  @override
  String get confirmBtn => 'Confirmer';

  @override
  String get backfillTitle => 'Rattraper le coût des anciennes ventes';

  @override
  String get backfillExplain =>
      'Les anciennes ventes qui n\'ont pas encore d\'écriture « Sortie de stock » vont en recevoir une, à leur date d\'origine.\n\nLe coût est calculé avec le prix d\'achat ACTUEL de chaque produit.\n\nVous pouvez relancer cette opération sans risque : une vente n\'est jamais comptée deux fois.';

  @override
  String get launch => 'Lancer';

  @override
  String get backfillRunning => 'Rattrapage en cours…';

  @override
  String get backfillNothing => 'Rien à rattraper';

  @override
  String get backfillDone => 'Rattrapage terminé';

  @override
  String backfillAllDone(String count) {
    return 'Toutes les ventes ($count) ont déjà leur écriture « Sortie de stock ».';
  }

  @override
  String backfillResult(String nb, String total, String cout) {
    return '$nb vente(s) rattrapée(s) sur $total.\n\nCoût des marchandises ajouté : $cout \$';
  }

  @override
  String backfillNoPrice(String count) {
    return '⚠️ $count article(s) sans prix d\'achat : leur coût est compté à 0. Complétez leur prix d\'achat puis relancez.';
  }

  @override
  String get backfillOffline =>
      'Enregistré sur le téléphone : l\'envoi se fera au retour d\'internet.';

  @override
  String get error => 'Erreur';

  @override
  String backfillFailed(String message) {
    return 'Le rattrapage n\'a pas pu se faire : $message';
  }

  @override
  String get maintTitle => 'Maintenance & Base de données';

  @override
  String get shopTitle => 'Mes boutiques';

  @override
  String get shopCardSubtitle => 'Créer et gérer vos points de vente';

  @override
  String get shopNew => 'Nouvelle boutique';

  @override
  String get shopEditTitle => 'Modifier la boutique';

  @override
  String get shopNameLabel => 'Nom de la boutique *';

  @override
  String get shopNameHint => 'Ex : Boutique Birere';

  @override
  String get shopNameError => 'Entrez un nom (2 lettres minimum)';

  @override
  String get shopAddress => 'Adresse (facultatif)';

  @override
  String get shopPhone => 'Téléphone (facultatif)';

  @override
  String shopCreated(String nom) {
    return 'Boutique « $nom » créée';
  }

  @override
  String get shopUpdated => 'Boutique modifiée';

  @override
  String shopReactivated(String nom) {
    return '« $nom » réactivée';
  }

  @override
  String shopDeactivated(String nom) {
    return '« $nom » désactivée';
  }

  @override
  String get shopTransfersTooltip => 'Transferts de stock';

  @override
  String shopLoadError(String message) {
    return 'Impossible de charger les boutiques : $message';
  }

  @override
  String get shopInfo =>
      'Stock de la boutique principale = stock total − stock des autres boutiques. Utilisez « Transférer du stock » pour approvisionner une boutique, et « Prix par boutique » pour adapter les prix à chaque marché.';

  @override
  String get shopTransferTitle => 'Transférer du stock';

  @override
  String get shopTransferSubtitle =>
      'Envoyer de la marchandise d\'une boutique à l\'autre';

  @override
  String get shopPricesTitle => 'Prix par boutique';

  @override
  String get shopPricesSubtitle =>
      'Adapter les prix de vente au marché de chaque boutique';

  @override
  String get shopMainBadge => 'Principale';

  @override
  String get shopDisabledBadge => 'Désactivée';

  @override
  String get shopNoAddress => 'Aucune adresse';

  @override
  String get shopDeactivate => 'Désactiver';

  @override
  String get shopReactivate => 'Réactiver';

  @override
  String get teamTitle => 'Gestion de l\'équipe';

  @override
  String get teamOwnerOnly => 'Accès réservé au propriétaire de la boutique.';

  @override
  String get teamNoMembers =>
      'Aucun employé pour l\'instant.\nAppuyez sur « Nouveau membre » pour créer le compte d\'un caissier ou d\'un gérant.';

  @override
  String get teamNewMember => 'Nouveau membre';

  @override
  String get teamAccountCreated => 'Compte créé';

  @override
  String teamGiveInfo(String nom) {
    return 'Donnez ces informations à $nom :';
  }

  @override
  String get teamLogin => 'Identifiant';

  @override
  String get teamPassword => 'Mot de passe';

  @override
  String get teamNoteNow =>
      'Notez-les maintenant : le mot de passe ne sera plus affiché.';

  @override
  String get teamCopy => 'Copier';

  @override
  String get teamCopied => 'Copié !';

  @override
  String get teamFullName => 'Nom complet';

  @override
  String get teamNameRequired => 'Nom obligatoire';

  @override
  String get teamLoginLabel => 'Identifiant (ex : grace)';

  @override
  String teamLoginPreview(String login) {
    return 'Connexion : $login';
  }

  @override
  String get teamLoginMin => '3 lettres ou chiffres minimum';

  @override
  String get teamPasswordMin => '6 caractères minimum';

  @override
  String get teamRole => 'Rôle';

  @override
  String get teamRoleLabel => 'Rôle :';

  @override
  String get roleOwner => 'Propriétaire';

  @override
  String get roleManager => 'Gérant';

  @override
  String get roleCashier => 'Caissier';

  @override
  String get teamManagerInfo =>
      'Un gérant a toutes les autorisations par défaut. Vous pourrez en retirer ensuite.';

  @override
  String get teamCashierInfo =>
      'Un caissier n\'a aucune autorisation spéciale par défaut. Vous pourrez en donner ensuite.';

  @override
  String get teamCreateAccount => 'Créer le compte';

  @override
  String teamYou(String nom) {
    return '$nom (vous)';
  }

  @override
  String get teamOwnerAll => 'Le propriétaire a tous les droits.';

  @override
  String get teamRoleChanged => 'Rôle modifié';

  @override
  String get teamActive => 'Compte actif';

  @override
  String get teamCanLogin => 'Peut se connecter';

  @override
  String get teamDisabledInfo => 'Désactivé : ne peut plus travailler';

  @override
  String get teamReactivated => 'Compte réactivé';

  @override
  String get teamDeactivated => 'Compte désactivé';

  @override
  String teamPermissions(int count, int total) {
    return 'Autorisations ($count/$total)';
  }

  @override
  String get teamManagerDefault =>
      'Par défaut pour un gérant : tout est autorisé';

  @override
  String get teamCashierDefault =>
      'Par défaut pour un caissier : rien de spécial';

  @override
  String teamPermGranted(String perm, String nom) {
    return '« $perm » autorisé pour $nom';
  }

  @override
  String teamPermRemoved(String perm, String nom) {
    return '« $perm » retiré à $nom';
  }

  @override
  String get permFinances => 'Voir les finances';

  @override
  String get permFinancesDesc => 'P&L, comptabilité, prix d\'achat et marges.';

  @override
  String get permReturns => 'Retours et annulations';

  @override
  String get permReturnsDesc =>
      'Enregistrer un retour ou annuler une vente non retirée.';

  @override
  String get permStock => 'Gérer le stock';

  @override
  String get permStockDesc =>
      'Ajouter, modifier, supprimer des produits, importer un fichier.';

  @override
  String get permDiscounts => 'Remises et retraits';

  @override
  String get permDiscountsDesc =>
      'Changer les prix à la caisse et retirer de l\'argent d\'un compte client.';

  @override
  String get permMaintenance => 'Maintenance des données';

  @override
  String get permMaintenanceDesc =>
      'Paramètres : rattraper les coûts, fusionner les doublons.';

  @override
  String get histTitle => 'Historique des ventes';

  @override
  String get histSearch => 'Client, téléphone ou n° de facture…';

  @override
  String get histToday => 'Aujourd\'hui';

  @override
  String get hist7Days => '7 jours';

  @override
  String get hist30Days => '30 jours';

  @override
  String get histAllTime => 'Tout';

  @override
  String histLoadError(String message) {
    return 'Erreur de chargement : $message';
  }

  @override
  String histSalesOf(String nom) {
    return 'Ventes de $nom';
  }

  @override
  String get histTotal => 'Total';

  @override
  String get histRemaining => 'Reste';

  @override
  String get histNoResult => 'Aucune vente pour cette recherche.';

  @override
  String get histPaid => 'Payé';

  @override
  String get histPartial => 'Partiel';

  @override
  String get histDebt => 'Dette';

  @override
  String get histCancelledSale => 'Annulée';

  @override
  String get histToDeliver => 'À livrer';

  @override
  String get histDelivered => 'Livré';

  @override
  String get histPartialCancel => 'Annulation partielle';

  @override
  String get histFullReturn => 'Retour total';

  @override
  String get histPartialReturn => 'Retour partiel';

  @override
  String histInvoice(String numero) {
    return 'Facture $numero';
  }

  @override
  String get histPrint => 'Imprimer';

  @override
  String get histShare => 'Partager (WhatsApp, e-mail…)';

  @override
  String histInvoiceError(String message) {
    return 'Impossible de créer la facture : $message';
  }

  @override
  String histDeliveredOn(String date) {
    return 'Livré le $date';
  }

  @override
  String get histItems => 'Articles';

  @override
  String histReturnedQty(int count) {
    return '↩ $count retourné(s)';
  }

  @override
  String histCancelledQty(int count) {
    return '✕ $count annulé(s)';
  }

  @override
  String get histReturned => 'Retourné';

  @override
  String get histCancelled => 'Annulé';

  @override
  String get histNetTotal => 'Total net';

  @override
  String get histToPay => 'Reste à payer';

  @override
  String get histMethod => 'Moyen';

  @override
  String get histSoldBy => 'Vendu par';

  @override
  String get histDeliveredBy => 'Livré par';

  @override
  String get histPdfButton => 'Facture PDF (imprimer / WhatsApp)';

  @override
  String get histDeliveryNote => 'Bon de livraison';

  @override
  String get histReturnGoods => 'Retour de marchandise';

  @override
  String get histCancelSale => 'Annuler la vente (non retirée)';

  @override
  String histArticles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count articles',
      one: '1 article',
    );
    return '$_temp0';
  }

  @override
  String histBy(String nom) {
    return 'par $nom';
  }

  @override
  String get histWalkIn => 'Client divers';

  @override
  String get ddMotif => 'Motif';

  @override
  String get ddNoItems => 'Aucun article : dette ajoutée à la main.';

  @override
  String get ddItemsError => 'Impossible de charger les articles.';

  @override
  String get ddCall => 'Appeler';

  @override
  String get ddPdf => 'Facture PDF';

  @override
  String get ddDetails => 'Détails';

  @override
  String ddDiscount(String montant) {
    return 'Remise accordée : $montant';
  }

  @override
  String ddDate(String date) {
    return 'Date : $date';
  }

  @override
  String get ddPayments => 'Historique des paiements';

  @override
  String get ddPaidBefore => 'Payé avant (à la vente ou plus tôt)';

  @override
  String get ddNoPayments => 'Aucun paiement pour l\'instant.';

  @override
  String get payMotif => 'Motif du crédit (facultatif)';

  @override
  String get payMotifHint => 'Ex : paiera vendredi après le marché';

  @override
  String accDebtsCollected(String montant) {
    return 'Dettes encaissées : $montant';
  }

  @override
  String accDebtsCollectedTitle(int count) {
    return 'Dettes encaissées aujourd\'hui ($count)';
  }

  @override
  String get repChoiceTitle => 'Quel résumé envoyer ?';

  @override
  String get repShort => 'Résumé court';

  @override
  String get repShortHint => 'Les totaux du jour';

  @override
  String get repDetailed => 'Rapport détaillé';

  @override
  String get repDetailedHint =>
      'Chaque vente, produits, vendeurs, dépenses, dettes, stock';

  @override
  String repSales(int count, String montant) {
    return '🛒 VENTES ($count) : $montant';
  }

  @override
  String get repProducts => '📦 PRODUITS VENDUS';

  @override
  String get repBySeller => '👤 PAR VENDEUR';

  @override
  String get repByMethod => '💳 PAR MOYEN DE PAIEMENT';

  @override
  String repExpenses(String montant) {
    return '💸 DÉPENSES ($montant)';
  }

  @override
  String repDebtsCollected(String montant) {
    return '💰 DETTES ENCAISSÉES ($montant)';
  }

  @override
  String repNewCredits(String montant) {
    return '📝 NOUVEAUX CRÉDITS ($montant)';
  }

  @override
  String get repToReorder => '⚠️ À RECOMMANDER';

  @override
  String repCredit(String montant) {
    return 'crédit $montant';
  }

  @override
  String repMore(int count) {
    return '…et $count autre(s)';
  }

  @override
  String get retCancelTitle => 'Annuler la vente';

  @override
  String get retNoCancelRight =>
      'Seuls le gérant et le patron peuvent annuler une vente.';

  @override
  String get retNoReturnRight =>
      'Seuls le gérant et le patron peuvent enregistrer un retour.';

  @override
  String retTooLate(String date, int jours, int limite) {
    return 'Délai de retour dépassé : vente du $date (il y a $jours jours, limite $limite jours).\n\nSeul le patron peut accepter ce retour.';
  }

  @override
  String get retNothingToCancel =>
      'Rien à annuler sur cette vente.\n\nToute la marchandise a déjà été remise au client ou déjà annulée. S\'il la rapporte, utilisez « Retour de marchandise ».';

  @override
  String get retNothingToReturn =>
      'Rien à retourner sur cette vente.\n\nSoit tout a déjà été retourné, soit la marchandise n\'a pas encore été remise au client (dans ce cas, utilisez « Annuler la vente »).';

  @override
  String get retModeAvoirHint =>
      'Le montant est ajouté au compte client : il pourra l\'utiliser en Caisse.';

  @override
  String get retModeKeepHint =>
      'La boutique garde l\'argent (acompte non remboursé).';

  @override
  String get retModeCashHint => 'L\'argent sort de la caisse.';

  @override
  String retSaleOf(String date, String age) {
    return 'Vente du $date • $age';
  }

  @override
  String retInvoiceAmount(String montant) {
    return 'Facture : $montant';
  }

  @override
  String retStillOwes(String montant) {
    return 'Le client doit encore : $montant';
  }

  @override
  String get retCancelInfo =>
      'Marchandise jamais retirée par le client : elle revient en stock et la vente est annulée pour ces articles.';

  @override
  String retLateAccepted(int jours) {
    return 'Hors délai ($jours jours) : retour accepté exceptionnellement par le patron.';
  }

  @override
  String get retItemsToCancel => 'Articles à annuler';

  @override
  String get retItemsReturned => 'Articles rapportés';

  @override
  String retPrice(String montant) {
    return 'Prix : $montant';
  }

  @override
  String retNotPicked(int count) {
    return 'non retiré : $count';
  }

  @override
  String retReturnable(int count) {
    return 'retournable : $count';
  }

  @override
  String retAlreadyReturned(int count) {
    return 'déjà retourné : $count';
  }

  @override
  String get retResell => 'Remettre en vente';

  @override
  String get retDamaged => 'Abîmé (perte)';

  @override
  String get retCancelAll => 'Tout annuler';

  @override
  String get retCancelReason => 'Motif de l\'annulation *';

  @override
  String get retReturnReason => 'Motif du retour *';

  @override
  String get retCancelHint => 'Ex : client jamais venu, délai dépassé…';

  @override
  String get retReturnHint => 'Ex : mauvaise taille, défaut de fabrication…';

  @override
  String retCancelledAmount(String montant) {
    return 'Montant annulé : $montant';
  }

  @override
  String retReturnAmount(String montant) {
    return 'Montant du retour : $montant';
  }

  @override
  String retDeducted(String montant) {
    return 'Déduit de la dette du client : $montant';
  }

  @override
  String retAlreadyPaid(String montant) {
    return 'Déjà payé par le client : $montant';
  }

  @override
  String retToGiveBack(String montant) {
    return 'À rendre au client : $montant';
  }

  @override
  String get retCash => 'Espèces';

  @override
  String get retCredit => 'Avoir';

  @override
  String get retKeep => 'Garder';

  @override
  String get retPhoneLabel => 'Téléphone du compte client *';

  @override
  String get retPhoneError => 'Un avoir a besoin du téléphone du client';

  @override
  String get retChooseItems => 'Choisissez les articles';

  @override
  String retValidateCancel(String montant) {
    return 'Valider l\'annulation ($montant)';
  }

  @override
  String retValidateReturn(String montant) {
    return 'Valider le retour ($montant)';
  }

  @override
  String get retNeedReason => 'Indiquez le motif pour valider.';

  @override
  String get retConfirmCancel => 'Confirmer l\'annulation';

  @override
  String get retConfirmReturn => 'Confirmer le retour';

  @override
  String get retDamagedShort => 'abîmé';

  @override
  String retAmount(String montant) {
    return 'Montant : $montant';
  }

  @override
  String retDamagedCount(int count) {
    return '$count pièce(s) abîmée(s) : ne reviennent pas en stock.';
  }

  @override
  String retCreditTo(String montant, String tel) {
    return 'Avoir de $montant versé sur le compte $tel.';
  }

  @override
  String get retIrreversible => 'Cette opération ne peut pas être annulée.';

  @override
  String get retBack => 'Retour';

  @override
  String get retValidate => 'Valider';

  @override
  String get retCancelSaved => 'Annulation enregistrée.';

  @override
  String get retReturnSaved => 'Retour enregistré.';

  @override
  String retGiveCash(String montant) {
    return 'Rendez $montant au client en espèces.';
  }

  @override
  String retCreditAdded(String montant, String solde) {
    return 'Avoir de $montant ajouté au compte client (nouveau solde : $solde).';
  }

  @override
  String retDepositKept(String montant) {
    return 'Acompte de $montant conservé par la boutique.';
  }

  @override
  String retDebtReduced(String montant) {
    return 'Dette du client diminuée de $montant.';
  }

  @override
  String get retOffline => '(envoi dès le retour d\'internet)';

  @override
  String get caisseNoShopProducts =>
      'Aucun produit en stock dans cette boutique.\nAjoutez du stock (achat ou transfert depuis la boutique principale).';

  @override
  String stockShowOut(int count) {
    return 'Voir les épuisés ($count)';
  }

  @override
  String get stockShowInStock => 'Retour aux produits en stock';

  @override
  String get livTitle => 'À livrer';

  @override
  String livButtonLate(int count) {
    return 'À livrer ($count en retard)';
  }

  @override
  String get livNoneTitle => 'Aucune livraison en attente';

  @override
  String get livNoneSub => 'Tous les clients ont reçu leur marchandise.';

  @override
  String livWaitingLate(int count, int late) {
    return '$count client(s) en attente — dont $late en retard';
  }

  @override
  String livWaiting(int count) {
    return '$count client(s) attendent leur marchandise';
  }

  @override
  String get livNoWhatsapp => 'Impossible d\'ouvrir WhatsApp.';

  @override
  String get livHandOverTitle => 'Remettre la marchandise';

  @override
  String livClient(String nom) {
    return 'Client : $nom';
  }

  @override
  String get livWhatNow => 'Indiquez ce que le client emporte maintenant :';

  @override
  String get livAllGiven => 'Tout a déjà été remis.';

  @override
  String livRemainDone(int reste, int deja) {
    return 'Reste $reste (déjà remis : $deja)';
  }

  @override
  String livToHand(int count) {
    return 'À remettre : $count';
  }

  @override
  String get livChooseOne => 'Choisissez au moins une pièce à remettre.';

  @override
  String livPartialAfter(int count) {
    return 'Sortie partielle : il restera $count pièce(s) à retirer.';
  }

  @override
  String get livComplete => 'Livraison complète : tout est remis.';

  @override
  String livWarnUnpaid(String montant) {
    return 'Attention : il reste $montant à payer.';
  }

  @override
  String get livValidateExit => 'Valider la sortie';

  @override
  String get livAllDelivered => 'Oui, tout livré';

  @override
  String get livSavedOffline =>
      'Sortie notée sur le téléphone. Envoi dès le retour d\'internet.';

  @override
  String livCompleteSaved(String client) {
    return 'Livraison complète enregistrée pour $client.';
  }

  @override
  String livPartialSaved(int count) {
    return 'Sortie partielle enregistrée : il reste $count pièce(s) à retirer.';
  }

  @override
  String livLatePassed(String date) {
    return 'Délai dépassé (limite : $date)';
  }

  @override
  String livLateDays(int jours, String date) {
    return 'Délai dépassé de $jours jour(s) (limite : $date)';
  }

  @override
  String livPickToday(String date) {
    return 'À retirer aujourd\'hui (limite : $date)';
  }

  @override
  String livPickTomorrow(String date) {
    return 'À retirer avant demain soir ($date)';
  }

  @override
  String livPickBefore(String date, int jours) {
    return 'À retirer avant le $date ($jours jours restants)';
  }

  @override
  String livCall(String tel) {
    return 'Appeler $tel';
  }

  @override
  String get livPartial => 'Partiellement livré';

  @override
  String livSoldOn(String date) {
    return 'Vendu le $date';
  }

  @override
  String livSoldOnBy(String date, String vendeur) {
    return 'Vendu le $date par $vendeur';
  }

  @override
  String get livStillToHand => 'Reste à remettre :';

  @override
  String get livToHandColon => 'À remettre :';

  @override
  String get livNothingToHand => 'rien à remettre';

  @override
  String livOutOf(String count) {
    return '(sur $count)';
  }

  @override
  String livHanded(int count) {
    return 'remis : $count';
  }

  @override
  String livCancelled(int count) {
    return '$count annulé(s)';
  }

  @override
  String get livAlreadyOut => 'Déjà sorti :';

  @override
  String livUnpaid(String montant) {
    return 'Reste à payer : $montant — à encaisser avant de livrer';
  }

  @override
  String get livRemind => 'Relancer';

  @override
  String get livMarkDelivered => 'Marquer comme livré';

  @override
  String livBy(String nom) {
    return '(par $nom)';
  }

  @override
  String get ccDepositTitle => 'Dépôt du client';

  @override
  String get ccWithdrawTitle => 'Retrait du client';

  @override
  String get ccPhoneLabel => 'Téléphone du client *';

  @override
  String get ccPhoneShort => 'Numéro trop court';

  @override
  String get ccNameLabel => 'Nom du client';

  @override
  String get ccAmountLabel => 'Montant (USD) *';

  @override
  String get ccMoreThanBalance => 'Plus que le solde disponible';

  @override
  String ccAvailable(String montant) {
    return 'Solde disponible : $montant';
  }

  @override
  String get ccCash => 'Espèces';

  @override
  String get ccSaveDeposit => 'Enregistrer le dépôt';

  @override
  String get ccSaveWithdraw => 'Enregistrer le retrait';

  @override
  String ccDepositSaved(String montant) {
    return 'Dépôt de $montant enregistré.';
  }

  @override
  String ccWithdrawSaved(String montant) {
    return 'Retrait de $montant enregistré.';
  }

  @override
  String get ccNewDeposit => 'Nouveau dépôt';

  @override
  String get ccSearchHint => 'Nom ou téléphone…';

  @override
  String ccCount(int count) {
    return '$count client(s) avec un compte';
  }

  @override
  String ccTotalKept(String montant) {
    return 'Argent des clients gardé : $montant';
  }

  @override
  String get ccNone =>
      'Aucun compte client.\nAppuyez sur « Nouveau dépôt » pour en créer un.';

  @override
  String get ccAccountTitle => 'Compte client';

  @override
  String get ccAvailableLabel => 'Solde disponible';

  @override
  String get ccDeposit => 'Dépôt';

  @override
  String get ccWithdraw => 'Retrait';

  @override
  String get ccSendStatement => 'Envoyer le relevé par WhatsApp';

  @override
  String get ccHistory => 'Historique';

  @override
  String get ccNoMovement => 'Aucun mouvement.';

  @override
  String ccDateBy(String date, String nom) {
    return '$date • par $nom';
  }

  @override
  String ccBalanceAfter(String montant) {
    return 'Solde : $montant';
  }

  @override
  String get depSearchHint => 'Rechercher une dépense...';

  @override
  String get depTitle => 'Charges & Dépenses';

  @override
  String get depTabAll => 'Toutes les Charges';

  @override
  String get depTabByCat => 'Par Catégorie';

  @override
  String get depExport => 'Exporter';

  @override
  String get depColDate => 'Date';

  @override
  String get depColTitle => 'Titre / Motif';

  @override
  String get depColCategory => 'Catégorie';

  @override
  String get depColAmount => 'Montant';

  @override
  String get depColAuthor => 'Auteur';

  @override
  String get depColNote => 'Note';

  @override
  String get depReportTitle => 'Rapport des Charges et Dépenses';

  @override
  String get depToExcel => 'Exporter vers Excel';

  @override
  String get depPrintPdf => 'Imprimer / PDF';

  @override
  String get depTotalAll => 'Total Général des Dépenses';

  @override
  String depTotalFor(String categorie) {
    return 'Total pour : $categorie';
  }

  @override
  String depNoResult(String recherche) {
    return 'Aucun résultat pour « $recherche »';
  }

  @override
  String get depNone => 'Aucune dépense enregistrée.';

  @override
  String depNote(String note) {
    return 'Note : $note';
  }

  @override
  String get depEdit => 'Modifier';

  @override
  String get depDelete => 'Supprimer';

  @override
  String get depAdd => 'Ajouter une dépense';

  @override
  String get depDeleteTitle => 'Supprimer la dépense';

  @override
  String get depDeleteConfirm =>
      'Êtes-vous sûr de vouloir supprimer cette ligne de charge ?';

  @override
  String get depInvalidAmount => 'Veuillez saisir un montant valide (> 0)';

  @override
  String get depEdited => 'Dépense modifiée !';

  @override
  String get depSaved => 'Dépense enregistrée !';

  @override
  String depSaveError(String erreur) {
    return 'Erreur lors de l\'enregistrement : $erreur';
  }

  @override
  String get depFormEdit => 'Modifier la dépense';

  @override
  String get depFormNew => 'Enregistrer une Dépense';

  @override
  String get depReasonRequired => 'Le motif est requis';

  @override
  String get depReasonLabel => 'Motif / Titre';

  @override
  String get depReasonHint => 'ex: Loyer, Électricité...';

  @override
  String get depAmountRequired => 'Le montant est requis';

  @override
  String get depAmountInvalid => 'Montant invalide';

  @override
  String get depCategoryLabel => 'Catégorie de Charge';

  @override
  String depDate(String date) {
    return 'Date : $date';
  }

  @override
  String get depNoteLabel => 'Note / Commentaire (Optionnel)';

  @override
  String get depSaveChanges => 'Enregistrer les modifications';

  @override
  String get depSaveExpense => 'Enregistrer la dépense';

  @override
  String get depCatAll => 'Toutes';

  @override
  String get depCatRent => 'Loyer';

  @override
  String get depCatSalaries => 'Salaires';

  @override
  String get depCatUtilities => 'Électricité & Eau';

  @override
  String get depCatTransport => 'Transport / Carburant';

  @override
  String get depCatTaxes => 'Taxes & Impôts';

  @override
  String get depCatMaintenance => 'Maintenance / Réparation';

  @override
  String get depCatMarketing => 'Marketing / Pub';

  @override
  String get depCatOther => 'Autre';

  @override
  String get blTraceTitle => 'Traçabilité requise';

  @override
  String blTraceMsg(String montant, String seuil) {
    return 'Ce bon de livraison s\'élève à $montant USD (au-dessus du seuil de $seuil USD).\n\nPour des raisons de sécurité financière et de suivi, un nom de client valide et un numéro de téléphone sont obligatoires.';
  }

  @override
  String get blTitle => 'Bon de livraison';

  @override
  String get blPrint => 'Imprimer';

  @override
  String get blShare => 'Partager (WhatsApp, e-mail…)';

  @override
  String blPdfError(String erreur) {
    return 'Impossible de créer le PDF : $erreur';
  }

  @override
  String get blPrintShare => 'Imprimer / Partager';

  @override
  String get blMyShop => 'Ma Boutique';

  @override
  String blPhoneShort(String tel) {
    return 'Tél : $tel';
  }

  @override
  String get blDeliveredTo => 'CLIENT LIVRÉ :';

  @override
  String get blCounterClient => 'Client Comptoir';

  @override
  String blAddress(String adresse) {
    return 'Adresse : $adresse';
  }

  @override
  String get blNotSpecified => 'Non spécifiée';

  @override
  String blPhone(String tel) {
    return 'Téléphone : $tel';
  }

  @override
  String get blColItem => 'Désignation';

  @override
  String get blColQty => 'Qté';

  @override
  String get blColUnit => 'P.U.';

  @override
  String get blColTotal => 'Total';

  @override
  String get blGrandTotal => 'TOTAL GÉNÉRAL : ';

  @override
  String get blDeliverer => 'Le Livreur / Expéditeur';

  @override
  String get blCustomerSign => 'Le Client (Bon accord)';

  @override
  String get panRateTitle => 'Taux du jour (USD -> FC)';

  @override
  String get panRateFor1 => 'Taux pour 1 USD';

  @override
  String get panUpdate => 'Mettre à jour';

  @override
  String get panClear => 'Vider le panier';

  @override
  String get panEmpty => 'Votre panier est vide';

  @override
  String get panTotal => 'Total à payer :';

  @override
  String get panCheckout => 'ENCAISSER';

  @override
  String get panRateLocked =>
      'Seul le patron (ou une personne autorisée) peut changer le taux.';
}
