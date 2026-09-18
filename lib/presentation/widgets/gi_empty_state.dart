import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/design_tokens.dart';
import '../theme/gi_colors.dart';

/// Etat vide du Figma — frames "Empty Notices" (0:5300), "Empty Reports" et
/// "Empty Payment".
///
/// Geometrie relevee : illustration de 157 x 176, puis le bloc de texte a 16
/// d'ecart, titre Medium 24 et corps Regular 15 sur 249 de large, le tout
/// centre. Le titre est en Medium et non en SemiBold, contrairement aux
/// titres de section.
///
/// L'illustration vient du fichier Figma et garde sa taille propre : c'est
/// elle qui porte les proportions de la maquette.
class GiEmptyState extends StatelessWidget {
  final String title;
  final String message;

  /// Illustration du Figma. Sans elle, l'etat vide se contente du texte —
  /// preferable a un dessin approximatif qui jurerait avec le reste.
  final String? illustration;

  /// Action facultative sous le texte. Le Figma en pose une sur l'etat vide
  /// des signalements, aucune sur les avis.
  final Widget? action;

  const GiEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.illustration,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (illustration != null) ...[
          SvgPicture.asset(
            illustration!,
            colorFilter: ColorFilter.mode(c.cardBorder, BlendMode.srcIn),
          ),
          const SizedBox(height: 27),
        ],
        Text(
          title,
          textAlign: TextAlign.center,
          style: FigText.greeting
              .copyWith(fontWeight: FontWeight.w500, color: c.textBody),
        ),
        const SizedBox(height: FigSpace.xl),
        SizedBox(
          width: 249,
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: FigText.field
                .copyWith(fontSize: 15, height: 1.2, color: c.textMuted),
          ),
        ),
        if (action != null) ...[
          const SizedBox(height: FigSpace.xxl),
          action!,
        ],
      ],
    );
  }
}
