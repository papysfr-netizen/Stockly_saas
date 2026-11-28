import '../core/format.dart';

enum CanalRappel { sms, whatsapp }

extension CanalRappelX on CanalRappel {
  String get label => this == CanalRappel.sms ? 'SMS' : 'WhatsApp';
}

const modeleRappelParDefaut =
    "Bonjour {parent}, sauf erreur de notre part, il reste {montant} à régler pour la scolarité de "
    "{eleve} ({classe}). Merci de passer au secrétariat. — {ecole}";

/// Remplace les variables {parent}, {eleve}, {classe}, {montant}, {ecole}.
/// Même logique que `functions/rappels.js` côté serveur.
String messageRappel({
  required String modele,
  required String parent,
  required String eleve,
  required String classe,
  required double montant,
  required String devise,
  required String ecole,
}) {
  final valeurs = {
    'parent': parent.trim().isEmpty ? 'cher parent' : parent.trim(),
    'eleve': eleve,
    'classe': classe,
    // Espaces simples : les espaces insécables forcent l'encodage UCS-2 (SMS deux fois plus courts).
    'montant': formatMontant(montant, devise: devise).replaceAll(RegExp('[\u00A0\u202F]'), ' '),
    'ecole': ecole,
  };
  return (modele.trim().isEmpty ? modeleRappelParDefaut : modele)
      .replaceAllMapped(RegExp(r'\{(\w+)\}'), (m) => valeurs[m[1]] ?? m[0]!);
}

/// Lien qui ouvre l'application SMS ou WhatsApp du téléphone avec le message prérempli.
/// (encodeComponent : les espaces deviennent %20 et non « + », mal lu par certaines applis SMS)
Uri lienRappel(CanalRappel canal, String telephoneE164, String message) {
  final texte = Uri.encodeComponent(message);
  return canal == CanalRappel.sms
      ? Uri.parse('sms:$telephoneE164?body=$texte')
      : Uri.parse('https://wa.me/${telephoneE164.replaceAll('+', '')}?text=$texte');
}

/// Résultat d'un envoi groupé par la Cloud Function `envoyerRappels`.
class ResultatRappels {
  final int envoyes, echecs, sansTelephone, recents;
  final List<String> erreurs;
  const ResultatRappels(this.envoyes, this.echecs, this.sansTelephone, this.recents, this.erreurs);

  factory ResultatRappels.fromMap(Map<String, dynamic> m) => ResultatRappels(
        (m['envoyes'] as num?)?.toInt() ?? 0,
        (m['echecs'] as num?)?.toInt() ?? 0,
        (m['sansTelephone'] as num?)?.toInt() ?? 0,
        (m['recents'] as num?)?.toInt() ?? 0,
        List<String>.from(m['erreurs'] ?? const []),
      );

  String get resume => [
        '$envoyes rappel(s) envoyé(s)',
        if (echecs > 0) '$echecs échec(s)${erreurs.isEmpty ? '' : ' : ${erreurs.join(' ; ')}'}',
        if (recents > 0) '$recents déjà relancé(s) il y a moins de 24 h',
        if (sansTelephone > 0) '$sansTelephone sans numéro de téléphone valide',
      ].join('\n');
}
