import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Taille maximale du logo stocké dans la fiche de l'école (la fiche Firestore
/// est limitée à 1 Mo ; le logo doit rester léger pour s'afficher vite).
const tailleMaxLogo = 300; // pixels, plus grand côté
const poidsMaxLogo = 350 * 1024; // octets

/// Décode une image (PNG, JPEG, WebP, GIF, BMP), la réduit et la réencode.
/// PNG si possible (garde la transparence), sinon JPEG plus léger.
/// Lève [FormatException] avec un message lisible si l'image est inutilisable.
Uint8List preparerLogo(Uint8List brut) {
  final image = img.decodeImage(brut);
  if (image == null) {
    throw const FormatException("Cette image n'est pas lisible. Utilisez un fichier PNG ou JPEG.");
  }
  final reduite = image.width > tailleMaxLogo || image.height > tailleMaxLogo
      ? img.copyResize(
          image,
          width: image.width >= image.height ? tailleMaxLogo : null,
          height: image.height > image.width ? tailleMaxLogo : null,
          interpolation: img.Interpolation.average,
        )
      : image;
  final png = img.encodePng(reduite, level: 9);
  if (png.length <= poidsMaxLogo) return png;
  for (final q in [85, 70, 55]) {
    final jpg = img.encodeJpg(reduite, quality: q);
    if (jpg.length <= poidsMaxLogo) return jpg;
  }
  throw const FormatException('Ce logo est trop lourd, même réduit. Essayez une image plus simple.');
}
