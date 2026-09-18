import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/design_tokens.dart';
import '../theme/gi_colors.dart';
import 'gi_card.dart';
import 'gi_pressable.dart';

/// En-tete d'ecran du Figma : pastille d'icone de 35, puis le titre et son
/// sous-titre, et a l'oppose un compteur facultatif.
/// Releve sur "Notices LT" (837:1947) : ecart de 16, titre SemiBold 18,
/// sous-titre Regular 13, ecart interne de 2.
class GiScreenHeader extends StatelessWidget {
  final String iconAsset;
  final Color accent;
  final String title;
  final String subtitle;
  final String? badge;

  const GiScreenHeader({
    super.key,
    required this.iconAsset,
    required this.accent,
    required this.title,
    required this.subtitle,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    return Row(
      children: [
        GiIconChip(
          accent: accent,
          icon: SvgPicture.asset(iconAsset,
              colorFilter: ColorFilter.mode(accent, BlendMode.srcIn)),
        ),
        const SizedBox(width: FigSpace.xl),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: FigText.titleMd
                      .copyWith(fontSize: 18, color: c.textBody)),
              const SizedBox(height: 2),
              Text(subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: FigText.body.copyWith(color: c.textMuted)),
            ],
          ),
        ),
        if (badge != null) ...[
          const SizedBox(width: FigSpace.md),
          // Le compteur apparait en fondu : il change quand des elements sont
          // lus, et un changement sec attirerait l'oeil sans raison.
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Container(
              key: ValueKey(badge),
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: FigBrand.amber,
                borderRadius: BorderRadius.circular(FigRadius.pill),
              ),
              child: Text(badge!,
                  style: FigText.label
                      .copyWith(fontWeight: FontWeight.w500, color: Colors.black)),
            ),
          ),
        ],
      ],
    );
  }
}

/// Puce de filtre — composant "Fillter" du Figma (837:2468 et suivants).
/// Hauteur 28, rayon 20, padding 20 x 6, libelle 13.
/// Selectionnee, elle prend la surface sombre de la barre de navigation, y
/// compris en theme clair : c'est le parti pris de la maquette.
class GiFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const GiFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    return GiPressable(
      onTap: onTap,
      pressedScale: 0.94,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? c.navbarBg : c.card,
          border: Border.all(
              color: selected ? c.navbarBorder : c.cardBorder),
          borderRadius: BorderRadius.circular(20),
        ),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 220),
          style: FigText.body
              .copyWith(color: selected ? Colors.white : c.textMuted),
          child: Text(label),
        ),
      ),
    );
  }
}
