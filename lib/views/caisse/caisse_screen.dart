import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stockly_saas/core/widgets/currency_selector_widget.dart';
import 'package:stockly_saas/features/boutiques/boutique_provider.dart';
import '../../core/providers/currency_provider.dart';
import '../../core/providers/produit_provider.dart';
import '../../core/providers/user_role_provider.dart';
import '../../features/debts/repositories/vente_repository.dart';
import '../../core/services/report_export_service.dart';
import 'package:stockly_saas/screens/settings_screen.dart';
import 'dialogs/nouveau_produit_dialog.dart';
import 'widgets/panier_view.dart';
import 'widgets/produits_view.dart' hide PanierView;

final venteRepositoryProvider =
    Provider<VenteRepository>((ref) => VenteRepository());

class CaisseScreen extends ConsumerWidget {
  const CaisseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return profileAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Erreur de chargement du profil : $err',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      ),
      data: (profile) {
        final entrepriseId = profile.entrepriseId;
        final userId = profile.uid;

        // 🔐 Droits selon le rôle
        // ➕ Nouveau produit : Propriétaire + Gérant (et permission activée)
        final canAddProduct =
            profile.peutGererStock;
        // ⚙️ Paramètres : Propriétaire seulement
        final estProprietaire = profile.role.peutGererEquipe;
        // 🏬 Bandeau de la boutique de vente (dès 2 boutiques)
        final plusieursBoutiques =
            ref.watch(boutiquesActivesProvider(entrepriseId)).length > 1;


        return LayoutBuilder(
          builder: (context, constraints) {
            final bool isMobile = constraints.maxWidth < 700;

            return Scaffold(
              appBar: AppBar(
                title: const Text('Caisse / POS'),
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
                    constraints: BoxConstraints(maxWidth: 180),
                    child: FittedBox(
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
                      tooltip: 'Nouveau Produit en Stock',
                      onPressed: () =>
                          _afficherDialogNouveauProduit(context, entrepriseId),
                    ),
                  // 🔐 Paramètres : Propriétaire seulement
                  if (estProprietaire)
                    IconButton(
                      icon: const Icon(Icons.settings, size: 24),
                      tooltip: 'Paramètres',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        );
                      },
                    ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 24),
                    tooltip: 'Options d\'exportation',
                    onSelected: (value) async {
                      final produits =
                          ref.read(produitsStreamProvider).value ?? [];
                      final currencyState = ref.read(currencyProvider);

                      final enTetes = [
                        'Nom du produit',
                        'Stock disponible',
                        'Prix Vente'
                      ];
                      final lignes = produits
                          .map((p) => [
                                p.nom,
                                p.quantite,
                                currencyState.formatPrice(p.prixVente),
                              ])
                          .toList();

                      if (value == 'excel') {
                        await ReportExportService.exporterExcel(
                          titreRapport: 'Catalogue_Produits_Caisse',
                          enTetes: enTetes,
                          lignes: lignes,
                        );
                      } else if (value == 'pdf') {
                        await ReportExportService.exporterPDF(
                          titreRapport: 'Catalogue des Produits (Caisse)',
                          nomBoutique: 'Stockly Pro',
                          enTetes: enTetes,
                          lignes: lignes,
                        );
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'excel',
                        child: Row(
                          children: [
                            Icon(Icons.table_chart, color: Colors.green),
                            SizedBox(width: 8),
                            Text('Exporter vers Excel'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'pdf',
                        child: Row(
                          children: [
                            Icon(Icons.picture_as_pdf, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Imprimer / PDF'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              body: isMobile
                  ? const ProduitsView()
                  : Row(
                      children: [
                        const Expanded(flex: 2, child: ProduitsView()),
                        const VerticalDivider(
                          width: 1,
                          thickness: 2,
                          color: Colors.grey,
                        ),
                        Expanded(
                          flex: 1,
                          child: PanierView(
                            entrepriseId: entrepriseId,
                            userId: userId,
                          ),
                        ),
                      ],
                    ),
            );
          },
        );
      },
    );
  }


  void _afficherDialogNouveauProduit(
      BuildContext context, String entrepriseId) {
    showDialog(
      context: context,
      builder: (dialogContext) =>
          NouveauProduitDialog(entrepriseId: entrepriseId),
    );
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
    final choisie = ref.watch(boutiqueActiveProvider);
    final boutiques = ref.watch(boutiquesActivesProvider(entrepriseId));
    final id = choisie ?? 'principale';
    final nom = boutiques.where((b) => b.id == id).map((b) => b.nom).firstOrNull ??
        'Boutique principale';
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
              attention ? 'Choisissez la boutique de vente' : 'Vente : $nom',
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
