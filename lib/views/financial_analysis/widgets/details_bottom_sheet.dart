import 'package:flutter/material.dart';

/// Fenêtre de détail du Compte de résultat (fond bleu nuit).
/// Tout ce qui s'affiche dedans utilise un thème sombre :
/// le texte sans couleur précise devient blanc (sinon : foncé sur foncé).
class DetailsBottomSheet {
  static const Color _fond = Color(0xFF1E2640);

  static void afficher({
    required BuildContext context,
    required String titre,
    required List<Widget> enfants,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _fond,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final themeDeBase = Theme.of(ctx);

        // Thème sombre limité à cette fenêtre
        final themeSombre = themeDeBase.copyWith(
          brightness: Brightness.dark,
          colorScheme: themeDeBase.colorScheme.copyWith(
            brightness: Brightness.dark,
            surface: _fond,
            onSurface: Colors.white,
            onSurfaceVariant: Colors.white70,
          ),
          listTileTheme: const ListTileThemeData(
            textColor: Colors.white,
            iconColor: Colors.white70,
          ),
          dividerColor: Colors.white10,
        );

        return Theme(
          data: themeSombre,
          child: DefaultTextStyle.merge(
            style: const TextStyle(color: Colors.white),
            child: Container(
              padding: const EdgeInsets.all(20),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    titre,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Colors.white10),
                  Expanded(
                    child: enfants.isEmpty
                        ? const Center(
                            child: Text(
                              'Aucun détail disponible pour cette période.',
                              style: TextStyle(color: Colors.white54),
                            ),
                          )
                        : ListView(children: enfants),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}