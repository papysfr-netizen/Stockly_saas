import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> remettreFichier(List<int> octets, String nom, String mime) async {
  final dossier = await getTemporaryDirectory();
  final f = File('${dossier.path}/$nom');
  await f.writeAsBytes(octets, flush: true);
  await Share.shareXFiles([XFile(f.path, mimeType: mime, name: nom)], subject: nom);
}
