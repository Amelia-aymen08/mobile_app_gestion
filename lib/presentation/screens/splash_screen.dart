import 'package:flutter/material.dart';
import '../widgets/gi_brand_logo.dart';

import '../../l10n/app_localizations.dart';
import '../theme/design_tokens.dart';
import '../theme/gi_colors.dart';

/// Splash — frames Figma "Splash 1 LT" (0:6001) et sa variante sombre.
///
/// Composition de la maquette : fond uni, halo dore montant du bas et logo
/// de 164 x 184 centre.
///
/// L'animation va du fond vers le detail : le halo monte, puis le logo
/// apparait en grandissant legerement. Ce decalage donne l'impression d'une
/// mise en place, et non d'un simple affichage.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    final t = AppL10n.of(context);
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

          // Le logo est deja la, bien visible, des la premiere image : il ne
          // « grandit » plus depuis un point minuscule. L'animation se
          // contente de l'asseoir, et le halo monte derriere lui.
          final halo = phase(0.00, 0.70, Curves.easeOut);
          final logo = phase(0.00, 0.45, Curves.easeOutCubic);
          // La signature arrive apres le logo : d'abord la marque, puis ce
          // qu'elle promet.
          final slogan = phase(0.35, 0.90, Curves.easeOutCubic);

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
                  // Jamais completement transparent : le logo apparait pose,
                  // pas surgi de nulle part.
                  opacity: 0.35 + 0.65 * logo,
                  // Le logo grandit a peine : au-dela, l'entree tire l'oeil
                  // plus que la marque elle-meme.
                  child: Transform.scale(
                    scale: 0.985 + 0.015 * logo,
                    // Logo vectoriel : l'image d'avant, decodee a 460 pixels
                    // pour un affichage qui en demande plus de 550, sortait
                    // floue.
                    child: GiBrandLogo(
                      height: 184,
                      color: GiBrandLogo.colorFor(
                          isDark ? Brightness.dark : Brightness.light),
                    ),
                  ),
                ),
              ),
              PositionedDirectional(
                start: FigSpace.pagePadding,
                end: FigSpace.pagePadding,
                bottom: 70,
                child: Opacity(
                  opacity: slogan,
                  child: Transform.translate(
                    offset: Offset(0, 10 * (1 - slogan)),
                    child: Text(
                      t.splashSlogan,
                      textAlign: TextAlign.center,
                      // Gris clair et graisse medium : en gris moyen et en
                      // regular sur le halo dore, le texte paraissait flou.
                      style: FigText.field.copyWith(
                        height: 1.3,
                        letterSpacing: 0.4,
                        fontWeight: FontWeight.w500,
                        color: GiBrandLogo.colorFor(
                                isDark ? Brightness.dark : Brightness.light)
                            .withValues(alpha: 0.82),
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
