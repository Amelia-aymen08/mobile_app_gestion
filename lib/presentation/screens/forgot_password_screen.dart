import 'package:flutter/material.dart';
import '../../data/api_service.dart';
import '../theme/app_theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _api = ApiService();
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _api.forgotPassword(_emailController.text.trim());
      if (!mounted) return;
      setState(() {
        _sent = true;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? Colors.white : brandNavy;
    final muted = dark ? darkMuted : const Color(0xFF6B7280);
    final fieldFill = dark ? darkCard : const Color(0xFFECE7DA);

    return Scaffold(
      backgroundColor: dark ? darkSurface : brandCream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              const SizedBox(height: 20),

              if (_sent) ...[
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                      color: const Color(0xFF16A34A).withValues(alpha: 0.14), shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: const Icon(Icons.mark_email_read_outlined, color: Color(0xFF16A34A), size: 36),
                ),
                const SizedBox(height: 20),
                Text('E-mail envoyé', style: TextStyle(color: fg, fontSize: 24, fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),
                Text(
                  "Si un compte existe avec l'adresse ${_emailController.text.trim()}, un lien de réinitialisation vient d'être envoyé. Vérifiez votre boîte de réception (et vos spams).",
                  style: TextStyle(color: muted, fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandAmber,
                    foregroundColor: brandNavy,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    minimumSize: const Size.fromHeight(54),
                    elevation: 0,
                  ),
                  child: const Text('Retour à la connexion',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ] else ...[
                Text('Mot de passe oublié',
                    style: TextStyle(color: fg, fontSize: 26, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text(
                  'Entrez votre adresse e-mail, nous vous enverrons un lien pour réinitialiser votre mot de passe.',
                  style: TextStyle(color: muted, fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 28),
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Adresse e-mail',
                          style: TextStyle(color: fg, fontSize: 13, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.email],
                        style: TextStyle(color: fg),
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          hintText: 'exemple@email.com',
                          hintStyle: TextStyle(color: muted.withValues(alpha: 0.6)),
                          errorText: _error,
                          filled: true,
                          fillColor: fieldFill,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        ),
                        validator: (v) =>
                            (v?.trim().isEmpty ?? true) ? 'Adresse e-mail requise' : null,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loading ? null : _submit,
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
                            : const Text('Envoyer le lien',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
