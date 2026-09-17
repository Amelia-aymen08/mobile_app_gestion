// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'tickets_screen.dart';

class IntervenantHomeScreen extends StatefulWidget {
  const IntervenantHomeScreen({super.key});
  @override
  State<IntervenantHomeScreen> createState() => _IntervenantHomeScreenState();
}

class _IntervenantHomeScreenState extends State<IntervenantHomeScreen> {
  int _tab = 0;

  // ─── Build ────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Scaffold(
      backgroundColor: brandBackground,
      body: IndexedStack(
        index: _tab,
        children: [
          const TicketsScreen(),
          _profilTab(user),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shadowColor: Colors.black12,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment_rounded),
            label: 'Mes Tickets',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  // ─── Profil tab ───────────────────────────────────────────
  Widget _profilTab(Map? user) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: const BoxDecoration(
                      color: brandBlue, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: const Icon(Icons.handyman_rounded,
                      size: 38, color: Colors.white),
                ),
                const SizedBox(height: 14),
                Text(
                  user?['name']?.toString() ?? '',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w900, color: brandBlue),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: brandGold.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    (user?['profession'] ?? 'Intervenant').toString(),
                    style: const TextStyle(
                        fontSize: 13, color: brandBlue, fontWeight: FontWeight.w700),
                  ),
                ),
                if (user?['email'] != null) ...[
                  const SizedBox(height: 6),
                  Text(user!['email'].toString(),
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF94A3B8))),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Se déconnecter'),
            onPressed: () {
              context.read<AuthProvider>().logout();
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFDC2626),
              side: const BorderSide(color: Color(0xFFDC2626)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      );
}
