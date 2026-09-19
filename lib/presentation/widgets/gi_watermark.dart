import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Filigrane des ecrans d'accueil — frames « Login LT » (0:5929) et sa
/// variante sombre : le symbole de la marque, pose hors cadre en haut a
/// gauche, tourne et a 6 % d'opacite.
///
/// L'asset vient du Figma : le symbole n'a pas change avec le nouveau nom, et
/// comme le texte est de toute facon hors cadre, c'est lui qui donne le rendu
/// exact de la maquette.
class GiWatermark extends StatelessWidget {
  final bool isDark;
  const GiWatermark({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final boxW = isDark ? 296.328 : 293.254;
    final boxH = isDark ? 265.163 : 246.49;
    final imgW = isDark ? 243.406 : 256.511;
    final imgH = isDark ? 180.316 : 194.426;
    final scale = isDark ? 1.5228 : 1.4829;

    return PositionedDirectional(
      start: isDark ? -122 : -128,
      top: isDark ? -69 : -56.7,
      child: IgnorePointer(
        child: SizedBox(
          width: boxW,
          height: boxH,
          child: Center(
            child: Transform.rotate(
              angle: (isDark ? -24.56 : -12.82) * math.pi / 180,
              child: Opacity(
                opacity: 0.06,
                child: SizedBox(
                  width: imgW,
                  height: imgH,
                  child: ClipRect(
                    child: OverflowBox(
                      maxHeight: double.infinity,
                      alignment: Alignment.topCenter,
                      child: Image.asset(
                        isDark
                            ? 'assets/figma/watermark_dark.png'
                            : 'assets/figma/watermark_light.png',
                        width: imgW,
                        height: imgH * scale,
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
