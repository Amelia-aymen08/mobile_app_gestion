import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';
import '../theme/gi_colors.dart';
import 'gi_pressable.dart';

/// Dialogue d'alerte — « Notice Card » du Figma, frames Home Alert LT
/// (927:9064) et DT (747:1924).
///
/// Geometrie relevee : carte de 335 x 316, rayon 16, texte a 71 du haut avec
/// 19 de marge laterale et 12 d'ecart, boutons a 238. L'illustration est un
/// cercle de 88 pose a -45, donc a cheval sur le bord superieur, cercle par un
/// anneau de 5 de la couleur de la carte.
///
/// Le voile n'est pas un simple noir transparent : le Figma y applique aussi
/// un flou de 3, ce qui detache nettement la carte du contenu derriere.
Future<T?> showGiAlert<T>({
  required BuildContext context,
  required String title,
  required String message,
  String? hint,
  required String closeLabel,
  required String primaryLabel,
  VoidCallback? onPrimary,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: closeLabel,
    // Le voile est dessine par le dialogue lui-meme, pour pouvoir y ajouter
    // le flou du Figma que barrierColor ne sait pas produire.
    barrierColor: Colors.transparent,
    // showGeneralDialog n'expose pas de duree de sortie distincte : la meme
    // valeur sert dans les deux sens.
    transitionDuration: const Duration(milliseconds: 460),
    pageBuilder: (context, animation, _) => _GiAlert(
      animation: animation,
      title: title,
      message: message,
      hint: hint,
      closeLabel: closeLabel,
      primaryLabel: primaryLabel,
      onPrimary: onPrimary,
    ),
  );
}

class _GiAlert extends StatelessWidget {
  final Animation<double> animation;
  final String title;
  final String message;
  final String? hint;
  final String closeLabel;
  final String primaryLabel;
  final VoidCallback? onPrimary;

  const _GiAlert({
    required this.animation,
    required this.title,
    required this.message,
    this.hint,
    required this.closeLabel,
    required this.primaryLabel,
    this.onPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final v = animation.value;

        // Le voile monte vite et sans rebond : il doit etre en place avant que
        // la carte n'arrive.
        final veil = Curves.easeOut.transform(v.clamp(0.0, 1.0));

        // La carte arrive avec un leger depassement, comme une feuille qu'on
        // pose. easeOutBack donne ce depassement sans ressort visible.
        final card = Curves.easeOutBack
            .transform(const Interval(0.05, 0.75).transform(v).clamp(0.0, 1.0));

        // L'illustration suit avec un temps de retard et un ressort plus
        // marque : c'est le point d'attention de la carte.
        final art = Curves.elasticOut
            .transform(const Interval(0.30, 1.0).transform(v).clamp(0.0, 1.0));

        final scale = reduceMotion ? 1.0 : 0.88 + 0.12 * card;
        final artScale = reduceMotion ? 1.0 : art;

        return Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).maybePop(),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(
                      sigmaX: 3 * veil, sigmaY: 3 * veil),
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.20 * veil),
                  ),
                ),
              ),
            ),
            Opacity(
              opacity: veil,
              child: Transform.scale(
                scale: scale,
                // L'illustration deborde en haut : sans marge, la carte
                // toucherait le bord de l'ecran sur les petits appareils.
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 84, 20, 20),
                  child: _card(context, c, artScale),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _card(BuildContext context, GiColors c, double artScale) {
    return Material(
      color: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 335),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: c.scaffold,
                borderRadius: BorderRadius.circular(FigRadius.card),
                border: Border.all(color: c.cardBorder),
              ),
              padding: const EdgeInsets.fromLTRB(19, 71, 19, 26),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title,
                      textAlign: TextAlign.center,
                      style: FigText.greeting.copyWith(color: c.textBody)),
                  const SizedBox(height: FigSpace.lg),
                  Text(message,
                      textAlign: TextAlign.center,
                      style: FigText.field.copyWith(
                          fontSize: 15, height: 1.2, color: c.textMuted)),
                  if (hint != null) ...[
                    const SizedBox(height: FigSpace.lg),
                    Text(hint!,
                        textAlign: TextAlign.center,
                        style: FigText.body.copyWith(color: c.textMuted)),
                  ],
                  const SizedBox(height: 40),
                  Row(
                    children: [
                      Expanded(
                        child: _button(
                          label: closeLabel,
                          filled: false,
                          onTap: () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(width: FigSpace.md),
                      Expanded(
                        child: _button(
                          label: primaryLabel,
                          filled: true,
                          onTap: () {
                            Navigator.of(context).pop();
                            onPrimary?.call();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              // Le Figma pose le cercle de 88 a -45. Le halo l'entoure dans
              // une boite de 140, soit 26 de marge de chaque cote : on remonte
              // d'autant pour que le cercle retombe exactement a -45.
              top: -45 - 26,
              child: _AlertArt(entrance: artScale, ring: c.scaffold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _button({
    required String label,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return GiPressable(
      onTap: onTap,
      pressedScale: 0.95,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? FigBrand.amber : Colors.transparent,
          borderRadius: BorderRadius.circular(FigRadius.cta),
          border: filled
              ? null
              : Border.all(color: FigBrand.amber, width: 1.5),
        ),
        // Le Figma dimensionne ces boutons pour « Close » et « Open Notice ».
        // En francais et en arabe les libelles sont plus longs : on les
        // reduit legerement plutot que de les couper, ce qui rendrait
        // l'action illisible.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            style: FigText.button.copyWith(
              fontSize: 14,
              color: filled ? Colors.black : FigBrand.amber,
            ),
          ),
        ),
      ),
    );
  }
}

/// Illustration de l'alerte — cercle de 88 du Figma, cercle d'un anneau de 5
/// a la couleur de la carte.
///
/// Deux mouvements se superposent. A l'ouverture, l'illustration arrive avec
/// le ressort pilote par la transition du dialogue. Ensuite, une onde part du
/// cercle en s'elargissant et en s'effacant, pendant que la bille respire
/// legerement. L'onde attire l'oeil sans agiter la carte : elle reste derriere
/// l'illustration et ne deplace aucun element.
class _AlertArt extends StatefulWidget {
  /// Echelle d'entree, pilotee par l'animation de route du dialogue.
  final double entrance;
  final Color ring;

  const _AlertArt({required this.entrance, required this.ring});

  @override
  State<_AlertArt> createState() => _AlertArtState();
}

class _AlertArtState extends State<_AlertArt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1900),
  )..repeat();

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return AnimatedBuilder(
      animation: _loop,
      builder: (context, _) {
        final t = reduceMotion ? 0.0 : _loop.value;

        // L'onde : part de la taille du cercle et s'efface en s'elargissant.
        final wave = Curves.easeOut.transform(t);
        // La respiration : un aller-retour complet par cycle, sans a-coup au
        // bouclage puisque le sinus revient exactement a son point de depart.
        final breath = reduceMotion ? 0.0 : math.sin(t * 2 * math.pi);

        return SizedBox(
          width: 140,
          height: 140,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: 0.63 + 0.37 * wave,
                child: Opacity(
                  opacity: (1 - wave) * 0.30,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: FigAlert.error,
                    ),
                  ),
                ),
              ),
              Transform.scale(
                scale: widget.entrance * (1 + 0.025 * breath),
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: widget.ring, width: 5),
                  ),
                  child: ClipOval(
                    // L'asset est desormais recadre au plus juste sur la
                    // bille : un simple cover suffit, sans agrandissement.
                    child: Image.asset(
                      'assets/figma/alert_illustration.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
