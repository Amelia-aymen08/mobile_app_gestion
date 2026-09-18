// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../l10n/app_localizations.dart';
import '../theme/design_tokens.dart';
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

  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    final t = AppL10n.of(context);

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
            const SizedBox(height: FigSpace.xxl),
            // Titre centre du Figma, sur 295 de large.
            SizedBox(
              width: 295,
              child: Column(
                children: [
                  Text(t.changeResidence,
                      textAlign: TextAlign.center,
                      style: FigText.greeting.copyWith(color: c.textBody)),
                  const SizedBox(height: 9),
                  Text(t.switchResidenceSubtitle,
                      textAlign: TextAlign.center,
                      style:
                          FigText.field.copyWith(height: 1.2, color: c.textMuted)),
                ],
              ),
            ),
            const SizedBox(height: FigSpace.xxl),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: FigBrand.amber))
                  : RefreshIndicator(
                      color: FigBrand.amber,
                      backgroundColor: c.card,
                      onRefresh: _fetchAll,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(
                            FigSpace.pagePadding, 0, FigSpace.pagePadding, 24),
                        children: [
                          Text(t.yourProperties(_properties.length),
                              style:
                                  FigText.field.copyWith(color: c.textMuted)),
                          const SizedBox(height: FigSpace.lg),
                          if (_properties.isEmpty)
                            GiEmptyState(
                              illustration:
                                  'assets/figma/empty/payments.svg',
                              title: t.myProperties,
                              message: _error ?? t.noPropertyYet,
                            )
                          else
                            for (var i = 0; i < _properties.length; i++) ...[
                              if (i > 0) const SizedBox(height: FigSpace.lg),
                              _residenceCard(c, t, _properties[i] as Map, i),
                            ],
                        ],
                      ),
                    ),
            ),
            if (_properties.length > 1)
              Padding(
                padding: const EdgeInsets.fromLTRB(FigSpace.pagePadding, 0,
                    FigSpace.pagePadding, FigSpace.xxl),
                child: GiPrimaryButton(
                  label: t.switchAction,
                  onPressed: () => Navigator.pop(context, _selected),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Carte de residence, reprise de l'accueil et rendue selectionnable.
  /// Selectionnee : fond ambre a 20 %, trait ambre plein et coche.
  /// Sinon : surface de carte, trait ambre discret et case vide.
  Widget _residenceCard(GiColors c, AppL10n t, Map property, int index) {
    final isSelected = index == _selected;
    final residence = property['Residence'] is Map
        ? Map<String, dynamic>.from(property['Residence'] as Map)
        : <String, dynamic>{};
    final resName = _residenceName(property);
    final address = (residence['address'] ?? '').toString();
    final asset = residenceImageAsset(
        id: _residenceId(property), name: resName);
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
          color: isSelected
              ? FigBrand.amber.withValues(alpha: 0.20)
              : c.card,
          borderRadius: BorderRadius.circular(FigRadius.card),
          border: Border.all(
              color: isSelected ? FigBrand.amber : c.heroBorder),
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
                ).createShader(rect,
                    textDirection: Directionality.of(context)),
                child: asset != null
                    ? Image.asset(asset,
                        fit: BoxFit.cover, alignment: Alignment.centerRight)
                    : (url != null
                        ? Image.network(url,
                            fit: BoxFit.cover,
                            alignment: Alignment.centerRight,
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
                          // Indicateur de selection : coche pleine quand la
                          // carte est choisie, case vide sinon.
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: isSelected
                                ? const Icon(Icons.check_circle_rounded,
                                    key: ValueKey(true),
                                    size: 20,
                                    color: FigBrand.amber)
                                : Container(
                                    key: const ValueKey(false),
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: c.innerBorder,
                                      borderRadius:
                                          BorderRadius.circular(4),
                                    ),
                                  ),
                          ),
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

  /// Bandeau du Figma : etage, surface et numero de lot, separes par un trait.
  /// La troisieme colonne porte le lot et non le statut, contrairement a la
  /// carte de l'accueil.
  Widget _stats(GiColors c, AppL10n t, String floor, String surface,
      String lot, bool isSelected) {
    Widget cell(String label, String value) => Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: FigText.label.copyWith(color: c.textFaint)),
              Text(value.isEmpty ? '—' : value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: FigText.statValue.copyWith(color: c.textBody)),
            ],
          ),
        );

    final divider = Container(width: 1, height: 37, color: c.innerBorder);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(FigRadius.card),
        border: Border.all(
            color: isSelected ? c.heroBorder : c.innerBorder),
        gradient: LinearGradient(
          begin: AlignmentDirectional.centerStart,
          end: AlignmentDirectional.centerEnd,
          colors: [c.card.withValues(alpha: 0), c.card],
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

