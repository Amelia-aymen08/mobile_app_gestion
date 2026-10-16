// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import '../services/gi_haptics.dart';
import '../widgets/gi_skeleton.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../l10n/app_localizations.dart';
import '../theme/design_tokens.dart';
import '../widgets/gi_appear.dart';
import '../widgets/gi_bottom_nav.dart' show glassFallback;
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../theme/gi_colors.dart';
import '../theme/residence_images.dart';
import '../widgets/gi_empty_state.dart';
import '../widgets/gi_pressable.dart';
import '../widgets/gi_primary_button.dart';
import '../widgets/gi_refresh.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../data/api_service.dart';
import '../../data/person_name.dart';

class MyPropertiesScreen extends StatefulWidget {
  /// Bien affiche au moment de l'ouverture : la selection demarre dessus
  /// pour que l'ecran reflete ce que le resident voit sur l'accueil.
  final int initialIndex;

  const MyPropertiesScreen({super.key, this.initialIndex = 0});

  @override
  State<MyPropertiesScreen> createState() => _MyPropertiesScreenState();
}

class _MyPropertiesScreenState extends State<MyPropertiesScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _properties = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = context.read<AuthProvider>().user;
      final email = (user?['email'] ?? '').toString();
      if (email.isEmpty) {
        setState(() {
          _error = 'Utilisateur non identifié';
          _loading = false;
        });
        return;
      }
      final properties = await _api.getMyProperties(email);
      if (!mounted) return;
      setState(() {
        _properties = properties;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  // ─── Helpers ─────────────────────────────────────────────
  String _residenceId(dynamic property) {
    if (property is! Map) return '';
    if (property['Residence'] is Map) {
      return (property['Residence']['id'] ?? '').toString();
    }
    return (property['residenceId'] ?? '').toString();
  }

  String _residenceName(dynamic property) {
    if (property is! Map) return '';
    if (property['Residence'] is Map) {
      return (property['Residence']['name'] ?? '').toString();
    }
    return '';
  }

  String? _propertyImage(Map property) {
    final residence =
        property['Residence'] is Map ? property['Residence'] as Map : const {};
    final raw = '${property['image'] ?? residence['image'] ?? ''}'.trim();
    if (raw.isEmpty) return null;
    if (raw.startsWith('http')) return raw;
    final base = _api.baseUrl.replaceAll(RegExp(r'/api/?$'), '');
    return '$base/${raw.startsWith('/') ? raw.substring(1) : raw}';
  }

  // ─── Build ────────────────────────────────────────────────
  /// Bien mis en avant. Le Figma fait de cet ecran un selecteur : une carte
  /// porte la selection, le bouton du bas la confirme.
  late int _selected = widget.initialIndex;

  /// Prenom du resident, repris de la session. Le Figma ne l'affiche pas,
  /// mais l'ecran sert a choisir « sa » residence : nommer la personne rend
  /// le choix personnel plutot qu'administratif.
  String get _firstName {
    return PersonName.firstName(context.read<AuthProvider>().user?['name']);
  }

  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    final t = AppL10n.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = _firstName;
    // En paysage, ou sur un tres petit ecran, le logo de 90 prend trop de
    // place avant les cartes : on le resserre.
    final compact = MediaQuery.sizeOf(context).height < 620;

    return Scaffold(
      backgroundColor: c.scaffold,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // La pastille de retour occupe sa propre ligne, en haut a
            // gauche, la ou on la cherche. Posee sur le logo, elle avait
            // l'air d'en faire partie.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  FigSpace.pagePadding, 14, FigSpace.pagePadding, 0),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: GiPressable(
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
                      flipX: Directionality.of(context) == TextDirection.rtl,
                      child: SvgPicture.asset(
                        'assets/figma/icons/back_14.svg',
                        colorFilter:
                            ColorFilter.mode(c.textBody, BlendMode.srcIn),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const GiSkeletonList(count: 3, itemHeight: FigSize.heroH)
                  : Stack(
                      children: [
                        CustomScrollView(
                          physics: giRefreshPhysics,
                          slivers: [
                            GiRefreshControl(onRefresh: _fetchAll),
                            // Le logo et le bonjour defilent avec la page ;
                            // le titre, lui, s'arrete en haut et y reste,
                            // en se resserrant sur une ligne.
                            SliverToBoxAdapter(
                              child: _intro(t, isDark, name, compact),
                            ),
                            SliverPersistentHeader(
                              pinned: true,
                              delegate: _PinnedTitle(
                                title: t.selectResidenceTitle,
                                color: c.textBody,
                                background: c.scaffold,
                              ),
                            ),
                            const SliverToBoxAdapter(
                                child: SizedBox(height: FigSpace.lg)),
                            SliverPadding(
                            padding: const EdgeInsets.fromLTRB(
                                FigSpace.pagePadding,
                                0,
                                FigSpace.pagePadding,
                                // Le bouton flotte au-dessus de la liste :
                                // on reserve sa hauteur pour que la derniere
                                // carte reste atteignable.
                                104),
                            sliver: SliverList.list(children: [
                              Text(t.yourProperties(_properties.length),
                                  style: FigText.field.copyWith(
                                      height: 1.2, color: c.textMuted)),
                              const SizedBox(height: FigSpace.lg),
                              if (_properties.isEmpty)
                                GiEmptyState(
                                  illustration:
                                      'assets/figma/empty/payments.svg',
                                  title: t.myProperties,
                                  message: _error ?? t.noPropertyYet,
                                )
                              else
                                for (var i = 0;
                                    i < _properties.length;
                                    i++) ...[
                                  if (i > 0)
                                    const SizedBox(height: FigSpace.lg),
                                  GiAppear(
                                    index: i,
                                    child: _residenceCard(
                                        c, t, _properties[i] as Map, i),
                                  ),
                                ],
                            ]),
                            ),
                          ],
                        ),
                        // Voile sous le bouton : la carte passe dessous sans
                        // venir buter sur le libelle.
                        PositionedDirectional(
                          start: 0,
                          end: 0,
                          bottom: 0,
                          child: IgnorePointer(
                            child: Container(
                              height: 104,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    c.scaffold.withValues(alpha: 0),
                                    c.scaffold.withValues(alpha: 0.85),
                                    c.scaffold,
                                  ],
                                  stops: const [0, 0.45, 1],
                                ),
                              ),
                            ),
                          ),
                        ),
                        PositionedDirectional(
                          start: FigSpace.pagePadding,
                          end: FigSpace.pagePadding,
                          bottom: FigSpace.xxl,
                          child: GiPrimaryButton(
                            label: t.continueAction,
                            onPressed: _properties.isEmpty
                                ? null
                                : () => Navigator.pop(context, _selected),
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

  /// Logo et salutation, au-dessus du titre. Le sous-titre a disparu : il
  /// redisait le titre avec d'autres mots.
  Widget _intro(AppL10n t, bool isDark, String name, bool compact) {
    return Column(
      children: [
        SizedBox(height: compact ? FigSpace.md : FigSpace.lg),
        Image.asset(
          isDark
              ? 'assets/brand/gis_logo_vertical_dark.png'
              : 'assets/brand/gis_logo_vertical_light.png',
          height: compact ? 48 : 90,
          fit: BoxFit.contain,
        ),
        SizedBox(height: compact ? FigSpace.lg : FigSpace.xxl),
        if (name.isNotEmpty) ...[
          Text(t.greeting(name),
              textAlign: TextAlign.center,
              style:
                  FigText.button.copyWith(height: 1.2, color: FigBrand.amber)),
          const SizedBox(height: FigSpace.xs),
        ],
      ],
    );
  }

  /// Carte de residence, reprise de l'accueil et rendue selectionnable.
  /// Selectionnee : fond ambre a 20 %, trait ambre plein et coche ambre.
  /// Sinon : surface de carte, trait ambre a 20 % et case grise.
  Widget _residenceCard(GiColors c, AppL10n t, Map property, int index) {
    final isSelected = index == _selected;
    final residence = property['Residence'] is Map
        ? Map<String, dynamic>.from(property['Residence'] as Map)
        : <String, dynamic>{};
    final resName = _residenceName(property);
    final address = (residence['address'] ?? '').toString();
    final asset =
        residenceImageAsset(id: _residenceId(property), name: resName);
    final url = _propertyImage(Map<String, dynamic>.from(property));
    final floor = (property['floor'] ?? '').toString();
    final surface = (property['surface'] ?? '').toString();
    final lot = (property['lotNumber'] ?? '').toString();

    return GiPressable(
      pressedScale: 0.985,
      haptic: false,
      onTap: () {
        if (index != _selected) GiHaptics.select();
        setState(() => _selected = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        height: FigSize.heroH,
        decoration: BoxDecoration(
          color: isSelected ? FigBrand.amber.withValues(alpha: 0.20) : c.card,
          borderRadius: BorderRadius.circular(FigRadius.card),
        ),
        // Trait peint par-dessus la photo : pose dessous, le rognage le
        // coupait dans les angles.
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(FigRadius.card),
          border: Border.all(
              color: isSelected
                  ? FigBrand.amber
                  : FigBrand.amber.withValues(alpha: 0.20)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
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
                ).createShader(rect, textDirection: Directionality.of(context)),
                child: asset != null
                    ? Image.asset(asset,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.medium,
                        alignment: AlignmentDirectional.centerEnd
                            .resolve(Directionality.of(context)))
                    : (url != null
                        ? Image.network(url,
                            loadingBuilder: giImageLoading,
                            fit: BoxFit.cover,
                            alignment: AlignmentDirectional.centerEnd
                                .resolve(Directionality.of(context)),
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
                                Text(t.myResidence,
                                    style: FigText.body
                                        .copyWith(color: c.textFaint)),
                                const SizedBox(height: FigSpace.xs),
                                Text(resName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: FigText.titleMd
                                        .copyWith(color: c.textBody)),
                              ],
                            ),
                          ),
                          _selectionBox(c, isSelected),
                        ],
                      ),
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
                  ),
                  _stats(c, t, floor, surface, lot, isSelected),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Marqueur de selection du Figma : carre de 20 au rayon 4. Choisi, il
  /// passe en ambre et porte la coche ; sinon il reste une case grise.
  Widget _selectionBox(GiColors c, bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isSelected ? FigBrand.amber : c.innerBorder,
        borderRadius: BorderRadius.circular(4),
      ),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        scale: isSelected ? 1 : 0,
        child: SvgPicture.asset(
          'assets/figma/icons/check_14.svg',
          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
        ),
      ),
    );
  }

  /// Bandeau etage, appartement, statut : une plaque de verre liquide posee
  /// sur la photo. Le verre refracte sans flouter — la photo reste nette a
  /// travers — et les valeurs, en clair et en gras, se lisent d'un coup
  /// d'oeil. Sans shader (web, simulateur), un verre peint prend le relais.
  Widget _stats(GiColors c, AppL10n t, String floor, String surface, String lot,
      bool isSelected) {
    const radius = 14.0;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final valueColor = dark ? Colors.white : FigBrand.navy;
    final labelColor = dark
        ? Colors.white.withValues(alpha: 0.62)
        : FigBrand.navy.withValues(alpha: 0.6);

    Widget cell(String label, String value, {bool accent = false}) => Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: FigText.label.copyWith(
                      fontSize: 11, letterSpacing: 0.2, color: labelColor)),
              const SizedBox(height: 3),
              Row(
                children: [
                  if (accent) ...[
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                          color: FigAlert.success, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(value.isEmpty ? '—' : value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: FigText.statValue.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: valueColor)),
                  ),
                ],
              ),
            ],
          ),
        );

    final divider = Container(
      width: 1,
      height: 30,
      margin: const EdgeInsetsDirectional.only(end: 14),
      color: valueColor.withValues(alpha: 0.18),
    );

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          cell(t.floor, floor),
          divider,
          cell(t.apartmentShortLabel, lot),
          divider,
          cell(t.status, t.statusActive, accent: true),
        ],
      ),
    );

    final Widget glass = glassFallback
        ? DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: dark
                    ? [
                        const Color(0xFF1C2732).withValues(alpha: 0.88),
                        FigBrand.navy.withValues(alpha: 0.82),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.88),
                        Colors.white.withValues(alpha: 0.74),
                      ],
              ),
            ),
          )
        : GlassContainer(
            useOwnLayer: true,
            quality: GlassQuality.premium,
            shape: const LiquidRoundedSuperellipse(borderRadius: radius),
            settings: LiquidGlassSettings(
              glassColor: dark
                  ? FigBrand.navy.withValues(alpha: 0.55)
                  : Colors.white.withValues(alpha: 0.6),
              thickness: 24,
              blur: 0,
              refractiveIndex: 1.45,
              lightIntensity: 0.7,
              ambientStrength: 0.5,
              saturation: 1.15,
              chromaticAberration: 0.1,
            ),
            child: const SizedBox.expand(),
          );

    return SizedBox(
      height: 60,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
            ),
          ),
          Positioned.fill(child: glass),
          // Arete de lumiere : plus vive en haut, comme un verre eclaire
          // par-dessus ; ambre quand la carte est choisie.
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  border: Border.all(
                    color: isSelected
                        ? FigBrand.amber.withValues(alpha: 0.55)
                        : Colors.white.withValues(alpha: dark ? 0.22 : 0.7),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.center,
                    colors: [
                      Colors.white.withValues(alpha: dark ? 0.10 : 0.25),
                      Colors.white.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(child: content),
        ],
      ),
    );
  }
}

/// Titre qui se fige en haut de la liste. Deplie, il tient sur deux lignes
/// en 24 ; une fois colle en haut il passe sur une ligne en 18, sur le fond
/// de l'ecran, avec un fondu en dessous pour que les cartes y glissent.
class _PinnedTitle extends SliverPersistentHeaderDelegate {
  final String title;
  final Color color;
  final Color background;

  const _PinnedTitle({
    required this.title,
    required this.color,
    required this.background,
  });

  @override
  // 16 de fondu compris en bas : dessine hors de l'en-tete, il etait rogne
  // et laissait voir le contenu qui passe dessous.
  double get maxExtent => 92;

  @override
  double get minExtent => 68;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final p = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        Positioned(
            left: 0, right: 0, top: 0, bottom: 16,
            child: ColoredBox(color: background)),
        Positioned.fill(
          bottom: 16,
          child: Center(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: FigSpace.pagePadding),
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: p > 0.5 ? 1 : 2,
              overflow: TextOverflow.ellipsis,
              style: FigText.greeting.copyWith(
                height: 1.2,
                fontSize: 24 - 6 * p,
                color: color,
              ),
            ),
          ),
        )),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 16,
          child: IgnorePointer(
            child: Opacity(
              opacity: 0.4 + 0.6 * p,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [background, background.withValues(alpha: 0)],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  bool shouldRebuild(_PinnedTitle old) =>
      old.title != title || old.color != color || old.background != background;
}
