import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/locale_provider.dart';

class LanguageCard extends ConsumerWidget {
  const LanguageCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final tr = ref.watch(trProvider);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.language, color: Colors.green),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    tr('app_language'),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              // La clé force l'affichage à se mettre à jour quand la
              // langue sauvegardée est relue au démarrage.
              key: ValueKey(currentLocale.languageCode),
              isExpanded: true,
              initialValue: LocaleNotifier.estSupportee(currentLocale.languageCode)
                  ? currentLocale.languageCode
                  : 'fr',
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: LocaleNotifier.supportedLanguages.map((lang) {
                return DropdownMenuItem<String>(
                  value: lang.code,
                  child: Row(
                    children: [
                      Text(lang.flag, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Flexible(child: Text(lang.name, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (code) {
                if (code != null) {
                  ref.read(localeProvider.notifier).setLanguage(code);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}