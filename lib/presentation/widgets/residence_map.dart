import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latlong2/latlong.dart';

import '../theme/design_tokens.dart';
import '../theme/gi_colors.dart';
import 'gi_back_button.dart';
import 'gi_pressable.dart';

/// Carte de l'emplacement d'une residence, dans une carte arrondie.
///
/// La carte est figee : un toucher l'ouvre en plein ecran, ou l'on peut la
/// deplacer et zoomer. Fond de carte OpenStreetMap, sans cle ni compte,
/// recolore aux tons de l'app : creme le jour, bleu nuit le soir. Le
/// repere est la pastille ambre de la marque.
class ResidenceMap extends StatelessWidget {
  final double latitude;
  final double longitude;

  /// Titre au-dessus de la carte.
  final Widget? header;

  const ResidenceMap({
    super.key,
    required this.latitude,
    required this.longitude,
    this.header,
  });

  LatLng get _point => LatLng(latitude, longitude);

  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (header != null) header!,
        SizedBox(
          height: 210,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(fit: StackFit.expand, children: [
              _MapView(point: _point, zoom: 14.5, interactive: false),
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _open(context),
                ),
              ),
              PositionedDirectional(
                top: 12,
                end: 12,
                child: GiPressable(
                  onTap: () => _open(context),
                  pressedScale: 0.88,
                  child: _RoundButton(
                    child: Icon(Icons.open_in_full_rounded,
                        size: 18, color: c.textBody),
                  ),
                ),
              ),
              // Liseré fin, comme les autres cartes de l'app.
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: c.cardBorder),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  void _open(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _FullMap(point: _point),
    ));
  }
}

/// Le fond de carte et le repere, figes ou libres selon [interactive].
class _MapView extends StatelessWidget {
  final LatLng point;
  final double zoom;
  final bool interactive;

  const _MapView({
    required this.point,
    required this.zoom,
    required this.interactive,
  });

  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return FlutterMap(
      options: MapOptions(
        initialCenter: point,
        initialZoom: zoom,
        minZoom: 3,
        maxZoom: 19,
        backgroundColor: c.card,
        interactionOptions: InteractionOptions(
          flags: interactive
              ? InteractiveFlag.all & ~InteractiveFlag.rotate
              : InteractiveFlag.none,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.globalimmoservice.app',
          // Les couleurs vives d'OpenStreetMap, ramenees aux tons de l'app.
          tileBuilder: (context, tile, _) => ColorFiltered(
            colorFilter: ColorFilter.matrix(dark ? _darkMatrix : _lightMatrix),
            child: tile,
          ),
        ),
        MarkerLayer(markers: [
          Marker(
            point: point,
            width: _haloSize,
            height: _haloSize,
            child: const _Pin(),
          ),
        ]),
        // Mention exigee par OpenStreetMap.
        Align(
          alignment: AlignmentDirectional.bottomStart,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Text('© OpenStreetMap',
                style: FigText.body.copyWith(
                    fontSize: 9.5, color: c.textMuted.withValues(alpha: 0.8))),
          ),
        ),
      ],
    );
  }
}

/// La carte en plein ecran, libre de bouger, avec un retour en haut.
class _FullMap extends StatelessWidget {
  final LatLng point;
  const _FullMap({required this.point});

  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final top = MediaQuery.paddingOf(context).top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: c.scaffold,
        body: Stack(children: [
          _MapView(point: point, zoom: 15.5, interactive: true),
          PositionedDirectional(
            top: top + 8,
            start: FigSpace.pagePadding,
            child: const GiBackButton(overMedia: true),
          ),
        ]),
      ),
    );
  }
}

/// Bouton rond pose sur la carte, couleur du fond de page.
class _RoundButton extends StatelessWidget {
  final Widget child;
  const _RoundButton({required this.child});

  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.scaffold,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
              color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 3)),
        ],
      ),
      child: child,
    );
  }
}

const double _pinSize = 52;
const double _haloSize = 84;

/// Le repere : une pastille ambre cerclee de blanc, l'immeuble au centre,
/// dans un halo ambre leger.
class _Pin extends StatelessWidget {
  const _Pin();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _haloSize,
      height: _haloSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: FigBrand.amber.withValues(alpha: 0.18),
        shape: BoxShape.circle,
      ),
      child: Container(
        width: _pinSize,
        height: _pinSize,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: FigBrand.amber,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [
            BoxShadow(
                color: Color(0x40000000), blurRadius: 14, offset: Offset(0, 4)),
          ],
        ),
        child: SvgPicture.asset('assets/figma/icons/nav_residence_fill.svg',
            width: 24),
      ),
    );
  }
}

// Luminance d'un pixel : 0.2126 R + 0.7152 G + 0.0722 B.

/// Clair : couleurs presque eteintes (15 % gardees), teintees creme.
const List<double> _lightMatrix = [
  0.319, 0.586, 0.059, 0, 0, //
  0.172, 0.722, 0.058, 0, 0, //
  0.167, 0.563, 0.196, 0, 0, //
  0, 0, 0, 1, 0, //
];

/// Sombre : luminance inversee, du bleu nuit (#0C1620) pour le fond au
/// gris bleute pour les noms de rues.
const List<double> _darkMatrix = [
  -0.132, -0.443, -0.045, 0, 170, //
  -0.133, -0.449, -0.045, 0, 182, //
  -0.137, -0.460, -0.046, 0, 196, //
  0, 0, 0, 1, 0, //
];
