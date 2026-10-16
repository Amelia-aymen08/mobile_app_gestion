import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/gi_colors.dart';

/// Flou leger en haut d'une page qui defile, facon Instagram.
///
/// Des qu'on descend, le contenu qui remonte ne se coupe plus net sur une
/// ligne : il passe sous un voile depoli de la couleur du fond, a peine
/// floute, qui s'estompe vers le bas. Au repos, en haut de page, le voile
/// est absent : rien ne passe dessous.
///
/// Deux usages :
/// - [GiScrollBlur.new] remplace un `SafeArea(bottom: false)` autour d'une
///   page qui defile en entier. Le contenu passe sous la barre d'etat ; la
///   liste doit donc etre construite avec `clipBehavior: Clip.none`.
/// - [GiScrollBlur.edge] se pose sur une liste placee sous un en-tete fixe :
///   le voile commence au bord haut de la liste, sans deborder sur l'en-tete.
class GiScrollBlur extends StatefulWidget {
  final Widget child;
  final bool _underStatusBar;

  const GiScrollBlur({super.key, required this.child}) : _underStatusBar = true;

  const GiScrollBlur.edge({super.key, required this.child})
      : _underStatusBar = false;

  /// Hauteur du degrade sous la zone floutee.
  static const double fade = 18;

  @override
  State<GiScrollBlur> createState() => _GiScrollBlurState();
}

class _GiScrollBlurState extends State<GiScrollBlur> {
  bool _scrolled = false;

  bool _onScroll(ScrollNotification n) {
    // Seuls les defilements verticaux comptent : un carrousel ou une rangee
    // de filtres ne doivent pas allumer le voile. La profondeur, elle, est
    // libre : sous des onglets, la liste est un cran plus bas.
    if (n.metrics.axis != Axis.vertical) return false;
    final scrolled = n.metrics.pixels > n.metrics.minScrollExtent + 1;
    if (scrolled != _scrolled) setState(() => _scrolled = scrolled);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final top =
        widget._underStatusBar ? MediaQuery.paddingOf(context).top : 0.0;
    final bg = GiColors.of(context).scaffold;

    final content = NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: widget.child,
    );

    return Stack(
      children: [
        if (widget._underStatusBar)
          SafeArea(bottom: false, child: content)
        else
          Positioned.fill(child: content),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: _scrolled ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Sous la barre d'etat : un flou franc mais doux, et un
                  // voile qui garde l'heure et la batterie lisibles.
                  if (top > 0)
                    _band(
                      height: top,
                      sigma: 6,
                      decoration:
                          BoxDecoration(color: bg.withValues(alpha: 0.78)),
                    ),
                  // Puis le bord se perd : un flou plus faible, un voile qui
                  // s'efface, pour qu'aucune ligne ne trahisse la limite.
                  _band(
                    height: GiScrollBlur.fade,
                    sigma: 2.5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          bg.withValues(alpha: top > 0 ? 0.78 : 0.9),
                          bg.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _band({
    required double height,
    required double sigma,
    required Decoration decoration,
  }) {
    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: DecoratedBox(
          decoration: decoration,
          child: SizedBox(height: height, width: double.infinity),
        ),
      ),
    );
  }
}
