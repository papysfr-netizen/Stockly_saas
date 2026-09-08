import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/debt_controller.dart';
import 'package:stockly_saas/models/dette.dart';

class DebtDialogs {
  static String _formaterDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  static void afficherAjoutDette(
    BuildContext context,
    WidgetRef ref,
    String entrepriseId,
    TypeDette type,
  ) {
    final nomController = TextEditingController();
    final factureController = TextEditingController();
    final montantTotalController = TextEditingController();
    final acompteController = TextEditingController();
    final noteController = TextEditingController();
    DateTime? dateEcheanceSelectionnee;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: Text(
              type == TypeDette.client
                  ? 'Nouvelle Créance Client'
                  : 'Nouvelle Dette Fournisseur',
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nomController,
                    decoration: InputDecoration(
                      labelText: type == TypeDette.client
                          ? 'Nom du Client *'
                          : 'Nom du Fournisseur *',
                      prefixIcon: const Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: factureController,
                    decoration: const InputDecoration(
                      labelText: 'N° Facture / Référence',
                      prefixIcon: Icon(Icons.receipt_long),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: montantTotalController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Montant Total *',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: acompteController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Acompte Versé (Si crédit partiel)',
                      prefixIcon: Icon(Icons.payments),
                      hintText: '0.0',
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: dialogContext,
                        initialDate:
                            DateTime.now().add(const Duration(days: 30)),
                        firstDate:
                            DateTime.now().subtract(const Duration(days: 365)),
                        lastDate:
                            DateTime.now().add(const Duration(days: 365 * 5)),
                      );
                      if (pickedDate != null) {
                        setDialogState(() {
                          dateEcheanceSelectionnee = pickedDate;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              color: Colors.indigo),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              dateEcheanceSelectionnee == null
                                  ? "Sélectionner une date d'échéance"
                                  : "Échéance : ${_formaterDate(dateEcheanceSelectionnee!)}",
                              style: TextStyle(
                                color: dateEcheanceSelectionnee == null
                                    ? Colors.grey.shade600
                                    : Colors.black,
                                fontWeight: dateEcheanceSelectionnee != null
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      labelText: 'Note / Description (Optionnel)',
                      prefixIcon: Icon(Icons.note),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: type == TypeDette.client
                      ? Colors.orange.shade800
                      : Colors.red.shade800,
                ),
                onPressed: () async {
                  final nom = nomController.text.trim();
                  final montantTotal =
                      double.tryParse(montantTotalController.text.trim()) ?? 0.0;
                  final acompte =
                      double.tryParse(acompteController.text.trim()) ?? 0.0;

                  if (nom.isNotEmpty && montantTotal > 0) {
                    final navigator = Navigator.of(dialogContext);
                    await ref
                        .read(debtControllerProvider(entrepriseId).notifier)
                        .ajouterDette(
                          nomTiers: nom,
                          numeroFacture: factureController.text.trim(),
                          montantTotal: montantTotal,
                          acompte: acompte,
                          type: type,
                          note: noteController.text.trim(),
                          dateEcheance: dateEcheanceSelectionnee,
                        );
                    navigator.pop();
                  }
                },
                child: const Text('Enregistrer',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  static void afficherPaiement(
    BuildContext context,
    WidgetRef ref,
    String entrepriseId,
    Dette dette,
    String currency,
  ) {
    final montantPaiementController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Règlement : ${dette.nomTiers}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (dette.numeroFacture.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  'Facture N° : ${dette.numeroFacture}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.indigo),
                ),
              ),
            Text(
                'Reste à payer actuel : ${dette.montantReste.toStringAsFixed(2)} $currency'),
            const SizedBox(height: 12),
            TextField(
              controller: montantPaiementController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Montant du Règlement',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700),
            onPressed: () async {
              final paye =
                  double.tryParse(montantPaiementController.text.trim()) ?? 0.0;
              if (paye > 0) {
                final navigator = Navigator.of(dialogContext);
                await ref
                    .read(debtControllerProvider(entrepriseId).notifier)
                    .enregistrerPaiement(
                      detteId: dette.id,
                      montantPaye: paye,
                    );
                navigator.pop();
              }
            },
            child: const Text('Valider le Règlement',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}