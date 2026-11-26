// 📜 Liste « paresseuse » : l'en-tête est construit tout de suite, mais les lignes
// (dettes, livraisons, produits importés, mouvements…) ne sont dessinées que
// lorsqu'elles arrivent à l'écran. Avec 500 lignes, un vieux téléphone ne rame plus.
import 'package:flutter/material.dart';

class ListeParesseuse<T> extends StatelessWidget {
  final List<Widget> avant;
  final List<T> elements;
  final Widget Function(BuildContext context, T element) construire;
  final List<Widget> apres;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;

  const ListeParesseuse({
    super.key,
    this.avant = const [],
    required this.elements,
    required this.construire,
    this.apres = const [],
    this.padding,
    this.controller,
  });

  @override
  Widget build(BuildContext context) => ListView.builder(
        controller: controller,
        padding: padding,
        itemCount: avant.length + elements.length + apres.length,
        itemBuilder: (context, i) {
          if (i < avant.length) return avant[i];
          i -= avant.length;
          if (i < elements.length) return construire(context, elements[i]);
          return apres[i - elements.length];
        },
      );
}
