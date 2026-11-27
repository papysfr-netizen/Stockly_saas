// Remettre un fichier généré à l'utilisateur :
// - web : téléchargement direct par le navigateur ;
// - Android / iOS / ordinateur : menu de partage (WhatsApp, e-mail, Drive, Fichiers…).
export 'fichier_io.dart' if (dart.library.js_interop) 'fichier_web.dart';

/// Nom de fichier sûr : lettres, chiffres, tirets.
String nomFichier(String base) => base
    .replaceAll(RegExp(r'[^A-Za-z0-9À-ÿ_-]+'), '_')
    .replaceAll(RegExp(r'_+'), '_');

const mimeExcel = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
