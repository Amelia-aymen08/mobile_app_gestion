import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'admin_notices_screen.dart';
import 'dashboard_screen.dart';
import 'notifications_screen.dart';
import 'property_add_requests_management_screen.dart';
import 'recouvrement_financial_screen.dart';
import 'registration_requests_screen.dart';
import 'residences_list_screen.dart';
import 'residents_list_screen.dart';
import 'tickets_screen.dart';
import 'user_management_screen.dart';

class ManagerHomeScreen extends StatefulWidget {
  const ManagerHomeScreen({super.key});

  @override
  State<ManagerHomeScreen> createState() => _ManagerHomeScreenState();
}

class _ManagerHomeScreenState extends State<ManagerHomeScreen> {
  int _tab = 0;

  Future<void> _open(Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final role = auth.userRole;
    return Scaffold(
      backgroundColor: brandCream,
      body: IndexedStack(
        index: _tab,
        children: [
          const DashboardScreen(),
          const TicketsScreen(),
          const AdminNoticesScreen(),
          _AdminMenu(
              user: auth.user, role: role, open: _open, logout: auth.logout),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (value) => setState(() => _tab = value),
        backgroundColor: brandNavy,
        indicatorColor: Colors.transparent,
        height: 74,
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view_rounded),
              label: 'ACCUEIL'),
          NavigationDestination(
              icon: Icon(Icons.confirmation_number_outlined),
              selectedIcon: Icon(Icons.confirmation_number_rounded),
              label: 'TICKETS'),
          NavigationDestination(
              icon: Icon(Icons.campaign_outlined),
              selectedIcon: Icon(Icons.campaign_rounded),
              label: 'AVIS'),
          NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view_rounded),
              label: 'MENU'),
        ],
      ),
    );
  }
}

class _AdminMenu extends StatelessWidget {
  final Map? user;
  final String role;
  final Future<void> Function(Widget) open;
  final Future<void> Function() logout;

  const _AdminMenu(
      {required this.user,
      required this.role,
      required this.open,
      required this.logout});

  bool get isAdmin => role == 'ADMIN';
  String get initials {
    final words = '${user?['name'] ?? ''}'
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    return words.take(2).map((word) => word[0]).join().toUpperCase();
  }

  String get roleLabel {
    if (role == 'ADMIN') return 'Administrateur';
    if (role == 'RESPONSABLE_ZONE') {
      final zone = (user?['zone'] ?? '').toString().trim();
      if (zone.isEmpty) return 'Responsable de zone';
      final label = zone.toUpperCase() == 'ALL' ? 'toutes les zones' : zone;
      return 'Responsable $label';
    }
    return 'Manager';
  }

  @override
  Widget build(BuildContext context) {
    final items = <_MenuItem>[
      const _MenuItem(
          'Tickets', Icons.confirmation_number_outlined, TicketsScreen()),
      const _MenuItem(
          'Résidences', Icons.apartment_outlined, ResidencesListScreen()),
      const _MenuItem('Résidents', Icons.badge_outlined, ResidentsListScreen()),
      if (isAdmin)
        const _MenuItem('Finances', Icons.account_balance_wallet_outlined,
            RecouvrementFinancialScreen()),
      if (isAdmin)
        const _MenuItem(
            'Employés', Icons.groups_outlined, UserManagementScreen()),
      if (isAdmin)
        const _MenuItem('Inscriptions', Icons.person_add_alt_outlined,
            RegistrationRequestsScreen()),
      if (isAdmin)
        const _MenuItem('Ajouts de biens', Icons.add_home_work_outlined,
            PropertyAddRequestsManagementScreen()),
      const _MenuItem('Avis', Icons.campaign_outlined, AdminNoticesScreen()),
      const _MenuItem(
          'Statistiques', Icons.bar_chart_outlined, DashboardScreen()),
      const _MenuItem('Notifications', Icons.notifications_none_rounded,
          NotificationsScreen()),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
            child: Row(children: [
              Image.asset('assets/global_immo_logo_dark.png',
                  width: 112, fit: BoxFit.contain),
              const Spacer(),
              const Icon(Icons.close, color: Color(0xFF666666), size: 24),
            ]),
          ),
          const Divider(height: 1, color: Color(0xFFE6DFD2)),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE6DFD2)),
                  borderRadius: BorderRadius.circular(4)),
              child: Row(children: [
                CircleAvatar(
                    radius: 21,
                    backgroundColor: const Color(0xFFFFF2D5),
                    child: Text(initials,
                        style: const TextStyle(
                            color: brandAmber, fontWeight: FontWeight.w800))),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${user?['name'] ?? ''}',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: brandNavy)),
                  Text(roleLabel,
                      style:
                          const TextStyle(fontSize: 11, color: brandGoldDark)),
                ]),
              ]),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const Padding(
                    padding: EdgeInsets.fromLTRB(20, 8, 20, 10),
                    child: Row(children: [
                      Icon(Icons.apartment_outlined,
                          size: 17, color: brandNavy),
                      SizedBox(width: 10),
                      Text('Gestion',
                          style: TextStyle(fontSize: 15, color: brandNavy))
                    ])),
                Container(
                  color: const Color(0xFFF4F4F4),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                      children: items
                          .take(isAdmin ? 7 : 3)
                          .map((item) => _row(item))
                          .toList()),
                ),
                ...items.skip(isAdmin ? 7 : 3).map((item) => _row(item)),
                _profileRow(context),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF9AA0A6)),
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            leading:
                const Icon(Icons.logout_rounded, size: 18, color: brandNavy),
            title: const Text('Déconnexion',
                style: TextStyle(fontSize: 14, color: brandNavy)),
            onTap: () async {
              await logout();
              if (context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
          ),
        ]),
      ),
    );
  }

  Widget _row(_MenuItem item) => ListTile(
        dense: true,
        minLeadingWidth: 20,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        leading: Icon(item.icon, size: 18, color: brandNavy),
        title: Text(item.label,
            style: const TextStyle(fontSize: 14, color: Color(0xFF3A3A3A))),
        onTap: () => open(item.screen),
      );

  Widget _profileRow(BuildContext context) => ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        leading: const Icon(Icons.person_outline, size: 18, color: brandNavy),
        title: const Text('Profil',
            style: TextStyle(fontSize: 14, color: Color(0xFF3A3A3A))),
        onTap: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: brandCream,
          builder: (_) => SafeArea(
              child: Padding(
            padding: const EdgeInsets.all(26),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              CircleAvatar(
                  radius: 34,
                  backgroundColor: const Color(0xFFFFF2D5),
                  child: Text(initials,
                      style: const TextStyle(
                          color: brandAmber,
                          fontSize: 22,
                          fontWeight: FontWeight.w800))),
              const SizedBox(height: 12),
              Text('${user?['name'] ?? ''}',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: brandNavy)),
              Text('${user?['email'] ?? ''}',
                  style: const TextStyle(color: brandGoldDark)),
              const SizedBox(height: 8),
              Chip(label: Text(roleLabel)),
              const SizedBox(height: 20),
            ]),
          )),
        ),
      );
}

class _MenuItem {
  final String label;
  final IconData icon;
  final Widget screen;
  const _MenuItem(this.label, this.icon, this.screen);
}
