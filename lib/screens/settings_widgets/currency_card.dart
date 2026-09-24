import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/currency_provider.dart';

class CurrencyCard extends ConsumerWidget {
  const CurrencyCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyState = ref.watch(currencyProvider);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.account_balance, color: Colors.amber),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Taux BCC & Devise Active',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: currencyState.bccCdfRate.toStringAsFixed(0),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Taux de change (BCC)',
                prefixIcon: const Icon(Icons.currency_exchange),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (val) {
                final double? newRate = double.tryParse(val);
                if (newRate != null && newRate > 0) {
                  ref.read(currencyProvider.notifier).updateBccRate(newRate);
                }
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: currencyState.activeCurrency,
              decoration: InputDecoration(
                labelText: 'Devise principale',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: currencyState.currencies.values.map((curr) {
                return DropdownMenuItem<String>(
                  value: curr.code,
                  child: Text(
                    '${curr.code} (${curr.symbol}) - ${curr.name}',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  ref.read(currencyProvider.notifier).setCurrency(val);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}