import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Reaction tactile commune a tous les elements cliquables.
///
/// Le principe repris des apps mobiles soignees : l'element se comprime vite
/// sous le doigt (la reponse doit sembler instantanee) puis se relache plus
/// lentement (le retour doit sembler physique, pas mecanique). D'ou deux
/// durees et deux courbes differentes plutot qu'une animation symetrique.
///
/// Un `InkWell` classique ne convient pas ici : le Figma n'a aucune onde de
/// propagation, et un splash Material sur ces cartes creme jurerait.
class GiPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Echelle atteinte doigt pose. 0.96 sur une carte, 0.92 sur une petite
  /// cible : plus l'element est petit, plus la compression doit etre marquee
  /// pour rester perceptible.
  final double pressedScale;

  /// Legere perte d'opacite a l'appui, comme sur iOS.
  final double pressedOpacity;

  final bool haptic;

  /// Zone de tap minimale, pour les cibles plus petites que 48 dp.
  final bool ensureMinTapTarget;

  const GiPressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedScale = 0.96,
    this.pressedOpacity = 1.0,
    this.haptic = true,
    this.ensureMinTapTarget = false,
  });

  @override
  State<GiPressable> createState() => _GiPressableState();
}

class _GiPressableState extends State<GiPressable>
    with SingleTickerProviderStateMixin {
  static const _pressIn = Duration(milliseconds: 110);
  static const _pressOut = Duration(milliseconds: 240);

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: _pressIn,
    reverseDuration: _pressOut,
  );

  bool get _enabled => widget.onTap != null || widget.onLongPress != null;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _down(_) {
    if (!_enabled) return;
    _c.forward();
  }

  void _up(_) {
    if (!_enabled) return;
    _c.reverse();
  }

  void _cancel() {
    if (!_enabled) return;
    _c.reverse();
  }

  void _tap() {
    if (!_enabled) return;
    if (widget.haptic) HapticFeedback.lightImpact();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    // Respecte « Reduire les animations » du systeme : on garde l'action,
    // on retire le mouvement.
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    Widget result = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: reduceMotion ? null : _down,
      onTapUp: reduceMotion ? null : _up,
      onTapCancel: reduceMotion ? null : _cancel,
      onTap: _enabled ? _tap : null,
      onLongPress: widget.onLongPress,
      child: reduceMotion
          ? widget.child
          : AnimatedBuilder(
              animation: _c,
              child: widget.child,
              builder: (context, child) {
                final t = Curves.easeOutCubic.transform(_c.value);
                final scale = 1.0 - (1.0 - widget.pressedScale) * t;
                final opacity = 1.0 - (1.0 - widget.pressedOpacity) * t;
                return Opacity(
                  opacity: opacity,
                  child: Transform.scale(scale: scale, child: child),
                );
              },
            ),
    );

    if (widget.ensureMinTapTarget) {
      result = Center(
        widthFactor: 1,
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: Center(widthFactor: 1, heightFactor: 1, child: result),
        ),
      );
    }

    return Semantics(button: _enabled, enabled: _enabled, child: result);
  }
}
