// ⬜ Pendant un chargement, on montre la FORME de la page en gris (comme WhatsApp
// ou Facebook) au lieu d'un rond qui tourne sur une page blanche :
// l'application paraît plus rapide et l'œil sait déjà où regarder.
import 'package:flutter/material.dart';

class ChargementSquelette extends StatefulWidget {
  /// true : cases de produits (caisse) ; false : lignes de liste
  final bool grille;
  final int lignes;
  const ChargementSquelette({super.key, this.grille = false, this.lignes = 6});

  @override
  State<ChargementSquelette> createState() => _ChargementSqueletteState();
}

class _ChargementSqueletteState extends State<ChargementSquelette> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sombre = Theme.of(context).brightness == Brightness.dark;
    final gris = sombre ? const Color(0xFF2A2E36) : const Color(0xFFE6E8EC);
    final fond = sombre ? const Color(0xFF1C1F26) : Colors.white;

    Widget bloc(double h, {double? w, double r = 6}) => Container(
          height: h,
          width: w,
          decoration: BoxDecoration(color: gris, borderRadius: BorderRadius.circular(r)),
        );

    Widget ligne() => Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: fond, borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            bloc(40, w: 40, r: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                FractionallySizedBox(widthFactor: 0.7, child: bloc(12)),
                const SizedBox(height: 8),
                FractionallySizedBox(widthFactor: 0.45, child: bloc(10)),
              ]),
            ),
            const SizedBox(width: 12),
            bloc(14, w: 56),
          ]),
        );

    Widget caseProduit() => Expanded(
          child: Container(
            margin: const EdgeInsets.all(4),
            padding: const EdgeInsets.all(10),
            height: 110,
            decoration: BoxDecoration(color: fond, borderRadius: BorderRadius.circular(14)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              bloc(12),
              const SizedBox(height: 8),
              FractionallySizedBox(widthFactor: 0.6, child: bloc(10)),
              const Spacer(),
              FractionallySizedBox(widthFactor: 0.5, child: bloc(14)),
            ]),
          ),
        );

    return FadeTransition(
      opacity: Tween(begin: 0.45, end: 1.0).animate(_pulse),
      child: ClipRect(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < widget.lignes; i++)
                widget.grille ? Row(children: [caseProduit(), caseProduit(), caseProduit()]) : ligne(),
            ],
          ),
        ),
      ),
    );
  }
}
