import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import '../widgets/gi_skeleton.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../data/api_service.dart';
import '../../l10n/app_localizations.dart';
import '../theme/amenities.dart';
import '../theme/design_tokens.dart';
import '../theme/gi_colors.dart';
import '../theme/residence_images.dart';
import '../widgets/gi_appear.dart';
import '../widgets/gi_bottom_nav.dart' show glassFallback;
import '../widgets/gi_pressable.dart';
import '../widgets/gi_refresh.dart';

/// Fiche d'une residence : photos, adresse, commodites et presentation.
///
/// Un en-tete simple, la photo en rectangle arrondi dans la marge, puis le
/// nom, l'adresse, les commodites et la description. Rien a vendre ni a reserver ici : on ne
/// montre que ce que le back-end renvoie par `GET /residences/:id`, la
/// description et les commodites venant du site Aymen Promotion.
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

/// Une photo de la galerie : un fichier de l'app ou une adresse du serveur.
class _Photo {
  final String? asset;
  final String? url;
  const _Photo.asset(this.asset) : url = null;
  const _Photo.url(this.url) : asset = null;

  Widget build({BoxFit fit = BoxFit.cover, Color? fallback}) {
    if (asset != null) {
      return Image.asset(asset!, fit: fit, filterQuality: FilterQuality.medium);
    }
    return Image.network(url!,
        fit: fit,
        loadingBuilder: giImageLoading,
        errorBuilder: (_, __, ___) =>
            ColoredBox(color: fallback ?? Colors.black));
  }
}

class _ResidenceDetailsScreenState extends State<ResidenceDetailsScreen> {
  final ApiService _api = ApiService();
  final PageController _pages = PageController();

  Map<String, dynamic>? _residence;
  bool _loading = true;
  String? _error;
  int _page = 0;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
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

  List<String> _list(Object? raw) {
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

  List<String> get _amenities => _list(_residence?['amenities']);

  /// La photo de l'app d'abord (celle de l'accueil, sinon celle du serveur),
  /// puis les autres photos si le serveur en envoie une liste `images`.
  /// Sans liste, la galerie se resume a une photo et le compteur se tait.
  List<_Photo> _photos(String name) {
    final photos = <_Photo>[];
    final seen = <String>{};
    final asset = residenceImageAsset(id: widget.residenceId, name: name);
    final main = _api.mediaUrl(_residence?['image']);
    if (asset != null) {
      photos.add(_Photo.asset(asset));
    } else if (main != null) {
      photos.add(_Photo.url(main));
      seen.add(main);
    }
    for (final raw in _list(_residence?['images'])) {
      final url = _api.mediaUrl(raw);
      if (url != null && seen.add(url)) photos.add(_Photo.url(url));
    }
    return photos;
  }

  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    final t = AppL10n.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;

    final name = (_residence?['name'] ?? widget.residenceName).toString();
    final address = (_residence?['address'] ?? '').toString().trim();
    final description = (_residence?['description'] ?? '').toString().trim();
    final amenities = _amenities;
    final photos = _photos(name);

    return Scaffold(
      backgroundColor: c.scaffold,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // En-tete : retour a gauche, titre au centre.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  FigSpace.pagePadding, 10, FigSpace.pagePadding, 0),
              child: SizedBox(
                height: 44,
                child: Stack(alignment: Alignment.center, children: [
                  Text(t.residenceDetails,
                      style: FigText.titleMd
                          .copyWith(fontSize: 17, color: c.textBody)),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: GiPressable(
                      onTap: () => Navigator.pop(context),
                      pressedScale: 0.88,
                      child: Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: c.headerChipBg,
                          border: Border.all(color: c.headerChipBorder),
                          shape: BoxShape.circle,
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
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: CustomScrollView(
                physics: giRefreshPhysics,
                slivers: [
                  GiRefreshControl(onRefresh: _load),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(
                          bottom: MediaQuery.paddingOf(context).bottom + 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: FigSpace.pagePadding),
                            child: _photo(c, photos),
                          ),
                          const SizedBox(height: 18),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: FigSpace.pagePadding),
                            child: _identity(c, name, address),
                          ),
                          if (_loading)
                            const Padding(
                              padding: EdgeInsets.fromLTRB(FigSpace.pagePadding,
                                  20, FigSpace.pagePadding, 0),
                              child: GiShimmer(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    GiBone(width: double.infinity, height: 130),
                                    SizedBox(height: 24),
                                    GiBone(width: 120, height: 16),
                                    SizedBox(height: 12),
                                    GiBone(width: double.infinity, height: 60),
                                  ],
                                ),
                              ),
                            )
                          else ...[
                            if (amenities.isNotEmpty) ...[
                              const SizedBox(height: 22),
                              GiAppear(
                                  child: _amenitiesRow(c, t, dark, amenities)),
                            ],
                            if (description.isNotEmpty) ...[
                              const SizedBox(height: 22),
                              GiAppear(
                                index: 1,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: FigSpace.pagePadding),
                                  child: _description(c, t, description),
                                ),
                              ),
                            ],
                            if (_error != null)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    FigSpace.pagePadding,
                                    16,
                                    FigSpace.pagePadding,
                                    0),
                                child: Text(_error!,
                                    textAlign: TextAlign.center,
                                    style: FigText.body
                                        .copyWith(color: FigAlert.error)),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Photo en rectangle arrondi, dans la marge de la page. A feuilleter du
  /// doigt ; un toucher l'ouvre en grand. Le compteur n'apparait que s'il y
  /// a plusieurs photos.
  Widget _photo(GiColors c, List<_Photo> photos) {
    return AspectRatio(
      aspectRatio: 2 / 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(fit: StackFit.expand, children: [
          if (photos.isEmpty)
            ColoredBox(
              color: c.card,
              child: Center(
                child: SvgPicture.asset('assets/figma/amenities/photos.svg',
                    width: 32,
                    colorFilter:
                        ColorFilter.mode(c.textFaint, BlendMode.srcIn)),
              ),
            )
          else
            PageView.builder(
              controller: _pages,
              itemCount: photos.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (context, i) => GestureDetector(
                onTap: () => _openViewer(photos, i),
                child: photos[i].build(fallback: c.card),
              ),
            ),
          if (photos.length > 1)
            PositionedDirectional(
              end: 12,
              bottom: 12,
              child: GiPressable(
                onTap: () => _openViewer(photos, _page),
                child: _glassPill(
                  height: 30,
                  padding: const EdgeInsets.symmetric(horizontal: 11),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    SvgPicture.asset('assets/figma/amenities/photos.svg',
                        width: 14,
                        colorFilter: const ColorFilter.mode(
                            Colors.white, BlendMode.srcIn)),
                    const SizedBox(width: 6),
                    Text('${_page + 1} / ${photos.length}',
                        style: FigText.body.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
                  ]),
                ),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _identity(GiColors c, String name, String address) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: FigText.greeting
                .copyWith(fontSize: 24, height: 1.15, color: c.textBody)),
        if (address.isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(children: [
            SvgPicture.asset('assets/figma/icons/pin_location.svg',
                height: 14,
                colorFilter:
                    const ColorFilter.mode(FigBrand.amber, BlendMode.srcIn)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      FigText.body.copyWith(fontSize: 14, color: c.textMuted)),
            ),
          ]),
        ],
      ],
    );
  }

  /// Commodites en tuiles sur deux lignes qui defilent ensemble de cote :
  /// l'icone au-dessus, le libelle en entier dessous. Elles
  /// alternent d'une ligne a l'autre pour que les deux aient la meme
  /// longueur. Une cle inconnue garde son libelle brut et une etoile.
  Widget _amenitiesRow(
      GiColors c, AppL10n t, bool dark, List<String> amenities) {
    Widget chip(String raw) {
      final key = raw.trim();
      final icon = kAmenityKeys.contains(key) ? key : 'autre';
      return Container(
        // Toutes de la meme taille, comme une grille : un libelle long passe
        // sur deux lignes au lieu d'etirer la tuile.
        width: 116,
        height: 78,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: dark ? Colors.white.withValues(alpha: 0.06) : c.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.cardBorder),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset('assets/figma/amenities/$icon.svg',
                width: 22,
                colorFilter:
                    const ColorFilter.mode(FigBrand.amber, BlendMode.srcIn)),
            const SizedBox(height: 6),
            Text(amenityLabel(t, key),
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: FigText.body
                    .copyWith(fontSize: 11.5, height: 1.2, color: c.textBody)),
          ],
        ),
      );
    }

    Widget line(int parity) => Row(children: [
          for (var i = parity; i < amenities.length; i += 2) ...[
            if (i > parity) const SizedBox(width: 8),
            chip(amenities[i]),
          ],
        ]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: FigSpace.pagePadding),
          child: Text(t.amenitiesTitle,
              style: FigText.titleMd.copyWith(fontSize: 17, color: c.textBody)),
        ),
        const SizedBox(height: 12),
        // Les pastilles filent jusqu'au bord de l'ecran : on voit qu'il y en
        // a d'autres a droite.
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: FigSpace.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              line(0),
              if (amenities.length > 1) ...[
                const SizedBox(height: 8),
                line(1),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Description sur trois lignes, a deplier d'un toucher.
  Widget _description(GiColors c, AppL10n t, String description) {
    final style =
        FigText.body.copyWith(fontSize: 14, height: 1.55, color: c.textMuted);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.descriptionLabel,
            style: FigText.titleMd.copyWith(fontSize: 17, color: c.textBody)),
        const SizedBox(height: 8),
        LayoutBuilder(builder: (context, constraints) {
          final painter = TextPainter(
            text: TextSpan(text: description, style: style),
            maxLines: 3,
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
          )..layout(maxWidth: constraints.maxWidth);
          final long = painter.didExceedMaxLines;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: long ? () => setState(() => _expanded = !_expanded) : null,
            child: AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(description,
                      maxLines: _expanded ? null : 3,
                      overflow: _expanded ? null : TextOverflow.ellipsis,
                      style: style),
                  if (long && !_expanded) ...[
                    const SizedBox(height: 4),
                    Text(t.readMore,
                        style: style.copyWith(
                            fontWeight: FontWeight.w600, color: c.textBody)),
                  ],
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  /// Pastille de verre sur la photo : le vrai verre liquide sur iPhone, un
  /// verre depoli sur le simulateur et le web.
  Widget _glassPill({
    double? width,
    required double height,
    EdgeInsets padding = EdgeInsets.zero,
    required Widget child,
  }) {
    final content = SizedBox(
      width: width,
      height: height,
      child: Padding(padding: padding, child: Center(child: child)),
    );
    if (glassFallback) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(height / 2),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(height / 2),
            ),
            child: content,
          ),
        ),
      );
    }
    return GlassContainer(
      useOwnLayer: true,
      quality: GlassQuality.premium,
      shape: LiquidRoundedSuperellipse(borderRadius: height / 2),
      settings: LiquidGlassSettings(
        glassColor: Colors.white.withValues(alpha: 0.14),
        thickness: 16,
        blur: 8,
        refractiveIndex: 1.25,
        lightIntensity: 0.4,
        saturation: 1.2,
        chromaticAberration: 0,
      ),
      child: content,
    );
  }

  /// Les photos en grand, sur fond noir, a feuilleter et agrandir.
  void _openViewer(List<_Photo> photos, int start) {
    Navigator.of(context).push(PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black,
      pageBuilder: (context, _, __) =>
          _PhotoViewer(photos: photos, start: start),
      transitionsBuilder: (context, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    ));
  }
}

class _PhotoViewer extends StatefulWidget {
  final List<_Photo> photos;
  final int start;
  const _PhotoViewer({required this.photos, required this.start});

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  late final PageController _pages = PageController(initialPage: widget.start);
  late int _page = widget.start;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        PageView.builder(
          controller: _pages,
          itemCount: widget.photos.length,
          onPageChanged: (i) => setState(() => _page = i),
          itemBuilder: (context, i) => InteractiveViewer(
            maxScale: 4,
            child: Center(child: widget.photos[i].build(fit: BoxFit.contain)),
          ),
        ),
        PositionedDirectional(
          top: top + 10,
          end: FigSpace.pagePadding,
          child: GiPressable(
            onTap: () => Navigator.pop(context),
            pressedScale: 0.88,
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: SvgPicture.asset('assets/figma/icons/close_16.svg',
                  colorFilter:
                      const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
            ),
          ),
        ),
        if (widget.photos.length > 1)
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.paddingOf(context).bottom + 24,
            child: Text('${_page + 1} / ${widget.photos.length}',
                textAlign: TextAlign.center,
                style: FigText.body.copyWith(
                    fontWeight: FontWeight.w600, color: Colors.white)),
          ),
      ]),
    );
  }
}
