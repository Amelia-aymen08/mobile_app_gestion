import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../data/api_service.dart';
import '../../l10n/app_localizations.dart';
import '../theme/design_tokens.dart';
import '../theme/gi_colors.dart';
import '../widgets/gi_pressable.dart';
import '../widgets/gi_primary_button.dart';
import '../widgets/gi_text_field.dart';

/// Mot de passe oublie. Pas de frame dediee dans le Figma : l'ecran reprend
/// donc a l'identique le vocabulaire visuel du login — meme fond, meme
/// typographie, meme champ, meme bouton — plutot que d'inventer un style.
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
    final c = GiColors.of(context);
    final t = AppL10n.of(context);

    return Scaffold(
      backgroundColor: c.scaffold,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
              FigSpace.pagePadding, FigSpace.xl, FigSpace.pagePadding, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: _BackChip(onTap: () => Navigator.pop(context)),
              ),
              const SizedBox(height: FigSpace.xxl),
              // Le changement d'etat se fait en fondu : l'ecran ne clignote pas
              // entre le formulaire et la confirmation.
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                child: _sent ? _confirmation(c, t) : _form(c, t),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _form(GiColors c, AppL10n t) {
    return Column(
      key: const ValueKey('form'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(t.forgotTitle,
            style: FigText.display.copyWith(color: c.loginTitle)),
        const SizedBox(height: FigSpace.md),
        Text(t.forgotSubtitle,
            style: FigText.field.copyWith(color: c.textMuted, height: 1.36)),
        const SizedBox(height: FigSpace.xxl),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GiTextField(
                label: t.emailLabel,
                hint: t.emailHint,
                controller: _emailController,
                errorText: _error,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                validator: (v) =>
                    (v?.trim().isEmpty ?? true) ? t.emailRequired : null,
              ),
              const SizedBox(height: 24),
              GiPrimaryButton(
                label: t.sendLink,
                isLoading: _loading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _confirmation(GiColors c, AppL10n t) {
    return Column(
      key: const ValueKey('sent'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: FigAlert.success.withValues(alpha: 0.10),
            border: Border.all(color: FigAlert.success.withValues(alpha: 0.20)),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: SvgPicture.asset(
            'assets/figma/icons/check_14.svg',
            width: 30,
            height: 30,
            colorFilter:
                const ColorFilter.mode(FigAlert.success, BlendMode.srcIn),
          ),
        ),
        const SizedBox(height: FigSpace.xxl),
        Text(t.emailSentTitle,
            style: FigText.display.copyWith(color: c.loginTitle)),
        const SizedBox(height: FigSpace.md),
        Text(
          t.emailSentBody(_emailController.text.trim()),
          style: FigText.field.copyWith(color: c.textMuted, height: 1.36),
        ),
        const SizedBox(height: FigSpace.xxl),
        GiPrimaryButton(
          label: t.backToLogin,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}

/// Bouton de retour, calque sur les pastilles d'en-tete du Figma :
/// 32 de cote, rayon 8, fond et bordure tres legers.
class _BackChip extends StatelessWidget {
  final VoidCallback onTap;
  const _BackChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    return GiPressable(
      onTap: onTap,
      pressedScale: 0.90,
      child: Container(
        width: FigSize.chipMd,
        height: FigSize.chipMd,
        decoration: BoxDecoration(
          color: c.headerChipBg,
          border: Border.all(color: c.headerChipBorder),
          borderRadius: BorderRadius.circular(FigRadius.chip),
        ),
        child: Transform.flip(
          flipX: Directionality.of(context) == TextDirection.rtl,
          child: SvgPicture.asset('assets/figma/icons/back_14.svg',
              colorFilter: ColorFilter.mode(c.textBody, BlendMode.srcIn))),
      ),
    );
  }
}
