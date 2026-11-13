import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageInfo {
  final String code;
  final String name;
  final String flag;
  final String category; // gardé pour compatibilité, plus affiché

  const LanguageInfo({
    required this.code,
    required this.name,
    required this.flag,
    this.category = '',
  });
}

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('fr')) {
    _chargerLangueSauvegardee();
  }

  /// Nom sous lequel le choix est gardé sur le téléphone.
  static const String _cleStockage = 'langue_app';

  /// Langues proposées : seulement celles qui sont vraiment traduites.
  static const List<LanguageInfo> supportedLanguages = [
    LanguageInfo(code: 'fr', name: 'Français', flag: '🇫🇷'),
    LanguageInfo(code: 'sw', name: 'Kiswahili', flag: '🇨🇩'),
    LanguageInfo(code: 'ln', name: 'Lingála', flag: '🇨🇩'),
    LanguageInfo(code: 'en', name: 'English', flag: '🇬🇧'),
  ];

  static bool estSupportee(String code) =>
      supportedLanguages.any((langue) => langue.code == code);

  /// Au démarrage : relit la langue choisie la dernière fois.
  Future<void> _chargerLangueSauvegardee() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_cleStockage);
      if (code != null && estSupportee(code) && mounted) {
        state = Locale(code);
      }
    } catch (e) {
      debugPrint('[Nguli] Lecture de la langue impossible : $e');
    }
  }

  /// Change la langue ET la garde en mémoire sur le téléphone.
  Future<void> setLanguage(String languageCode) async {
    if (!estSupportee(languageCode)) return;
    state = Locale(languageCode);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cleStockage, languageCode);
    } catch (e) {
      debugPrint('[Nguli] Sauvegarde de la langue impossible : $e');
    }
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

// ================= DICTIONNAIRE DE TRADUCTIONS =================
// Provisoire : sera remplacé par les fichiers de traduction officiels
// de Flutter (étape 2). Kiswahili et lingala à faire relire.
final Map<String, Map<String, String>> appTranslations = {
  // Français
  'fr': {
    'settings': 'Paramètres & Configuration',
    'store_info': 'Informations du Magasin (Ticket)',
    'store_name': 'Nom de la Boutique',
    'address': 'Adresse physique (Ex: Goma, Nord-Kivu)',
    'phone': 'Téléphone Boutique',
    'save_info': 'ENREGISTRER LES INFOS',
    'bcc_section': 'Banque Centrale du Congo (BCC) & Devises',
    'bcc_rate': 'Taux Officiel BCC (1 USD = X FC)',
    'active_currency': 'Devise d\'affichage active',
    'app_language': 'Langue de l\'application',
    'reports_export': 'Rapports & Exports',
    'export_excel': 'EXPORTER L\'INVENTAIRE EN EXCEL',
    'db_maintenance': 'Maintenance de la Base de données',
    'merge_duplicates': 'FUSIONNER LES DOUBLONS',
    'clear_stock': 'VIDER TOUT LE STOCK',
  },

  // Kiswahili (à faire relire)
  'sw': {
    'settings': 'Mipangilio',
    'store_info': 'Taarifa za Duka (Risiti)',
    'store_name': 'Jina la Duka',
    'address': 'Anwani (Mfano: Goma, Kivu Kaskazini)',
    'phone': 'Nambari ya Simu ya Duka',
    'save_info': 'HIFADHI TAARIFA',
    'bcc_section': 'Benki Kuu ya Kongo (BCC) na Sarafu',
    'bcc_rate': 'Kiwango Rasmi cha BCC (1 USD = X FC)',
    'active_currency': 'Sarafu inayotumika',
    'app_language': 'Lugha ya programu',
    'reports_export': 'Ripoti na Kupakua',
    'export_excel': 'PAKUA BIDHAA KWA EXCEL',
    'db_maintenance': 'Matengenezo ya Hifadhidata',
    'merge_duplicates': 'UNGANISHA BIDHAA ZILIZORUDIWA',
    'clear_stock': 'FUTA BIDHAA ZOTE',
  },

  // Lingála (à faire relire)
  'ln': {
    'settings': 'Bibongisi',
    'store_info': 'Sango ya Magazini (Tiké)',
    'store_name': 'Nkombo ya Magazini',
    'address': 'Adresi (Ndakisa: Goma, Nord-Kivu)',
    'phone': 'Nimero ya Telefone ya Magazini',
    'save_info': 'BOMBA SANGO',
    'bcc_section': 'Banque Centrale du Congo (BCC) mpe Mbongo',
    'bcc_rate': 'Motuya ya BCC (1 USD = X FC)',
    'active_currency': 'Mbongo oyo ezali kosalela',
    'app_language': 'Lokota ya programe',
    'reports_export': 'Ba rapport mpe Kobimisa',
    'export_excel': 'BIMISA BILOKO NA EXCEL',
    'db_maintenance': 'Kobongisa ba données',
    'merge_duplicates': 'SANGISA BILOKO OYO EZALI MBALA MIBALE',
    'clear_stock': 'LONGOLA BILOKO NYONSO',
  },

  // English
  'en': {
    'settings': 'Settings & Configuration',
    'store_info': 'Store Information (Receipt)',
    'store_name': 'Store Name',
    'address': 'Physical Address (Ex: Goma, North Kivu)',
    'phone': 'Store Phone Number',
    'save_info': 'SAVE INFORMATION',
    'bcc_section': 'Central Bank of Congo (BCC) & Currencies',
    'bcc_rate': 'Official BCC Rate (1 USD = X CDF)',
    'active_currency': 'Active Display Currency',
    'app_language': 'App language',
    'reports_export': 'Reports & Exports',
    'export_excel': 'EXPORT INVENTORY TO EXCEL',
    'db_maintenance': 'Database Maintenance',
    'merge_duplicates': 'MERGE DUPLICATES',
    'clear_stock': 'CLEAR ALL STOCK',
  },
};

// ================= PROVIDER DE TRADUCTION RÉACTIF =================
final trProvider = Provider<String Function(String key)>((ref) {
  final currentLocale = ref.watch(localeProvider);
  final langCode = currentLocale.languageCode;

  return (String key) {
    if (appTranslations.containsKey(langCode) &&
        appTranslations[langCode]!.containsKey(key)) {
      return appTranslations[langCode]![key]!;
    }
    // Sécurité : retour au français si la traduction manque
    return appTranslations['fr']?[key] ?? key;
  };
});