// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/design_tokens.dart';
import '../theme/gi_colors.dart';
import '../widgets/gi_card.dart';
import '../widgets/gi_pressable.dart';
import '../widgets/gi_settings.dart';
import 'change_password_screen.dart';

/// Profil et reglages — frame Figma "Setting LT" (837:4287).
///
/// Le Figma organise cet ecran en listes groupees : un titre de section, puis
/// une carte unique dont les lignes sont separees par un trait. On reprend
/// cette structure au lieu de l'ancien formulaire a champs empiles.
///
/// Le changement de mot de passe ouvre l'ecran dedie, comme dans la maquette,
/// au lieu d'etre saisi ici. L'ancienne version appelait changePassword avec
/// un mot de passe actuel vide, ce que l'ecran dedie gere correctement.
class ResidentProfileScreen extends StatelessWidget {
  const ResidentProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    final t = AppL10n.of(context);
    final user = context.watch<AuthProvider>().user;
    final theme = context.watch<ThemeProvider>();
    final locale = context.watch<LocaleProvider>();

    final name = (user?['name'] ?? user?['fullName'] ?? '').toString();
    final email = (user?['email'] ?? '').toString();
    final phone = (user?['phone'] ?? '').toString();

    String langLabel() => switch (locale.locale.languageCode) {
          'en' => t.langEnglish,
          'ar' => t.langArabic,
          _ => t.langFrench,
        };

    return Scaffold(
      backgroundColor: c.scaffold,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
              FigSpace.pagePadding,
              MediaQuery.paddingOf(context).top > 0 ? 22 : 32,
              FigSpace.pagePadding,
              40),
          children: [
            // En-tete du Figma : pastille de retour de 32 puis le titre, ecart 16.
            Row(
              children: [
                GiPressable(
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
                      flipX:
                          Directionality.of(context) == TextDirection.rtl,
                      child: SvgPicture.asset(
                        'assets/figma/icons/back_14.svg',
                        colorFilter:
                            ColorFilter.mode(c.textBody, BlendMode.srcIn),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: FigSpace.xl),
                Text(t.profile,
                    style: FigText.titleMd
                        .copyWith(fontSize: 18, color: c.textBody)),
              ],
            ),
            const SizedBox(height: FigSpace.xxl),
            _identity(c, name, email),
            const SizedBox(height: FigSpace.xl),
            GiSettingsGroup(
              title: t.myAccount,
              rows: [
                GiSettingsRow(
                  icon: Icon(Icons.mail_outline_rounded, color: c.textBody),
                  label: t.emailLabel,
                  value: email.isEmpty ? t.notProvided : email,
                  trailing: const SizedBox.shrink(),
                ),
                GiSettingsRow(
                  icon: Icon(Icons.phone_outlined, color: c.textBody),
                  label: t.phoneLabel,
                  value: phone.isEmpty ? t.notProvided : phone,
                  trailing: const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: FigSpace.xl),
            GiSettingsGroup(
              title: t.services,
              rows: [
                GiSettingsRow(
                  icon: SvgPicture.asset('assets/figma/icons/lock_16.svg',
                      colorFilter:
                          ColorFilter.mode(c.textBody, BlendMode.srcIn)),
                  label: t.changePassword,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ChangePasswordScreen()),
                  ),
                ),
                GiSettingsRow(
                  // Le Figma reutilise l'icone du cadenas sur la ligne du
                  // theme, visiblement par copie : on prend une icone qui
                  // correspond a l'action.
                  icon: Icon(Icons.dark_mode_outlined, color: c.textBody),
                  label: t.darkTheme,
                  trailing: GiToggle(
                    value: theme.isDark,
                    onChanged: (v) => theme.setDark(v),
                  ),
                ),
                GiSettingsRow(
                  icon: SvgPicture.asset('assets/figma/icons/language_16.svg',
                      colorFilter:
                          ColorFilter.mode(c.textBody, BlendMode.srcIn)),
                  label: t.language,
                  value: langLabel(),
                  onTap: () => _pickLanguage(context, t, locale),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Carte d'identite : avatar, nom, adresse.
  Widget _identity(GiColors c, String name, String email) {
    return GiCard(
      child: Row(
        children: [
          // Trait ambre de 1 seulement : une bordure epaisse rogne la photo
          // et alourdit la carte.
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              border: Border.all(color: FigBrand.amber),
              borderRadius: BorderRadius.circular(FigRadius.card),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset('assets/figma/avatar.png', fit: BoxFit.cover),
          ),
          const SizedBox(width: FigSpace.xl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FigText.titleMd.copyWith(color: c.textBody)),
                const SizedBox(height: FigSpace.xs),
                Text(email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FigText.body.copyWith(color: c.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Choix de la langue. Le passage a l'arabe bascule toute l'interface de
  /// droite a gauche, Flutter s'en chargeant via le Directionality pose par
  /// MaterialApp.
  Future<void> _pickLanguage(
      BuildContext context, AppL10n t, LocaleProvider provider) async {
    final c = GiColors.of(context);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: c.scaffold,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(FigRadius.card)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              FigSpace.pagePadding, 0, FigSpace.pagePadding, FigSpace.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.selectLanguage,
                  style: FigText.titleMd.copyWith(color: c.textBody)),
              const SizedBox(height: FigSpace.xl),
              for (final entry in {
                'fr': t.langFrench,
                'en': t.langEnglish,
                'ar': t.langArabic,
              }.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: FigSpace.md),
                  child: GiCard(
                    onTap: () {
                      provider.setLocale(Locale(entry.key));
                      Navigator.pop(sheetContext);
                    },
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(entry.value,
                              style: FigText.statValue
                                  .copyWith(color: c.textBody)),
                        ),
                        if (provider.locale.languageCode == entry.key)
                          const Icon(Icons.check_rounded,
                              color: FigBrand.amber, size: 20),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
