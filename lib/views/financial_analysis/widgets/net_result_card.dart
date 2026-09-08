import 'package:flutter/material.dart';

class NetResultCard extends StatelessWidget {
  final double beneficeNet;
  final String currency;
  final bool isProfit;

  const NetResultCard({
    super.key,
    required this.beneficeNet,
    required this.currency,
    required this.isProfit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isProfit ? const Color(0xFF1A3B34) : const Color(0xFF3B1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isProfit ? Colors.teal.shade700 : Colors.red.shade700,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isProfit ? Icons.trending_up : Icons.trending_down,
                color: isProfit ? Colors.tealAccent : Colors.redAccent,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'RÉSULTAT NET (BÉNÉFICE NET)',
                style: TextStyle(
                  color: isProfit ? Colors.tealAccent : Colors.redAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${beneficeNet.toStringAsFixed(2)} $currency',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isProfit
                ? 'Votre entreprise est bénéficiaire !'
                : 'Attention : Déficit sur cette période',
            style: TextStyle(
              color: isProfit ? Colors.tealAccent : Colors.redAccent,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}