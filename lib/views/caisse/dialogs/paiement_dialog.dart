import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:stockly_saas/models/payment_method.dart';
import 'package:stockly_saas/providers/cart_provider.dart';
import 'package:stockly_saas/providers/currency_provider.dart';
import 'package:stockly_saas/providers/entreprise_provider.dart';
import 'package:stockly_saas/services/accounting_journal_service.dart';
import 'package:stockly_saas/services/receipt_service.dart';
import 'package:stockly_saas/utils/payment_calculator.dart';

class PaiementDialog extends ConsumerStatefulWidget {
  final double total;
  final List<CartItem> cart;
  final String entrepriseId;
  final String userId;

  const PaiementDialog({
    super.key,
    required this.total,
    required this.cart,
    required this.entrepriseId,
    required this.userId,
  });

  @override
  ConsumerState<PaiementDialog> createState() => _PaiementDialogState();
}

class _PaiementDialogState extends ConsumerState<PaiementDialog> {
  final _clientController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _verseUSDController = TextEditingController();
  final _verseLocalController = TextEditingController();

  String statutPaiement = 'Payé';
  String methodePaiement = 'Cash';
  String statutLivraison = 'Livré';

  bool imprimerRecu = true;
  bool envoyerWhatsApp = false;
  bool envoyerSMS = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _preremplirMontant());
  }

  @override
  void dispose() {
    _clientController.dispose();
    _telephoneController.dispose();
    _verseUSDController.dispose();
    _verseLocalController.dispose();
    super.dispose();
  }

  String _formatAmount(double amount) {
    return amount % 1 == 0 ? amount.toStringAsFixed(0) : amount.toStringAsFixed(2);
  }

  void _preremplirMontant() {
    if (!mounted) return;
    final activeInfo = ref.read(currencyProvider).activeCurrencyInfo;

    if (statutPaiement == 'Payé') {
      if (activeInfo.code == 'USD') {
        _verseUSDController.text = widget.total.toStringAsFixed(2);
        _verseLocalController.clear();
      } else {
        final totalLocal = widget.total * activeInfo.rateToUSD;
        _verseLocalController.text = _formatAmount(totalLocal);
        _verseUSDController.clear();
      }
    } else if (statutPaiement == 'Dette') {
      _verseUSDController.text = '0.0';
      _verseLocalController.clear();
    }
  }

  void _onMontantChanged(double rate) {
    final paidUSD = double.tryParse(_verseUSDController.text.trim()) ?? 0.0;
    final paidLocal = double.tryParse(_verseLocalController.text.trim()) ?? 0.0;
    final totalPayeUSD = paidUSD + (rate > 0 ? paidLocal / rate : 0.0);

    setState(() {
      if (totalPayeUSD >= widget.total - 0.001) {
        statutPaiement = 'Payé';
      } else if (totalPayeUSD > 0) {
        statutPaiement = 'Acompte';
      } else {
        statutPaiement = 'Dette';
      }
    });
  }

  void _payerToutUSD() {
    setState(() {
      _verseUSDController.text = widget.total.toStringAsFixed(2);
      _verseLocalController.clear();
      statutPaiement = 'Payé';
    });
  }

  void _payerToutLocal(double rate) {
    setState(() {
      _verseLocalController.text = _formatAmount(widget.total * rate);
      _verseUSDController.clear();
      statutPaiement = 'Payé';
    });
  }

  void _completerResteLocal(PaymentResult calc, double rate) {
    if (calc.remainingUSD <= 0) return;
    setState(() {
      _verseLocalController.text = _formatAmount(calc.remainingUSD * rate);
      statutPaiement = 'Payé';
    });
  }

  PaymentMethod _parsePaymentMethod(String method) {
    switch (method.toLowerCase()) {
      case 'carte bancaire':
      case 'virement':
      case 'banque':
        return PaymentMethod.bank;
      case 'mobile money':
        return PaymentMethod.mobileMoney;
      case 'dette':
        return PaymentMethod.credit;
      case 'cash':
      default:
        return PaymentMethod.cash;
    }
  }

  Future<void> _envoyerNotificationMessage({
    required String telephone,
    required String message,
    required bool viaWhatsApp,
  }) async {
    final cleanPhone = telephone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (cleanPhone.isEmpty) return;

    final Uri uri = viaWhatsApp
        ? Uri.parse('https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}')
        : Uri.parse('sms:$cleanPhone?body=${Uri.encodeComponent(message)}');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("Impossible d'ouvrir l'application de message : $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyState = ref.watch(currencyProvider);
    final activeInfo = currencyState.activeCurrencyInfo;

    final paidUSD = double.tryParse(_verseUSDController.text.trim()) ?? 0.0;
    final paidLocal = double.tryParse(_verseLocalController.text.trim()) ?? 0.0;

    final calc = PaymentResult(
      totalUSD: widget.total,
      paidUSD: paidUSD,
      paidLocal: paidLocal,
      localRate: activeInfo.rateToUSD,
    );

    final eqUSDinLocal = paidUSD * activeInfo.rateToUSD;
    final eqLocalinUSD = activeInfo.rateToUSD > 0 ? paidLocal / activeInfo.rateToUSD : 0.0;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.90,
          maxWidth: 480,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // EN-TÊTE FIXE
              Row(
                children: [
                  const Icon(Icons.point_of_sale, color: Colors.teal),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Finaliser la vente & Règlement',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Divider(height: 16),

              // CONTENU DÉFILABLE
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // INFORMATIONS CLIENT
                      TextField(
                        controller: _clientController,
                        decoration: InputDecoration(
                          labelText: 'Nom du Client',
                          prefixIcon: const Icon(Icons.person_outline, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _telephoneController,
                        decoration: InputDecoration(
                          labelText: 'Téléphone (ex: +243...)',
                          hintText: '+243...',
                          prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 10),

                      // MOYEN ET STATUT DE PAIEMENT
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: methodePaiement,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: 'Moyen',
                                prefixIcon: const Icon(Icons.payment, size: 18),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                              ),
                              items: ['Cash', 'Mobile Money', 'Carte bancaire', 'Virement']
                                  .map((m) => DropdownMenuItem(
                                        value: m,
                                        child: Text(m, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                                      ))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => methodePaiement = val);
                              },
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: statutPaiement,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: 'Statut',
                                prefixIcon: const Icon(Icons.rule_folder_outlined, size: 18),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                              ),
                              items: ['Payé', 'Dette', 'Acompte']
                                  .map((s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(s, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                                      ))
                                  .toList(),
                              onChanged: (val) {
                                if (val == null) return;
                                setState(() {
                                  statutPaiement = val;
                                  _preremplirMontant();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // SECTION SAISIE MULTI-DEVISES
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.teal.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total Facture :', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                Flexible(
                                  child: Text(
                                    currencyState.formatPrice(widget.total),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Colors.teal.shade900,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 12),

                            // BOUTONS D'ACTION RAPIDE
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                ActionChip(
                                  avatar: const Icon(Icons.attach_money, size: 15, color: Colors.teal),
                                  label: const Text('Tout en \$', style: TextStyle(fontSize: 11)),
                                  onPressed: _payerToutUSD,
                                  backgroundColor: Colors.white,
                                  padding: EdgeInsets.zero,
                                ),
                                if (activeInfo.code != 'USD') ...[
                                  ActionChip(
                                    avatar: const Icon(Icons.currency_exchange, size: 15, color: Colors.teal),
                                    label: Text('Tout en ${activeInfo.code}', style: const TextStyle(fontSize: 11)),
                                    onPressed: () => _payerToutLocal(activeInfo.rateToUSD),
                                    backgroundColor: Colors.white,
                                    padding: EdgeInsets.zero,
                                  ),
                                  if (calc.remainingUSD > 0 && paidUSD > 0)
                                    ActionChip(
                                      avatar: const Icon(Icons.add_card, size: 15, color: Colors.orange),
                                      label: Text('Reste en ${activeInfo.code}', style: const TextStyle(fontSize: 11)),
                                      onPressed: () => _completerResteLocal(calc, activeInfo.rateToUSD),
                                      backgroundColor: Colors.orange.shade50,
                                      padding: EdgeInsets.zero,
                                    ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Saisie dynamique USD
                            TextField(
                              controller: _verseUSDController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: 'Montant Perçu (USD)',
                                prefixText: '\$ ',
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                helperText: paidUSD > 0 && activeInfo.code != 'USD'
                                    ? '≈ ${_formatAmount(eqUSDinLocal)} ${activeInfo.symbol}'
                                    : null,
                                helperStyle: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                              onChanged: (_) => _onMontantChanged(activeInfo.rateToUSD),
                            ),
                            const SizedBox(height: 8),

                            // Saisie dynamique Devise Locale
                            if (activeInfo.code != 'USD') ...[
                              TextField(
                                controller: _verseLocalController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  labelText: 'Montant Perçu (${activeInfo.code})',
                                  suffixText: activeInfo.symbol,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  helperText: paidLocal > 0
                                      ? '≈ \$ ${eqLocalinUSD.toStringAsFixed(2)}'
                                      : null,
                                  helperStyle: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 11),
                                ),
                                onChanged: (_) => _onMontantChanged(activeInfo.rateToUSD),
                              ),
                              const SizedBox(height: 8),
                            ],

                            // RÉSUMÉ RESTE / MONNAIE À RENDRE
                            if (!calc.isFullyPaid) ...[
                              Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  const Text('Reste dû :', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                                  Text(
                                    '${calc.remainingUSD.toStringAsFixed(2)} \$ (${_formatAmount(calc.remainingUSD * activeInfo.rateToUSD)} ${activeInfo.symbol})',
                                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ],
                              ),
                            ] else ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Monnaie à rendre (USD) :', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600, fontSize: 12)),
                                  Text(
                                    '\$ ${calc.changeInUSD.toStringAsFixed(2)}',
                                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ],
                              ),
                              if (activeInfo.code != 'USD')
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Monnaie à rendre (${activeInfo.code}) :', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600, fontSize: 12)),
                                    Text(
                                      '${_formatAmount(calc.changeInLocal)} ${activeInfo.symbol}',
                                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ],
                                ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // STATUT LIVRAISON
                      DropdownButtonFormField<String>(
                        initialValue: statutLivraison,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Livraison',
                          prefixIcon: const Icon(Icons.local_shipping_outlined, size: 18),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        ),
                        items: ['Livré', 'Non livré']
                            .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13))))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => statutLivraison = val);
                        },
                      ),
                      const Divider(height: 16),

                      // CHECKBOXES
                      const Text('Actions pour le reçu :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      CheckboxListTile(
                        title: const Text('Imprimer le reçu thermique', style: TextStyle(fontSize: 12)),
                        value: imprimerRecu,
                        activeColor: Colors.teal.shade800,
                        onChanged: (val) => setState(() => imprimerRecu = val ?? true),
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                      CheckboxListTile(
                        title: const Text('Envoyer par WhatsApp', style: TextStyle(fontSize: 12)),
                        value: envoyerWhatsApp,
                        activeColor: Colors.teal.shade800,
                        onChanged: (val) => setState(() => envoyerWhatsApp = val ?? false),
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                      CheckboxListTile(
                        title: const Text('Envoyer par SMS', style: TextStyle(fontSize: 12)),
                        value: envoyerSMS,
                        activeColor: Colors.teal.shade800,
                        onChanged: (val) => setState(() => envoyerSMS = val ?? false),
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // BOUTONS D'ACTION FIXES
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Annuler'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: isLoading ? null : () => _validerVente(calc),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade800,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Valider & Encaisser', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= ENREGISTREMENT ET COMPTABILISATION =================
  Future<void> _validerVente(PaymentResult calc) async {
    setState(() => isLoading = true);

    try {
      final double totalVente = widget.total;
      final double verseEffective = calc.totalPaidInUSD > totalVente
          ? totalVente
          : (calc.totalPaidInUSD < 0 ? 0.0 : calc.totalPaidInUSD);
      final double resteEffective = calc.remainingUSD > 0 ? calc.remainingUSD : 0.0;

      final String client = _clientController.text.trim().isEmpty
          ? 'Client Divers'
          : _clientController.text.trim();
      final String telephone = _telephoneController.text.trim();

      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      final Timestamp now = Timestamp.now();

      // 1. Enregistrement de la Vente
      final venteRef = firestore
          .collection('entreprises')
          .doc(widget.entrepriseId)
          .collection('ventes')
          .doc();

      batch.set(venteRef, {
        'id': venteRef.id,
        'nomClient': client,
        'telephoneClient': telephone,
        'montantTotal': totalVente,
        'montantPaye': calc.totalPaidInUSD,
        'montantPayeUSD': calc.paidUSD,
        'montantPayeLocal': calc.paidLocal,
        'monnaieRendueUSD': calc.changeInUSD,
        'monnaieRendueLocal': calc.changeInLocal,
        'tauxEchange': calc.localRate,
        'resteAPayer': resteEffective,
        'statutPaiement': verseEffective >= totalVente
            ? 'Payé'
            : (verseEffective > 0 ? 'Acompte' : 'Dette'),
        'statutLivraison': statutLivraison,
        'methodePaiement': methodePaiement,
        'vendeurId': widget.userId,
        'entrepriseId': widget.entrepriseId,
        'comptabilise': true,
        'articles': widget.cart
            .map((item) => {
                  'produitId': item.id,
                  'nom': item.nom,
                  'prixUnitaire': item.prix,
                  'quantite': item.quantite,
                  'totalItem': item.prix * item.quantite,
                })
            .toList(),
        'createdAt': now,
        'date': now,
      });

      // 2. Écriture Comptable (SYSCOHADA)
      final ecritureRef = firestore
          .collection('entreprises')
          .doc(widget.entrepriseId)
          .collection('ecritures_comptables')
          .doc();

      final pMethod = _parsePaymentMethod(methodePaiement);
      final String codeTresorerie = AccountingJournalService.getAccountCodeForPayment(pMethod);

      final List<Map<String, dynamic>> lines = [];

      if (verseEffective > 0) {
        lines.add({
          'accountCode': codeTresorerie,
          'accountLabel': AccountingJournalService.getAccountLabel(codeTresorerie),
          'debit': verseEffective,
          'credit': 0.0,
        });
      }

      if (resteEffective > 0) {
        lines.add({
          'accountCode': '411000',
          'accountLabel': 'Client (Créance) - $client',
          'debit': resteEffective,
          'credit': 0.0,
        });
      }

      lines.add({
        'accountCode': '701000',
        'accountLabel': AccountingJournalService.getAccountLabel('701000'),
        'debit': 0.0,
        'credit': totalVente,
      });

      batch.set(ecritureRef, {
        'id': ecritureRef.id,
        'entrepriseId': widget.entrepriseId,
        'reference': venteRef.id,
        'description': 'Facture de vente - $client',
        'date': now,
        'lines': lines,
        'montantEncaisse': verseEffective,
      });

      // 3. Enregistrement Créance (si reste > 0)
      if (resteEffective > 0) {
        final creanceRef = firestore
            .collection('entreprises')
            .doc(widget.entrepriseId)
            .collection('creances')
            .doc();

        batch.set(creanceRef, {
          'id': creanceRef.id,
          'venteId': venteRef.id,
          'numeroFacture': venteRef.id.substring(0, 8).toUpperCase(),
          'nomTiers': client,
          'nomClient': client,
          'telephone': telephone,
          'montantInitial': totalVente,
          'acomptePaye': verseEffective,
          'montantReste': resteEffective,
          'type': 'client',
          'statut': verseEffective > 0 ? 'partiel' : 'non_paye',
          'note': 'Créance issue de la vente #${venteRef.id.substring(0, 6)}',
          'entrepriseId': widget.entrepriseId,
          'comptabilise': true,
          'createdAt': now,
          'dateCreation': now,
        });
      }

      // 4. Décrémentation directe des stocks en Batch
      for (final item in widget.cart) {
        final prodRef = firestore
            .collection('entreprises')
            .doc(widget.entrepriseId)
            .collection('produits')
            .doc(item.id);

        batch.update(prodRef, {
          'quantite': FieldValue.increment(-item.quantite),
          'updatedAt': now,
        });
      }

      await batch.commit();

      if (!mounted) return;

      ref.read(cartProvider.notifier).clearCart();
      final entreprise = ref.read(entrepriseProvider);
      final currencyState = ref.read(currencyProvider);
      final activeInfo = currencyState.activeCurrencyInfo;

      final double totalAffiche = totalVente * activeInfo.rateToUSD;
      final double payeAffiche = calc.totalPaidInUSD * activeInfo.rateToUSD;
      final double resteAffiche = resteEffective * activeInfo.rateToUSD;

      // 5. Impression Reçu Thermique (avec conversion préalable des articles)
      if (imprimerRecu) {
        final articlesConvertis = widget.cart.map((item) {
          return CartItem(
            id: item.id,
            nom: item.nom,
            prix: item.prix * activeInfo.rateToUSD,
            quantite: item.quantite,
            stock: item.stock,
          );
        }).toList();

        await ReceiptService.imprimerTicket(
          nomBoutique: entreprise.nom,
          adresseBoutique: entreprise.adresse,
          phoneBoutique: entreprise.telephone,
          nomClient: client,
          articles: articlesConvertis,
          total: totalAffiche,
          paye: payeAffiche,
          reste: resteAffiche,
          monnaie: activeInfo.symbol,
        );
      }

      if (!mounted) return;

      // 6. Notifications WhatsApp / SMS
      final String msgText =
          "Bonjour $client, votre achat chez ${entreprise.nom} s'élève à ${currencyState.formatPrice(totalVente)}. "
          "Payé: ${currencyState.formatPrice(verseEffective)}. Reste: ${currencyState.formatPrice(resteEffective)}. Merci !";

      if (envoyerWhatsApp && telephone.isNotEmpty) {
        await _envoyerNotificationMessage(
          telephone: telephone,
          message: msgText,
          viaWhatsApp: true,
        );
      }

      if (envoyerSMS && telephone.isNotEmpty) {
        await _envoyerNotificationMessage(
          telephone: telephone,
          message: msgText,
          viaWhatsApp: false,
        );
      }

      if (!mounted) return;

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vente enregistrée avec succès !'),
          backgroundColor: Colors.teal,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la validation : $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }
}