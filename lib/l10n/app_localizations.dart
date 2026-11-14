import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_ln.dart';
import 'app_localizations_sw.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
    Locale('ln'),
    Locale('sw')
  ];

  /// No description provided for @appTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nguli'**
  String get appTitle;

  /// No description provided for @settings.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get settings;

  /// No description provided for @storeInfo.
  ///
  /// In fr, this message translates to:
  /// **'Informations du magasin'**
  String get storeInfo;

  /// No description provided for @storeName.
  ///
  /// In fr, this message translates to:
  /// **'Nom de la boutique'**
  String get storeName;

  /// No description provided for @address.
  ///
  /// In fr, this message translates to:
  /// **'Adresse'**
  String get address;

  /// No description provided for @phone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone'**
  String get phone;

  /// No description provided for @saveInfo.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer les informations'**
  String get saveInfo;

  /// No description provided for @bccSection.
  ///
  /// In fr, this message translates to:
  /// **'Taux BCC & devise active'**
  String get bccSection;

  /// No description provided for @bccRate.
  ///
  /// In fr, this message translates to:
  /// **'Taux de change (BCC)'**
  String get bccRate;

  /// No description provided for @activeCurrency.
  ///
  /// In fr, this message translates to:
  /// **'Devise principale'**
  String get activeCurrency;

  /// No description provided for @appLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Langue de l\'application'**
  String get appLanguage;

  /// No description provided for @reportsExport.
  ///
  /// In fr, this message translates to:
  /// **'Exportation des données'**
  String get reportsExport;

  /// No description provided for @exportExcel.
  ///
  /// In fr, this message translates to:
  /// **'Exporter le stock vers Excel'**
  String get exportExcel;

  /// No description provided for @dbMaintenance.
  ///
  /// In fr, this message translates to:
  /// **'Maintenance'**
  String get dbMaintenance;

  /// No description provided for @mergeDuplicates.
  ///
  /// In fr, this message translates to:
  /// **'Fusionner les doublons'**
  String get mergeDuplicates;

  /// No description provided for @teamManagement.
  ///
  /// In fr, this message translates to:
  /// **'Gestion de l\'équipe & permissions'**
  String get teamManagement;

  /// No description provided for @teamManagementSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter des collaborateurs et gérer leurs droits'**
  String get teamManagementSubtitle;

  /// No description provided for @navAccueil.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get navAccueil;

  /// No description provided for @navCaisse.
  ///
  /// In fr, this message translates to:
  /// **'Caisse'**
  String get navCaisse;

  /// No description provided for @navStock.
  ///
  /// In fr, this message translates to:
  /// **'Stock'**
  String get navStock;

  /// No description provided for @navRapport.
  ///
  /// In fr, this message translates to:
  /// **'Rapport'**
  String get navRapport;

  /// No description provided for @navParametres.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get navParametres;

  /// No description provided for @accHello.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour {prenom} 👋'**
  String accHello(String prenom);

  /// No description provided for @tauxTitle.
  ///
  /// In fr, this message translates to:
  /// **'Taux du jour'**
  String get tauxTitle;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get save;

  /// No description provided for @accToday.
  ///
  /// In fr, this message translates to:
  /// **'AUJOURD\'HUI'**
  String get accToday;

  /// No description provided for @accOfSales.
  ///
  /// In fr, this message translates to:
  /// **'de ventes'**
  String get accOfSales;

  /// No description provided for @accCashed.
  ///
  /// In fr, this message translates to:
  /// **'Encaissé'**
  String get accCashed;

  /// No description provided for @accCredit.
  ///
  /// In fr, this message translates to:
  /// **'Crédit'**
  String get accCredit;

  /// No description provided for @accExpenses.
  ///
  /// In fr, this message translates to:
  /// **'Dépenses'**
  String get accExpenses;

  /// No description provided for @accCashInDrawer.
  ///
  /// In fr, this message translates to:
  /// **'Argent en caisse du jour : {montant}'**
  String accCashInDrawer(String montant);

  /// No description provided for @accDiscounts.
  ///
  /// In fr, this message translates to:
  /// **'Remises accordées : {montant}'**
  String accDiscounts(String montant);

  /// No description provided for @accSendSummary.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer le résumé du jour'**
  String get accSendSummary;

  /// No description provided for @accExpense.
  ///
  /// In fr, this message translates to:
  /// **'Dépense'**
  String get accExpense;

  /// No description provided for @accSales.
  ///
  /// In fr, this message translates to:
  /// **'Ventes'**
  String get accSales;

  /// No description provided for @accClientAccounts.
  ///
  /// In fr, this message translates to:
  /// **'Comptes clients'**
  String get accClientAccounts;

  /// No description provided for @accAccounting.
  ///
  /// In fr, this message translates to:
  /// **'Comptabilité'**
  String get accAccounting;

  /// No description provided for @accHelp.
  ///
  /// In fr, this message translates to:
  /// **'Aide'**
  String get accHelp;

  /// No description provided for @accTodaySales.
  ///
  /// In fr, this message translates to:
  /// **'Ventes d\'aujourd\'hui ({count})'**
  String accTodaySales(int count);

  /// No description provided for @accNoSales.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de vente aujourd\'hui.\nAppuyez sur « Caisse » pour commencer.'**
  String get accNoSales;

  /// No description provided for @accClient.
  ///
  /// In fr, this message translates to:
  /// **'Client'**
  String get accClient;

  /// No description provided for @accRemaining.
  ///
  /// In fr, this message translates to:
  /// **'reste {montant}'**
  String accRemaining(String montant);

  /// No description provided for @accMainShop.
  ///
  /// In fr, this message translates to:
  /// **'Boutique principale'**
  String get accMainShop;

  /// No description provided for @resMorning.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour'**
  String get resMorning;

  /// No description provided for @resAfternoon.
  ///
  /// In fr, this message translates to:
  /// **'Bon après-midi'**
  String get resAfternoon;

  /// No description provided for @resEvening.
  ///
  /// In fr, this message translates to:
  /// **'Bonsoir'**
  String get resEvening;

  /// No description provided for @resNoSales.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de vente aujourd\'hui. Bonne journée de travail ! 💪'**
  String get resNoSales;

  /// No description provided for @resTodayPrefix.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui, '**
  String get resTodayPrefix;

  /// No description provided for @resSalesCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 vente} other{{count} ventes}}'**
  String resSalesCount(int count);

  /// No description provided for @resFor.
  ///
  /// In fr, this message translates to:
  /// **' pour '**
  String get resFor;

  /// No description provided for @resGained.
  ///
  /// In fr, this message translates to:
  /// **'. Vous avez gagné '**
  String get resGained;

  /// No description provided for @resLoss.
  ///
  /// In fr, this message translates to:
  /// **'. Pour l\'instant, perte de '**
  String get resLoss;

  /// No description provided for @todoTitle.
  ///
  /// In fr, this message translates to:
  /// **'📋 À faire aujourd\'hui'**
  String get todoTitle;

  /// No description provided for @todoNothing.
  ///
  /// In fr, this message translates to:
  /// **'✅ Rien d\'urgent. Tout est en ordre !'**
  String get todoNothing;

  /// No description provided for @todoOwes.
  ///
  /// In fr, this message translates to:
  /// **'{nom} vous doit {montant}'**
  String todoOwes(String nom, String montant);

  /// No description provided for @todoOtherClients.
  ///
  /// In fr, this message translates to:
  /// **'…et {count} autre(s) client(s)'**
  String todoOtherClients(int count);

  /// No description provided for @todoOut.
  ///
  /// In fr, this message translates to:
  /// **'{nom} : épuisé'**
  String todoOut(String nom);

  /// No description provided for @todoLow.
  ///
  /// In fr, this message translates to:
  /// **'Il reste seulement {count} {nom}'**
  String todoLow(int count, String nom);

  /// No description provided for @todoOtherProducts.
  ///
  /// In fr, this message translates to:
  /// **'…et {count} autre(s) produit(s) à recommander'**
  String todoOtherProducts(int count);

  /// No description provided for @actSee.
  ///
  /// In fr, this message translates to:
  /// **'Voir'**
  String get actSee;

  /// No description provided for @actAll.
  ///
  /// In fr, this message translates to:
  /// **'Tous'**
  String get actAll;

  /// No description provided for @caisseNoCompany.
  ///
  /// In fr, this message translates to:
  /// **'Erreur : Aucune entreprise sélectionnée.'**
  String get caisseNoCompany;

  /// No description provided for @caisseOutOfStock.
  ///
  /// In fr, this message translates to:
  /// **'{nom} est en rupture de stock !'**
  String caisseOutOfStock(String nom);

  /// No description provided for @caisseStockLimit.
  ///
  /// In fr, this message translates to:
  /// **'Limite du stock atteinte ({count})'**
  String caisseStockLimit(int count);

  /// No description provided for @caisseAdded.
  ///
  /// In fr, this message translates to:
  /// **'{nom} ajouté au panier !'**
  String caisseAdded(String nom);

  /// No description provided for @caisseNoBarcode.
  ///
  /// In fr, this message translates to:
  /// **'Aucun produit trouvé pour le code : {code}'**
  String caisseNoBarcode(String code);

  /// No description provided for @caisseSearch.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un produit…'**
  String get caisseSearch;

  /// No description provided for @caisseScan.
  ///
  /// In fr, this message translates to:
  /// **'Scanner un code-barres'**
  String get caisseScan;

  /// No description provided for @errorPrefix.
  ///
  /// In fr, this message translates to:
  /// **'Erreur : {message}'**
  String errorPrefix(String message);

  /// No description provided for @caisseNoProducts.
  ///
  /// In fr, this message translates to:
  /// **'Aucun produit enregistré.\nAjoutez vos produits dans l\'onglet « Stock ».'**
  String get caisseNoProducts;

  /// No description provided for @caisseHint.
  ///
  /// In fr, this message translates to:
  /// **'Touchez un produit pour l\'ajouter • appui long : quantité'**
  String get caisseHint;

  /// No description provided for @caisseNoMatch.
  ///
  /// In fr, this message translates to:
  /// **'Aucun produit ne correspond à votre recherche.'**
  String get caisseNoMatch;

  /// No description provided for @caisseCheckout.
  ///
  /// In fr, this message translates to:
  /// **'Encaisser {montant}'**
  String caisseCheckout(String montant);

  /// No description provided for @caisseNoName.
  ///
  /// In fr, this message translates to:
  /// **'Sans nom'**
  String get caisseNoName;

  /// No description provided for @caisseOut.
  ///
  /// In fr, this message translates to:
  /// **'Épuisé'**
  String get caisseOut;

  /// No description provided for @caissePriceNeedsPermission.
  ///
  /// In fr, this message translates to:
  /// **'Changer le prix demande l\'autorisation « Remises et retraits ».'**
  String get caissePriceNeedsPermission;

  /// No description provided for @cartTitle.
  ///
  /// In fr, this message translates to:
  /// **'Panier d\'achat'**
  String get cartTitle;

  /// No description provided for @cartEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Votre panier est vide'**
  String get cartEmpty;

  /// No description provided for @cartCount.
  ///
  /// In fr, this message translates to:
  /// **'Panier ({count} références)'**
  String cartCount(int count);

  /// No description provided for @cartClear.
  ///
  /// In fr, this message translates to:
  /// **'Vider le panier'**
  String get cartClear;

  /// No description provided for @cartNormalPrice.
  ///
  /// In fr, this message translates to:
  /// **'Prix normal : {montant}'**
  String cartNormalPrice(String montant);

  /// No description provided for @cartLoss.
  ///
  /// In fr, this message translates to:
  /// **'Vente à perte'**
  String get cartLoss;

  /// No description provided for @addTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter {nom}'**
  String addTitle(String nom);

  /// No description provided for @lossConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Le prix de {nom} est sous le prix d\'achat.\nVoulez-vous vraiment vendre à ce prix ?'**
  String lossConfirm(String nom);

  /// No description provided for @noCorrect.
  ///
  /// In fr, this message translates to:
  /// **'Non, corriger'**
  String get noCorrect;

  /// No description provided for @yesSell.
  ///
  /// In fr, this message translates to:
  /// **'Oui, vendre'**
  String get yesSell;

  /// No description provided for @stockAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Stock disponible : {count}'**
  String stockAvailable(int count);

  /// No description provided for @unitPrice.
  ///
  /// In fr, this message translates to:
  /// **'Prix unitaire ({code})'**
  String unitPrice(String code);

  /// No description provided for @discountPerPiece.
  ///
  /// In fr, this message translates to:
  /// **'Remise : {montant} par pièce'**
  String discountPerPiece(String montant);

  /// No description provided for @fixedPrice.
  ///
  /// In fr, this message translates to:
  /// **'Prix fixe (autorisation « Remises et retraits » nécessaire)'**
  String get fixedPrice;

  /// No description provided for @lossWithCost.
  ///
  /// In fr, this message translates to:
  /// **'Vente à perte ! Prix d\'achat : {montant}'**
  String lossWithCost(String montant);

  /// No description provided for @lossBelowCost.
  ///
  /// In fr, this message translates to:
  /// **'Vente à perte : ce prix est sous le prix d\'achat.'**
  String get lossBelowCost;

  /// No description provided for @qtyInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Quantité invalide'**
  String get qtyInvalid;

  /// No description provided for @maxAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Max disponible : {count}'**
  String maxAvailable(int count);

  /// No description provided for @quantity.
  ///
  /// In fr, this message translates to:
  /// **'Quantité'**
  String get quantity;

  /// No description provided for @subtotal.
  ///
  /// In fr, this message translates to:
  /// **'Sous-total :'**
  String get subtotal;

  /// No description provided for @qtyOverStock.
  ///
  /// In fr, this message translates to:
  /// **'Quantité supérieure au stock disponible ({count})'**
  String qtyOverStock(int count);

  /// No description provided for @outOfStockGeneric.
  ///
  /// In fr, this message translates to:
  /// **'Produit en rupture de stock !'**
  String get outOfStockGeneric;

  /// No description provided for @sellAtLoss.
  ///
  /// In fr, this message translates to:
  /// **'Vendre à perte'**
  String get sellAtLoss;

  /// No description provided for @add.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get add;

  /// No description provided for @priceFor.
  ///
  /// In fr, this message translates to:
  /// **'Prix pour {nom}'**
  String priceFor(String nom);

  /// No description provided for @agreedPrice.
  ///
  /// In fr, this message translates to:
  /// **'Prix accordé (par pièce)'**
  String get agreedPrice;

  /// No description provided for @normalPriceBtn.
  ///
  /// In fr, this message translates to:
  /// **'Prix normal'**
  String get normalPriceBtn;

  /// No description provided for @validate.
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get validate;

  /// No description provided for @payTitle.
  ///
  /// In fr, this message translates to:
  /// **'Finaliser la vente & Règlement'**
  String get payTitle;

  /// No description provided for @payClientName.
  ///
  /// In fr, this message translates to:
  /// **'Nom du Client'**
  String get payClientName;

  /// No description provided for @payPhone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone (ex: +243...)'**
  String get payPhone;

  /// No description provided for @payClientAccount.
  ///
  /// In fr, this message translates to:
  /// **'Compte client : {montant}'**
  String payClientAccount(String montant);

  /// No description provided for @payUse.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser'**
  String get payUse;

  /// No description provided for @payPaidByAccount.
  ///
  /// In fr, this message translates to:
  /// **'Payé par le compte : {montant} • Nouveau solde : {solde}'**
  String payPaidByAccount(String montant, String solde);

  /// No description provided for @payMethod.
  ///
  /// In fr, this message translates to:
  /// **'Moyen'**
  String get payMethod;

  /// No description provided for @payStatus.
  ///
  /// In fr, this message translates to:
  /// **'Statut'**
  String get payStatus;

  /// No description provided for @payCash.
  ///
  /// In fr, this message translates to:
  /// **'Cash'**
  String get payCash;

  /// No description provided for @payCard.
  ///
  /// In fr, this message translates to:
  /// **'Carte bancaire'**
  String get payCard;

  /// No description provided for @payTransfer.
  ///
  /// In fr, this message translates to:
  /// **'Virement'**
  String get payTransfer;

  /// No description provided for @payPaid.
  ///
  /// In fr, this message translates to:
  /// **'Payé'**
  String get payPaid;

  /// No description provided for @payDebt.
  ///
  /// In fr, this message translates to:
  /// **'Dette'**
  String get payDebt;

  /// No description provided for @payPartial.
  ///
  /// In fr, this message translates to:
  /// **'Paiement partiel'**
  String get payPartial;

  /// No description provided for @payInvoiceTotal.
  ///
  /// In fr, this message translates to:
  /// **'Total Facture :'**
  String get payInvoiceTotal;

  /// No description provided for @payPaidByClientAccount.
  ///
  /// In fr, this message translates to:
  /// **'Payé par compte client :'**
  String get payPaidByClientAccount;

  /// No description provided for @payToCollect.
  ///
  /// In fr, this message translates to:
  /// **'À encaisser maintenant :'**
  String get payToCollect;

  /// No description provided for @payAllIn.
  ///
  /// In fr, this message translates to:
  /// **'Tout en {code}'**
  String payAllIn(String code);

  /// No description provided for @payRestIn.
  ///
  /// In fr, this message translates to:
  /// **'Reste en {code}'**
  String payRestIn(String code);

  /// No description provided for @payReceived.
  ///
  /// In fr, this message translates to:
  /// **'Montant Perçu ({code})'**
  String payReceived(String code);

  /// No description provided for @payRemaining.
  ///
  /// In fr, this message translates to:
  /// **'Reste dû :'**
  String get payRemaining;

  /// No description provided for @payChange.
  ///
  /// In fr, this message translates to:
  /// **'Monnaie à rendre ({code}) :'**
  String payChange(String code);

  /// No description provided for @payDelivery.
  ///
  /// In fr, this message translates to:
  /// **'Livraison'**
  String get payDelivery;

  /// No description provided for @payDeliveredNow.
  ///
  /// In fr, this message translates to:
  /// **'Livré maintenant'**
  String get payDeliveredNow;

  /// No description provided for @payDeliverLater.
  ///
  /// In fr, this message translates to:
  /// **'À livrer plus tard'**
  String get payDeliverLater;

  /// No description provided for @payPickupBefore.
  ///
  /// In fr, this message translates to:
  /// **'À retirer avant'**
  String get payPickupBefore;

  /// No description provided for @payDeadline.
  ///
  /// In fr, this message translates to:
  /// **'Date limite : {date} — le client apparaîtra dans « À livrer ».'**
  String payDeadline(String date);

  /// No description provided for @payDays.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 jour} other{{count} jours}}'**
  String payDays(int count);

  /// No description provided for @payReceiptActions.
  ///
  /// In fr, this message translates to:
  /// **'Actions pour le reçu :'**
  String get payReceiptActions;

  /// No description provided for @payPrintReceipt.
  ///
  /// In fr, this message translates to:
  /// **'Imprimer le reçu thermique'**
  String get payPrintReceipt;

  /// No description provided for @paySendWhatsApp.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer par WhatsApp'**
  String get paySendWhatsApp;

  /// No description provided for @paySendSms.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer par SMS'**
  String get paySendSms;

  /// No description provided for @payValidate.
  ///
  /// In fr, this message translates to:
  /// **'Valider & Encaisser'**
  String get payValidate;

  /// No description provided for @payBalanceChanged.
  ///
  /// In fr, this message translates to:
  /// **'Le solde du client a changé (disponible : {montant} \$). Désactivez puis réactivez « Utiliser » pour recalculer.'**
  String payBalanceChanged(String montant);

  /// No description provided for @payNotSaved.
  ///
  /// In fr, this message translates to:
  /// **'Vente NON enregistrée'**
  String get payNotSaved;

  /// No description provided for @payDenied.
  ///
  /// In fr, this message translates to:
  /// **'Le serveur a refusé cette vente (droits insuffisants).\n\nRien n\'a été enregistré : ni la vente, ni le stock, ni la caisse.\nNe donnez pas encore la marchandise : prévenez le responsable.\n\nCode : {code}'**
  String payDenied(String code);

  /// No description provided for @payNotSavedOther.
  ///
  /// In fr, this message translates to:
  /// **'Rien n\'a été enregistré.\n\n{detail}'**
  String payNotSavedOther(String detail);

  /// No description provided for @payUnderstood.
  ///
  /// In fr, this message translates to:
  /// **'Compris'**
  String get payUnderstood;

  /// No description provided for @paySaved.
  ///
  /// In fr, this message translates to:
  /// **'Vente enregistrée avec succès !'**
  String get paySaved;

  /// No description provided for @paySavedPickup.
  ///
  /// In fr, this message translates to:
  /// **'Vente enregistrée — à retirer avant le {date}.'**
  String paySavedPickup(String date);

  /// No description provided for @payNewBalance.
  ///
  /// In fr, this message translates to:
  /// **' Nouveau solde du client : {montant}.'**
  String payNewBalance(String montant);

  /// No description provided for @payError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la validation : {message}'**
  String payError(String message);

  /// No description provided for @debtNewClient.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle Créance Client'**
  String get debtNewClient;

  /// No description provided for @debtNewSupplier.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle Dette Fournisseur'**
  String get debtNewSupplier;

  /// No description provided for @debtClientName.
  ///
  /// In fr, this message translates to:
  /// **'Nom du Client *'**
  String get debtClientName;

  /// No description provided for @debtSupplierName.
  ///
  /// In fr, this message translates to:
  /// **'Nom du Fournisseur *'**
  String get debtSupplierName;

  /// No description provided for @debtInvoiceRef.
  ///
  /// In fr, this message translates to:
  /// **'N° Facture / Référence'**
  String get debtInvoiceRef;

  /// No description provided for @debtTotal.
  ///
  /// In fr, this message translates to:
  /// **'Montant Total *'**
  String get debtTotal;

  /// No description provided for @debtAlreadyPaid.
  ///
  /// In fr, this message translates to:
  /// **'Montant déjà payé (paiement partiel)'**
  String get debtAlreadyPaid;

  /// No description provided for @debtPickDueDate.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner une date d\'échéance'**
  String get debtPickDueDate;

  /// No description provided for @debtDueDate.
  ///
  /// In fr, this message translates to:
  /// **'Échéance : {date}'**
  String debtDueDate(String date);

  /// No description provided for @debtNote.
  ///
  /// In fr, this message translates to:
  /// **'Motif (facultatif)'**
  String get debtNote;

  /// No description provided for @debtPaidOverTotal.
  ///
  /// In fr, this message translates to:
  /// **'Le montant déjà payé dépasse le montant total.'**
  String get debtPaidOverTotal;

  /// No description provided for @debtPaymentTitle.
  ///
  /// In fr, this message translates to:
  /// **'Règlement : {nom}'**
  String debtPaymentTitle(String nom);

  /// No description provided for @debtInvoiceNo.
  ///
  /// In fr, this message translates to:
  /// **'Facture N° : {numero}'**
  String debtInvoiceNo(String numero);

  /// No description provided for @debtRemainingNow.
  ///
  /// In fr, this message translates to:
  /// **'Reste à payer actuel : {montant}'**
  String debtRemainingNow(String montant);

  /// No description provided for @debtPaymentAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant du Règlement'**
  String get debtPaymentAmount;

  /// No description provided for @debtHelperSurplus.
  ///
  /// In fr, this message translates to:
  /// **'Reste : {montant}. Un surplus peut aller sur son compte client.'**
  String debtHelperSurplus(String montant);

  /// No description provided for @debtMax.
  ///
  /// In fr, this message translates to:
  /// **'Maximum : {montant}'**
  String debtMax(String montant);

  /// No description provided for @debtPaymentMode.
  ///
  /// In fr, this message translates to:
  /// **'Mode de paiement'**
  String get debtPaymentMode;

  /// No description provided for @debtCashDesk.
  ///
  /// In fr, this message translates to:
  /// **'Espèces (Caisse)'**
  String get debtCashDesk;

  /// No description provided for @debtCheck.
  ///
  /// In fr, this message translates to:
  /// **'Chèque'**
  String get debtCheck;

  /// No description provided for @debtEnterAmount.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez un montant.'**
  String get debtEnterAmount;

  /// No description provided for @debtTooHighNoPhone.
  ///
  /// In fr, this message translates to:
  /// **'Trop élevé. Maximum : {montant} (client sans numéro : pas de compte client)'**
  String debtTooHighNoPhone(String montant);

  /// No description provided for @debtTooHigh.
  ///
  /// In fr, this message translates to:
  /// **'Trop élevé. Maximum : {montant}'**
  String debtTooHigh(String montant);

  /// No description provided for @debtGivesMore.
  ///
  /// In fr, this message translates to:
  /// **'Le client donne plus'**
  String get debtGivesMore;

  /// No description provided for @debtSurplusQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Dette : {dette}\nDonné : {donne}\n\nMettre {surplus} sur le compte client de {nom} ?\nIl pourra s\'en servir pour ses prochains achats.'**
  String debtSurplusQuestion(
      String dette, String donne, String surplus, String nom);

  /// No description provided for @debtYesAccount.
  ///
  /// In fr, this message translates to:
  /// **'Oui, sur son compte'**
  String get debtYesAccount;

  /// No description provided for @debtSettled.
  ///
  /// In fr, this message translates to:
  /// **'Dette soldée. {montant} mis sur le compte de {nom}.'**
  String debtSettled(String montant, String nom);

  /// No description provided for @debtPendingNet.
  ///
  /// In fr, this message translates to:
  /// **' (envoi dès le retour d\'internet)'**
  String get debtPendingNet;

  /// No description provided for @debtPaymentSaved.
  ///
  /// In fr, this message translates to:
  /// **'Règlement de {montant} enregistré.'**
  String debtPaymentSaved(String montant);

  /// No description provided for @debtValidatePayment.
  ///
  /// In fr, this message translates to:
  /// **'Valider le Règlement'**
  String get debtValidatePayment;

  /// No description provided for @debtScreenTitle.
  ///
  /// In fr, this message translates to:
  /// **'Créances & Dettes'**
  String get debtScreenTitle;

  /// No description provided for @debtExport.
  ///
  /// In fr, this message translates to:
  /// **'Exporter'**
  String get debtExport;

  /// No description provided for @debtExportExcel.
  ///
  /// In fr, this message translates to:
  /// **'Exporter vers Excel'**
  String get debtExportExcel;

  /// No description provided for @debtPrintPdf.
  ///
  /// In fr, this message translates to:
  /// **'Imprimer / PDF'**
  String get debtPrintPdf;

  /// No description provided for @debtTabClients.
  ///
  /// In fr, this message translates to:
  /// **'Clients'**
  String get debtTabClients;

  /// No description provided for @debtTabSuppliers.
  ///
  /// In fr, this message translates to:
  /// **'Fournisseurs'**
  String get debtTabSuppliers;

  /// No description provided for @debtLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de chargement : {message}'**
  String debtLoadError(String message);

  /// No description provided for @debtAdd.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une dette'**
  String get debtAdd;

  /// No description provided for @ageToday.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get ageToday;

  /// No description provided for @ageYesterday.
  ///
  /// In fr, this message translates to:
  /// **'Hier'**
  String get ageYesterday;

  /// No description provided for @ageDays.
  ///
  /// In fr, this message translates to:
  /// **'Il y a {count} jours'**
  String ageDays(int count);

  /// No description provided for @ageMonths.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Il y a 1 mois} other{Il y a {count} mois}}'**
  String ageMonths(int count);

  /// No description provided for @whatsAppError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'ouvrir WhatsApp sur cet appareil.'**
  String get whatsAppError;

  /// No description provided for @debtEmptyClients.
  ///
  /// In fr, this message translates to:
  /// **'Aucune créance client'**
  String get debtEmptyClients;

  /// No description provided for @debtEmptySuppliers.
  ///
  /// In fr, this message translates to:
  /// **'Aucune dette fournisseur'**
  String get debtEmptySuppliers;

  /// No description provided for @debtEmptyClientsHint.
  ///
  /// In fr, this message translates to:
  /// **'Les ventes à crédit ou partielles apparaîtront ici automatiquement.'**
  String get debtEmptyClientsHint;

  /// No description provided for @debtEmptySuppliersHint.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez ici ce que vous devez à vos fournisseurs avec le bouton « Ajouter une dette ».'**
  String get debtEmptySuppliersHint;

  /// No description provided for @noResults.
  ///
  /// In fr, this message translates to:
  /// **'Aucun résultat'**
  String get noResults;

  /// No description provided for @noResultsHint.
  ///
  /// In fr, this message translates to:
  /// **'Essayez un autre filtre ou une autre recherche.'**
  String get noResultsHint;

  /// No description provided for @debtToCollect.
  ///
  /// In fr, this message translates to:
  /// **'À RECOUVRER (CLIENTS)'**
  String get debtToCollect;

  /// No description provided for @debtToPay.
  ///
  /// In fr, this message translates to:
  /// **'À PAYER (FOURNISSEURS)'**
  String get debtToPay;

  /// No description provided for @debtOpenFiles.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{dossier ouvert} other{dossiers ouverts}}'**
  String debtOpenFiles(int count);

  /// No description provided for @debtClientsCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{client} other{clients}}'**
  String debtClientsCount(int count);

  /// No description provided for @debtSuppliersCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{fournisseur} other{fournisseurs}}'**
  String debtSuppliersCount(int count);

  /// No description provided for @debtLateCount.
  ///
  /// In fr, this message translates to:
  /// **'en retard ({count})'**
  String debtLateCount(int count);

  /// No description provided for @debtSearchClients.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un client, une facture, un téléphone…'**
  String get debtSearchClients;

  /// No description provided for @debtSearchSuppliers.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un fournisseur, une facture…'**
  String get debtSearchSuppliers;

  /// No description provided for @filterOngoing.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get filterOngoing;

  /// No description provided for @filterRecent.
  ///
  /// In fr, this message translates to:
  /// **'Récentes (< 30 j)'**
  String get filterRecent;

  /// No description provided for @filterLate.
  ///
  /// In fr, this message translates to:
  /// **'En retard'**
  String get filterLate;

  /// No description provided for @filterPartial.
  ///
  /// In fr, this message translates to:
  /// **'Partielles'**
  String get filterPartial;

  /// No description provided for @filterSettled.
  ///
  /// In fr, this message translates to:
  /// **'Soldées'**
  String get filterSettled;

  /// No description provided for @statusSettled.
  ///
  /// In fr, this message translates to:
  /// **'Soldée'**
  String get statusSettled;

  /// No description provided for @statusPartial.
  ///
  /// In fr, this message translates to:
  /// **'Partiel'**
  String get statusPartial;

  /// No description provided for @statusUnpaid.
  ///
  /// In fr, this message translates to:
  /// **'Non payée'**
  String get statusUnpaid;

  /// No description provided for @invoiceShort.
  ///
  /// In fr, this message translates to:
  /// **'Fact. {numero}'**
  String invoiceShort(String numero);

  /// No description provided for @paidOf.
  ///
  /// In fr, this message translates to:
  /// **'Payé {paye} sur {total}'**
  String paidOf(String paye, String total);

  /// No description provided for @lastPayment.
  ///
  /// In fr, this message translates to:
  /// **'Dernier paiement {date}'**
  String lastPayment(String date);

  /// No description provided for @remind.
  ///
  /// In fr, this message translates to:
  /// **'Relancer'**
  String get remind;

  /// No description provided for @message.
  ///
  /// In fr, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @collect.
  ///
  /// In fr, this message translates to:
  /// **'Encaisser'**
  String get collect;

  /// No description provided for @pay.
  ///
  /// In fr, this message translates to:
  /// **'Payer'**
  String get pay;

  /// No description provided for @printFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impression impossible : {message}'**
  String printFailed(String message);

  /// No description provided for @printerTitle.
  ///
  /// In fr, this message translates to:
  /// **'Imprimante'**
  String get printerTitle;

  /// No description provided for @printerPhoneOnly.
  ///
  /// In fr, this message translates to:
  /// **'Réglages de ce téléphone seulement'**
  String get printerPhoneOnly;

  /// No description provided for @printerPaperWidth.
  ///
  /// In fr, this message translates to:
  /// **'Largeur du papier'**
  String get printerPaperWidth;

  /// No description provided for @printer58.
  ///
  /// In fr, this message translates to:
  /// **'58 mm (petite)'**
  String get printer58;

  /// No description provided for @printer80.
  ///
  /// In fr, this message translates to:
  /// **'80 mm (grande)'**
  String get printer80;

  /// No description provided for @printerAfterSale.
  ///
  /// In fr, this message translates to:
  /// **'Après une vente, le reçu…'**
  String get printerAfterSale;

  /// No description provided for @printerPrints.
  ///
  /// In fr, this message translates to:
  /// **'S\'imprime'**
  String get printerPrints;

  /// No description provided for @printerPrintsHint.
  ///
  /// In fr, this message translates to:
  /// **'Fenêtre d\'impression d\'Android (imprimante installée sur le téléphone)'**
  String get printerPrintsHint;

  /// No description provided for @printerPdf.
  ///
  /// In fr, this message translates to:
  /// **'Est envoyé en PDF'**
  String get printerPdf;

  /// No description provided for @printerPdfHint.
  ///
  /// In fr, this message translates to:
  /// **'WhatsApp, Bluetooth, e-mail… (quand il n\'y a pas d\'imprimante)'**
  String get printerPdfHint;

  /// No description provided for @printerTest.
  ///
  /// In fr, this message translates to:
  /// **'Imprimer un reçu d\'essai'**
  String get printerTest;

  /// No description provided for @crashTest.
  ///
  /// In fr, this message translates to:
  /// **'Tester les rapports d\'erreurs'**
  String get crashTest;

  /// No description provided for @crashDebugOnly.
  ///
  /// In fr, this message translates to:
  /// **'Les rapports ne partent que depuis l\'APK (pas au câble).'**
  String get crashDebugOnly;

  /// No description provided for @crashSent.
  ///
  /// In fr, this message translates to:
  /// **'Rapport de test envoyé. Il apparaît dans Firebase sous quelques minutes.'**
  String get crashSent;

  /// No description provided for @guideTitle.
  ///
  /// In fr, this message translates to:
  /// **'Guide d\'utilisation'**
  String get guideTitle;

  /// No description provided for @guideSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Comment vendre, encaisser une dette, imprimer…'**
  String get guideSubtitle;

  /// No description provided for @guideSearch.
  ///
  /// In fr, this message translates to:
  /// **'Chercher : dette, taux, imprimer…'**
  String get guideSearch;

  /// No description provided for @guideNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Rien trouvé pour « {mot} ».'**
  String guideNotFound(String mot);

  /// No description provided for @guideOwnerOnly.
  ///
  /// In fr, this message translates to:
  /// **'Patron / gérant'**
  String get guideOwnerOnly;

  /// No description provided for @stockDeleted.
  ///
  /// In fr, this message translates to:
  /// **'« {nom} » supprimé.'**
  String stockDeleted(String nom);

  /// No description provided for @stockDeletedOffline.
  ///
  /// In fr, this message translates to:
  /// **'« {nom} » supprimé sur le téléphone. Envoi dès le retour d\'internet.'**
  String stockDeletedOffline(String nom);

  /// No description provided for @stockDeleteError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la suppression : {message}'**
  String stockDeleteError(String message);

  /// No description provided for @stockAnalyzing.
  ///
  /// In fr, this message translates to:
  /// **'Analyse...'**
  String get stockAnalyzing;

  /// No description provided for @stockImported.
  ///
  /// In fr, this message translates to:
  /// **'{count} produit(s) importé(s) ou mis à jour avec succès !'**
  String stockImported(int count);

  /// No description provided for @stockImportError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur d\'importation : {message}'**
  String stockImportError(String message);

  /// No description provided for @stockConnected.
  ///
  /// In fr, this message translates to:
  /// **'Connecté: {nom}'**
  String stockConnected(String nom);

  /// No description provided for @stockImportTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Importer Excel / CSV / Packing List'**
  String get stockImportTooltip;

  /// No description provided for @myAccount.
  ///
  /// In fr, this message translates to:
  /// **'Mon compte'**
  String get myAccount;

  /// No description provided for @changePassword.
  ///
  /// In fr, this message translates to:
  /// **'Changer mon mot de passe'**
  String get changePassword;

  /// No description provided for @logout.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get logout;

  /// No description provided for @stockNoProduct.
  ///
  /// In fr, this message translates to:
  /// **'Aucun produit trouvé.'**
  String get stockNoProduct;

  /// No description provided for @stockProducts.
  ///
  /// In fr, this message translates to:
  /// **'Produits'**
  String get stockProducts;

  /// No description provided for @stockValue.
  ///
  /// In fr, this message translates to:
  /// **'Valeur Stock'**
  String get stockValue;

  /// No description provided for @stockCannotDelete.
  ///
  /// In fr, this message translates to:
  /// **'Suppression impossible'**
  String get stockCannotDelete;

  /// No description provided for @stockCannotDeleteMsg.
  ///
  /// In fr, this message translates to:
  /// **'« {nom} » a encore {count} article(s) en stock.\n\nMettez d\'abord le stock à 0 (inventaire ou perte), pour que la perte reste visible dans les comptes.'**
  String stockCannotDeleteMsg(String nom, int count);

  /// No description provided for @stockDeleteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le produit'**
  String get stockDeleteTitle;

  /// No description provided for @stockDeleteConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous vraiment supprimer « {nom} » ?\n\nCette action est définitive.'**
  String stockDeleteConfirm(String nom);

  /// No description provided for @delete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get delete;

  /// No description provided for @stockNewProduct.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau Produit'**
  String get stockNewProduct;

  /// No description provided for @stockQty.
  ///
  /// In fr, this message translates to:
  /// **'Stock: {count}'**
  String stockQty(int count);

  /// No description provided for @stockAlert.
  ///
  /// In fr, this message translates to:
  /// **'Alerte stock'**
  String get stockAlert;

  /// No description provided for @edit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get edit;

  /// No description provided for @prodDefaultName.
  ///
  /// In fr, this message translates to:
  /// **'Produit sans nom'**
  String get prodDefaultName;

  /// No description provided for @prodBarcodeUsed.
  ///
  /// In fr, this message translates to:
  /// **'Code-barres déjà utilisé'**
  String get prodBarcodeUsed;

  /// No description provided for @prodBarcodeUsedMsg.
  ///
  /// In fr, this message translates to:
  /// **'Ce code appartient déjà à :\n\n« {nom} »\nStock : {stock}  •  Prix : {prix} \$\n\nVoulez-vous ouvrir ce produit pour le modifier (par exemple ajouter du stock) ?'**
  String prodBarcodeUsedMsg(String nom, String stock, String prix);

  /// No description provided for @prodOpenThis.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir ce produit'**
  String get prodOpenThis;

  /// No description provided for @prodNoCompany.
  ///
  /// In fr, this message translates to:
  /// **'Entreprise introuvable. Déconnectez-vous puis reconnectez-vous.'**
  String get prodNoCompany;

  /// No description provided for @prodSavedOffline.
  ///
  /// In fr, this message translates to:
  /// **'Enregistré sur le téléphone. Il sera envoyé dès que internet revient.'**
  String get prodSavedOffline;

  /// No description provided for @prodUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Produit mis à jour avec succès !'**
  String get prodUpdated;

  /// No description provided for @prodAdded.
  ///
  /// In fr, this message translates to:
  /// **'Produit ajouté avec succès !'**
  String get prodAdded;

  /// No description provided for @prodSaveError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de l\'enregistrement : {message}'**
  String prodSaveError(String message);

  /// No description provided for @prodEditTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le produit'**
  String get prodEditTitle;

  /// No description provided for @prodImportPacking.
  ///
  /// In fr, this message translates to:
  /// **'Importer Packing List (Excel / CSV)'**
  String get prodImportPacking;

  /// No description provided for @prodOrManual.
  ///
  /// In fr, this message translates to:
  /// **'OU SAISIE MANUELLE'**
  String get prodOrManual;

  /// No description provided for @prodImageUrl.
  ///
  /// In fr, this message translates to:
  /// **'URL de l\'image'**
  String get prodImageUrl;

  /// No description provided for @prodImageUrlOpt.
  ///
  /// In fr, this message translates to:
  /// **'URL de l\'image (optionnel)'**
  String get prodImageUrlOpt;

  /// No description provided for @prodName.
  ///
  /// In fr, this message translates to:
  /// **'Nom du produit *'**
  String get prodName;

  /// No description provided for @prodNameHint.
  ///
  /// In fr, this message translates to:
  /// **'ex: T-Shirt Coton'**
  String get prodNameHint;

  /// No description provided for @prodNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Nom obligatoire'**
  String get prodNameRequired;

  /// No description provided for @prodBarcode.
  ///
  /// In fr, this message translates to:
  /// **'Code-barres'**
  String get prodBarcode;

  /// No description provided for @prodBarcodeHint.
  ///
  /// In fr, this message translates to:
  /// **'Scanner / Saisir'**
  String get prodBarcodeHint;

  /// No description provided for @prodCategory.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie'**
  String get prodCategory;

  /// No description provided for @prodBuyPrice.
  ///
  /// In fr, this message translates to:
  /// **'Prix d\'achat (\$)'**
  String get prodBuyPrice;

  /// No description provided for @prodInvalidPrice.
  ///
  /// In fr, this message translates to:
  /// **'Prix invalide'**
  String get prodInvalidPrice;

  /// No description provided for @prodSellPrice.
  ///
  /// In fr, this message translates to:
  /// **'Prix vente (\$)*'**
  String get prodSellPrice;

  /// No description provided for @prodPriceRequired.
  ///
  /// In fr, this message translates to:
  /// **'Prix requis'**
  String get prodPriceRequired;

  /// No description provided for @prodStock.
  ///
  /// In fr, this message translates to:
  /// **'Stock *'**
  String get prodStock;

  /// No description provided for @prodInitialStock.
  ///
  /// In fr, this message translates to:
  /// **'Stock initial *'**
  String get prodInitialStock;

  /// No description provided for @prodStockRequired.
  ///
  /// In fr, this message translates to:
  /// **'Stock requis'**
  String get prodStockRequired;

  /// No description provided for @prodWholeNumber.
  ///
  /// In fr, this message translates to:
  /// **'Nombre entier'**
  String get prodWholeNumber;

  /// No description provided for @prodAlertLevel.
  ///
  /// In fr, this message translates to:
  /// **'Seuil d\'alerte'**
  String get prodAlertLevel;

  /// No description provided for @prodSaving.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrement...'**
  String get prodSaving;

  /// No description provided for @prodUpdate.
  ///
  /// In fr, this message translates to:
  /// **'Mettre à jour'**
  String get prodUpdate;

  /// No description provided for @prodSave.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer le produit'**
  String get prodSave;

  /// No description provided for @msgLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Langue du message'**
  String get msgLanguage;

  /// No description provided for @sumDays.
  ///
  /// In fr, this message translates to:
  /// **'lundi,mardi,mercredi,jeudi,vendredi,samedi,dimanche'**
  String get sumDays;

  /// No description provided for @sumAllShops.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les boutiques'**
  String get sumAllShops;

  /// No description provided for @sumSales.
  ///
  /// In fr, this message translates to:
  /// **'Ventes : {count} pour {montant}'**
  String sumSales(int count, String montant);

  /// No description provided for @sumCollected.
  ///
  /// In fr, this message translates to:
  /// **'Encaissé : {montant}'**
  String sumCollected(String montant);

  /// No description provided for @sumCredit.
  ///
  /// In fr, this message translates to:
  /// **'Crédit : {montant}'**
  String sumCredit(String montant);

  /// No description provided for @sumExpenses.
  ///
  /// In fr, this message translates to:
  /// **'Dépenses : {montant}'**
  String sumExpenses(String montant);

  /// No description provided for @sumCash.
  ///
  /// In fr, this message translates to:
  /// **'💵 Argent en caisse : {montant}'**
  String sumCash(String montant);

  /// No description provided for @sumProfit.
  ///
  /// In fr, this message translates to:
  /// **'📈 Bénéfice : {montant}'**
  String sumProfit(String montant);

  /// No description provided for @sumRate.
  ///
  /// In fr, this message translates to:
  /// **'Taux : 1 \$ = {taux} FC'**
  String sumRate(String taux);

  /// No description provided for @sumSentBy.
  ///
  /// In fr, this message translates to:
  /// **'Envoyé par {nom} — Nguli'**
  String sumSentBy(String nom);

  /// No description provided for @logoutQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter ?'**
  String get logoutQuestion;

  /// No description provided for @logoutWarning.
  ///
  /// In fr, this message translates to:
  /// **'Vous devrez vous reconnecter avec votre e-mail et votre mot de passe.'**
  String get logoutWarning;

  /// No description provided for @exportDone.
  ///
  /// In fr, this message translates to:
  /// **'Exportation Excel terminée avec succès !'**
  String get exportDone;

  /// No description provided for @exportError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur d\'exportation : {message}'**
  String exportError(String message);

  /// No description provided for @attention.
  ///
  /// In fr, this message translates to:
  /// **'Attention'**
  String get attention;

  /// No description provided for @mergeConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous vraiment fusionner les produits en double ? Cette action est irréversible.'**
  String get mergeConfirm;

  /// No description provided for @mergeDone.
  ///
  /// In fr, this message translates to:
  /// **'Nettoyage des doublons terminé avec succès !'**
  String get mergeDone;

  /// No description provided for @confirmBtn.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get confirmBtn;

  /// No description provided for @backfillTitle.
  ///
  /// In fr, this message translates to:
  /// **'Rattraper le coût des anciennes ventes'**
  String get backfillTitle;

  /// No description provided for @backfillExplain.
  ///
  /// In fr, this message translates to:
  /// **'Les anciennes ventes qui n\'ont pas encore d\'écriture « Sortie de stock » vont en recevoir une, à leur date d\'origine.\n\nLe coût est calculé avec le prix d\'achat ACTUEL de chaque produit.\n\nVous pouvez relancer cette opération sans risque : une vente n\'est jamais comptée deux fois.'**
  String get backfillExplain;

  /// No description provided for @launch.
  ///
  /// In fr, this message translates to:
  /// **'Lancer'**
  String get launch;

  /// No description provided for @backfillRunning.
  ///
  /// In fr, this message translates to:
  /// **'Rattrapage en cours…'**
  String get backfillRunning;

  /// No description provided for @backfillNothing.
  ///
  /// In fr, this message translates to:
  /// **'Rien à rattraper'**
  String get backfillNothing;

  /// No description provided for @backfillDone.
  ///
  /// In fr, this message translates to:
  /// **'Rattrapage terminé'**
  String get backfillDone;

  /// No description provided for @backfillAllDone.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les ventes ({count}) ont déjà leur écriture « Sortie de stock ».'**
  String backfillAllDone(String count);

  /// No description provided for @backfillResult.
  ///
  /// In fr, this message translates to:
  /// **'{nb} vente(s) rattrapée(s) sur {total}.\n\nCoût des marchandises ajouté : {cout} \$'**
  String backfillResult(String nb, String total, String cout);

  /// No description provided for @backfillNoPrice.
  ///
  /// In fr, this message translates to:
  /// **'⚠️ {count} article(s) sans prix d\'achat : leur coût est compté à 0. Complétez leur prix d\'achat puis relancez.'**
  String backfillNoPrice(String count);

  /// No description provided for @backfillOffline.
  ///
  /// In fr, this message translates to:
  /// **'Enregistré sur le téléphone : l\'envoi se fera au retour d\'internet.'**
  String get backfillOffline;

  /// No description provided for @error.
  ///
  /// In fr, this message translates to:
  /// **'Erreur'**
  String get error;

  /// No description provided for @backfillFailed.
  ///
  /// In fr, this message translates to:
  /// **'Le rattrapage n\'a pas pu se faire : {message}'**
  String backfillFailed(String message);

  /// No description provided for @maintTitle.
  ///
  /// In fr, this message translates to:
  /// **'Maintenance & Base de données'**
  String get maintTitle;

  /// No description provided for @shopTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes boutiques'**
  String get shopTitle;

  /// No description provided for @shopCardSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Créer et gérer vos points de vente'**
  String get shopCardSubtitle;

  /// No description provided for @shopNew.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle boutique'**
  String get shopNew;

  /// No description provided for @shopEditTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la boutique'**
  String get shopEditTitle;

  /// No description provided for @shopNameLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nom de la boutique *'**
  String get shopNameLabel;

  /// No description provided for @shopNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex : Boutique Birere'**
  String get shopNameHint;

  /// No description provided for @shopNameError.
  ///
  /// In fr, this message translates to:
  /// **'Entrez un nom (2 lettres minimum)'**
  String get shopNameError;

  /// No description provided for @shopAddress.
  ///
  /// In fr, this message translates to:
  /// **'Adresse (facultatif)'**
  String get shopAddress;

  /// No description provided for @shopPhone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone (facultatif)'**
  String get shopPhone;

  /// No description provided for @shopCreated.
  ///
  /// In fr, this message translates to:
  /// **'Boutique « {nom} » créée'**
  String shopCreated(String nom);

  /// No description provided for @shopUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Boutique modifiée'**
  String get shopUpdated;

  /// No description provided for @shopReactivated.
  ///
  /// In fr, this message translates to:
  /// **'« {nom} » réactivée'**
  String shopReactivated(String nom);

  /// No description provided for @shopDeactivated.
  ///
  /// In fr, this message translates to:
  /// **'« {nom} » désactivée'**
  String shopDeactivated(String nom);

  /// No description provided for @shopTransfersTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Transferts de stock'**
  String get shopTransfersTooltip;

  /// No description provided for @shopLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les boutiques : {message}'**
  String shopLoadError(String message);

  /// No description provided for @shopInfo.
  ///
  /// In fr, this message translates to:
  /// **'Stock de la boutique principale = stock total − stock des autres boutiques. Utilisez « Transférer du stock » pour approvisionner une boutique, et « Prix par boutique » pour adapter les prix à chaque marché.'**
  String get shopInfo;

  /// No description provided for @shopTransferTitle.
  ///
  /// In fr, this message translates to:
  /// **'Transférer du stock'**
  String get shopTransferTitle;

  /// No description provided for @shopTransferSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer de la marchandise d\'une boutique à l\'autre'**
  String get shopTransferSubtitle;

  /// No description provided for @shopPricesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Prix par boutique'**
  String get shopPricesTitle;

  /// No description provided for @shopPricesSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Adapter les prix de vente au marché de chaque boutique'**
  String get shopPricesSubtitle;

  /// No description provided for @shopMainBadge.
  ///
  /// In fr, this message translates to:
  /// **'Principale'**
  String get shopMainBadge;

  /// No description provided for @shopDisabledBadge.
  ///
  /// In fr, this message translates to:
  /// **'Désactivée'**
  String get shopDisabledBadge;

  /// No description provided for @shopNoAddress.
  ///
  /// In fr, this message translates to:
  /// **'Aucune adresse'**
  String get shopNoAddress;

  /// No description provided for @shopDeactivate.
  ///
  /// In fr, this message translates to:
  /// **'Désactiver'**
  String get shopDeactivate;

  /// No description provided for @shopReactivate.
  ///
  /// In fr, this message translates to:
  /// **'Réactiver'**
  String get shopReactivate;

  /// No description provided for @teamTitle.
  ///
  /// In fr, this message translates to:
  /// **'Gestion de l\'équipe'**
  String get teamTitle;

  /// No description provided for @teamOwnerOnly.
  ///
  /// In fr, this message translates to:
  /// **'Accès réservé au propriétaire de la boutique.'**
  String get teamOwnerOnly;

  /// No description provided for @teamNoMembers.
  ///
  /// In fr, this message translates to:
  /// **'Aucun employé pour l\'instant.\nAppuyez sur « Nouveau membre » pour créer le compte d\'un caissier ou d\'un gérant.'**
  String get teamNoMembers;

  /// No description provided for @teamNewMember.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau membre'**
  String get teamNewMember;

  /// No description provided for @teamAccountCreated.
  ///
  /// In fr, this message translates to:
  /// **'Compte créé'**
  String get teamAccountCreated;

  /// No description provided for @teamGiveInfo.
  ///
  /// In fr, this message translates to:
  /// **'Donnez ces informations à {nom} :'**
  String teamGiveInfo(String nom);

  /// No description provided for @teamLogin.
  ///
  /// In fr, this message translates to:
  /// **'Identifiant'**
  String get teamLogin;

  /// No description provided for @teamPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get teamPassword;

  /// No description provided for @teamNoteNow.
  ///
  /// In fr, this message translates to:
  /// **'Notez-les maintenant : le mot de passe ne sera plus affiché.'**
  String get teamNoteNow;

  /// No description provided for @teamCopy.
  ///
  /// In fr, this message translates to:
  /// **'Copier'**
  String get teamCopy;

  /// No description provided for @teamCopied.
  ///
  /// In fr, this message translates to:
  /// **'Copié !'**
  String get teamCopied;

  /// No description provided for @teamFullName.
  ///
  /// In fr, this message translates to:
  /// **'Nom complet'**
  String get teamFullName;

  /// No description provided for @teamNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Nom obligatoire'**
  String get teamNameRequired;

  /// No description provided for @teamLoginLabel.
  ///
  /// In fr, this message translates to:
  /// **'Identifiant (ex : grace)'**
  String get teamLoginLabel;

  /// No description provided for @teamLoginPreview.
  ///
  /// In fr, this message translates to:
  /// **'Connexion : {login}'**
  String teamLoginPreview(String login);

  /// No description provided for @teamLoginMin.
  ///
  /// In fr, this message translates to:
  /// **'3 lettres ou chiffres minimum'**
  String get teamLoginMin;

  /// No description provided for @teamPasswordMin.
  ///
  /// In fr, this message translates to:
  /// **'6 caractères minimum'**
  String get teamPasswordMin;

  /// No description provided for @teamRole.
  ///
  /// In fr, this message translates to:
  /// **'Rôle'**
  String get teamRole;

  /// No description provided for @teamRoleLabel.
  ///
  /// In fr, this message translates to:
  /// **'Rôle :'**
  String get teamRoleLabel;

  /// No description provided for @roleOwner.
  ///
  /// In fr, this message translates to:
  /// **'Propriétaire'**
  String get roleOwner;

  /// No description provided for @roleManager.
  ///
  /// In fr, this message translates to:
  /// **'Gérant'**
  String get roleManager;

  /// No description provided for @roleCashier.
  ///
  /// In fr, this message translates to:
  /// **'Caissier'**
  String get roleCashier;

  /// No description provided for @teamManagerInfo.
  ///
  /// In fr, this message translates to:
  /// **'Un gérant a toutes les autorisations par défaut. Vous pourrez en retirer ensuite.'**
  String get teamManagerInfo;

  /// No description provided for @teamCashierInfo.
  ///
  /// In fr, this message translates to:
  /// **'Un caissier n\'a aucune autorisation spéciale par défaut. Vous pourrez en donner ensuite.'**
  String get teamCashierInfo;

  /// No description provided for @teamCreateAccount.
  ///
  /// In fr, this message translates to:
  /// **'Créer le compte'**
  String get teamCreateAccount;

  /// No description provided for @teamYou.
  ///
  /// In fr, this message translates to:
  /// **'{nom} (vous)'**
  String teamYou(String nom);

  /// No description provided for @teamOwnerAll.
  ///
  /// In fr, this message translates to:
  /// **'Le propriétaire a tous les droits.'**
  String get teamOwnerAll;

  /// No description provided for @teamRoleChanged.
  ///
  /// In fr, this message translates to:
  /// **'Rôle modifié'**
  String get teamRoleChanged;

  /// No description provided for @teamActive.
  ///
  /// In fr, this message translates to:
  /// **'Compte actif'**
  String get teamActive;

  /// No description provided for @teamCanLogin.
  ///
  /// In fr, this message translates to:
  /// **'Peut se connecter'**
  String get teamCanLogin;

  /// No description provided for @teamDisabledInfo.
  ///
  /// In fr, this message translates to:
  /// **'Désactivé : ne peut plus travailler'**
  String get teamDisabledInfo;

  /// No description provided for @teamReactivated.
  ///
  /// In fr, this message translates to:
  /// **'Compte réactivé'**
  String get teamReactivated;

  /// No description provided for @teamDeactivated.
  ///
  /// In fr, this message translates to:
  /// **'Compte désactivé'**
  String get teamDeactivated;

  /// No description provided for @teamPermissions.
  ///
  /// In fr, this message translates to:
  /// **'Autorisations ({count}/{total})'**
  String teamPermissions(int count, int total);

  /// No description provided for @teamManagerDefault.
  ///
  /// In fr, this message translates to:
  /// **'Par défaut pour un gérant : tout est autorisé'**
  String get teamManagerDefault;

  /// No description provided for @teamCashierDefault.
  ///
  /// In fr, this message translates to:
  /// **'Par défaut pour un caissier : rien de spécial'**
  String get teamCashierDefault;

  /// No description provided for @teamPermGranted.
  ///
  /// In fr, this message translates to:
  /// **'« {perm} » autorisé pour {nom}'**
  String teamPermGranted(String perm, String nom);

  /// No description provided for @teamPermRemoved.
  ///
  /// In fr, this message translates to:
  /// **'« {perm} » retiré à {nom}'**
  String teamPermRemoved(String perm, String nom);

  /// No description provided for @permFinances.
  ///
  /// In fr, this message translates to:
  /// **'Voir les finances'**
  String get permFinances;

  /// No description provided for @permFinancesDesc.
  ///
  /// In fr, this message translates to:
  /// **'P&L, comptabilité, prix d\'achat et marges.'**
  String get permFinancesDesc;

  /// No description provided for @permReturns.
  ///
  /// In fr, this message translates to:
  /// **'Retours et annulations'**
  String get permReturns;

  /// No description provided for @permReturnsDesc.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer un retour ou annuler une vente non retirée.'**
  String get permReturnsDesc;

  /// No description provided for @permStock.
  ///
  /// In fr, this message translates to:
  /// **'Gérer le stock'**
  String get permStock;

  /// No description provided for @permStockDesc.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter, modifier, supprimer des produits, importer un fichier.'**
  String get permStockDesc;

  /// No description provided for @permDiscounts.
  ///
  /// In fr, this message translates to:
  /// **'Remises et retraits'**
  String get permDiscounts;

  /// No description provided for @permDiscountsDesc.
  ///
  /// In fr, this message translates to:
  /// **'Changer les prix à la caisse et retirer de l\'argent d\'un compte client.'**
  String get permDiscountsDesc;

  /// No description provided for @permMaintenance.
  ///
  /// In fr, this message translates to:
  /// **'Maintenance des données'**
  String get permMaintenance;

  /// No description provided for @permMaintenanceDesc.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres : rattraper les coûts, fusionner les doublons.'**
  String get permMaintenanceDesc;

  /// No description provided for @histTitle.
  ///
  /// In fr, this message translates to:
  /// **'Historique des ventes'**
  String get histTitle;

  /// No description provided for @histSearch.
  ///
  /// In fr, this message translates to:
  /// **'Client, téléphone ou n° de facture…'**
  String get histSearch;

  /// No description provided for @histToday.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get histToday;

  /// No description provided for @hist7Days.
  ///
  /// In fr, this message translates to:
  /// **'7 jours'**
  String get hist7Days;

  /// No description provided for @hist30Days.
  ///
  /// In fr, this message translates to:
  /// **'30 jours'**
  String get hist30Days;

  /// No description provided for @histAllTime.
  ///
  /// In fr, this message translates to:
  /// **'Tout'**
  String get histAllTime;

  /// No description provided for @histLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de chargement : {message}'**
  String histLoadError(String message);

  /// No description provided for @histSalesOf.
  ///
  /// In fr, this message translates to:
  /// **'Ventes de {nom}'**
  String histSalesOf(String nom);

  /// No description provided for @histTotal.
  ///
  /// In fr, this message translates to:
  /// **'Total'**
  String get histTotal;

  /// No description provided for @histRemaining.
  ///
  /// In fr, this message translates to:
  /// **'Reste'**
  String get histRemaining;

  /// No description provided for @histNoResult.
  ///
  /// In fr, this message translates to:
  /// **'Aucune vente pour cette recherche.'**
  String get histNoResult;

  /// No description provided for @histPaid.
  ///
  /// In fr, this message translates to:
  /// **'Payé'**
  String get histPaid;

  /// No description provided for @histPartial.
  ///
  /// In fr, this message translates to:
  /// **'Partiel'**
  String get histPartial;

  /// No description provided for @histDebt.
  ///
  /// In fr, this message translates to:
  /// **'Dette'**
  String get histDebt;

  /// No description provided for @histCancelledSale.
  ///
  /// In fr, this message translates to:
  /// **'Annulée'**
  String get histCancelledSale;

  /// No description provided for @histToDeliver.
  ///
  /// In fr, this message translates to:
  /// **'À livrer'**
  String get histToDeliver;

  /// No description provided for @histDelivered.
  ///
  /// In fr, this message translates to:
  /// **'Livré'**
  String get histDelivered;

  /// No description provided for @histPartialCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annulation partielle'**
  String get histPartialCancel;

  /// No description provided for @histFullReturn.
  ///
  /// In fr, this message translates to:
  /// **'Retour total'**
  String get histFullReturn;

  /// No description provided for @histPartialReturn.
  ///
  /// In fr, this message translates to:
  /// **'Retour partiel'**
  String get histPartialReturn;

  /// No description provided for @histInvoice.
  ///
  /// In fr, this message translates to:
  /// **'Facture {numero}'**
  String histInvoice(String numero);

  /// No description provided for @histPrint.
  ///
  /// In fr, this message translates to:
  /// **'Imprimer'**
  String get histPrint;

  /// No description provided for @histShare.
  ///
  /// In fr, this message translates to:
  /// **'Partager (WhatsApp, e-mail…)'**
  String get histShare;

  /// No description provided for @histInvoiceError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de créer la facture : {message}'**
  String histInvoiceError(String message);

  /// No description provided for @histDeliveredOn.
  ///
  /// In fr, this message translates to:
  /// **'Livré le {date}'**
  String histDeliveredOn(String date);

  /// No description provided for @histItems.
  ///
  /// In fr, this message translates to:
  /// **'Articles'**
  String get histItems;

  /// No description provided for @histReturnedQty.
  ///
  /// In fr, this message translates to:
  /// **'↩ {count} retourné(s)'**
  String histReturnedQty(int count);

  /// No description provided for @histCancelledQty.
  ///
  /// In fr, this message translates to:
  /// **'✕ {count} annulé(s)'**
  String histCancelledQty(int count);

  /// No description provided for @histReturned.
  ///
  /// In fr, this message translates to:
  /// **'Retourné'**
  String get histReturned;

  /// No description provided for @histCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Annulé'**
  String get histCancelled;

  /// No description provided for @histNetTotal.
  ///
  /// In fr, this message translates to:
  /// **'Total net'**
  String get histNetTotal;

  /// No description provided for @histToPay.
  ///
  /// In fr, this message translates to:
  /// **'Reste à payer'**
  String get histToPay;

  /// No description provided for @histMethod.
  ///
  /// In fr, this message translates to:
  /// **'Moyen'**
  String get histMethod;

  /// No description provided for @histSoldBy.
  ///
  /// In fr, this message translates to:
  /// **'Vendu par'**
  String get histSoldBy;

  /// No description provided for @histDeliveredBy.
  ///
  /// In fr, this message translates to:
  /// **'Livré par'**
  String get histDeliveredBy;

  /// No description provided for @histPdfButton.
  ///
  /// In fr, this message translates to:
  /// **'Facture PDF (imprimer / WhatsApp)'**
  String get histPdfButton;

  /// No description provided for @histDeliveryNote.
  ///
  /// In fr, this message translates to:
  /// **'Bon de livraison'**
  String get histDeliveryNote;

  /// No description provided for @histReturnGoods.
  ///
  /// In fr, this message translates to:
  /// **'Retour de marchandise'**
  String get histReturnGoods;

  /// No description provided for @histCancelSale.
  ///
  /// In fr, this message translates to:
  /// **'Annuler la vente (non retirée)'**
  String get histCancelSale;

  /// No description provided for @histArticles.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 article} other{{count} articles}}'**
  String histArticles(int count);

  /// No description provided for @histBy.
  ///
  /// In fr, this message translates to:
  /// **'par {nom}'**
  String histBy(String nom);

  /// No description provided for @histWalkIn.
  ///
  /// In fr, this message translates to:
  /// **'Client divers'**
  String get histWalkIn;

  /// No description provided for @ddMotif.
  ///
  /// In fr, this message translates to:
  /// **'Motif'**
  String get ddMotif;

  /// No description provided for @ddNoItems.
  ///
  /// In fr, this message translates to:
  /// **'Aucun article : dette ajoutée à la main.'**
  String get ddNoItems;

  /// No description provided for @ddItemsError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les articles.'**
  String get ddItemsError;

  /// No description provided for @ddCall.
  ///
  /// In fr, this message translates to:
  /// **'Appeler'**
  String get ddCall;

  /// No description provided for @ddPdf.
  ///
  /// In fr, this message translates to:
  /// **'Facture PDF'**
  String get ddPdf;

  /// No description provided for @ddDetails.
  ///
  /// In fr, this message translates to:
  /// **'Détails'**
  String get ddDetails;

  /// No description provided for @ddDiscount.
  ///
  /// In fr, this message translates to:
  /// **'Remise accordée : {montant}'**
  String ddDiscount(String montant);

  /// No description provided for @ddDate.
  ///
  /// In fr, this message translates to:
  /// **'Date : {date}'**
  String ddDate(String date);

  /// No description provided for @ddPayments.
  ///
  /// In fr, this message translates to:
  /// **'Historique des paiements'**
  String get ddPayments;

  /// No description provided for @ddPaidBefore.
  ///
  /// In fr, this message translates to:
  /// **'Payé avant (à la vente ou plus tôt)'**
  String get ddPaidBefore;

  /// No description provided for @ddNoPayments.
  ///
  /// In fr, this message translates to:
  /// **'Aucun paiement pour l\'instant.'**
  String get ddNoPayments;

  /// No description provided for @payMotif.
  ///
  /// In fr, this message translates to:
  /// **'Motif du crédit (facultatif)'**
  String get payMotif;

  /// No description provided for @payMotifHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex : paiera vendredi après le marché'**
  String get payMotifHint;

  /// No description provided for @accDebtsCollected.
  ///
  /// In fr, this message translates to:
  /// **'Dettes encaissées : {montant}'**
  String accDebtsCollected(String montant);

  /// No description provided for @accDebtsCollectedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Dettes encaissées aujourd\'hui ({count})'**
  String accDebtsCollectedTitle(int count);

  /// No description provided for @repChoiceTitle.
  ///
  /// In fr, this message translates to:
  /// **'Quel résumé envoyer ?'**
  String get repChoiceTitle;

  /// No description provided for @repShort.
  ///
  /// In fr, this message translates to:
  /// **'Résumé court'**
  String get repShort;

  /// No description provided for @repShortHint.
  ///
  /// In fr, this message translates to:
  /// **'Les totaux du jour'**
  String get repShortHint;

  /// No description provided for @repDetailed.
  ///
  /// In fr, this message translates to:
  /// **'Rapport détaillé'**
  String get repDetailed;

  /// No description provided for @repDetailedHint.
  ///
  /// In fr, this message translates to:
  /// **'Chaque vente, produits, vendeurs, dépenses, dettes, stock'**
  String get repDetailedHint;

  /// No description provided for @repSales.
  ///
  /// In fr, this message translates to:
  /// **'🛒 VENTES ({count}) : {montant}'**
  String repSales(int count, String montant);

  /// No description provided for @repProducts.
  ///
  /// In fr, this message translates to:
  /// **'📦 PRODUITS VENDUS'**
  String get repProducts;

  /// No description provided for @repBySeller.
  ///
  /// In fr, this message translates to:
  /// **'👤 PAR VENDEUR'**
  String get repBySeller;

  /// No description provided for @repByMethod.
  ///
  /// In fr, this message translates to:
  /// **'💳 PAR MOYEN DE PAIEMENT'**
  String get repByMethod;

  /// No description provided for @repExpenses.
  ///
  /// In fr, this message translates to:
  /// **'💸 DÉPENSES ({montant})'**
  String repExpenses(String montant);

  /// No description provided for @repDebtsCollected.
  ///
  /// In fr, this message translates to:
  /// **'💰 DETTES ENCAISSÉES ({montant})'**
  String repDebtsCollected(String montant);

  /// No description provided for @repNewCredits.
  ///
  /// In fr, this message translates to:
  /// **'📝 NOUVEAUX CRÉDITS ({montant})'**
  String repNewCredits(String montant);

  /// No description provided for @repToReorder.
  ///
  /// In fr, this message translates to:
  /// **'⚠️ À RECOMMANDER'**
  String get repToReorder;

  /// No description provided for @repCredit.
  ///
  /// In fr, this message translates to:
  /// **'crédit {montant}'**
  String repCredit(String montant);

  /// No description provided for @repMore.
  ///
  /// In fr, this message translates to:
  /// **'…et {count} autre(s)'**
  String repMore(int count);

  /// No description provided for @retCancelTitle.
  ///
  /// In fr, this message translates to:
  /// **'Annuler la vente'**
  String get retCancelTitle;

  /// No description provided for @retNoCancelRight.
  ///
  /// In fr, this message translates to:
  /// **'Seuls le gérant et le patron peuvent annuler une vente.'**
  String get retNoCancelRight;

  /// No description provided for @retNoReturnRight.
  ///
  /// In fr, this message translates to:
  /// **'Seuls le gérant et le patron peuvent enregistrer un retour.'**
  String get retNoReturnRight;

  /// No description provided for @retTooLate.
  ///
  /// In fr, this message translates to:
  /// **'Délai de retour dépassé : vente du {date} (il y a {jours} jours, limite {limite} jours).\n\nSeul le patron peut accepter ce retour.'**
  String retTooLate(String date, int jours, int limite);

  /// No description provided for @retNothingToCancel.
  ///
  /// In fr, this message translates to:
  /// **'Rien à annuler sur cette vente.\n\nToute la marchandise a déjà été remise au client ou déjà annulée. S\'il la rapporte, utilisez « Retour de marchandise ».'**
  String get retNothingToCancel;

  /// No description provided for @retNothingToReturn.
  ///
  /// In fr, this message translates to:
  /// **'Rien à retourner sur cette vente.\n\nSoit tout a déjà été retourné, soit la marchandise n\'a pas encore été remise au client (dans ce cas, utilisez « Annuler la vente »).'**
  String get retNothingToReturn;

  /// No description provided for @retModeAvoirHint.
  ///
  /// In fr, this message translates to:
  /// **'Le montant est ajouté au compte client : il pourra l\'utiliser en Caisse.'**
  String get retModeAvoirHint;

  /// No description provided for @retModeKeepHint.
  ///
  /// In fr, this message translates to:
  /// **'La boutique garde l\'argent (acompte non remboursé).'**
  String get retModeKeepHint;

  /// No description provided for @retModeCashHint.
  ///
  /// In fr, this message translates to:
  /// **'L\'argent sort de la caisse.'**
  String get retModeCashHint;

  /// No description provided for @retSaleOf.
  ///
  /// In fr, this message translates to:
  /// **'Vente du {date} • {age}'**
  String retSaleOf(String date, String age);

  /// No description provided for @retInvoiceAmount.
  ///
  /// In fr, this message translates to:
  /// **'Facture : {montant}'**
  String retInvoiceAmount(String montant);

  /// No description provided for @retStillOwes.
  ///
  /// In fr, this message translates to:
  /// **'Le client doit encore : {montant}'**
  String retStillOwes(String montant);

  /// No description provided for @retCancelInfo.
  ///
  /// In fr, this message translates to:
  /// **'Marchandise jamais retirée par le client : elle revient en stock et la vente est annulée pour ces articles.'**
  String get retCancelInfo;

  /// No description provided for @retLateAccepted.
  ///
  /// In fr, this message translates to:
  /// **'Hors délai ({jours} jours) : retour accepté exceptionnellement par le patron.'**
  String retLateAccepted(int jours);

  /// No description provided for @retItemsToCancel.
  ///
  /// In fr, this message translates to:
  /// **'Articles à annuler'**
  String get retItemsToCancel;

  /// No description provided for @retItemsReturned.
  ///
  /// In fr, this message translates to:
  /// **'Articles rapportés'**
  String get retItemsReturned;

  /// No description provided for @retPrice.
  ///
  /// In fr, this message translates to:
  /// **'Prix : {montant}'**
  String retPrice(String montant);

  /// No description provided for @retNotPicked.
  ///
  /// In fr, this message translates to:
  /// **'non retiré : {count}'**
  String retNotPicked(int count);

  /// No description provided for @retReturnable.
  ///
  /// In fr, this message translates to:
  /// **'retournable : {count}'**
  String retReturnable(int count);

  /// No description provided for @retAlreadyReturned.
  ///
  /// In fr, this message translates to:
  /// **'déjà retourné : {count}'**
  String retAlreadyReturned(int count);

  /// No description provided for @retResell.
  ///
  /// In fr, this message translates to:
  /// **'Remettre en vente'**
  String get retResell;

  /// No description provided for @retDamaged.
  ///
  /// In fr, this message translates to:
  /// **'Abîmé (perte)'**
  String get retDamaged;

  /// No description provided for @retCancelAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout annuler'**
  String get retCancelAll;

  /// No description provided for @retCancelReason.
  ///
  /// In fr, this message translates to:
  /// **'Motif de l\'annulation *'**
  String get retCancelReason;

  /// No description provided for @retReturnReason.
  ///
  /// In fr, this message translates to:
  /// **'Motif du retour *'**
  String get retReturnReason;

  /// No description provided for @retCancelHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex : client jamais venu, délai dépassé…'**
  String get retCancelHint;

  /// No description provided for @retReturnHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex : mauvaise taille, défaut de fabrication…'**
  String get retReturnHint;

  /// No description provided for @retCancelledAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant annulé : {montant}'**
  String retCancelledAmount(String montant);

  /// No description provided for @retReturnAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant du retour : {montant}'**
  String retReturnAmount(String montant);

  /// No description provided for @retDeducted.
  ///
  /// In fr, this message translates to:
  /// **'Déduit de la dette du client : {montant}'**
  String retDeducted(String montant);

  /// No description provided for @retAlreadyPaid.
  ///
  /// In fr, this message translates to:
  /// **'Déjà payé par le client : {montant}'**
  String retAlreadyPaid(String montant);

  /// No description provided for @retToGiveBack.
  ///
  /// In fr, this message translates to:
  /// **'À rendre au client : {montant}'**
  String retToGiveBack(String montant);

  /// No description provided for @retCash.
  ///
  /// In fr, this message translates to:
  /// **'Espèces'**
  String get retCash;

  /// No description provided for @retCredit.
  ///
  /// In fr, this message translates to:
  /// **'Avoir'**
  String get retCredit;

  /// No description provided for @retKeep.
  ///
  /// In fr, this message translates to:
  /// **'Garder'**
  String get retKeep;

  /// No description provided for @retPhoneLabel.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone du compte client *'**
  String get retPhoneLabel;

  /// No description provided for @retPhoneError.
  ///
  /// In fr, this message translates to:
  /// **'Un avoir a besoin du téléphone du client'**
  String get retPhoneError;

  /// No description provided for @retChooseItems.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez les articles'**
  String get retChooseItems;

  /// No description provided for @retValidateCancel.
  ///
  /// In fr, this message translates to:
  /// **'Valider l\'annulation ({montant})'**
  String retValidateCancel(String montant);

  /// No description provided for @retValidateReturn.
  ///
  /// In fr, this message translates to:
  /// **'Valider le retour ({montant})'**
  String retValidateReturn(String montant);

  /// No description provided for @retNeedReason.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez le motif pour valider.'**
  String get retNeedReason;

  /// No description provided for @retConfirmCancel.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer l\'annulation'**
  String get retConfirmCancel;

  /// No description provided for @retConfirmReturn.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le retour'**
  String get retConfirmReturn;

  /// No description provided for @retDamagedShort.
  ///
  /// In fr, this message translates to:
  /// **'abîmé'**
  String get retDamagedShort;

  /// No description provided for @retAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant : {montant}'**
  String retAmount(String montant);

  /// No description provided for @retDamagedCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} pièce(s) abîmée(s) : ne reviennent pas en stock.'**
  String retDamagedCount(int count);

  /// No description provided for @retCreditTo.
  ///
  /// In fr, this message translates to:
  /// **'Avoir de {montant} versé sur le compte {tel}.'**
  String retCreditTo(String montant, String tel);

  /// No description provided for @retIrreversible.
  ///
  /// In fr, this message translates to:
  /// **'Cette opération ne peut pas être annulée.'**
  String get retIrreversible;

  /// No description provided for @retBack.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get retBack;

  /// No description provided for @retValidate.
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get retValidate;

  /// No description provided for @retCancelSaved.
  ///
  /// In fr, this message translates to:
  /// **'Annulation enregistrée.'**
  String get retCancelSaved;

  /// No description provided for @retReturnSaved.
  ///
  /// In fr, this message translates to:
  /// **'Retour enregistré.'**
  String get retReturnSaved;

  /// No description provided for @retGiveCash.
  ///
  /// In fr, this message translates to:
  /// **'Rendez {montant} au client en espèces.'**
  String retGiveCash(String montant);

  /// No description provided for @retCreditAdded.
  ///
  /// In fr, this message translates to:
  /// **'Avoir de {montant} ajouté au compte client (nouveau solde : {solde}).'**
  String retCreditAdded(String montant, String solde);

  /// No description provided for @retDepositKept.
  ///
  /// In fr, this message translates to:
  /// **'Acompte de {montant} conservé par la boutique.'**
  String retDepositKept(String montant);

  /// No description provided for @retDebtReduced.
  ///
  /// In fr, this message translates to:
  /// **'Dette du client diminuée de {montant}.'**
  String retDebtReduced(String montant);

  /// No description provided for @retOffline.
  ///
  /// In fr, this message translates to:
  /// **'(envoi dès le retour d\'internet)'**
  String get retOffline;

  /// No description provided for @caisseNoShopProducts.
  ///
  /// In fr, this message translates to:
  /// **'Aucun produit en stock dans cette boutique.\nAjoutez du stock (achat ou transfert depuis la boutique principale).'**
  String get caisseNoShopProducts;

  /// No description provided for @stockShowOut.
  ///
  /// In fr, this message translates to:
  /// **'Voir les épuisés ({count})'**
  String stockShowOut(int count);

  /// No description provided for @stockShowInStock.
  ///
  /// In fr, this message translates to:
  /// **'Retour aux produits en stock'**
  String get stockShowInStock;

  /// No description provided for @livTitle.
  ///
  /// In fr, this message translates to:
  /// **'À livrer'**
  String get livTitle;

  /// No description provided for @livButtonLate.
  ///
  /// In fr, this message translates to:
  /// **'À livrer ({count} en retard)'**
  String livButtonLate(int count);

  /// No description provided for @livNoneTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune livraison en attente'**
  String get livNoneTitle;

  /// No description provided for @livNoneSub.
  ///
  /// In fr, this message translates to:
  /// **'Tous les clients ont reçu leur marchandise.'**
  String get livNoneSub;

  /// No description provided for @livWaitingLate.
  ///
  /// In fr, this message translates to:
  /// **'{count} client(s) en attente — dont {late} en retard'**
  String livWaitingLate(int count, int late);

  /// No description provided for @livWaiting.
  ///
  /// In fr, this message translates to:
  /// **'{count} client(s) attendent leur marchandise'**
  String livWaiting(int count);

  /// No description provided for @livNoWhatsapp.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'ouvrir WhatsApp.'**
  String get livNoWhatsapp;

  /// No description provided for @livHandOverTitle.
  ///
  /// In fr, this message translates to:
  /// **'Remettre la marchandise'**
  String get livHandOverTitle;

  /// No description provided for @livClient.
  ///
  /// In fr, this message translates to:
  /// **'Client : {nom}'**
  String livClient(String nom);

  /// No description provided for @livWhatNow.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez ce que le client emporte maintenant :'**
  String get livWhatNow;

  /// No description provided for @livAllGiven.
  ///
  /// In fr, this message translates to:
  /// **'Tout a déjà été remis.'**
  String get livAllGiven;

  /// No description provided for @livRemainDone.
  ///
  /// In fr, this message translates to:
  /// **'Reste {reste} (déjà remis : {deja})'**
  String livRemainDone(int reste, int deja);

  /// No description provided for @livToHand.
  ///
  /// In fr, this message translates to:
  /// **'À remettre : {count}'**
  String livToHand(int count);

  /// No description provided for @livChooseOne.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez au moins une pièce à remettre.'**
  String get livChooseOne;

  /// No description provided for @livPartialAfter.
  ///
  /// In fr, this message translates to:
  /// **'Sortie partielle : il restera {count} pièce(s) à retirer.'**
  String livPartialAfter(int count);

  /// No description provided for @livComplete.
  ///
  /// In fr, this message translates to:
  /// **'Livraison complète : tout est remis.'**
  String get livComplete;

  /// No description provided for @livWarnUnpaid.
  ///
  /// In fr, this message translates to:
  /// **'Attention : il reste {montant} à payer.'**
  String livWarnUnpaid(String montant);

  /// No description provided for @livValidateExit.
  ///
  /// In fr, this message translates to:
  /// **'Valider la sortie'**
  String get livValidateExit;

  /// No description provided for @livAllDelivered.
  ///
  /// In fr, this message translates to:
  /// **'Oui, tout livré'**
  String get livAllDelivered;

  /// No description provided for @livSavedOffline.
  ///
  /// In fr, this message translates to:
  /// **'Sortie notée sur le téléphone. Envoi dès le retour d\'internet.'**
  String get livSavedOffline;

  /// No description provided for @livCompleteSaved.
  ///
  /// In fr, this message translates to:
  /// **'Livraison complète enregistrée pour {client}.'**
  String livCompleteSaved(String client);

  /// No description provided for @livPartialSaved.
  ///
  /// In fr, this message translates to:
  /// **'Sortie partielle enregistrée : il reste {count} pièce(s) à retirer.'**
  String livPartialSaved(int count);

  /// No description provided for @livLatePassed.
  ///
  /// In fr, this message translates to:
  /// **'Délai dépassé (limite : {date})'**
  String livLatePassed(String date);

  /// No description provided for @livLateDays.
  ///
  /// In fr, this message translates to:
  /// **'Délai dépassé de {jours} jour(s) (limite : {date})'**
  String livLateDays(int jours, String date);

  /// No description provided for @livPickToday.
  ///
  /// In fr, this message translates to:
  /// **'À retirer aujourd\'hui (limite : {date})'**
  String livPickToday(String date);

  /// No description provided for @livPickTomorrow.
  ///
  /// In fr, this message translates to:
  /// **'À retirer avant demain soir ({date})'**
  String livPickTomorrow(String date);

  /// No description provided for @livPickBefore.
  ///
  /// In fr, this message translates to:
  /// **'À retirer avant le {date} ({jours} jours restants)'**
  String livPickBefore(String date, int jours);

  /// No description provided for @livCall.
  ///
  /// In fr, this message translates to:
  /// **'Appeler {tel}'**
  String livCall(String tel);

  /// No description provided for @livPartial.
  ///
  /// In fr, this message translates to:
  /// **'Partiellement livré'**
  String get livPartial;

  /// No description provided for @livSoldOn.
  ///
  /// In fr, this message translates to:
  /// **'Vendu le {date}'**
  String livSoldOn(String date);

  /// No description provided for @livSoldOnBy.
  ///
  /// In fr, this message translates to:
  /// **'Vendu le {date} par {vendeur}'**
  String livSoldOnBy(String date, String vendeur);

  /// No description provided for @livStillToHand.
  ///
  /// In fr, this message translates to:
  /// **'Reste à remettre :'**
  String get livStillToHand;

  /// No description provided for @livToHandColon.
  ///
  /// In fr, this message translates to:
  /// **'À remettre :'**
  String get livToHandColon;

  /// No description provided for @livNothingToHand.
  ///
  /// In fr, this message translates to:
  /// **'rien à remettre'**
  String get livNothingToHand;

  /// No description provided for @livOutOf.
  ///
  /// In fr, this message translates to:
  /// **'(sur {count})'**
  String livOutOf(String count);

  /// No description provided for @livHanded.
  ///
  /// In fr, this message translates to:
  /// **'remis : {count}'**
  String livHanded(int count);

  /// No description provided for @livCancelled.
  ///
  /// In fr, this message translates to:
  /// **'{count} annulé(s)'**
  String livCancelled(int count);

  /// No description provided for @livAlreadyOut.
  ///
  /// In fr, this message translates to:
  /// **'Déjà sorti :'**
  String get livAlreadyOut;

  /// No description provided for @livUnpaid.
  ///
  /// In fr, this message translates to:
  /// **'Reste à payer : {montant} — à encaisser avant de livrer'**
  String livUnpaid(String montant);

  /// No description provided for @livRemind.
  ///
  /// In fr, this message translates to:
  /// **'Relancer'**
  String get livRemind;

  /// No description provided for @livMarkDelivered.
  ///
  /// In fr, this message translates to:
  /// **'Marquer comme livré'**
  String get livMarkDelivered;

  /// No description provided for @livBy.
  ///
  /// In fr, this message translates to:
  /// **'(par {nom})'**
  String livBy(String nom);

  /// No description provided for @ccDepositTitle.
  ///
  /// In fr, this message translates to:
  /// **'Dépôt du client'**
  String get ccDepositTitle;

  /// No description provided for @ccWithdrawTitle.
  ///
  /// In fr, this message translates to:
  /// **'Retrait du client'**
  String get ccWithdrawTitle;

  /// No description provided for @ccPhoneLabel.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone du client *'**
  String get ccPhoneLabel;

  /// No description provided for @ccPhoneShort.
  ///
  /// In fr, this message translates to:
  /// **'Numéro trop court'**
  String get ccPhoneShort;

  /// No description provided for @ccNameLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nom du client'**
  String get ccNameLabel;

  /// No description provided for @ccAmountLabel.
  ///
  /// In fr, this message translates to:
  /// **'Montant (USD) *'**
  String get ccAmountLabel;

  /// No description provided for @ccMoreThanBalance.
  ///
  /// In fr, this message translates to:
  /// **'Plus que le solde disponible'**
  String get ccMoreThanBalance;

  /// No description provided for @ccAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Solde disponible : {montant}'**
  String ccAvailable(String montant);

  /// No description provided for @ccCash.
  ///
  /// In fr, this message translates to:
  /// **'Espèces'**
  String get ccCash;

  /// No description provided for @ccSaveDeposit.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer le dépôt'**
  String get ccSaveDeposit;

  /// No description provided for @ccSaveWithdraw.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer le retrait'**
  String get ccSaveWithdraw;

  /// No description provided for @ccDepositSaved.
  ///
  /// In fr, this message translates to:
  /// **'Dépôt de {montant} enregistré.'**
  String ccDepositSaved(String montant);

  /// No description provided for @ccWithdrawSaved.
  ///
  /// In fr, this message translates to:
  /// **'Retrait de {montant} enregistré.'**
  String ccWithdrawSaved(String montant);

  /// No description provided for @ccNewDeposit.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau dépôt'**
  String get ccNewDeposit;

  /// No description provided for @ccSearchHint.
  ///
  /// In fr, this message translates to:
  /// **'Nom ou téléphone…'**
  String get ccSearchHint;

  /// No description provided for @ccCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} client(s) avec un compte'**
  String ccCount(int count);

  /// No description provided for @ccTotalKept.
  ///
  /// In fr, this message translates to:
  /// **'Argent des clients gardé : {montant}'**
  String ccTotalKept(String montant);

  /// No description provided for @ccNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucun compte client.\nAppuyez sur « Nouveau dépôt » pour en créer un.'**
  String get ccNone;

  /// No description provided for @ccAccountTitle.
  ///
  /// In fr, this message translates to:
  /// **'Compte client'**
  String get ccAccountTitle;

  /// No description provided for @ccAvailableLabel.
  ///
  /// In fr, this message translates to:
  /// **'Solde disponible'**
  String get ccAvailableLabel;

  /// No description provided for @ccDeposit.
  ///
  /// In fr, this message translates to:
  /// **'Dépôt'**
  String get ccDeposit;

  /// No description provided for @ccWithdraw.
  ///
  /// In fr, this message translates to:
  /// **'Retrait'**
  String get ccWithdraw;

  /// No description provided for @ccSendStatement.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer le relevé par WhatsApp'**
  String get ccSendStatement;

  /// No description provided for @ccHistory.
  ///
  /// In fr, this message translates to:
  /// **'Historique'**
  String get ccHistory;

  /// No description provided for @ccNoMovement.
  ///
  /// In fr, this message translates to:
  /// **'Aucun mouvement.'**
  String get ccNoMovement;

  /// No description provided for @ccDateBy.
  ///
  /// In fr, this message translates to:
  /// **'{date} • par {nom}'**
  String ccDateBy(String date, String nom);

  /// No description provided for @ccBalanceAfter.
  ///
  /// In fr, this message translates to:
  /// **'Solde : {montant}'**
  String ccBalanceAfter(String montant);

  /// No description provided for @depSearchHint.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher une dépense...'**
  String get depSearchHint;

  /// No description provided for @depTitle.
  ///
  /// In fr, this message translates to:
  /// **'Charges & Dépenses'**
  String get depTitle;

  /// No description provided for @depTabAll.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les Charges'**
  String get depTabAll;

  /// No description provided for @depTabByCat.
  ///
  /// In fr, this message translates to:
  /// **'Par Catégorie'**
  String get depTabByCat;

  /// No description provided for @depExport.
  ///
  /// In fr, this message translates to:
  /// **'Exporter'**
  String get depExport;

  /// No description provided for @depColDate.
  ///
  /// In fr, this message translates to:
  /// **'Date'**
  String get depColDate;

  /// No description provided for @depColTitle.
  ///
  /// In fr, this message translates to:
  /// **'Titre / Motif'**
  String get depColTitle;

  /// No description provided for @depColCategory.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie'**
  String get depColCategory;

  /// No description provided for @depColAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant'**
  String get depColAmount;

  /// No description provided for @depColAuthor.
  ///
  /// In fr, this message translates to:
  /// **'Auteur'**
  String get depColAuthor;

  /// No description provided for @depColNote.
  ///
  /// In fr, this message translates to:
  /// **'Note'**
  String get depColNote;

  /// No description provided for @depReportTitle.
  ///
  /// In fr, this message translates to:
  /// **'Rapport des Charges et Dépenses'**
  String get depReportTitle;

  /// No description provided for @depToExcel.
  ///
  /// In fr, this message translates to:
  /// **'Exporter vers Excel'**
  String get depToExcel;

  /// No description provided for @depPrintPdf.
  ///
  /// In fr, this message translates to:
  /// **'Imprimer / PDF'**
  String get depPrintPdf;

  /// No description provided for @depTotalAll.
  ///
  /// In fr, this message translates to:
  /// **'Total Général des Dépenses'**
  String get depTotalAll;

  /// No description provided for @depTotalFor.
  ///
  /// In fr, this message translates to:
  /// **'Total pour : {categorie}'**
  String depTotalFor(String categorie);

  /// No description provided for @depNoResult.
  ///
  /// In fr, this message translates to:
  /// **'Aucun résultat pour « {recherche} »'**
  String depNoResult(String recherche);

  /// No description provided for @depNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucune dépense enregistrée.'**
  String get depNone;

  /// No description provided for @depNote.
  ///
  /// In fr, this message translates to:
  /// **'Note : {note}'**
  String depNote(String note);

  /// No description provided for @depEdit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get depEdit;

  /// No description provided for @depDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get depDelete;

  /// No description provided for @depAdd.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une dépense'**
  String get depAdd;

  /// No description provided for @depDeleteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la dépense'**
  String get depDeleteTitle;

  /// No description provided for @depDeleteConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir supprimer cette ligne de charge ?'**
  String get depDeleteConfirm;

  /// No description provided for @depInvalidAmount.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez saisir un montant valide (> 0)'**
  String get depInvalidAmount;

  /// No description provided for @depEdited.
  ///
  /// In fr, this message translates to:
  /// **'Dépense modifiée !'**
  String get depEdited;

  /// No description provided for @depSaved.
  ///
  /// In fr, this message translates to:
  /// **'Dépense enregistrée !'**
  String get depSaved;

  /// No description provided for @depSaveError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de l\'enregistrement : {erreur}'**
  String depSaveError(String erreur);

  /// No description provided for @depFormEdit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la dépense'**
  String get depFormEdit;

  /// No description provided for @depFormNew.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer une Dépense'**
  String get depFormNew;

  /// No description provided for @depReasonRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le motif est requis'**
  String get depReasonRequired;

  /// No description provided for @depReasonLabel.
  ///
  /// In fr, this message translates to:
  /// **'Motif / Titre'**
  String get depReasonLabel;

  /// No description provided for @depReasonHint.
  ///
  /// In fr, this message translates to:
  /// **'ex: Loyer, Électricité...'**
  String get depReasonHint;

  /// No description provided for @depAmountRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le montant est requis'**
  String get depAmountRequired;

  /// No description provided for @depAmountInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Montant invalide'**
  String get depAmountInvalid;

  /// No description provided for @depCategoryLabel.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie de Charge'**
  String get depCategoryLabel;

  /// No description provided for @depDate.
  ///
  /// In fr, this message translates to:
  /// **'Date : {date}'**
  String depDate(String date);

  /// No description provided for @depNoteLabel.
  ///
  /// In fr, this message translates to:
  /// **'Note / Commentaire (Optionnel)'**
  String get depNoteLabel;

  /// No description provided for @depSaveChanges.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer les modifications'**
  String get depSaveChanges;

  /// No description provided for @depSaveExpense.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer la dépense'**
  String get depSaveExpense;

  /// No description provided for @depCatAll.
  ///
  /// In fr, this message translates to:
  /// **'Toutes'**
  String get depCatAll;

  /// No description provided for @depCatRent.
  ///
  /// In fr, this message translates to:
  /// **'Loyer'**
  String get depCatRent;

  /// No description provided for @depCatSalaries.
  ///
  /// In fr, this message translates to:
  /// **'Salaires'**
  String get depCatSalaries;

  /// No description provided for @depCatUtilities.
  ///
  /// In fr, this message translates to:
  /// **'Électricité & Eau'**
  String get depCatUtilities;

  /// No description provided for @depCatTransport.
  ///
  /// In fr, this message translates to:
  /// **'Transport / Carburant'**
  String get depCatTransport;

  /// No description provided for @depCatTaxes.
  ///
  /// In fr, this message translates to:
  /// **'Taxes & Impôts'**
  String get depCatTaxes;

  /// No description provided for @depCatMaintenance.
  ///
  /// In fr, this message translates to:
  /// **'Maintenance / Réparation'**
  String get depCatMaintenance;

  /// No description provided for @depCatMarketing.
  ///
  /// In fr, this message translates to:
  /// **'Marketing / Pub'**
  String get depCatMarketing;

  /// No description provided for @depCatOther.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get depCatOther;

  /// No description provided for @blTraceTitle.
  ///
  /// In fr, this message translates to:
  /// **'Traçabilité requise'**
  String get blTraceTitle;

  /// No description provided for @blTraceMsg.
  ///
  /// In fr, this message translates to:
  /// **'Ce bon de livraison s\'élève à {montant} USD (au-dessus du seuil de {seuil} USD).\n\nPour des raisons de sécurité financière et de suivi, un nom de client valide et un numéro de téléphone sont obligatoires.'**
  String blTraceMsg(String montant, String seuil);

  /// No description provided for @blTitle.
  ///
  /// In fr, this message translates to:
  /// **'Bon de livraison'**
  String get blTitle;

  /// No description provided for @blPrint.
  ///
  /// In fr, this message translates to:
  /// **'Imprimer'**
  String get blPrint;

  /// No description provided for @blShare.
  ///
  /// In fr, this message translates to:
  /// **'Partager (WhatsApp, e-mail…)'**
  String get blShare;

  /// No description provided for @blPdfError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de créer le PDF : {erreur}'**
  String blPdfError(String erreur);

  /// No description provided for @blPrintShare.
  ///
  /// In fr, this message translates to:
  /// **'Imprimer / Partager'**
  String get blPrintShare;

  /// No description provided for @blMyShop.
  ///
  /// In fr, this message translates to:
  /// **'Ma Boutique'**
  String get blMyShop;

  /// No description provided for @blPhoneShort.
  ///
  /// In fr, this message translates to:
  /// **'Tél : {tel}'**
  String blPhoneShort(String tel);

  /// No description provided for @blDeliveredTo.
  ///
  /// In fr, this message translates to:
  /// **'CLIENT LIVRÉ :'**
  String get blDeliveredTo;

  /// No description provided for @blCounterClient.
  ///
  /// In fr, this message translates to:
  /// **'Client Comptoir'**
  String get blCounterClient;

  /// No description provided for @blAddress.
  ///
  /// In fr, this message translates to:
  /// **'Adresse : {adresse}'**
  String blAddress(String adresse);

  /// No description provided for @blNotSpecified.
  ///
  /// In fr, this message translates to:
  /// **'Non spécifiée'**
  String get blNotSpecified;

  /// No description provided for @blPhone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone : {tel}'**
  String blPhone(String tel);

  /// No description provided for @blColItem.
  ///
  /// In fr, this message translates to:
  /// **'Désignation'**
  String get blColItem;

  /// No description provided for @blColQty.
  ///
  /// In fr, this message translates to:
  /// **'Qté'**
  String get blColQty;

  /// No description provided for @blColUnit.
  ///
  /// In fr, this message translates to:
  /// **'P.U.'**
  String get blColUnit;

  /// No description provided for @blColTotal.
  ///
  /// In fr, this message translates to:
  /// **'Total'**
  String get blColTotal;

  /// No description provided for @blGrandTotal.
  ///
  /// In fr, this message translates to:
  /// **'TOTAL GÉNÉRAL : '**
  String get blGrandTotal;

  /// No description provided for @blDeliverer.
  ///
  /// In fr, this message translates to:
  /// **'Le Livreur / Expéditeur'**
  String get blDeliverer;

  /// No description provided for @blCustomerSign.
  ///
  /// In fr, this message translates to:
  /// **'Le Client (Bon accord)'**
  String get blCustomerSign;

  /// No description provided for @panRateTitle.
  ///
  /// In fr, this message translates to:
  /// **'Taux du jour (USD -> FC)'**
  String get panRateTitle;

  /// No description provided for @panRateFor1.
  ///
  /// In fr, this message translates to:
  /// **'Taux pour 1 USD'**
  String get panRateFor1;

  /// No description provided for @panUpdate.
  ///
  /// In fr, this message translates to:
  /// **'Mettre à jour'**
  String get panUpdate;

  /// No description provided for @panClear.
  ///
  /// In fr, this message translates to:
  /// **'Vider le panier'**
  String get panClear;

  /// No description provided for @panEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Votre panier est vide'**
  String get panEmpty;

  /// No description provided for @panTotal.
  ///
  /// In fr, this message translates to:
  /// **'Total à payer :'**
  String get panTotal;

  /// No description provided for @panCheckout.
  ///
  /// In fr, this message translates to:
  /// **'ENCAISSER'**
  String get panCheckout;

  /// No description provided for @panRateLocked.
  ///
  /// In fr, this message translates to:
  /// **'Seul le patron (ou une personne autorisée) peut changer le taux.'**
  String get panRateLocked;

  /// No description provided for @payCreditNeedsPhone.
  ///
  /// In fr, this message translates to:
  /// **'Pour une vente à crédit, saisissez le numéro de téléphone du client (au moins 9 chiffres).'**
  String get payCreditNeedsPhone;

  /// No description provided for @debtClientPhone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone du client *'**
  String get debtClientPhone;

  /// No description provided for @debtPhoneRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le numéro de téléphone du client est obligatoire pour un crédit (au moins 9 chiffres).'**
  String get debtPhoneRequired;

  /// No description provided for @payCreditNeedsName.
  ///
  /// In fr, this message translates to:
  /// **'Pour une vente à crédit, saisissez le nom du client.'**
  String get payCreditNeedsName;

  /// No description provided for @debtNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le nom du client est obligatoire pour un crédit.'**
  String get debtNameRequired;

  /// No description provided for @cloTitle.
  ///
  /// In fr, this message translates to:
  /// **'Clôture de caisse'**
  String get cloTitle;

  /// No description provided for @cloButton.
  ///
  /// In fr, this message translates to:
  /// **'Clôturer la caisse'**
  String get cloButton;

  /// No description provided for @cloDoneAt.
  ///
  /// In fr, this message translates to:
  /// **'Caisse clôturée à {heure}'**
  String cloDoneAt(String heure);

  /// No description provided for @cloBoutique.
  ///
  /// In fr, this message translates to:
  /// **'Boutique'**
  String get cloBoutique;

  /// No description provided for @cloPickBoutique.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez la boutique à clôturer'**
  String get cloPickBoutique;

  /// No description provided for @cloBlindInfo.
  ///
  /// In fr, this message translates to:
  /// **'Comptez l\'argent du tiroir et notez ce que vous trouvez. Ne recopiez pas un autre montant : le patron compare ensuite avec les ventes.'**
  String get cloBlindInfo;

  /// No description provided for @cloFloatMorning.
  ///
  /// In fr, this message translates to:
  /// **'Fond de caisse du matin'**
  String get cloFloatMorning;

  /// No description provided for @cloCounted.
  ///
  /// In fr, this message translates to:
  /// **'Argent compté dans le tiroir'**
  String get cloCounted;

  /// No description provided for @cloMobileReceived.
  ///
  /// In fr, this message translates to:
  /// **'Mobile Money reçu aujourd\'hui'**
  String get cloMobileReceived;

  /// No description provided for @cloMobileHint.
  ///
  /// In fr, this message translates to:
  /// **'Total reçu sur le téléphone de la boutique, en dollars'**
  String get cloMobileHint;

  /// No description provided for @cloFloatTomorrow.
  ///
  /// In fr, this message translates to:
  /// **'Fond laissé pour demain (facultatif)'**
  String get cloFloatTomorrow;

  /// No description provided for @cloNote.
  ///
  /// In fr, this message translates to:
  /// **'Remarque (facultatif)'**
  String get cloNote;

  /// No description provided for @cloInDollars.
  ///
  /// In fr, this message translates to:
  /// **'En dollars (\$)'**
  String get cloInDollars;

  /// No description provided for @cloInFrancs.
  ///
  /// In fr, this message translates to:
  /// **'En francs (FC)'**
  String get cloInFrancs;

  /// No description provided for @cloSave.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer la clôture'**
  String get cloSave;

  /// No description provided for @cloConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer la clôture ?'**
  String get cloConfirmTitle;

  /// No description provided for @cloConfirmBody.
  ///
  /// In fr, this message translates to:
  /// **'Une fois enregistrée, la clôture ne peut plus être modifiée.'**
  String get cloConfirmBody;

  /// No description provided for @cloSaved.
  ///
  /// In fr, this message translates to:
  /// **'Clôture enregistrée. Le patron verra le résultat.'**
  String get cloSaved;

  /// No description provided for @cloAlreadyDone.
  ///
  /// In fr, this message translates to:
  /// **'Cette caisse est déjà clôturée aujourd\'hui.'**
  String get cloAlreadyDone;

  /// No description provided for @cloResult.
  ///
  /// In fr, this message translates to:
  /// **'Résultat de la clôture'**
  String get cloResult;

  /// No description provided for @cloCash.
  ///
  /// In fr, this message translates to:
  /// **'Espèces'**
  String get cloCash;

  /// No description provided for @cloMobile.
  ///
  /// In fr, this message translates to:
  /// **'Mobile Money'**
  String get cloMobile;

  /// No description provided for @cloExpected.
  ///
  /// In fr, this message translates to:
  /// **'Attendu'**
  String get cloExpected;

  /// No description provided for @cloCountedShort.
  ///
  /// In fr, this message translates to:
  /// **'Compté'**
  String get cloCountedShort;

  /// No description provided for @cloGap.
  ///
  /// In fr, this message translates to:
  /// **'Écart'**
  String get cloGap;

  /// No description provided for @cloOk.
  ///
  /// In fr, this message translates to:
  /// **'Juste ✓'**
  String get cloOk;

  /// No description provided for @cloMissing.
  ///
  /// In fr, this message translates to:
  /// **'Il manque {montant}'**
  String cloMissing(String montant);

  /// No description provided for @cloSurplus.
  ///
  /// In fr, this message translates to:
  /// **'Surplus de {montant}'**
  String cloSurplus(String montant);

  /// No description provided for @cloDetail.
  ///
  /// In fr, this message translates to:
  /// **'Détail de l\'attendu'**
  String get cloDetail;

  /// No description provided for @cloLineFloat.
  ///
  /// In fr, this message translates to:
  /// **'Fond de caisse'**
  String get cloLineFloat;

  /// No description provided for @cloLineSales.
  ///
  /// In fr, this message translates to:
  /// **'Ventes'**
  String get cloLineSales;

  /// No description provided for @cloLineDebts.
  ///
  /// In fr, this message translates to:
  /// **'Dettes encaissées'**
  String get cloLineDebts;

  /// No description provided for @cloLineDeposits.
  ///
  /// In fr, this message translates to:
  /// **'Dépôts des comptes clients'**
  String get cloLineDeposits;

  /// No description provided for @cloLineWithdrawals.
  ///
  /// In fr, this message translates to:
  /// **'Retraits des comptes clients'**
  String get cloLineWithdrawals;

  /// No description provided for @cloLineExpenses.
  ///
  /// In fr, this message translates to:
  /// **'Dépenses'**
  String get cloLineExpenses;

  /// No description provided for @cloLineSuppliers.
  ///
  /// In fr, this message translates to:
  /// **'Fournisseurs payés'**
  String get cloLineSuppliers;

  /// No description provided for @cloLineRefunds.
  ///
  /// In fr, this message translates to:
  /// **'Remboursements des retours'**
  String get cloLineRefunds;

  /// No description provided for @cloLineOther.
  ///
  /// In fr, this message translates to:
  /// **'Autres paiements (carte, virement…), non comptés'**
  String get cloLineOther;

  /// No description provided for @cloExpensesHidden.
  ///
  /// In fr, this message translates to:
  /// **'Les dépenses n\'ont pas pu être lues : l\'attendu peut être trop élevé.'**
  String get cloExpensesHidden;

  /// No description provided for @cloAfterSales.
  ///
  /// In fr, this message translates to:
  /// **'{nombre} vente(s) après la clôture : {montant}'**
  String cloAfterSales(String nombre, String montant);

  /// No description provided for @cloBy.
  ///
  /// In fr, this message translates to:
  /// **'Par {nom} à {heure}'**
  String cloBy(String nom, String heure);

  /// No description provided for @cloHistory.
  ///
  /// In fr, this message translates to:
  /// **'Historique des clôtures'**
  String get cloHistory;

  /// No description provided for @cloHistoryEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune clôture pour le moment.'**
  String get cloHistoryEmpty;

  /// No description provided for @cloReopen.
  ///
  /// In fr, this message translates to:
  /// **'Rouvrir (supprimer la clôture)'**
  String get cloReopen;

  /// No description provided for @cloReopenConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer cette clôture ? La caisse pourra être recomptée.'**
  String get cloReopenConfirm;

  /// No description provided for @cloAfterWarning.
  ///
  /// In fr, this message translates to:
  /// **'Caisse déjà clôturée aujourd\'hui : cette vente sera signalée « après clôture ».'**
  String get cloAfterWarning;

  /// No description provided for @cloRate.
  ///
  /// In fr, this message translates to:
  /// **'Taux : 1 \$ = {taux} FC'**
  String cloRate(String taux);

  /// No description provided for @cloLoading.
  ///
  /// In fr, this message translates to:
  /// **'Calcul de l\'attendu…'**
  String get cloLoading;

  /// No description provided for @cloDoneBy.
  ///
  /// In fr, this message translates to:
  /// **'Clôturée à {heure} par {nom}'**
  String cloDoneBy(String heure, String nom);

  /// No description provided for @cloSavedShort.
  ///
  /// In fr, this message translates to:
  /// **'Clôture enregistrée.'**
  String get cloSavedShort;

  /// No description provided for @caiTitle.
  ///
  /// In fr, this message translates to:
  /// **'Caisse'**
  String get caiTitle;

  /// No description provided for @caiNewProduct.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau produit'**
  String get caiNewProduct;

  /// No description provided for @caiSettings.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get caiSettings;

  /// No description provided for @caiExport.
  ///
  /// In fr, this message translates to:
  /// **'Exporter le catalogue'**
  String get caiExport;

  /// No description provided for @caiExportExcel.
  ///
  /// In fr, this message translates to:
  /// **'Exporter vers Excel'**
  String get caiExportExcel;

  /// No description provided for @caiExportPdf.
  ///
  /// In fr, this message translates to:
  /// **'Imprimer / PDF'**
  String get caiExportPdf;

  /// No description provided for @caiColName.
  ///
  /// In fr, this message translates to:
  /// **'Produit'**
  String get caiColName;

  /// No description provided for @caiColStock.
  ///
  /// In fr, this message translates to:
  /// **'Stock'**
  String get caiColStock;

  /// No description provided for @caiColPrice.
  ///
  /// In fr, this message translates to:
  /// **'Prix de vente'**
  String get caiColPrice;

  /// No description provided for @caiCatalogTitle.
  ///
  /// In fr, this message translates to:
  /// **'Catalogue des produits'**
  String get caiCatalogTitle;

  /// No description provided for @caiProfileError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger votre profil : {erreur}'**
  String caiProfileError(String erreur);

  /// No description provided for @caiPickShop.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez la boutique de vente'**
  String get caiPickShop;

  /// No description provided for @caiSellingIn.
  ///
  /// In fr, this message translates to:
  /// **'Vente : {nom}'**
  String caiSellingIn(String nom);

  /// No description provided for @caiMainShop.
  ///
  /// In fr, this message translates to:
  /// **'Boutique principale'**
  String get caiMainShop;

  /// No description provided for @payDeliveryNote.
  ///
  /// In fr, this message translates to:
  /// **'Bon de livraison'**
  String get payDeliveryNote;

  /// No description provided for @debtOrigin.
  ///
  /// In fr, this message translates to:
  /// **'D\'où vient cette dette ?'**
  String get debtOrigin;

  /// No description provided for @debtOriginSale.
  ///
  /// In fr, this message translates to:
  /// **'Vente hors caisse'**
  String get debtOriginSale;

  /// No description provided for @debtOriginLoan.
  ///
  /// In fr, this message translates to:
  /// **'Argent prêté'**
  String get debtOriginLoan;

  /// No description provided for @debtOriginOld.
  ///
  /// In fr, this message translates to:
  /// **'Ancienne dette (cahier)'**
  String get debtOriginOld;

  /// No description provided for @debtOriginPurchase.
  ///
  /// In fr, this message translates to:
  /// **'Achat à crédit'**
  String get debtOriginPurchase;

  /// No description provided for @debtOriginBorrow.
  ///
  /// In fr, this message translates to:
  /// **'Argent emprunté'**
  String get debtOriginBorrow;

  /// No description provided for @debtFromDrawer.
  ///
  /// In fr, this message translates to:
  /// **'L\'argent est sorti de la caisse'**
  String get debtFromDrawer;

  /// No description provided for @debtToDrawer.
  ///
  /// In fr, this message translates to:
  /// **'L\'argent est entré dans la caisse'**
  String get debtToDrawer;

  /// No description provided for @debtOldPaid.
  ///
  /// In fr, this message translates to:
  /// **'Déjà remboursé avant Nguli'**
  String get debtOldPaid;

  /// No description provided for @cloLineBorrowed.
  ///
  /// In fr, this message translates to:
  /// **'Argent emprunté (mis en caisse)'**
  String get cloLineBorrowed;

  /// No description provided for @cloLineLent.
  ///
  /// In fr, this message translates to:
  /// **'Argent prêté (pris dans la caisse)'**
  String get cloLineLent;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr', 'ln', 'sw'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
    case 'ln':
      return AppLocalizationsLn();
    case 'sw':
      return AppLocalizationsSw();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
