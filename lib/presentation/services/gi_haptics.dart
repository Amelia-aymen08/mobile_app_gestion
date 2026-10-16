import 'package:flutter/services.dart';

/// Vibrations de l'app, au meme endroit pour qu'elles gardent un sens.
///
/// Chaque appui donne deja un toucher leger (GiPressable). Celles-ci
/// marquent ce qui compte : un choix qui change, une action qui aboutit ou
/// qui echoue, un geste qui atteint son seuil. Utilisees partout, elles ne
/// voudraient plus rien dire.
abstract final class GiHaptics {
  /// Un choix change : onglet, puce, carte selectionnee.
  static void select() => HapticFeedback.selectionClick();

  /// Un geste atteint son seuil : tirer pour actualiser, glisser pour
  /// revenir.
  static void threshold() => HapticFeedback.mediumImpact();

  /// Une action aboutit : signalement envoye, piece jointe ajoutee.
  static void success() => HapticFeedback.mediumImpact();

  /// Une action echoue : deux coups secs, qu'on ne confond pas avec un
  /// succes.
  static Future<void> error() async {
    await HapticFeedback.heavyImpact();
    await Future<void>.delayed(const Duration(milliseconds: 110));
    await HapticFeedback.heavyImpact();
  }
}
