// ignore_for_file: use_build_context_synchronously
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
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

  static const _accessLabels = {
    'FULL': 'Accès complet',
    'RESIDENT': 'Accès résident',
    'VISITOR': 'Accès visiteur',
    'CUSTOM': 'Accès personnalisé',
  };

  Color _accessColor(String level, bool dark) {
    switch (level) {
      case 'FULL':
        return const Color(0xFF16A34A);
      case 'VISITOR':
        return dark ? darkMuted : const Color(0xFF6B7280);
      default:
        return brandAmber;
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? Colors.white : brandNavy;
    final muted = dark ? darkMuted : const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: dark ? darkSurface : brandCream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  _iconBtn(Icons.arrow_back_rounded, dark, fg, () => Navigator.pop(context)),
                  const SizedBox(width: 12),
                  Text('Membres du foyer',
                      style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 18)),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          _memberTile(
                            fg: fg,
                            muted: muted,
                            dark: dark,
                            name: 'Vous',
                            relation: 'Résident principal',
                            accessLabel: 'Accès complet',
                            accessColor: const Color(0xFF16A34A),
                            photo: null,
                            trailing: null,
                          ),
                          if (_members.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 40),
                              child: Center(
                                child: Text('Aucun autre membre pour le moment.',
                                    style: TextStyle(color: muted, fontSize: 14)),
                              ),
                            ),
                          ..._members.whereType<Map>().map((m) {
                            final member = Map<String, dynamic>.from(m);
                            final level = (member['accessLevel'] ?? 'RESIDENT').toString();
                            return _memberTile(
                              fg: fg,
                              muted: muted,
                              dark: dark,
                              name: (member['fullName'] ?? '').toString(),
                              relation: (member['relation'] ?? '').toString(),
                              accessLabel: _accessLabels[level] ?? level,
                              accessColor: _accessColor(level, dark),
                              photo: (member['photo'] ?? '').toString(),
                              trailing: PopupMenuButton<String>(
                                icon: Icon(Icons.more_vert_rounded, color: muted),
                                onSelected: (v) {
                                  if (v == 'edit') _openForm(existing: member);
                                  if (v == 'remove') _remove(member);
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                      value: 'edit',
                                      child: Row(children: [
                                        Icon(Icons.edit_outlined, size: 18),
                                        SizedBox(width: 10),
                                        Text('Modifier'),
                                      ])),
                                  PopupMenuItem(
                                      value: 'remove',
                                      child: Row(children: [
                                        Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFDC2626)),
                                        SizedBox(width: 10),
                                        Text('Retirer', style: TextStyle(color: Color(0xFFDC2626))),
                                      ])),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _openForm(),
            child: const Text('Ajouter un membre'),
          ),
        ),
      ),
    );
  }

  Widget _memberTile({
    required Color fg,
    required Color muted,
    required bool dark,
    required String name,
    required String relation,
    required String accessLabel,
    required Color accessColor,
    required String? photo,
    required Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: dark ? darkCard : Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          _avatar(photo, name, dark),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 15)),
                if (relation.isNotEmpty)
                  Text(relation, style: TextStyle(color: muted, fontSize: 12)),
                const SizedBox(height: 2),
                Text(accessLabel,
                    style: TextStyle(color: accessColor, fontSize: 12, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _avatar(String? photo, String name, bool dark) {
    final initials = name.trim().isEmpty
        ? '?'
        : name.trim().split(RegExp(r'\s+')).map((p) => p[0]).take(2).join().toUpperCase();
    if (photo != null && photo.isNotEmpty) {
      return ClipOval(
        child: Image.network('${ApiService().baseUrl.replaceAll('/api', '')}$photo',
            width: 48, height: 48, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _initialsCircle(initials, dark)),
      );
    }
    return _initialsCircle(initials, dark);
  }

  Widget _initialsCircle(String initials, bool dark) => Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(shape: BoxShape.circle, color: brandAmber.withValues(alpha: 0.16)),
        alignment: Alignment.center,
        child: Text(initials, style: const TextStyle(color: brandAmber, fontWeight: FontWeight.w800)),
      );

  Widget _iconBtn(IconData icon, bool dark, Color fg, VoidCallback onTap) => Container(
        decoration: BoxDecoration(color: dark ? darkCard : Colors.white, borderRadius: BorderRadius.circular(12)),
        child: IconButton(icon: Icon(icon, color: fg), onPressed: onTap),
      );
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
