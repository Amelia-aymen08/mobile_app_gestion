import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/person_name.dart';
import '../../providers/theme_provider.dart';
import '../../theme/design_tokens.dart';
import '../../theme/gi_colors.dart';
import '../../widgets/gi_appear.dart';
import '../../widgets/gi_card.dart';
import '../../widgets/gi_pressable.dart';
import '../../widgets/gi_settings.dart';
import 'admin_ui.dart';
import '../../widgets/gi_scroll_blur.dart';

/// Une entree du menu d'administration, partagee par l'onglet « Plus » du
/// telephone et la barre laterale de l'ordinateur.
class AdminMenuEntry {
  final String label;
  final String? hint;
  final IconData icon;
  final VoidCallback onTap;
  final int badge;
  const AdminMenuEntry(this.label, this.icon, this.onTap,
      {this.hint, this.badge = 0});
}

/// Libelle du role, tel qu'on l'affiche sous le nom.
String adminRoleLabel(String role, Map? user) {
  if (role == 'ADMIN') return 'Administrateur';
  if (role == 'RESPONSABLE_ZONE') {
    final zone = (user?['zone'] ?? '').toString().trim();
    if (zone.isEmpty) return 'Responsable de zone';
    return 'Responsable ${zone.toUpperCase() == 'ALL' ? 'toutes les zones' : zone}';
  }
  if (role == 'HSE') return 'HSE';
  return 'Manager';
}

String adminInitials(Map? user) =>
    PersonName.format(user?['name'] ?? user?['fullName'])
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

/// Onglet « Plus » : identite, raccourcis groupes, theme, deconnexion.
class AdminMoreScreen extends StatelessWidget {
  final Map? user;
  final String role;
  final List<AdminMenuEntry> management;
  final List<AdminMenuEntry> administration;
  final List<AdminMenuEntry> account;
  final VoidCallback onLogout;

  const AdminMoreScreen({
    super.key,
    required this.user,
    required this.role,
    required this.management,
    required this.administration,
    required this.account,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    final top = MediaQuery.paddingOf(context).top > 0 ? 14.0 : 24.0;
    final theme = context.watch<ThemeProvider>();
    final name = PersonName.format(user?['name'] ?? user?['fullName']);

    GiSettingsRow row(AdminMenuEntry e) => GiSettingsRow(
          icon: Icon(e.icon, color: c.textBody),
          label: e.label,
          value: e.hint,
          onTap: e.onTap,
          trailing: e.badge > 0
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      constraints: const BoxConstraints(minWidth: 20),
                      height: 20,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: FigBrand.amber,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('${e.badge}',
                          style: FigText.caption.copyWith(
                              color: Colors.black,
                              fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: FigSpace.md),
                    GiChevron(color: c.textMuted),
                  ],
                )
              : null,
        );

    var i = 0;
    Widget appear(Widget w) => GiAppear(index: i++, child: w);

    return Scaffold(
      backgroundColor: c.scaffold,
      body: GiScrollBlur(
        child: AdminContent(
          maxWidth: 720,
          child: ListView(
            clipBehavior: Clip.none,
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            padding: EdgeInsets.fromLTRB(
                FigSpace.pagePadding, top, FigSpace.pagePadding, 150),
            children: [
              const AdminPageHeader(title: 'Plus', large: true),
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
                          style:
                              FigText.titleMd.copyWith(color: FigBrand.amber)),
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
                          AdminPill(adminRoleLabel(role, user), FigBrand.amber,
                              icon: Icons.verified_user_outlined, dense: true),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: FigSpace.xl + 4),
              appear(GiSettingsGroup(
                  title: 'Gestion',
                  rows: [for (final e in management) row(e)])),
              if (administration.isNotEmpty) ...[
                const SizedBox(height: FigSpace.xl + 4),
                appear(GiSettingsGroup(
                    title: 'Administration',
                    rows: [for (final e in administration) row(e)])),
              ],
              const SizedBox(height: FigSpace.xl + 4),
              appear(GiSettingsGroup(
                title: 'Compte',
                rows: [
                  for (final e in account) row(e),
                  GiSettingsRow(
                    icon: Icon(Icons.dark_mode_outlined, color: c.textBody),
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
      ),
    );
  }
}

/// Deconnexion en deux temps, sans boite de dialogue : le premier appui
/// arme le bouton, qui demande confirmation pendant quatre secondes.
class AdminLogoutButton extends StatefulWidget {
  final VoidCallback onLogout;
  final bool compact;
  const AdminLogoutButton(
      {super.key, required this.onLogout, this.compact = false});

  @override
  State<AdminLogoutButton> createState() => _AdminLogoutButtonState();
}

class _AdminLogoutButtonState extends State<AdminLogoutButton> {
  bool _armed = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tap() {
    if (_armed) {
      _timer?.cancel();
      widget.onLogout();
      return;
    }
    setState(() => _armed = true);
    _timer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _armed = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GiPressable(
      onTap: _tap,
      pressedScale: 0.97,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: widget.compact ? 12 : 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: FigAlert.error.withValues(alpha: _armed ? 1 : 0.08),
          border: Border.all(color: FigAlert.error.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(FigRadius.cta),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Row(
            key: ValueKey(_armed),
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.logout_rounded,
                  size: 18, color: _armed ? Colors.white : FigAlert.error),
              const SizedBox(width: FigSpace.md),
              Flexible(
                child: Text(
                    _armed
                        ? (widget.compact ? 'Confirmer' : 'Confirmer la déconnexion')
                        : 'Se déconnecter',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        (widget.compact ? FigText.bodyActive : FigText.button)
                            .copyWith(
                                color: _armed ? Colors.white : FigAlert.error)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
