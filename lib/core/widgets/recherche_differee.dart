// ⌨️ Recherche « différée » : on attend que la personne ait fini de taper
// (pause de 250 ms) avant de filtrer la liste. Sur un vieux téléphone, la liste
// n'est plus recalculée à chaque lettre.
import 'dart:async';

import 'package:flutter/widgets.dart';

mixin RechercheDifferee<T extends StatefulWidget> on State<T> {
  Timer? _minuteurRecherche;

  static const Duration pause = Duration(milliseconds: 250);

  /// Lance [action] quand la frappe s'arrête (la précédente est annulée).
  void differer(VoidCallback action) {
    _minuteurRecherche?.cancel();
    _minuteurRecherche = Timer(pause, () {
      if (mounted) action();
    });
  }

  /// À appeler quand on vide le champ (bouton ✕) : la recherche en attente est oubliée.
  void annulerRecherche() => _minuteurRecherche?.cancel();

  @override
  void dispose() {
    _minuteurRecherche?.cancel();
    super.dispose();
  }
}
