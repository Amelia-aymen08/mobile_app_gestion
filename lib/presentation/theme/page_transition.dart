import 'package:flutter/material.dart';

/// Ouverture d'un ecran : le nouveau glisse par-dessus l'ancien.
///
/// Aucun fondu. Un fondu rend les deux pages visibles en meme temps pendant
/// la moitie de l'animation : on voit le texte de l'ancienne a travers la
/// nouvelle, ce qui se lit comme un defaut d'affichage. Ici la page qui
/// arrive est opaque du premier au dernier pixel ; elle recouvre, elle ne se
/// melange pas.
///
/// La page qu'on quitte recule d'un quart de la largeur, ce qui donne la
/// profondeur sans jamais la laisser transparaitre.
///
/// 240 ms : assez pour que le mouvement se lise, assez court pour qu'on ne
/// l'attende pas. La transition par defaut d'Android en met 450 et agrandit
/// tout l'ecran, ce qui saute sur un telephone de milieu de gamme.
class GiPageTransitionsBuilder extends PageTransitionsBuilder {
  const GiPageTransitionsBuilder();

  @override
  Duration get transitionDuration => const Duration(milliseconds: 240);

  @override
  Widget buildTransitions<T>(
    PageRoute<T>? route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final incoming = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));

    final outgoing = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-0.25, 0),
    ).animate(CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));

    return SlideTransition(
      position: outgoing,
      child: SlideTransition(position: incoming, child: child),
    );
  }
}
