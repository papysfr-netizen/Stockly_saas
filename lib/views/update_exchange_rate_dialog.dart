import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/currency_provider.dart';

class UpdateExchangeRateDialog extends ConsumerStatefulWidget {
  final String currencyCode;
  final double currentRate;

  const UpdateExchangeRateDialog({
    super.key,
    required this.currencyCode,
    required this.currentRate,
  });

  @override
  ConsumerState<UpdateExchangeRateDialog> createState() =>
      _UpdateExchangeRateDialogState();
}

class _UpdateExchangeRateDialogState
    extends ConsumerState<UpdateExchangeRateDialog> {
  late final TextEditingController _rateController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _rateController = TextEditingController(
      text: widget.currentRate.toString(),
    );
  }

  @override
  void dispose() {
    _rateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Modifier le taux (${widget.currencyCode})'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _rateController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Nouveau taux de change',
            suffixText: 'CDF',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer un taux';
            }
            final parsed = double.tryParse(value);
            if (parsed == null || parsed <= 0) {
              return 'Entrez un nombre valide supérieur à 0';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final newRate = double.parse(_rateController.text);

              // Mise à jour du taux via le provider Riverpod
              ref.read(currencyProvider.notifier).updateRate(
                    widget.currencyCode,
                    newRate,
                    modifiedBy: 'Admin', // À remplacer par l'utilisateur connecté
                  );

              Navigator.pop(context);
            }
          },
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}