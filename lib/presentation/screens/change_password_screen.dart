// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'resident_home_screen.dart';
import 'manager_home_screen.dart';
import 'intervenant_home_screen.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _goHome(AuthProvider auth) {
    final role = auth.userRole;
    if (role == 'INTERVENANT') {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const IntervenantHomeScreen()));
    } else if (role == 'ADMIN' || role == 'RESPONSABLE_ZONE' || role == 'MANAGER') {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ManagerHomeScreen()));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ResidentHomeScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? Colors.white : brandNavy;
    final muted = dark ? darkMuted : const Color(0xFF6B7280);
    final fieldFill = dark ? darkCard : const Color(0xFFECE7DA);
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: dark ? darkSurface : brandCream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (canPop) ...[
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                            color: dark ? darkCard : Colors.white, borderRadius: BorderRadius.circular(12)),
                        child: IconButton(
                          icon: Icon(Icons.arrow_back_rounded, color: fg),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ] else
                  const SizedBox(height: 8),
                Text('Changer le mot de passe',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: fg)),
                const SizedBox(height: 8),
                Text(
                  'Créez un nouveau mot de passe pour sécuriser votre compte.',
                  style: TextStyle(color: muted, fontSize: 14),
                ),
                const SizedBox(height: 28),

                _label('Mot de passe actuel', fg),
                const SizedBox(height: 8),
                _field(
                  controller: _currentController,
                  obscure: _obscureCurrent,
                  onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
                  fg: fg,
                  muted: muted,
                  fill: fieldFill,
                  validator: (v) => (v == null || v.isEmpty) ? 'Champ obligatoire' : null,
                ),
                const SizedBox(height: 16),

                _label('Nouveau mot de passe', fg),
                const SizedBox(height: 8),
                _field(
                  controller: _newController,
                  obscure: _obscureNew,
                  onToggle: () => setState(() => _obscureNew = !_obscureNew),
                  fg: fg,
                  muted: muted,
                  fill: fieldFill,
                  validator: (v) => (v == null || v.length < 6) ? '6 caractères minimum' : null,
                ),
                const SizedBox(height: 16),

                _label('Confirmer le nouveau mot de passe', fg),
                const SizedBox(height: 8),
                _field(
                  controller: _confirmController,
                  obscure: _obscureConfirm,
                  onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  fg: fg,
                  muted: muted,
                  fill: fieldFill,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Champ obligatoire';
                    if (v != _newController.text) return 'Les mots de passe ne correspondent pas';
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: _loading
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;
                          setState(() => _loading = true);
                          try {
                            await auth.changePassword(_currentController.text, _newController.text);
                            _goHome(auth);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
                            );
                          } finally {
                            if (mounted) setState(() => _loading = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandAmber,
                    foregroundColor: brandNavy,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    minimumSize: const Size.fromHeight(54),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: brandNavy, strokeWidth: 2))
                      : const Text('Changer le mot de passe',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text, Color fg) =>
      Text(text, style: TextStyle(color: fg, fontSize: 13, fontWeight: FontWeight.w700));

  Widget _field({
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
    required Color fg,
    required Color muted,
    required Color fill,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
      controller: controller,
      obscureText: obscure,
      style: TextStyle(color: fg),
      decoration: InputDecoration(
        filled: true,
        fillColor: fill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: muted),
          onPressed: onToggle,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
      validator: validator,
    );
  }
}
