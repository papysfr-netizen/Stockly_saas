import 'package:flutter/material.dart';

/// Une ligne du Compte de résultat (Ventes, Coût d'achat, Marge, Dépenses).
/// Les couleurs suivent le thème : lisibles sur fond clair comme sur fond sombre.
class PLRowWidget extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final double montant;
  final String currency;
  final bool isNegative;
  final bool isBold;
  final VoidCallback? onTap;

  const PLRowWidget({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.montant,
    required this.currency,
    this.isNegative = false,
    this.isBold = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sombre = Theme.of(context).brightness == Brightness.dark;

    // Couleur du texte principal : foncé sur fond clair, clair sur fond sombre.
    final couleurTexte = scheme.onSurface;

    // Couleur du montant
    final Color couleurMontant;
    if (isNegative && montant.abs() >= 0.005) {
      couleurMontant = sombre ? Colors.redAccent : Colors.red.shade700;
    } else if (isBold) {
      couleurMontant = sombre ? Colors.tealAccent : Colors.teal.shade700;
    } else {
      couleurMontant = couleurTexte;
    }

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: couleurTexte,
          fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          fontSize: 14,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${(montant.abs() < 0.005 ? 0.0 : montant).toStringAsFixed(2)} $currency',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: couleurMontant,
            ),
          ),
          if (onTap != null)
            Icon(
              Icons.chevron_right,
              color: couleurTexte.withValues(alpha: 0.4),
              size: 18,
            ),
        ],
      ),
    );
  }
}