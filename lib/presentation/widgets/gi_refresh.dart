import 'package:flutter/cupertino.dart';

import '../theme/design_tokens.dart';

/// Tirer pour actualiser, sans pastille qui reste a l'ecran.
///
/// Le `RefreshIndicator` de Material dessine un disque par-dessus la liste,
/// qui pouvait rester fige a mi-course : l'ecran s'ouvrait alors avec la
/// fleche affichee, comme s'il chargeait en permanence. Celui-ci vit dans
/// l'espace que le geste ouvre au-dessus de la liste : il n'existe que
/// pendant le geste et le chargement, et disparait avec eux.
///
/// A poser en premier `sliver` d'un `CustomScrollView`.
class GiRefreshControl extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const GiRefreshControl({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) => CupertinoSliverRefreshControl(
        onRefresh: onRefresh,
        builder: _indicator,
      );

  /// Indicateur ambre : il se revele au fil du geste, puis tourne pendant le
  /// chargement.
  static Widget _indicator(
    BuildContext context,
    RefreshIndicatorMode mode,
    double pulledExtent,
    double refreshTriggerPullDistance,
    double refreshIndicatorExtent,
  ) {
    final progress =
        (pulledExtent / refreshTriggerPullDistance).clamp(0.0, 1.0);
    final Widget indicator = switch (mode) {
      RefreshIndicatorMode.inactive => const SizedBox.shrink(),
      RefreshIndicatorMode.drag => CupertinoActivityIndicator.partiallyRevealed(
          progress: progress, color: FigBrand.amber, radius: 12),
      _ => const CupertinoActivityIndicator(color: FigBrand.amber, radius: 12),
    };
    return Center(child: Opacity(opacity: progress, child: indicator));
  }
}

/// Physique commune aux listes qui portent un [GiRefreshControl] : elle
/// autorise le geste meme quand le contenu tient dans l'ecran.
const giRefreshPhysics =
    BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
