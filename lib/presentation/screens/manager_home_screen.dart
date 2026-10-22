import 'dart:async';

import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:provider/provider.dart';

import '../../data/api_service.dart';
import '../../data/person_name.dart';
import '../providers/auth_provider.dart';
import '../services/gi_haptics.dart';
import '../theme/design_tokens.dart';
import '../theme/gi_colors.dart';
import '../widgets/gi_bottom_nav.dart';
import '../widgets/gi_brand_logo.dart';
import '../widgets/gi_pressable.dart';
import 'admin/admin_dashboard_screen.dart';
import 'admin/admin_more_screen.dart';
import 'admin/admin_resident_screen.dart';
import 'admin/admin_residences_screen.dart';
import 'admin/admin_store.dart';
import 'admin/admin_tickets_screen.dart';
import 'admin/admin_ui.dart';
import 'admin_notices_screen.dart';
import 'login_screen.dart';
import 'notifications_screen.dart';
import 'property_add_requests_management_screen.dart';
import 'recouvrement_financial_screen.dart';
import 'registration_requests_screen.dart';
import 'user_management_screen.dart';

/// Espace d'administration : administrateurs, managers, responsables de
/// zone et HSE.
///
/// Cinq onglets, dans l'ordre du travail : l'accueil dit ce qui attend,
/// les tickets le traitent, les annonces parlent a tous les residents, les
/// residences situent le travail, « Plus » rassemble le reste. Sur telephone, la barre de verre de l'espace resident ; sur
/// ordinateur, une barre laterale qui montre aussi les raccourcis.
class ManagerHomeScreen extends StatefulWidget {
  const ManagerHomeScreen({super.key});

  @override
  State<ManagerHomeScreen> createState() => _ManagerHomeScreenState();
}

class _ManagerHomeScreenState extends State<ManagerHomeScreen> {
  late final AdminStore _store =
      AdminStore(role: context.read<AuthProvider>().userRole);
  final _tickets = AdminTicketsController();
  final _navMinimize = GlassTabBarMinimizeController(
      behavior: GlassBarMinimizeBehavior.onScrollDown);
  final ApiService _api = ApiService();

  int _tab = 0;
  // Un onglet n'est construit qu'a sa premiere visite : l'ouverture de
  // l'administration ne monte plus cinq pages d'un coup.
  final Set<int> _visited = {0};
  int _unread = 0;
  int _pendingRegistrations = 0;
  int _pendingProperties = 0;
  Timer? _poll;
  late final AppLifecycleListener _lifecycle;

  static const _tabTickets = 1,
      _tabNotices = 2,
      _tabResidences = 3,
      _tabMore = 4;

  @override
  void initState() {
    super.initState();
    _store.load();
    _fetchUnread();
    // Les tickets arrivent pendant qu'on travaille : la liste se remet a
    // jour seule, sans tirer pour actualiser.
    _poll = Timer.periodic(const Duration(seconds: 45), (_) {
      if (!mounted) return;
      if (WidgetsBinding.instance.lifecycleState !=
          AppLifecycleState.resumed) {
        return;
      }
      _store.load();
      _fetchUnread();
    });
    // De retour dans l'app, la liste est a jour tout de suite, sans attendre
    // le prochain tour du minuteur.
    _lifecycle = AppLifecycleListener(onResume: () {
      if (!mounted) return;
      _store.load();
      _fetchUnread();
      _fetchPending();
    });
    _fetchPending();
  }

  @override
  void dispose() {
    _poll?.cancel();
    _lifecycle.dispose();
    _navMinimize.dispose();
    _tickets.dispose();
    _store.dispose();
    super.dispose();
  }

  Future<void> _fetchUnread() async {
    try {
      final n = await _api.getUnreadNotificationsCount();
      if (mounted) setState(() => _unread = n);
    } catch (_) {}
  }

  // Demandes qui attendent l'administrateur : elles s'affichent en
  // pastille sur leur entree du menu.
  Future<void> _fetchPending() async {
    if (!_store.isAdmin) return;
    try {
      final (r, p) = await (
        _api.getRegistrationRequests(),
        _api.getPropertyAddRequests(status: 'PENDING'),
      ).wait;
      if (!mounted) return;
      setState(() {
        _pendingRegistrations =
            r.whereType<Map>().where((e) => e['status'] == 'PENDING').length;
        _pendingProperties =
            p.whereType<Map>().where((e) => e['status'] == 'PENDING').length;
      });
    } catch (_) {}
  }

  void _go(int tab) {
    if (tab == _tab) return;
    setState(() {
      _tab = tab;
      _visited.add(tab);
    });
  }

  void _openTickets(AdminTicketFilter filter, {String residenceId = ''}) {
    _tickets.reveal(filter, residenceId: residenceId);
    _go(_tabTickets);
  }

  Future<void> _push(Widget screen) async {
    await adminPush(context, screen);
    if (!mounted) return;
    _fetchUnread();
    _fetchPending();
  }

  void _logout() {
    GiHaptics.select();
    context.read<AuthProvider>().logout();
    Navigator.of(context)
        .pushAndRemoveUntil(AdminRoute(const LoginScreen()), (_) => false);
  }

  // ─── Menus ────────────────────────────────────────────────
  //
  // Toutes les entrees du menu d'origine sont la. Tickets, Annonces,
  // Residences et Statistiques (l'accueil) ont leur onglet ; « Plus » les reprend pour
  // qu'on retrouve le menu complet au meme endroit. La barre laterale de
  // l'ordinateur montre deja les onglets : elle ne les repete pas.

  List<AdminMenuEntry> _management({bool withTabs = true}) => [
        if (withTabs) ...[
          AdminMenuEntry('Tickets', Icons.confirmation_number_outlined,
              () => _go(_tabTickets),
              hint: 'Signalements à assigner et à suivre',
              badge: _store.loading
                  ? 0
                  : _store.count(AdminTicketFilter.toAssign.test)),
          AdminMenuEntry('Résidences', Icons.apartment_outlined,
              () => _go(_tabResidences),
              hint: 'Bâtiments, logements et tickets par site'),
        ],
        AdminMenuEntry('Résidents', Icons.people_outline_rounded,
            () => _push(AdminResidentsScreen(store: _store)),
            hint: 'Annuaire et tickets de chaque résident'),
        if (withTabs)
          AdminMenuEntry('Annonces', Icons.campaign_outlined,
              () => _go(_tabNotices),
              hint: 'Annonces publiées aux résidents'),
        if (withTabs)
          AdminMenuEntry('Statistiques', Icons.bar_chart_rounded,
              () => _go(0),
              hint: 'Tableau de bord et chiffres clés'),
      ];

  List<AdminMenuEntry> get _administration => _store.isAdmin
      ? [
          AdminMenuEntry('Paiements', Icons.account_balance_wallet_outlined,
              () => _push(const RecouvrementFinancialScreen()),
              hint: 'Charges payées et impayées, par résidence'),
          AdminMenuEntry('Employés', Icons.badge_outlined,
              () => _push(const UserManagementScreen()),
              hint: 'Comptes, mots de passe et appareils'),
          AdminMenuEntry('Inscriptions', Icons.person_add_alt_outlined,
              () => _push(const RegistrationRequestsScreen()),
              hint: 'Nouveaux résidents à valider',
              badge: _pendingRegistrations),
          AdminMenuEntry('Ajouts de biens', Icons.add_home_work_outlined,
              () => _push(const PropertyAddRequestsManagementScreen()),
              hint: 'Biens déclarés par les résidents',
              badge: _pendingProperties),
        ]
      : const [];

  List<AdminMenuEntry> get _account => [
        AdminMenuEntry('Notifications', Icons.notifications_none_rounded,
            () => _push(const NotificationsScreen()),
            badge: _unread),
      ];

  // ─── Build ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: _store, builder: (context, _) => _build(context));

  Widget _build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final role = context.watch<AuthProvider>().userRole;
    final c = GiColors.of(context);
    final wide = isAdminWide(context);
    final toAssign =
        _store.loading ? 0 : _store.count(AdminTicketFilter.toAssign.test);

    final pages = [
      AdminDashboardScreen(
        store: _store,
        user: user,
        unread: _unread,
        openTickets: _openTickets,
        openResidences: () => _go(_tabResidences),
        openProfile: () => _go(_tabMore),
        onNotificationsClosed: _fetchUnread,
      ),
      AdminTicketsScreen(store: _store, controller: _tickets),
      const AdminNoticesScreen(asTab: true),
      AdminResidencesScreen(store: _store),
      AdminMoreScreen(
        user: user,
        role: role,
        management: _management(),
        administration: _administration,
        account: _account,
        onLogout: _logout,
      ),
    ];

    // Changement d'onglet en fondu glisse, plutot qu'un remplacement sec.
    // Les onglets restent montes : chacun garde sa position de defilement.
    //
    // Le fondu reste hors du TickerMode : coupe des qu'on quitte l'onglet,
    // il figeait la page quittee a pleine opacite, par-dessus l'onglet
    // choisi. Seule la page elle-meme se met en sommeil.
    final body = Stack(
      children: [
        for (var i = 0; i < pages.length; i++)
          IgnorePointer(
            ignoring: i != _tab,
            child: !_visited.contains(i)
                ? const SizedBox.shrink()
                : AnimatedOpacity(
              opacity: i == _tab ? 1 : 0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              child: AnimatedSlide(
                offset: i == _tab ? Offset.zero : const Offset(0, 0.015),
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                child: TickerMode(enabled: i == _tab, child: pages[i]),
              ),
            ),
          ),
      ],
    );

    if (wide) {
      return Scaffold(
        backgroundColor: c.scaffold,
        body: Row(
          children: [
            _Sidebar(
              user: user,
              role: role,
              current: _tab,
              onTab: _go,
              ticketsBadge: toAssign,
              management: _management(withTabs: false),
              administration: _administration,
              account: _account,
              onLogout: _logout,
            ),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: c.scaffold,
      extendBody: true,
      body: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          _navMinimize.handleNotification(n);
          return false;
        },
        child: body,
      ),
      bottomNavigationBar: GiBottomNav(
        currentIndex: _tab,
        minimizeController: _navMinimize,
        onTap: _go,
        items: [
          const GiNavItem(
              asset: 'assets/figma/icons/nav_home.svg',
              activeAsset: 'assets/figma/icons/nav_home_fill.svg',
              label: 'Accueil'),
          GiNavItem(
              asset: 'assets/figma/icons/nav_report.svg',
              activeAsset: 'assets/figma/icons/nav_report_fill.svg',
              label: 'Tickets',
              badge: toAssign),
          const GiNavItem(
              asset: 'assets/figma/icons/nav_notice.svg',
              activeAsset: 'assets/figma/icons/nav_notice_fill.svg',
              label: 'Annonces'),
          const GiNavItem(
              asset: 'assets/figma/icons/nav_residence.svg',
              activeAsset: 'assets/figma/icons/nav_residence_fill.svg',
              label: 'Résidences'),
          GiNavItem(
              asset: 'assets/figma/icons/nav_more.svg',
              label: 'Plus',
              badge: _unread + _pendingRegistrations + _pendingProperties),
        ],
      ),
    );
  }
}

/// Barre laterale de l'ordinateur : marque, onglets, raccourcis, compte.
class _Sidebar extends StatelessWidget {
  final Map? user;
  final String role;
  final int current;
  final ValueChanged<int> onTab;
  final int ticketsBadge;
  final List<AdminMenuEntry> management;
  final List<AdminMenuEntry> administration;
  final List<AdminMenuEntry> account;
  final VoidCallback onLogout;

  const _Sidebar({
    required this.user,
    required this.role,
    required this.current,
    required this.onTab,
    required this.ticketsBadge,
    required this.management,
    required this.administration,
    required this.account,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    final brightness = Theme.of(context).brightness;
    final tabs = [
      (
        Icons.space_dashboard_outlined,
        Icons.space_dashboard_rounded,
        'Accueil',
        0
      ),
      (
        Icons.confirmation_number_outlined,
        Icons.confirmation_number_rounded,
        'Tickets',
        ticketsBadge
      ),
      (Icons.campaign_outlined, Icons.campaign_rounded, 'Annonces', 0),
      (Icons.apartment_outlined, Icons.apartment_rounded, 'Résidences', 0),
    ];

    Widget heading(String text) => Padding(
          padding: const EdgeInsets.fromLTRB(14, 20, 14, 8),
          child: Text(text.toUpperCase(),
              style: FigText.caption.copyWith(
                  fontSize: 11,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w600,
                  color: c.textFaint)),
        );

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: c.card,
        border: Border(right: BorderSide(color: c.innerBorder)),
      ),
      child: SafeArea(
        right: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 22),
            Center(
              child: GiBrandLogo(
                  height: 76, color: GiBrandLogo.colorFor(brightness)),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (var i = 0; i < tabs.length; i++)
                    _SideItem(
                      icon: i == current ? tabs[i].$2 : tabs[i].$1,
                      label: tabs[i].$3,
                      badge: tabs[i].$4,
                      selected: i == current,
                      onTap: () => onTab(i),
                    ),
                  heading('Gestion'),
                  for (final e in management)
                    _SideItem(icon: e.icon, label: e.label, badge: e.badge, onTap: e.onTap),
                  if (administration.isNotEmpty) ...[
                    heading('Administration'),
                    for (final e in administration)
                      _SideItem(icon: e.icon, label: e.label, badge: e.badge, onTap: e.onTap),
                  ],
                  heading('Compte'),
                  for (final e in account)
                    _SideItem(
                        icon: e.icon,
                        label: e.label,
                        badge: e.badge,
                        onTap: e.onTap),
                  _SideItem(
                    icon: current == 4
                        ? Icons.settings_rounded
                        : Icons.settings_outlined,
                    label: 'Profil et réglages',
                    selected: current == 4,
                    onTap: () => onTab(4),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: c.scaffold,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: c.innerBorder),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: FigBrand.amber.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(adminInitials(user),
                            style: FigText.label.copyWith(
                                fontWeight: FontWeight.w700,
                                color: FigBrand.amber)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                PersonName.format(
                                    user?['name'] ?? user?['fullName']),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: FigText.bodyActive
                                    .copyWith(color: c.textBody)),
                            Text(adminRoleLabel(role, user),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: FigText.caption.copyWith(
                                    fontSize: 11, color: c.textMuted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  AdminLogoutButton(onLogout: onLogout, compact: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SideItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final int badge;
  final VoidCallback onTap;

  const _SideItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: GiPressable(
        pressedScale: 0.97,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: selected
                ? FigBrand.amber.withValues(alpha: 0.14)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon,
                  size: 20, color: selected ? FigBrand.amber : c.textMuted),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: (selected ? FigText.bodyActive : FigText.body)
                        .copyWith(
                            fontSize: 14,
                            color: selected ? FigBrand.amber : c.textBody)),
              ),
              if (badge > 0)
                Container(
                  constraints: const BoxConstraints(minWidth: 20),
                  height: 20,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: FigBrand.amber,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('$badge',
                      style: FigText.caption.copyWith(
                          color: Colors.black, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
