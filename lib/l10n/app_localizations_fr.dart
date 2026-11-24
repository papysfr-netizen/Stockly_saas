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
  String get teamActive => 'Accès actif (désactivez pour suspendre)';

  @override
  String get teamCanLogin => 'Peut se connecter';

  @override
  String get teamDisabledInfo =>
      'Suspendu : ne peut plus travailler, réactivable à tout moment';

  @override
  String get teamReactivated => 'Accès réactivé';

  @override
  String get teamDeactivated => 'Employé suspendu';

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

  @override
  String get payCreditNeedsPhone =>
      'Pour une vente à crédit, saisissez le numéro de téléphone du client (au moins 9 chiffres).';

  @override
  String get debtClientPhone => 'Téléphone du client *';

  @override
  String get debtPhoneRequired =>
      'Le numéro de téléphone du client est obligatoire pour un crédit (au moins 9 chiffres).';

  @override
  String get payCreditNeedsName =>
      'Pour une vente à crédit, saisissez le nom du client.';

  @override
  String get debtNameRequired =>
      'Le nom du client est obligatoire pour un crédit.';

  @override
  String get cloTitle => 'Clôture de caisse';

  @override
  String get cloButton => 'Clôturer la caisse';

  @override
  String cloDoneAt(String heure) {
    return 'Caisse clôturée à $heure';
  }

  @override
  String get cloBoutique => 'Boutique';

  @override
  String get cloPickBoutique => 'Choisissez la boutique à clôturer';

  @override
  String get cloBlindInfo =>
      'Comptez l\'argent du tiroir et notez ce que vous trouvez. Ne recopiez pas un autre montant : le patron compare ensuite avec les ventes.';

  @override
  String get cloFloatMorning => 'Fond de caisse du matin';

  @override
  String get cloCounted => 'Argent compté dans le tiroir';

  @override
  String get cloMobileReceived => 'Mobile Money reçu aujourd\'hui';

  @override
  String get cloMobileHint =>
      'Total reçu sur le téléphone de la boutique, en dollars';

  @override
  String get cloFloatTomorrow => 'Fond laissé pour demain (facultatif)';

  @override
  String get cloNote => 'Remarque (facultatif)';

  @override
  String get cloInDollars => 'En dollars (\$)';

  @override
  String get cloInFrancs => 'En francs (FC)';

  @override
  String get cloSave => 'Enregistrer la clôture';

  @override
  String get cloConfirmTitle => 'Enregistrer la clôture ?';

  @override
  String get cloConfirmBody =>
      'Une fois enregistrée, la clôture ne peut plus être modifiée.';

  @override
  String get cloSaved => 'Clôture enregistrée. Le patron verra le résultat.';

  @override
  String get cloAlreadyDone => 'Cette caisse est déjà clôturée aujourd\'hui.';

  @override
  String get cloResult => 'Résultat de la clôture';

  @override
  String get cloCash => 'Espèces';

  @override
  String get cloMobile => 'Mobile Money';

  @override
  String get cloExpected => 'Attendu';

  @override
  String get cloCountedShort => 'Compté';

  @override
  String get cloGap => 'Écart';

  @override
  String get cloOk => 'Juste ✓';

  @override
  String cloMissing(String montant) {
    return 'Il manque $montant';
  }

  @override
  String cloSurplus(String montant) {
    return 'Surplus de $montant';
  }

  @override
  String get cloDetail => 'Détail de l\'attendu';

  @override
  String get cloLineFloat => 'Fond de caisse';

  @override
  String get cloLineSales => 'Ventes';

  @override
  String get cloLineDebts => 'Dettes encaissées';

  @override
  String get cloLineDeposits => 'Dépôts des comptes clients';

  @override
  String get cloLineWithdrawals => 'Retraits des comptes clients';

  @override
  String get cloLineExpenses => 'Dépenses';

  @override
  String get cloLineSuppliers => 'Fournisseurs payés';

  @override
  String get cloLineRefunds => 'Remboursements des retours';

  @override
  String get cloLineOther => 'Autres paiements (carte, virement…), non comptés';

  @override
  String get cloExpensesHidden =>
      'Les dépenses n\'ont pas pu être lues : l\'attendu peut être trop élevé.';

  @override
  String cloAfterSales(String nombre, String montant) {
    return '$nombre vente(s) après la clôture : $montant';
  }

  @override
  String cloBy(String nom, String heure) {
    return 'Par $nom à $heure';
  }

  @override
  String get cloHistory => 'Historique des clôtures';

  @override
  String get cloHistoryEmpty => 'Aucune clôture pour le moment.';

  @override
  String get cloReopen => 'Rouvrir (supprimer la clôture)';

  @override
  String get cloReopenConfirm =>
      'Supprimer cette clôture ? La caisse pourra être recomptée.';

  @override
  String get cloAfterWarning =>
      'Caisse déjà clôturée aujourd\'hui : cette vente sera signalée « après clôture ».';

  @override
  String cloRate(String taux) {
    return 'Taux : 1 \$ = $taux FC';
  }

  @override
  String get cloLoading => 'Calcul de l\'attendu…';

  @override
  String cloDoneBy(String heure, String nom) {
    return 'Clôturée à $heure par $nom';
  }

  @override
  String get cloSavedShort => 'Clôture enregistrée.';

  @override
  String get caiTitle => 'Caisse';

  @override
  String get caiNewProduct => 'Nouveau produit';

  @override
  String get caiSettings => 'Paramètres';

  @override
  String get caiExport => 'Exporter le catalogue';

  @override
  String get caiExportExcel => 'Exporter vers Excel';

  @override
  String get caiExportPdf => 'Imprimer / PDF';

  @override
  String get caiColName => 'Produit';

  @override
  String get caiColStock => 'Stock';

  @override
  String get caiColPrice => 'Prix de vente';

  @override
  String get caiCatalogTitle => 'Catalogue des produits';

  @override
  String caiProfileError(String erreur) {
    return 'Impossible de charger votre profil : $erreur';
  }

  @override
  String get caiPickShop => 'Choisissez la boutique de vente';

  @override
  String caiSellingIn(String nom) {
    return 'Vente : $nom';
  }

  @override
  String get caiMainShop => 'Boutique principale';

  @override
  String get payDeliveryNote => 'Bon de livraison';

  @override
  String get debtOrigin => 'D\'où vient cette dette ?';

  @override
  String get debtOriginSale => 'Vente hors caisse';

  @override
  String get debtOriginLoan => 'Argent prêté';

  @override
  String get debtOriginOld => 'Ancienne dette (cahier)';

  @override
  String get debtOriginPurchase => 'Achat à crédit';

  @override
  String get debtOriginBorrow => 'Argent emprunté';

  @override
  String get debtFromDrawer => 'L\'argent est sorti de la caisse';

  @override
  String get debtToDrawer => 'L\'argent est entré dans la caisse';

  @override
  String get debtOldPaid => 'Déjà remboursé avant Nguli';

  @override
  String get cloLineBorrowed => 'Argent emprunté (mis en caisse)';

  @override
  String get cloLineLent => 'Argent prêté (pris dans la caisse)';

  @override
  String get prodPricePositive => 'Le prix de vente doit être supérieur à 0';

  @override
  String get prodNoNegative => 'Pas de nombre négatif';

  @override
  String payChangeToAccount(String montant) {
    return 'Mettre la monnaie ($montant) sur le compte du client';
  }

  @override
  String get delAccount => 'Supprimer mon compte';

  @override
  String get delTitle => 'Supprimer le compte ?';

  @override
  String get delOwnerWarning =>
      'Vous êtes le propriétaire : TOUTE l\'entreprise sera effacée pour toujours (produits, ventes, dettes, comptabilité, comptes clients, dépenses) et vos employés n\'auront plus accès. Faites une sauvegarde avant si vous voulez garder vos chiffres.';

  @override
  String get delEmployeeWarning =>
      'Votre accès sera supprimé pour toujours. Les ventes que vous avez faites restent dans les registres de l\'entreprise.';

  @override
  String get delConfirmWord => 'SUPPRIMER';

  @override
  String get delPassword => 'Votre mot de passe';

  @override
  String get delSmsHint =>
      'Compte par SMS : déconnectez-vous, reconnectez-vous, puis supprimez dans les 5 minutes.';

  @override
  String get delButton => 'Supprimer pour toujours';

  @override
  String get delProgress =>
      'Suppression en cours… Gardez l\'application ouverte et restez connecté à internet.';

  @override
  String get delErrPassword => 'Mot de passe incorrect.';

  @override
  String get delErrRelogin =>
      'Par sécurité, déconnectez-vous, reconnectez-vous, puis recommencez dans les 5 minutes.';

  @override
  String get delErrNetwork =>
      'Pas de connexion internet. La suppression a besoin d\'internet : réessayez.';

  @override
  String get delErrUnknown =>
      'La suppression n\'a pas pu se terminer. Réessayez : ce qui est déjà effacé ne revient pas.';

  @override
  String get delDone => 'Votre compte a été supprimé.';

  @override
  String delTypeConfirm(String mot) {
    return 'Pour confirmer, écrivez $mot';
  }

  @override
  String get delEmployeeAskOwner =>
      'Seul votre patron peut supprimer votre accès à Nguli. Demandez-le-lui, ou écrivez-nous à l\'adresse indiquée dans la politique de confidentialité.';

  @override
  String get teamRemove => 'Retirer de l\'équipe';

  @override
  String teamRemoveQuestion(String nom) {
    return 'Retirer $nom de l\'équipe ?';
  }

  @override
  String get teamRemoveInfo =>
      'Son accès est supprimé pour toujours : il ne pourra plus entrer dans la boutique. Les ventes qu\'il a faites restent. Pour une absence, désactivez-le plutôt.';

  @override
  String teamRemoved(String nom) {
    return '$nom a été retiré de l\'équipe';
  }

  @override
  String get accountRemovedTitle => 'Accès supprimé';

  @override
  String get accountRemovedInfo =>
      'Votre accès à cette boutique a été supprimé. Contactez le patron si c\'est une erreur.';

  @override
  String get payChangeHow => 'Rendre la monnaie en :';

  @override
  String payChangeGive(String montant) {
    return 'Donnez : $montant';
  }

  @override
  String get scanTypeCode => 'Saisir le code à la main';

  @override
  String get scanTypeCodeHint => 'Tapez le numéro imprimé sous les barres.';

  @override
  String get scanTitle => 'Scanner le code-barres';

  @override
  String get scanSwitchCamera => 'Changer de caméra';

  @override
  String get scanCameraNeeded => 'Accès à la caméra requis';

  @override
  String get scanCameraAllow =>
      'Autorisez l\'accès à la caméra dans les paramètres du téléphone pour scanner les codes-barres.';

  @override
  String get retry => 'Réessayer';

  @override
  String scanChecking(String fait, String total) {
    return 'Vérification… $fait/$total';
  }

  @override
  String get scanStepBack =>
      'Reculez un peu : tout le code-barres doit tenir dans le cadre';

  @override
  String get accountSuspendedTitle => 'Compte suspendu';

  @override
  String get accountSuspendedInfo =>
      'Le patron a suspendu votre accès.\nContactez-le pour le réactiver.';

  @override
  String get backToLogin => 'Retour à la connexion';

  @override
  String authError(String erreur) {
    return 'Erreur de connexion : $erreur';
  }

  @override
  String profileLoadError(String erreur) {
    return 'Erreur lors du chargement du profil :\n$erreur';
  }

  @override
  String get pwdOldWrong => 'L\'ancien mot de passe est incorrect.';

  @override
  String get pwdTooWeak =>
      'Nouveau mot de passe trop faible (6 caractères minimum).';

  @override
  String get pwdTooMany => 'Trop d\'essais. Patientez quelques minutes.';

  @override
  String get pwdNoInternet =>
      'Pas de connexion internet. Il faut internet pour changer le mot de passe.';

  @override
  String get pwdRelogin =>
      'Par sécurité, déconnectez-vous puis reconnectez-vous, et réessayez.';

  @override
  String get errorUnknown => 'Erreur inconnue.';

  @override
  String get pwdFillAll => 'Remplissez les trois champs.';

  @override
  String get pwdMin6 =>
      'Le nouveau mot de passe doit avoir au moins 6 caractères.';

  @override
  String get pwdMismatch =>
      'Les deux nouveaux mots de passe ne sont pas identiques.';

  @override
  String get pwdSameAsOld =>
      'Le nouveau mot de passe doit être différent de l\'ancien.';

  @override
  String get pwdSmsAccount =>
      'Ce compte ne se connecte pas avec un mot de passe (connexion par SMS).';

  @override
  String get pwdChanged => 'Mot de passe changé avec succès.';

  @override
  String errorWith(String erreur) {
    return 'Erreur : $erreur';
  }

  @override
  String get pwdChangeTitle => 'Changer mon mot de passe';

  @override
  String get pwdOld => 'Ancien mot de passe';

  @override
  String get pwdNew => 'Nouveau mot de passe';

  @override
  String get pwdMinHint => '6 caractères minimum';

  @override
  String get pwdConfirm => 'Confirmer le nouveau mot de passe';

  @override
  String get lotOldStock => 'Stock d\'avant les arrivages';

  @override
  String get lotArrival => 'Arrivage';

  @override
  String get lotSellFrom => 'Vendre depuis l\'arrivage';

  @override
  String lotChoice(String nom, String reste) {
    return '$nom (reste $reste)';
  }

  @override
  String livMsgRest(String client, String liste, String boutique) {
    return 'Bonjour $client, le reste de votre marchandise ($liste) vous attend chez $boutique. ';
  }

  @override
  String livMsgAll(String client, String liste, String boutique) {
    return 'Bonjour $client, votre marchandise ($liste) vous attend chez $boutique. ';
  }

  @override
  String livMsgLate(String date) {
    return 'La date de retrait ($date) est dépassée : merci de passer la récupérer au plus vite. ';
  }

  @override
  String livMsgBefore(String date) {
    return 'Merci de passer la retirer avant le $date. ';
  }

  @override
  String livMsgToPay(String montant) {
    return 'Reste à payer : $montant. ';
  }

  @override
  String get livMsgThanks => 'Merci !';

  @override
  String get lotProposed => 'proposé';

  @override
  String get cloByCurrency => 'Par devise (fond + ventes en espèces)';

  @override
  String get cloDollars => 'Dollars';

  @override
  String get cloFrancs => 'Francs';

  @override
  String cloExpCounted(String attendu, String compte) {
    return 'attendu $attendu · compté $compte';
  }

  @override
  String get cloByCurrencyNote =>
      'Les dettes, dépenses et dépôts ne sont pas séparés par devise : cette comparaison est juste quand la journée n\'a surtout que des ventes.';

  @override
  String accMsgBalance(String nom, String boutique, String solde) {
    return 'Bonjour $nom, votre solde chez $boutique est de $solde.';
  }

  @override
  String get accMsgLast => 'Derniers mouvements :';

  @override
  String get accMsgThanks => 'Merci de votre confiance !';

  @override
  String get accMvtDeposit => 'Dépôt';

  @override
  String get logWrong => 'Identifiant (ou e-mail) ou mot de passe incorrect.';

  @override
  String get logDisabled => 'Ce compte est suspendu. Contactez le patron.';

  @override
  String get logNoInternet =>
      'Pas de connexion internet. Vérifiez votre réseau.';

  @override
  String get logError => 'Erreur de connexion.';

  @override
  String get logNoProfile => 'Aucun profil trouvé pour ce compte.';

  @override
  String get logOk => 'Connexion réussie !';

  @override
  String logWelcome(String nom) {
    return 'Bienvenue $nom !';
  }

  @override
  String logDbError(String erreur) {
    return 'Erreur d\'accès aux données : $erreur';
  }

  @override
  String get fillAll => 'Remplissez tous les champs.';

  @override
  String get logEnterPhone => 'Entrez un numéro de téléphone.';

  @override
  String logSmsError(String erreur) {
    return 'Erreur SMS : $erreur';
  }

  @override
  String get logSmsSent => 'Code SMS envoyé !';

  @override
  String get logEnterCode => 'Saisissez le code reçu.';

  @override
  String get logBadCode => 'Code SMS invalide.';

  @override
  String get logWithPhone => 'Se connecter avec un numéro';

  @override
  String get logWithId => 'Se connecter par identifiant ou e-mail';

  @override
  String get logIdLabel => 'E-mail ou identifiant';

  @override
  String get logIdHelp => 'Employé : tapez l\'identifiant reçu du patron';

  @override
  String get logPassword => 'Mot de passe';

  @override
  String get logSignIn => 'Se connecter';

  @override
  String get logPhoneLabel => 'Téléphone (ex : +243970000000)';

  @override
  String get logSendSms => 'Envoyer le code SMS';

  @override
  String get logCodeLabel => 'Code à 6 chiffres reçu par SMS';

  @override
  String get logValidateCode => 'Valider le code';

  @override
  String get logNew => 'Nouveau sur Nguli ?';

  @override
  String get logCreateBusiness => 'Créer une entreprise';

  @override
  String get regDone => 'Entreprise et compte créés avec succès !';

  @override
  String regError(String erreur) {
    return 'Erreur lors de l\'inscription : $erreur';
  }

  @override
  String get regCreate => 'Créer mon entreprise';

  @override
  String get regJoin => 'Rejoignez Nguli';

  @override
  String get regIntro =>
      'Configurez votre entreprise et gérez votre stock en toute simplicité.';

  @override
  String get regBusinessName => 'Nom de l\'entreprise *';

  @override
  String get regBusinessHint => 'ex : Établissement La Grâce';

  @override
  String get regBusinessNeeded => 'Saisissez le nom de votre entreprise';

  @override
  String get regManagerName => 'Votre nom complet *';

  @override
  String get regNameNeeded => 'Saisissez votre nom';

  @override
  String get regPhone => 'Téléphone (facultatif)';

  @override
  String get regEmail => 'Adresse e-mail *';

  @override
  String get regEmailNeeded => 'Saisissez une adresse e-mail';

  @override
  String get regEmailInvalid => 'Saisissez une adresse e-mail valide';

  @override
  String get regPassword => 'Mot de passe *';

  @override
  String get regConfirm => 'Confirmer le mot de passe *';

  @override
  String get regCreating => 'Création du compte…';

  @override
  String get regHaveAccount => 'Vous avez déjà un compte ?';

  @override
  String get cloOldSalesFc =>
      'Anciennes ventes : monnaie supposée rendue en francs.';

  @override
  String get accMvtCredit => 'Avoir (retour)';

  @override
  String get accMvtPurchase => 'Achat';

  @override
  String get accMvtWithdrawal => 'Retrait';

  @override
  String get impConfirm => 'Confirmer l\'import';

  @override
  String impConfirmBody(String nouveaux, String maj, String ignores) {
    return '$nouveaux nouveau(x) produit(s)\n$maj produit(s) mis à jour\n$ignores ligne(s) ignorée(s)\n\n';
  }

  @override
  String get impImport => 'Importer';

  @override
  String get impSaving => 'Enregistrement…';

  @override
  String impSavingProgress(String fait, String total) {
    return 'Enregistrement : $fait / $total';
  }

  @override
  String get impDone => 'Import terminé';

  @override
  String impDoneBody(String nouveaux, String maj, String ignores) {
    return '🟢 $nouveaux nouveau(x) produit(s)\n🔵 $maj produit(s) mis à jour\n⚪ $ignores ligne(s) ignorée(s)';
  }

  @override
  String get impColMissing => 'non trouvée';

  @override
  String impCheck(String doute) {
    return 'À vérifier : $doute';
  }

  @override
  String impFileLine(String nom) {
    return '📄 Fichier : $nom';
  }

  @override
  String impCodeQty(String code, String qte) {
    return 'Code : $code • Qté : $qte';
  }

  @override
  String impAlready(String nom) {
    return '📦 Déjà en stock : $nom';
  }

  @override
  String impCodeStock(String code, String stock) {
    return 'Code : $code • Stock : $stock';
  }

  @override
  String get impSame => 'Même produit';

  @override
  String get impNew => 'Nouveau produit';

  @override
  String impStockChange(String avant, String apres) {
    return 'Stock : $avant → $apres';
  }

  @override
  String impWillCreate(String qte) {
    return 'Un nouveau produit sera créé ($qte pièce(s)).';
  }

  @override
  String impNewLine(String qte, String code, String achat, String vente) {
    return 'Nouveau produit • Qté : $qte$code\nPrix achat : $achat • Prix vente : $vente';
  }

  @override
  String impExistsLine(
      String nom, String avant, String apres, String achat, String vente) {
    return 'Existe déjà$nom • Stock : $avant → $apres\nPrix achat : $achat • Prix vente : $vente';
  }

  @override
  String impSkipped(String n, String raison) {
    return 'Ligne $n ignorée : $raison';
  }

  @override
  String get impPreview => 'Aperçu de l\'import';

  @override
  String get impColumns => 'Colonnes reconnues :';

  @override
  String get impColCode => 'Code-barres';

  @override
  String get impColName => 'Nom';

  @override
  String get impColQty => 'Quantité';

  @override
  String get impColCost => 'Prix d\'achat';

  @override
  String get impColPrice => 'Prix de vente';

  @override
  String get impNoHeader =>
      'Pas de ligne de titres : l\'ordre A=Code, B=Nom, C=Qté, D=Prix achat, E=Prix vente est utilisé.';

  @override
  String get impType => 'Type d\'import :';

  @override
  String get impModeArrivalInfo =>
      'Les quantités du fichier sont AJOUTÉES au stock actuel (nouvelle marchandise reçue).';

  @override
  String get impModeInventoryInfo =>
      'Le stock est REMPLACÉ par les quantités du fichier (après un comptage physique).';

  @override
  String get impSupplier => 'Fournisseur';

  @override
  String get impListNo => 'N° de la liste';

  @override
  String impChipNew(String n) {
    return '$n nouveau(x)';
  }

  @override
  String impChipUpd(String n) {
    return '$n mis à jour';
  }

  @override
  String impChipSkip(String n) {
    return '$n ignoré(s)';
  }

  @override
  String impChipCheck(String n) {
    return '$n à vérifier';
  }

  @override
  String impToCheck(String n) {
    return '$n produit(s) à vérifier (en orange) : choisissez pour chacun.';
  }

  @override
  String get impChecked => 'Produits vérifiés ✔ (vous pouvez encore changer)';

  @override
  String get impAllSame => 'Tous : même produit';

  @override
  String get impAllNew => 'Tous : nouveau produit';

  @override
  String get impEmpty => 'Aucun produit trouvé dans ce fichier.';

  @override
  String impChooseFirst(String n) {
    return 'Choisissez d\'abord : $n à vérifier';
  }

  @override
  String impImportN(String n) {
    return 'Importer $n produit(s)';
  }

  @override
  String get impModeArrivalWarn =>
      'Mode ARRIVAGE : les quantités seront AJOUTÉES au stock.';

  @override
  String get impModeInventoryWarn =>
      'Mode INVENTAIRE : le stock sera REMPLACÉ par les quantités du fichier.';

  @override
  String get impOffline =>
      'Pas d\'internet : les changements seront envoyés au retour du réseau.';

  @override
  String get impUnchanged => 'inchangé';

  @override
  String get impInventory => 'Inventaire';

  @override
  String get arrTitle => 'Arrivages (packing lists)';

  @override
  String get arrEmpty =>
      'Aucun arrivage pour le moment.\n\nImportez une packing list en mode « Arrivage » (Stock → Importer) : elle apparaîtra ici avec son fournisseur et ses produits.';

  @override
  String arrNo(String n) {
    return 'N° $n';
  }

  @override
  String get arrNoSupplier => 'Fournisseur non indiqué';

  @override
  String arrListLine(
      String date, String boutique, String produits, String pieces) {
    return '$date · $boutique\n$produits produit(s) · $pieces pièce(s)';
  }

  @override
  String get arrNoNet => 'Pas de connexion internet : réessayez.';

  @override
  String get arrCancelQ => 'Annuler cet arrivage ?';

  @override
  String arrCancelBody(String pieces) {
    return 'Les quantités de cette packing list seront RETIRÉES du stock ($pieces pièce(s)). Les prix modifiés par l\'import ne changent pas.';
  }

  @override
  String get no => 'Non';

  @override
  String get arrCancelBtn => 'Annuler l\'arrivage';

  @override
  String get arrCancelled => 'Arrivage annulé.';

  @override
  String get arrCancelOffline =>
      'Pas de connexion : l\'annulation partira au retour d\'internet.';

  @override
  String arrCancelError(String erreur) {
    return 'Annulation impossible : $erreur';
  }

  @override
  String get arrSheet => 'Fiche d\'arrivage';

  @override
  String get arrNotFound => 'Arrivage introuvable.';

  @override
  String arrPlNo(String n) {
    return 'Packing list n° $n';
  }

  @override
  String arrReceived(String date) {
    return 'Reçu le $date';
  }

  @override
  String arrShop(String nom) {
    return 'Boutique : $nom';
  }

  @override
  String arrFile(String nom) {
    return 'Fichier : $nom';
  }

  @override
  String arrCounts(String produits, String pieces) {
    return '$produits produit(s) · $pieces pièce(s)';
  }

  @override
  String arrCancelledOn(String date) {
    return 'ANNULÉ le $date';
  }

  @override
  String get arrSales => 'Ventes de cet arrivage';

  @override
  String arrSoldLeft(String vendu, String reste) {
    return 'Vendu : $vendu pièce(s) · Reste : $reste pièce(s)';
  }

  @override
  String arrRevenue(String montant) {
    return 'Argent des ventes : $montant';
  }

  @override
  String arrCost(String montant) {
    return 'Coût des pièces vendues : $montant';
  }

  @override
  String arrProfit(String montant) {
    return 'Bénéfice : $montant';
  }

  @override
  String get arrOldestFirst =>
      'Nguli propose d\'abord le stock le plus ancien ; le vendeur peut en choisir un autre.';

  @override
  String arrLineCost(String montant) {
    return 'Achat $montant';
  }

  @override
  String arrLinePrice(String montant) {
    return 'Vente $montant';
  }

  @override
  String get arrLineNew => 'nouveau produit';

  @override
  String arrLineStats(String vendu, String reste, String benefice) {
    return 'Vendu $vendu · reste $reste · bénéfice $benefice';
  }

  @override
  String get arrCancelThis => 'Annuler cet arrivage';

  @override
  String get stockImportExcel => 'Fichier Excel / CSV';

  @override
  String get stockImportPhoto => 'Photo de facture (IA)';

  @override
  String get arrMainShop => 'Boutique principale';

  @override
  String get arrCancelledTag => 'ANNULÉ';

  @override
  String arrCancelMissing(String n) {
    return '$n pièce(s) ne sont plus en stock (déjà vendues ou sorties) : le stock de ces produits deviendra négatif.';
  }

  @override
  String arrCancelDeleted(String n) {
    return '$n produit(s) ont été supprimés depuis : ils sont ignorés.';
  }

  @override
  String trfOnly(String nom, String dispo, String boutique) {
    return '« $nom » : seulement $dispo disponible(s) à $boutique.';
  }

  @override
  String get trfConfirm => 'Confirmer le transfert';

  @override
  String trfTotal(String n) {
    return 'Total : $n article(s)';
  }

  @override
  String get trfDo => 'Transférer';

  @override
  String get trfOffline =>
      'Transfert enregistré hors ligne : il sera envoyé au retour du réseau.';

  @override
  String trfDone(String de, String vers) {
    return 'Transfert effectué : $de → $vers';
  }

  @override
  String get trfTitle => 'Transferts de stock';

  @override
  String get accessRestricted => 'Accès réservé';

  @override
  String get oneShopOnly => 'Une seule boutique';

  @override
  String get searchProduct => 'Rechercher un produit…';

  @override
  String get trfAll => 'Tout transférer';

  @override
  String get trfNoProduct => 'Aucun produit disponible';

  @override
  String get trfChooseQty => 'Choisissez les quantités';

  @override
  String trfSummary(String articles, String produits) {
    return '$articles article(s) • $produits produit(s)';
  }

  @override
  String trfAvailable(String n) {
    return 'Disponible : $n';
  }

  @override
  String trfQtyMax(String n) {
    return 'Quantité (max $n)';
  }

  @override
  String get trfNone => 'Aucun transfert';

  @override
  String get trfTabNew => 'Nouveau';

  @override
  String get trfTabHistory => 'Historique';

  @override
  String pbSavedOffline(String n) {
    return '$n prix enregistrés hors ligne (envoyés au retour du réseau)';
  }

  @override
  String pbSaved(String n) {
    return '$n prix enregistrés';
  }

  @override
  String get pbChooseShop => 'Choisir la boutique…';

  @override
  String get pbPickShop => 'Choisissez une boutique';

  @override
  String get pbEmptyNormal => 'Champ vide = prix normal';

  @override
  String pbChanged(String n) {
    return '$n prix modifié(s)';
  }

  @override
  String get pbTitle => 'Prix par boutique';

  @override
  String pbNormal(String prix) {
    return 'Prix normal : $prix';
  }

  @override
  String get trfNeedStock =>
      'Il faut l\'autorisation « Gérer le stock » pour faire des transferts.';

  @override
  String get trfNeedTwoShops =>
      'Créez au moins 2 boutiques (Paramètres → Mes boutiques) pour transférer du stock.';

  @override
  String get trfAllSearch => 'Tout (recherche)';

  @override
  String get trfNoStock => 'Cette boutique n\'a pas de stock à transférer.';

  @override
  String get trfNoneInfo => 'Les transferts effectués apparaîtront ici.';

  @override
  String get pbNeedStock =>
      'Il faut l\'autorisation « Gérer le stock » pour modifier les prix.';

  @override
  String get pbNeedTwoShops =>
      'Créez au moins 2 boutiques pour définir des prix différents.';

  @override
  String get pbPickShopInfo =>
      'Puis saisissez le prix de vente de chaque produit dans cette boutique.';

  @override
  String repColAmount(String devise) {
    return 'Montant ($devise)';
  }

  @override
  String get repToday => 'AUJOURD\'HUI';

  @override
  String get repYesterday => 'HIER';

  @override
  String get rep7Days => '7 JOURS';

  @override
  String get repThisMonth => 'CE MOIS';

  @override
  String get repLastMonth => 'MOIS DERNIER';

  @override
  String get repThisYear => 'CETTE ANNÉE';

  @override
  String get repDates => 'DATES…';

  @override
  String get repColItem => 'Poste';

  @override
  String get repGross => 'Ventes brutes';

  @override
  String get repReturns => 'Retours et annulations';

  @override
  String get repNetSales => 'CHIFFRE D\'AFFAIRES NET';

  @override
  String get repCogs => 'Coût des marchandises vendues';

  @override
  String get repGrossMargin => 'MARGE BRUTE';

  @override
  String get repOtherIncome => 'Autres produits (acomptes conservés)';

  @override
  String repOfWhich(String nom) {
    return 'dont $nom';
  }

  @override
  String get repLosses => 'Pertes (articles abîmés)';

  @override
  String get repNet => 'RÉSULTAT NET';

  @override
  String get repNbSales => 'Nombre de ventes';

  @override
  String get repAvgBasket => 'Panier moyen';

  @override
  String get repCashedLong => 'Encaissé (payé à la vente)';

  @override
  String get repCreditsLong => 'Crédits accordés (reste à payer)';

  @override
  String get repByShopUp => 'PAR BOUTIQUE';

  @override
  String get repShopSales => 'CA net / nombre de ventes';

  @override
  String get repShopCash => 'Encaissé / crédits';

  @override
  String get repStockCost => 'Stock (prix d\'achat)';

  @override
  String get repBySellerUp => 'PAR VENDEUR';

  @override
  String repSellerLine(String nom, String n) {
    return '$nom ($n vente(s))';
  }

  @override
  String get repTopUp => 'PRODUITS LES PLUS VENDUS';

  @override
  String get repDormantUp => 'NE BOUGENT PAS (en stock, aucune vente)';

  @override
  String repFull(String periode) {
    return 'Rapport complet $periode';
  }

  @override
  String repFromTo(String debut, String fin) {
    return 'du $debut au $fin';
  }

  @override
  String get repAllShops => 'Toutes les boutiques';

  @override
  String get repIncomeStatement => 'Compte de résultat';

  @override
  String get repExportExcel => 'Exporter vers Excel';

  @override
  String get repPrintPdf => 'Imprimer / PDF';

  @override
  String repExpError(String erreur) {
    return 'Erreur dépenses : $erreur';
  }

  @override
  String repLoadError(String erreur) {
    return 'Impossible de charger les données : $erreur';
  }

  @override
  String get repSearchClient => 'Rechercher un client';

  @override
  String repPaidAtSale(String devise) {
    return '$devise • payé à la vente';
  }

  @override
  String get repCreditsGiven => 'Crédits accordés';

  @override
  String repLeftToPay(String devise) {
    return '$devise • reste à payer';
  }

  @override
  String get repTapDetail => 'Touchez une ligne pour le détail';

  @override
  String get repByShop => 'Par boutique';

  @override
  String get repTop => 'Produits les plus vendus';

  @override
  String get repDormant => 'Ne bougent pas';

  @override
  String repAmountsNote(String devise) {
    return 'Montants en $devise • Comparaison avec la période précédente de même durée.';
  }

  @override
  String get repVsPrevNone => '— vs période préc.';

  @override
  String repVsPrev(String pct) {
    return '$pct % vs période préc.';
  }

  @override
  String get repNoActivity => 'Aucune activité sur cette période';

  @override
  String get repNetMargin => 'Marge nette';

  @override
  String get repNetSalesShort => 'CA net';

  @override
  String get repGrossMarginShort => 'Marge brute';

  @override
  String repBasket(String montant) {
    return 'Panier $montant';
  }

  @override
  String get repDepositsKept => 'Acomptes conservés';

  @override
  String get repLossesTitle => 'Pertes : articles abîmés';

  @override
  String get repNoData => 'Aucune donnée sur cette période';

  @override
  String get repSalesShort => 'CA';

  @override
  String get repNbShort => 'Ventes';

  @override
  String get repCreditsShort => 'Crédits';

  @override
  String get repStockShort => 'Stock (achat)';

  @override
  String repNSales(String n) {
    return '$n vente(s)';
  }

  @override
  String repPieces(String n) {
    return '$n pièce(s)';
  }

  @override
  String repAndMore(String n) {
    return '… et $n autre(s)';
  }

  @override
  String get repAllSold => 'Tous les produits en stock se sont vendus 👍';

  @override
  String repTiedUp(String n, String montant) {
    return '$n produit(s) • $montant immobilisés (prix d\'achat)';
  }

  @override
  String repStockN(String n) {
    return 'Stock : $n';
  }

  @override
  String get repWhoOwes => 'Qui doit encore';

  @override
  String get repPeriodSales => 'Ventes de la période';

  @override
  String repUnitCost(String montant) {
    return 'Prix d\'achat unitaire : $montant';
  }

  @override
  String get repMarginPerItem => 'Marge par article';

  @override
  String repSaleCost(String vente, String achat) {
    return 'Vente : $vente | Achat : $achat';
  }

  @override
  String get repExpByCat => 'Charges et dépenses par catégorie';

  @override
  String repPctOfCosts(String pct) {
    return '$pct % des charges';
  }

  @override
  String get repNetResult => 'Résultat net';

  @override
  String get repSold => 'Vendu';

  @override
  String get repAmount => 'Montant';

  @override
  String get repStockValue => 'Stock / valeur achat';

  @override
  String get repDormantInfo => 'En stock, aucune vente';

  @override
  String get repCostsExpenses => 'Charges et dépenses';
}
