import 'dart:io' show Platform;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../theme/design_tokens.dart';
import '../theme/gi_colors.dart';

/// Un onglet de la barre de navigation.
class GiNavItem {
  final String asset;
  final String label;

  /// Compteur affiche en pastille sur l'icone. Absent du Figma, mais les
  /// notifications non lues existent dans l'app : on ne supprime pas une
  /// information utile parce que la maquette ne l'a pas prevue.
  final int badge;

  const GiNavItem({
    required this.asset,
    required this.label,
    this.badge = 0,
  });
}

/// Vrai la ou les shaders du verre ne tournent pas : le simulateur iOS (il
/// n'accepte que 14 tampons, le verre en demande 21 et le moteur plantait)
/// et le web. On y garde un verre depoli classique.
///
/// L'app d'un simulateur est installee sous CoreSimulator ; les variables
/// d'environnement, elles, ne parviennent pas jusqu'a Dart.
final bool glassFallback = kIsWeb ||
    (Platform.isIOS && Platform.resolvedExecutable.contains('CoreSimulator'));

/// Barre de navigation en verre liquide, facon iOS 26.
///
/// Une capsule de verre flotte au-dessus du contenu, cerclee d'un filet
/// ambre. Elle se resserre sur les icones quand on descend dans une page et
/// reprend sa taille quand on remonte ou qu'on la touche ; l'etat est tenu
/// par [minimizeController], nourri par les defilements de l'ecran.
///
/// La pastille de l'onglet actif se fait glisser du doigt : tant qu'on la
/// tient, elle devient une lentille de verre qui deforme les icones qu'elle
/// survole, l'onglet survole prend deja la couleur active, et elle se pose
/// sur l'onglet le plus proche quand on la lache.
class GiBottomNav extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<GiNavItem> items;
  final GlassTabBarMinimizeController? minimizeController;

  const GiBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.minimizeController,
  });

  static const double expandedHeight = 66;
  static const double minimizedHeight = 50;

  @override
  State<GiBottomNav> createState() => _GiBottomNavState();
}

class _GiBottomNavState extends State<GiBottomNav> {
  static const Duration _duration = Duration(milliseconds: 420);
  // Un leger depassement, comme le ressort des barres d'Apple.
  static const Curve _curve = Curves.easeOutBack;

  late final GlassTabBarMinimizeController _ownController =
      GlassTabBarMinimizeController(behavior: GlassBarMinimizeBehavior.never);

  GlassTabBarMinimizeController get _minimize =>
      widget.minimizeController ?? _ownController;

  // Position du doigt pendant le glisser, en alignement : -1 sur le premier
  // onglet, 1 sur le dernier.
  double? _dragAlign;
  // L'onglet que la pastille survole pendant le glisser.
  int? _hoverIndex;
  bool _down = false;

  int get _count => widget.items.length;

  double _alignOf(int index) => _count < 2 ? 0 : index / (_count - 1) * 2 - 1;

  int _indexOf(double align) =>
      ((align.clamp(-1.0, 1.0) + 1) / 2 * (_count - 1)).round();

  // Le centre de la pastille suit le doigt ; au-dela des bords elle
  // resiste, comme un elastique.
  double _alignAt(double dx, double width) {
    final slot = width / _count;
    final align = (dx - slot / 2) / (width - slot) * 2 - 1;
    if (align.abs() <= 1) return align;
    return align.sign * (1 + (align.abs() - 1) * 0.25);
  }

  bool get _rtl => Directionality.of(context) == TextDirection.rtl;

  // Les onglets sont poses dans le sens de lecture ; le calcul se fait de
  // gauche a droite, puis on retourne l'indice en arabe.
  int _visualToIndex(int i) => _rtl ? _count - 1 - i : i;

  @override
  void dispose() {
    _ownController.dispose();
    super.dispose();
  }

  void _select(int index) {
    HapticFeedback.selectionClick();
    _minimize.expand();
    widget.onTap(index);
  }

  void _dragTo(double dx, double width) {
    final align = _alignAt(dx, width);
    final index = _visualToIndex(_indexOf(align));
    if (_hoverIndex != null && index != _hoverIndex) {
      HapticFeedback.selectionClick();
    }
    setState(() {
      _dragAlign = align;
      _hoverIndex = index;
    });
  }

  void _release() {
    final align = _dragAlign;
    setState(() {
      _dragAlign = null;
      _hoverIndex = null;
      _down = false;
    });
    if (align == null) return;
    final index = _visualToIndex(_indexOf(align));
    if (index != widget.currentIndex) {
      _select(index);
    } else {
      _minimize.expand();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _minimize,
      builder: (context, _) {
        final minimized = _minimize.minimized;
        final fullWidth = MediaQuery.sizeOf(context).width - 16;
        final width = minimized ? fullWidth * 0.62 : fullWidth;
        final height = minimized
            ? GiBottomNav.minimizedHeight
            : GiBottomNav.expandedHeight;

        return Padding(
          padding: const EdgeInsets.only(bottom: FigSpace.navbarBottom),
          child: Align(
            alignment: Alignment.bottomCenter,
            heightFactor: 1,
            child: TweenAnimationBuilder<Size?>(
              tween: SizeTween(end: Size(width, height)),
              duration: _duration,
              curve: _curve,
              builder: (context, size, _) => _bar(size!, minimized),
            ),
          ),
        );
      },
    );
  }

  Widget _bar(Size size, bool minimized) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final radius = size.height / 2;

    return GestureDetector(
      // Repliee, toute la capsule est une seule cible : la toucher la
      // rouvre. Les icones gardent leur propre appui par-dessus.
      behavior: HitTestBehavior.opaque,
      onTap: minimized ? _minimize.expand : null,
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: Stack(clipBehavior: Clip.none, children: [
          // L'ombre portee, sous le verre : a peine, le verre doit paraitre
          // pose sur la page, pas en sortir.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: dark ? 0.35 : 0.10),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: glassFallback
                ? _frostedFallback(radius, dark)
                : GlassContainer(
                    useOwnLayer: true,
                    quality: GlassQuality.premium,
                    shape: LiquidRoundedSuperellipse(borderRadius: radius),
                    settings: LiquidGlassSettings(
                      // Du vrai verre : presque pas de voile ni de flou,
                      // c'est la refraction des bords qui dessine la
                      // capsule. Sur le fond nuit, un voile bleu nuit garde
                      // les icones lisibles quand une photo passe dessous.
                      glassColor: dark
                          ? FigBrand.navy.withValues(alpha: 0.45)
                          : Colors.white.withValues(alpha: 0.35),
                      thickness: 30,
                      blur: 2,
                      refractiveIndex: 1.5,
                      lightIntensity: dark ? 0.5 : 0.6,
                      ambientStrength: 0.6,
                      saturation: 1.2,
                      chromaticAberration: 0.15,
                    ),
                    child: const SizedBox.expand(),
                  ),
          ),
          // Le filet ambre, par-dessus le verre.
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  border: Border.all(
                    color: FigBrand.amber.withValues(alpha: 0.35),
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: _items(minimized),
            ),
          ),
        ]),
      ),
    );
  }

  // Le simulateur et le web : un verre depoli classique, sans shader.
  Widget _frostedFallback(double radius, bool dark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: ColoredBox(
          color: dark
              ? FigDark.navbarBg.withValues(alpha: 0.72)
              : Colors.white.withValues(alpha: 0.55),
        ),
      ),
    );
  }

  Widget _items(bool minimized) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final visualCurrent = _visualToIndex(widget.currentIndex);
      final target = _alignOf(visualCurrent);
      final dragging = _dragAlign != null;

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (details) {
          setState(() => _down = false);
          _select(_visualToIndex(
              _indexOf(_alignAt(details.localPosition.dx, width))));
        },
        onHorizontalDragStart: (details) {
          _hoverIndex = _visualToIndex(
              _indexOf(_alignAt(details.localPosition.dx, width)));
          _dragTo(details.localPosition.dx, width);
        },
        onHorizontalDragUpdate: (details) =>
            _dragTo(details.localPosition.dx, width),
        onHorizontalDragEnd: (_) => _release(),
        onHorizontalDragCancel: _release,
        child: VelocitySpringBuilder(
          value: _dragAlign ?? target,
          active: dragging,
          springWhenActive: GlassSpring.interactive(),
          springWhenReleased:
              GlassSpring.snappy(duration: const Duration(milliseconds: 380)),
          builder: (context, align, velocity, _) {
            return SpringBuilder(
              spring: GlassSpring.snappy(
                  duration: const Duration(milliseconds: 300)),
              // La lentille vit tant qu'on tient la barre, et le temps que
              // la pastille rejoigne sa place.
              value: (_down || dragging || (align - target).abs() > 0.05)
                  ? 1.0
                  : 0.0,
              builder: (context, lens, _) => Stack(
                clipBehavior: Clip.none,
                children: [
                  // La pastille au repos, teintee d'ambre ; elle s'efface
                  // quand la lentille apparait.
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment(align, 0),
                      child: FractionallySizedBox(
                        widthFactor: 1 / _count,
                        heightFactor: 1,
                        child: Opacity(
                          opacity: (1 - lens / 0.3).clamp(0.0, 1.0),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: FigBrand.amber.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(
                                  constraints.maxHeight / 2),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Row(children: [
                    for (var i = 0; i < _count; i++)
                      Expanded(child: _item(i, minimized)),
                  ]),
                  // La lentille, au-dessus des icones pour les deformer.
                  if (lens > 0.02)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: glassFallback
                            ? _lensFallback(align, lens, constraints.maxHeight)
                            // L'indicateur rend lui-meme un Positioned : il
                            // lui faut un Stack pour parent direct, sans quoi
                            // Flutter le remplace par un widget d'erreur.
                            : Stack(clipBehavior: Clip.none, children: [
                                AnimatedGlassIndicator(
                                  velocity: velocity,
                                  itemCount: _count,
                                  alignment: Alignment(align, 0),
                                  thickness: lens,
                                  quality: GlassQuality.premium,
                                  indicatorColor: Colors.transparent,
                                  isBackgroundIndicator: false,
                                  paintBackground: false,
                                  expansion: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 9),
                                  settings: LiquidGlassSettings(
                                    glassColor:
                                        Colors.white.withValues(alpha: 0.06),
                                    thickness: 22,
                                    refractiveIndex: 1.2,
                                    chromaticAberration: 0.12,
                                    shadowElevation: 2,
                                  ),
                                ),
                              ]),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      );
    });
  }

  // Sans shader : une bulle depolie qui gonfle sous le doigt.
  Widget _lensFallback(double align, double lens, double height) {
    return Align(
      alignment: Alignment(align, 0),
      child: FractionallySizedBox(
        widthFactor: 1 / _count,
        heightFactor: 1,
        child: Transform.scale(
          scale: 1 + 0.28 * lens,
          child: Opacity(
            opacity: lens.clamp(0.0, 1.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(height),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(height),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.6)),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _item(int visual, bool minimized) {
    final c = GiColors.of(context);
    final index = _visualToIndex(visual);
    final item = widget.items[index];
    final selected = index == widget.currentIndex;
    // Pendant le glisser, l'onglet survole prend deja la couleur active.
    final highlighted = index == (_hoverIndex ?? widget.currentIndex);
    final color = highlighted ? FigBrand.amber : c.textBody;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      onTap: () => _select(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedScale(
            duration: _duration,
            curve: _curve,
            scale: minimized ? 0.9 : 1,
            // Boite de gabarit fixe : les icones ont des hauteurs tres
            // differentes (« Plus » fait 4,8 de haut contre 22 pour
            // « Accueil ») ; la pastille de compteur se place ainsi au meme
            // endroit sur chaque onglet.
            child: SizedBox(
              width: 28,
              height: 24,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  TweenAnimationBuilder<Color?>(
                    tween: ColorTween(end: color),
                    duration: const Duration(milliseconds: 200),
                    builder: (context, col, _) => Transform.scale(
                      scale: 1.12,
                      child: SvgPicture.asset(item.asset,
                          colorFilter: ColorFilter.mode(col!, BlendMode.srcIn)),
                    ),
                  ),
                  if (item.badge > 0)
                    PositionedDirectional(
                      top: -4,
                      end: -6,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 16),
                        height: 16,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: FigAlert.error,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.badge > 9 ? '9+' : '${item.badge}',
                          style: FigText.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Le libelle se replie avec la barre.
          AnimatedSize(
            duration: _duration,
            curve: Curves.easeOutCubic,
            child: minimized
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                      style: FigText.caption.copyWith(
                        fontSize: 11,
                        color: color,
                        fontWeight:
                            highlighted ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
