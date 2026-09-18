// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../data/api_service.dart';
import '../../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../theme/design_tokens.dart';
import '../theme/gi_colors.dart';
import '../widgets/gi_alert_dialog.dart';
import '../widgets/gi_card.dart';
import '../widgets/gi_pressable.dart';
import '../widgets/gi_primary_button.dart';

/// Demande de rattachement d'un bien.
///
/// Le Figma ne dessine pas cet ecran : il est repris de la maquette
/// « Add Report LT », dont il partage la structure — pastille de retour,
/// titre 18, libelle 14 puis champ, et le bouton ambre en bas. Les trois
/// listes sont ouvertes dans une feuille glissee du bas, comme la priorite
/// du signalement, plutot que dans un menu deroulant Material.
///
/// Les listes s'enchainent : la residence determine les etages, l'etage
/// determine les appartements encore libres.
class PropertyAddRequestScreen extends StatefulWidget {
  const PropertyAddRequestScreen({super.key});

  @override
  State<PropertyAddRequestScreen> createState() =>
      _PropertyAddRequestScreenState();
}

class _PropertyAddRequestScreenState extends State<PropertyAddRequestScreen> {
  final ApiService _api = ApiService();

  bool _loadingResidences = true;
  bool _isOptionsLoading = false;
  bool _submitting = false;
  List<dynamic> _residences = [];
  String? _selectedResidenceId;

  List<String> _floors = [];
  List<Map<String, dynamic>> _units = [];
  String? _selectedFloor;
  String? _selectedUnitId;

  @override
  void initState() {
    super.initState();
    _fetchResidences();
  }

  // ─── Donnees ──────────────────────────────────────────────
  Future<void> _fetchResidences() async {
    setState(() => _loadingResidences = true);
    try {
      final list = await _api.getResidences(forPropertyRequest: true);
      if (!mounted) return;
      setState(() {
        _residences = list;
        _loadingResidences = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingResidences = false);
      _showError(e);
    }
  }

  Future<void> _fetchResidenceOptions(String residenceId) async {
    setState(() {
      _isOptionsLoading = true;
      _floors = [];
      _units = [];
      _selectedFloor = null;
      _selectedUnitId = null;
    });

    try {
      final decoded = await _api.getRegistrationOptions(residenceId);
      final data = decoded['data'];
      final floors =
          (data is Map && data['floors'] is List) ? (data['floors'] as List) : const [];
      final units =
          (data is Map && data['units'] is List) ? (data['units'] as List) : const [];

      if (!mounted) return;
      setState(() {
        _floors = _sortFloors(floors.map((e) => (e ?? '').toString()).toList());
        _units =
            units.whereType<Map>().map((u) => u.cast<String, dynamic>()).toList();
        _isOptionsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isOptionsLoading = false);
      _showError(e);
    }
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await _api.submitPropertyAddRequest(
        residenceId: _selectedResidenceId!,
        propertyId: _selectedUnitId!,
        notes: '',
      );
      if (!mounted) return;
      setState(() => _submitting = false);
      final t = AppL10n.of(context);
      await showGiAlert<void>(
        context: context,
        title: t.requestSentTitle,
        message: t.requestSentBody,
        closeLabel: t.close,
        primaryLabel: t.close,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showError(e);
    }
  }

  void _showError(Object e) {
    final t = AppL10n.of(context);
    showGiAlert<void>(
      context: context,
      title: t.errorTitle,
      message: e.toString().replaceAll('Exception: ', ''),
      closeLabel: t.close,
      primaryLabel: t.close,
    );
  }

  // ─── Libelles ─────────────────────────────────────────────
  String _residenceLabel(dynamic r) {
    if (r is! Map) return '';
    final name = (r['name'] ?? '').toString().trim();
    final zone = (r['zone'] ?? '').toString().trim();
    if (name.isEmpty) return (r['id'] ?? '').toString();
    return zone.isNotEmpty ? '$name ($zone)' : name;
  }

  String _residenceId(dynamic r) =>
      r is Map ? (r['id'] ?? '').toString().trim() : '';

  /// Etages tries par valeur numerique. Le rez-de-chaussee arrive sans
  /// numero depuis l'API : il est range en dernier plutot qu'au hasard.
  List<String> _sortFloors(List<String> floors) {
    final copy = [...floors];
    copy.sort((a, b) {
      if (a.isEmpty && b.isEmpty) return 0;
      if (a.isEmpty) return 1;
      if (b.isEmpty) return -1;
      final ai = int.tryParse(a.trim());
      final bi = int.tryParse(b.trim());
      if (ai != null && bi != null) return ai.compareTo(bi);
      return a.compareTo(b);
    });
    return copy;
  }

  String _floorLabel(AppL10n t, String floor) =>
      floor.isEmpty ? t.groundFloor : t.floorNumber(floor);

  String _unitLabel(Map<String, dynamic> u) {
    final apt = (u['apartmentNumber'] ?? '').toString();
    final block = (u['block'] ?? '').toString().trim();
    return block.isNotEmpty ? 'N° $apt — Bloc $block' : 'N° $apt';
  }

  List<Map<String, dynamic>> get _unitsForSelectedFloor {
    if (_selectedFloor == null) return [];
    final floor = _selectedFloor!.trim();
    final list =
        _units.where((u) => (u['floor'] ?? '').toString().trim() == floor).toList();
    list.sort((a, b) {
      final an = int.tryParse((a['apartmentNumber'] ?? '').toString());
      final bn = int.tryParse((b['apartmentNumber'] ?? '').toString());
      if (an != null && bn != null) return an.compareTo(bn);
      return (a['apartmentNumber'] ?? '')
          .toString()
          .compareTo((b['apartmentNumber'] ?? '').toString());
    });
    return list;
  }

  bool get _canSubmit =>
      !_submitting &&
      (_selectedResidenceId ?? '').isNotEmpty &&
      _selectedFloor != null &&
      (_selectedUnitId ?? '').isNotEmpty;

  // ─── Build ────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    final t = AppL10n.of(context);
    final email = (context.watch<AuthProvider>().user?['email'] ?? '').toString();

    final residenceName = _residences
        .whereType<Map>()
        .where((r) => _residenceId(r) == _selectedResidenceId)
        .map(_residenceLabel)
        .firstOrNull;
    final unit = _unitsForSelectedFloor
        .where((u) => (u['id'] ?? '').toString() == _selectedUnitId)
        .firstOrNull;

    return Scaffold(
      backgroundColor: c.scaffold,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
              FigSpace.pagePadding,
              MediaQuery.paddingOf(context).top > 0 ? 22 : 32,
              FigSpace.pagePadding,
              40),
          children: [
            // En-tete du Figma : pastille de retour de 32, ecart 17, titre 18.
            Row(
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
                      flipX: Directionality.of(context) == TextDirection.rtl,
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
                  child: Text(t.addProperty,
                      style: FigText.titleMd
                          .copyWith(fontSize: 18, color: c.textBody)),
                ),
              ],
            ),
            const SizedBox(height: FigSpace.xxl),
            _accountCard(c, t, email),
            const SizedBox(height: 17),
            _label(c, t.residenceLabel),
            const SizedBox(height: FigSpace.xs),
            _selectField(
              c,
              value: residenceName,
              hint: _loadingResidences ? t.loadingEllipsis : t.chooseResidence,
              enabled: !_loadingResidences && !_submitting,
              onTap: () => _pickResidence(c, t),
            ),
            const SizedBox(height: 17),
            _label(c, t.floor),
            const SizedBox(height: FigSpace.xs),
            _selectField(
              c,
              value:
                  _selectedFloor == null ? null : _floorLabel(t, _selectedFloor!),
              hint: _selectedResidenceId == null
                  ? t.selectResidenceFirst
                  : _isOptionsLoading
                      ? t.loadingEllipsis
                      : _floors.isEmpty
                          ? t.noFloorAvailable
                          : t.chooseFloor,
              enabled: _selectedResidenceId != null &&
                  !_isOptionsLoading &&
                  _floors.isNotEmpty &&
                  !_submitting,
              onTap: () => _pickFloor(c, t),
            ),
            const SizedBox(height: 17),
            _label(c, t.apartmentLabel),
            const SizedBox(height: FigSpace.xs),
            _selectField(
              c,
              value: unit == null ? null : _unitLabel(unit),
              hint: _selectedFloor == null
                  ? t.selectFloorFirst
                  : _unitsForSelectedFloor.isEmpty
                      ? t.noApartmentAvailable
                      : t.chooseApartment,
              enabled: _selectedFloor != null &&
                  _unitsForSelectedFloor.isNotEmpty &&
                  !_submitting,
              onTap: () => _pickUnit(c, t),
            ),
            const SizedBox(height: FigSpace.xl),
            // La demande passe par le gestionnaire : le dire evite d'attendre
            // un rattachement immediat.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: c.textFaint),
                const SizedBox(width: FigSpace.md),
                Expanded(
                  child: Text(t.addPropertyNotice,
                      style: FigText.body
                          .copyWith(height: 1.4, color: c.textMuted)),
                ),
              ],
            ),
            const SizedBox(height: FigSpace.xxl),
            GiPrimaryButton(
              label: t.sendRequest,
              isLoading: _submitting,
              onPressed: _canSubmit ? _submit : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(GiColors c, String text) =>
      Text(text, style: FigText.fieldLabel.copyWith(color: c.textMuted));

  /// Rappel du compte auquel le bien sera rattache. L'ancienne page posait
  /// l'adresse seule au milieu de l'ecran, sans dire a quoi elle servait.
  Widget _accountCard(GiColors c, AppL10n t, String email) {
    if (email.isEmpty) return const SizedBox.shrink();
    return GiCard(
      child: Row(
        children: [
          GiIconChip(
            accent: FigBrand.amber,
            icon: SvgPicture.asset(
              'assets/figma/icons/profile_20.svg',
              colorFilter:
                  const ColorFilter.mode(FigBrand.amber, BlendMode.srcIn),
            ),
          ),
          const SizedBox(width: FigSpace.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.accountLabel,
                    style: FigText.body.copyWith(color: c.textFaint)),
                const SizedBox(height: FigSpace.xs),
                Text(email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FigText.statValue.copyWith(color: c.textBody)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Champ de selection : meme geometrie que les champs de saisie du Figma
  /// (rayon 8, bordure 1.5, padding 16), avec le chevron a droite.
  Widget _selectField(
    GiColors c, {
    required String? value,
    required String hint,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: GiPressable(
        pressedScale: enabled ? 0.99 : 1,
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.all(FigSpace.xl - 1.5),
          decoration: BoxDecoration(
            color: c.fieldBg,
            borderRadius: BorderRadius.circular(FigRadius.field),
            border: Border.all(
                color: value == null ? c.fieldBorder : c.fieldBorderFocus,
                width: 1.5),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value ?? hint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: FigText.field
                      .copyWith(color: value == null ? c.fieldHint : c.fieldText),
                ),
              ),
              const SizedBox(width: FigSpace.md),
              Icon(Icons.keyboard_arrow_down_rounded,
                  size: 20, color: c.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Feuilles de selection ────────────────────────────────
  /// Feuille commune aux trois listes : titre, puis une carte par choix avec
  /// la coche ambre sur la valeur retenue.
  Future<void> _pickFrom({
    required GiColors c,
    required String title,
    required List<({String id, String label})> options,
    required String? current,
    required ValueChanged<String> onPicked,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: c.scaffold,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(FigRadius.card)),
      ),
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          // Une residence peut compter beaucoup d'appartements : la feuille
          // s'arrete a 70 % de l'ecran et la liste defile a l'interieur.
          constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(FigSpace.pagePadding, 0,
                    FigSpace.pagePadding, FigSpace.xl),
                child: Text(title,
                    style: FigText.titleMd.copyWith(color: c.textBody)),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(FigSpace.pagePadding, 0,
                      FigSpace.pagePadding, FigSpace.xxl),
                  itemCount: options.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: FigSpace.md),
                  itemBuilder: (_, i) {
                    final option = options[i];
                    return GiCard(
                      onTap: () {
                        onPicked(option.id);
                        Navigator.pop(sheetContext);
                      },
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(option.label,
                                style: FigText.statValue
                                    .copyWith(color: c.textBody)),
                          ),
                          if (option.id == current)
                            const Icon(Icons.check_rounded,
                                color: FigBrand.amber, size: 20),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickResidence(GiColors c, AppL10n t) => _pickFrom(
        c: c,
        title: t.chooseResidence,
        current: _selectedResidenceId,
        options: _residences
            .whereType<Map>()
            .map((r) => (id: _residenceId(r), label: _residenceLabel(r)))
            .where((o) => o.id.isNotEmpty)
            .toList(),
        onPicked: (id) {
          setState(() {
            _selectedResidenceId = id;
            _selectedFloor = null;
            _selectedUnitId = null;
            _floors = [];
            _units = [];
          });
          _fetchResidenceOptions(id);
        },
      );

  Future<void> _pickFloor(GiColors c, AppL10n t) => _pickFrom(
        c: c,
        title: t.chooseFloor,
        current: _selectedFloor,
        options:
            _floors.map((f) => (id: f, label: _floorLabel(t, f))).toList(),
        onPicked: (f) => setState(() {
          _selectedFloor = f;
          _selectedUnitId = null;
        }),
      );

  Future<void> _pickUnit(GiColors c, AppL10n t) => _pickFrom(
        c: c,
        title: t.chooseApartment,
        current: _selectedUnitId,
        options: _unitsForSelectedFloor
            .map((u) => (id: (u['id'] ?? '').toString(), label: _unitLabel(u)))
            .where((o) => o.id.isNotEmpty)
            .toList(),
        onPicked: (id) => setState(() => _selectedUnitId = id),
      );
}
