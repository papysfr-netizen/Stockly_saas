import 'package:flutter/material.dart';

import 'package:stockly_saas/l10n/app_localizations.dart';

// ============================================================================
// 💬 MESSAGES ENVOYÉS AUX CLIENTS (WhatsApp / SMS)
// Écrits dans la langue DU CLIENT, choisie à chaque envoi :
// français, anglais, swahili ou lingala.
// ============================================================================
class MessagesClients {
  static const Map<String, String> langues = {
    'fr': 'Français',
    'en': 'English',
    'sw': 'Kiswahili',
    'ln': 'Lingala',
  };

  static String _code(String langue) => langues.containsKey(langue) ? langue : 'fr';

  /// Message après une vente (reçu par WhatsApp / SMS)
  static String vente({
    required String langue,
    required String client,
    required String boutique,
    required String total,
    required String paye,
    required String reste,
    String? payeCompte,
    String? nouveauSolde,
    String? retirerAvant,
  }) {
    switch (_code(langue)) {
      case 'en':
        return 'Hello $client, your purchase at $boutique comes to $total. Paid: $paye. Balance: $reste.'
            '${payeCompte != null ? ' Paid from your account: $payeCompte. New balance: $nouveauSolde.' : ''}'
            '${retirerAvant != null ? ' Your goods are waiting for you at the shop: please collect them before $retirerAvant.' : ''}'
            ' Thank you!';
      case 'sw':
        return 'Habari $client, ununuzi wako kwa $boutique ni $total. Umelipa: $paye. Kilichobaki: $reste.'
            '${payeCompte != null ? ' Umelipa kwa akaunti yako: $payeCompte. Salio jipya: $nouveauSolde.' : ''}'
            '${retirerAvant != null ? ' Bidhaa zako zinakusubiri dukani: tafadhali zichukue kabla ya $retirerAvant.' : ''}'
            ' Asante!';
      case 'ln':
        return 'Mbote $client, esombeli na yo epai ya $boutique ezali $total. Ofuti: $paye. Etikali: $reste.'
            '${payeCompte != null ? ' Efutami na compte na yo: $payeCompte. Mbongo etikali: $nouveauSolde.' : ''}'
            '${retirerAvant != null ? ' Biloko na yo ezali kozela yo na magazini: kende kozwa yango liboso ya $retirerAvant.' : ''}'
            ' Matondi!';
      default:
        return "Bonjour $client, votre achat chez $boutique s'élève à $total. Payé: $paye. Reste: $reste."
            '${payeCompte != null ? ' Payé par votre compte : $payeCompte. Nouveau solde : $nouveauSolde.' : ''}'
            '${retirerAvant != null ? ' Votre marchandise vous attend à la boutique : merci de la retirer avant le $retirerAvant.' : ''}'
            ' Merci !';
    }
  }

  static String _facture(String code, String numero) {
    if (numero.trim().isEmpty) return '';
    switch (code) {
      case 'en':
        return ' (invoice $numero)';
      case 'sw':
        return ' (ankara $numero)';
      case 'ln':
        return ' (fakture $numero)';
      default:
        return ' (facture $numero)';
    }
  }

  /// Rappel à un CLIENT qui doit de l'argent
  static String relanceClient({
    required String langue,
    required String nom,
    required String reste,
    required String date,
    required String numero,
    required String total,
    required String paye,
  }) {
    final c = _code(langue);
    final f = _facture(c, numero);
    switch (c) {
      case 'en':
        return 'Hello $nom,\n\nA friendly reminder: $reste is still due on your purchase of $date$f.\n'
            'Total: $total — already paid: $paye.\n\nThank you for your trust!';
      case 'sw':
        return 'Habari $nom,\n\nUkumbusho wa kirafiki: bado kuna $reste za kulipa kwa ununuzi wako wa $date$f.\n'
            'Jumla: $total — umeshalipa: $paye.\n\nAsante kwa kutuamini!';
      case 'ln':
        return 'Mbote $nom,\n\nTokundolisi yo na boboto: etikali $reste ya kofuta na esombeli na yo ya $date$f.\n'
            'Motango mobimba: $total — esili kofutama: $paye.\n\nMatondi mpo na elikya na yo!';
      default:
        return 'Bonjour $nom,\n\nPetit rappel amical : il reste $reste à régler sur votre achat du $date$f.\n'
            'Montant total : $total — déjà payé : $paye.\n\nMerci pour votre confiance !';
    }
  }

  /// Message à un FOURNISSEUR à qui l'on doit de l'argent
  static String relanceFournisseur({
    required String langue,
    required String nom,
    required String reste,
    required String date,
    required String numero,
  }) {
    final c = _code(langue);
    final f = _facture(c, numero);
    switch (c) {
      case 'en':
        return 'Hello $nom,\n\nRegarding our invoice of $date$f: we still owe you $reste.\n'
            'We will get back to you very soon for the payment.\n\nThank you.';
      case 'sw':
        return 'Habari $nom,\n\nKuhusu ankara yetu ya $date$f: bado tunadaiwa $reste.\n'
            'Tutawasiliana nawe hivi karibuni kwa malipo.\n\nAsante.';
      case 'ln':
        return 'Mbote $nom,\n\nMpo na fakture na biso ya $date$f: tozali naino na niongo ya $reste epai na yo.\n'
            'Tokozonga epai na yo noki mpo na kofuta.\n\nMatondi.';
      default:
        return 'Bonjour $nom,\n\nConcernant notre facture du $date$f : il nous reste $reste à vous régler.\n'
            'Nous revenons vers vous très bientôt pour le paiement.\n\nMerci.';
    }
  }

  /// Fenêtre « Langue du message » : renvoie 'fr', 'en', 'sw', 'ln' ou null (annulé)
  static Future<String?> choisirLangue(BuildContext context, {String? defaut}) {
    final choisi = _code(defaut ?? 'fr');
    return showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(AppLocalizations.of(ctx).msgLanguage),
        children: [
          for (final e in langues.entries)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, e.key),
              child: Row(
                children: [
                  Icon(
                    e.key == choisi ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: e.key == choisi ? Colors.teal : Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(e.value, style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Petit choix « Langue du message » (fenêtre de paiement)
class LangueMessageChoix extends StatelessWidget {
  final String valeur;
  final ValueChanged<String> onChanged;

  const LangueMessageChoix({super.key, required this.valeur, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final v = MessagesClients.langues.containsKey(valeur) ? valeur : 'fr';
    return Row(
      children: [
        const Icon(Icons.translate_rounded, size: 18, color: Colors.teal),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            AppLocalizations.of(context).msgLanguage,
            style: const TextStyle(fontSize: 12),
          ),
        ),
        DropdownButton<String>(
          value: v,
          underline: const SizedBox.shrink(),
          items: [
            for (final e in MessagesClients.langues.entries)
              DropdownMenuItem(
                value: e.key,
                child: Text(e.value, style: const TextStyle(fontSize: 13)),
              ),
          ],
          onChanged: (x) {
            if (x != null) onChanged(x);
          },
        ),
      ],
    );
  }
}
