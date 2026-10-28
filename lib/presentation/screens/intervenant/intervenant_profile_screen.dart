import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../data/person_name.dart';
import '../../providers/theme_provider.dart';
import '../../theme/design_tokens.dart';
import '../../theme/gi_colors.dart';
import '../../widgets/gi_appear.dart';
import '../../widgets/gi_card.dart';
import '../../widgets/gi_scroll_blur.dart';
import '../../widgets/gi_settings.dart';
import '../admin/admin_more_screen.dart';
import '../admin/admin_ui.dart';
import '../change_password_screen.dart';
import 'intervenant_store.dart';

/// Onglet Profil : qui il est, ce qu'il a fait, ses reglages.
class IntervenantProfileScreen extends StatelessWidget {
  final IntervenantStore store;
  final Map? user;
  final int unread;
  final VoidCallback openNotifications;
  final VoidCallback onLogout;

  const IntervenantProfileScreen({
    super.key,
    required this.store,
    required this.user,
    required this.unread,
    required this.openNotifications,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    final top = MediaQuery.paddingOf(context).top > 0 ? 14.0 : 24.0;
    final theme = context.watch<ThemeProvider>();
    final name = PersonName.format(user?['name'] ?? user?['fullName']);
    final profession = (user?['profession'] ?? '').toString().trim();

    Widget svg(String asset) => SvgPicture.asset(asset,
        colorFilter: ColorFilter.mode(c.textBody, BlendMode.srcIn));

    var i = 0;
    Widget appear(Widget w) => GiAppear(index: i++, child: w);

    return Scaffold(
      backgroundColor: c.scaffold,
      body: GiScrollBlur(
        child: ListView(
          clipBehavior: Clip.none,
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          padding: EdgeInsets.fromLTRB(
              FigSpace.pagePadding, top, FigSpace.pagePadding, 150),
          children: [
            const AdminPageHeader(title: 'Profil', large: true),
            const SizedBox(height: FigSpace.xl + 4),
            appear(GiCard(
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: FigBrand.amber.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: FigBrand.amber.withValues(alpha: 0.6)),
                    ),
                    child: Text(adminInitials(user),
                        style: FigText.titleMd.copyWith(color: FigBrand.amber)),
                  ),
                  const SizedBox(width: FigSpace.xl),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: FigText.titleMd
                                .copyWith(fontSize: 18, color: c.textBody)),
                        const SizedBox(height: 3),
                        Text((user?['email'] ?? '').toString(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: FigText.body.copyWith(color: c.textMuted)),
                        const SizedBox(height: FigSpace.md),
                        AdminPill(
                            profession.isEmpty ? 'Intervenant' : profession,
                            FigBrand.amber,
                            icon: Icons.handyman_outlined,
                            dense: true),
                      ],
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: FigSpace.lg),
            appear(ListenableBuilder(
              listenable: store,
              builder: (context, _) => Row(
                children: [
                  Expanded(
                    child: AdminStatTile(
                      icon: Icons.task_alt_rounded,
                      accent: FigAlert.success,
                      label: 'Missions terminées',
                      value: store.loading ? '–' : '${store.done.length}',
                      hint: store.loading
                          ? null
                          : '${store.doneThisWeek} cette semaine',
                    ),
                  ),
                  const SizedBox(width: FigSpace.md),
                  Expanded(
                    child: AdminStatTile(
                      icon: Icons.pending_actions_rounded,
                      accent: FigBrand.amber,
                      label: 'À faire',
                      value: store.loading
                          ? '–'
                          : '${store.current.length + store.toStart.length}',
                      hint: store.loading
                          ? null
                          : '${store.current.length} en cours',
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: FigSpace.xl + 4),
            appear(GiSettingsGroup(
              title: 'Compte',
              rows: [
                GiSettingsRow(
                  icon: svg('assets/figma/icons/bell_16.svg'),
                  label: 'Notifications',
                  value: unread > 0
                      ? (unread == 1 ? '1 non lue' : '$unread non lues')
                      : 'Tout est lu',
                  onTap: openNotifications,
                ),
                GiSettingsRow(
                  icon: svg('assets/figma/icons/lock_16.svg'),
                  label: 'Changer le mot de passe',
                  onTap: () => adminPush(context, const ChangePasswordScreen()),
                ),
                GiSettingsRow(
                  icon: svg('assets/figma/icons/theme_16.svg'),
                  label: 'Thème sombre',
                  trailing: GiToggle(
                    value: theme.isDark,
                    onChanged: (v) => theme.setDark(v),
                  ),
                ),
              ],
            )),
            const SizedBox(height: FigSpace.xl + 4),
            appear(AdminLogoutButton(onLogout: onLogout)),
          ],
        ),
      ),
    );
  }
}
