import 'package:flutter/material.dart';

/// Ouverture d'un ecran : un fondu et un leger glissement.
///
/// La transition par defaut d'Android agrandit et fait disparaitre l'ecran
/// entier. C'est couteux a dessiner : sur un telephone de milieu de gamme
/// l'animation saute, et le passage parait casse. Un fondu double d'un
/// glissement de quelques pour cent coute presque rien et se lit comme un
/// mouvement continu.
///
/// La courbe fait l'essentiel du chemin dans le premier tiers : l'ecran
/// parait arriver vite, sans pour autant s'interrompre net.
class GiPageTransitionsBuilder extends PageTransitionsBuilder {
  const GiPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final entering = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    // L'ecran qu'on quitte recule a peine : il reste present sous le
    // nouveau, ce qui donne la profondeur sans le faire disparaitre.
    final leaving = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return FadeTransition(
      opacity: entering,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.05, 0),
          end: Offset.zero,
        ).animate(entering),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: Offset.zero,
            end: const Offset(-0.02, 0),
          ).animate(leaving),
          child: child,
        ),
      ),
    );
  }
}
