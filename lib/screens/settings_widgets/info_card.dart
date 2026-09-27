import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/settings_provider.dart' hide currencyProvider; // Masque le doublon pour éviter le conflit
import '../../l10n/app_localizations.dart';

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

  /// Vrai dès que l'utilisateur tape quelque chose : on ne remplace
  /// alors plus ses saisies par les données arrivant de Firestore.
  bool _modifieParUtilisateur = false;
  bool _enregistrementEnCours = false;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    nomController = TextEditingController(text: settings.nomBoutique);
    adresseController = TextEditingController(text: settings.adresse);
    phoneController = TextEditingController(text: settings.telephone);
    rccmController = TextEditingController(text: settings.rccm);
    idNatController = TextEditingController(text: settings.idNat);
    nifController = TextEditingController(text: settings.nif);
  }

  void _remplirChamps(ShopSettings settings) {
    nomController.text = settings.nomBoutique;
    adresseController.text = settings.adresse;
    phoneController.text = settings.telephone;
    rccmController.text = settings.rccm;
    idNatController.text = settings.idNat;
    nifController.text = settings.nif;
  }

  Future<void> _enregistrer() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _enregistrementEnCours = true);

    final ok = await ref.read(settingsProvider.notifier).updateSettings(
          nom: nomController.text,
          adresse: adresseController.text,
          phone: phoneController.text,
          rccm: rccmController.text,
          idNat: idNatController.text,
          nif: nifController.text,
          currency: ref.read(settingsProvider).currency,
        );

    if (!mounted) return;
    setState(() {
      _enregistrementEnCours = false;
      if (ok) _modifieParUtilisateur = false;
    });

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Informations du magasin enregistrées !'
              : 'Échec de l\'enregistrement. Réessayez.',
        ),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );
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

  Widget _champ({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: (_) => _modifieParUtilisateur = true,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: Icon(icon),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    // Quand les infos arrivent de Firestore, on remplit les champs
    // (sauf si l'utilisateur est en train de les modifier).
    ref.listen<ShopSettings>(settingsProvider, (precedent, suivant) {
      if (!_modifieParUtilisateur && precedent != suivant) {
        _remplirChamps(suivant);
      }
    });

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
                const Icon(Icons.store, color: Colors.blue),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    t.storeInfo,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _champ(controller: nomController, label: t.storeName, icon: Icons.storefront),
            const SizedBox(height: 12),
            _champ(controller: adresseController, label: t.address, icon: Icons.location_on),
            const SizedBox(height: 12),
            _champ(
              controller: phoneController,
              label: t.phone,
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            _champ(controller: rccmController, label: 'RCCM', icon: Icons.business_center),
            const SizedBox(height: 12),
            _champ(controller: idNatController, label: 'ID.NAT', icon: Icons.badge),
            const SizedBox(height: 12),
            _champ(controller: nifController, label: 'NIF', icon: Icons.receipt_long),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                icon: _enregistrementEnCours
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save),
                label: Text(t.saveInfo),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _enregistrementEnCours ? null : _enregistrer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}