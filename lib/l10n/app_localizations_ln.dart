// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Lingala (`ln`).
class AppLocalizationsLn extends AppLocalizations {
  AppLocalizationsLn([String locale = 'ln']) : super(locale);

  @override
  String get appTitle => 'Stockly Pro';

  @override
  String get settings => 'Bibongisi';

  @override
  String get storeInfo => 'Sango ya magazini';

  @override
  String get storeName => 'Nkombo ya magazini';

  @override
  String get address => 'Adresi';

  @override
  String get phone => 'Telefone';

  @override
  String get saveInfo => 'Bomba sango';

  @override
  String get bccSection => 'Motuya ya BCC mpe mbongo';

  @override
  String get bccRate => 'Motuya ya mbongo (BCC)';

  @override
  String get activeCurrency => 'Mbongo ya liboso';

  @override
  String get appLanguage => 'Lokota ya programe';

  @override
  String get reportsExport => 'Kobimisa ba données';

  @override
  String get exportExcel => 'Bimisa biloko na Excel';

  @override
  String get dbMaintenance => 'Kobongisa';

  @override
  String get mergeDuplicates => 'Sangisa biloko oyo ezali mbala mibale';

  @override
  String get teamManagement => 'Ekipi mpe ba ndingisa';

  @override
  String get teamManagementSubtitle =>
      'Bakisa basali mpe bongisa makoki na bango';

  @override
  String get navAccueil => 'Ebandeli';

  @override
  String get navCaisse => 'Kesi';

  @override
  String get navStock => 'Biloko';

  @override
  String get navRapport => 'Lapolo';

  @override
  String get navParametres => 'Mibongiseli';

  @override
  String accHello(String prenom) {
    return 'Mbote $prenom 👋';
  }

  @override
  String get tauxTitle => 'Motuya ya dolare lelo';

  @override
  String get cancel => 'Tika';

  @override
  String get save => 'Kobomba';

  @override
  String get accToday => 'LELO';

  @override
  String get accOfSales => 'ya biteki';

  @override
  String get accCashed => 'Mbongo ezwami';

  @override
  String get accCredit => 'Niongo';

  @override
  String get accExpenses => 'Bibimisi';

  @override
  String accCashInDrawer(String montant) {
    return 'Mbongo na kesi lelo : $montant';
  }

  @override
  String accDiscounts(String montant) {
    return 'Bakitisi talo : $montant';
  }

  @override
  String get accSendSummary => 'Tinda bokuse ya lelo';

  @override
  String get accExpense => 'Mbimisi';

  @override
  String get accSales => 'Biteki';

  @override
  String get accClientAccounts => 'Ba compte ya bakiliya';

  @override
  String get accAccounting => 'Botangi mbongo';

  @override
  String get accHelp => 'Lisalisi';

  @override
  String accTodaySales(int count) {
    return 'Biteki ya lelo ($count)';
  }

  @override
  String get accNoSales =>
      'Naino biteki te lelo.\nFina « Kesi » mpo na kobanda.';

  @override
  String get accClient => 'Mosombi';

  @override
  String accRemaining(String montant) {
    return 'etikali $montant';
  }

  @override
  String get accMainShop => 'Magazini monene';

  @override
  String get resMorning => 'Mbote';

  @override
  String get resAfternoon => 'Mbote';

  @override
  String get resEvening => 'Mbote';

  @override
  String get resNoSales => 'Naino biteki te lelo. Mosala malamu! 💪';

  @override
  String get resTodayPrefix => 'Lelo, ';

  @override
  String resSalesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'biteki $count',
      one: 'eteki 1',
    );
    return '$_temp0';
  }

  @override
  String get resFor => ' ya ';

  @override
  String get resGained => '. Ozwi litomba ya ';

  @override
  String get resLoss => '. Sikawa, bobungisi ya ';

  @override
  String get todoTitle => '📋 Oyo ya kosala lelo';

  @override
  String get todoNothing => '✅ Eloko ya nsoko te. Nyonso ezali malamu!';

  @override
  String todoOwes(String nom, String montant) {
    return '$nom azali na niongo na yo $montant';
  }

  @override
  String todoOtherClients(int count) {
    return '…mpe bakiliya mosusu $count';
  }

  @override
  String todoOut(String nom) {
    return '$nom : esili';
  }

  @override
  String todoLow(int count, String nom) {
    return 'Etikali kaka $count ya $nom';
  }

  @override
  String todoOtherProducts(int count) {
    return '…mpe biloko mosusu $count ya kosomba lisusu';
  }

  @override
  String get actSee => 'Tala';

  @override
  String get actAll => 'Nyonso';

  @override
  String get caisseNoCompany => 'Libunga: kompanyi eponami te.';

  @override
  String caisseOutOfStock(String nom) {
    return '$nom esili na stock!';
  }

  @override
  String caisseStockLimit(int count) {
    return 'Ndelo ya stock ekoki ($count)';
  }

  @override
  String caisseAdded(String nom) {
    return '$nom ebakisami na panier!';
  }

  @override
  String caisseNoBarcode(String code) {
    return 'Eloko moko te na kode : $code';
  }

  @override
  String get caisseSearch => 'Luka eloko…';

  @override
  String get caisseScan => 'Tanga kode-barre';

  @override
  String errorPrefix(String message) {
    return 'Libunga : $message';
  }

  @override
  String get caisseNoProducts =>
      'Biloko ezali te.\nBakisa biloko na yo na « Biloko ».';

  @override
  String get caisseHint =>
      'Simba eloko mpo na kobakisa • simba ntango molai: motango';

  @override
  String get caisseNoMatch => 'Eloko moko te ekokani na oyo olukaki.';

  @override
  String caisseCheckout(String montant) {
    return 'Zwa mbongo $montant';
  }

  @override
  String get caisseNoName => 'Kombo te';

  @override
  String get caisseOut => 'Esili';

  @override
  String get caissePriceNeedsPermission =>
      'Kobongola talo esengeli ndingisa ya « Bakitisi mpe kobimisa ».';

  @override
  String get cartTitle => 'Panier';

  @override
  String get cartEmpty => 'Panier na yo ezali pamba';

  @override
  String cartCount(int count) {
    return 'Panier (biloko $count)';
  }

  @override
  String get cartClear => 'Longola nyonso na panier';

  @override
  String cartNormalPrice(String montant) {
    return 'Talo ya momesano : $montant';
  }

  @override
  String get cartLoss => 'Koteka na bobungisi';
}
