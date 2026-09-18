import 'package:flutter/material.dart';

/// Apparition d'un element de liste : fondu et leger glissement vers le haut.
///
/// Les elements entrent les uns apres les autres, avec un decalage tire de
/// leur rang. C'est ce decalage qui donne l'impression que la liste se pose,
/// la ou une apparition simultanee fait un a-coup.
///
/// Le decalage est plafonne : au-dela d'une poignee d'elements, attendre son
/// tour deviendrait une attente, pas une animation. Les elements suivants
/// apparaissent donc ensemble, ce qui ne se voit pas puisqu'ils sont hors de
/// l'ecran.
class GiAppear extends StatefulWidget {
  final Widget child;
  final int index;

  /// Decalage entre deux elements.
  static const step = Duration(milliseconds: 55);

  /// Rang au-dela duquel le decalage n'augmente plus.
  static const maxSteps = 6;

  const GiAppear({super.key, required this.child, this.index = 0});

  @override
  State<GiAppear> createState() => _GiAppearState();
}

class _GiAppearState extends State<GiAppear>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 340),
  );

  @override
  void initState() {
    super.initState();
    final steps = widget.index.clamp(0, GiAppear.maxSteps);
    if (steps == 0) {
      _c.forward();
    } else {
      Future<void>.delayed(GiAppear.step * steps, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Respecte le reglage systeme « reduire les animations » : l'element est
    // alors simplement pose.
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final v = Curves.easeOutCubic.transform(_c.value);
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - v)),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
