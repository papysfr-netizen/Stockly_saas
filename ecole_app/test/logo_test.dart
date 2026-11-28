import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:ecole_app/demo/donnees_demo.dart';
import 'package:ecole_app/models/ecole.dart';
import 'package:ecole_app/services/logo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  test('un grand logo est réduit à 300 px, en PNG', () {
    final grand = img.Image(width: 1200, height: 800);
    img.fill(grand, color: img.ColorRgb8(30, 90, 168));
    final r = preparerLogo(Uint8List.fromList(img.encodePng(grand)));
    final d = img.decodeImage(r)!;
    expect((d.width, d.height), (300, 200));
    expect(r.length, lessThan(poidsMaxLogo));
    expect(String.fromCharCodes(r.sublist(1, 4)), 'PNG');
  });

  test('une photo trop lourde en PNG passe en JPEG', () {
    // Bruit aléatoire : incompressible en PNG.
    final photo = img.Image(width: 300, height: 300, numChannels: 4, format: img.Format.uint16); // 720 Ko de pixels
    var x = 7;
    for (final p in photo) {
      x = (x * 1103515245 + 12345) & 0x7fffffff;
      p
        ..r = x & 0xffff
        ..g = (x >> 4) & 0xffff
        ..b = (x >> 8) & 0xffff
        ..a = (x >> 12) & 0xffff;
    }
    expect(img.encodePng(photo).length, greaterThan(poidsMaxLogo)); // le PNG dépasse bien la limite
    final r = preparerLogo(Uint8List.fromList(img.encodePng(photo)));
    expect(r.length, lessThanOrEqualTo(poidsMaxLogo));
    expect(r.sublist(0, 2), [0xFF, 0xD8]); // signature JPEG
  });

  test("un fichier qui n'est pas une image est refusé", () {
    expect(() => preparerLogo(Uint8List.fromList(utf8.encode('pas une image'))), throwsFormatException);
  });

  test("le logo et l'en-tête se relisent depuis la fiche de l'école", () {
    final logo = logoDemo();
    final e = Ecole(id: 'e', nom: 'X', logo: base64Encode(logo), enTete: 'Ligne 1\n\n  Ligne 2  ', codeEcole: 'K-1');
    expect(e.logoOctets, logo);
    expect(e.lignesEnTete, ['Ligne 1', 'Ligne 2']);
    expect(const Ecole(id: 'e', nom: 'X', logo: '%%%').logoOctets, isNull); // base64 invalide : ignoré
    final dir = Platform.environment['EXPORT_DIR'];
    if (dir != null) File('$dir/logo_demo.png').writeAsBytesSync(logo);
  });
}
