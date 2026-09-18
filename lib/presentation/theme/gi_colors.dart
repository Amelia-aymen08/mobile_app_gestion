import 'package:flutter/material.dart';
import 'design_tokens.dart';

/// Surfaces du design Figma, exposees via le theme pour qu'un widget n'ait
/// jamais a tester lui-meme si l'app est en clair ou en sombre.
///
/// Usage : `final c = GiColors.of(context);`
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
  });

  /// Thème clair — frame "Home LT" (927:7894).
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
    heroBorder: FigBrand.amber.withValues(alpha: 0.20),
    headerChipBg: Colors.black.withValues(alpha: 0.05),
    headerChipBorder: Colors.black.withValues(alpha: 0.02),
  );

  /// Thème sombre — frame "Home DT" (960:6915).
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
    heroBorder: FigBrand.amber.withValues(alpha: 0.20),
    headerChipBg: Colors.white.withValues(alpha: 0.05),
    headerChipBorder: Colors.white.withValues(alpha: 0.10),
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
    );
  }
}
