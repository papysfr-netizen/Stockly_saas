import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

Future<void> remettreFichier(List<int> octets, String nom, String mime) async {
  final blob = web.Blob([Uint8List.fromList(octets).toJS].toJS, web.BlobPropertyBag(type: mime));
  final url = web.URL.createObjectURL(blob);
  final lien = web.HTMLAnchorElement()
    ..href = url
    ..download = nom;
  web.document.body!.append(lien);
  lien.click();
  lien.remove();
  web.URL.revokeObjectURL(url);
}
