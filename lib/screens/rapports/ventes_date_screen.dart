import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class VentesParDateScreen extends StatefulWidget {
  const VentesParDateScreen({super.key});

  @override
  State<VentesParDateScreen> createState() => _VentesParDateScreenState();
}

class _VentesParDateScreenState extends State<VentesParDateScreen> {
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 7)),
    end: DateTime.now(),
  );

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text("Ventes par Date")),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.blue.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Période : ${dateFormat.format(_dateRange.start)} - ${dateFormat.format(_dateRange.end)}"),
                ElevatedButton.icon(
                  icon: const Icon(Icons.date_range, size: 18),
                  label: const Text("Changer"),
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      initialDateRange: _dateRange,
                    );
                    if (picked != null) setState(() => _dateRange = picked);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('ventes')
                  .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(_dateRange.start))
                  .where('date', isLessThanOrEqualTo: Timestamp.fromDate(_dateRange.end.add(const Duration(days: 1))))
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Aucune vente sur cette période"));
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final DateTime date = (data['date'] as Timestamp).toDate();

                    return ListTile(
                      leading: const Icon(Icons.receipt_long, color: Colors.blue),
                      title: Text("Vente #${docs[index].id.substring(0, 6)}"),
                      subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(date)),
                      trailing: Text(
                        "${data['totalVente'] ?? 0} FCFA",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}