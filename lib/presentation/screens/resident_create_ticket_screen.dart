import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../l10n/app_localizations.dart';
import '../theme/design_tokens.dart';
import '../theme/gi_colors.dart';
import '../widgets/gi_card.dart';
import '../widgets/gi_pressable.dart';
import '../widgets/gi_primary_button.dart';
import 'package:file_picker/file_picker.dart';
import '../../data/api_service.dart';

class ResidentCreateTicketScreen extends StatefulWidget {
  final Map<String, dynamic> property;

  const ResidentCreateTicketScreen({super.key, required this.property});

  @override
  State<ResidentCreateTicketScreen> createState() => _ResidentCreateTicketScreenState();
}

class _ResidentCreateTicketScreenState extends State<ResidentCreateTicketScreen> {
  final ApiService _api = ApiService();

  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();

  bool _loading = true;
  bool _submitting = false;

  List<Map<String, dynamic>> _categories = [];
  String? _selectedCategory;
  String? _selectedSubCategory;

  String _priority = 'Moyenne';
  PlatformFile? _attachment;

  String _apartmentNumberFromLotNumber(dynamic lotNumber) {
    final raw = (lotNumber ?? '').toString().trim();
    if (raw.isEmpty) return '';
    final parts = raw.split('-').where((p) => p.trim().isNotEmpty).toList();
    return (parts.isNotEmpty ? parts.last : raw).trim();
  }

  String? _mimeTypeForFilename(String filename) {
    final parts = filename.split('.');
    if (parts.length < 2) return null;
    final ext = parts.last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      default:
        return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _api.getMaintenanceCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _selectedCategory = _categories.isNotEmpty ? (_categories.first['category']?.toString()) : null;
        _selectedSubCategory = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur catégories: $e')));
    }
  }

  List<String> get _subCategoriesForSelected {
    final cat = _selectedCategory;
    if (cat == null) return [];
    final entry = _categories.firstWhere(
      (c) => (c['category'] ?? '').toString() == cat,
      orElse: () => <String, dynamic>{},
    );
    final items = entry['items'];
    if (items is List) {
      return items.map((e) => (e ?? '').toString()).where((e) => e.trim().isNotEmpty).toList();
    }
    return [];
  }

  String _locationLabel() {
    final p = widget.property;
    final apt = _apartmentNumberFromLotNumber(p['lotNumber']);
    final block = (p['block'] ?? '').toString().trim();
    final floor = (p['floor'] ?? '').toString().trim();
    final residenceName = (p['Residence'] is Map ? (p['Residence']['name'] ?? '') : '').toString().trim();

    final parts = <String>[
      if (residenceName.isNotEmpty) residenceName,
      if (apt.isNotEmpty) 'Appartement n° $apt',
      if (block.isNotEmpty) 'Bloc $block',
      if (floor.isNotEmpty) 'Étage $floor',
    ];
    return parts.join(' • ');
  }

  Future<void> _pickAttachment() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp', 'doc', 'docx', 'xls', 'xlsx'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final picked = result.files.first;
    if (picked.bytes == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Impossible de lire le fichier sélectionné.')));
      return;
    }
    if (picked.size > 2 * 1024 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fichier trop grand (max 2 Mo).')));
      return;
    }
    final mime = _mimeTypeForFilename(picked.name);
    if (mime == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Type de fichier non supporté.')));
      return;
    }
    setState(() => _attachment = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null || _selectedSubCategory == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Choisissez une catégorie et un type de problème.')));
      return;
    }

    setState(() => _submitting = true);
    try {
      final p = widget.property;
      final residenceId = (p['residenceId'] ?? '').toString().trim();
      final location = _locationLabel();

      final payload = <String, dynamic>{
        'title': _selectedSubCategory,
        'description': _descController.text.trim(),
        'priority': _priority,
        'status': 'Signalé',
        'category': _selectedCategory,
        'location': location,
        if (residenceId.isNotEmpty) 'residenceId': residenceId,
      };

      final created = await _api.createTicket(payload);

      if (_attachment != null && _attachment!.bytes != null) {
        final mime = _mimeTypeForFilename(_attachment!.name);
        if (mime != null) {
          await _api.uploadTicketAttachment(
            ticketId: created['id'].toString(),
            bytes: _attachment!.bytes!,
            filename: _attachment!.name,
            mimeType: mime,
          );
        }
      }

      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signalement envoyé.')));
    } catch (e) {
      if (mounted) {
        final raw = e.toString();
        final msg = raw.replaceFirst(RegExp(r'^Exception:\s*'), '');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg.isNotEmpty ? msg : 'Erreur')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    final t = AppL10n.of(context);

    return Scaffold(
      backgroundColor: c.scaffold,
      body: SafeArea(
        child: Form(
          key: _formKey,
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
                  Text(t.newReport,
                      style: FigText.titleMd
                          .copyWith(fontSize: 18, color: c.textBody)),
                ],
              ),
              const SizedBox(height: FigSpace.xxl),
              _propertyCard(c, t),
              const SizedBox(height: 17),
              _label(c, t.category),
              const SizedBox(height: FigSpace.xs),
              _chips(
                c,
                _categories.map((e) => e['category'].toString()).toList(),
                _selectedCategory,
                (v) => setState(() {
                  _selectedCategory = v;
                  _selectedSubCategory = null;
                }),
              ),
              if (_subCategoriesForSelected.isNotEmpty) ...[
                const SizedBox(height: 17),
                _label(c, t.issueType),
                const SizedBox(height: FigSpace.xs),
                _chips(c, _subCategoriesForSelected, _selectedSubCategory,
                    (v) => setState(() => _selectedSubCategory = v)),
              ],
              const SizedBox(height: 17),
              _label(c, t.descriptionLabel),
              const SizedBox(height: FigSpace.xs),
              _descriptionField(c, t),
              const SizedBox(height: 17),
              _label(c, t.priorityLabel),
              const SizedBox(height: FigSpace.xs),
              _priorityField(c, t),
              const SizedBox(height: 17),
              _attachBox(c, t),
              const SizedBox(height: FigSpace.xxl),
              GiPrimaryButton(
                label: t.submitReport,
                isLoading: _submitting,
                onPressed: _canSubmit ? _submit : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _canSubmit =>
      !_loading &&
      _selectedCategory != null &&
      _selectedSubCategory != null &&
      _descController.text.trim().isNotEmpty;

  Widget _label(GiColors c, String text) =>
      Text(text, style: FigText.fieldLabel.copyWith(color: c.textBody));

  /// Rappel du bien concerne. Absent du Figma, mais un resident peut posseder
  /// plusieurs biens : sans ce rappel il ne sait pas lequel il signale.
  Widget _propertyCard(GiColors c, AppL10n t) {
    return GiCard(
      child: Row(
        children: [
          GiIconChip(
            accent: FigBrand.amber,
            size: FigSize.chipSm,
            radius: FigRadius.pill,
            icon: SvgPicture.asset('assets/figma/icons/pin_location.svg',
                colorFilter:
                    const ColorFilter.mode(FigBrand.amber, BlendMode.srcIn)),
          ),
          const SizedBox(width: FigSpace.lg),
          Expanded(
            child: Text(_locationLabel(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: FigText.body.copyWith(color: c.textMuted)),
          ),
        ],
      ),
    );
  }

  /// Puces de selection — composant "Fillter" du Figma en version 6 de rayon :
  /// selectionnee en bleu a 5 % sur trait a 10 %, les autres en gris.
  Widget _chips(GiColors c, List<String> values, String? selected,
      ValueChanged<String> onPick) {
    return Wrap(
      spacing: FigSpace.md,
      runSpacing: FigSpace.md,
      children: [
        for (final v in values)
          GiPressable(
            pressedScale: 0.94,
            onTap: () => onPick(v),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: v == selected
                    ? FigAccent.chipFill(_chipBlue)
                    : c.card,
                border: Border.all(
                    color: v == selected
                        ? FigAccent.chipBorder(_chipBlue)
                        : c.cardBorder),
                borderRadius: BorderRadius.circular(FigRadius.pill),
              ),
              child: Text(
                v,
                style: FigText.fieldLabel.copyWith(
                    color: v == selected ? _chipBlue : c.fieldHint),
              ),
            ),
          ),
      ],
    );
  }

  Widget _descriptionField(GiColors c, AppL10n t) {
    return Container(
      height: 138 - 21,
      padding: const EdgeInsets.all(FigSpace.xl - 1.5),
      decoration: BoxDecoration(
        color: c.fieldBg,
        borderRadius: BorderRadius.circular(FigRadius.field),
        border: Border.all(color: c.fieldBorder, width: 1.5),
      ),
      child: TextFormField(
        controller: _descController,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        cursorColor: FigBrand.amber,
        style: FigText.field.copyWith(color: c.fieldText),
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: t.describeProblem,
          hintStyle: FigText.field.copyWith(color: c.fieldHint),
          filled: false,
          isDense: true,
          contentPadding: EdgeInsets.zero,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }

  /// Priorite : le Figma ouvre un panneau de quatre lignes sous le champ.
  /// Une feuille glissee du bas rend la meme liste utilisable au pouce.
  Widget _priorityField(GiColors c, AppL10n t) {
    return GiPressable(
      pressedScale: 0.99,
      onTap: () => _pickPriority(c, t),
      child: Container(
        padding: const EdgeInsets.all(FigSpace.xl - 1.5),
        decoration: BoxDecoration(
          color: c.fieldBg,
          borderRadius: BorderRadius.circular(FigRadius.field),
          border: Border.all(color: c.fieldBorder, width: 1.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(_priorityLabel(t, _priority),
                  style: FigText.field.copyWith(color: c.fieldText)),
            ),
            Icon(Icons.keyboard_arrow_down_rounded,
                size: 20, color: c.textMuted),
          ],
        ),
      ),
    );
  }

  String _priorityLabel(AppL10n t, String value) => switch (value) {
        'Basse' => t.priorityLow,
        'Haute' => t.priorityHigh,
        'Urgente' => t.priorityUrgent,
        _ => t.priorityMedium,
      };

  Future<void> _pickPriority(GiColors c, AppL10n t) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: c.scaffold,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(FigRadius.card)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(FigSpace.pagePadding, 0,
              FigSpace.pagePadding, FigSpace.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.priorityLabel,
                  style: FigText.titleMd.copyWith(color: c.textBody)),
              const SizedBox(height: FigSpace.xl),
              for (final value in const ['Basse', 'Moyenne', 'Haute', 'Urgente'])
                Padding(
                  padding: const EdgeInsets.only(bottom: FigSpace.md),
                  child: GiCard(
                    onTap: () {
                      setState(() => _priority = value);
                      Navigator.pop(sheetContext);
                    },
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(_priorityLabel(t, value),
                              style: FigText.statValue
                                  .copyWith(color: c.textBody)),
                        ),
                        if (_priority == value)
                          const Icon(Icons.check_rounded,
                              color: FigBrand.amber, size: 20),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Zone de piece jointe : fond ambre a 5 %, trait a 10 %, rayon 8.
  /// Une fois un fichier choisi, la zone affiche son nom et permet de le
  /// retirer — le Figma ne prevoit pas cet etat, mais sans lui on ne peut
  /// pas revenir sur une piece jointe par erreur.
  Widget _attachBox(GiColors c, AppL10n t) {
    final has = _attachment != null;
    return GiPressable(
      pressedScale: 0.98,
      onTap: has ? () => setState(() => _attachment = null) : _pickAttachment,
      child: Container(
        padding: const EdgeInsets.all(FigSpace.cardPadding),
        decoration: BoxDecoration(
          color: FigAccent.chipFill(FigBrand.amber),
          border: Border.all(color: FigAccent.chipBorder(FigBrand.amber)),
          borderRadius: BorderRadius.circular(FigRadius.field),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(has ? Icons.close_rounded : Icons.photo_camera_outlined,
                size: 18, color: has ? FigAlert.error : FigBrand.amber),
            const SizedBox(width: FigSpace.lg),
            Flexible(
              child: Text(
                has ? _attachment!.name : t.attachPhoto,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: FigText.field.copyWith(color: c.textBody),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bleu des puces selectionnees, propre a cet ecran dans le Figma.
const _chipBlue = Color(0xFF0088FF);
