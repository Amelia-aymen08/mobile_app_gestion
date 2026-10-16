import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/design_tokens.dart';
import '../theme/gi_colors.dart';
import '../theme/residence_images.dart';
import 'gi_pressable.dart';
import 'gi_skeleton.dart';

/// Une case du bandeau bas de la carte : libelle, puis valeur.
class GiResidenceStat {
  final String label;
  final String value;
  final Color? color;
  const GiResidenceStat(this.label, this.value, {this.color});
}

/// Carte de residence de l'accueil resident, partagee avec l'administration.
///
/// La photo couvre toute la carte et se fond vers la gauche dans la couleur
/// de la carte ; en haut le surtitre, le nom et une pastille facultative, puis
/// l'adresse, et en bas un bandeau de trois chiffres. Les deux cotes de l'app
/// montrent ainsi une residence de la meme facon.
class GiResidenceCard extends StatelessWidget {
  final String id;
  final String name;
  final String address;

  /// Photo distante, quand la residence n'a pas de photo embarquee.
  final String? imageUrl;
  final String eyebrow;
  final String? badge;
  final Color? badgeColor;
  final List<GiResidenceStat> stats;
  final VoidCallback? onTap;
  final double height;

  const GiResidenceCard({
    super.key,
    required this.id,
    required this.name,
    required this.address,
    required this.eyebrow,
    required this.stats,
    this.imageUrl,
    this.badge,
    this.badgeColor,
    this.onTap,
    this.height = FigSize.heroH,
  });

  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    final dir = Directionality.of(context);
    final asset = residenceImageAsset(id: id, name: name);
    final end = AlignmentDirectional.centerEnd.resolve(dir);

    final card = Container(
      height: height,
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(FigRadius.card),
      ),
      // Trait ambre peint par-dessus la photo, sinon le rognage le coupe
      // dans les angles.
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(FigRadius.card),
        border: Border.all(color: c.heroBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // La photo couvre la carte, montee en quatre paliers et plafonnee
          // a 78 % : elle reste teintee par la carte jusqu'au bord.
          Positioned.fill(
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (rect) => LinearGradient(
                begin: AlignmentDirectional.centerStart,
                end: AlignmentDirectional.centerEnd,
                colors: [
                  Colors.white.withValues(alpha: 0),
                  Colors.white.withValues(alpha: 0.10),
                  Colors.white.withValues(alpha: 0.45),
                  Colors.white.withValues(alpha: 0.78),
                ],
                stops: const [0.12, 0.42, 0.72, 1.0],
              ).createShader(rect, textDirection: dir),
              child: asset != null
                  ? Image.asset(asset,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.medium,
                      alignment: end)
                  : (imageUrl != null
                      ? Image.network(imageUrl!,
                          loadingBuilder: giImageLoading,
                          fit: BoxFit.cover,
                          alignment: end,
                          errorBuilder: (_, __, ___) =>
                              ColoredBox(color: c.card))
                      : ColoredBox(color: c.card)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(FigSpace.heroPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(eyebrow,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: FigText.body
                                      .copyWith(color: c.textFaint)),
                              const SizedBox(height: FigSpace.xs),
                              Text(name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: FigText.titleMd
                                      .copyWith(color: c.textBody)),
                            ],
                          ),
                        ),
                        if (badge != null && badge!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: c.scaffold,
                              border: Border.all(color: c.cardBorder),
                              borderRadius:
                                  BorderRadius.circular(FigRadius.pill),
                            ),
                            child: Text(badge!,
                                style: FigText.body.copyWith(
                                    color: badgeColor ?? FigBrand.amber)),
                          ),
                      ],
                    ),
                    if (address.isNotEmpty) ...[
                      const SizedBox(height: FigSpace.lg),
                      Row(
                        children: [
                          SvgPicture.asset(
                              'assets/figma/icons/pin_location.svg',
                              colorFilter: const ColorFilter.mode(
                                  FigBrand.amber, BlendMode.srcIn)),
                          const SizedBox(width: FigSpace.md),
                          Expanded(
                            child: Text(address,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style:
                                    FigText.body.copyWith(color: c.textBody)),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
                if (stats.isNotEmpty) _ribbon(c),
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return card;
    return GiPressable(pressedScale: 0.985, onTap: onTap, child: card);
  }

  Widget _ribbon(GiColors c) {
    final divider = Container(width: 1, height: 37, color: c.innerBorder);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(FigRadius.card),
        border: Border.all(color: c.innerBorder),
        gradient: LinearGradient(
          begin: AlignmentDirectional.centerStart,
          end: AlignmentDirectional.centerEnd,
          colors: [c.card.withValues(alpha: 0), c.card],
        ),
      ),
      child: SizedBox(
        height: 40,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var i = 0; i < stats.length; i++) ...[
              if (i > 0) divider,
              Flexible(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(stats[i].label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: FigText.label.copyWith(color: c.textFaint)),
                    Text(stats[i].value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: FigText.statValue
                            .copyWith(color: stats[i].color ?? c.textBody)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
