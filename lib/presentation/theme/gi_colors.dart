import 'package:flutter/material.dart';
import 'design_tokens.dart';

// Teintes semi-transparentes recurrentes du Figma.
// Le Figma pose la bordure de la carte residence a 20 % d'ambre, ce qui la
// rend presque invisible a l'ecran. Elle est montee a 55 % pour que le liere
// dore se voie, comme demande.
final _amber20 = FigBrand.amber.withValues(alpha: 0.55);
final _black05 = Colors.black.withValues(alpha: 0.05);
final _black02 = Colors.black.withValues(alpha: 0.02);
final _white05 = Colors.white.withValues(alpha: 0.05);
final _white10 = Colors.white.withValues(alpha: 0.10);

/// Surfaces du design Figma, exposees via le theme pour qu'un widget n'ait
/// jamais a tester lui-meme si l'app est en clair ou en sombre.
///
/// Usage : `final c = GiColors.of(context);`
///
/// Ce fichier est genere a partir d'une liste de champs : ajouter une couleur
/// demande de la declarer, de l'initialiser deux fois, de l'ajouter au
/// copyWith et au lerp. L'oubli d'une seule de ces quatre etapes passe la
/// compilation mais casse la transition clair/sombre.
@immutable
class GiColors extends ThemeExtension<GiColors> {
  final Color scaffold;
  final Color card;
  final Color cardBorder;
  final Color innerBorder;
  final Color title;
  final Color textBody;
  final Color textMuted;
  final Color textFaint;
  final Color navbarBg;
  final Color navbarBorder;
  final Color heroBorder;
  final Color headerChipBg;
  final Color headerChipBorder;
  final Color fieldBg;
  final Color fieldBorder;
  final Color fieldBorderFocus;
  final Color fieldText;
  final Color fieldHint;
  final Color eyeStroke;
  final Color ctaBg;
  final Color ctaText;
  final Color ctaDisabledBg;
  final Color ctaDisabledText;
  final Color loginTitle;
  final Color loginSubtitle;
  final Color footerText;

  const GiColors({
    required this.scaffold,
    required this.card,
    required this.cardBorder,
    required this.innerBorder,
    required this.title,
    required this.textBody,
    required this.textMuted,
    required this.textFaint,
    required this.navbarBg,
    required this.navbarBorder,
    required this.heroBorder,
    required this.headerChipBg,
    required this.headerChipBorder,
    required this.fieldBg,
    required this.fieldBorder,
    required this.fieldBorderFocus,
    required this.fieldText,
    required this.fieldHint,
    required this.eyeStroke,
    required this.ctaBg,
    required this.ctaText,
    required this.ctaDisabledBg,
    required this.ctaDisabledText,
    required this.loginTitle,
    required this.loginSubtitle,
    required this.footerText,
  });

  /// Theme clair — frames "Home LT" (927:7894) et "Login LT" (721:7277).
  static final light = GiColors(
    scaffold: FigLight.scaffold,
    card: FigLight.card,
    cardBorder: FigLight.cardBorder,
    innerBorder: const Color(0xFFE7E4DE),
    title: FigLight.title,
    textBody: FigLight.textBody,
    textMuted: FigLight.textMuted,
    textFaint: FigLight.textFaint,
    navbarBg: FigLight.navbarBg,
    navbarBorder: FigLight.navbarBorder,
    heroBorder: _amber20,
    headerChipBg: _black05,
    headerChipBorder: _black02,
    fieldBg: const Color(0xFFECE9E3), // fond de champ
    fieldBorder: FigNeutral.n10, // bordure au repos
    fieldBorderFocus: FigNeutral.n20, // bordure au focus
    fieldText: FigNeutral.n70, // valeur saisie
    fieldHint: FigNeutral.n30, // placeholder
    eyeStroke: FigNeutral.n30, // icone oeil
    ctaBg: FigBrand.amber, // bouton actif
    ctaText: FigNeutral.n100, // libelle sur ambre : noir
    ctaDisabledBg: const Color(0xFFDEDBD5), // bouton inactif
    ctaDisabledText: FigNeutral.n30,
    loginTitle: FigBrand.navy,
    loginSubtitle: FigBrand.navy,
    footerText: FigNeutral.n70,
  );

  /// Theme sombre — frames "Home DT" (960:6915) et "Login DT" (34:96).
  static final dark = GiColors(
    scaffold: FigDark.scaffold,
    card: FigDark.card,
    cardBorder: FigDark.cardBorder,
    innerBorder: FigDark.innerBorder,
    title: FigDark.title,
    textBody: FigDark.textBody,
    textMuted: FigDark.textMuted,
    textFaint: FigDark.textFaint,
    navbarBg: FigDark.navbarBg,
    navbarBorder: FigDark.navbarBorder,
    heroBorder: _amber20,
    headerChipBg: _white05,
    headerChipBorder: _white10,
    fieldBg: const Color(0xFF1A242D),
    fieldBorder: FigNeutral.n80,
    fieldBorderFocus: FigNeutral.n40,
    fieldText: FigNeutral.n10,
    fieldHint: FigNeutral.n40,
    eyeStroke: FigNeutral.n40,
    ctaBg: FigBrand.amber,
    ctaText: FigNeutral.n100,
    ctaDisabledBg: FigNeutral.n70,
    ctaDisabledText: FigNeutral.n40,
    loginTitle: FigBrand.cream,
    loginSubtitle: Colors.white,
    footerText: FigNeutral.n30,
  );

  static GiColors of(BuildContext context) =>
      Theme.of(context).extension<GiColors>() ?? light;

  @override
  GiColors copyWith({
    Color? scaffold,
    Color? card,
    Color? cardBorder,
    Color? innerBorder,
    Color? title,
    Color? textBody,
    Color? textMuted,
    Color? textFaint,
    Color? navbarBg,
    Color? navbarBorder,
    Color? heroBorder,
    Color? headerChipBg,
    Color? headerChipBorder,
    Color? fieldBg,
    Color? fieldBorder,
    Color? fieldBorderFocus,
    Color? fieldText,
    Color? fieldHint,
    Color? eyeStroke,
    Color? ctaBg,
    Color? ctaText,
    Color? ctaDisabledBg,
    Color? ctaDisabledText,
    Color? loginTitle,
    Color? loginSubtitle,
    Color? footerText,
  }) {
    return GiColors(
      scaffold: scaffold ?? this.scaffold,
      card: card ?? this.card,
      cardBorder: cardBorder ?? this.cardBorder,
      innerBorder: innerBorder ?? this.innerBorder,
      title: title ?? this.title,
      textBody: textBody ?? this.textBody,
      textMuted: textMuted ?? this.textMuted,
      textFaint: textFaint ?? this.textFaint,
      navbarBg: navbarBg ?? this.navbarBg,
      navbarBorder: navbarBorder ?? this.navbarBorder,
      heroBorder: heroBorder ?? this.heroBorder,
      headerChipBg: headerChipBg ?? this.headerChipBg,
      headerChipBorder: headerChipBorder ?? this.headerChipBorder,
      fieldBg: fieldBg ?? this.fieldBg,
      fieldBorder: fieldBorder ?? this.fieldBorder,
      fieldBorderFocus: fieldBorderFocus ?? this.fieldBorderFocus,
      fieldText: fieldText ?? this.fieldText,
      fieldHint: fieldHint ?? this.fieldHint,
      eyeStroke: eyeStroke ?? this.eyeStroke,
      ctaBg: ctaBg ?? this.ctaBg,
      ctaText: ctaText ?? this.ctaText,
      ctaDisabledBg: ctaDisabledBg ?? this.ctaDisabledBg,
      ctaDisabledText: ctaDisabledText ?? this.ctaDisabledText,
      loginTitle: loginTitle ?? this.loginTitle,
      loginSubtitle: loginSubtitle ?? this.loginSubtitle,
      footerText: footerText ?? this.footerText,
    );
  }

  /// Interpole les surfaces : la bascule clair/sombre devient une transition
  /// continue au lieu d'un saut brutal.
  @override
  GiColors lerp(ThemeExtension<GiColors>? other, double t) {
    if (other is! GiColors) return this;
    return GiColors(
      scaffold: Color.lerp(scaffold, other.scaffold, t)!,
      card: Color.lerp(card, other.card, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      innerBorder: Color.lerp(innerBorder, other.innerBorder, t)!,
      title: Color.lerp(title, other.title, t)!,
      textBody: Color.lerp(textBody, other.textBody, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textFaint: Color.lerp(textFaint, other.textFaint, t)!,
      navbarBg: Color.lerp(navbarBg, other.navbarBg, t)!,
      navbarBorder: Color.lerp(navbarBorder, other.navbarBorder, t)!,
      heroBorder: Color.lerp(heroBorder, other.heroBorder, t)!,
      headerChipBg: Color.lerp(headerChipBg, other.headerChipBg, t)!,
      headerChipBorder: Color.lerp(headerChipBorder, other.headerChipBorder, t)!,
      fieldBg: Color.lerp(fieldBg, other.fieldBg, t)!,
      fieldBorder: Color.lerp(fieldBorder, other.fieldBorder, t)!,
      fieldBorderFocus: Color.lerp(fieldBorderFocus, other.fieldBorderFocus, t)!,
      fieldText: Color.lerp(fieldText, other.fieldText, t)!,
      fieldHint: Color.lerp(fieldHint, other.fieldHint, t)!,
      eyeStroke: Color.lerp(eyeStroke, other.eyeStroke, t)!,
      ctaBg: Color.lerp(ctaBg, other.ctaBg, t)!,
      ctaText: Color.lerp(ctaText, other.ctaText, t)!,
      ctaDisabledBg: Color.lerp(ctaDisabledBg, other.ctaDisabledBg, t)!,
      ctaDisabledText: Color.lerp(ctaDisabledText, other.ctaDisabledText, t)!,
      loginTitle: Color.lerp(loginTitle, other.loginTitle, t)!,
      loginSubtitle: Color.lerp(loginSubtitle, other.loginSubtitle, t)!,
      footerText: Color.lerp(footerText, other.footerText, t)!,
    );
  }
}
