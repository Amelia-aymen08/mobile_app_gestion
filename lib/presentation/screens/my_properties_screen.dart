// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../l10n/app_localizations.dart';
import '../theme/design_tokens.dart';
import '../widgets/gi_appear.dart';
import '../theme/gi_colors.dart';
import '../theme/residence_images.dart';
import '../widgets/gi_empty_state.dart';
import '../widgets/gi_pressable.dart';
import '../widgets/gi_primary_button.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../data/api_service.dart';

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
    final full =
        (context.read<AuthProvider>().user?['name'] ?? '').toString().trim();
    if (full.isEmpty) return '';
    return full.split(RegExp(r'\s+')).first;
  }

  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    final t = AppL10n.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = _firstName;
    // En paysage, ou sur un tres petit ecran, l'en-tete du Figma — logo de
    // 98 puis titre et sous-titre — ne laisse plus de place aux cartes. On
    // le resserre plutot que de faire defiler un ecran de selection.
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
                  FigSpace.pagePadding, 22, FigSpace.pagePadding, 0),
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
            // Logo vertical du Figma, centre sous la pastille.
            Padding(
              padding: EdgeInsets.only(top: compact ? FigSpace.md : FigSpace.lg),
              child: Image.asset(
                isDark
                    ? 'assets/brand/gis_logo_vertical_dark.png'
                    : 'assets/brand/gis_logo_vertical_light.png',
                height: compact ? 48 : 90,
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(height: compact ? FigSpace.lg : FigSpace.xxl),
            // Titre centre du Figma, sur 295 de large.
            SizedBox(
              width: 295,
              child: Column(
                children: [
                  if (name.isNotEmpty) ...[
                    Text(t.greeting(name),
                        textAlign: TextAlign.center,
                        style: FigText.button
                            .copyWith(height: 1.2, color: FigBrand.amber)),
                    const SizedBox(height: FigSpace.sm),
                  ],
                  Text(t.selectResidenceTitle,
                      textAlign: TextAlign.center,
                      style: FigText.greeting
                          .copyWith(height: 1.2, color: c.textBody)),
                  // Le sous-titre explique le titre ; sur un ecran court il
                  // coute plus de place qu'il n'apporte.
                  if (!compact) ...[
                    const SizedBox(height: 9),
                    SizedBox(
                      width: 248,
                      child: Text(t.selectResidenceSubtitle,
                          textAlign: TextAlign.center,
                          style: FigText.field
                              .copyWith(height: 1.2, color: c.textMuted)),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: compact ? FigSpace.lg : FigSpace.xxl),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: FigBrand.amber))
                  : Stack(
                      children: [
                        RefreshIndicator(
                          color: FigBrand.amber,
                          backgroundColor: c.card,
                          onRefresh: _fetchAll,
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(
                                FigSpace.pagePadding,
                                0,
                                FigSpace.pagePadding,
                                // Le bouton flotte au-dessus de la liste :
                                // on reserve sa hauteur pour que la derniere
                                // carte reste atteignable.
                                104),
                            children: [
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
                            ],
                          ),
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
      onTap: () => setState(() => _selected = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        height: FigSize.heroH,
        decoration: BoxDecoration(
          color: isSelected ? FigBrand.amber.withValues(alpha: 0.20) : c.card,
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
                        alignment: AlignmentDirectional.centerEnd
                            .resolve(Directionality.of(context)))
                    : (url != null
                        ? Image.network(url,
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

  /// Bandeau du Figma : etage, surface et numero de lot, separes par un trait.
  /// La troisieme colonne porte le lot et non le statut, contrairement a la
  /// carte de l'accueil.
  Widget _stats(GiColors c, AppL10n t, String floor, String surface, String lot,
      bool isSelected) {
    Widget cell(String label, String value) => Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: FigText.label.copyWith(color: c.textFaint)),
              Text(value.isEmpty ? '—' : value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: FigText.statValue.copyWith(color: c.textMuted)),
            ],
          ),
        );

    final divider = Container(width: 1, height: 37, color: c.innerBorder);
    // Le fond du bandeau se fond dans la carte a gauche et se ferme a droite,
    // pour que les valeurs restent lisibles par-dessus la photo.
    final fill = isSelected
        ? Color.alphaBlend(FigBrand.amber.withValues(alpha: 0.20), c.card)
        : c.card;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(FigRadius.card),
        border: Border.all(
            color: isSelected
                ? FigBrand.amber.withValues(alpha: 0.20)
                : c.innerBorder),
        gradient: LinearGradient(
          begin: AlignmentDirectional.centerStart,
          end: AlignmentDirectional.centerEnd,
          colors: [fill.withValues(alpha: 0), fill],
        ),
      ),
      child: SizedBox(
        height: 40,
        child: Row(
          children: [
            cell(t.floor, floor),
            divider,
            const SizedBox(width: FigSpace.lg),
            cell(t.area, surface.isEmpty ? '' : '$surface m²'),
            divider,
            const SizedBox(width: FigSpace.lg),
            cell(t.unitLabel, lot),
          ],
        ),
      ),
    );
  }
}
