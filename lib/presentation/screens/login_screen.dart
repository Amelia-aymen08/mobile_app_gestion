// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../widgets/gi_alert_dialog.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../theme/design_tokens.dart';
import '../theme/gi_colors.dart';
import '../widgets/gi_pressable.dart';
import '../widgets/gi_primary_button.dart';
import '../widgets/gi_text_field.dart';
import '../widgets/gi_watermark.dart';
import 'change_password_screen.dart';
import 'forgot_password_screen.dart';
import 'gestionnaire_tag_home_screen.dart';
import 'intervenant_home_screen.dart';
import 'manager_home_screen.dart';
import 'recouvrement_home_screen.dart';
import 'resident_home_screen.dart';
import 'registration_screen.dart';

/// Ecran de connexion — frames Figma "Login LT" (721:7277), "Login Active LT"
/// (721:7222), "Login Error LT" (721:7253) et "Login DT" (34:96).
///
/// Le Figma dessine une saisie par numero d'appartement ; l'API attend
/// `{email, password}`. Conformement a la regle du projet, on garde le
/// fonctionnement du code et on reprend l'habillage du Figma.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _form = GlobalKey<FormState>();
  String? _error;

  // Pilote l'etat actif du bouton : le Figma distingue nettement un CTA gris
  // d'un CTA ambre, il faut donc savoir si les deux champs sont remplis.
  bool _canSubmit = false;

  @override
  void initState() {
    super.initState();
    _email.addListener(_refreshSubmitState);
    _password.addListener(_refreshSubmitState);
    // Quand le serveur a coupe la session — compte desactive par
    // l'administration — on arrive ici sans explication. Le message est
    // livre par le fournisseur d'authentification, et ne s'affiche qu'une
    // fois.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final notice = context.read<AuthProvider>().consumeNotice();
      if (notice == null) return;
      final t = AppL10n.of(context);
      showGiAlert<void>(
        context: context,
        title: t.loginTitle,
        message: notice == 'accountDisabled' ? t.accountDisabled : notice,
        closeLabel: t.close,
        primaryLabel: t.close,
      );
    });
  }

  void _refreshSubmitState() {
    final ready = _email.text.trim().isNotEmpty && _password.text.isNotEmpty;
    if (ready != _canSubmit) setState(() => _canSubmit = ready);
  }

  @override
  void dispose() {
    _email.removeListener(_refreshSubmitState);
    _password.removeListener(_refreshSubmitState);
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
        setState(() => _error = error.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  void _go(Widget screen) => Navigator.pushAndRemoveUntil(
      context, MaterialPageRoute(builder: (_) => screen), (_) => false);

  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    final t = AppL10n.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: c.scaffold,
      body: Stack(
        children: [
          GiWatermark(isDark: isDark),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Le rythme du Figma pousse le bouton vers le bas de
                // l'ecran. Cela n'a de sens que s'il y a de la hauteur a
                // occuper : en paysage, ou clavier ouvert, on repasse a une
                // colonne qui defile simplement.
                final tall = constraints.maxHeight >= 620;
                return SingleChildScrollView(
                // Toujours defilable : sans cela, un contenu qui tient dans
                // l'ecran ne rebondit pas, et la page parait figee la ou
                // toutes les autres repondent.
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                      minHeight: tall ? constraints.maxHeight : 0),
                  child: _MaybeIntrinsic(
                    enabled: tall,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: FigSpace.pagePadding),
                      child: Form(
                        key: _form,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Rythme vertical du Figma, mesure depuis le haut de
                            // la frame : logo a 67, titre a 193, champs a 303.
                            // La barre d'etat est deja retiree par le SafeArea,
                            // d'ou le 23.
                            const SizedBox(height: 23),
                            Center(
                              // Le Figma reserve 87 x 98. Le logo Gerance Immo
                              // Service est carre : on garde la hauteur du
                              // Figma et on laisse la largeur suivre, plutot
                              // que de rogner la marque pour tenir dans la
                              // boite.
                              child: Image.asset(
                                isDark
                                    ? 'assets/brand/gis_logo_vertical_dark.png'
                                    : 'assets/brand/gis_logo_vertical_light.png',
                                height: 98,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(height: 28),
                            Text(
                              t.loginTitle,
                              textAlign: TextAlign.center,
                              style:
                                  FigText.display.copyWith(color: c.loginTitle),
                            ),
                            const SizedBox(height: 9),
                            Text(
                              t.loginSubtitle,
                              textAlign: TextAlign.center,
                              style: FigText.field.copyWith(
                                  color: c.loginSubtitle, height: 1.2),
                            ),
                            const SizedBox(height: 48),
                            GiTextField(
                              label: t.emailLabel,
                              hint: t.emailHint,
                              controller: _email,
                              errorText: _error,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? t.emailRequired
                                  : null,
                            ),
                            const SizedBox(height: FigSpace.xl),
                            GiTextField(
                              label: t.passwordLabel,
                              hint: t.passwordHint,
                              controller: _password,
                              isPassword: true,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _submit(),
                              validator: (v) => v == null || v.isEmpty
                                  ? t.passwordRequired
                                  : null,
                            ),
                            const SizedBox(height: FigSpace.xl),
                            Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: GiPressable(
                                pressedScale: 0.94,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const ForgotPasswordScreen()),
                                ),
                                child: Text(
                                  t.forgotPassword,
                                  style: FigText.field
                                      .copyWith(color: FigBrand.amber),
                                ),
                              ),
                            ),
                            // Espace souple : il absorbe l'ecart entre la frame
                            // de 812 du Figma et la hauteur reelle de l'ecran,
                            // sans deformer les blocs.
                            // Sur un ecran court l'espace extensible
                            // disparait : il ne reste que l'ecart minimal.
                            if (tall)
                              const Expanded(child: SizedBox(height: 48))
                            else
                              const SizedBox(height: 32),
                            GiPrimaryButton(
                              label: t.loginCta,
                              isLoading: auth.isLoading,
                              onPressed: _canSubmit ? _submit : null,
                            ),
                            const SizedBox(height: 17),
                            Center(
                              child: SizedBox(
                                width: 285,
                                child: Text.rich(
                                  TextSpan(children: [
                                    TextSpan(
                                      text: t.firstLoginQuestion,
                                      style: FigText.field
                                          .copyWith(color: FigBrand.amber),
                                    ),
                                    TextSpan(
                                      text: t.firstLoginHelp,
                                      style: FigText.field
                                          .copyWith(color: c.footerText),
                                    ),
                                  ]),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            const SizedBox(height: FigSpace.xl),
                            // Absent du Figma, mais l'inscription existe dans
                            // l'app : c'est une fonctionnalite, donc elle reste.
                            Center(
                              child: GiPressable(
                                pressedScale: 0.96,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const RegistrationScreen()),
                                ),
                                child: Text.rich(
                                  TextSpan(children: [
                                    TextSpan(
                                      text: '${t.noAccountQuestion} ',
                                      style: FigText.body
                                          .copyWith(color: c.footerText),
                                    ),
                                    TextSpan(
                                      text: t.signUp,
                                      style: FigText.body.copyWith(
                                        color: FigBrand.amber,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ]),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            const SizedBox(height: FigSpace.xxl),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Filigrane du logo dans l'angle superieur, a 6 % d'opacite.
///
/// Geometrie reprise telle quelle du Figma. En clair : boite de 293,254 x
/// 246,49 posee a -128 / -56,7, contenant une image de 256,511 x 194,426
/// tournee de -12,82 degres. En sombre : 296,328 x 265,163 a -122 / -69,
/// image de 243,406 x 180,316 tournee de -24,56 degres.
///
/// Le point cle : l'image est rendue 1,48 fois plus haute que sa fenetre et
/// alignee en haut. Elle deborde donc par le bas et seul le monogramme reste
/// visible, sans le texte de la marque. C'est ce cadrage qui donne l'angle
/// dessine dans la maquette.
///

/// Applique IntrinsicHeight seulement quand on en a besoin.
///
/// IntrinsicHeight mesure ses enfants avant de les disposer, ce qui permet
/// a un Expanded de vivre dans une zone qui defile. Mais la mesure d'un
/// texte suppose qu'il tient sur une ligne : des qu'il revient a la ligne,
/// la hauteur reelle depasse la mesure et Flutter signale un debordement.
/// On ne s'en sert donc que sur les ecrans assez hauts, la ou l'espace
/// extensible sert a quelque chose.
class _MaybeIntrinsic extends StatelessWidget {
  final bool enabled;
  final Widget child;
  const _MaybeIntrinsic({required this.enabled, required this.child});

  @override
  Widget build(BuildContext context) =>
      enabled ? IntrinsicHeight(child: child) : child;
}
