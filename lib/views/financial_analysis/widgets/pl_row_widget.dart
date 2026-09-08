import 'package:flutter/material.dart';

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
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          fontSize: 14,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${montant.toStringAsFixed(2)} $currency',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isNegative
                  ? Colors.redAccent
                  : (isBold ? Colors.tealAccent : Colors.white),
            ),
          ),
          if (onTap != null) const Icon(Icons.chevron_right, color: Colors.white38, size: 18),
        ],
      ),
    );
  }
}