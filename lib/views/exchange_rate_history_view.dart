import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/currency_provider.dart';

/// Vue complète de l'historique d'audit des taux de change avec filtres
class ExchangeRateHistoryView extends ConsumerStatefulWidget {
  const ExchangeRateHistoryView({super.key});

  @override
  ConsumerState<ExchangeRateHistoryView> createState() =>
      _ExchangeRateHistoryViewState();
}

class _ExchangeRateHistoryViewState
    extends ConsumerState<ExchangeRateHistoryView> {
  String _selectedCurrency = 'ALL';
  DateTimeRange? _selectedDateRange;

  @override
  Widget build(BuildContext context) {
    final logs = ref.watch(rateHistoryProvider);

    // Extraction des devises uniques présentes dans l'historique pour le filtre
    final availableCurrencies = [
      'ALL',
      ...logs.map((e) => e.currencyCode).toSet(),
    ];

    // Application des filtres (Devise & Date)
    final filteredLogs = logs.where((log) {
      final matchesCurrency = _selectedCurrency == 'ALL' ||
          log.currencyCode == _selectedCurrency;

      final matchesDate = _selectedDateRange == null ||
          (!log.timestamp.isBefore(_selectedDateRange!.start) &&
              log.timestamp.isBefore(
                _selectedDateRange!.end.add(const Duration(days: 1)),
              ));

      return matchesCurrency && matchesDate;
    }).toList();

    final hasActiveFilters =
        _selectedCurrency != 'ALL' || _selectedDateRange != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des Taux'),
        actions: [
          if (hasActiveFilters)
            IconButton(
              icon: const Icon(Icons.filter_alt_off),
              tooltip: 'Réinitialiser les filtres',
              onPressed: () {
                setState(() {
                  _selectedCurrency = 'ALL';
                  _selectedDateRange = null;
                });
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // ==================================================================
          // BARRE DE FILTRES
          // ==================================================================
          Container(
            padding: const EdgeInsets.all(12.0),
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            child: Row(
              children: [
                // Filtre par Devise
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedCurrency,
                    decoration: const InputDecoration(
                      labelText: 'Devise',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: availableCurrencies
                        .map<DropdownMenuItem<String>>((code) {
                      return DropdownMenuItem<String>(
                        value: code,
                        child: Text(
                          code == 'ALL' ? 'Toutes' : code,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedCurrency = val);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),

                // Filtre par Plage de Dates
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 12),
                  ),
                  icon: const Icon(Icons.date_range, size: 20),
                  label: Text(
                    _selectedDateRange == null
                        ? 'Toutes dates'
                        : '${DateFormat('dd/MM').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM').format(_selectedDateRange!.end)}',
                  ),
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2024),
                      lastDate: DateTime.now(),
                      initialDateRange: _selectedDateRange,
                    );
                    if (picked != null) {
                      setState(() => _selectedDateRange = picked);
                    }
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ==================================================================
          // LISTE DES JOURNAUX D'AUDIT
          // ==================================================================
          Expanded(
            child: filteredLogs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history,
                            size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          hasActiveFilters
                              ? 'Aucun changement ne correspond aux filtres'
                              : 'Aucun historique de modification',
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: filteredLogs.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final log = filteredLogs[index];
                      final isIncrease = log.newRate > log.oldRate;
                      final difference = (log.newRate - log.oldRate).abs();
                      final decimalDigits = log.currencyCode == 'CDF' ? 0 : 2;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isIncrease
                              ? Colors.red.shade50
                              : Colors.green.shade50,
                          child: Icon(
                            isIncrease
                                ? Icons.trending_up
                                : Icons.trending_down,
                            color: isIncrease
                                ? Colors.red.shade700
                                : Colors.green.shade700,
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              log.currencyCode,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${log.oldRate.toStringAsFixed(decimalDigits)} ➔ ${log.newRate.toStringAsFixed(decimalDigits)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          'Auteur : ${log.modifiedBy} (${isIncrease ? '+' : '-'}${difference.toStringAsFixed(decimalDigits)})',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              DateFormat('dd/MM/yyyy').format(log.timestamp),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              DateFormat('HH:mm').format(log.timestamp),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}