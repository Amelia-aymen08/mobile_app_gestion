// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../data/api_service.dart';
import '../../l10n/app_localizations.dart';
import '../theme/design_tokens.dart';
import '../theme/gi_colors.dart';
import '../widgets/gi_alert_dialog.dart';
import '../widgets/gi_card.dart';
import '../widgets/gi_pressable.dart';
import '../widgets/gi_primary_button.dart';
import '../widgets/gi_text_field.dart';
import '../widgets/gi_watermark.dart';

/// Inscription d'un resident.
///
/// Le Figma ne dessine pas cet ecran. Il reprend donc la frame « Login LT »
/// — filigrane, logo a 98, titre 28 puis sous-titre, champs de 52, bouton
/// ambre et une ligne de renvoi en bas — avec les champs de l'inscription.
///
/// Les trois dernieres listes s'enchainent : la residence determine les
/// etages, l'etage determine les appartements encore libres.
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final ApiService _api = ApiService();

  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();

  bool _sending = false;
  bool _loadingResidences = true;
  bool _loadingOptions = false;
  bool _touched = false;

  List<Map<String, dynamic>> _residences = [];
  List<String> _floors = [];
  List<Map<String, dynamic>> _units = [];
  String? _residenceId;
  String? _floor;
  String? _unitId;

  @override
  void initState() {
    super.initState();
    _fetchResidences();
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  // ─── Donnees ──────────────────────────────────────────────
  Future<void> _fetchResidences() async {
    setState(() => _loadingResidences = true);
    try {
      final data = await _api.getResidences();
      if (!mounted) return;
      setState(() {
        _residences = data
            .whereType<Map>()
            .map((r) => {
                  'id': (r['id'] ?? '').toString(),
                  'name': (r['name'] ?? '').toString(),
                })
            .where((r) => (r['id'] ?? '').toString().isNotEmpty)
            .cast<Map<String, dynamic>>()
            .toList();
        _loadingResidences = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingResidences = false);
      _showError(e);
    }
  }

  Future<void> _fetchOptions(String residenceId) async {
    setState(() {
      _loadingOptions = true;
      _floors = [];
      _units = [];
      _floor = null;
      _unitId = null;
    });
    try {
      final decoded = await _api.getRegistrationOptions(residenceId);
      final data = decoded['data'];
      final floors =
          (data is Map && data['floors'] is List) ? data['floors'] as List : const [];
      final units =
          (data is Map && data['units'] is List) ? data['units'] as List : const [];
      if (!mounted) return;
      setState(() {
        _floors = _sortFloors(floors.map((e) => (e ?? '').toString()).toList());
        _units =
            units.whereType<Map>().map((u) => u.cast<String, dynamic>()).toList();
        _loadingOptions = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingOptions = false);
      _showError(e);
    }
  }

  Future<void> _submit() async {
    final t = AppL10n.of(context);
    setState(() => _touched = true);
    if (_firstName.text.trim().isEmpty ||
        _lastName.text.trim().isEmpty ||
        !_emailLooksValid ||
        _phone.text.trim().isEmpty ||
        _residenceId == null ||
        _floor == null ||
        _unitId == null) {
      return;
    }

    setState(() => _sending = true);
    try {
      final unit = _unitsForFloor
          .where((u) => (u['id'] ?? '').toString() == _unitId)
          .firstOrNull;
      await _api.register({
        'firstName': _firstName.text.trim(),
        'lastName': _lastName.text.trim(),
        'email': _email.text.trim().toLowerCase(),
        'phone': _phone.text.trim(),
        'residenceId': _residenceId,
        'block': (unit?['block'] ?? '').toString(),
        'floor': _floor,
        'door': (unit?['apartmentNumber'] ?? '').toString(),
      });
      if (!mounted) return;
      setState(() => _sending = false);
      await showGiAlert<void>(
        context: context,
        title: t.registrationSentTitle,
        message: t.registrationSentBody,
        closeLabel: t.close,
        primaryLabel: t.backToLogin,
        onPrimary: () {},
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
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

  // ─── Libelles et tris ─────────────────────────────────────
  bool get _emailLooksValid {
    final value = _email.text.trim();
    return value.contains('@') && value.contains('.') && value.length > 5;
  }

  /// Le rez-de-chaussee arrive sans numero depuis l'API : il est range en
  /// dernier plutot qu'au hasard.
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

  List<Map<String, dynamic>> get _unitsForFloor {
    if (_floor == null) return [];
    final floor = _floor!.trim();
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

  String _floorLabel(AppL10n t, String floor) =>
      floor.isEmpty ? t.groundFloor : t.floorNumber(floor);

  String _unitLabel(Map<String, dynamic> u) {
    final apt = (u['apartmentNumber'] ?? '').toString();
    final block = (u['block'] ?? '').toString().trim();
    return block.isNotEmpty ? 'N° $apt — Bloc $block' : 'N° $apt';
  }

  // ─── Build ────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    final t = AppL10n.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final residenceName = _residences
        .where((r) => r['id'] == _residenceId)
        .map((r) => r['name'].toString())
        .firstOrNull;
    final unit = _unitsForFloor
        .where((u) => (u['id'] ?? '').toString() == _unitId)
        .firstOrNull;

    return Scaffold(
      backgroundColor: c.scaffold,
      body: Stack(
        children: [
          GiWatermark(isDark: isDark),
          SafeArea(
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(FigSpace.pagePadding, 23,
                  FigSpace.pagePadding, FigSpace.xxl),
              children: [
                Align(
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
                const SizedBox(height: FigSpace.lg),
                Center(
                  child: Image.asset(
                    isDark
                        ? 'assets/brand/gis_logo_vertical_dark.png'
                        : 'assets/brand/gis_logo_vertical_light.png',
                    height: 98,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 28),
                Text(t.registerTitle,
                    textAlign: TextAlign.center,
                    style: FigText.display.copyWith(color: c.loginTitle)),
                const SizedBox(height: 9),
                Text(t.registerSubtitle,
                    textAlign: TextAlign.center,
                    style: FigText.field
                        .copyWith(height: 1.2, color: c.loginSubtitle)),
                const SizedBox(height: 40),
                // Prenom et nom partagent une ligne : ce sont deux moities
                // d'une meme information, et le formulaire est deja long.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: GiTextField(
                        label: t.firstNameLabel,
                        hint: t.firstNameHint,
                        controller: _firstName,
                        textInputAction: TextInputAction.next,
                        errorText: _touched && _firstName.text.trim().isEmpty
                            ? t.firstNameRequired
                            : null,
                      ),
                    ),
                    const SizedBox(width: FigSpace.lg),
                    Expanded(
                      child: GiTextField(
                        label: t.lastNameLabel,
                        hint: t.lastNameHint,
                        controller: _lastName,
                        textInputAction: TextInputAction.next,
                        errorText: _touched && _lastName.text.trim().isEmpty
                            ? t.lastNameRequired
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: FigSpace.xl),
                GiTextField(
                  label: t.emailLabel,
                  hint: t.emailHint,
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  errorText:
                      _touched && !_emailLooksValid ? t.emailRequired : null,
                ),
                const SizedBox(height: FigSpace.xl),
                GiTextField(
                  label: t.phoneLabel,
                  hint: t.phoneHint,
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  errorText: _touched && _phone.text.trim().isEmpty
                      ? t.phoneRequired
                      : null,
                ),
                const SizedBox(height: FigSpace.xl),
                _selectField(
                  c,
                  label: t.residenceLabel,
                  value: residenceName,
                  hint: _loadingResidences ? t.loadingEllipsis : t.chooseResidence,
                  error: _touched && _residenceId == null
                      ? t.residenceRequired
                      : null,
                  enabled: !_loadingResidences && !_sending,
                  onTap: () => _pick(
                    c,
                    title: t.chooseResidence,
                    current: _residenceId,
                    options: _residences
                        .map((r) => (
                              id: r['id'].toString(),
                              label: r['name'].toString()
                            ))
                        .toList(),
                    onPicked: (id) {
                      setState(() => _residenceId = id);
                      _fetchOptions(id);
                    },
                  ),
                ),
                const SizedBox(height: FigSpace.xl),
                _selectField(
                  c,
                  label: t.floor,
                  value: _floor == null ? null : _floorLabel(t, _floor!),
                  hint: _residenceId == null
                      ? t.selectResidenceFirst
                      : _loadingOptions
                          ? t.loadingEllipsis
                          : _floors.isEmpty
                              ? t.noFloorAvailable
                              : t.chooseFloor,
                  error: _touched && _floor == null ? t.floorRequired : null,
                  enabled: _residenceId != null &&
                      !_loadingOptions &&
                      _floors.isNotEmpty &&
                      !_sending,
                  onTap: () => _pick(
                    c,
                    title: t.chooseFloor,
                    current: _floor,
                    options: _floors
                        .map((f) => (id: f, label: _floorLabel(t, f)))
                        .toList(),
                    onPicked: (f) => setState(() {
                      _floor = f;
                      _unitId = null;
                    }),
                  ),
                ),
                const SizedBox(height: FigSpace.xl),
                _selectField(
                  c,
                  label: t.apartmentLabel,
                  value: unit == null ? null : _unitLabel(unit),
                  hint: _floor == null
                      ? t.selectFloorFirst
                      : _unitsForFloor.isEmpty
                          ? t.noApartmentAvailable
                          : t.chooseApartment,
                  error:
                      _touched && _unitId == null ? t.apartmentRequired : null,
                  enabled: _floor != null &&
                      _unitsForFloor.isNotEmpty &&
                      !_sending,
                  onTap: () => _pick(
                    c,
                    title: t.chooseApartment,
                    current: _unitId,
                    options: _unitsForFloor
                        .map((u) =>
                            (id: (u['id'] ?? '').toString(), label: _unitLabel(u)))
                        .where((o) => o.id.isNotEmpty)
                        .toList(),
                    onPicked: (id) => setState(() => _unitId = id),
                  ),
                ),
                const SizedBox(height: FigSpace.xxl),
                GiPrimaryButton(
                  label: t.signUp,
                  isLoading: _sending,
                  onPressed: _sending ? null : _submit,
                ),
                const SizedBox(height: 17),
                // Renvoi vers la connexion, a la place de la ligne d'aide du
                // Figma : c'est la sortie naturelle de cet ecran.
                Center(
                  child: GiPressable(
                    pressedScale: 0.96,
                    onTap: () => Navigator.pop(context),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${t.alreadyHaveAccount} ',
                            style: FigText.body.copyWith(color: c.textMuted),
                          ),
                          TextSpan(
                            text: t.signIn,
                            style: FigText.bodyActive
                                .copyWith(color: FigBrand.amber),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Champ de selection : geometrie des champs de saisie du Figma, avec le
  /// chevron a droite et le message d'erreur sous le champ.
  Widget _selectField(
    GiColors c, {
    required String label,
    required String? value,
    required String hint,
    required String? error,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: FigText.fieldLabel.copyWith(color: c.textBody)),
        const SizedBox(height: FigSpace.xs),
        Opacity(
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
                    color: error != null
                        ? FigAlert.error
                        : value == null
                            ? c.fieldBorder
                            : c.fieldBorderFocus,
                    width: 1.5),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value ?? hint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: FigText.field.copyWith(
                          color: value == null ? c.fieldHint : c.fieldText),
                    ),
                  ),
                  const SizedBox(width: FigSpace.md),
                  SvgPicture.asset(
                    'assets/figma/icons/chevron_down.svg',
                    colorFilter: ColorFilter.mode(c.textMuted, BlendMode.srcIn),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: FigSpace.xs),
          Text(error, style: FigText.fieldLabel.copyWith(color: FigAlert.error)),
        ],
      ],
    );
  }

  /// Feuille commune aux trois listes : titre, puis une carte par choix.
  Future<void> _pick(
    GiColors c, {
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(FigRadius.card)),
      ),
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    FigSpace.pagePadding, 0, FigSpace.pagePadding, FigSpace.xl),
                child:
                    Text(title, style: FigText.titleMd.copyWith(color: c.textBody)),
              ),
              Flexible(
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(FigSpace.pagePadding, 0,
                      FigSpace.pagePadding, FigSpace.xxl),
                  itemCount: options.length,
                  separatorBuilder: (_, __) => const SizedBox(height: FigSpace.md),
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
                                style:
                                    FigText.statValue.copyWith(color: c.textBody)),
                          ),
                          if (option.id == current)
                            SvgPicture.asset(
                              'assets/figma/icons/check_14.svg',
                              colorFilter: const ColorFilter.mode(
                                  FigBrand.amber, BlendMode.srcIn),
                            ),
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
}
