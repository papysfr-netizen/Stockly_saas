// lib/features/debts/presentation/views/debt_list_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stockly_saas/core/models/dette.dart';
import 'debt_dialogs.dart';

class DebtListView extends ConsumerWidget {
  final String entrepriseId;
  final List<Dette> liste;
  final TypeDette type;
  final String currency;

  const DebtListView({
    super.key,
    required this.entrepriseId,
    required this.liste,
    required this.type,
    required this.currency,
  });

  String _formaterDateHeure(DateTime date) {
    final jour = date.day.toString().padLeft(2, '0');
    final mois = date.month.toString().padLeft(2, '0');
    final annee = date.year;
    final heure = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return "$jour/$mois/$annee à $heure:$minute";
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double totalDetteReste = liste.fold(
      0.0,
      (sum, dette) => sum + dette.montantReste,
    );

    final bool isClient = type == TypeDette.client;
    final Color couleurPrincipale =
        isClient ? Colors.orange.shade800 : Colors.red.shade800;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            elevation: 3,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: couleurPrincipale,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white24,
                    radius: 24,
                    child: Icon(
                      isClient ? Icons.arrow_downward : Icons.arrow_upward,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isClient
                            ? 'Total À Recouvrer (Clients)'
                            : 'Total À Payer (Fournisseurs)',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${totalDetteReste.toStringAsFixed(2)} $currency',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (liste.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Text(
                isClient
                    ? 'Aucune créance client enregistrée.'
                    : 'Aucune dette fournisseur enregistrée.',
                style: const TextStyle(color: Colors.grey),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: liste.length,
              itemBuilder: (context, index) {
                final dette = liste[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dette.nomTiers,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        if (dette.numeroFacture.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.indigo.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Facture: ${dette.numeroFacture}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.indigo.shade900,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        if (dette.dateEcheance != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  size: 13,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'Échéance : ${_formaterDateHeure(dette.dateEcheance!)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: dette.estEnRetard
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: dette.estEnRetard
                                          ? Colors.red.shade700
                                          : Colors.grey.shade800,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (dette.estEnRetard) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'EN RETARD',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        Text(
                            'Total initial : ${dette.montantInitial.toStringAsFixed(2)} $currency'),
                        if (dette.acomptePaye > 0)
                          Text(
                              'Acompte versé : ${dette.acomptePaye.toStringAsFixed(2)} $currency',
                              style: const TextStyle(color: Colors.blueGrey)),
                        
                        // CORRECTION : Enveloppement dans un Expanded pour éviter le débordement
                        if (dette.dernierPaiement != null) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.history_rounded, size: 13, color: Colors.grey),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Dernier règlement : ${_formaterDateHeure(dette.dernierPaiement!)}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],

                        if (dette.note.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text('Note : ${dette.note}',
                                style: const TextStyle(
                                    fontStyle: FontStyle.italic)),
                          ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${dette.montantReste.toStringAsFixed(2)} $currency',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: dette.montantReste > 0
                                ? Colors.red.shade700
                                : Colors.green.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: dette.statut == 'paye'
                                ? Colors.green.shade100
                                : (dette.statut == 'partiel'
                                    ? Colors.orange.shade100
                                    : Colors.red.shade100),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            dette.statut == 'paye'
                                ? 'Soldé'
                                : (dette.statut == 'partiel'
                                    ? 'Partiel'
                                    : 'Non Payé'),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: dette.statut == 'paye'
                                  ? Colors.green.shade800
                                  : (dette.statut == 'partiel'
                                      ? Colors.orange.shade800
                                      : Colors.red.shade800),
                            ),
                          ),
                        ),
                      ],
                    ),
                    onTap: dette.montantReste > 0
                        ? () => DebtDialogs.afficherPaiement(
                            context, ref, entrepriseId, dette, currency)
                        : null,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}