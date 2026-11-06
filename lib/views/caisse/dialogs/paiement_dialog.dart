// lib/views/caisse/dialogs/paiement_dialog.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stockly_saas/core/services/journal_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:stockly_saas/core/models/payment_method.dart';
import 'package:stockly_saas/core/providers/cart_provider.dart';
import 'package:stockly_saas/features/boutiques/boutique_provider.dart';
import 'package:stockly_saas/core/providers/currency_provider.dart';
import 'package:stockly_saas/core/providers/entreprise_provider.dart';
import 'package:stockly_saas/features/accounting/services/accounting_journal_service.dart';
import 'package:stockly_saas/features/comptes_clients/compte_client_service.dart';
import 'package:stockly_saas/core/services/receipt_service.dart';
import 'package:stockly_saas/core/utils/payment_calculator.dart';
import 'package:stockly_saas/l10n/app_localizations.dart';
import 'package:stockly_saas/core/services/messages_clients.dart';

// Import de ton écran de Bon de Livraison professionnel
import '../../../screens/bon_livraison_screen.dart';
import '../../../core/services/utilisateur_service.dart';

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
  /// 🏬 Boutique de la vente (patron sur « Toutes les boutiques » = boutique principale)
  String get _boutiqueVente => ref.read(boutiqueActiveProvider) ?? 'principale';

  final _clientController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _verseUSDController = TextEditingController();
  final _verseLocalController = TextEditingController();
  final _motifController = TextEditingController(); // 📝 motif du crédit

  String statutPaiement = 'Payé';
  String methodePaiement = 'Cash';
  // 🚚 Valeurs enregistrées : 'Livré' ou 'Non livré' (affichées autrement à l'écran)
  String statutLivraison = 'Livré';
  // ⏰ Délai de retrait (en jours) pour les ventes à livrer plus tard
  int delaiRetraitJours = 7;

  bool imprimerRecu = true;
  bool envoyerWhatsApp = false;
  bool envoyerSMS = false;
  String? _langueMessage; // langue du message au client (null = langue de l'application)
  bool isLoading = false;

  // 💰 Compte client (dépôts / avoirs)
  Timer? _rechercheTimer;
  bool _rechercheEnCours = false;
  double _soldeCompte = 0.0;
  bool _utiliserSolde = false;

  /// Part de la facture payée par le compte client (en USD).
  double get _montantSoldeUtilise {
    if (!_utiliserSolde || _soldeCompte <= 0) return 0.0;
    return _soldeCompte < widget.total ? _soldeCompte : widget.total;
  }

  /// Ce qu'il reste à encaisser (espèces, Mobile Money…) après le compte client.
  double get _totalAPayer {
    final t = widget.total - _montantSoldeUtilise;
    return t > 0 ? t : 0.0;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(_preremplirMontant);
    });
  }

  @override
  void dispose() {
    _rechercheTimer?.cancel();
    _clientController.dispose();
    _telephoneController.dispose();
    _verseUSDController.dispose();
    _verseLocalController.dispose();
    _motifController.dispose();
    super.dispose();
  }

  String _formatAmount(double amount) {
    return amount % 1 == 0 ? amount.toStringAsFixed(0) : amount.toStringAsFixed(2);
  }

  String _formatJour(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  void _preremplirMontant() {
    if (!mounted) return;
    final activeInfo = ref.read(currencyProvider).activeCurrencyInfo;
    final aPayer = _totalAPayer;

    if (aPayer <= 0.001) {
      // Tout est payé par le compte client
      _verseUSDController.clear();
      _verseLocalController.clear();
      statutPaiement = 'Payé';
      return;
    }

    if (statutPaiement == 'Payé') {
      if (activeInfo.code == 'USD') {
        _verseUSDController.text = aPayer.toStringAsFixed(2);
        _verseLocalController.clear();
      } else {
        final totalLocal = aPayer * activeInfo.rateToUSD;
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
    final totalPayeUSD = paidUSD + (rate > 0 ? paidLocal / rate : 0.0) + _montantSoldeUtilise;

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
      _verseUSDController.text = _totalAPayer.toStringAsFixed(2);
      _verseLocalController.clear();
      statutPaiement = 'Payé';
    });
  }

  void _payerToutLocal(double rate) {
    setState(() {
      _verseLocalController.text = _formatAmount(_totalAPayer * rate);
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

  // 💰 Recherche du compte client quand on tape le téléphone
  void _onTelephoneChanged(String tel) {
    _rechercheTimer?.cancel();
    if (!CompteClientService.telephoneValide(tel)) {
      if (_soldeCompte != 0 || _utiliserSolde) {
        setState(() {
          _soldeCompte = 0.0;
          _utiliserSolde = false;
          _preremplirMontant();
        });
      }
      return;
    }
    _rechercheTimer = Timer(const Duration(milliseconds: 600), () async {
      if (!mounted) return;
      setState(() => _rechercheEnCours = true);
      final compte = await CompteClientService.lireCompte(widget.entrepriseId, tel);
      if (!mounted) return;
      final brut = compte?['solde'];
      final solde = brut is num ? brut.toDouble() : 0.0;
      final nom = (compte?['nom'] ?? '').toString();
      setState(() {
        _rechercheEnCours = false;
        _soldeCompte = solde > 0 ? solde : 0.0;
        _utiliserSolde = _soldeCompte > 0.005; // 💳 allumé par défaut si le client a un solde
        if (_clientController.text.trim().isEmpty && nom.isNotEmpty) {
          _clientController.text = nom;
        }
        _preremplirMontant();
      });
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
      totalUSD: _totalAPayer,
      paidUSD: paidUSD,
      paidLocal: paidLocal,
      localRate: activeInfo.rateToUSD,
    );

    final eqUSDinLocal = paidUSD * activeInfo.rateToUSD;
    final eqLocalinUSD = activeInfo.rateToUSD > 0 ? paidLocal / activeInfo.rateToUSD : 0.0;

    final dateLimiteApercu = DateTime.now().add(Duration(days: delaiRetraitJours));
    final soldeUtilise = _montantSoldeUtilise;
    final t = AppLocalizations.of(context);

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
                      t.payTitle,
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
                          labelText: t.payClientName,
                          prefixIcon: const Icon(Icons.person_outline, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _telephoneController,
                        onChanged: _onTelephoneChanged,
                        decoration: InputDecoration(
                          labelText: t.payPhone,
                          hintText: '+243...',
                          prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      if (_rechercheEnCours)
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: LinearProgressIndicator(minHeight: 2),
                        ),

                      // 💰 COMPTE CLIENT
                      if (_soldeCompte > 0.005)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.fromLTRB(10, 6, 4, 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF16302A) : Colors.green.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.green.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.account_balance_wallet,
                                      color: Colors.green.shade800, size: 20),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      t.payClientAccount(currencyState.formatPrice(_soldeCompte)),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade900,
                                      ),
                                    ),
                                  ),
                                  Text(t.payUse, style: const TextStyle(fontSize: 12)),
                                  Switch(
                                    value: _utiliserSolde,
                                    activeThumbColor: Colors.green.shade700,
                                    onChanged: (v) => setState(() {
                                      _utiliserSolde = v;
                                      statutPaiement = 'Payé';
                                      _preremplirMontant();
                                    }),
                                  ),
                                ],
                              ),
                              if (_utiliserSolde)
                                Text(
                                  t.payPaidByAccount(currencyState.formatPrice(soldeUtilise),
                                      currencyState.formatPrice(_soldeCompte - soldeUtilise)),
                                  style: TextStyle(fontSize: 12, color: Colors.green.shade900),
                                ),
                            ],
                          ),
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
                                labelText: t.payMethod,
                                prefixIcon: const Icon(Icons.payment, size: 18),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                              ),
                              items: ['Cash', 'Mobile Money', 'Carte bancaire', 'Virement']
                                  .map((m) => DropdownMenuItem(
                                        value: m,
                                        child: Text(m == 'Cash' ? t.payCash : m == 'Carte bancaire' ? t.payCard : m == 'Virement' ? t.payTransfer : m, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
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
                              key: ValueKey('statut_$statutPaiement'),
                              initialValue: statutPaiement,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: t.payStatus,
                                prefixIcon: const Icon(Icons.rule_folder_outlined, size: 18),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                              ),
                              items: ['Payé', 'Dette', 'Acompte']
                                  .map((s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(s == 'Acompte' ? t.payPartial : (s == 'Dette' ? t.payDebt : t.payPaid), style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
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
                          color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF143533) : Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.teal.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(t.payInvoiceTotal, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
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
                            if (soldeUtilise > 0.005) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(t.payPaidByClientAccount,
                                      style: TextStyle(fontSize: 12, color: Colors.green.shade800)),
                                  Text('- ${currencyState.formatPrice(soldeUtilise)}',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green.shade800)),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(t.payToCollect,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                  Text(currencyState.formatPrice(_totalAPayer),
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                            const Divider(height: 12),

                            // BOUTONS D'ACTION RAPIDE
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                ActionChip(
                                  avatar: const Icon(Icons.attach_money, size: 15, color: Colors.teal),
                                  label: Text(t.payAllIn('\$'), style: const TextStyle(fontSize: 11)),
                                  onPressed: _payerToutUSD,
                                  backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF22262E) : Colors.white,
                                  padding: EdgeInsets.zero,
                                ),
                                if (activeInfo.code != 'USD') ...[
                                  ActionChip(
                                    avatar: const Icon(Icons.currency_exchange, size: 15, color: Colors.teal),
                                    label: Text(t.payAllIn(activeInfo.code), style: const TextStyle(fontSize: 11)),
                                    onPressed: () => _payerToutLocal(activeInfo.rateToUSD),
                                    backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF22262E) : Colors.white,
                                    padding: EdgeInsets.zero,
                                  ),
                                  if (calc.remainingUSD > 0 && paidUSD > 0)
                                    ActionChip(
                                      avatar: const Icon(Icons.add_card, size: 15, color: Colors.orange),
                                      label: Text(t.payRestIn(activeInfo.code), style: const TextStyle(fontSize: 11)),
                                      onPressed: () => _completerResteLocal(calc, activeInfo.rateToUSD),
                                      backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF3A2A14) : Colors.orange.shade50,
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
                                labelText: t.payReceived('USD'),
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
                                  labelText: t.payReceived(activeInfo.code),
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
                                  Text(t.payRemaining, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
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
                                  Text(t.payChange('USD'), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600, fontSize: 12)),
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
                                    Text(t.payChange(activeInfo.code), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600, fontSize: 12)),
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

                      // 📝 MOTIF DU CRÉDIT (seulement si le client ne paie pas tout)
                      if (!calc.isFullyPaid) ...[
                        TextField(
                          controller: _motifController,
                          textCapitalization: TextCapitalization.sentences,
                          minLines: 1,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: t.payMotif,
                            hintText: t.payMotifHint,
                            prefixIcon: const Icon(Icons.notes_rounded, size: 18),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],

                      // 🚚 STATUT LIVRAISON
                      DropdownButtonFormField<String>(
                        initialValue: statutLivraison,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: t.payDelivery,
                          prefixIcon: Icon(
                            statutLivraison == 'Livré'
                                ? Icons.check_circle_outline
                                : Icons.local_shipping_outlined,
                            size: 18,
                            color: statutLivraison == 'Livré' ? Colors.teal : Colors.orange.shade800,
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'Livré',
                            child: Text(t.payDeliveredNow, style: const TextStyle(fontSize: 13)),
                          ),
                          DropdownMenuItem(
                            value: 'Non livré',
                            child: Text(t.payDeliverLater, style: const TextStyle(fontSize: 13)),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => statutLivraison = val);
                        },
                      ),

                      // ⏰ DÉLAI DE RETRAIT (seulement si à livrer plus tard)
                      if (statutLivraison == 'Non livré') ...[
                        const SizedBox(height: 10),
                        DropdownButtonFormField<int>(
                          initialValue: delaiRetraitJours,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: t.payPickupBefore,
                            prefixIcon: Icon(Icons.event, size: 18, color: Colors.orange.shade800),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            helperText:
                                t.payDeadline(_formatJour(dateLimiteApercu)),
                            helperMaxLines: 2,
                            helperStyle: TextStyle(color: Colors.orange.shade800, fontSize: 11),
                          ),
                          items: const [1, 3, 7, 14, 30]
                              .map((j) => DropdownMenuItem(
                                    value: j,
                                    child: Text(
                                      t.payDays(j),
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => delaiRetraitJours = val);
                          },
                        ),
                      ],
                      const Divider(height: 16),

                      // CHECKBOXES
                      Text(t.payReceiptActions, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      CheckboxListTile(
                        title: Text(t.payPrintReceipt, style: const TextStyle(fontSize: 12)),
                        value: imprimerRecu,
                        activeColor: Colors.teal.shade800,
                        onChanged: (val) => setState(() => imprimerRecu = val ?? true),
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                      CheckboxListTile(
                        title: Text(t.paySendWhatsApp, style: const TextStyle(fontSize: 12)),
                        value: envoyerWhatsApp,
                        activeColor: Colors.teal.shade800,
                        onChanged: (val) => setState(() => envoyerWhatsApp = val ?? false),
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                      CheckboxListTile(
                        title: Text(t.paySendSms, style: const TextStyle(fontSize: 12)),
                        value: envoyerSMS,
                        activeColor: Colors.teal.shade800,
                        onChanged: (val) => setState(() => envoyerSMS = val ?? false),
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                      if (envoyerWhatsApp || envoyerSMS)
                        LangueMessageChoix(
                          valeur: _langueMessage ?? Localizations.localeOf(context).languageCode,
                          onChanged: (v) => setState(() => _langueMessage = v),
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
                    child: Text(t.cancel),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: isLoading ? null : _validerVente,
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
                        : Text(t.payValidate, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= LECTURE DES PRIX D'ACHAT =================

  Future<DocumentSnapshot<Map<String, dynamic>>?> _lireDoc(
    DocumentReference<Map<String, dynamic>> ref,
  ) async {
    try {
      return await ref.get().timeout(const Duration(seconds: 3));
    } catch (_) {
      try {
        return await ref.get(const GetOptions(source: Source.cache));
      } catch (_) {
        return null;
      }
    }
  }

  Future<Map<String, double>> _chargerPrixAchat(FirebaseFirestore firestore) async {
    final ids = widget.cart.map((item) => item.id).toSet().toList();

    Future<MapEntry<String, double>> lirePrix(String id) async {
      final ref = firestore
          .collection('entreprises')
          .doc(widget.entrepriseId)
          .collection('produits')
          .doc(id);

      DocumentSnapshot<Map<String, dynamic>>? doc;
      try {
        doc = await ref.get(const GetOptions(source: Source.cache));
      } catch (_) {
        doc = null;
      }
      if (doc == null || !doc.exists) {
        doc = await _lireDoc(ref);
      }

      final valeur = doc?.data()?['prixAchat'];
      final double prix = valeur is num ? valeur.toDouble() : 0.0;
      if (prix <= 0) {
        debugPrint('[Stockly] Prix d\'achat inconnu pour le produit $id : coût compté à 0');
      }
      return MapEntry(id, prix);
    }

    final resultats = await Future.wait(ids.map(lirePrix));
    return Map.fromEntries(resultats);
  }

  // ================= ENREGISTREMENT ET COMPTABILISATION =================
  Future<void> _validerVente() async {
    setState(() => isLoading = true);
    final t = AppLocalizations.of(context);
    final langueMsg = _langueMessage ?? Localizations.localeOf(context).languageCode;

    final activeInfoValidation = ref.read(currencyProvider).activeCurrencyInfo;
    final double soldeUtilise = _montantSoldeUtilise;
    final calc = PaymentResult(
      totalUSD: _totalAPayer,
      paidUSD: double.tryParse(_verseUSDController.text.trim()) ?? 0.0,
      paidLocal: double.tryParse(_verseLocalController.text.trim()) ?? 0.0,
      localRate: activeInfoValidation.rateToUSD,
    );

    try {
      final String client = _clientController.text.trim().isEmpty
          ? 'Client Divers'
          : _clientController.text.trim();
      final String telephone = _telephoneController.text.trim();

      // 💰 Vérifie que le solde du compte client est toujours suffisant
      double soldeAvant = _soldeCompte;
      if (soldeUtilise > 0.005) {
        soldeAvant = await CompteClientService.lireSolde(widget.entrepriseId, telephone);
        if (soldeAvant < soldeUtilise - 0.005) {
          throw Exception(t.payBalanceChanged(soldeAvant.toStringAsFixed(2)));
        }
      }

      final double totalVente = widget.total;
      final double aPayer = totalVente - soldeUtilise;
      final double verseCash = calc.totalPaidInUSD > aPayer
          ? aPayer
          : (calc.totalPaidInUSD < 0 ? 0.0 : calc.totalPaidInUSD);
      final double verseEffective = verseCash + soldeUtilise;
      final double resteEffective = calc.remainingUSD > 0 ? calc.remainingUSD : 0.0;

      final String methodeEnregistree = soldeUtilise > 0.005
          ? (verseCash > 0.005 ? '$methodePaiement + Compte client' : 'Compte client')
          : methodePaiement;

      final bool estLivre = statutLivraison == 'Livré';

      final firestore = FirebaseFirestore.instance;

      final prixAchat = await _chargerPrixAchat(firestore);
      double coutMarchandises = 0.0;
      for (final item in widget.cart) {
        coutMarchandises += (prixAchat[item.id] ?? 0.0) * item.quantite;
      }

      final vendeurNom = await nomUtilisateurConnecte();

      final batch = firestore.batch();
      final Timestamp now = Timestamp.now();

      // ⏰ Date limite de retrait (fin de journée du dernier jour)
      final DateTime limite = now.toDate().add(Duration(days: delaiRetraitJours));
      final DateTime finJourLimite =
          DateTime(limite.year, limite.month, limite.day, 23, 59, 59);

      // 1. Vente
      final venteRef = firestore
          .collection('entreprises')
          .doc(widget.entrepriseId)
          .collection('ventes')
          .doc();
      final numeroFacture = venteRef.id.substring(0, 8).toUpperCase();

      batch.set(venteRef, {
        'id': venteRef.id,
        'nomClient': client,
        'telephoneClient': telephone,
        'montantTotal': totalVente,
        'montantPaye': calc.totalPaidInUSD + soldeUtilise,
        'montantPayeUSD': calc.paidUSD,
        'montantPayeLocal': calc.paidLocal,
        'montantCompteClient': soldeUtilise,
        'monnaieRendueUSD': calc.changeInUSD,
        'monnaieRendueLocal': calc.changeInLocal,
        'tauxEchange': calc.localRate,
        'resteAPayer': resteEffective,
        'statutPaiement': verseEffective >= totalVente - 0.001
            ? 'Payé'
            : (verseEffective > 0 ? 'Acompte' : 'Dette'),
        'statutLivraison': statutLivraison,
        'dateLivraison': estLivre ? now : null,
        'livrePar': estLivre ? widget.userId : null,
        'dateLimiteLivraison': estLivre ? null : Timestamp.fromDate(finJourLimite),
        'methodePaiement': methodeEnregistree,
        'vendeurId': widget.userId,
        'boutiqueId': _boutiqueVente, // 🏬
        'vendeurNom': vendeurNom,
        'entrepriseId': widget.entrepriseId,
        'comptabilise': true,
        'coutMarchandises': coutMarchandises,
        // 🏷️ Remises accordées (prix négocié)
        'remiseTotale': widget.cart.fold<double>(0.0, (s, i) => s + i.remiseTotale),
        'articles': widget.cart
            .map((item) => {
                  'produitId': item.id,
                  'nom': item.nom,
                  'prixUnitaire': item.prix,
                  'prixNormal': item.prixNormal,
                  'remise': item.remiseTotale,
                  'prixAchat': prixAchat[item.id] ?? 0.0,
                  'quantite': item.quantite,
                  'totalItem': item.prix * item.quantite,
                })
            .toList(),
        'createdAt': now,
        'date': now,
      });

      // 2. Écriture comptable de la vente (SYSCOHADA)
      final ecritureRef = firestore
          .collection('entreprises')
          .doc(widget.entrepriseId)
          .collection('ecritures_comptables')
          .doc();

      final pMethod = _parsePaymentMethod(methodePaiement);
      final String codeTresorerie = AccountingJournalService.getAccountCodeForPayment(pMethod);

      final List<Map<String, dynamic>> lines = [];

      if (verseCash > 0) {
        lines.add({
          'accountCode': codeTresorerie,
          'accountLabel': AccountingJournalService.getAccountLabel(codeTresorerie),
          'debit': verseCash,
          'credit': 0.0,
        });
      }

      if (soldeUtilise > 0.005) {
        lines.add({
          'accountCode': CompteClientService.compteAvances,
          'accountLabel': '${CompteClientService.libelleAvances} - $client',
          'debit': soldeUtilise,
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
        'montantEncaisse': verseCash,
        'boutiqueId': _boutiqueVente, // 🏬 compta
      });

      // 2 bis. Coût des marchandises vendues
      if (coutMarchandises > 0) {
        final coutRef = firestore
            .collection('entreprises')
            .doc(widget.entrepriseId)
            .collection('ecritures_comptables')
            .doc('STK-${venteRef.id}');

        batch.set(coutRef, {
          'id': coutRef.id,
          'entrepriseId': widget.entrepriseId,
          'reference': venteRef.id,
          'description': 'Sortie de stock (coût des marchandises) - $client',
          'boutiqueId': _boutiqueVente, // 🏬 compta
          'date': now,
          'lines': [
            {
              'accountCode': '603100',
              'accountLabel': AccountingJournalService.getAccountLabel('603100'),
              'debit': coutMarchandises,
              'credit': 0.0,
            },
            {
              'accountCode': '311000',
              'accountLabel': AccountingJournalService.getAccountLabel('311000'),
              'debit': 0.0,
              'credit': coutMarchandises,
            },
          ],
          'montantEncaisse': 0.0,
        });
      }

      // 3. Créance (si reste > 0)
      if (resteEffective > 0) {
        final creanceRef = firestore
            .collection('entreprises')
            .doc(widget.entrepriseId)
            .collection('creances')
            .doc();

        batch.set(creanceRef, {
          'id': creanceRef.id,
          'venteId': venteRef.id,
          'boutiqueId': _boutiqueVente, // 🏬 dette
          'numeroFacture': numeroFacture,
          'nomTiers': client,
          'nomClient': client,
          'telephone': telephone,
          'montantInitial': totalVente,
          'acomptePaye': verseEffective,
          'montantReste': resteEffective,
          'type': 'client',
          'statut': verseEffective > 0 ? 'partiel' : 'non_paye',
          // 📝 Motif écrit par le vendeur (sinon la phrase automatique)
          'note': _motifController.text.trim().isNotEmpty
              ? _motifController.text.trim()
              : 'Créance issue de la vente #${venteRef.id.substring(0, 6)}',
          // 🧾 Historique : l'acompte versé à la caisse
          if (verseEffective > 0.005)
            'paiements': [
              {
                'date': now,
                'montant': verseEffective,
                'methode': methodeEnregistree,
                'parNom': vendeurNom,
                'parUid': widget.userId,
              }
            ],
          'entrepriseId': widget.entrepriseId,
          'comptabilise': true,
          'createdAt': now,
          'dateCreation': now,
        });
      }

      // 3 bis. 💰 Compte client : mouvement « Achat »
      if (soldeUtilise > 0.005) {
        CompteClientService.ajouterMouvement(
          batch,
          entrepriseId: widget.entrepriseId,
          telephone: telephone,
          nom: client == 'Client Divers' ? '' : client,
          type: 'achat',
          delta: -soldeUtilise,
          soldeAvant: soldeAvant,
          description: 'Achat facture $numeroFacture',
          date: now,
          uid: widget.userId,
          parNom: vendeurNom,
          venteId: venteRef.id,
        );
      }

      // 4. Stock (même si à livrer plus tard : la marchandise est réservée)
      for (final item in widget.cart) {
        final prodRef = firestore
            .collection('entreprises')
            .doc(widget.entrepriseId)
            .collection('produits')
            .doc(item.id);

        final b = _boutiqueVente;
        batch.update(prodRef, {
          'quantite': FieldValue.increment(-item.quantite),
          // 🏬 stock de la boutique (la principale = total − autres boutiques)
          if (b != 'principale') 'stocks.$b': FieldValue.increment(-item.quantite),
          'updatedAt': now,
        });
      }

      // ⏳ On attend la réponse du serveur (6 s maximum).
      //    Pas de réseau : la vente reste sur le téléphone et partira plus tard.
      //    Refus du serveur : on prévient clairement, rien n'est enregistré.
      try {
        await batch.commit().timeout(const Duration(seconds: 6));
        debugPrint('[Stockly] Vente ${venteRef.id} envoyée au serveur');
      } on TimeoutException {
        debugPrint('[Stockly] Vente ${venteRef.id} gardée hors ligne');
      } on FirebaseException catch (e) {
        debugPrint('[Stockly] Vente ${venteRef.id} REFUSÉE : ${e.code} ${e.message}');
        if (!mounted) return;
        setState(() => isLoading = false);
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            icon: const Icon(Icons.error_outline_rounded, color: Colors.red, size: 44),
            title: Text(t.payNotSaved),
            content: Text(
              e.code == 'permission-denied'
                  ? t.payDenied(e.code)
                  : t.payNotSavedOther('${e.code} : ${e.message ?? ''}'),
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(t.payUnderstood),
              ),
            ],
          ),
        );
        return;
      }

      // 📒 Journal « qui a fait quoi » (n'empêche jamais la vente)
      var resumeArticles =
          widget.cart.map((i) => '${i.quantite} × ${i.nom}').join(', ');
      if (resumeArticles.length > 200) {
        resumeArticles = '${resumeArticles.substring(0, 200)}…';
      }
      unawaited(noterJournal(
        entrepriseId: widget.entrepriseId,
        action: ActionsJournal.vente,
        details: 'Facture $numeroFacture · $client · $resumeArticles'
            '${resteEffective > 0.005 ? ' · crédit ${resteEffective.toStringAsFixed(2)} \$' : ''}'
            '${_montantSoldeUtilise > 0.005 ? ' · payé par compte ${_montantSoldeUtilise.toStringAsFixed(2)} \$' : ''}',
        boutiqueId: _boutiqueVente,
        montant: totalVente,
        reference: venteRef.id,
      ));

      if (!mounted) return;

      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);

      ref.read(cartProvider.notifier).clearCart();
      final entreprise = ref.read(entrepriseProvider);
      final currencyState = ref.read(currencyProvider);
      final activeInfo = currencyState.activeCurrencyInfo;

      final double totalAffiche = totalVente * activeInfo.rateToUSD;
      final double payeAffiche = (calc.totalPaidInUSD + soldeUtilise) * activeInfo.rateToUSD;
      final double resteAffiche = resteEffective * activeInfo.rateToUSD;

      Future<void> Function()? impressionEnAttente;

      // 5. Reçu thermique
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

        impressionEnAttente = () => ReceiptService.imprimerTicket(
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

      // 6. WhatsApp / SMS
      // 💬 Message au client, dans SA langue (choisie dans la fenêtre)
      final String msgText = MessagesClients.vente(
        langue: langueMsg,
        client: client,
        boutique: entreprise.nom,
        total: currencyState.formatPrice(totalVente),
        paye: currencyState.formatPrice(verseEffective),
        reste: currencyState.formatPrice(resteEffective),
        payeCompte: soldeUtilise > 0.005 ? currencyState.formatPrice(soldeUtilise) : null,
        nouveauSolde: soldeUtilise > 0.005 ? currencyState.formatPrice(soldeAvant - soldeUtilise) : null,
        retirerAvant: estLivre ? null : _formatJour(finJourLimite),
      );

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

      // 7. Fermeture
      navigator.pop();

      // 8. Bon de livraison seulement si la marchandise part maintenant
      if (estLivre) {
        navigator.push(
          MaterialPageRoute(
            builder: (context) => BonLivraisonScreen(
              entrepriseId: widget.entrepriseId,
              nomClient: client,
              adresseClient: '',
              telephoneClient: telephone,
              articles: widget.cart,
            ),
          ),
        );
      }

      final String texteCompte = soldeUtilise > 0.005
          ? t.payNewBalance(currencyState.formatPrice(soldeAvant - soldeUtilise))
          : '';
      messenger.showSnackBar(
        SnackBar(
          content: Text(estLivre
              ? '${t.paySaved}$texteCompte'
              : '${t.paySavedPickup(_formatJour(finJourLimite))}$texteCompte'),
          backgroundColor: estLivre ? Colors.teal : Colors.orange.shade800,
        ),
      );

      // 9. Impression après la fermeture
      final impression = impressionEnAttente;
      if (impression != null) {
        unawaited(impression());
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.payError(e.toString().replaceFirst('Exception: ', ''))),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
