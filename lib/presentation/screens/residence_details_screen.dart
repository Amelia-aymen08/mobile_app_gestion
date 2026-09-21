import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../data/api_service.dart';
import '../../l10n/app_localizations.dart';
import '../theme/amenities.dart';
import '../theme/design_tokens.dart';
import '../theme/gi_colors.dart';
import '../theme/residence_images.dart';
import '../widgets/gi_appear.dart';
import '../widgets/gi_card.dart';
import '../widgets/gi_pressable.dart';

/// Fiche d'une residence : photo, adresse, presentation et commodites.
///
/// Le Figma ne dessine pas cet ecran. Il reprend la carte de l'accueil pour
/// la photo — meme hauteur, meme degrade — puis nos cartes pour le texte.
/// La description et les commodites viennent du site Aymen Promotion, que le
/// back-end expose depuis `GET /residences/:id`.
class ResidenceDetailsScreen extends StatefulWidget {
  final String residenceId;
  final String residenceName;

  const ResidenceDetailsScreen({
    super.key,
    required this.residenceId,
    required this.residenceName,
  });

  @override
  State<ResidenceDetailsScreen> createState() => _ResidenceDetailsScreenState();
}

class _ResidenceDetailsScreenState extends State<ResidenceDetailsScreen> {
  final ApiService _api = ApiService();

  Map<String, dynamic>? _residence;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _api.getResidence(widget.residenceId);
      if (!mounted) return;
      setState(() {
        _residence = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  List<String> get _amenities {
    final raw = _residence?['amenities'];
    if (raw is List) {
      return raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }
    // Le serveur peut aussi renvoyer une chaine separee par des virgules.
    if (raw is String) {
      return raw
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    final t = AppL10n.of(context);

    final name = (_residence?['name'] ?? widget.residenceName).toString();
    final address = (_residence?['address'] ?? '').toString();
    final description = (_residence?['description'] ?? '').toString();
    final amenities = _amenities;

    return Scaffold(
      backgroundColor: c.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                  FigSpace.pagePadding,
                  MediaQuery.paddingOf(context).top > 0 ? 22 : 32,
                  FigSpace.pagePadding,
                  0),
              child: Row(
                children: [
                  GiPressable(
                    onTap: () => Navigator.pop(context),
                    pressedScale: 0.88,
                    child: Container(
                      width: FigSize.chipMd,
                      height: FigSize.chipMd,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: c.headerChipBg,
                        border: Border.all(color: c.headerChipBorder),
                        borderRadius: BorderRadius.circular(FigRadius.chip),
                      ),
                      child: Transform.flip(
                        flipX:
                            Directionality.of(context) == TextDirection.rtl,
                        child: SvgPicture.asset(
                          'assets/figma/icons/back_14.svg',
                          colorFilter:
                              ColorFilter.mode(c.textBody, BlendMode.srcIn),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 17),
                  Expanded(
                    child: Text(t.residenceDetails,
                        style: FigText.titleMd
                            .copyWith(fontSize: 18, color: c.textBody)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: FigBrand.amber))
                  : RefreshIndicator(
                      color: FigBrand.amber,
                      backgroundColor: c.card,
                      onRefresh: _load,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(
                            FigSpace.pagePadding, 0, FigSpace.pagePadding, 40),
                        children: [
                          GiAppear(child: _cover(c, name, address)),
                          if (description.isNotEmpty) ...[
                            const SizedBox(height: FigSpace.lg),
                            GiAppear(
                              index: 1,
                              child: GiCard(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(t.aboutTitle,
                                        style: FigText.titleMd
                                            .copyWith(color: c.textBody)),
                                    const SizedBox(height: FigSpace.lg),
                                    Text(description,
                                        style: FigText.fieldLabel.copyWith(
                                            height: 1.6, color: c.textMuted)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          if (amenities.isNotEmpty) ...[
                            const SizedBox(height: FigSpace.lg),
                            GiAppear(
                              index: 2,
                              child: _amenitiesCard(c, t, amenities),
                            ),
                          ],
                          if (_error != null) ...[
                            const SizedBox(height: FigSpace.lg),
                            Text(_error!,
                                textAlign: TextAlign.center,
                                style: FigText.body
                                    .copyWith(color: FigAlert.error)),
                          ],
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Photo de la residence, au format de la carte de l'accueil : le resident
  /// reconnait son immeuble avant de lire quoi que ce soit.
  Widget _cover(GiColors c, String name, String address) {
    final asset =
        residenceImageAsset(id: widget.residenceId, name: name);
    final url = _api.mediaUrl(_residence?['image']);

    return Container(
      height: FigSize.heroH,
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(FigRadius.card),
        border: Border.all(color: c.heroBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (asset != null)
            Image.asset(asset,
                fit: BoxFit.cover, filterQuality: FilterQuality.medium)
          else if (url != null)
            Image.network(url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => ColoredBox(color: c.card)),
          // Voile sombre en bas : le nom reste lisible quelle que soit la
          // photo.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0),
                  Colors.black.withValues(alpha: 0.55),
                ],
                stops: const [0.45, 1],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(FigSpace.heroPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FigText.greeting
                        .copyWith(fontSize: 20, color: Colors.white)),
                if (address.isNotEmpty) ...[
                  const SizedBox(height: FigSpace.xs),
                  Row(
                    children: [
                      SvgPicture.asset('assets/figma/icons/pin_location.svg',
                          colorFilter: const ColorFilter.mode(
                              FigBrand.amber, BlendMode.srcIn)),
                      const SizedBox(width: FigSpace.md),
                      Expanded(
                        child: Text(address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: FigText.body
                                .copyWith(color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Commodites en pastilles. Pas d'icone : le catalogue en compte dix-neuf
  /// et le Figma n'en dessine aucune — un point ambre suffit a marquer
  /// l'entree sans emprunter un jeu d'icones etranger.
  Widget _amenitiesCard(GiColors c, AppL10n t, List<String> amenities) {
    return GiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.amenitiesTitle,
              style: FigText.titleMd.copyWith(color: c.textBody)),
          const SizedBox(height: FigSpace.lg),
          Wrap(
            spacing: FigSpace.md,
            runSpacing: FigSpace.md,
            children: [
              for (final key in amenities)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: FigSpace.lg, vertical: FigSpace.md),
                  decoration: BoxDecoration(
                    color: FigAccent.chipFill(FigBrand.amber),
                    border:
                        Border.all(color: FigAccent.chipBorder(FigBrand.amber)),
                    borderRadius: BorderRadius.circular(FigRadius.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                            color: FigBrand.amber, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: FigSpace.md),
                      Text(amenityLabel(t, key),
                          style: FigText.body.copyWith(color: c.textBody)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
