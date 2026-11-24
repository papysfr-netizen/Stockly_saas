import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stockly_saas/core/models/produit.dart';
import 'package:stockly_saas/features/assistant/assistant_service.dart';

void main() {
  final maintenant = DateTime(2026, 11, 24, 15);
  Map<String, dynamic> vente(DateTime d, double total, {double reste = 0, String vendeur = 'Grace', double retour = 0}) => {
        'date': Timestamp.fromDate(d),
        'montantTotal': total,
        'montantRetourne': retour,
        'resteAPayer': reste,
        'coutMarchandises': total * 0.6,
        'vendeurNom': vendeur,
        'boutiqueId': 'principale',
        'articles': [
          {'produitId': 'p1', 'nom': 'Primus', 'quantite': 6, 'prixUnitaire': total / 6},
        ],
      };

  test('résumé : ventes nettes, vendeurs, produits, stock à recommander, dettes', () {
    final r = AssistantService.resumer(
      maintenant: maintenant,
      ventes: [
        vente(DateTime(2026, 11, 23, 10), 30),
        vente(DateTime(2026, 11, 24, 9), 60, reste: 20, vendeur: 'Jean', retour: 10),
      ],
      creances: [
        {'nomTiers': 'Mama Neema', 'montantReste': 40, 'telephone': '0812345678'},
        {'nomTiers': 'Papa Jo', 'montantReste': 0},
      ],
      dettesFournisseurs: [
        {'nomTiers': 'Bralima', 'montantReste': 300},
      ],
      depenses: [
        {'categorie': 'Transport', 'montant': 5},
        {'categorie': 'Transport', 'montant': 3},
      ],
      produits: const [
        Produit(id: 'p1', entrepriseId: 'e', nom: 'Primus', quantite: 4, prixAchat: 1, seuilAlerte: 2),
        Produit(id: 'p2', entrepriseId: 'e', nom: 'Sac', quantite: 10, prixAchat: 2),
      ],
      tauxCDF: 2800,
    );
    final ventes = r['ventes'] as Map;
    expect(ventes['nombre'], 2);
    expect(ventes['chiffreAffairesNet'], 80); // 30 + 60 − 10 de retour
    expect(ventes['creditAccorde'], 20);
    expect((ventes['parJour'] as Map)['2026-11-24'], 50);
    expect((ventes['parVendeur'] as List).first['vendeur'], 'Jean');
    expect((ventes['produitsLesPlusVendus'] as List).first['quantite'], 12);

    final stock = r['stock'] as Map;
    // Primus : 12 vendus en 30 jours, 4 en stock → 10 jours restants
    expect((stock['aRecommander'] as List).first['nom'], 'Primus');
    expect((stock['aRecommander'] as List).first['joursRestants'], 10);
    expect((stock['neBougentPas'] as List).first['nom'], 'Sac');

    final clients = r['clientsQuiDoivent'] as Map;
    expect(clients['total'], 40);
    expect(clients['nombre'], 1);
    expect(r.toString().contains('0812345678'), isFalse); // pas de téléphone envoyé
    expect((r['jeDoisAuxFournisseurs'] as Map)['total'], 300);
    expect((r['depenses'] as Map)['total'], 8);
    expect(r['taux'], '1 USD = 2800 FC');
  });
}
