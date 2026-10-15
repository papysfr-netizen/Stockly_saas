import 'package:flutter/material.dart';

import 'package:stockly_saas/core/services/imprimante_reglages.dart';
import 'package:stockly_saas/core/services/receipt_service.dart';
import 'package:stockly_saas/l10n/app_localizations.dart';

/// 🖨️ Carte « Imprimante » des Paramètres (visible par tout le monde).
class ImprimanteCard extends StatefulWidget {
  const ImprimanteCard({super.key});

  @override
  State<ImprimanteCard> createState() => _ImprimanteCardState();
}

class _ImprimanteCardState extends State<ImprimanteCard> {
  ReglagesImprimante _reglages = const ReglagesImprimante();
  bool _essaiEnCours = false;

  @override
  void initState() {
    super.initState();
    ReglagesImprimante.charger().then((r) {
      if (mounted) setState(() => _reglages = r);
    });
  }

  Future<void> _changer(ReglagesImprimante r) async {
    setState(() => _reglages = r);
    await r.enregistrer();
  }

  Future<void> _essai() async {
    if (_essaiEnCours) return;
    final messenger = ScaffoldMessenger.of(context);
    final t = AppLocalizations.of(context);
    setState(() => _essaiEnCours = true);
    try {
      await ReceiptService.imprimerTicket(
        nomBoutique: 'Stockly Pro',
        nomClient: "Reçu d'essai",
        articles: const [
          {'nom': 'Article essai 1', 'quantite': 2, 'prix': 5.0},
          {'nom': 'Article essai 2', 'quantite': 1, 'prix': 12.5},
        ],
        total: 22.5,
        paye: 25.0,
        reste: -2.5,
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text(t.printFailed('$e')),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) setState(() => _essaiEnCours = false);
    }
  }

  Widget _choixMode(String valeur, IconData icone, String titre, String detail) {
    final choisi = _reglages.mode == valeur;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        choisi ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: choisi ? Colors.indigo : Colors.grey,
      ),
      title: Row(
        children: [
          Icon(icone, size: 18, color: Colors.indigo.shade300),
          const SizedBox(width: 6),
          Expanded(child: Text(titre)),
        ],
      ),
      subtitle: Text(detail, style: const TextStyle(fontSize: 12)),
      onTap: () => _changer(_reglages.copyWith(mode: valeur)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.print_rounded, color: Colors.indigo.shade400),
                const SizedBox(width: 8),
                Text(
                  t.printerTitle,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              t.printerPhoneOnly,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const SizedBox(height: 16),
            Text(t.printerPaperWidth),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<int>(
                segments: [
                  ButtonSegment(value: 58, label: Text(t.printer58)),
                  ButtonSegment(value: 80, label: Text(t.printer80)),
                ],
                selected: {_reglages.papierMm},
                onSelectionChanged: (v) =>
                    _changer(_reglages.copyWith(papierMm: v.first)),
              ),
            ),
            const SizedBox(height: 16),
            Text(t.printerAfterSale),
            _choixMode(
              'android',
              Icons.print_outlined,
              t.printerPrints,
              t.printerPrintsHint,
            ),
            _choixMode(
              'partager',
              Icons.share_rounded,
              t.printerPdf,
              t.printerPdfHint,
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: _essaiEnCours ? null : _essai,
                icon: _essaiEnCours
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.receipt_long_rounded),
                label: Text(t.printerTest),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
