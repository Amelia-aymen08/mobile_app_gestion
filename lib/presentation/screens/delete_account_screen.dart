import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../theme/design_tokens.dart';
import '../theme/gi_colors.dart';
import '../widgets/gi_alert_dialog.dart';
import '../widgets/gi_pressable.dart';
import '../widgets/gi_text_field.dart';
import 'login_screen.dart';

/// Suppression du compte par le resident (Plus > Supprimer mon compte).
///
/// Exigee par le Play Store et l'App Store pour toute application ou l'on
/// peut creer un compte. Le serveur anonymise le compte (et ceux du foyer si
/// c'est le resident principal) ; voir DELETE /api/auth/me.
///
/// Meme construction que l'ecran de changement de mot de passe, avec un
/// bouton rouge : l'action est definitive.
class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _password = TextEditingController();
  bool _loading = false;
  bool _touched = false;
  String? _serverError;

  @override
  void initState() {
    super.initState();
    _password.addListener(() {
      if (_touched || _serverError != null) setState(() {});
    });
  }

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final t = AppL10n.of(context);
    setState(() {
      _touched = true;
      _serverError = null;
    });
    if (_password.text.isEmpty) return;

    var confirmed = false;
    await showGiAlert<void>(
      context: context,
      title: t.deleteAccountConfirmTitle,
      message: t.deleteAccountConfirmBody,
      closeLabel: t.cancel,
      primaryLabel: t.deleteAccountConfirm,
      onPrimary: () => confirmed = true,
    );
    if (!confirmed || !mounted) return;

    final auth = context.read<AuthProvider>();
    setState(() => _loading = true);
    try {
      await auth.deleteAccount(_password.text);
      if (!mounted) return;
      setState(() => _loading = false);
      await showGiAlert<void>(
        context: context,
        title: t.deleteAccountDoneTitle,
        message: t.deleteAccountDoneBody,
        closeLabel: t.close,
        primaryLabel: t.close,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _serverError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Widget _note(GiColors c, String text) => Padding(
        padding: const EdgeInsets.only(top: FigSpace.lg),
        child: Text(text,
            style: FigText.body.copyWith(height: 1.45, color: c.textMuted)),
      );

  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    final t = AppL10n.of(context);

    return Scaffold(
      backgroundColor: c.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                    FigSpace.pagePadding,
                    MediaQuery.paddingOf(context).top > 0 ? 22 : 32,
                    FigSpace.pagePadding,
                    FigSpace.xl),
                children: [
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
                          borderRadius: BorderRadius.circular(FigRadius.chip),
                        ),
                        child: Transform.flip(
                          flipX: Directionality.of(context) ==
                              TextDirection.rtl,
                          child: SvgPicture.asset(
                            'assets/figma/icons/back_14.svg',
                            colorFilter:
                                ColorFilter.mode(c.textBody, BlendMode.srcIn),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: FigSpace.xxl),
                  Text(t.deleteAccount,
                      style: FigText.display.copyWith(color: c.loginTitle)),
                  const SizedBox(height: FigSpace.lg),
                  Text(t.deleteAccountSubtitle,
                      style: FigText.field
                          .copyWith(height: 1.3, color: c.loginSubtitle)),
                  _note(c, t.deleteAccountHousehold),
                  _note(c, t.deleteAccountKept),
                  const SizedBox(height: FigSpace.xxl),
                  GiTextField(
                    label: t.currentPassword,
                    hint: t.deleteAccountPasswordHint,
                    controller: _password,
                    isPassword: true,
                    textInputAction: TextInputAction.done,
                    errorText: _touched && _password.text.isEmpty
                        ? t.passwordRequired
                        : null,
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
              child: GiPressable(
                onTap: _loading ? null : _submit,
                pressedScale: 0.97,
                child: Container(
                  width: double.infinity,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: FigAlert.error,
                    borderRadius: BorderRadius.circular(FigRadius.cta),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.4, color: Colors.white),
                        )
                      : Text(t.deleteAccount,
                          style: FigText.button.copyWith(color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
