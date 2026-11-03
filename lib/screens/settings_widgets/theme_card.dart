import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/theme_provider.dart';

/// 🌙 Carte « Apparence » : Automatique / Clair / Sombre
class ThemeCard extends ConsumerWidget {
  const ThemeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final langue = Localizations.localeOf(context).languageCode;
    String tr(String fr, String en, String sw, String ln) => switch (langue) {
          'en' => en,
          'sw' => sw,
          'ln' => ln,
          _ => fr,
        };

    final options = [
      (ThemeMode.system, Icons.brightness_auto_rounded, tr('Auto', 'Auto', 'Otomatiki', 'Auto')),
      (ThemeMode.light, Icons.light_mode_rounded, tr('Clair', 'Light', 'Mwanga', 'Mwinda')),
      (ThemeMode.dark, Icons.dark_mode_rounded, tr('Sombre', 'Dark', 'Giza', 'Molili')),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.contrast_rounded),
                const SizedBox(width: 8),
                Text(
                  tr('Apparence', 'Appearance', 'Mwonekano', 'Lolenge'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<ThemeMode>(
                showSelectedIcon: false,
                segments: [
                  for (final o in options)
                    ButtonSegment(value: o.$1, icon: Icon(o.$2), label: Text(o.$3)),
                ],
                selected: {mode},
                onSelectionChanged: (s) => ref.read(themeModeProvider.notifier).choisir(s.first),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tr(
                '« Auto » suit le réglage du téléphone (clair le jour, sombre le soir si le téléphone le fait).',
                '“Auto” follows the phone setting.',
                '« Otomatiki » inafuata mpangilio wa simu.',
                '« Auto » elandaka réglage ya telefone.',
              ),
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
