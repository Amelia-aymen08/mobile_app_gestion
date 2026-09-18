import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';
import '../theme/gi_colors.dart';

/// Etat vide du Figma — frames "Empty Notices" (837:1963), "Empty Reports"
/// (606:3670) et "Empty Payment" (606:4059).
///
/// Geometrie relevee sur Empty Notices : illustration de 157 x 176, puis le
/// bloc de texte a 249 de large, titre de 29 de haut (24 semi-gras) et corps
/// sur deux a trois lignes, le tout centre.
class GiEmptyState extends StatelessWidget {
  final String title;
  final String message;
  final double illustrationSize;

  /// Action facultative sous le texte. Le Figma en pose une sur l'etat vide
  /// des signalements (« Nouveau signalement »), aucune sur les avis.
  final Widget? action;

  const GiEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.illustrationSize = 176,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: illustrationSize * 157 / 176,
          height: illustrationSize,
          child: CustomPaint(
            painter: _AlertOutlinePainter(color: c.cardBorder),
          ),
        ),
        const SizedBox(height: 27),
        SizedBox(
          width: 269,
          child: Column(
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: FigText.greeting.copyWith(color: c.textBody),
              ),
              const SizedBox(height: FigSpace.xl),
              Text(
                message,
                textAlign: TextAlign.center,
                style: FigText.field.copyWith(height: 1.36, color: c.textMuted),
              ),
              if (action != null) ...[
                const SizedBox(height: FigSpace.xxl),
                action!,
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Point d'exclamation cercle, trace au trait.
///
/// L'illustration du Figma n'a pas pu etre exportee : le quota de lecture du
/// fichier est epuise. Elle est donc redessinee au plus pres de la maquette —
/// cercle ouvert, barre et point, trois rayons en haut a droite. A remplacer
/// par l'export SVG des que le fichier redevient accessible.
class _AlertOutlinePainter extends CustomPainter {
  final Color color;
  const _AlertOutlinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.height * 0.038;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    // Le cercle occupe le bas du cadre, les rayons debordent en haut a droite.
    final d = size.width * 0.92;
    final center = Offset(size.width * 0.46, size.height - d / 2 - stroke);
    final r = d / 2;

    // Cercle ouvert sur son quart superieur droit, ou passent les rayons.
    canvas.drawArc(Rect.fromCircle(center: center, radius: r),
        -math.pi * 0.28, math.pi * 1.86, false, paint);

    // Barre puis point du point d'exclamation.
    final barTop = center.dy - r * 0.52;
    final barBottom = center.dy + r * 0.10;
    canvas.drawLine(Offset(center.dx, barTop), Offset(center.dx, barBottom),
        Paint()
          ..color = color
          ..strokeWidth = stroke * 2.1
          ..strokeCap = StrokeCap.round);
    canvas.drawCircle(
        Offset(center.dx, center.dy + r * 0.42), stroke * 1.15, Paint()..color = color);

    // Trois rayons, de plus en plus courts en s'eloignant de la verticale.
    for (final entry in [(-0.10, 0.34), (0.16, 0.30), (0.42, 0.24)]) {
      final angle = -math.pi / 2 + entry.$1 * math.pi;
      final from = center + Offset(math.cos(angle), math.sin(angle)) * (r * 1.16);
      final to = center +
          Offset(math.cos(angle), math.sin(angle)) * (r * (1.16 + entry.$2));
      canvas.drawLine(from, to, paint);
    }
  }

  @override
  bool shouldRepaint(_AlertOutlinePainter old) => old.color != color;
}
