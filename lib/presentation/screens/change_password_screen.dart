// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../theme/design_tokens.dart';
import '../theme/gi_colors.dart';
import '../widgets/gi_alert_dialog.dart';
import '../widgets/gi_pressable.dart';
import '../widgets/gi_primary_button.dart';
import '../widgets/gi_text_field.dart';
import 'intervenant_home_screen.dart';
import 'manager_home_screen.dart';
import 'resident_home_screen.dart';

/// Changement de mot de passe — frame Figma « Change Password LT » (0:3781)
/// et ses variantes d'erreur et de reussite.
///
/// Geometrie relevee : pastille de retour a 66, titre 28 a 126, sous-titre
/// a 43 dessous, champs a 235 espaces de 16, bouton a 708.
///
/// C'est le premier ecran qu'un nouveau resident voit : l'administration lui
/// remet un mot de passe provisoire, et l'app impose de le remplacer.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();

  bool _loading = false;
  bool _touched = false;
  String? _serverError;

  @override
  void initState() {
    super.initState();
    for (final c in [_current, _next, _confirm]) {
      c.addListener(() {
        if (_touched || _serverError != null) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  // ─── Verifications ────────────────────────────────────────
  String? _currentError(AppL10n t) =>
      _touched && _current.text.isEmpty ? t.passwordRequired : null;

  /// Huit caracteres au minimum : c'est la regle du serveur, autant la dire
  /// avant l'aller-retour.
  String? _nextError(AppL10n t) {
    if (!_touched) return null;
    if (_next.text.isEmpty) return t.passwordRequired;
    if (_next.text.length < 8) return t.passwordTooShort;
    return null;
  }

  String? _confirmError(AppL10n t) {
    if (!_touched) return null;
    if (_confirm.text.isEmpty) return t.passwordRequired;
    if (_confirm.text != _next.text) return t.passwordMismatch;
    return null;
  }

  bool _isValid(AppL10n t) =>
      _current.text.isNotEmpty &&
      _next.text.length >= 8 &&
      _confirm.text == _next.text;

  Future<void> _submit() async {
    final t = AppL10n.of(context);
    setState(() {
      _touched = true;
      _serverError = null;
    });
    if (!_isValid(t)) return;

    final auth = context.read<AuthProvider>();
    setState(() => _loading = true);
    try {
      await auth.changePassword(_current.text, _next.text);
      if (!mounted) return;
      setState(() => _loading = false);
      await showGiAlert<void>(
        context: context,
        title: t.passwordChangedTitle,
        message: t.passwordChangedBody,
        closeLabel: t.close,
        primaryLabel: t.close,
      );
      if (mounted) _goHome(auth);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _serverError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _goHome(AuthProvider auth) {
    final role = auth.userRole;
    final Widget home = switch (role) {
      'INTERVENANT' => const IntervenantHomeScreen(),
      'ADMIN' || 'RESPONSABLE_ZONE' || 'MANAGER' => const ManagerHomeScreen(),
      _ => const ResidentHomeScreen(),
    };
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => home));
  }

  // ─── Build ────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    final t = AppL10n.of(context);
    // Le mot de passe provisoire est impose : tant qu'il n'est pas remplace,
    // il n'y a pas d'ecran ou revenir.
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: c.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                    FigSpace.pagePadding,
                    MediaQuery.paddingOf(context).top > 0 ? 22 : 32,
                    FigSpace.pagePadding,
                    FigSpace.xl),
                children: [
                  if (canPop)
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: GiPressable(
                        onTap: () => Navigator.pop(context),
                        pressedScale: 0.88,
                        child: Container(
                          width: FigSize.chipMd,
                          height: FigSize.chipMd,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: c.headerChipBg,
                            border: Border.all(color: c.headerChipBorder),
                            borderRadius:
                                BorderRadius.circular(FigRadius.chip),
                          ),
                          child: Transform.flip(
                            flipX: Directionality.of(context) ==
                                TextDirection.rtl,
                            child: SvgPicture.asset(
                              'assets/figma/icons/back_14.svg',
                              colorFilter: ColorFilter.mode(
                                  c.textBody, BlendMode.srcIn),
                            ),
                          ),
                        ),
                      ),
                    ),
                  SizedBox(height: canPop ? FigSpace.xxl : 0),
                  Text(t.changePassword,
                      style:
                          FigText.display.copyWith(color: c.loginTitle)),
                  const SizedBox(height: FigSpace.lg),
                  Text(t.changePasswordSubtitle,
                      style: FigText.field
                          .copyWith(height: 1.2, color: c.loginSubtitle)),
                  const SizedBox(height: FigSpace.xxl),
                  GiTextField(
                    label: t.currentPassword,
                    hint: t.passwordHint,
                    controller: _current,
                    isPassword: true,
                    textInputAction: TextInputAction.next,
                    errorText: _currentError(t),
                  ),
                  const SizedBox(height: FigSpace.xl),
                  GiTextField(
                    label: t.newPassword,
                    hint: t.newPasswordHint,
                    controller: _next,
                    isPassword: true,
                    textInputAction: TextInputAction.next,
                    errorText: _nextError(t),
                  ),
                  const SizedBox(height: FigSpace.xl),
                  GiTextField(
                    label: t.confirmPassword,
                    hint: t.confirmPasswordHint,
                    controller: _confirm,
                    isPassword: true,
                    textInputAction: TextInputAction.done,
                    errorText: _confirmError(t),
                    onSubmitted: (_) => _submit(),
                  ),
                  if (_serverError != null) ...[
                    const SizedBox(height: FigSpace.xl),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SvgPicture.asset(
                          'assets/figma/icons/info_16.svg',
                          colorFilter: const ColorFilter.mode(
                              FigAlert.error, BlendMode.srcIn),
                        ),
                        const SizedBox(width: FigSpace.md),
                        Expanded(
                          child: Text(_serverError!,
                              style: FigText.body.copyWith(
                                  height: 1.4, color: FigAlert.error)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(FigSpace.pagePadding, 0,
                  FigSpace.pagePadding, FigSpace.xxl),
              child: GiPrimaryButton(
                label: t.changePassword,
                isLoading: _loading,
                onPressed: _loading ? null : _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
