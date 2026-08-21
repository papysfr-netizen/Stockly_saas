import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LanguageInfo {
  final String code;
  final String name;
  final String flag;
  final String category; // 'Régionale' ou 'Mondiale'

  const LanguageInfo({
    required this.code,
    required this.name,
    required this.flag,
    required this.category,
  });
}

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('fr')); // Français par défaut

  void setLanguage(String languageCode) {
    state = Locale(languageCode);
  }

  static const List<LanguageInfo> supportedLanguages = [
    // --- 10 LANGUES RÉGIONALES (Afrique Centrale, Est & Corne de l'Afrique) ---
    LanguageInfo(code: 'fr', name: 'Français', flag: '🇫🇷', category: 'Régionale'),
    LanguageInfo(code: 'sw', name: 'Kiswahili', flag: '🇨🇩', category: 'Régionale'),
    LanguageInfo(code: 'ln', name: 'Lingála', flag: '🇨🇩', category: 'Régionale'),
    LanguageInfo(code: 'lua', name: 'Tshiluba', flag: '🇨🇩', category: 'Régionale'),
    LanguageInfo(code: 'kg', name: 'Kikongo', flag: '🇨🇩', category: 'Régionale'),
    LanguageInfo(code: 'rw', name: 'Kinyarwanda', flag: '🇷🇼', category: 'Régionale'),
    LanguageInfo(code: 'rn', name: 'Kirundi', flag: '🇧🇮', category: 'Régionale'),
    LanguageInfo(code: 'lg', name: 'Luganda', flag: '🇺🇬', category: 'Régionale'),
    LanguageInfo(code: 'am', name: 'አማርኛ (Amharique)', flag: '🇪🇹', category: 'Régionale'),
    LanguageInfo(code: 'om', name: 'Afaan Oromoo', flag: '🇪🇹', category: 'Régionale'),

    // --- 10 LANGUES LES PLUS PARLÉES AU MONDE ---
    LanguageInfo(code: 'en', name: 'English', flag: '🇬🇧', category: 'Mondiale'),
    LanguageInfo(code: 'es', name: 'Español', flag: '🇪🇸', category: 'Mondiale'),
    LanguageInfo(code: 'zh', name: '中文 (Mandarin)', flag: '🇨🇳', category: 'Mondiale'),
    LanguageInfo(code: 'ar', name: 'العربية (Arabe)', flag: '🇸🇦', category: 'Mondiale'),
    LanguageInfo(code: 'hi', name: 'हिन्दी (Hindi)', flag: '🇮🇳', category: 'Mondiale'),
    LanguageInfo(code: 'pt', name: 'Português', flag: '🇵🇹', category: 'Mondiale'),
    LanguageInfo(code: 'ru', name: 'Русский (Russe)', flag: '🇷🇺', category: 'Mondiale'),
    LanguageInfo(code: 'bn', name: 'বাংলা (Bengali)', flag: '🇧🇩', category: 'Mondiale'),
    LanguageInfo(code: 'de', name: 'Deutsch', flag: '🇩🇪', category: 'Mondiale'),
    LanguageInfo(code: 'ja', name: '日本語 (Japonais)', flag: '🇯🇵', category: 'Mondiale'),
  ];
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

// ================= DICTIONNAIRE DE TRADUCTIONS =================
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
    'active_currency': 'Devise d\'affichage active (20 disponibles)',
    'app_language': 'Langue de l\'application (20 Langues)',
    'reports_export': 'Rapports & Exports',
    'export_excel': 'EXPORTER L\'INVENTAIRE EN EXCEL',
    'db_maintenance': 'Maintenance de la Base de données',
    'merge_duplicates': 'FUSIONNER LES DOUBLONS',
    'clear_stock': 'VIDER TOUT LE STOCK',
  },

  // Kinyarwanda 🇷🇼
  'rw': {
    'settings': 'Igenamiterere & Imiterere',
    'store_info': 'Amakuru y\'Iduka (Inyemezabwishyu)',
    'store_name': 'Izina ry\'Iduka',
    'address': 'Aderesi y\'Iduka (Akarorero: Goma, Nord-Kivu)',
    'phone': 'Telefoni y\'Iduka',
    'save_info': 'BIKA AMAKURU',
    'bcc_section': 'Banki Nkuru ya Kongo (BCC) & Amafaranga',
    'bcc_rate': 'Igipimo Cyemewe cya BCC (1 USD = X FC)',
    'active_currency': 'Amafaranga Akoreshwa (20 ahari)',
    'app_language': 'Ururimi rwa Porogaramu (Ndimo 20)',
    'reports_export': 'Iraporo & Kohereza',
    'export_excel': 'KOHEREZA STOKE MURI EXCEL',
    'db_maintenance': 'Kubungabunga Ububiko bw\'Amakuru',
    'merge_duplicates': 'GUHUZA IBIFITE IZINA RIMO',
    'clear_stock': 'GUSIBA STOKE YOSE',
  },

  // Kiswahili
  'sw': {
    'settings': 'Mipangilio na Usanidi',
    'store_info': 'Taarifa za Duka (Risiti)',
    'store_name': 'Jina la Duka',
    'address': 'Anwani ya Eneo (Mfano: Goma, Nord-Kivu)',
    'phone': 'Nambari ya Simu ya Duka',
    'save_info': 'HIFADHI TAARIFA',
    'bcc_section': 'Benki Kuu ya Congo (BCC) na Fedha',
    'bcc_rate': 'Kiwango Rasmi cha BCC (1 USD = X FC)',
    'active_currency': 'Matazo Inayoonyeshwa (20 zilizopo)',
    'app_language': 'Lugha ya Programu (Lugha 20)',
    'reports_export': 'Ripoti na Usafirishaji',
    'export_excel': 'PAKUA INVENTORY KWA EXCEL',
    'db_maintenance': 'Ukarabati wa Hifadhidata',
    'merge_duplicates': 'UNGANISHA ZAIDI YA MOJA',
    'clear_stock': 'FUTA HISA ZOTE',
  },

  // Lingála
  'ln': {
    'settings': 'Bipamboli mpe Bobongisi',
    'store_info': 'Sango ya Magazini (Tiké)',
    'store_name': 'Kombo ya Magazini',
    'address': 'Adresi ya Magazini (Ndakisa: Goma, Nord-Kivu)',
    'phone': 'Nimero ya Telefon ya Magazini',
    'save_info': 'BOMBA SANGO',
    'bcc_section': 'Banque Centrale du Congo (BCC) mpe Mbongo',
    'bcc_rate': 'Talo ya Leta BCC (1 USD = X FC)',
    'active_currency': 'Mbongo ezali kosalela (20 ezali)',
    'app_language': 'Lokota ya Programe (Nkota 20)',
    'reports_export': 'Rapports mpe Kobimisa',
    'export_excel': 'BIMISA INVENTAIRE NA EXCEL',
    'db_maintenance': 'Bobongisi ya Hifadhidata',
    'merge_duplicates': 'SANGISA BILOKO BIKOKANI',
    'clear_stock': 'LONGOLA BILOKO BIONSO',
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
    'active_currency': 'Active Display Currency (20 available)',
    'app_language': 'Application Language (20 Languages)',
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
    if (appTranslations.containsKey(langCode) && appTranslations[langCode]!.containsKey(key)) {
      return appTranslations[langCode]![key]!;
    }
    // Sécurité : Fallback vers le Français si la traduction n'est pas encore saisie
    return appTranslations['fr']?[key] ?? key;
  };
});