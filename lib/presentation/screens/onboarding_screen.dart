import 'dart:ui' as ui;

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
    'assets/onboarding-who-we-are.png',
    'assets/figma/onboarding/photo_2.png',
    'assets/figma/onboarding/photo_3.png',
  ];

  /// Page demandee : pilote les points, le fond et les boutons, tout de suite.
  int _page = 0;

  /// Page dont le texte est affiche : change au creux de l'animation, pour que
  /// l'ancien texte ait fini de sortir avant que le nouveau entre.
  int _shown = 0;

  bool _forward = true;
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
        onHorizontalDragEnd: (details) {
          final v = details.primaryVelocity ?? 0;
          if (v.abs() < 200) return;
          // En arabe l'interface est inversee : le geste doit l'etre aussi.
          final rtl = Directionality.of(context) == TextDirection.rtl;
          final forward = rtl ? v > 0 : v < 0;
          _goTo(_page + (forward ? 1 : -1));
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

  @override
  Widget build(BuildContext context) => Image.asset(
        asset,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        errorBuilder: (_, __, ___) =>
            ColoredBox(color: GiColors.of(context).scaffold),
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

    return SafeArea(
      top: false,
      child: SizedBox(
        // Figma : le bloc « All Content » occupe les 360 derniers pixels.
        height: 360,
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
                padding: const EdgeInsets.fromLTRB(
                    FigSpace.pagePadding, 75, FigSpace.pagePadding, 29),
                child: _content(titleColor, bodyColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content(Color titleColor, Color bodyColor) {
    return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Dots(count: pageCount, current: page, isDark: isDark),
            const SizedBox(height: FigSpace.lg),
            // Hauteur reservee au texte : sans elle, les boutons remonteraient
            // et redescendraient a chaque changement de slide.
            ConstrainedBox(
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
            const Spacer(),
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
/// Elle porte aussi un flou d'arriere-plan de 74,85 : c'est ce qui adoucit le
/// bas de la photo et rend le texte lisible. Sans ce flou, l'arc ne serait
/// qu'un voile colore et l'effet tomberait a plat.
class _Arc extends StatelessWidget {
  final bool isDark;
  const _Arc({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 645,
      height: 462,
      child: ClipOval(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 74.85, sigmaY: 74.85),
          child: ColoredBox(
            // Figma : creme a 60 % en clair, navy a 50 % en sombre.
            color: isDark
                ? FigBrand.navy.withValues(alpha: 0.50)
                : FigBrand.cream.withValues(alpha: 0.60),
            child: const SizedBox.expand(),
          ),
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
