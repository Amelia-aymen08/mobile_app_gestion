import 'package:flutter/cupertino.dart';

/// Tirer pour actualiser, sans rien afficher.
///
/// Aucun indicateur : ni le disque de Material, qui se dessine par-dessus la
/// liste et pouvait rester fige a mi-course, ni la roue iOS. Le geste
/// recharge les donnees, un point c'est tout. Ce qui se voit, c'est la liste
/// qui se met a jour.
///
/// `refreshIndicatorExtent` a zero : le controle ne reserve aucune hauteur
/// pendant le chargement, donc la liste ne se decale pas.
///
/// A poser en premier `sliver` d'un `CustomScrollView`.
class GiRefreshControl extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const GiRefreshControl({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) => CupertinoSliverRefreshControl(
        onRefresh: onRefresh,
        refreshIndicatorExtent: 0,
        builder: (context, mode, pulled, trigger, extent) =>
            const SizedBox.shrink(),
      );
}

/// Physique commune aux listes qui portent un [GiRefreshControl] : elle
/// autorise le geste meme quand le contenu tient dans l'ecran.
const giRefreshPhysics =
    BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
