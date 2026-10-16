import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';
import '../theme/gi_colors.dart';

/// Chargement sans cercle qui tourne : la forme de la page apparait tout de
/// suite, en os gris, et un reflet de lumiere la balaie en diagonale, comme
/// dans les grandes apps. On voit ou le contenu va arriver, et l'attente
/// parait plus courte qu'avec une roue au milieu d'un ecran vide.

/// Teinte des os : un cran au-dessus de la surface des cartes.
Color _boneColor(GiColors c, bool dark) =>
    dark ? const Color(0xFF17212B) : const Color(0xFFE3DFD7);

/// Fait passer le reflet sur [child]. Tout ce qui est opaque dessous
/// s'eclaire au passage ; le reste ne change pas.
class GiShimmer extends StatefulWidget {
  final Widget child;
  const GiShimmer({super.key, required this.child});

  @override
  State<GiShimmer> createState() => _GiShimmerState();
}

class _GiShimmerState extends State<GiShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final base = _boneColor(c, dark);
    final light = dark ? const Color(0xFF2A3644) : const Color(0xFFF7F4EE);

    return AnimatedBuilder(
      animation: _ctrl,
      child: widget.child,
      builder: (context, child) {
        // Le reflet traverse de -1 a 2 : il entre et sort tout entier du
        // cadre, puis une courte pause avant le passage suivant.
        final x = -1.0 + 3.0 * Curves.easeInOut.transform(_ctrl.value);
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (rect) => LinearGradient(
            begin: Alignment(x - 1, -0.3),
            end: Alignment(x, 0.3),
            colors: [base, light, base],
            stops: const [0.25, 0.5, 0.75],
          ).createShader(rect),
          child: child,
        );
      },
    );
  }
}

/// Un os : un bloc arrondi a la place d'un texte, d'une image ou d'un bouton.
class GiBone extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  final BoxShape shape;

  const GiBone({
    super.key,
    this.width,
    this.height = 12,
    this.radius = 6,
    this.shape = BoxShape.rectangle,
  });

  const GiBone.circle({super.key, required double size})
      : width = size,
        height = size,
        radius = 0,
        shape = BoxShape.circle;

  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: _boneColor(c, dark),
        shape: shape,
        borderRadius:
            shape == BoxShape.circle ? null : BorderRadius.circular(radius),
      ),
    );
  }
}

/// Squelette d'une carte de liste : pastille, deux lignes de texte, et une
/// pilule a droite — la silhouette commune des signalements, avis,
/// paiements, documents et notifications.
class GiSkeletonCard extends StatelessWidget {
  final double height;
  const GiSkeletonCard({super.key, this.height = 84});

  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    return Container(
      height: height,
      padding: const EdgeInsets.all(FigSpace.cardPadding),
      decoration: BoxDecoration(
        color: c.card,
        border: Border.all(color: c.cardBorder),
        borderRadius: BorderRadius.circular(FigRadius.card),
      ),
      child: const Row(
        children: [
          GiBone(width: 40, height: 40, radius: 10),
          SizedBox(width: FigSpace.lg),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FractionallySizedBox(
                    widthFactor: 0.7, child: GiBone(height: 13)),
                SizedBox(height: 10),
                FractionallySizedBox(
                    widthFactor: 0.45, child: GiBone(height: 10)),
              ],
            ),
          ),
          SizedBox(width: FigSpace.lg),
          GiBone(width: 54, height: 20, radius: 10),
        ],
      ),
    );
  }
}

/// Page en chargement : une grande carte en tete puis des cartes de liste,
/// le tout sous le reflet. Remplace le cercle au centre d'un ecran vide.
class GiSkeletonList extends StatelessWidget {
  final int count;
  final double itemHeight;

  /// Une carte haute en tete, pour les ecrans qui ouvrent sur une photo ou
  /// un resume (residence, paiements).
  final bool hero;
  final EdgeInsetsGeometry padding;

  const GiSkeletonList({
    super.key,
    this.count = 5,
    this.itemHeight = 84,
    this.hero = false,
    this.padding = const EdgeInsets.fromLTRB(
        FigSpace.pagePadding, FigSpace.xs, FigSpace.pagePadding, 0),
  });

  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    return GiShimmer(
      // A sa hauteur de contenu : le squelette se pose aussi bien seul dans
      // un Expanded qu'au milieu d'une liste qui defile deja.
      child: ListView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: padding,
        children: [
          if (hero) ...[
            Container(
              height: FigSize.heroH,
              decoration: BoxDecoration(
                color: c.card,
                border: Border.all(color: c.cardBorder),
                borderRadius: BorderRadius.circular(FigRadius.card),
              ),
              padding: const EdgeInsets.all(FigSpace.cardPadding),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GiBone(width: 90, height: 10),
                  SizedBox(height: 10),
                  GiBone(width: 160, height: 18),
                  Spacer(),
                  GiBone(height: 52, radius: 14),
                ],
              ),
            ),
            const SizedBox(height: FigSpace.lg),
          ],
          for (var i = 0; i < count; i++) ...[
            if (i > 0) const SizedBox(height: FigSpace.lg),
            GiSkeletonCard(height: itemHeight),
          ],
        ],
      ),
    );
  }
}

/// A brancher sur `Image.network(loadingBuilder: ...)` : tant que l'image
/// arrive, un os sous reflet occupe sa place au lieu d'un trou noir.
Widget giImageLoading(
    BuildContext context, Widget child, ImageChunkEvent? progress) {
  if (progress == null) return child;
  return const GiShimmer(child: GiBone(height: double.infinity, radius: 0));
}
