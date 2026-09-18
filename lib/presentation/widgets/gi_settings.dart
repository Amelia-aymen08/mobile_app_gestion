import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';
import '../theme/gi_colors.dart';
import 'gi_card.dart';
import 'gi_pressable.dart';

/// Interrupteur du Figma (447:1665) : 35 x 21, rayon 67,3, pastille blanche de
/// 16,15, marge interieure de 2,69. Ambre a l'etat actif, gris a l'arret.
///
/// La pastille glisse et la couleur se fond : un interrupteur qui bascule d'un
/// coup ne laisse pas voir dans quel sens il est parti.
class GiToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const GiToggle({super.key, required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) {
    const w = 35.0, h = 21.0, pad = 2.692, knob = 16.154;

    return GiPressable(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      pressedScale: 0.90,
      ensureMinTapTarget: true,
      child: Semantics(
        toggled: value,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          width: w,
          height: h,
          padding: const EdgeInsets.symmetric(horizontal: pad),
          alignment: value
              ? AlignmentDirectional.centerEnd
              : AlignmentDirectional.centerStart,
          decoration: BoxDecoration(
            color: value ? FigBrand.amber : const Color(0xFF959595),
            borderRadius: BorderRadius.circular(67.308),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            width: knob,
            height: knob,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

/// Section de reglages : un titre puis une carte unique contenant les lignes,
/// separees par un trait. Relevee sur "Setting LT" (837:4299).
/// Titre SemiBold 16, ecart de 12, carte au rayon 16.
class GiSettingsGroup extends StatelessWidget {
  final String title;
  final List<Widget> rows;

  const GiSettingsGroup({super.key, required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: FigText.titleMd.copyWith(color: c.textBody)),
        const SizedBox(height: FigSpace.lg),
        // Le rognage evite que la premiere et la derniere ligne debordent des
        // angles arrondis quand elles s'enfoncent a l'appui.
        ClipRRect(
          borderRadius: BorderRadius.circular(FigRadius.card),
          child: Container(
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(FigRadius.card),
              border: Border.all(color: c.cardBorder),
            ),
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0) Divider(height: 1, thickness: 1, color: c.innerBorder),
                  rows[i],
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Ligne de reglage : pastille d'icone, libelle, sous-titre facultatif, et a
/// l'oppose un chevron ou un interrupteur.
///
/// La pastille est volontairement neutre — noir a 3 % — et non teintee comme
/// sur l'accueil : le Figma reserve la couleur aux elements porteurs de sens.
class GiSettingsRow extends StatelessWidget {
  final Widget icon;
  final String label;
  final String? value;
  final VoidCallback? onTap;
  final Widget? trailing;

  const GiSettingsRow({
    super.key,
    required this.icon,
    required this.label,
    this.value,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final neutral = isDark
        ? Colors.white.withValues(alpha: 0.03)
        : Colors.black.withValues(alpha: 0.03);

    final content = Padding(
      padding: const EdgeInsets.all(FigSpace.cardPadding),
      child: Row(
        children: [
          Container(
            width: FigSize.chipSm,
            height: FigSize.chipSm,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: neutral,
              border: Border.all(color: neutral),
              borderRadius: BorderRadius.circular(FigRadius.pill),
            ),
            child: SizedBox(
              width: 16,
              height: 16,
              child: FittedBox(fit: BoxFit.contain, child: icon),
            ),
          ),
          const SizedBox(width: FigSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    style: FigText.statValue
                        .copyWith(height: 1.2, color: c.textBody)),
                if (value != null) ...[
                  const SizedBox(height: FigSpace.md),
                  Text(value!,
                      style: FigText.body.copyWith(color: c.textMuted)),
                ],
              ],
            ),
          ),
          const SizedBox(width: FigSpace.md),
          trailing ?? GiChevron(color: c.textMuted),
        ],
      ),
    );

    if (onTap == null) return content;
    return GiPressable(onTap: onTap, pressedScale: 0.985, child: content);
  }
}
