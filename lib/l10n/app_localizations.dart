import 'package:flutter/material.dart';

/// Gestionnaire de la langue active de l'application
class AppLanguage extends ChangeNotifier {
  Locale _appLocale = const Locale('fr');

  Locale get appLocale => _appLocale;

  void changeLanguage(Locale type) {
    if (_appLocale.languageCode == type.languageCode) return;
    _appLocale = type;
    notifyListeners();
  }
}

/// Dictionnaire et délégué de traduction multilingue (FR, EN, SW)
class AppTranslations {
  final Locale locale;

  AppTranslations(this.locale);

  static AppTranslations? of(BuildContext context) {
    return Localizations.of<AppTranslations>(context, AppTranslations);
  }

  static const LocalizationsDelegate<AppTranslations> delegate =
      _AppTranslationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'fr': {
      'app_title': 'Stockly SaaS',
      'stock_overview': 'Vue d\'ensemble du Stock',
      'add_product': 'Ajouter un Produit',
      'scan_barcode': 'Scanner le Code-Barres',
      'low_stock_alert': 'Alerte Stock Bas',
      'currency': 'Devise',
      'language': 'Langue',
      'sales_analytics': 'Analyse des Ventes',
    },
    'en': {
      'app_title': 'Stockly SaaS',
      'stock_overview': 'Stock Overview',
      'add_product': 'Add Product',
      'scan_barcode': 'Scan Barcode',
      'low_stock_alert': 'Low Stock Alert',
      'currency': 'Currency',
      'language': 'Language',
      'sales_analytics': 'Sales Analytics',
    },
    'sw': {
      'app_title': 'Stockly SaaS',
      'stock_overview': 'Muhtasari wa Akiba',
      'add_product': 'Ongeza Bidhaa',
      'scan_barcode': 'Soma Barcode',
      'low_stock_alert': 'Tahadhari ya Akiba Chini',
      'currency': 'Pesa',
      'language': 'Lugha',
      'sales_analytics': 'Uchanganuzi wa Mauzo',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['fr']?[key] ??
        key;
  }
}

class _AppTranslationsDelegate
    extends LocalizationsDelegate<AppTranslations> {
  const _AppTranslationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['fr', 'en', 'sw'].contains(locale.languageCode);
  }

  @override
  Future<AppTranslations> load(Locale locale) async {
    return AppTranslations(locale);
  }

  @override
  bool shouldReload(_AppTranslationsDelegate old) => false;
}

/// Extension raccourcie pour appeler les traductions dans l'UI
extension TranslationX on BuildContext {
  String tr(String key) {
    return AppTranslations.of(this)?.translate(key) ?? key;
  }
}