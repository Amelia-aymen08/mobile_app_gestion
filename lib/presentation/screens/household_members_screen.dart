// ignore_for_file: use_build_context_synchronously
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../l10n/app_localizations.dart';
import '../theme/design_tokens.dart';
import '../theme/gi_colors.dart';
import '../widgets/gi_card.dart';
import '../widgets/gi_pressable.dart';
import '../widgets/gi_primary_button.dart';
import '../theme/app_theme.dart';
import '../../data/api_service.dart';

class HouseholdMembersScreen extends StatefulWidget {
  const HouseholdMembersScreen({super.key});

  @override
  State<HouseholdMembersScreen> createState() => _HouseholdMembersScreenState();
}

class _HouseholdMembersScreenState extends State<HouseholdMembersScreen> {
  final ApiService _api = ApiService();
  bool _loading = true;
  List<dynamic> _members = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _api.getHouseholdMembers();
      if (mounted) setState(() => _members = list);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }



  Future<void> _openForm({Map<String, dynamic>? existing}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MemberFormSheet(existing: existing),
    );
    if (saved == true) _load();
  }

  Future<void> _remove(Map<String, dynamic> member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Retirer ce membre ?'),
        content: Text('${member['fullName']} ne sera plus listé dans votre foyer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Retirer', style: TextStyle(color: Color(0xFFDC2626)))),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _api.removeHouseholdMember(member['id'].toString());
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    final t = AppL10n.of(context);

    return Scaffold(
      backgroundColor: c.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            // En-tete du Figma : pastille de retour de 32, ecart 16, titre 18.
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
                  const SizedBox(width: FigSpace.xl),
                  Text(t.householdMembers,
                      style: FigText.titleMd
                          .copyWith(fontSize: 18, color: c.textBody)),
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
                        padding: const EdgeInsets.fromLTRB(
                            FigSpace.pagePadding, 0, FigSpace.pagePadding, 120),
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          // Le titulaire du bien, toujours en tete et sans
                          // menu : il ne peut ni etre modifie ni retire.
                          _memberCard(
                            c,
                            name: t.you,
                            relation: t.primaryResident,
                            accessLabel: t.fullAccess,
                            accessColor: FigAlert.success,
                            photo: null,
                            member: null,
                          ),
                          // Figma : les cartes sont espacees de 4, pas de 12.
                          for (final m in _members.whereType<Map>()) ...[
                            const SizedBox(height: FigSpace.xs),
                            _memberCard(
                              c,
                              name: (m['fullName'] ?? '').toString(),
                              relation: (m['relation'] ?? '').toString(),
                              accessLabel: _accessLabel(
                                  t, (m['accessLevel'] ?? 'RESIDENT').toString()),
                              accessColor: FigBrand.amber,
                              photo: (m['photo'] ?? '').toString(),
                              member: Map<String, dynamic>.from(m),
                            ),
                          ],
                        ],
                      ),
                    ),
            ),
            // Le Figma pose le bouton a 52 du bas, hors de la liste.
            Padding(
              padding: const EdgeInsets.fromLTRB(FigSpace.pagePadding, 0,
                  FigSpace.pagePadding, FigSpace.xxl),
              child: GiPrimaryButton(
                label: t.addMember,
                onPressed: () => _openForm(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _accessLabel(AppL10n t, String level) => switch (level.toUpperCase()) {
        'FULL' => t.fullAccess,
        'VISITOR' || 'VISITEUR' => t.visitorAccess,
        'CUSTOM' || 'PERSONNALISE' => t.customAccess,
        _ => t.residentAccess,
      };

  /// Carte de membre — Figma 0:4180 : avatar rond de 36, ecart 12, trois
  /// lignes de texte espacees de 4, et le menu a trois points de 20.
  Widget _memberCard(
    GiColors c, {
    required String name,
    required String relation,
    required String accessLabel,
    required Color accessColor,
    required String? photo,
    required Map<String, dynamic>? member,
  }) {
    return GiCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _avatar(c, photo, name),
          const SizedBox(width: FigSpace.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(name.isEmpty ? '—' : name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FigText.statValue
                        .copyWith(height: 1.2, color: c.textBody)),
                if (relation.isNotEmpty) ...[
                  const SizedBox(height: FigSpace.xs),
                  Text(relation,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: FigText.body.copyWith(color: c.textMuted)),
                ],
                const SizedBox(height: FigSpace.xs),
                Text(accessLabel,
                    style: FigText.body.copyWith(
                        fontWeight: FontWeight.w500, color: accessColor)),
              ],
            ),
          ),
          if (member != null) ...[
            const SizedBox(width: FigSpace.md),
            GiPressable(
              pressedScale: 0.82,
              ensureMinTapTarget: true,
              onTap: () => _openMemberMenu(c, member),
              child: SvgPicture.asset(
                'assets/figma/icons/dots_20.svg',
                colorFilter: ColorFilter.mode(c.textMuted, BlendMode.srcIn),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Avatar rond de 36. Sans photo servie par l'API, on retombe sur les
  /// initiales plutot que sur une silhouette generique : elles distinguent
  /// au moins les membres entre eux.
  Widget _avatar(GiColors c, String? photo, String name) {
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .take(2)
        .map((e) => e[0].toUpperCase())
        .join();

    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: FigAccent.chipFill(FigBrand.amber),
        border: Border.all(color: FigAccent.chipBorder(FigBrand.amber)),
      ),
      clipBehavior: Clip.antiAlias,
      child: photo != null && photo.startsWith('http')
          ? Image.network(photo,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _initials(initials))
          : _initials(initials),
    );
  }

  Widget _initials(String initials) => Text(
        initials.isEmpty ? '?' : initials,
        style: FigText.body.copyWith(
            fontWeight: FontWeight.w600, color: FigBrand.amber),
      );

  /// Menu du Figma : « Modifier » puis « Retirer » en rouge.
  Future<void> _openMemberMenu(GiColors c, Map<String, dynamic> member) async {
    final t = AppL10n.of(context);
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
            children: [
              GiCard(
                onTap: () {
                  Navigator.pop(sheetContext);
                  _openForm(existing: member);
                },
                child: Row(
                  children: [
                    SvgPicture.asset('assets/figma/icons/edit_13.svg',
                        colorFilter:
                            ColorFilter.mode(c.textBody, BlendMode.srcIn)),
                    const SizedBox(width: FigSpace.lg),
                    Text(t.edit,
                        style: FigText.field.copyWith(color: c.textBody)),
                  ],
                ),
              ),
              const SizedBox(height: FigSpace.md),
              GiCard(
                onTap: () {
                  Navigator.pop(sheetContext);
                  _remove(member);
                },
                child: Row(
                  children: [
                    SvgPicture.asset('assets/figma/icons/trash_15.svg',
                        colorFilter: const ColorFilter.mode(
                            FigAlert.error, BlendMode.srcIn)),
                    const SizedBox(width: FigSpace.lg),
                    Text(t.remove,
                        style:
                            FigText.field.copyWith(color: FigAlert.error)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// ─── Add / Edit sheet ───────────────────────────────────────────────────────
class _MemberFormSheet extends StatefulWidget {
  final Map<String, dynamic>? existing;
  const _MemberFormSheet({this.existing});

  @override
  State<_MemberFormSheet> createState() => _MemberFormSheetState();
}

class _MemberFormSheetState extends State<_MemberFormSheet> {
  final ApiService _api = ApiService();
  final _nameCtrl = TextEditingController();
  final _relationCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _accessLevel = 'RESIDENT';
  String? _photoDataUrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameCtrl.text = (e['fullName'] ?? '').toString();
      _relationCtrl.text = (e['relation'] ?? '').toString();
      _phoneCtrl.text = (e['phone'] ?? '').toString();
      _accessLevel = (e['accessLevel'] ?? 'RESIDENT').toString();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _relationCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    final file = result?.files.single;
    if (file?.bytes == null) return;
    final ext = (file!.extension ?? 'jpg').toLowerCase();
    final mime = ext == 'png' ? 'image/png' : (ext == 'webp' ? 'image/webp' : 'image/jpeg');
    setState(() => _photoDataUrl = 'data:$mime;base64,${base64Encode(file.bytes!)}');
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Le nom est requis.')));
      return;
    }
    setState(() => _saving = true);
    try {
      final id = widget.existing?['id']?.toString();
      if (id != null) {
        await _api.updateHouseholdMember(id,
            fullName: name,
            relation: _relationCtrl.text.trim(),
            accessLevel: _accessLevel,
            phone: _phoneCtrl.text.trim(),
            photoDataUrl: _photoDataUrl);
      } else {
        await _api.addHouseholdMember(
            fullName: name,
            relation: _relationCtrl.text.trim(),
            accessLevel: _accessLevel,
            phone: _phoneCtrl.text.trim(),
            photoDataUrl: _photoDataUrl);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  static const _levels = ['FULL', 'RESIDENT', 'VISITOR', 'CUSTOM'];
  static const _labels = {
    'FULL': 'Accès complet',
    'RESIDENT': 'Accès résident',
    'VISITOR': 'Accès visiteur',
    'CUSTOM': 'Accès personnalisé',
  };

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? Colors.white : brandNavy;
    final isEdit = widget.existing != null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        decoration: BoxDecoration(
          color: dark ? darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: dark ? darkBorder : const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(height: 18),
              Text(isEdit ? 'Modifier le membre' : 'Ajouter un membre',
                  style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 18)),
              const SizedBox(height: 18),
              Center(
                child: GestureDetector(
                  onTap: _pickPhoto,
                  child: Stack(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: brandAmber.withValues(alpha: 0.14)),
                        alignment: Alignment.center,
                        child: const Icon(Icons.person_rounded, size: 36, color: brandAmber),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(color: brandNavy, shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: const Icon(Icons.camera_alt_rounded, size: 12, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              TextField(
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => FocusScope.of(context).nextFocus(),controller: _nameCtrl, decoration: const InputDecoration(hintText: 'Nom complet')),
              const SizedBox(height: 12),
              TextField(
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => FocusScope.of(context).nextFocus(),controller: _relationCtrl, decoration: const InputDecoration(hintText: 'Relation (ex: Épouse, Fils...)')),
              const SizedBox(height: 12),
              TextField(
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => FocusScope.of(context).nextFocus(),controller: _phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(hintText: 'Téléphone (optionnel)')),
              const SizedBox(height: 16),
              Text("Niveau d'accès", style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _levels.map((level) {
                  final active = _accessLevel == level;
                  return GestureDetector(
                    onTap: () => setState(() => _accessLevel = level),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: active ? brandAmber : (dark ? darkCard : const Color(0xFFF3F0E8)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(_labels[level]!,
                          style: TextStyle(
                              color: active ? brandNavy : (dark ? Colors.white70 : const Color(0xFF6B7280)),
                              fontWeight: FontWeight.w700,
                              fontSize: 12)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(isEdit ? 'Enregistrer' : 'Ajouter'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
