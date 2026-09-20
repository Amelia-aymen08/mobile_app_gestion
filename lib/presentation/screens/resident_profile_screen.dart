// ignore_for_file: use_build_context_synchronously
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/api_service.dart';
import '../l10n/l10n.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/language_picker.dart';
import '../widgets/user_avatar.dart';

class ResidentProfileScreen extends StatefulWidget {
  const ResidentProfileScreen({super.key});

  @override
  State<ResidentProfileScreen> createState() => _ResidentProfileScreenState();
}

class _ResidentProfileScreenState extends State<ResidentProfileScreen> {
  final ApiService _api = ApiService();
  final _currentController = TextEditingController();
  final _pwdController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _photoBusy = false;
  bool _obscureCurrent = true;
  bool _obscurePwd = true;
  bool _obscureConf = true;

  static const int _maxPhotoBytes = 5 * 1024 * 1024;

  @override
  void dispose() {
    _currentController.dispose();
    _pwdController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final auth = context.read<AuthProvider>();
      // Only update password if fields are filled
      if (_pwdController.text.isNotEmpty) {
        await auth.changePassword(_currentController.text, _pwdController.text);
      }
      _currentController.clear();
      _pwdController.clear();
      _confirmController.clear();
      _snack('Profil enregistré.'.tr);
    } catch (e) {
      _snack(e.toString().replaceAll('Exception: ', '').tr);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Profile picture (optional) ───────────────────────────
  Future<void> _pickPhoto() async {
    final result =
        await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    final file = result?.files.single;
    if (file == null || file.bytes == null) return;
    if (file.size > _maxPhotoBytes) {
      _snack('Photo trop grande (max 5 Mo).'.tr);
      return;
    }
    final ext = (file.extension ?? 'jpg').toLowerCase();
    final mime =
        ext == 'png' ? 'image/png' : (ext == 'webp' ? 'image/webp' : 'image/jpeg');

    setState(() => _photoBusy = true);
    try {
      final updated = await _api
          .updateProfilePhoto('data:$mime;base64,${base64Encode(file.bytes!)}');
      await context.read<AuthProvider>().setPhoto(updated['photo']?.toString());
      _snack('Photo de profil mise à jour.'.tr);
    } catch (e) {
      _snack(e.toString().replaceAll('Exception: ', '').tr);
    } finally {
      if (mounted) setState(() => _photoBusy = false);
    }
  }

  Future<void> _removePhoto() async {
    setState(() => _photoBusy = true);
    try {
      await _api.removeProfilePhoto();
      await context.read<AuthProvider>().setPhoto(null);
      _snack('Photo de profil supprimée.'.tr);
    } catch (e) {
      _snack(e.toString().replaceAll('Exception: ', '').tr);
    } finally {
      if (mounted) setState(() => _photoBusy = false);
    }
  }

  void _photoMenu(bool hasPhoto) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        decoration: BoxDecoration(
          color: dark ? darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: brandAmber),
              title: Text(hasPhoto ? 'Changer la photo'.tr : 'Choisir une photo'.tr,
                  style: TextStyle(
                      color: dark ? Colors.white : brandNavy,
                      fontWeight: FontWeight.w700)),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhoto();
              },
            ),
            if (hasPhoto)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded,
                    color: Color(0xFFDC2626)),
                title: Text('Supprimer la photo'.tr,
                    style: const TextStyle(
                        color: Color(0xFFDC2626), fontWeight: FontWeight.w700)),
                onTap: () {
                  Navigator.pop(ctx);
                  _removePhoto();
                },
              ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final name = (user?['name'] ?? '').toString();
    final email = (user?['email'] ?? '').toString();
    final phone = (user?['phone'] ?? '').toString();
    final photo = (user?['photo'] ?? '').toString();
    final lang = context.watch<LocaleProvider>().lang;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
        ),
        title: Text('Profil'.tr,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: Container(
        decoration: appBg(),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // ── Avatar ────────────────────────────────
                  Center(
                    child: GestureDetector(
                      onTap: _photoBusy ? null : () => _photoMenu(photo.isNotEmpty),
                      child: Stack(
                        children: [
                          UserAvatar(
                              photo: photo,
                              name: name,
                              size: 96,
                              ringColor: Colors.white),
                          if (_photoBusy)
                            const Positioned.fill(
                              child: Center(
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2.5)),
                            ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: const BoxDecoration(
                                color: brandNavy,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: const Icon(Icons.camera_alt_rounded,
                                  size: 15, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('La photo de profil est facultative.'.tr,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12)),
                  const SizedBox(height: 24),

                  // ── White profile card ─────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.10),
                            blurRadius: 16,
                            offset: const Offset(0, 4))
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Profil'.tr,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: brandNavy)),
                        const SizedBox(height: 16),

                        // Email (read-only display)
                        TextFormField(
                          initialValue: email,
                          readOnly: true,
                          decoration: InputDecoration(hintText: 'E-mail'.tr),
                          style: const TextStyle(color: brandNavy),
                        ),
                        const SizedBox(height: 12),

                        // Phone (read-only display)
                        if (phone.isNotEmpty) ...[
                          TextFormField(
                            initialValue: phone,
                            readOnly: true,
                            decoration: InputDecoration(
                                hintText: 'Numéro de téléphone'.tr),
                            style: const TextStyle(color: brandNavy),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Current password (needed to set a new one)
                        TextFormField(
                          controller: _currentController,
                          obscureText: _obscureCurrent,
                          decoration: InputDecoration(
                            hintText: 'Mot de passe actuel'.tr,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureCurrent
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: const Color(0xFFADB5BD),
                              ),
                              onPressed: () => setState(
                                  () => _obscureCurrent = !_obscureCurrent),
                            ),
                          ),
                          validator: (v) {
                            if (_pwdController.text.isNotEmpty &&
                                (v == null || v.isEmpty)) {
                              return 'Saisissez votre mot de passe actuel'.tr;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // New password
                        TextFormField(
                          controller: _pwdController,
                          obscureText: _obscurePwd,
                          decoration: InputDecoration(
                            hintText: 'Nouveau mot de passe'.tr,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePwd
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: const Color(0xFFADB5BD),
                              ),
                              onPressed: () =>
                                  setState(() => _obscurePwd = !_obscurePwd),
                            ),
                          ),
                          validator: (v) {
                            if (v != null && v.isNotEmpty && v.length < 6) {
                              return '6 caractères minimum'.tr;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // Confirm password
                        TextFormField(
                          controller: _confirmController,
                          obscureText: _obscureConf,
                          decoration: InputDecoration(
                            hintText: 'Confirmer le mot de passe'.tr,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConf
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: const Color(0xFFADB5BD),
                              ),
                              onPressed: () =>
                                  setState(() => _obscureConf = !_obscureConf),
                            ),
                          ),
                          validator: (v) {
                            if (_pwdController.text.isNotEmpty &&
                                v != _pwdController.text) {
                              return 'Les mots de passe ne correspondent pas'.tr;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Language
                        InkWell(
                          onTap: () => showLanguagePicker(context),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Text('Langue'.tr,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: brandNavy,
                                        fontSize: 14)),
                                const Spacer(),
                                Text(lang.nativeName,
                                    style: const TextStyle(
                                        color: brandAmber,
                                        fontWeight: FontWeight.w700)),
                                const Icon(Icons.chevron_right_rounded,
                                    color: Color(0xFFADB5BD)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Dark mode toggle
                        Consumer<ThemeProvider>(
                          builder: (_, theme, __) => Row(
                            children: [
                              Text('Activer le thème sombre'.tr,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: brandNavy,
                                      fontSize: 14)),
                              const Spacer(),
                              Switch(value: theme.isDark, onChanged: theme.setDark),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Save button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _save,
                            child: _loading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : Text('Enregistrer'.tr),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
