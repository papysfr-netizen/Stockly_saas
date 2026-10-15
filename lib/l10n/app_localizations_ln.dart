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
}
