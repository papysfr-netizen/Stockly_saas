// Outils de numéros de téléphone (format international E.164 : +225XXXXXXXXXX).

/// Normalise un numéro saisi librement. [indicatif] est l'indicatif du pays
/// de l'école (ex. "+225") utilisé quand le numéro est saisi en format local.
/// Retourne `null` si le numéro est inexploitable.
String? normaliserTelephone(String brut, {String indicatif = '+225'}) {
  var t = brut.trim().replaceAll(RegExp(r'[\s.\-()/]'), '');
  if (t.isEmpty) return null;
  if (t.startsWith('00')) t = '+${t.substring(2)}';
  if (!t.startsWith('+')) {
    final code = indicatif.replaceAll(RegExp(r'[^0-9]'), '');
    // Un numéro local commençant par 0 garde son 0 dans certains pays
    // (Côte d'Ivoire depuis 2021) mais pas dans d'autres (France, Sénégal…).
    if (t.startsWith('0') && !_garde0.contains(code)) t = t.substring(1);
    t = '+$code$t';
  }
  if (!RegExp(r'^\+[1-9][0-9]{7,14}$').hasMatch(t)) return null;
  return t;
}

/// Pays où le 0 initial fait partie du numéro national.
const _garde0 = {'225', '39'};
