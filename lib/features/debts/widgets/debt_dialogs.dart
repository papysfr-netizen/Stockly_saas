// 🌙 mode sombre automatique
// lib/features/debts/presentation/dialogs/debt_dialogs.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stockly_saas/core/models/dette.dart';
import 'package:stockly_saas/core/models/payment_method.dart';
import '../controllers/debt_controller.dart';
import 'package:stockly_saas/l10n/app_localizations.dart';
import 'package:stockly_saas/features/comptes_clients/compte_client_service.dart';
import 'package:stockly_saas/features/boutiques/boutique_provider.dart';

class DebtDialogs {
  static String _formaterDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  /// Dialogue pour l'ajout d'une nouvelle créance client ou dette fournisseur
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
    final t = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: Text(
              type == TypeDette.client
                  ? t.debtNewClient
                  : t.debtNewSupplier,
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nomController,
                    decoration: InputDecoration(
                      labelText: type == TypeDette.client
                          ? t.debtClientName
                          : t.debtSupplierName,
                      prefixIcon: const Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: factureController,
                    decoration: InputDecoration(
                      labelText: t.debtInvoiceRef,
                      prefixIcon: Icon(Icons.receipt_long),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: montantTotalController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: t.debtTotal,
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: acompteController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: t.debtAlreadyPaid,
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
                                  ? t.debtPickDueDate
                                  : t.debtDueDate(_formaterDate(dateEcheanceSelectionnee!)),
                              style: TextStyle(
                                color: dateEcheanceSelectionnee == null
                                    ? (Theme.of(context).brightness == Brightness.dark ? Colors.grey[400]! : Colors.grey[600]!)
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
                    decoration: InputDecoration(
                      labelText: t.debtNote,
                      prefixIcon: Icon(Icons.note),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(t.cancel),
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
                    // 🛑 Déjà payé > total : on refuse
                    if (acompte > montantTotal + 0.005 || acompte < 0) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(
                        content: Text(t.debtPaidOverTotal),
                        backgroundColor: Colors.red,
                      ));
                      return;
                    }
                    final controleur =
                        ref.read(debtControllerProvider(entrepriseId).notifier);
                    // On ferme d'abord la fenêtre, puis on enregistre
                    Navigator.of(dialogContext).pop();
                    await controleur
                        .ajouterDette(
                          nomTiers: nom,
                          numeroFacture: factureController.text.trim(),
                          montantTotal: montantTotal,
                          acompte: acompte,
                          type: type,
                          note: noteController.text.trim(),
                          dateEcheance: dateEcheanceSelectionnee,
                          boutiqueId: ref.read(boutiqueActiveProvider) ?? 'principale', // 🏬
                        );
                  }
                },
                child: Text(t.save,
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Dialogue pour enregistrer un règlement (partiel ou total) sur une créance/dette
  static void afficherPaiement(
    BuildContext context,
    WidgetRef ref,
    String entrepriseId,
    Dette dette,
    String currency,
  ) {
    final montantPaiementController = TextEditingController();
    PaymentMethod modePaiementSelectionne = PaymentMethod.cash;
    String? erreurMontant;
    bool enCours = false;
    final messenger = ScaffoldMessenger.of(context);
    final t = AppLocalizations.of(context);
    final controleur = ref.read(debtControllerProvider(entrepriseId).notifier);

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(t.debtPaymentTitle(dette.nomTiers)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (dette.numeroFacture.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      t.debtInvoiceNo(dette.numeroFacture),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.indigo),
                    ),
                  ),
                Text(
                    t.debtRemainingNow('${dette.montantReste.toStringAsFixed(2)} $currency')),
                const SizedBox(height: 12),
                TextField(
                  controller: montantPaiementController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: t.debtPaymentAmount,
                    border: const OutlineInputBorder(),
                    errorText: erreurMontant,
                    helperText: dette.type == TypeDette.client &&
                            CompteClientService.telephoneValide(dette.telephone)
                        ? t.debtHelperSurplus('${dette.montantReste.toStringAsFixed(2)} $currency')
                        : t.debtMax('${dette.montantReste.toStringAsFixed(2)} $currency'),
                    helperMaxLines: 2,
                    errorMaxLines: 3,
                  ),
                  onChanged: (_) {
                    if (erreurMontant != null) setDialogState(() => erreurMontant = null);
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<PaymentMethod>(
                  initialValue: modePaiementSelectionne,
                  decoration: InputDecoration(
                    labelText: t.debtPaymentMode,
                    border: OutlineInputBorder(),
                  ),
                  items: PaymentMethod.values.map((method) {
                    String label = method.name;
                    if (method == PaymentMethod.cash) label = t.debtCashDesk;
                    if (method == PaymentMethod.bankTransfer) label = t.payTransfer;
                    if (method == PaymentMethod.check) label = t.debtCheck;

                    return DropdownMenuItem(
                      value: method,
                      child: Text(label),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() {
                        modePaiementSelectionne = val;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(t.cancel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700),
              onPressed: enCours
                  ? null
                  : () async {
                      final paye = double.tryParse(
                              montantPaiementController.text.trim().replaceAll(',', '.')) ??
                          0.0;
                      // 🛑 Montant vide, nul ou supérieur au reste : on refuse
                      if (paye <= 0) {
                        setDialogState(() => erreurMontant = t.debtEnterAmount);
                        return;
                      }
                      // 💰 Le client donne PLUS que sa dette : le surplus peut aller sur son compte
                      double surplus = 0;
                      if (paye > dette.montantReste + 0.005) {
                        final peutGarder = dette.type == TypeDette.client &&
                            CompteClientService.telephoneValide(dette.telephone);
                        if (!peutGarder) {
                          setDialogState(() => erreurMontant = dette.type == TypeDette.client
                              ? t.debtTooHighNoPhone('${dette.montantReste.toStringAsFixed(2)} $currency')
                              : t.debtTooHigh('${dette.montantReste.toStringAsFixed(2)} $currency'));
                          return;
                        }
                        surplus = paye - dette.montantReste;
                        final accepte = await showDialog<bool>(
                          context: dialogContext,
                          builder: (c) => AlertDialog(
                            icon: const Icon(Icons.savings_rounded, color: Colors.teal, size: 40),
                            title: Text(t.debtGivesMore),
                            content: Text(t.debtSurplusQuestion(
                              '${dette.montantReste.toStringAsFixed(2)} $currency',
                              '${paye.toStringAsFixed(2)} $currency',
                              '${surplus.toStringAsFixed(2)} $currency',
                              dette.nomTiers,
                            )),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(c, false),
                                child: Text(t.noCorrect),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(c, true),
                                child: Text(t.debtYesAccount),
                              ),
                            ],
                          ),
                        );
                        if (accepte != true) return;
                      }
                      if (!dialogContext.mounted) return;
                      final payeDette = surplus > 0 ? dette.montantReste : paye;
                      setDialogState(() => enCours = true);
                      // On ferme d'abord la fenêtre, puis on enregistre
                      Navigator.of(dialogContext).pop();
                      try {
                        await controleur.enregistrerPaiement(
                          detteId: dette.id,
                          montantPaye: payeDette,
                          paymentMethod: modePaiementSelectionne,
                        );
                        // ⚠️ Le contrôleur garde l'erreur pour lui : on la fait remonter
                        final etat = ref.read(debtControllerProvider(entrepriseId));
                        if (etat.hasError) throw etat.error!;
                        if (surplus > 0) {
                          final envoye = await CompteClientService.depot(
                            entrepriseId: entrepriseId,
                            telephone: dette.telephone,
                            nom: dette.nomTiers,
                            montant: surplus,
                            methode: modePaiementSelectionne.name.toLowerCase().contains('mobile')
                                ? 'Mobile Money'
                                : 'Espèces',
                          );
                          messenger.showSnackBar(SnackBar(
                            content: Text(
                              t.debtSettled('${surplus.toStringAsFixed(2)} $currency', dette.nomTiers) +
                                  (envoye ? '' : t.debtPendingNet),
                            ),
                            backgroundColor: Colors.teal.shade700,
                          ));
                        } else {
                          messenger.showSnackBar(SnackBar(
                            content: Text(t.debtPaymentSaved('${paye.toStringAsFixed(2)} $currency')),
                            backgroundColor: Colors.green.shade700,
                          ));
                        }
                      } catch (e) {
                        messenger.showSnackBar(SnackBar(
                          content: Text(t.errorPrefix('$e')),
                          backgroundColor: Colors.red.shade700,
                        ));
                      }
                    },
              child: Text(t.debtValidatePayment,
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}