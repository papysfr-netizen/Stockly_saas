import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../../core/providers/settings_provider.dart' hide currencyProvider; // Masque le doublon pour éviter le conflit

class InfoCard extends ConsumerStatefulWidget {
  const InfoCard({super.key});

  @override
  ConsumerState<InfoCard> createState() => _InfoCardState();
}

class _InfoCardState extends ConsumerState<InfoCard> {
  late final TextEditingController nomController;
  late final TextEditingController adresseController;
  late final TextEditingController phoneController;
  late final TextEditingController rccmController;
  late final TextEditingController idNatController;
  late final TextEditingController nifController;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    nomController = TextEditingController(text: settings.nomBoutique);
    adresseController = TextEditingController(text: settings.adresse);
    phoneController = TextEditingController(text: settings.telephone);
    // Les champs rccm, idNat et nif sont maintenant des String directs dans ShopSettings
    rccmController = TextEditingController(text: settings.rccm);
    idNatController = TextEditingController(text: settings.idNat);
    nifController = TextEditingController(text: settings.nif);
  }

  @override
  void dispose() {
    nomController.dispose();
    adresseController.dispose();
    phoneController.dispose();
    rccmController.dispose();
    idNatController.dispose();
    nifController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                Icon(Icons.store, color: Colors.blue),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Informations du Magasin & Légales',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nomController,
              decoration: InputDecoration(
                labelText: 'Nom de la boutique',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.storefront),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: adresseController,
              decoration: InputDecoration(
                labelText: 'Adresse',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              decoration: InputDecoration(
                labelText: 'Téléphone',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: rccmController,
              decoration: InputDecoration(
                labelText: 'RCCM',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.business_center),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: idNatController,
              decoration: InputDecoration(
                labelText: 'ID.NAT',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.badge),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nifController,
              decoration: InputDecoration(
                labelText: 'NIF',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.receipt_long),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Enregistrer les informations'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  ref.read(settingsProvider.notifier).updateSettings(
                        nom: nomController.text,
                        adresse: adresseController.text,
                        phone: phoneController.text,
                        rccm: rccmController.text,
                        idNat: idNatController.text,
                        nif: nifController.text,
                        currency: ref.read(settingsProvider).currency,
                      );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Paramètres enregistrés avec succès !'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}