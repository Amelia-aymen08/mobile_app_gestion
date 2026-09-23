import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// Portrait d'une personne : sa photo quand elle en a pose une, ses
/// initiales sinon.
///
/// Les initiales valent mieux qu'une silhouette generique : elles
/// distinguent les membres d'un foyer les uns des autres, ce qu'un
/// pictogramme identique pour tous ne fait pas.
class GiAvatar extends StatelessWidget {
  final String? photoUrl;
  final String name;
  final double size;

  /// Rayon des coins. Rond par defaut ; la carte d'identite du profil le
  /// passe au rayon des cartes pour s'aligner sur le Figma.
  final double? radius;

  /// Trait ambre plein autour du portrait, au lieu du trait discret.
  final bool bordered;

  const GiAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.size = 36,
    this.radius,
    this.bordered = false,
  });

  String get _initials => name
      .trim()
      .split(RegExp(r'\s+'))
      .where((e) => e.isNotEmpty)
      .take(2)
      .map((e) => e[0].toUpperCase())
      .join();

  @override
  Widget build(BuildContext context) {
    final url = photoUrl;
    final border = Border.all(
        color: bordered ? FigBrand.amber : FigAccent.chipBorder(FigBrand.amber));
    final fill = FigAccent.chipFill(FigBrand.amber);

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      // Un BoxDecoration ne peut pas porter a la fois une forme ronde et un
      // rayon : les deux cas sont donc construits separement.
      decoration: radius == null
          ? BoxDecoration(shape: BoxShape.circle, color: fill)
          : BoxDecoration(
              borderRadius: BorderRadius.circular(radius!), color: fill),
      // Le trait est peint par-dessus la photo, apres le rognage. Pose dans
      // `decoration`, il passait dessous : la photo le mangeait et les
      // angles arrivaient en marches d'escalier.
      foregroundDecoration: radius == null
          ? BoxDecoration(shape: BoxShape.circle, border: border)
          : BoxDecoration(
              borderRadius: BorderRadius.circular(radius!), border: border),
      child: url == null || url.isEmpty
          ? _fallback()
          : Image.network(url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _fallback()),
    );
  }

  Widget _fallback() => Text(
        _initials.isEmpty ? '?' : _initials,
        style: FigText.body.copyWith(
          fontSize: size < 40 ? 13 : 18,
          fontWeight: FontWeight.w600,
          color: FigBrand.amber,
        ),
      );
}
