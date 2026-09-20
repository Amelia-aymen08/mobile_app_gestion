// ignore_for_file: use_build_context_synchronously
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/l10n.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/user_avatar.dart';
import '../../data/api_service.dart';

/// A household can hold at most this many additional members (backend rule too).
const int kMaxHouseholdMembers = 4;

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
      _toast(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toast(Object e) {
    if (!mounted) return;
    final msg = e.toString().replaceFirst('Exception: ', '');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg.tr)));
  }

  bool get _isFull => _members.length >= kMaxHouseholdMembers;

  Future<void> _openForm({Map<String, dynamic>? existing}) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MemberFormSheet(existing: existing),
    );
    if (result == null) return;
    await _load();
    // The account was created but the invitation mail couldn't go out.
    if (result['emailSent'] == false && mounted) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text("E-mail non envoyé".tr),
          content: Text(
              "Le compte a été créé mais l'e-mail d'accès n'a pas pu être envoyé. Utilisez « Renvoyer les accès » depuis le menu du membre."
                  .tr),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: Text('OK'.tr)),
          ],
        ),
      );
    }
  }

  Future<void> _resend(Map<String, dynamic> member) async {
    try {
      final sent = await _api.resendMemberAccess(member['id'].toString());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text((sent
                  ? "Les accès ont été renvoyés par e-mail."
                  : "L'e-mail n'a pas pu être envoyé.")
              .tr)));
    } catch (e) {
      _toast(e);
    }
  }

  Future<void> _remove(Map<String, dynamic> member) async {
    final hasAccount = member['linkedUserId'] != null;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Retirer ce membre ?'.tr),
        content: Text((hasAccount
                ? '{name} ne pourra plus se connecter à l\'application : son compte sera supprimé.'
                : '{name} ne sera plus listé dans votre foyer.')
            .trp({'name': member['fullName']})),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Annuler'.tr)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Retirer'.tr,
                  style: const TextStyle(color: Color(0xFFDC2626)))),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _api.removeHouseholdMember(member['id'].toString());
      _load();
    } catch (e) {
      _toast(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? Colors.white : brandNavy;
    final muted = dark ? darkMuted : const Color(0xFF6B7280);
    final me = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: dark ? darkSurface : brandCream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  _iconBtn(Icons.arrow_back_rounded, dark, fg,
                      () => Navigator.pop(context)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Membres du foyer'.tr,
                            style: TextStyle(
                                color: fg,
                                fontWeight: FontWeight.w800,
                                fontSize: 18)),
                        Text(
                            '{count} sur {max} membres'.trp({
                              'count': _members.length,
                              'max': kMaxHouseholdMembers
                            }),
                            style: TextStyle(color: muted, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: brandAmber.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: brandAmber.withValues(alpha: 0.35)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.mail_outline_rounded,
                                    color: brandAmber, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                      "Chaque membre reçoit ses accès de connexion par e-mail. Vous pouvez ajouter jusqu'à {max} personnes."
                                          .trp({'max': kMaxHouseholdMembers}),
                                      style: TextStyle(
                                          color: fg, fontSize: 12.5, height: 1.4)),
                                ),
                              ],
                            ),
                          ),
                          _memberTile(
                            fg: fg,
                            muted: muted,
                            dark: dark,
                            name: ((me?['name'] ?? '').toString().isEmpty
                                ? 'Vous'.tr
                                : '{name} ({you})'.trp({
                                    'name': me?['name'],
                                    'you': 'Vous'.tr,
                                  })),
                            relation: 'Résident principal'.tr,
                            email: (me?['email'] ?? '').toString(),
                            photo: (me?['photo'] ?? '').toString(),
                            statusChip: null,
                            trailing: null,
                          ),
                          if (_members.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 40),
                              child: Center(
                                child: Text('Aucun autre membre pour le moment.'.tr,
                                    style: TextStyle(color: muted, fontSize: 14)),
                              ),
                            ),
                          ..._members.whereType<Map>().map((m) {
                            final member = Map<String, dynamic>.from(m);
                            final hasAccount = member['linkedUserId'] != null;
                            final active = member['accountActive'];
                            return _memberTile(
                              fg: fg,
                              muted: muted,
                              dark: dark,
                              name: (member['fullName'] ?? '').toString(),
                              relation: (member['relation'] ?? '').toString(),
                              email: (member['email'] ?? '').toString(),
                              photo: (member['photo'] ?? '').toString(),
                              statusChip: !hasAccount
                                  ? _StatusChip('Sans compte'.tr, muted)
                                  : (active == false
                                      ? _StatusChip('Compte désactivé'.tr,
                                          const Color(0xFFDC2626))
                                      : _StatusChip('Compte actif'.tr,
                                          const Color(0xFF16A34A))),
                              trailing: PopupMenuButton<String>(
                                icon: Icon(Icons.more_vert_rounded, color: muted),
                                onSelected: (v) {
                                  if (v == 'edit') _openForm(existing: member);
                                  if (v == 'resend') _resend(member);
                                  if (v == 'remove') _remove(member);
                                },
                                itemBuilder: (_) => [
                                  PopupMenuItem(
                                      value: 'edit',
                                      child: Row(children: [
                                        const Icon(Icons.edit_outlined, size: 18),
                                        const SizedBox(width: 10),
                                        Text('Modifier'.tr),
                                      ])),
                                  if (hasAccount && active != false)
                                    PopupMenuItem(
                                        value: 'resend',
                                        child: Row(children: [
                                          const Icon(Icons.forward_to_inbox_outlined,
                                              size: 18),
                                          const SizedBox(width: 10),
                                          Text('Renvoyer les accès'.tr),
                                        ])),
                                  PopupMenuItem(
                                      value: 'remove',
                                      child: Row(children: [
                                        const Icon(Icons.delete_outline_rounded,
                                            size: 18, color: Color(0xFFDC2626)),
                                        const SizedBox(width: 10),
                                        Text('Retirer'.tr,
                                            style: const TextStyle(
                                                color: Color(0xFFDC2626))),
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
            onPressed: (_loading || _isFull) ? null : () => _openForm(),
            child: Text(_isFull
                ? 'Maximum de {max} membres atteint'.trp({'max': kMaxHouseholdMembers})
                : 'Ajouter un membre'.tr),
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
    required String email,
    required String? photo,
    required _StatusChip? statusChip,
    required Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: dark ? darkCard : Colors.white,
          borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          UserAvatar(photo: photo, name: name, size: 48),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                        color: fg, fontWeight: FontWeight.w800, fontSize: 15)),
                if (relation.isNotEmpty)
                  Text(relation, style: TextStyle(color: muted, fontSize: 12)),
                if (email.isNotEmpty)
                  Text(email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: muted, fontSize: 12)),
                const SizedBox(height: 4),
                if (statusChip != null)
                  Text(statusChip.label,
                      style: TextStyle(
                          color: statusChip.color,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, bool dark, Color fg, VoidCallback onTap) =>
      Container(
        decoration: BoxDecoration(
            color: dark ? darkCard : Colors.white,
            borderRadius: BorderRadius.circular(12)),
        child: IconButton(icon: Icon(icon, color: fg), onPressed: onTap),
      );
}

class _StatusChip {
  final String label;
  final Color color;
  const _StatusChip(this.label, this.color);
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
  final _emailCtrl = TextEditingController();
  final _relationCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String? _photoDataUrl;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  /// Once a member has a login account its e-mail can't change.
  bool get _emailLocked => widget.existing?['linkedUserId'] != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameCtrl.text = (e['fullName'] ?? '').toString();
      _emailCtrl.text = (e['email'] ?? '').toString();
      _relationCtrl.text = (e['relation'] ?? '').toString();
      _phoneCtrl.text = (e['phone'] ?? '').toString();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _relationCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final result =
        await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    final file = result?.files.single;
    if (file?.bytes == null) return;
    if (file!.size > 5 * 1024 * 1024) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Photo trop grande (max 5 Mo).'.tr)));
      return;
    }
    final ext = (file.extension ?? 'jpg').toLowerCase();
    final mime =
        ext == 'png' ? 'image/png' : (ext == 'webp' ? 'image/webp' : 'image/jpeg');
    setState(() => _photoDataUrl = 'data:$mime;base64,${base64Encode(file.bytes!)}');
  }

  bool _validEmail(String v) => RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v);

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim().toLowerCase();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Le nom est requis.'.tr)));
      return;
    }
    // New members need an e-mail (their login); so do legacy members being given one.
    final needsEmail = !_isEdit || !_emailLocked;
    if (needsEmail && !_validEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saisissez une adresse e-mail valide.'.tr)));
      return;
    }
    setState(() => _saving = true);
    try {
      final id = widget.existing?['id']?.toString();
      Map<String, dynamic> saved;
      if (id != null) {
        saved = await _api.updateHouseholdMember(id,
            fullName: name,
            email: _emailLocked ? null : email,
            relation: _relationCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
            photoDataUrl: _photoDataUrl);
      } else {
        saved = await _api.addHouseholdMember(
            fullName: name,
            email: email,
            relation: _relationCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
            photoDataUrl: _photoDataUrl);
      }
      if (mounted) Navigator.pop(context, saved);
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg.tr)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? Colors.white : brandNavy;
    final muted = dark ? darkMuted : const Color(0xFF6B7280);

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
                  decoration: BoxDecoration(
                      color: dark ? darkBorder : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(height: 18),
              Text(_isEdit ? 'Modifier le membre'.tr : 'Ajouter un membre'.tr,
                  style: TextStyle(
                      color: fg, fontWeight: FontWeight.w800, fontSize: 18)),
              const SizedBox(height: 18),
              Center(
                child: GestureDetector(
                  onTap: _pickPhoto,
                  child: Stack(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: brandAmber.withValues(alpha: 0.14)),
                        alignment: Alignment.center,
                        child: _photoDataUrl != null
                            ? ClipOval(
                                child: Image.memory(
                                    base64Decode(_photoDataUrl!.split(',').last),
                                    width: 72,
                                    height: 72,
                                    fit: BoxFit.cover))
                            : const Icon(Icons.person_rounded,
                                size: 36, color: brandAmber),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                              color: brandNavy, shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: const Icon(Icons.camera_alt_rounded,
                              size: 12, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(hintText: 'Nom complet'.tr)),
              const SizedBox(height: 12),
              TextField(
                controller: _emailCtrl,
                enabled: !_emailLocked,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: InputDecoration(hintText: 'Adresse e-mail (identifiant de connexion)'.tr),
              ),
              if (!_emailLocked)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4, right: 4),
                  child: Text(
                      "Un e-mail contenant les accès (mot de passe temporaire) sera envoyé à cette adresse."
                          .tr,
                      style: TextStyle(color: muted, fontSize: 11.5)),
                ),
              const SizedBox(height: 12),
              TextField(
                  controller: _relationCtrl,
                  decoration: InputDecoration(hintText: 'Relation (ex: Épouse, Fils...)'.tr)),
              const SizedBox(height: 12),
              TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(hintText: 'Téléphone (optionnel)'.tr)),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(_isEdit ? 'Enregistrer'.tr : 'Ajouter'.tr),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
