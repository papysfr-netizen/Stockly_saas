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
  /// **'Stockly Pro'**
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
  /// **'Note / Description (Optionnel)'**
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
