import 'dart:typed_data';

import 'file_opener_io.dart' if (dart.library.js_interop) 'file_opener_web.dart'
    as impl;

/// Remet un fichier telecharge a l'utilisateur.
///
/// Sur mobile il est ecrit dans le dossier temporaire puis confie au
/// visualiseur du systeme ; sur le web le navigateur s'en charge et le
/// depose dans les telechargements. Les deux implementations vivent dans des
/// fichiers separes : `dart:io` n'existe pas sur le web, et inversement.
class FileOpener {
  FileOpener._();

  static String safeName(String name) {
    final cleaned = name.replaceAll(RegExp(r'[\/:*?"<>|]'), '_').trim();
    return cleaned.isEmpty ? 'document' : cleaned;
  }

  /// Leve une exception quand le fichier ne peut pas etre ouvert.
  static Future<void> openBytes(Uint8List bytes, String filename) =>
      impl.openBytes(bytes, safeName(filename));
}
