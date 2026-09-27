// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Stockly Pro';

  @override
  String get settings => 'Settings';

  @override
  String get storeInfo => 'Store information';

  @override
  String get storeName => 'Store name';

  @override
  String get address => 'Address';

  @override
  String get phone => 'Phone';

  @override
  String get saveInfo => 'Save information';

  @override
  String get bccSection => 'BCC rate & active currency';

  @override
  String get bccRate => 'Exchange rate (BCC)';

  @override
  String get activeCurrency => 'Main currency';

  @override
  String get appLanguage => 'App language';

  @override
  String get reportsExport => 'Data export';

  @override
  String get exportExcel => 'Export stock to Excel';

  @override
  String get dbMaintenance => 'Maintenance';

  @override
  String get mergeDuplicates => 'Merge duplicates';

  @override
  String get teamManagement => 'Team & permissions';

  @override
  String get teamManagementSubtitle =>
      'Add collaborators and manage their rights';
}
