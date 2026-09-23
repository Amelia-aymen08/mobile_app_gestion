import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';
import '../theme/gi_colors.dart';
import 'gi_pressable.dart';

/// Bouton principal — composant CTA du Figma.
///
/// Geometrie : rayon 28, padding 40 x 16, libelle Montserrat Medium 16.
/// Actif   -> fond ambre #DB9200, libelle noir (les deux themes).
/// Inactif -> #DEDBD5 / #B2B2B2 en clair, #4C4C4C / #999999 en sombre.
///
/// Le passage inactif -> actif est anime : le bouton se colore a mesure que
/// le formulaire devient valide, au lieu de changer d'un coup.
class GiPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const GiPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
  });

  bool get _enabled => onPressed != null && !isLoading;

  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    final bg = _enabled ? c.ctaBg : c.ctaDisabledBg;
    final fg = _enabled ? c.ctaText : c.ctaDisabledText;

    return GiPressable(
      onTap: _enabled ? onPressed : null,
      pressedScale: 0.97,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        width: double.infinity,
        // 24 et non 40 : sur un bouton pleine largeur la difference ne se
        // voit pas, et sur un bouton etroit elle rend au libelle la place
        // qu'il lui faut pour rester a sa taille.
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(FigRadius.cta),
        ),
        child: Center(
          // Le chargement remplace le libelle sans changer la hauteur du
          // bouton, donc sans faire sauter la mise en page.
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: isLoading
                ? SizedBox(
                    key: const ValueKey('loading'),
                    height: FigText.button.fontSize! * 1.2,
                    width: FigText.button.fontSize! * 1.2,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(fg),
                    ),
                  )
                : AnimatedDefaultTextStyle(
                    key: const ValueKey('label'),
                    duration: const Duration(milliseconds: 220),
                    style: FigText.button.copyWith(color: fg),
                    // Le libelle se reduit plutot que de deborder : un
                    // bouton de largeur imposee, une traduction plus longue
                    // ou la police du systeme agrandie suffisent a le faire
                    // sortir du cadre.
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(label, maxLines: 1),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
