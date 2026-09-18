// ─────────────────────────────────────────────────────────────────────────────
// Design tokens — extraits du Figma "Global Immo Service"
// Fichier  : 5VQDFHrI3Dnu4i0BVleB0F  ·  page "Design"
// Source   : frames Home LT (927:7894) et Home DT (960:6915)
//
// Toute valeur ici vient du Figma. Ne rien inventer : si une valeur manque,
// la relever dans Figma plutôt que l'approximer.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

/// Neutres — styles nommés "Neutral/xx" dans Figma.
abstract final class FigNeutral {
  static const n10  = Color(0xFFE5E5E5); // Neutral/10  — texte principal (dark)
  static const n40  = Color(0xFF999999); // Neutral/40  — labels secondaires
  static const n50  = Color(0xFF7F7F7F); // Neutral/50  — texte atténué (dark)
  static const n60  = Color(0xFF666666); // Neutral/60
  static const n70  = Color(0xFF4C4C4C); // Neutral/70  — texte secondaire (light)
  static const n100 = Color(0xFF000000); // Neutral/100 — texte principal (light)
}

/// Couleurs de marque.
abstract final class FigBrand {
  static const amber = Color(0xFFDB9200); // accent CTA / actif
  static const navy  = Color(0xFF0C1620); // fond dark + navbar en thème light
  static const cream = Color(0xFFF6F3EC); // fond light
}

/// États — styles nommés "Alert/xx" dans Figma.
abstract final class FigAlert {
  static const success = Color(0xFF2ECC71);
  static const error   = Color(0xFFE74C3C);
}

/// Teintes des pastilles d'icônes. Dans le Figma chaque pastille est
/// `bg: base @ 5%` + `border: base @ 10%`, identique en light et en dark.
abstract final class FigAccent {
  static const amber  = FigBrand.amber;    // Payments
  static const red    = FigAlert.error;    // Reports
  static const violet = Color(0xFF7B6FDE); // Notices
  static const blue   = Color(0xFF5794EA); // Documents
  static const purple = Color(0xFF8B81CB); // Profile

  static Color chipFill(Color base)   => base.withValues(alpha: 0.05);
  static Color chipBorder(Color base) => base.withValues(alpha: 0.10);
}

/// Surfaces du thème clair.
abstract final class FigLight {
  static const scaffold   = FigBrand.cream;   // #F6F3EC
  /// Fond de carte : #F6F3EC recouvert de noir 4% → composite exact.
  static const card       = Color(0xFFECE9E3);
  static const cardBorder = Color(0xFFE7E4DE);
  static const pillBorder = Color(0xFFE2E0D9);
  static const title      = FigBrand.navy;    // "Welcome Mehdi"
  static const textBody   = FigNeutral.n100;
  static const textMuted  = FigNeutral.n70;
  static const textFaint  = FigNeutral.n40;
  static const navbarBg     = FigBrand.navy;  // navbar sombre sur fond clair
  static const navbarBorder = Color(0xFF1F2932);
  static const gestureBar   = Color(0xFFCED0D2);
}

/// Surfaces du thème sombre.
abstract final class FigDark {
  static const scaffold   = FigBrand.navy;    // #0C1620
  static const card       = Color(0xFF0A121A);
  static const cardBorder = Color(0xFF080F16);
  static const innerBorder = Color(0xFF141B24);
  static const title      = FigBrand.amber;   // "Welcome Mehdi" passe en ambre
  static const textBody   = FigNeutral.n10;
  static const textMuted  = FigNeutral.n50;
  static const textFaint  = FigNeutral.n40;
  static const navbarBg     = Color(0xFF242D36); // navbar plus claire que le fond
  static const navbarBorder = Color(0xFF2D353E);
}

/// Bordure ambrée de la carte hero, commune aux deux thèmes.
final heroBorderColor = FigBrand.amber.withValues(alpha: 0.20);

/// Rayons d'arrondi relevés dans le Figma.
abstract final class FigRadius {
  static const pill    = 6.0;   // badge APt.3B
  static const chip    = 8.0;   // pastille d'icône, avatar, bouton header
  static const chipLg  = 8.75;  // pastille 35px de la 1re Quick Action
  static const handle  = 12.0;  // gesture bar
  static const card    = 16.0;  // cartes, hero, stat fill
  static const navbar  = 40.0;  // bottom nav flottante
}

/// Espacements et gabarits.
abstract final class FigSpace {
  static const screenW     = 375.0; // largeur de référence des frames
  static const pagePadding = 20.0;  // marge latérale du contenu
  static const contentW    = 335.0; // screenW - 2 * pagePadding
  static const headerTop   = 66.0;  // y du header
  static const contentTop  = 118.0; // y du premier bloc
  static const navbarBottom = 24.0; // offset bas de la navbar

  static const xs  = 4.0;
  static const sm  = 6.0;
  static const md  = 8.0;
  static const lg  = 12.0;
  static const xl  = 16.0;
  static const xxl = 28.0;

  static const cardPadding = 16.0;
  static const heroPadding = 15.0;
}

/// Tailles d'éléments récurrents.
abstract final class FigSize {
  static const heroH        = 195.0;
  static const statCardW    = 161.5;
  static const quickTileW   = 103.667;
  static const chipSm       = 28.0; // pastille des stat cards
  static const chipMd       = 32.0; // bouton notif + avatar du header
  static const chipLg       = 35.0; // pastille des Quick Actions
  static const navIcon      = 24.0;
  static const navIconAlt   = 22.0; // Home et Report
  static const navItemW     = 60.0;
  static const chevron      = Size(7.0, 8.615);
  static const activityDot  = 6.0;
}

/// Typographie — Montserrat, tailles et interlignes relevés au pixel.
/// Figma exprime l'interligne en multiple : 1.2 partout, 1.36 pour les
/// valeurs de stats. Flutter utilise `height`, qui est le même ratio.
abstract final class FigText {
  static const family = 'Montserrat';

  static const _h  = 1.2;
  static const _hv = 1.36;

  /// 24 / SemiBold — "Welcome Mehdi"
  static const greeting = TextStyle(
    fontFamily: family, fontSize: 24, fontWeight: FontWeight.w600, height: _h);

  /// 16 / SemiBold — titres de section, nom de résidence, valeurs de stats
  static const titleMd = TextStyle(
    fontFamily: family, fontSize: 16, fontWeight: FontWeight.w600, height: _h);

  /// 16 / Regular — lignes d'activité récente
  static const bodyLg = TextStyle(
    fontFamily: family, fontSize: 16, fontWeight: FontWeight.w400, height: _h);

  /// 16 / Medium — valeurs du bandeau (3rd, 127 m², Active)
  static const statValue = TextStyle(
    fontFamily: family, fontSize: 16, fontWeight: FontWeight.w500, height: _hv);

  /// 13 / Regular — libellés courants, onglets de navbar inactifs
  static const body = TextStyle(
    fontFamily: family, fontSize: 13, fontWeight: FontWeight.w400, height: _h);

  /// 13 / SemiBold — onglet de navbar actif
  static const bodyActive = TextStyle(
    fontFamily: family, fontSize: 13, fontWeight: FontWeight.w600, height: _h);

  /// 12 / Regular — labels du bandeau (Floor, Area, Status)
  static const label = TextStyle(
    fontFamily: family, fontSize: 12, fontWeight: FontWeight.w400, height: _h);

  /// 10 / Regular — échéances, horodatages
  static const caption = TextStyle(
    fontFamily: family, fontSize: 10, fontWeight: FontWeight.w400, height: _h);
}
