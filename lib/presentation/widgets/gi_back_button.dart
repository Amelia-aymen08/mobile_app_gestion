import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/design_tokens.dart';
import '../theme/gi_colors.dart';
import 'gi_pressable.dart';

/// Bouton retour commun a toute l'app : la pastille carree aux coins
/// arrondis des en-tetes, fleche vers la gauche (vers la droite en arabe).
///
/// Le meme partout, y compris pose sur une photo ou une carte : un seul
/// bouton retour a reconnaitre d'un ecran a l'autre. Sur une image, seul le
/// fond change : plein, pour rester lisible sur n'importe quelle photo.
class GiBackButton extends StatelessWidget {
  /// Par defaut, ferme l'ecran.
  final VoidCallback? onTap;

  /// Pose sur une photo ou une carte plutot que sur le fond de page.
  final bool overMedia;

  const GiBackButton({super.key, this.onTap, this.overMedia = false});

  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    return GiPressable(
      onTap: onTap ?? () => Navigator.maybePop(context),
      pressedScale: 0.88,
      child: Container(
        width: FigSize.chipMd,
        height: FigSize.chipMd,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: overMedia ? c.scaffold : c.headerChipBg,
          border: Border.all(color: c.headerChipBorder),
          borderRadius: BorderRadius.circular(FigRadius.chip),
          boxShadow: overMedia
              ? const [
                  BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 12,
                      offset: Offset(0, 3)),
                ]
              : null,
        ),
        child: Transform.flip(
          flipX: Directionality.of(context) == TextDirection.rtl,
          child: SvgPicture.asset(
            'assets/figma/icons/back_14.svg',
            colorFilter: ColorFilter.mode(c.textBody, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }
}
