// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import '../widgets/gi_avatar.dart';
import '../widgets/gi_alert_dialog.dart';
import '../../data/api_service.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
class ResidentProfileScreen extends StatefulWidget {
  const ResidentProfileScreen({super.key});

  @override
  State<ResidentProfileScreen> createState() => _ResidentProfileScreenState();
}

class _ResidentProfileScreenState extends State<ResidentProfileScreen> {
  bool _photoBusy = false;

  /// Choix d'une photo de profil. Le serveur accepte une image en data-URL
  /// et renvoie l'utilisateur mis a jour ; la limite de 5 Mo est verifiee
  /// ici pour ne pas televerser en vain.
  Future<void> _pickPhoto() async {
    final t = AppL10n.of(context);
    final auth = context.read<AuthProvider>();
    final hasPhoto = (auth.user?['photo'] ?? '').toString().isNotEmpty;

    if (hasPhoto) {
      final action = await _askPhotoAction(t);
      if (action == null) return;
      if (action == 'remove') {
        setState(() => _photoBusy = true);
        try {
          await ApiService().removeProfilePhoto();
          await auth.setPhoto(null);
        } catch (e) {
          _photoError(t, e);
        } finally {
          if (mounted) setState(() => _photoBusy = false);
        }
        return;
      }
    }

    final result = await FilePicker.platform
        .pickFiles(type: FileType.image, withData: true);
    final file = result?.files.single;
    if (file?.bytes == null) return;
    if (file!.bytes!.length > 5 * 1024 * 1024) {
      if (!mounted) return;
      showGiAlert<void>(
        context: context,
        title: t.errorTitle,
        message: t.photoTooBig,
        closeLabel: t.close,
        primaryLabel: t.close,
      );
      return;
    }

    final ext = (file.extension ?? 'jpg').toLowerCase();
    final mime = ext == 'png'
        ? 'image/png'
        : (ext == 'webp' ? 'image/webp' : 'image/jpeg');
    setState(() => _photoBusy = true);
    try {
      final updated = await ApiService()
          .updateProfilePhoto('data:$mime;base64,${base64Encode(file.bytes!)}');
      await auth.setPhoto(updated['photo']?.toString());
    } catch (e) {
      _photoError(t, e);
    } finally {
      if (mounted) setState(() => _photoBusy = false);
    }
  }

  /// Photo deja posee : on demande s'il faut la remplacer ou l'enlever.
  Future<String?> _askPhotoAction(AppL10n t) {
    final c = GiColors.of(context);
    return showModalBottomSheet<String>(
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
            children: [
              GiCard(
                onTap: () => Navigator.pop(sheetContext, 'change'),
                child: Row(
                  children: [
                    SvgPicture.asset('assets/figma/icons/camera_24.svg',
                        width: 16,
                        height: 16,
                        colorFilter:
                            ColorFilter.mode(c.textBody, BlendMode.srcIn)),
                    const SizedBox(width: FigSpace.lg),
                    Text(t.changePhoto,
                        style: FigText.field.copyWith(color: c.textBody)),
                  ],
                ),
              ),
              const SizedBox(height: FigSpace.md),
              GiCard(
                onTap: () => Navigator.pop(sheetContext, 'remove'),
                child: Row(
                  children: [
                    SvgPicture.asset('assets/figma/icons/trash_15.svg',
                        colorFilter: const ColorFilter.mode(
                            FigAlert.error, BlendMode.srcIn)),
                    const SizedBox(width: FigSpace.lg),
                    Text(t.removePhoto,
                        style: FigText.field.copyWith(color: FigAlert.error)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _photoError(AppL10n t, Object e) {
    if (!mounted) return;
    showGiAlert<void>(
      context: context,
      title: t.errorTitle,
      message: e.toString().replaceFirst('Exception: ', ''),
      closeLabel: t.close,
      primaryLabel: t.close,
    );
  }

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
            const SizedBox(height: FigSpace.xl),
            _identity(c, name, email),
            const SizedBox(height: FigSpace.lg),
            GiSettingsGroup(
              title: t.myAccount,
              rows: [
                GiSettingsRow(
                  icon: SvgPicture.asset('assets/figma/icons/mail_16.svg',
                      colorFilter: ColorFilter.mode(c.textBody, BlendMode.srcIn)),
                  label: t.emailLabel,
                  value: email.isEmpty ? t.notProvided : email,
                  trailing: const SizedBox.shrink(),
                ),
                GiSettingsRow(
                  icon: SvgPicture.asset('assets/figma/icons/phone_16.svg',
                      colorFilter: ColorFilter.mode(c.textBody, BlendMode.srcIn)),
                  label: t.phoneLabel,
                  value: phone.isEmpty ? t.notProvided : phone,
                  trailing: const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: FigSpace.lg),
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
                  icon: SvgPicture.asset('assets/figma/icons/theme_16.svg',
                      colorFilter: ColorFilter.mode(c.textBody, BlendMode.srcIn)),
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
            const SizedBox(height: FigSpace.xl),
            const _NotificationPrefs(),
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
          GiPressable(
            pressedScale: 0.94,
            onTap: _photoBusy ? null : _pickPhoto,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                GiAvatar(
                  name: name,
                  photoUrl: context.watch<AuthProvider>().photoUrl,
                  size: 56,
                  radius: FigRadius.card,
                  bordered: true,
                ),
                // Pastille d'appareil photo : sans elle, rien ne dit que la
                // photo se change en appuyant dessus.
                PositionedDirectional(
                  bottom: -4,
                  end: -4,
                  child: Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: FigBrand.amber,
                      shape: BoxShape.circle,
                      border: Border.all(color: c.card, width: 2),
                    ),
                    child: _photoBusy
                        ? const SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(
                                strokeWidth: 1.5, color: Colors.black),
                          )
                        : SvgPicture.asset(
                            'assets/figma/icons/camera_24.svg',
                            width: 11,
                            height: 11,
                            colorFilter: const ColorFilter.mode(
                                Colors.black, BlendMode.srcIn),
                          ),
                  ),
                ),
              ],
            ),
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
                          SvgPicture.asset('assets/figma/icons/check_14.svg',
                              colorFilter: const ColorFilter.mode(
                                  FigBrand.amber, BlendMode.srcIn)),
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


/// Section Notifications de la frame "Setting LT" (837:4324) : quatre lignes
/// a interrupteur.
///
/// A savoir : l'API n'expose aucun point d'entree pour ces preferences. Elles
/// sont donc enregistrees sur l'appareil. Elles ne suivent pas l'utilisateur
/// d'un telephone a l'autre, et le serveur continue d'envoyer toutes les
/// notifications — ce reglage filtre a l'arrivee. A rebrancher sur l'API le
/// jour ou elle les gerera.
class _NotificationPrefs extends StatefulWidget {
  const _NotificationPrefs();

  @override
  State<_NotificationPrefs> createState() => _NotificationPrefsState();
}

class _NotificationPrefsState extends State<_NotificationPrefs> {
  static const _keys = [
    'notif_announcements',
    'notif_maintenance',
    'notif_bookings',
    'notif_payments',
  ];

  /// Tout est actif par defaut : un resident qui n'a rien regle doit etre
  /// prevenu d'une coupure d'eau ou d'une echeance.
  final _values = <String, bool>{for (final k in _keys) k: true};

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      for (final k in _keys) {
        _values[k] = prefs.getBool(k) ?? true;
      }
    });
  }

  Future<void> _set(String key, bool value) async {
    setState(() => _values[key] = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    final t = AppL10n.of(context);

    Widget row(String key, Widget icon, String label) => GiSettingsRow(
          icon: icon,
          label: label,
          trailing: GiToggle(
            value: _values[key] ?? true,
            onChanged: (v) => _set(key, v),
          ),
        );

    Widget svg(String name) => SvgPicture.asset(
          'assets/figma/icons/$name.svg',
          colorFilter: ColorFilter.mode(c.textBody, BlendMode.srcIn),
        );

    return GiSettingsGroup(
      title: t.notificationsTitle,
      rows: [
        row(_keys[0], svg('notif_announce_16'), t.notifAnnouncements),
        // Le Figma reprend ici l'icone de la langue, visiblement par copie :
        // on prend une icone qui correspond a l'intervention.
        row(_keys[1], SvgPicture.asset('assets/figma/icons/alert_16.svg',
                      colorFilter: ColorFilter.mode(c.textBody, BlendMode.srcIn)),
            t.notifMaintenance),
        row(_keys[2], svg('notif_booking_16'), t.notifBookings),
        row(_keys[3], svg('notif_payment_16'), t.notifPayments),
      ],
    );
  }
}
