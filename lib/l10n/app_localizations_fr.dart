// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Stockly Pro';

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
}
