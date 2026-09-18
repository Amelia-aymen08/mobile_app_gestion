import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
///
/// L'icone est mise a l'echelle de la pastille plutot que laissee a sa taille
/// d'export. Les SVG exportes du Figma sont plus petits que leur cadre — l'art
/// de `alert_20` mesure 17,8 et non 20 — et rendus tels quels ils paraissent
/// maigres dans une pastille de 35. [iconRatio] fixe la part de la pastille
/// occupee par l'icone ; c'est le seul reglage a toucher pour les grossir ou
/// les reduire partout a la fois. Les proportions de chaque icone sont
/// conservees, seule sa taille change.
class GiIconChip extends StatelessWidget {
  final Widget icon;
  final Color accent;
  final double size;
  final double radius;

  /// Part de la pastille occupee par l'icone.
  static const iconRatio = 0.62;

  const GiIconChip({
    super.key,
    required this.icon,
    required this.accent,
    this.size = FigSize.chipLg,
    this.radius = FigRadius.chip,
  });

  @override
  Widget build(BuildContext context) {
    final inner = size * iconRatio;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: FigAccent.chipFill(accent),
        border: Border.all(color: FigAccent.chipBorder(accent)),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: SizedBox(
        width: inner,
        height: inner,
        child: FittedBox(fit: BoxFit.contain, child: icon),
      ),
    );
  }
}

/// Chevron de fin de ligne — asset du Figma, 9 x 8, a sa taille propre.
/// Il est retourne en lecture de droite a gauche pour pointer vers la sortie
/// de l'ecran, et non vers le bord dont on vient.
class GiChevron extends StatelessWidget {
  final Color? color;
  const GiChevron({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Transform.flip(
      flipX: rtl,
      child: SvgPicture.asset(
        'assets/figma/icons/chevron_row.svg',
        colorFilter: ColorFilter.mode(
            color ?? GiColors.of(context).textMuted, BlendMode.srcIn),
      ),
    );
  }
}
