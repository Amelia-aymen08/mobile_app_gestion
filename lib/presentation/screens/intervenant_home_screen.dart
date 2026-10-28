import 'dart:async';

import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:provider/provider.dart';

import '../../data/api_service.dart';
import '../providers/auth_provider.dart';
import '../services/gi_haptics.dart';
import '../theme/gi_colors.dart';
import '../theme/ticket_status.dart';
import '../widgets/gi_bottom_nav.dart';
import 'admin/admin_ui.dart';
import 'intervenant/intervenant_missions_screen.dart';
import 'intervenant/intervenant_profile_screen.dart';
import 'intervenant/intervenant_store.dart';
import 'intervenant/intervenant_today_screen.dart';
import 'login_screen.dart';
import 'notifications_screen.dart';

/// Espace de l'intervenant : les missions que l'administration lui confie.
///
/// Trois onglets, dans l'ordre de sa journee : l'accueil montre la mission
/// du moment et son bouton, Missions les range par pile, Profil garde ses
/// reglages. Commencer et terminer se font en un geste, depuis n'importe
/// lequel des trois : c'est ce qui previent l'administration et le
/// resident, sans appel ni message.
class IntervenantHomeScreen extends StatefulWidget {
  const IntervenantHomeScreen({super.key});

  @override
  State<IntervenantHomeScreen> createState() => _IntervenantHomeScreenState();
}

class _IntervenantHomeScreenState extends State<IntervenantHomeScreen> {
  final _store = IntervenantStore();
  final _filter = ValueNotifier(MissionFilter.todo);
  final _navMinimize = GlassTabBarMinimizeController(
      behavior: GlassBarMinimizeBehavior.onScrollDown);
  final ApiService _api = ApiService();

  int _tab = 0;
  int _unread = 0;
  Timer? _poll;
  late final AppLifecycleListener _lifecycle;

  // Missions deja vues : une nouvelle venue s'annonce en bandeau.
  Set<String>? _known;

  static const _tabMissions = 1;

  @override
  void initState() {
    super.initState();
    _store.addListener(_announceNew);
    _refresh();
    // Les missions arrivent pendant la journee : la liste se tient a jour
    // seule, sans tirer pour actualiser.
    _poll = Timer.periodic(const Duration(seconds: 45), (_) {
      if (!mounted) return;
      if (WidgetsBinding.instance.lifecycleState !=
          AppLifecycleState.resumed) {
        return;
      }
      _refresh();
    });
    _lifecycle = AppLifecycleListener(onResume: () {
      if (mounted) _refresh();
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _lifecycle.dispose();
    _navMinimize.dispose();
    _store.removeListener(_announceNew);
    _store.dispose();
    _filter.dispose();
    super.dispose();
  }

  void _refresh() {
    _store.load();
    _fetchUnread();
  }

  Future<void> _fetchUnread() async {
    try {
      final n = await _api.getUnreadNotificationsCount();
      if (mounted) setState(() => _unread = n);
    } catch (_) {}
  }

  void _announceNew() {
    if (_store.loading || _store.error != null) return;
    final ids = {for (final t in _store.toStart) TicketFields.id(t)};
    final known = _known;
    _known = {...?known, ...ids};
    if (known == null) return;
    final fresh = _store.toStart
        .where((t) => !known.contains(TicketFields.id(t)))
        .toList();
    if (fresh.isEmpty || !mounted) return;
    showAdminToast(
        context,
        fresh.length == 1
            ? 'Nouvelle mission : ${TicketFields.title(fresh.first)}'
            : '${fresh.length} nouvelles missions');
  }

  void _go(int tab) {
    if (tab == _tab) return;
    setState(() => _tab = tab);
  }

  void _openMissions(MissionFilter f) {
    _filter.value = f;
    _go(_tabMissions);
  }

  Future<void> _openNotifications() async {
    await adminPush(context, const NotificationsScreen());
    if (mounted) _refresh();
  }

  void _logout() {
    GiHaptics.select();
    context.read<AuthProvider>().logout();
    Navigator.of(context)
        .pushAndRemoveUntil(AdminRoute(const LoginScreen()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final c = GiColors.of(context);

    final pages = [
      IntervenantTodayScreen(
        store: _store,
        user: user,
        unread: _unread,
        openNotifications: _openNotifications,
        openMissions: _openMissions,
      ),
      IntervenantMissionsScreen(store: _store, filter: _filter),
      IntervenantProfileScreen(
        store: _store,
        user: user,
        unread: _unread,
        openNotifications: _openNotifications,
        onLogout: _logout,
      ),
    ];

    // Meme passage d'onglet que l'administration : fondu glisse, pages
    // gardees montees pour que chacune retrouve sa position.
    final body = Stack(
      children: [
        for (var i = 0; i < pages.length; i++)
          IgnorePointer(
            ignoring: i != _tab,
            child: AnimatedOpacity(
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
      bottomNavigationBar: ListenableBuilder(
        listenable: _store,
        builder: (context, _) => GiBottomNav(
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
                label: 'Missions',
                badge: _store.loading ? 0 : _store.toStart.length),
            GiNavItem(
                asset: 'assets/figma/icons/nav_more.svg',
                label: 'Profil',
                badge: _unread),
          ],
        ),
      ),
    );
  }
}
