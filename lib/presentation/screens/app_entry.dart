import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../../data/api_service.dart';
import 'login_screen.dart';
import 'resident_home_screen.dart';
import 'manager_home_screen.dart';
import 'intervenant_home_screen.dart';
import 'change_password_screen.dart';
import 'recouvrement_home_screen.dart';
import 'gestionnaire_tag_home_screen.dart';
import 'splash_screen.dart';
import 'onboarding_screen.dart';
import '../services/system_notification_service.dart';

class AppEntry extends StatefulWidget {
  const AppEntry({super.key});

  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> {
  bool _ready = false;
  bool _showOnboarding = false;
  final ApiService _api = ApiService();
  Timer? _notificationTimer;
  final Set<String> _seenUnreadIds = {};
  String? _pollingUserId;
  bool _initializedUnreadSnapshot = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final auth = context.read<AuthProvider>();
    final prefs = await SharedPreferences.getInstance();
    await auth.restoreSession();
    final onboardingDone = prefs.getBool('onboarding_done') ?? false;
    // AIDE AU TEST — a retirer avant la mise en production.
    // Sur le web, ?onboarding=1 force l'affichage de l'onboarding meme s'il a
    // deja ete vu, pour pouvoir le revoir a chaque rafraichissement.
    final forced = Uri.base.queryParameters['onboarding'] == '1';
    if (forced || (!onboardingDone && !auth.isAuthenticated)) {
      _showOnboarding = true;
    }
    if (mounted) setState(() => _ready = true);
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (mounted) setState(() => _showOnboarding = false);
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    super.dispose();
  }

  void _configureNotificationPolling(AuthProvider auth) {
    if (!auth.isAuthenticated || auth.user == null) {
      _notificationTimer?.cancel();
      _notificationTimer = null;
      _pollingUserId = null;
      _seenUnreadIds.clear();
      _initializedUnreadSnapshot = false;
      return;
    }

    final userId = (auth.user!['id'] ?? '').toString();
    if (userId.isEmpty) return;

    if (_pollingUserId == userId && _notificationTimer != null) return;

    _notificationTimer?.cancel();
    _pollingUserId = userId;
    _seenUnreadIds.clear();
    _initializedUnreadSnapshot = false;

    _pollNotifications();
    _notificationTimer = Timer.periodic(
        const Duration(seconds: 20), (_) => _pollNotifications());
  }

  Future<void> _pollNotifications() async {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) return;

    try {
      final list = await _api.getNotifications();
      final unreadIds = list
          .whereType<Map>()
          .where((n) => n['isRead'] != true)
          .map((n) => (n['id'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toSet();

      if (!_initializedUnreadSnapshot) {
        // Show system notifications for unread items created in the last 5 minutes,
        // so notifications received just before the app opened appear in the status bar.
        final recentCutoff =
            DateTime.now().subtract(const Duration(minutes: 5));
        final notifById = <String, Map>{};
        for (final n in list.whereType<Map>()) {
          final id = (n['id'] ?? '').toString();
          if (id.isNotEmpty) notifById[id] = n;
        }
        for (final id in unreadIds) {
          final notif = notifById[id] ?? {};
          DateTime? createdAt;
          try {
            createdAt = DateTime.parse((notif['createdAt'] ?? '').toString());
          } catch (_) {}
          if (createdAt != null && createdAt.isAfter(recentCutoff)) {
            final title =
                (notif['title'] ?? 'Nouvelle notification').toString();
            final message = (notif['message'] ?? '').toString();
            await SystemNotificationService.instance.show(
              key: id,
              title: title,
              message: message.isNotEmpty ? message : title,
            );
          }
        }
        _seenUnreadIds
          ..clear()
          ..addAll(unreadIds);
        _initializedUnreadSnapshot = true;
        return;
      }

      final newUnread = unreadIds.difference(_seenUnreadIds);
      if (newUnread.isNotEmpty) {
        final notifById = <String, Map>{};
        for (final n in list.whereType<Map>()) {
          final id = (n['id'] ?? '').toString();
          if (id.isNotEmpty) notifById[id] = n;
        }
        for (final id in newUnread) {
          final notif = notifById[id] ?? {};
          final title = (notif['title'] ?? 'Nouvelle notification').toString();
          final message = (notif['message'] ?? '').toString();
          final body = message.isNotEmpty ? message : title;
          await SystemNotificationService.instance.show(
            key: id,
            title: title,
            message: body,
          );
        }
      }

      _seenUnreadIds
        ..clear()
        ..addAll(unreadIds);
    } catch (_) {
      // silent polling failure
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    _configureNotificationPolling(auth);

    if (!_ready) return const SplashScreen();

    if (_showOnboarding) {
      return OnboardingScreen(onComplete: _completeOnboarding);
    }

    if (!auth.isAuthenticated) return const LoginScreen();
    if (auth.mustChangePassword) return const ChangePasswordScreen();

    final role = auth.userRole;
    if (role == 'INTERVENANT') return const IntervenantHomeScreen();
    if (role == 'RECOUVREMENT') return const RecouvrementHomeScreen();
    if (role == 'GESTIONNAIRE_TAG') return const GestionnaireTagHomeScreen();
    if (role == 'ADMIN' ||
        role == 'RESPONSABLE_ZONE' ||
        role == 'MANAGER' ||
        role == 'HSE') {
      return const ManagerHomeScreen();
    }
    return const ResidentHomeScreen();
  }
}
