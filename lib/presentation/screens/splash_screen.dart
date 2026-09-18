import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';
import '../theme/gi_colors.dart';

/// Splash — frames Figma "Splash 1 LT" (0:6001) et sa variante sombre.
///
/// Composition de la maquette : fond uni, halo dore montant du bas, logo de
/// 164 x 184 centre, et la signature de marque a 70 du bas.
///
/// L'animation se joue en trois temps, du fond vers le detail : le halo
/// monte, le logo apparait en grandissant legerement, puis la signature se
/// devoile. Chaque element part un peu apres le precedent — c'est ce decalage
/// qui donne l'impression d'une mise en place, et non d'un affichage.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return Scaffold(
      backgroundColor: c.scaffold,
      body: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final v = reduceMotion ? 1.0 : _c.value;

          double phase(double start, double end, Curve curve) =>
              curve.transform(Interval(start, end).transform(v).clamp(0.0, 1.0));

          final halo = phase(0.00, 0.70, Curves.easeOut);
          final logo = phase(0.10, 0.75, Curves.easeOutCubic);
          final sign = phase(0.45, 1.00, Curves.easeOutCubic);

          return Stack(
            fit: StackFit.expand,
            children: [
              // Halo dore du Figma : transparent aux trois quarts de la
              // hauteur, puis or a 50 % en debordant sous le bord bas.
              Opacity(
                opacity: halo,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.73, 1.0],
                      colors: [
                        const Color(0x00666666),
                        FigBrand.goldDark.withValues(alpha: isDark ? 0.35 : 0.5),
                      ],
                    ),
                  ),
                ),
              ),
              Center(
                child: Opacity(
                  opacity: logo,
                  // Le logo grandit a peine : au-dela, l'entree tire l'oeil
                  // plus que la marque elle-meme.
                  child: Transform.scale(
                    scale: 0.94 + 0.06 * logo,
                    child: Image.asset(
                      isDark
                          ? 'assets/brand/gis_logo_vertical_dark.png'
                          : 'assets/brand/gis_logo_vertical_light.png',
                      height: 184,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 70,
                child: Opacity(
                  opacity: sign,
                  child: Transform.translate(
                    offset: Offset(0, 12 * (1 - sign)),
                    child: Text(
                      'Frappez à la bonne porte.',
                      textAlign: TextAlign.center,
                      // Le Figma emploie une police manuscrite, « Photograph
                      // Signature », qui n'est pas fournie avec le fichier.
                      // En attendant, Montserrat en italique leger conserve
                      // l'intention sans introduire une police approximative.
                      style: FigText.field.copyWith(
                        fontSize: 20,
                        letterSpacing: 1.6,
                        fontStyle: FontStyle.italic,
                        color: c.textBody,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
