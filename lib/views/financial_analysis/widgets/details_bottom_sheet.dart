import 'package:flutter/material.dart';

class DetailsBottomSheet {
  static void afficher({
    required BuildContext context,
    required String titre,
    required List<Widget> enfants,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E2640),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                titre,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 12),
              const Divider(color: Colors.white10),
              Expanded(
                child: enfants.isEmpty
                    ? const Center(
                        child: Text(
                          'Aucun détail disponible pour cette période.',
                          style: TextStyle(color: Colors.white54),
                        ),
                      )
                    : ListView(children: enfants),
              ),
            ],
          ),
        );
      },
    );
  }
}