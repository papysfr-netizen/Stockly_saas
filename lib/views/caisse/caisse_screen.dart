import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stockly_saas/core/widgets/add_product_modal.dart';
import 'package:stockly_saas/core/widgets/currency_selector_widget.dart';
import 'package:stockly_saas/features/boutiques/boutique_provider.dart';
import 'package:stockly_saas/features/boutiques/boutiques_screen.dart' show BoutiquesService;
import 'package:stockly_saas/l10n/app_localizations.dart';
import 'package:stockly_saas/screens/settings_screen.dart';
import '../../core/providers/currency_provider.dart';
import '../../core/providers/produit_provider.dart';
import '../../core/providers/user_role_provider.dart';
import '../../core/services/report_export_service.dart';
import 'widgets/produits_view.dart';

/// 🧾 Écran de la caisse.
///  - Téléphone : les produits, et le panier dans une fenêtre du bas.
///  - Tablette (≥ 700 px) : les produits à gauche, le panier à droite.
class CaisseScreen extends ConsumerWidget {
  const CaisseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final t = AppLocalizations.of(context);

    return profileAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              t.caiProfileError('$err'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      ),
      data: (profile) {
        final entrepriseId = profile.entrepriseId;
        // 🔐 Droits : « Gérer le stock » pour créer un produit, patron pour les paramètres
        final canAddProduct = profile.peutGererStock;
        final estProprietaire = profile.role.peutGererEquipe;
        // 🏬 Bandeau de la boutique de vente (dès 2 boutiques)
        final plusieursBoutiques =
            ref.watch(boutiquesActivesProvider(entrepriseId)).length > 1;

        return LayoutBuilder(
          builder: (context, constraints) {
            final bool isMobile = constraints.maxWidth < 700;

            return Scaffold(
              appBar: AppBar(
                title: Text(t.caiTitle),
                bottom: plusieursBoutiques
                    ? PreferredSize(
                        preferredSize: const Size.fromHeight(46),
                        child: BandeauBoutiqueVente(
                          entrepriseId: entrepriseId,
                          estProprietaire: estProprietaire,
                        ),
                      )
                    : null,
                actions: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 180),
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.0),
                        child: CurrencySelectorWidget(),
                      ),
                    ),
                  ),
                  if (canAddProduct)
                    IconButton(
                      icon: const Icon(Icons.add_box, size: 24),
                      tooltip: t.caiNewProduct,
                      // Même fiche complète que l'écran Stock (boutique, code-barres, journal…)
                      onPressed: () => AddProductModal.show(
                        context,
                        entrepriseId: entrepriseId,
                        boutiqueId: ref.read(boutiqueActiveProvider),
                      ),
                    ),
                  if (estProprietaire)
                    IconButton(
                      icon: const Icon(Icons.settings, size: 24),
                      tooltip: t.caiSettings,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SettingsScreen()),
                      ),
                    ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 24),
                    tooltip: t.caiExport,
                    onSelected: (value) => _exporter(ref, t, value),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'excel',
                        child: Row(children: [
                          const Icon(Icons.table_chart, color: Colors.green),
                          const SizedBox(width: 8),
                          Text(t.caiExportExcel),
                        ]),
                      ),
                      PopupMenuItem(
                        value: 'pdf',
                        child: Row(children: [
                          const Icon(Icons.picture_as_pdf, color: Colors.red),
                          const SizedBox(width: 8),
                          Text(t.caiExportPdf),
                        ]),
                      ),
                    ],
                  ),
                ],
              ),
              body: isMobile
                  ? const ProduitsView()
                  : const Row(
                      children: [
                        // Sur tablette, le panier est déjà à droite : pas de 2ᵉ barre « Encaisser »
                        Expanded(flex: 2, child: ProduitsView(barreEncaisser: false)),
                        VerticalDivider(width: 1, thickness: 2, color: Colors.grey),
                        Expanded(flex: 1, child: PanierView()),
                      ],
                    ),
            );
          },
        );
      },
    );
  }

  /// Catalogue de la boutique de vente (stock de CETTE boutique)
  Future<void> _exporter(WidgetRef ref, AppLocalizations t, String format) async {
    final produits = ref.read(produitsStreamProvider).value ?? [];
    final devise = ref.read(currencyProvider);
    final boutique = ref.read(boutiqueActiveProvider) ?? BoutiquesService.idPrincipale;
    final enTetes = [t.caiColName, t.caiColStock, t.caiColPrice];
    final lignes = produits
        .map((p) => [
              p.nom,
              p.stockBoutique(boutique),
              devise.formatPrice((p.prixPour(boutique) as num).toDouble()),
            ])
        .toList();

    if (format == 'excel') {
      await ReportExportService.exporterExcel(
        titreRapport: t.caiCatalogTitle.replaceAll(' ', '_'),
        enTetes: enTetes,
        lignes: lignes,
      );
    } else {
      await ReportExportService.exporterPDF(
        titreRapport: t.caiCatalogTitle,
        nomBoutique: 'Nguli',
        enTetes: enTetes,
        lignes: lignes,
      );
    }
  }
}

// ============================================================================
// 🏬 BANDEAU « VENTE : <BOUTIQUE> »
// ============================================================================
class BandeauBoutiqueVente extends ConsumerWidget {
  final String entrepriseId;
  final bool estProprietaire;

  const BandeauBoutiqueVente({
    super.key,
    required this.entrepriseId,
    required this.estProprietaire,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final choisie = ref.watch(boutiqueActiveProvider);
    final boutiques = ref.watch(boutiquesActivesProvider(entrepriseId));
    final id = choisie ?? BoutiquesService.idPrincipale;
    final nom = boutiques.where((b) => b.id == id).map((b) => b.nom).firstOrNull ?? t.caiMainShop;
    // Propriétaire sur « Toutes les boutiques » : il doit choisir
    final attention = estProprietaire && choisie == null;

    return Container(
      width: double.infinity,
      height: 46,
      color: attention ? Colors.orange.shade800 : const Color(0xFF1E3A8A),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(
            attention ? Icons.warning_amber_rounded : Icons.storefront_rounded,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              attention ? t.caiPickShop : t.caiSellingIn(nom),
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          if (estProprietaire) SelecteurBoutique(entrepriseId: entrepriseId),
        ],
      ),
    );
  }
}
