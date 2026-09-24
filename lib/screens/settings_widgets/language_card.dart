import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/locale_provider.dart';

class LanguageCard extends ConsumerWidget {
  const LanguageCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.language, color: Colors.green),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Langue de l\'application',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: currentLocale.languageCode, // Remplacé value par initialValue
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
                      const SizedBox(width: 6),
                      Text(
                        '(${lang.category})',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
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