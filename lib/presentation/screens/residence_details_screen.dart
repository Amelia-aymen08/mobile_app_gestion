import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/gi_skeleton.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../data/api_service.dart';
import '../../l10n/app_localizations.dart';
import '../theme/amenities.dart';
import '../theme/design_tokens.dart';
import '../theme/gi_colors.dart';
import '../theme/residence_images.dart';
import '../theme/residence_locations.dart';
import '../widgets/gi_appear.dart';
import '../widgets/gi_back_button.dart';
import '../widgets/gi_bottom_nav.dart' show glassFallback;
import '../widgets/gi_pressable.dart';
import '../widgets/gi_refresh.dart';
import '../widgets/residence_map.dart';

/// Fiche d'une residence : photos, adresse, commodites et presentation.
///
/// La photo bord a bord en haut, puis une fiche aux coins arrondis qui la
/// recouvre en bas : le nom, l'adresse, les commodites et la description. Rien a vendre ni a reserver ici : on ne
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
  final ScrollController _scroll = ScrollController();

  /// Position du defilement, pour la barre du haut et la photo.
  final ValueNotifier<double> _offset = ValueNotifier(0);

  Map<String, dynamic>? _residence;
  bool _loading = true;
  String? _error;
  int _page = 0;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() => _offset.value = _scroll.offset);
    _load();
  }

  @override
  void dispose() {
    _pages.dispose();
    _scroll.dispose();
    _offset.dispose();
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

    final media = MediaQuery.of(context);
    // Photo bord a bord, recadree comme dans les grandes apps : elle tient le
    // haut de l'ecran et la fiche aux coins arrondis glisse par-dessus.
    // En paysage l'ecran est bas : le plafond l'emporte sur le plancher.
    final maxHero = media.size.height * 0.48;
    final heroHeight = (media.size.width * 0.86)
        .clamp(maxHero < 280.0 ? maxHero : 280.0, maxHero)
        .toDouble();

    return Scaffold(
      backgroundColor: c.scaffold,
      body: Stack(children: [
        CustomScrollView(
          controller: _scroll,
          physics: giRefreshPhysics,
          slivers: [
            GiRefreshControl(onRefresh: _load),
            SliverToBoxAdapter(
              child: Stack(children: [
                SizedBox(
                  // La photo continue sous le haut de la fiche, pour que le
                  // verre ait quelque chose a flouter.
                  height: heroHeight - _sheetRadius + _sheetRim,
                  child: _parallax(heroHeight, _photo(c, photos)),
                ),
                // La fiche remonte sur le bas de la photo et descend jusqu'en
                // bas de l'ecran.
                Padding(
                  padding: EdgeInsets.only(top: heroHeight - _sheetRadius),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                        minHeight:
                            media.size.height - heroHeight + _sheetRadius),
                    child: _sheet(
                      c,
                      Padding(
                        padding: EdgeInsets.only(
                            top: 20, bottom: media.padding.bottom + 32),
                        child: _content(
                            c, t, dark, name, address, description, amenities),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ],
        ),
        // Barre du haut : transparente sur la photo, elle devient pleine et
        // affiche le nom une fois celui-ci passe dessous.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _topBar(context, c, t, name, heroHeight),
        ),
      ]),
    );
  }

  /// Rayon des coins de la fiche, qui recouvre d'autant le bas de la photo.
  static const double _sheetRadius = 28;

  /// Hauteur de la barre du haut, sous la barre d'etat.
  static const double _barHeight = 56;

  /// La photo defile moins vite que la fiche, et s'etire quand on tire la
  /// page vers le bas pour la rafraichir.
  Widget _parallax(double heroHeight, Widget child) {
    return ValueListenableBuilder<double>(
      valueListenable: _offset,
      child: child,
      builder: (context, offset, child) {
        if (offset < 0) {
          return Transform.scale(
            scale: 1 + -offset / heroHeight,
            alignment: Alignment.bottomCenter,
            child: child,
          );
        }
        return Transform.translate(offset: Offset(0, offset * 0.4), child: child);
      },
    );
  }

  Widget _topBar(BuildContext context, GiColors c, AppL10n t, String name,
      double heroHeight) {
    final top = MediaQuery.of(context).padding.top;
    final dark = Theme.of(context).brightness == Brightness.dark;
    // La barre se remplit pendant que le bord de la fiche passe dessous.
    final start = heroHeight - _sheetRadius - top - _barHeight - 24;
    return ValueListenableBuilder<double>(
      valueListenable: _offset,
      builder: (context, offset, _) {
        final fill = ((offset - start) / 40).clamp(0.0, 1.0);
        // Le nom n'apparait qu'une fois celui de la fiche cache.
        final title = ((offset - start - 40) / 30).clamp(0.0, 1.0);
        return AnnotatedRegion<SystemUiOverlayStyle>(
          // Heure et batterie en blanc sur la photo, en noir sur la barre.
          value: fill > 0.5 && !dark
              ? SystemUiOverlayStyle.dark
              : SystemUiOverlayStyle.light,
          // Barre en verre depoli : la page reste devinee en dessous.
          child: ClipRect(
            child: BackdropFilter(
              enabled: fill > 0,
              filter: ui.ImageFilter.blur(sigmaX: 20 * fill, sigmaY: 20 * fill),
              child: DecoratedBox(
            decoration: BoxDecoration(
              color: c.scaffold.withValues(alpha: 0.72 * fill),
              border: Border(
                  bottom: BorderSide(
                      color: c.cardBorder.withValues(alpha: fill),
                      width: 0.5)),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  FigSpace.pagePadding, top, FigSpace.pagePadding, 0),
              child: SizedBox(
                height: _barHeight,
                child: Stack(alignment: Alignment.center, children: [
                  // Sur la photo, le titre de la page en blanc ; il s'efface
                  // quand le nom prend sa place.
                  if (title < 1)
                    Opacity(
                      opacity: 1 - title,
                      child: Text(t.residenceDetails,
                          maxLines: 1,
                          style: FigText.titleMd.copyWith(
                            fontSize: 17,
                            color: Colors.white,
                            shadows: const [
                              Shadow(color: Colors.black45, blurRadius: 12)
                            ],
                          )),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 56),
                    child: Opacity(
                      opacity: title,
                      child: Text(name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: FigText.titleMd
                              .copyWith(fontSize: 17, color: c.textBody)),
                    ),
                  ),
                  // Fond plein sur la photo, pastille habituelle sur la barre.
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: GiBackButton(overMedia: fill < 0.5),
                  ),
                ]),
              ),
            ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Hauteur de la lame de verre en haut de la fiche.
  static const double _sheetRim = 52;

  /// Courbe tres douce aux deux bouts, pour le fondu du verre vers la fiche.
  static double _ease(double t) => t * t * t * (t * (t * 6 - 15) + 10);

  /// Fiche aux coins arrondis posee sur la photo. Son haut est une lame de
  /// verre liquide : sur l'arrondi, l'epaisseur du verre deforme la photo
  /// comme une vitre, puis le fond de la fiche monte en douceur par-dessus.
  Widget _sheet(GiColors c, Widget child) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Stack(children: [
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        height: _sheetRim,
        child: GlassContainer(
          useOwnLayer: true,
          quality: GlassQuality.premium,
          shape: const LiquidVerticalRoundedRectangle(
              topRadius: _sheetRadius, bottomRadius: 0),
          settings: LiquidGlassSettings(
            // Verre laiteux et desature : la photo se devine, sans que le
            // bleu du ciel ne teinte la lame.
            glassColor: c.scaffold.withValues(alpha: dark ? 0.8 : 0.86),
            thickness: 18,
            blur: 4,
            refractiveIndex: 1.45,
            lightIntensity: dark ? 0.25 : 0.4,
            saturation: 0.55,
            chromaticAberration: 0.01,
          ),
          child: const SizedBox.expand(),
        ),
      ),
      // Le fond de la fiche monte sur le verre selon une courbe douce aux
      // deux bouts : ni debut ni fin visibles.
      Positioned(
        top: 4,
        left: 0,
        right: 0,
        height: 40,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [for (var i = 0; i <= 12; i++) i / 12],
              colors: [
                for (var i = 0; i <= 12; i++)
                  c.scaffold.withValues(alpha: _ease(i / 12)),
              ],
            ),
          ),
        ),
      ),
      Positioned.fill(
        top: 41,
        child: ColoredBox(color: c.scaffold),
      ),
      child,
    ]);
  }

  Widget _content(GiColors c, AppL10n t, bool dark, String name, String address,
      String description, List<String> amenities) {
    final location = residenceLocation(id: widget.residenceId, name: name);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: FigSpace.pagePadding),
          child: _identity(c, name, address),
        ),
        if (_loading)
          const Padding(
            padding: EdgeInsets.fromLTRB(
                FigSpace.pagePadding, 20, FigSpace.pagePadding, 0),
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
            GiAppear(child: _amenitiesRow(c, t, dark, amenities)),
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
          if (location != null)
            GiAppear(
              index: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    FigSpace.pagePadding, 0, FigSpace.pagePadding, 0),
                child: ResidenceMap(
                  latitude: location.$1,
                  longitude: location.$2,
                  header: Padding(
                    padding: const EdgeInsets.only(top: 26, bottom: 12),
                    child: Text(t.locationTitle,
                        style: FigText.titleMd
                            .copyWith(fontSize: 17, color: c.textBody)),
                  ),
                ),
              ),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  FigSpace.pagePadding, 16, FigSpace.pagePadding, 0),
              child: Text(_error!,
                  textAlign: TextAlign.center,
                  style: FigText.body.copyWith(color: FigAlert.error)),
            ),
        ],
      ],
    );
  }

  /// Photo bord a bord, jusque sous la barre d'etat, sans rien rogner. A
  /// feuilleter du doigt ; un toucher l'ouvre en grand. Le compteur
  /// n'apparait que s'il y a plusieurs photos.
  Widget _photo(GiColors c, List<_Photo> photos) {
    return Stack(fit: StackFit.expand, children: [
      if (photos.isEmpty)
        ColoredBox(
          color: c.card,
          child: Center(
            child: SvgPicture.asset('assets/figma/amenities/photos.svg',
                width: 32,
                colorFilter: ColorFilter.mode(c.textFaint, BlendMode.srcIn)),
          ),
        )
      else
        PageView.builder(
          controller: _pages,
          itemCount: photos.length,
          onPageChanged: (i) => setState(() => _page = i),
          itemBuilder: (context, i) => GestureDetector(
            onTap: () => _openViewer(photos, i),
            child: _heroPage(c, photos[i]),
          ),
        ),
      // Voile sombre en haut pour lire l'heure et le titre.
      const IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.center,
              colors: [Color(0x73000000), Color(0x00000000)],
            ),
          ),
        ),
      ),
      if (photos.length > 1)
        PositionedDirectional(
          end: FigSpace.pagePadding,
          bottom: _sheetRim + 12,
          child: GiPressable(
            onTap: () => _openViewer(photos, _page),
            child: _glassPill(
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: 11),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                SvgPicture.asset('assets/figma/amenities/photos.svg',
                    width: 14,
                    colorFilter:
                        const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
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
    ]);
  }

  /// Une page de la photo du haut, recadree pour remplir toute la largeur.
  Widget _heroPage(GiColors c, _Photo photo) {
    return photo.build(fallback: c.card);
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

  /// Commodites sur une seule ligne qui defile de cote : des tuiles toutes
  /// pareilles, l'icone au-dessus du libelle. La largeur laisse deviner la
  /// tuile suivante au bord de l'ecran. Une cle inconnue garde son libelle
  /// brut et une etoile.
  Widget _amenitiesRow(
      GiColors c, AppL10n t, bool dark, List<String> amenities) {
    const gap = 10.0;

    Widget chip(String raw, double width) {
      final key = raw.trim();
      final icon = kAmenityKeys.contains(key) ? key : 'autre';
      return Container(
        // Un libelle long passe sur deux lignes au lieu d'etirer la tuile.
        width: width,
        height: 92,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: dark ? Colors.white.withValues(alpha: 0.06) : c.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.cardBorder),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset('assets/figma/amenities/$icon.svg',
                width: 24,
                colorFilter:
                    const ColorFilter.mode(FigBrand.amber, BlendMode.srcIn)),
            const SizedBox(height: 8),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: FigSpace.pagePadding),
          child: Text(t.amenitiesTitle,
              style: FigText.titleMd.copyWith(fontSize: 17, color: c.textBody)),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(builder: (context, constraints) {
          // Un peu plus de trois tuiles a l'ecran : on voit qu'il y en a
          // d'autres, et « stationnement » tient sur sa ligne.
          final width =
              (constraints.maxWidth - FigSpace.pagePadding - 3 * gap) / 3.2;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(horizontal: FigSpace.pagePadding),
            child: Row(children: [
              for (var i = 0; i < amenities.length; i++) ...[
                if (i > 0) const SizedBox(width: gap),
                chip(amenities[i], width),
              ],
            ]),
          );
        }),
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
