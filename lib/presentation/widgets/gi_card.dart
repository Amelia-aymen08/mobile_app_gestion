import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';
import '../theme/gi_colors.dart';
import 'gi_pressable.dart';

/// Surface de carte du Figma : fond plein, trait de 1, rayon 16, padding 16.
/// Presente sur les cartes de stats, les tuiles d'actions et les lignes
/// d'activite de l'accueil (frames 927:7894 et 960:6915).
class GiCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double radius;
  final Color? borderColor;
  final double? width;

  const GiCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(FigSpace.cardPadding),
    this.onTap,
    this.radius = FigRadius.card,
    this.borderColor,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    final surface = Container(
      width: width,
      padding: padding,
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? c.cardBorder),
      ),
      child: child,
    );
    if (onTap == null) return surface;
    return GiPressable(onTap: onTap, child: surface);
  }
}

/// Pastille d'icone teintee. Le Figma applique partout la meme recette :
/// fond a 5 % de la teinte, trait a 10 %, dans les deux themes.
class GiIconChip extends StatelessWidget {
  final Widget icon;
  final Color accent;
  final double size;
  final double radius;

  const GiIconChip({
    super.key,
    required this.icon,
    required this.accent,
    this.size = FigSize.chipLg,
    this.radius = FigRadius.chip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: FigAccent.chipFill(accent),
        border: Border.all(color: FigAccent.chipBorder(accent)),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: icon,
    );
  }
}

/// Chevron de fin de ligne : 7 x 8,615 dans le Figma, oriente par le sens de
/// lecture pour que l'arabe le renvoie vers la gauche.
class GiChevron extends StatelessWidget {
  final Color? color;
  const GiChevron({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Transform.flip(
      flipX: rtl,
      child: Icon(
        Icons.chevron_right_rounded,
        size: 18,
        color: color ?? GiColors.of(context).textMuted,
      ),
    );
  }
}
