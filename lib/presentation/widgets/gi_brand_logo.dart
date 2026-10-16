import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/design_tokens.dart';

/// Logo vertical de Gerance Immo Service, dessine plutot qu'affiche.
///
/// L'ancien logo etait une image de 716 pixels : agrandie, reduite puis
/// reagrandie selon l'ecran, elle paraissait floue, surtout sur le splash.
/// Ici le monogramme est un trace vectoriel releve sur cette image, et
/// « GERANCE IMMO / SERVICE » est ecrit en Montserrat, la police du logo :
/// tout reste net a n'importe quelle taille et sur n'importe quel ecran.
///
/// Les positions reprennent celles de l'image, sur sa grille de 716 : le
/// rendu se superpose a l'original.
class GiBrandLogo extends StatelessWidget {
  /// Hauteur du logo ; la largeur est la meme, le logo tient dans un carre.
  final double height;
  final Color color;

  const GiBrandLogo({super.key, required this.height, required this.color});

  /// Creme du logo sur fond sombre, encre sur fond clair : les teintes
  /// exactes de l'image d'origine.
  static Color colorFor(Brightness brightness) => brightness == Brightness.dark
      ? const Color(0xFFF4F1EA)
      : const Color(0xFF15191D);

  static const double _grid = 716;

  @override
  Widget build(BuildContext context) {
    final u = height / _grid;
    return SizedBox(
      width: height,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 84.7 * u,
            top: 0.5 * u,
            width: 394.8 * u,
            height: 431.5 * u,
            child: SvgPicture.asset(
              'assets/brand/gis_monogram.svg',
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _WordmarkPainter(color: color, unit: u),
            ),
          ),
        ],
      ),
    );
  }
}

/// Les deux lignes du nom, calees sur leurs capitales : la hauteur des
/// capitales fixe le corps, la largeur de la ligne fixe l'interlettrage.
class _WordmarkPainter extends CustomPainter {
  final Color color;
  final double unit;

  const _WordmarkPainter({required this.color, required this.unit});

  /// Une ligne calee sur l'encre de l'image d'origine : [inkTop] et
  /// [inkHeight] bornent les lettres (debordements des O et des S compris),
  /// [left] et [width] leur etendue. [inkRatio] est la hauteur d'encre de
  /// la ligne en fraction du corps, [bearingLeft] et [bearings] les
  /// approches de Montserrat — l'espace vide autour des lettres, que
  /// Flutter compte dans la largeur du texte mais qui ne s'imprime pas.
  /// Ces trois valeurs ont ete mesurees sur le rendu, a la grille de 716.
  void _line(Canvas canvas, String text,
      {required double left,
      required double inkTop,
      required double inkHeight,
      required double width,
      required double inkRatio,
      required double bearingLeft,
      required double bearings}) {
    final fontSize = inkHeight / inkRatio * unit;
    TextPainter layout(double spacing) => TextPainter(
          text: TextSpan(
            text: text,
            style: TextStyle(
              fontFamily: FigText.family,
              fontSize: fontSize,
              fontWeight: FontWeight.w400,
              height: 1,
              letterSpacing: spacing,
              color: color,
            ),
          ),
          textDirection: TextDirection.ltr,
          maxLines: 1,
        )..layout();

    // Flutter ajoute l'interlettrage apres chaque lettre, la derniere
    // comprise : il ne compte que n - 1 fois dans la largeur visible.
    final natural = layout(0).width;
    final spacing =
        ((width + bearings) * unit - natural) / (text.length - 1);
    final painter = layout(spacing);
    final baseline =
        painter.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    painter.paint(
      canvas,
      Offset((left - bearingLeft) * unit,
          (inkTop + inkHeight) * unit - baseline),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    _line(canvas, 'GERANCE IMMO',
        left: 13, inkTop: 499, inkHeight: 60, width: 702,
        inkRatio: 0.7117, bearingLeft: 3.9, bearings: 9.8);
    _line(canvas, 'SERVICE',
        left: 0, inkTop: 596, inkHeight: 118, width: 715,
        inkRatio: 0.7178, bearingLeft: 8.9, bearings: 21.5);
  }

  @override
  bool shouldRepaint(_WordmarkPainter old) =>
      old.color != color || old.unit != unit;
}
