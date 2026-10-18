// ============================================================================
// 🗣️ ACCUEIL « QUI PARLE »
//  - ResumeDuJour : une phrase simple qui résume la journée
//  - AFaireAujourdhui : ce que le commerçant doit faire (stock bas, clients
//    qui doivent de l'argent)
// Ces widgets ne font qu'AFFICHER : ils n'enregistrent rien.
// ============================================================================
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stockly_saas/core/providers/currency_provider.dart';
import 'package:stockly_saas/core/providers/produit_provider.dart';
import 'package:stockly_saas/l10n/app_localizations.dart';

double _num(Object? v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v.replaceAll(',', '.')) ?? 0.0;
  return 0.0;
}

// ----------------------------------------------------------------------------
// 1. LA PHRASE DU JOUR
// ----------------------------------------------------------------------------
class ResumeDuJour extends ConsumerWidget {
  final String prenom;
  final int nbVentes;
  final double ventes;
  final double benefice; // ventes - coût des marchandises - dépenses
  final bool voirFinances;

  const ResumeDuJour({
    super.key,
    required this.prenom,
    required this.nbVentes,
    required this.ventes,
    required this.benefice,
    required this.voirFinances,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devise = ref.watch(currencyProvider);
    final t = AppLocalizations.of(context);
    final heure = DateTime.now().hour;
    final salut = heure < 12 ? t.resMorning : (heure < 18 ? t.resAfternoon : t.resEvening);

    const normal = TextStyle(fontSize: 17, height: 1.45, color: Color(0xFF1F2937));
    const gras = TextStyle(fontWeight: FontWeight.bold);

    final List<InlineSpan> morceaux;
    if (nbVentes == 0) {
      morceaux = [
        TextSpan(text: '$salut $prenom. '),
        TextSpan(text: t.resNoSales),
      ];
    } else {
      morceaux = [
        TextSpan(text: '$salut $prenom. ${t.resTodayPrefix}'),
        TextSpan(text: t.resSalesCount(nbVentes), style: gras),
        TextSpan(text: t.resFor),
        TextSpan(text: devise.formatPrice(ventes), style: gras.copyWith(color: const Color(0xFF0B7A5A))),
        if (voirFinances) ...[
          TextSpan(text: benefice >= 0 ? t.resGained : t.resLoss),
          TextSpan(
            text: devise.formatPrice(benefice.abs()),
            style: gras.copyWith(color: benefice >= 0 ? const Color(0xFF0B7A5A) : Colors.red),
          ),
        ],
        TextSpan(text: benefice >= 0 || !voirFinances ? '. 👏' : '.'),
      ];
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text.rich(TextSpan(style: normal, children: morceaux)),
    );
  }
}

// ----------------------------------------------------------------------------
// 2. À FAIRE AUJOURD'HUI
// ----------------------------------------------------------------------------
class AFaireAujourdhui extends ConsumerStatefulWidget {
  final String entrepriseId;
  final String? boutique; // null = toutes les boutiques
  final VoidCallback onOuvrirStock;
  final VoidCallback onOuvrirCredits;

  const AFaireAujourdhui({
    super.key,
    required this.entrepriseId,
    required this.boutique,
    required this.onOuvrirStock,
    required this.onOuvrirCredits,
  });

  @override
  ConsumerState<AFaireAujourdhui> createState() => _AFaireAujourdhuiState();
}

class _AFaireAujourdhuiState extends ConsumerState<AFaireAujourdhui> {
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _creances;

  @override
  void initState() {
    super.initState();
    // Crédits clients pas encore payés (issus des ventes à crédit)
    _creances = FirebaseFirestore.instance
        .collection('entreprises')
        .doc(widget.entrepriseId)
        .collection('creances')
        .where('montantReste', isGreaterThan: 0)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final devise = ref.watch(currencyProvider);
    final t = AppLocalizations.of(context);
    final produits = ref.watch(produitsStreamProvider).value ?? const [];

    // Produits presque épuisés dans la boutique affichée (les produits à 0 ne sont pas listés)
    final bas = <MapEntry<String, int>>[];
    for (final p in produits) {
      final stock = p.stockBoutique(widget.boutique);
      final seuil = _num(p.toMap()['seuilAlerte']);
      final limite = seuil > 0 ? seuil : 5;
      if (stock > 0 && stock <= limite) bas.add(MapEntry(p.nom, stock));
    }
    bas.sort((a, b) => a.value.compareTo(b.value));

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _creances,
      builder: (context, snap) {
        final clients = <String, double>{};
        for (final d in snap.data?.docs ?? const []) {
          final m = d.data();
          if ((m['type'] ?? 'client').toString() != 'client') continue;
          final nom = (m['nomTiers'] ?? m['nomClient'] ?? t.accClient).toString().trim();
          clients[nom.isEmpty ? t.accClient : nom] = (clients[nom] ?? 0) + _num(m['montantReste']);
        }
        final debiteurs = clients.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

        final lignes = <Widget>[];
        for (final e in debiteurs.take(3)) {
          lignes.add(_ligne(
            icone: Icons.person_rounded,
            couleur: Colors.indigo,
            texte: t.todoOwes(e.key, devise.formatPrice(e.value)),
            action: t.actSee,
            onTap: widget.onOuvrirCredits,
          ));
        }
        if (debiteurs.length > 3) {
          lignes.add(_ligne(
            icone: Icons.groups_rounded,
            couleur: Colors.indigo,
            texte: t.todoOtherClients(debiteurs.length - 3),
            action: t.actAll,
            onTap: widget.onOuvrirCredits,
          ));
        }
        for (final e in bas.take(3)) {
          lignes.add(_ligne(
            icone: e.value <= 0 ? Icons.remove_shopping_cart_rounded : Icons.warning_amber_rounded,
            couleur: e.value <= 0 ? Colors.red : Colors.orange.shade800,
            texte: e.value <= 0
                ? t.todoOut(e.key)
                : t.todoLow(e.value, e.key),
            action: t.navStock,
            onTap: widget.onOuvrirStock,
          ));
        }
        if (bas.length > 3) {
          lignes.add(_ligne(
            icone: Icons.inventory_2_rounded,
            couleur: Colors.orange.shade800,
            texte: t.todoOtherProducts(bas.length - 3),
            action: t.navStock,
            onTap: widget.onOuvrirStock,
          ));
        }

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.todoTitle,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              if (lignes.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(t.todoNothing,
                      style: TextStyle(color: Colors.grey.shade700)),
                )
              else
                ...lignes,
            ],
          ),
        );
      },
    );
  }

  Widget _ligne({
    required IconData icone,
    required Color couleur,
    required String texte,
    required String action,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: couleur.withValues(alpha: 0.12),
              child: Icon(icone, size: 18, color: couleur),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(texte, style: const TextStyle(fontSize: 14.5))),
            TextButton(onPressed: onTap, child: Text(action)),
          ],
        ),
      ),
    );
  }
}
