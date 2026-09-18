import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/design_tokens.dart';
import '../theme/gi_colors.dart';
import 'gi_pressable.dart';

/// Un onglet de la barre de navigation.
class GiNavItem {
  final String asset;
  final String label;
  final double iconSize;

  const GiNavItem({
    required this.asset,
    required this.label,
    this.iconSize = FigSize.navIcon,
  });
}

/// Barre de navigation flottante — frames Figma 928:2843 (LT) et 931:4053 (DT).
///
/// Geometrie relevee au pixel : largeur 359, rayon 40, padding 16, onglets de
/// 60 de large, ecart icone/libelle de 8, libelle 13.
///
/// L'animation de selection est volontairement sobre : l'icone fait une
/// impulsion breve puis revient a sa taille, pendant que la couleur passe au
/// dore. Le pic vient d'une sinusoide — il culmine a mi-parcours et retombe
/// exactement a zero, ce qui evite tout rebond residuel.
class GiBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<GiNavItem> items;

  const GiBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, FigSpace.navbarBottom),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(FigRadius.navbar),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 2.85, sigmaY: 2.85),
          child: Container(
            padding: const EdgeInsets.all(FigSpace.xl),
            decoration: BoxDecoration(
              color: c.navbarBg,
              borderRadius: BorderRadius.circular(FigRadius.navbar),
              border: Border.all(color: c.navbarBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 0; i < items.length; i++)
                  _GiNavTab(
                    item: items[i],
                    selected: i == currentIndex,
                    onTap: () => onTap(i),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GiNavTab extends StatelessWidget {
  final GiNavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _GiNavTab({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GiPressable(
      onTap: onTap,
      pressedScale: 0.90,
      child: SizedBox(
        width: FigSize.navItemW,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: selected ? 1 : 0, end: selected ? 1 : 0),
          duration: const Duration(milliseconds: 340),
          curve: Curves.easeOutCubic,
          builder: (context, t, _) {
            // Impulsion : nulle aux extremites, maximale au milieu.
            final pop = math.sin(t * math.pi);
            final color = Color.lerp(Colors.white, FigBrand.amber, t)!;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.translate(
                  offset: Offset(0, -3 * pop),
                  child: Transform.scale(
                    scale: 1 + 0.16 * pop,
                    child: SvgPicture.asset(
                      item.asset,
                      width: item.iconSize,
                      height: item.iconSize,
                      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                    ),
                  ),
                ),
                const SizedBox(height: FigSpace.md),
                DefaultTextStyle(
                  style: FigText.body.copyWith(
                    color: color,
                    fontWeight:
                        t > 0.5 ? FontWeight.w600 : FontWeight.w400,
                  ),
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
