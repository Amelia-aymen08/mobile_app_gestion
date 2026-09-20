// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/l10n.dart';
import '../providers/auth_provider.dart';
import '../widgets/language_picker.dart';
import '../theme/app_theme.dart';
import 'change_password_screen.dart';
import 'gestionnaire_tag_home_screen.dart';
import 'intervenant_home_screen.dart';
import 'manager_home_screen.dart';
import 'recouvrement_home_screen.dart';
import 'resident_home_screen.dart';
import 'registration_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _obscure = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // e.g. "account deactivated" after the administration cut this account off.
    _error = context.read<AuthProvider>().consumeNotice()?.tr;
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_form.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    try {
      await auth.login(_email.text, _password.text);
      if (!mounted) return;
      if (auth.mustChangePassword) return _go(const ChangePasswordScreen());
      final role = auth.userRole;
      if (role == 'INTERVENANT') return _go(const IntervenantHomeScreen());
      if (role == 'RECOUVREMENT') return _go(const RecouvrementHomeScreen());
      if (role == 'GESTIONNAIRE_TAG') {
        return _go(const GestionnaireTagHomeScreen());
      }
      if (['ADMIN', 'RESPONSABLE_ZONE', 'MANAGER', 'HSE'].contains(role)) {
        return _go(const ManagerHomeScreen());
      }
      _go(const ResidentHomeScreen());
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString().replaceAll('Exception: ', '').tr);
      }
    }
  }

  void _go(Widget screen) => Navigator.pushAndRemoveUntil(
      context, MaterialPageRoute(builder: (_) => screen), (_) => false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(children: [
        Positioned.fill(
          bottom: MediaQuery.sizeOf(context).height * .38,
          child: Stack(fit: StackFit.expand, children: [
            Image.asset('assets/onboarding-who-we-are.png', fit: BoxFit.cover),
            Container(color: Colors.black.withValues(alpha: .26)),
            SafeArea(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  Image.asset('assets/global_immo_logo_light.png', width: 118),
                  const SizedBox(height: 20),
                  Text('Bienvenue chez vous'.tr,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          height: 1.05,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Text('Accédez à votre résidence et à tous vos services.'.tr,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 11, height: 1.45)),
                ])),
            const SafeArea(
              child: Align(
                alignment: AlignmentDirectional.topEnd,
                child: Padding(
                  padding: EdgeInsets.all(14),
                  child: LanguageChip(),
                ),
              ),
            ),
          ]),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: MediaQuery.sizeOf(context).height * .55,
            decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(34))),
            child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                      26, 28, 26, 18 + MediaQuery.viewInsetsOf(context).bottom),
                  child: Form(
                      key: _form,
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Connexion'.tr,
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: brandNavy)),
                            const SizedBox(height: 6),
                            Text('Saisissez les identifiants associés à votre compte.'.tr,
                                style: const TextStyle(
                                    fontSize: 11, color: brandGoldDark)),
                            const SizedBox(height: 20),
                            _Label('ADRESSE E-MAIL'.tr),
                            TextFormField(
                                controller: _email,
                                keyboardType: TextInputType.emailAddress,
                                decoration: _decoration('nom@aymenpromotion.dz',
                                    error: _error),
                                validator: (value) =>
                                    value == null || value.trim().isEmpty
                                        ? 'Adresse requise'.tr
                                        : null),
                            const SizedBox(height: 14),
                            _Label('MOT DE PASSE'.tr),
                            TextFormField(
                                controller: _password,
                                obscureText: _obscure,
                                onFieldSubmitted: (_) => _submit(),
                                decoration: _decoration('••••••••').copyWith(
                                    suffixIcon: IconButton(
                                        onPressed: () => setState(
                                            () => _obscure = !_obscure),
                                        icon: Icon(
                                            _obscure
                                                ? Icons.visibility_outlined
                                                : Icons.visibility_off_outlined,
                                            size: 17,
                                            color: brandGoldDark))),
                                validator: (value) =>
                                    value == null || value.isEmpty
                                        ? 'Mot de passe requis'.tr
                                        : null),
                            const SizedBox(height: 20),
                            Consumer<AuthProvider>(
                                builder: (_, auth, __) => SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: FilledButton(
                                        onPressed:
                                            auth.isLoading ? null : _submit,
                                        style: FilledButton.styleFrom(
                                            backgroundColor: brandAmber,
                                            foregroundColor: brandNavy,
                                            shape:
                                                const RoundedRectangleBorder()),
                                        child: auth.isLoading
                                            ? const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                        strokeWidth: 2))
                                            : Text('Se connecter'.tr,
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.w700))))),
                            const SizedBox(height: 18),
                            Center(
                                child: Text(
                                    'Le type de compte est détecté automatiquement'.tr,
                                    style: const TextStyle(
                                        fontSize: 9,
                                        color: Color(0xFFB8B8B8)))),
                            const SizedBox(height: 14),
                            Center(
                              child: GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const RegistrationScreen()),
                                ),
                                child: RichText(
                                  text: TextSpan(
                                    style: const TextStyle(fontSize: 12, color: brandGoldDark),
                                    children: [
                                      TextSpan(text: "Vous êtes résident et n'avez pas encore de compte ? ".tr),
                                      TextSpan(
                                        text: "S'inscrire".tr,
                                        style: const TextStyle(fontWeight: FontWeight.w800, color: brandAmber),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ])),
                )),
          ),
        ),
      ]),
    );
  }

  InputDecoration _decoration(String hint, {String? error}) => InputDecoration(
        hintText: hint,
        errorText: error,
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        border: const OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: Color(0xFFD9D9D9))),
        enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: Color(0xFFD9D9D9))),
        focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: brandAmber)),
      );
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text,
          style: const TextStyle(
              fontSize: 9,
              letterSpacing: 1,
              color: brandGoldDark,
              fontWeight: FontWeight.w700)));
}
