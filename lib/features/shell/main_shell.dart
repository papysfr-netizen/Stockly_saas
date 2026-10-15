// ============================================================================
// 🧭 COQUILLE PRINCIPALE : barre de menu en bas
// Accueil • Caisse • Stock • Rapport • Paramètres
// Les écrans existants sont réutilisés tels quels (aucun n'est modifié).
// Un onglet n'est chargé que la première fois qu'on l'ouvre (économie de données).
// ============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stockly_saas/core/models/user_model.dart';
import 'package:stockly_saas/core/providers/user_role_provider.dart';
import 'package:stockly_saas/features/debts/screens/home_screen.dart';
import 'package:stockly_saas/features/shell/accueil_screen.dart';
import 'package:stockly_saas/screens/settings_screen.dart';
import 'package:stockly_saas/views/caisse/caisse_screen.dart';
import 'package:stockly_saas/l10n/app_localizations.dart';
import 'package:stockly_saas/views/financial_analysis/financial_analysis_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  final UserModel currentUser;

  const MainShell({super.key, required this.currentUser});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _Onglet {
  final String cle; // identifiant fixe (ne change pas avec la langue)
  final String titre;
  final IconData icone;
  final IconData iconeActive;
  final Widget Function() ecran;

  const _Onglet(this.cle, this.titre, this.icone, this.iconeActive, this.ecran);
}

class _MainShellState extends ConsumerState<MainShell> {
  int _index = 0;
  final Set<String> _dejaOuverts = {'Accueil'};

  @override
  Widget build(BuildContext context) {
    // Le Rapport (finances) n'apparaît que pour ceux qui ont l'autorisation
    final profil = ref.watch(userProfileProvider).value;
    final voirFinances = profil?.peutVoirFinances ?? false;
    final t = AppLocalizations.of(context);

    final onglets = <_Onglet>[
      _Onglet('Accueil', t.navAccueil, Icons.home_outlined, Icons.home_rounded,
          () => AccueilScreen(currentUser: widget.currentUser)),
      _Onglet('Caisse', t.navCaisse, Icons.point_of_sale_outlined, Icons.point_of_sale_rounded,
          () => const CaisseScreen()),
      _Onglet('Stock', t.navStock, Icons.inventory_2_outlined, Icons.inventory_2_rounded,
          () => HomeScreen(currentUser: widget.currentUser)),
      if (voirFinances)
        _Onglet('Rapport', t.navRapport, Icons.bar_chart_outlined, Icons.bar_chart_rounded,
            () => const FinancialAnalysisScreen()),
      _Onglet('Paramètres', t.navParametres, Icons.settings_outlined, Icons.settings_rounded,
          () => const SettingsScreen()),
    ];

    if (_index >= onglets.length) _index = 0;

    return PopScope(
      // Bouton « retour » d'Android : revient d'abord à l'Accueil
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _index != 0) setState(() => _index = 0);
      },
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: [
            for (final o in onglets)
              _dejaOuverts.contains(o.cle)
                  ? KeyedSubtree(key: ValueKey(o.cle), child: o.ecran())
                  : const SizedBox.shrink(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          height: 68,
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFF0052FF).withValues(alpha: 0.12),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (i) => setState(() {
            _index = i;
            _dejaOuverts.add(onglets[i].cle);
          }),
          destinations: [
            for (final o in onglets)
              NavigationDestination(
                icon: Icon(o.icone),
                selectedIcon: Icon(o.iconeActive, color: const Color(0xFF0052FF)),
                label: o.titre,
              ),
          ],
        ),
      ),
    );
  }
}
