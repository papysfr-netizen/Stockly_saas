import 'package:flutter/material.dart';

import '../../models/emploi_du_temps.dart';
import '../../services/emploi_du_temps.dart';

/// Contenu affiché dans une case.
typedef ContenuCase = ({String titre, String detail});

/// Grille jours × plages horaires. Grand écran : tableau complet ;
/// téléphone : un onglet par jour, la liste des heures en dessous.
class GrilleEmploiDuTemps extends StatelessWidget {
  const GrilleEmploiDuTemps({
    super.key,
    required this.jours,
    required this.plages,
    required this.creneaux,
    required this.contenu,
    this.onTap,
  });

  final List<int> jours;
  final List<String> plages;
  final List<Creneau> creneaux;
  final ContenuCase Function(Creneau c) contenu;
  final void Function(int jour, String plage, Creneau? existant)? onTap;

  Creneau? _a(int jour, String plage) => creneaux.where((c) => c.jour == jour && c.plage == plage).firstOrNull;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, box) => box.maxWidth >= 760 ? _tableau(context) : _parJour(context),
      );

  Widget _case(BuildContext context, int jour, String plage, {bool compacte = false}) {
    final c = _a(jour, plage);
    final scheme = Theme.of(context).colorScheme;
    final contenu = c == null ? null : this.contenu(c);
    return InkWell(
      onTap: onTap == null ? null : () => onTap!(jour, plage, c),
      child: Container(
        constraints: BoxConstraints(minHeight: compacte ? 48 : 56),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: c == null ? null : scheme.primaryContainer.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.centerLeft,
        child: contenu == null
            ? (onTap == null ? const SizedBox.shrink() : Icon(Icons.add, size: 18, color: scheme.outline))
            : Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(contenu.titre,
                    style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                if (contenu.detail.isNotEmpty)
                  Text(contenu.detail,
                      style: Theme.of(context).textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
              ]),
      ),
    );
  }

  Widget _tableau(BuildContext context) {
    final bord = BorderSide(color: Theme.of(context).dividerColor);
    return Table(
      border:
          TableBorder(horizontalInside: bord, verticalInside: bord, top: bord, bottom: bord, left: bord, right: bord),
      columnWidths: const {0: FixedColumnWidth(96)},
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest),
          children: [
            const Padding(padding: EdgeInsets.all(8), child: Text('Heure')),
            for (final j in jours)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(nomsJours[j - 1], style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        for (final p in plages)
          TableRow(children: [
            Padding(padding: const EdgeInsets.all(8), child: Text(p.replaceAll('-', '\n'))),
            for (final j in jours) Padding(padding: const EdgeInsets.all(2), child: _case(context, j, p)),
          ]),
      ],
    );
  }

  Widget _parJour(BuildContext context) {
    final aujourdhui = DateTime.now().weekday;
    return DefaultTabController(
      length: jours.length,
      initialIndex: jours.contains(aujourdhui) ? jours.indexOf(aujourdhui) : 0,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        TabBar(isScrollable: true, tabs: [for (final j in jours) Tab(text: nomsJours[j - 1])]),
        SizedBox(
          height: plages.length * 64.0 + 8,
          child: TabBarView(children: [
            for (final j in jours)
              Column(children: [
                for (final p in plages)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(children: [
                      SizedBox(width: 92, child: Text(p, style: Theme.of(context).textTheme.bodySmall)),
                      Expanded(child: _case(context, j, p, compacte: true)),
                    ]),
                  ),
              ]),
          ]),
        ),
      ]),
    );
  }
}
