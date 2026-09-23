import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/design_tokens.dart';
import '../theme/gi_colors.dart';
import 'gi_pressable.dart';

/// Champ de saisie du Figma — frames "Login LT" (721:7277), "Login Active LT"
/// (721:7222) et "Login Error LT" (721:7253).
///
/// Geometrie : libelle 14 au-dessus, ecart 4, champ a fond plein, bordure de
/// 1.5, rayon 8, padding interieur 16, texte 16.
///
/// Trois etats de bordure, tous releves dans le Figma :
///   repos  -> fieldBorder       (#E5E5E5 clair / #333333 sombre)
///   focus  -> fieldBorderFocus  (#CCCCCC clair / #999999 sombre)
///   erreur -> Alert/Error       (#E74C3C, identique dans les deux themes)
///
/// La bordure est animee : en sautant d'une couleur a l'autre, le champ
/// clignote a chaque prise de focus.
class GiTextField extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool isPassword;
  final String? errorText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final String? Function(String?)? validator;
  final bool enabled;

  /// Noeud de focus fourni par l'ecran, quand il a besoin de designer le
  /// champ suivant lui-meme. `nextFocus()` suit l'ordre de l'arbre et peut
  /// s'arreter sur un bouton pose entre deux champs.
  final FocusNode? focusNode;

  const GiTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.isPassword = false,
    this.errorText,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.validator,
    this.enabled = true,
    this.focusNode,
  });

  @override
  State<GiTextField> createState() => _GiTextFieldState();
}

class _GiTextFieldState extends State<GiTextField> {
  FocusNode? _own;
  bool _obscure = true;

  /// Celui de l'ecran s'il en fournit un, sinon le notre.
  FocusNode get _focus => widget.focusNode ?? (_own ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChanged);
    // Seul le noeud que nous avons cree nous appartient.
    _own?.dispose();
    super.dispose();
  }

  void _onFocusChanged() => setState(() {});

  /// Comportement de la touche de validation du clavier.
  ///
  /// `next` fait passer au champ suivant, toute autre action referme le
  /// clavier. C'est traite ici une fois pour toutes : sinon chaque ecran
  /// doit y penser, et il suffit d'un oubli pour qu'un formulaire pietine.
  void _onSubmitted(String value) {
    widget.onSubmitted?.call(value);
    if (widget.textInputAction == TextInputAction.next) {
      FocusScope.of(context).nextFocus();
    } else {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    final borderColor = hasError
        ? FigAlert.error
        : _focus.hasFocus
            ? c.fieldBorderFocus
            : c.fieldBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: FigText.fieldLabel.copyWith(color: c.textBody),
        ),
        const SizedBox(height: FigSpace.xs),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          // Figma : le champ mesure 52 de haut, padding 16 et texte de 20.
          // Le trait de 1,5 n'y consomme aucune place, alors que dans Flutter
          // une bordure decale le contenu. On retire donc 1,5 au padding pour
          // retomber sur 16 depuis le bord exterieur, et sur 52 au total.
          padding: const EdgeInsets.all(FigSpace.xl - 1.5),
          decoration: BoxDecoration(
            color: c.fieldBg,
            borderRadius: BorderRadius.circular(FigRadius.field),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: widget.controller,
                  focusNode: _focus,
                  enabled: widget.enabled,
                  obscureText: widget.isPassword && _obscure,
                  keyboardType: widget.keyboardType,
                  textInputAction: widget.textInputAction,
                  onFieldSubmitted: _onSubmitted,
                  validator: widget.validator,
                  cursorColor: FigBrand.amber,
                  style: FigText.field.copyWith(color: c.fieldText),
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    hintStyle: FigText.field.copyWith(color: c.fieldHint),
                    // Le theme global de l'app remplit les champs en blanc.
                    // Sans cette coupure, ce blanc se peint a l'interieur du
                    // conteneur creme et dessine un rectangle clair.
                    filled: false,
                    // Le padding vient du conteneur : sans cette remise a zero,
                    // Flutter ajoute le sien et le champ depasse la hauteur
                    // du Figma.
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    // L'erreur est rendue sous le champ, pas par le TextField.
                    errorStyle: const TextStyle(height: 0, fontSize: 0),
                  ),
                ),
              ),
              if (widget.isPassword) ...[
                const SizedBox(width: FigSpace.lg),
                Semantics(
                  button: true,
                  label: _obscure
                      ? 'Afficher le mot de passe'
                      : 'Masquer le mot de passe',
                  child: GiPressable(
                    onTap: () => setState(() => _obscure = !_obscure),
                    pressedScale: 0.82,
                    ensureMinTapTarget: true,
                    child: SvgPicture.asset(
                      'assets/figma/icons/eye_light.svg',
                      width: 16,
                      height: 16,
                      // Le Figma ne fournit pas d'icone « oeil barre » : l'etat
                      // « mot de passe visible » se signale par la couleur.
                      colorFilter: ColorFilter.mode(
                        _obscure ? c.eyeStroke : FigBrand.amber,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        // L'erreur apparait en glissant plutot qu'en poussant brutalement le
        // reste du formulaire vers le bas.
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment: Alignment.topLeft,
          child: hasError
              ? Padding(
                  padding: const EdgeInsets.only(top: FigSpace.xs),
                  child: Text(
                    widget.errorText!,
                    style: FigText.fieldLabel.copyWith(color: FigAlert.error),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}
