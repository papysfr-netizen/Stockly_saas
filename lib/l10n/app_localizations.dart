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
  /// **'Envoyé par {nom} — Stockly Pro'**
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
