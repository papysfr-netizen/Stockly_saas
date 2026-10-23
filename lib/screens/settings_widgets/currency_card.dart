import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/currency_provider.dart';
import '../../core/providers/user_role_provider.dart';
import '../../l10n/app_localizations.dart';

class CurrencyCard extends ConsumerWidget {
  const CurrencyCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyState = ref.watch(currencyProvider);
    final t = AppLocalizations.of(context);
    // 🔒 Taux : le patron, ou « Paramètres sensibles » ; les autres le voient seulement
    final peutModifierTaux =
        ref.watch(userProfileProvider).value?.peutParametres ?? false;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance, color: Colors.amber),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    t.bccSection,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: currencyState.bccCdfRate.toStringAsFixed(0),
              keyboardType: TextInputType.number,
              readOnly: !peutModifierTaux,
              decoration: InputDecoration(
                labelText: t.bccRate,
                helperText: peutModifierTaux
                    ? null
                    : 'Seul le patron (ou une personne autorisée) peut changer le taux.',
                prefixIcon: const Icon(Icons.currency_exchange),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (val) {
                if (!peutModifierTaux) return;
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
                labelText: t.activeCurrency,
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