import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/currency_provider.dart';

class CurrencySelectorWidget extends ConsumerWidget {
  final bool showRateDialogOption;

  const CurrencySelectorWidget({
    super.key,
    this.showRateDialogOption = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyState = ref.watch(currencyProvider);
    final activeInfo = currencyState.activeCurrencyInfo;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: currencyState.activeCurrency,
            icon: const Icon(Icons.arrow_drop_down, color: Colors.teal),
            items: currencyState.currencies.values.map((info) {
              return DropdownMenuItem<String>(
                value: info.code,
                child: Row(
                  children: [
                    Text(
                      info.symbol,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Text('${info.code} - ${info.name}'),
                  ],
                ),
              );
            }).toList(),
            onChanged: (code) {
              if (code != null) {
                ref.read(currencyProvider.notifier).setCurrency(code);
              }
            },
          ),
        ),
        if (showRateDialogOption && activeInfo.code != 'USD') ...[
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.edit, size: 18, color: Colors.teal),
            tooltip: 'Ajuster le taux du ${activeInfo.name}',
            onPressed: () => _showUpdateRateDialog(context, ref, activeInfo),
          ),
        ],
      ],
    );
  }

  void _showUpdateRateDialog(
    BuildContext context,
    WidgetRef ref,
    CurrencyInfo activeInfo,
  ) {
    // Calcule dynamiquement le format sans dépendre de 'hasDecimals'
    final initialRateText = activeInfo.rateToUSD == activeInfo.rateToUSD.truncateToDouble()
        ? activeInfo.rateToUSD.toStringAsFixed(0)
        : activeInfo.rateToUSD.toStringAsFixed(2);

    final rateController = TextEditingController(text: initialRateText);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Taux de change (USD → ${activeInfo.code})'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ajuster le taux officiel / marché pour ${activeInfo.name} :',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: rateController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: '1 USD = ? ${activeInfo.code}',
                border: const OutlineInputBorder(),
                suffixText: activeInfo.symbol,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final newRate = double.tryParse(rateController.text.trim());
              if (newRate != null && newRate > 0) {
                ref
                    .read(currencyProvider.notifier)
                    .updateRate(activeInfo.code, newRate);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Mettre à jour'),
          ),
        ],
      ),
    );
  }
}