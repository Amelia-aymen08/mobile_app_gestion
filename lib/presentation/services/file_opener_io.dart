import 'dart:io';
import 'dart:typed_data';

import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

/// Mobile et bureau : le fichier est ecrit puis ouvert par l'application du
/// systeme associee a son type.
Future<void> openBytes(Uint8List bytes, String filename) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$filename');
  await file.writeAsBytes(bytes, flush: true);
  final result = await OpenFilex.open(file.path);
  if (result.type == ResultType.noAppToOpen) {
    throw Exception('noAppToOpen');
  }
  if (result.type != ResultType.done) {
    throw Exception('openFailed');
  }
}
