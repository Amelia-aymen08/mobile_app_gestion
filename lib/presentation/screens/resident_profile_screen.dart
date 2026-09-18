// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';

class ResidentProfileScreen extends StatefulWidget {
  const ResidentProfileScreen({super.key});

  @override
  State<ResidentProfileScreen> createState() => _ResidentProfileScreenState();
}

class _ResidentProfileScreenState extends State<ResidentProfileScreen> {
  final _pwdController     = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey           = GlobalKey<FormState>();
  bool _loading   = false;
  bool _obscurePwd    = true;
  bool _obscureConf   = true;

  @override
  void dispose() {
    _pwdController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final auth = context.read<AuthProvider>();
      // Only update password if fields are filled
      if (_pwdController.text.isNotEmpty) {
        await auth.changePassword('', _pwdController.text);
      }
      _pwdController.clear();
      _confirmController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil enregistré.')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final name  = (user?['name'] ?? '').toString();
    final email = (user?['email'] ?? '').toString();
    final phone = (user?['phone'] ?? '').toString();

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
        title: const Text('Profil',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
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
                    child: Stack(
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.25),
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.person_rounded,
                              size: 46, color: Colors.white),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              color: brandNavy,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Icon(Icons.edit_rounded,
                                size: 14, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800)),
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
                        const Text('Profil',
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: brandNavy)),
                        const SizedBox(height: 16),

                        // Email (read-only display)
                        TextFormField(
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                          initialValue: email,
                          readOnly: true,
                          decoration: const InputDecoration(hintText: 'E-mail'),
                          style: const TextStyle(color: brandNavy),
                        ),
                        const SizedBox(height: 12),

                        // Phone (read-only display)
                        TextFormField(
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                          initialValue: phone.isNotEmpty ? phone : null,
                          readOnly: true,
                          decoration: const InputDecoration(
                              hintText: 'Numéro de téléphone'),
                          style: const TextStyle(color: brandNavy),
                        ),
                        const SizedBox(height: 12),

                        // New password
                        TextFormField(
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                          controller: _pwdController,
                          obscureText: _obscurePwd,
                          decoration: InputDecoration(
                            hintText: 'Mot de passe',
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
                              return '6 caractères minimum';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // Confirm password
                        TextFormField(
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                          controller: _confirmController,
                          obscureText: _obscureConf,
                          decoration: InputDecoration(
                            hintText: 'Confirmer le mot de passe',
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
                              return 'Les mots de passe ne correspondent pas';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Dark mode toggle
                        Consumer<ThemeProvider>(
                          builder: (_, theme, __) => Row(
                            children: [
                              const Text('Activer le thème sombre',
                                  style: TextStyle(
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
                                : const Text('Enregistrer'),
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
