import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../l10n/app_localizations.dart';
import '../theme/design_tokens.dart';
import '../theme/gi_colors.dart';
import '../widgets/gi_pressable.dart';

/// Onboarding — frames Figma "Onboarding 1/2/3" en clair (721:7329, 721:7315,
/// 721:7302) et en sombre (41:10).
///
/// Aucun glissement de page : le fond, les points et les boutons restent en
/// place et se transforment. Seuls le titre et le paragraphe sortent puis
/// reviennent, decales l'un apres l'autre. C'est ce qui donne l'impression que
/// le contenu avance au lieu que l'ecran defile.
///
/// A noter : les trois frames du Figma montrent toutes le premier point actif.
/// La maquette ne fait jamais progresser l'indicateur ; on le fait ici.
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  /// Photos de fond, dans l'ordre des frames du Figma.
  static const _photos = [
    'assets/onboarding-who-we-are.jpg',
    'assets/figma/onboarding/photo_2.jpg',
    'assets/figma/onboarding/photo_3.jpg',
  ];

  /// Page demandee : pilote les points, le fond et les boutons, tout de suite.
  int _page = 0;

  /// Page dont le texte est affiche : change au creux de l'animation, pour que
  /// l'ancien texte ait fini de sortir avant que le nouveau entre.
  int _shown = 0;

  bool _forward = true;

  /// Distance parcourue par le doigt pendant le glissement en cours.
  double _dragOffset = 0;
  bool _busy = false;

  late final AnimationController _text = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
    value: 1,
  );

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  bool get _isLast => _page == _photos.length - 1;

  Future<void> _goTo(int target) async {
    if (_busy || target == _page || target < 0 || target >= _photos.length) {
      return;
    }
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    _busy = true;
    _forward = target > _page;
    setState(() => _page = target);

    if (reduceMotion) {
      setState(() => _shown = target);
      _busy = false;
      return;
    }

    await _text.reverse();
    if (!mounted) return;
    setState(() => _shown = target);
    await _text.forward();
    _busy = false;
  }

  void _next() => _isLast ? widget.onComplete() : _goTo(_page + 1);

  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    final t = AppL10n.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final titles = [t.onbTitle1, t.onbTitle2, t.onbTitle3];
    final bodies = [t.onbBody1, t.onbBody2, t.onbBody3];

    return Scaffold(
      backgroundColor: c.scaffold,
      body: GestureDetector(
        // Un glissement compte de deux facons : vif, ou simplement long.
        // Ne regarder que la vitesse ignorait les gestes poses, et l'ecran
        // paraissait ne pas repondre.
        onHorizontalDragStart: (_) => _dragOffset = 0,
        onHorizontalDragUpdate: (details) => _dragOffset += details.delta.dx,
        onHorizontalDragEnd: (details) {
          final velocity = details.primaryVelocity ?? 0;
          final distance = _dragOffset;
          _dragOffset = 0;
          final backward = velocity > 120 || distance > 60;
          final forward = velocity < -120 || distance < -60;
          if (!backward && !forward) return;
          // En arabe l'interface est inversee : le geste doit l'etre aussi.
          final rtl = Directionality.of(context) == TextDirection.rtl;
          final goForward = rtl ? backward : forward;
          _goTo(_page + (goForward ? 1 : -1));
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Le fond ne glisse pas : il se substitue en fondu.
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 620),
              child: _Photo(
                key: ValueKey(_page),
                asset: _photos[_page],
              ),
            ),
            const _Scrim(),
            Align(
              alignment: Alignment.bottomCenter,
              child: _BottomBlock(
                isDark: isDark,
                page: _page,
                pageCount: _photos.length,
                isLast: _isLast,
                animation: _text,
                forward: _forward,
                title: titles[_shown],
                body: bodies[_shown],
                onSkip: widget.onComplete,
                onNext: _next,
                skipLabel: t.skip,
                nextLabel: _isLast ? t.getStarted : t.next,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Photo de fond. Le Figma zoome fortement dans chaque image ; `cover` en
/// reproduit l'esprit sans figer un cadrage qui ne tiendrait pas sur les
/// ecrans plus hauts ou plus etroits.
class _Photo extends StatelessWidget {
  final String asset;
  const _Photo({super.key, required this.asset});

  // SizedBox.expand est indispensable : AnimatedSwitcher ne transmet pas les
  // contraintes d'expansion du Stack a son enfant. Sans lui, l'image se cadre
  // sur son ratio naturel et laisse une bande vide en haut de l'ecran.
  @override
  Widget build(BuildContext context) => SizedBox.expand(
        child: Image.asset(
          asset,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          errorBuilder: (_, __, ___) =>
              ColoredBox(color: GiColors.of(context).scaffold),
        ),
      );
}

/// Degrade qui eteint la photo vers le bas pour rendre le texte lisible.
/// Figma : transparent a 14,5 % de la hauteur, puis creme a 46,8 % d'opacite
/// en clair, noir a 90 % en sombre, a 61,6 % de la hauteur.
class _Scrim extends StatelessWidget {
  const _Scrim();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.145, 0.616, 1.0],
          colors: isDark
              ? [
                  const Color(0x00666666),
                  Colors.black.withValues(alpha: 0.90),
                  Colors.black.withValues(alpha: 0.90),
                ]
              : [
                  const Color(0x00666666),
                  FigBrand.cream.withValues(alpha: 0.468),
                  FigBrand.cream.withValues(alpha: 0.468),
                ],
        ),
      ),
    );
  }
}

class _BottomBlock extends StatelessWidget {
  final bool isDark;
  final int page;
  final int pageCount;
  final bool isLast;
  final Animation<double> animation;
  final bool forward;
  final String title;
  final String body;
  final String skipLabel;
  final String nextLabel;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  const _BottomBlock({
    required this.isDark,
    required this.page,
    required this.pageCount,
    required this.isLast,
    required this.animation,
    required this.forward,
    required this.title,
    required this.body,
    required this.skipLabel,
    required this.nextLabel,
    required this.onSkip,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = isDark ? FigBrand.amber : FigBrand.navy;
    final bodyColor = isDark ? FigNeutral.n20 : FigNeutral.n80;

    // Figma : le bloc « All Content » occupe les 360 derniers pixels. Cette
    // hauteur suppose la police du systeme a sa taille normale et un ecran
    // en portrait. Elle suit donc l'agrandissement du texte, sans jamais
    // depasser les trois quarts de l'ecran — au-dela, la photo disparaitrait.
    final screenHeight = MediaQuery.sizeOf(context).height;
    final scaled = MediaQuery.textScalerOf(context).scale(360);
    final blockHeight =
        math.min(math.max(360.0, scaled), screenHeight * 0.74);
    // Ecran court — paysage, tres petit telephone : le haut du bloc se
    // resserre et les reperes de position s'effacent, faute de place.
    final short = screenHeight < 620;

    return SafeArea(
      top: false,
      child: SizedBox(
        height: blockHeight,
        child: ClipRect(
          child: Stack(
            children: [
              // L'arc, dessine en premier pour rester derriere le texte.
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 462,
                child: OverflowBox(
                  maxWidth: double.infinity,
                  alignment: Alignment.topCenter,
                  child: _Arc(isDark: isDark),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(FigSpace.pagePadding,
                    short ? 24 : 75, FigSpace.pagePadding, short ? 16 : 29),
                child: _content(titleColor, bodyColor, short),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content(Color titleColor, Color bodyColor, bool short) {
    return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          // Les reperes restent en haut du bloc et les boutons en bas :
          // l'espace libre se place entre les deux, et le texte prend ce
          // qu'il lui faut sans jamais pousser les boutons hors du cadre.
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (!short)
              _Dots(count: pageCount, current: page, isDark: isDark)
            else
              const SizedBox.shrink(),
            // Hauteur reservee au texte : sans elle, les boutons remonteraient
            // et redescendraient a chaque changement de slide. Le texte
            // defile s'il ne tient pas — police du systeme agrandie, ecran
            // etroit — plutot que d'etre coupe.
            Flexible(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 129),
                  child: _AnimatedText(
                    animation: animation,
                    forward: forward,
                    title: title,
                    body: body,
                    titleColor: titleColor,
                    bodyColor: bodyColor,
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // « Passer » disparait sur la derniere slide, sans deplacer le
                // bouton principal qui reste ancre a droite.
                AnimatedOpacity(
                  opacity: isLast ? 0 : 1,
                  duration: const Duration(milliseconds: 240),
                  child: IgnorePointer(
                    ignoring: isLast,
                    child: GiPressable(
                      pressedScale: 0.94,
                      onTap: onSkip,
                      child: Text(
                        skipLabel,
                        style: FigText.button.copyWith(
                          color: isDark ? FigNeutral.n10 : Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
                _NextButton(label: nextLabel, onTap: onNext),
              ],
            ),
          ],
    );
  }
}

/// « Ellipse 4 » du Figma : une ellipse de 645 x 462, plus large que l'ecran,
/// donc seule la partie centrale de sa courbe apparait — c'est elle qui trace
/// l'arc au-dessus du texte.
///
/// Volontairement sans flou d'arriere-plan, bien que l'export Figma annonce
/// `blur(74.85px)`. A cette valeur, la photo est entierement effacee sous
/// l'arc, alors que la maquette laisse voir les balcons nettement. Meme un
/// sigma de 6 detruit deja le detail. La valeur exportee ne correspond donc
/// pas a ce que Figma affiche ; on garde ses opacites et on retire le flou,
/// ce qui reproduit le rendu de la maquette et evite au passage un
/// BackdropFilter, couteux sur mobile.
class _Arc extends StatelessWidget {
  final bool isDark;
  const _Arc({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 645,
      height: 462,
      // ClipOval inscrit une ellipse dans la boite : 645 x 462. Un
      // BoxShape.circle dessinerait un cercle du cote le plus court.
      child: ClipOval(
        child: ColoredBox(
          // Figma : creme a 60 % en clair, navy a 50 % en sombre.
          color: isDark
              ? FigBrand.navy.withValues(alpha: 0.50)
              : FigBrand.cream.withValues(alpha: 0.60),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

/// Indicateur de progression. Le point actif s'etire de 8 a 28 au lieu de
/// simplement changer de couleur : l'oeil suit l'allongement.
class _Dots extends StatelessWidget {
  final int count;
  final int current;
  final bool isDark;

  const _Dots({required this.count, required this.current, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final idle = isDark ? FigNeutral.n20 : FigNeutral.n40;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 340),
            curve: Curves.easeOutCubic,
            // Figma : l'indicateur mesure 48 (28 + 2 + 8 + 2 + 8). L'ecart de
            // 2 separe les points, il ne suit donc pas le dernier.
            margin: EdgeInsetsDirectional.only(end: i == count - 1 ? 0 : 2),
            width: i == current ? 28 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == current ? FigBrand.amber : idle,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
      ],
    );
  }
}

/// Titre et paragraphe. Ils sortent puis reviennent dans le sens du geste,
/// le paragraphe avec un retard sur le titre.
class _AnimatedText extends StatelessWidget {
  final Animation<double> animation;
  final bool forward;
  final String title;
  final String body;
  final Color titleColor;
  final Color bodyColor;

  const _AnimatedText({
    required this.animation,
    required this.forward,
    required this.title,
    required this.body,
    required this.titleColor,
    required this.bodyColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final v = animation.value;
        final titleT = const Interval(0.0, 0.65, curve: Curves.easeOutCubic)
            .transform(v);
        final bodyT = const Interval(0.30, 1.0, curve: Curves.easeOutCubic)
            .transform(v);
        final dir = forward ? 1.0 : -1.0;

        Widget shift(double t, Widget child) => Opacity(
              opacity: t,
              child: Transform.translate(
                offset: Offset((1 - t) * 28 * dir, 0),
                child: child,
              ),
            );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            shift(
              titleT,
              Text(title,
                  style: FigText.display
                      .copyWith(fontSize: 24, color: titleColor)),
            ),
            const SizedBox(height: FigSpace.lg),
            shift(
              bodyT,
              Text(body,
                  style: FigText.field
                      .copyWith(height: 1.36, color: bodyColor)),
            ),
          ],
        );
      },
    );
  }
}

class _NextButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _NextButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GiPressable(
      onTap: onTap,
      pressedScale: 0.95,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: FigBrand.amber,
          borderRadius: BorderRadius.circular(FigRadius.cta),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Le libelle change sur la derniere slide : on le fond au lieu de
            // le remplacer sechement.
            AnimatedSize(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOut,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: Text(
                  label,
                  key: ValueKey(label),
                  style: FigText.button.copyWith(color: Colors.black),
                ),
              ),
            ),
            const SizedBox(width: FigSpace.xl),
            SvgPicture.asset(
              'assets/figma/icons/arrow_right.svg',
              width: 24,
              height: 16,
              colorFilter:
                  const ColorFilter.mode(Colors.black, BlendMode.srcIn),
            ),
          ],
        ),
      ),
    );
  }
}
