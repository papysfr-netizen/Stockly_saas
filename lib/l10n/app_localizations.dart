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
