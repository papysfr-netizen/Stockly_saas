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
}
