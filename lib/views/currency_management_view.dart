import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/currency_provider.dart';
import 'exchange_rate_history_view.dart';
import 'update_exchange_rate_dialog.dart';

/// Vue principale de gestion des devises avec accès à l'historique et modification
class CurrencyManagementView extends ConsumerWidget {
  const CurrencyManagementView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Utilisation du provider dérivé qui renvoie List<CurrencyInfo>
    final currencies = ref.watch(availableCurrenciesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Devises'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Voir l\'historique des taux',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ExchangeRateHistoryView(),
                ),
              );
            },
          ),
        ],
      ),
      body: currencies.isEmpty
          ? const Center(
              child: Text(
                'Aucune devise disponible',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.separated(
              itemCount: currencies.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final currency = currencies[index];
                return ListTile(
                  title: Text(
                    '${currency.name} (${currency.code})',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '1 USD = ${currency.rateToUSD.toStringAsFixed(currency.decimalDigits)} ${currency.symbol}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    tooltip: 'Modifier le taux',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => UpdateExchangeRateDialog(
                          currencyCode: currency.code,
                          currentRate: currency.rateToUSD,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}