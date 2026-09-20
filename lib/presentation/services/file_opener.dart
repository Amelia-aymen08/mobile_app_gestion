import 'dart:io';
import 'dart:typed_data';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

/// Saves downloaded bytes to a temporary file and hands it to the system
/// viewer (PDF reader, gallery, Office app...).
class FileOpener {
  FileOpener._();

  static String _safeName(String name) {
    final cleaned = name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    return cleaned.isEmpty ? 'document' : cleaned;
  }

  /// Throws an [Exception] with a French message when the file can't be opened.
  static Future<void> openBytes(Uint8List bytes, String filename) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${_safeName(filename)}');
    await file.writeAsBytes(bytes, flush: true);
    final result = await OpenFilex.open(file.path);
    if (result.type == ResultType.noAppToOpen) {
      throw Exception('Aucune application ne peut ouvrir ce type de fichier.');
    }
    if (result.type != ResultType.done) {
      throw Exception("Impossible d'ouvrir le fichier.");
    }
  }
}
