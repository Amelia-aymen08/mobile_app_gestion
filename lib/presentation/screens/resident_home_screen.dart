// ignore_for_file: use_build_context_synchronously
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/api_service.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../theme/residence_images.dart';
import 'login_screen.dart';
import 'my_properties_screen.dart';
import 'my_charges_screen.dart';
import 'notifications_screen.dart';
import 'resident_profile_screen.dart';
import 'change_password_screen.dart';
import 'property_add_request_screen.dart';
import 'resident_tickets_screen.dart';
import 'household_members_screen.dart';
import 'notices_screen.dart';

class ResidentHomeScreen extends StatefulWidget {
  const ResidentHomeScreen({super.key});
  @override
  State<ResidentHomeScreen> createState() => _ResidentHomeScreenState();
}

class _ResidentHomeScreenState extends State<ResidentHomeScreen> {
  final ApiService _api = ApiService();
  int _tab = 0;

  List<dynamic> _properties = [];
  Map<String, dynamic> _chargesSummary = {};
  List<dynamic> _tickets = [];
  bool _loadingDashboard = true;

  int _unreadCount = 0;
  Timer? _notifTimer;
  bool _checkedUrgent = false;

  final _residenceCarouselController = PageController();
  Timer? _carouselTimer;
  int _carouselPage = 0;

  @override
  void initState() {
    super.initState();
    _fetchDashboard();
    _fetchUnread();
    _notifTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      if (mounted) _fetchUnread();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkUrgent());
  }

  @override
  void dispose() {
    _notifTimer?.cancel();
    _carouselTimer?.cancel();
    _residenceCarouselController.dispose();
    super.dispose();
  }

  void _restartCarouselAutoplay() {
    _carouselTimer?.cancel();
    if (_properties.length < 2) return;
    _carouselTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_residenceCarouselController.hasClients) return;
      final next = (_carouselPage + 1) % _properties.length;
      _residenceCarouselController.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> _fetchUnread() async {
    try {
      final list = await _api.getNotifications();
      if (!mounted) return;
      setState(() => _unreadCount =
          list.whereType<Map>().where((n) => n['isRead'] != true).length);
    } catch (_) {
      try {
        final c = await _api.getUnreadNotificationsCount();
        if (mounted) setState(() => _unreadCount = c);
      } catch (_) {}
    }
  }

  Future<void> _fetchDashboard() async {
    setState(() => _loadingDashboard = true);
    try {
      final user = context.read<AuthProvider>().user;
      final email = (user?['email'] ?? '').toString();
      final results = await Future.wait([
        email.isNotEmpty
            ? _api.getMyProperties(email)
            : Future.value(<dynamic>[]),
        _api.getMyChargesSummary(),
        _api.getTickets(),
      ]);
      if (!mounted) return;
      setState(() {
        _properties = results[0] as List<dynamic>;
        _chargesSummary = Map<String, dynamic>.from(results[1] as Map);
        _tickets = (results[2] as List<dynamic>)
          ..sort((a, b) => (b is Map ? b['createdAt'] : '')
              .toString()
              .compareTo((a is Map ? a['createdAt'] : '').toString()));
        _loadingDashboard = false;
      });
      _carouselPage = 0;
      _restartCarouselAutoplay();
    } catch (_) {
      if (mounted) setState(() => _loadingDashboard = false);
    }
  }

  Future<void> _checkUrgent() async {
    if (_checkedUrgent) return;
    _checkedUrgent = true;
    try {
      final s = await _api.getMyChargesSummary();
      final days = int.tryParse((s['daysRemaining'] ?? '').toString());
      final raw = s['nextPaymentDate']?.toString();
      if (days == null || raw == null || days > 10 || days < 0 || !mounted) {
        return;
      }
      final due = DateTime.tryParse(raw)?.toLocal();
      final label = due != null ? _formatDate(due) : raw;
      final dark = Theme.of(context).brightness == Brightness.dark;
      await showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: dark ? darkCard : Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                      color: Color(0xFFE0362B), shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: const Icon(Icons.priority_high_rounded,
                      color: Colors.white, size: 34),
                ),
                const SizedBox(height: 18),
                Text('Paiement urgent',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: dark ? Colors.white : brandNavy)),
                const SizedBox(height: 10),
                Text('Votre prochain paiement est dû le $label.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: dark ? darkMuted : const Color(0xFF6B7280),
                        fontSize: 14)),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: brandAmber,
                          side: const BorderSide(color: brandAmber, width: 1.5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Fermer',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() => _tab = 3);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brandAmber,
                          foregroundColor: brandNavy,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                        child: const Text('Voir',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    } catch (_) {}
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _timeAgo(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final d = DateTime.tryParse(iso);
    if (d == null) return '';
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays} j';
    return _formatDate(d);
  }

  Color _statusColor(String? s) {
    switch (s) {
      case 'Signalé':
        return const Color(0xFFF59E0B);
      case 'En cours':
        return const Color(0xFF3B82F6);
      case 'Terminé':
        return const Color(0xFF16A34A);
      case 'SAV':
        return const Color(0xFF8B5CF6);
      case 'Rejeté':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF9AA3AB);
    }
  }

  String? _imgUrl(dynamic raw) {
    final s = (raw ?? '').toString().trim();
    if (s.isEmpty) return null;
    if (s.startsWith('http')) return s;
    final base = _api.baseUrl.replaceAll(RegExp(r'/api/?$'), '');
    return '$base/${s.startsWith('/') ? s.substring(1) : s}';
  }

  Future<void> _push(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    if (mounted) _fetchUnread();
  }

  Future<void> _confirmLogout() async {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? Colors.white : brandNavy;
    final muted = dark ? darkMuted : const Color(0xFF6B7280);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: dark ? darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                    color: Color(0xFFE0362B), shape: BoxShape.circle),
                alignment: Alignment.center,
                child: const Icon(Icons.priority_high_rounded,
                    color: Colors.white, size: 34),
              ),
              const SizedBox(height: 18),
              Text('Se déconnecter ?',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800, color: fg)),
              const SizedBox(height: 10),
              Text(
                  'Voulez-vous vraiment vous déconnecter ? Vous pourrez vous reconnecter à tout moment.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: muted, fontSize: 14)),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: brandAmber,
                        side: const BorderSide(color: brandAmber, width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Annuler',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandAmber,
                        foregroundColor: brandNavy,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      child: const Text('Se déconnecter',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed == true) _logout();
  }

  void _logout() {
    context.read<AuthProvider>().logout();
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  // ─── Build ────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: dark ? darkSurface : brandCream,
      extendBody: true,
      body: IndexedStack(
        index: _tab,
        children: [
          _homeTab(user, dark),
          const NoticesScreen(),
          const ResidentTicketsScreen(),
          const MyChargesScreen(),
          _moreTab(user, dark),
        ],
      ),
      bottomNavigationBar: _buildNavBar(dark),
    );
  }

  Widget _buildNavBar(bool dark) {
    final items = [
      const _NavItem(
          icon: Icons.home_outlined,
          activeIcon: Icons.home_rounded,
          label: 'Accueil'),
      const _NavItem(
          icon: Icons.campaign_outlined,
          activeIcon: Icons.campaign_rounded,
          label: 'Avis'),
      const _NavItem(
          icon: Icons.add_circle_outline,
          activeIcon: Icons.add_circle_rounded,
          label: 'Signaler'),
      const _NavItem(
          icon: Icons.credit_card_outlined,
          activeIcon: Icons.credit_card_rounded,
          label: 'Paiement'),
      const _NavItem(
          icon: Icons.more_horiz_rounded,
          activeIcon: Icons.more_horiz_rounded,
          label: 'Plus'),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      decoration: BoxDecoration(
        color: dark ? darkCard : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.40 : 0.12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          )
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final item = items[i];
          final active = _tab == i;
          return GestureDetector(
            onTap: () => setState(() => _tab = i),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: active
                  ? BoxDecoration(
                      color: brandAmber.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                    )
                  : null,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        active ? item.activeIcon : item.icon,
                        color: active
                            ? brandAmber
                            : (dark ? darkMuted : const Color(0xFF6B7280)),
                        size: 24,
                      ),
                      if (i == 4 && _unreadCount > 0)
                        Positioned(
                          top: -4,
                          right: -6,
                          child: Container(
                            width: 16,
                            height: 16,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: Color(0xFFDC2626),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                                '${_unreadCount > 9 ? '9+' : _unreadCount}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.label,
                    style: TextStyle(
                      color: active
                          ? brandAmber
                          : (dark ? darkMuted : const Color(0xFF6B7280)),
                      fontSize: 10,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // ─── Tab 0 — Accueil ─────────────────────────────────────
  Widget _homeTab(Map? user, bool dark) {
    final firstName = (user?['name'] ?? '').toString().split(' ').first;
    final fg = dark ? Colors.white : brandNavy;
    final muted = dark ? darkMuted : const Color(0xFF6B7280);

    final openTickets = _tickets
        .whereType<Map>()
        .where((t) =>
            !['Terminé', 'Rejeté'].contains((t['status'] ?? '').toString()))
        .toList();
    final inProgressTickets = _tickets
        .whereType<Map>()
        .where((t) => (t['status'] ?? '').toString() == 'En cours')
        .toList();

    final ownerStatus =
        (_chargesSummary['ownerStatus'] ?? _chargesSummary['status'] ?? '')
            .toString();
    final annualAmount = _chargesSummary['annualAmount'];
    final nextPaymentRaw = _chargesSummary['nextPaymentDate']?.toString();
    final nextPaymentDate = nextPaymentRaw != null
        ? DateTime.tryParse(nextPaymentRaw)?.toLocal()
        : null;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => Future.wait([_fetchDashboard(), _fetchUnread()]),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          children: [
            // ── Header ──────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Bienvenue ${firstName.isNotEmpty ? firstName : ''}',
                    style: TextStyle(
                        color: fg, fontWeight: FontWeight.w900, fontSize: 24),
                  ),
                ),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _iconButton(
                      icon: Icons.notifications_outlined,
                      dark: dark,
                      onTap: () => _push(const NotificationsScreen()),
                    ),
                    if (_unreadCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: const BoxDecoration(
                              color: Color(0xFFDC2626), shape: BoxShape.circle),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 10),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (dark ? Colors.white : brandNavy)
                        .withValues(alpha: 0.08),
                    border: Border.all(color: brandAmber, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.person_rounded, color: fg, size: 22),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // ── My Residence(s) carousel ────────────────
            if (_properties.isNotEmpty)
              _residenceCarousel(ownerStatus, dark, fg, muted)
            else if (_loadingDashboard)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
            const SizedBox(height: 14),

            // ── Stat cards ──────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _statCard(
                    icon: Icons.account_balance_wallet_outlined,
                    iconColor: brandAmber,
                    label: 'Prochain paiement',
                    value: annualAmount != null ? '$annualAmount DZD' : '—',
                    sub: nextPaymentDate != null
                        ? 'Échéance : ${_formatDate(nextPaymentDate)}'
                        : (ownerStatus.isNotEmpty ? ownerStatus : null),
                    subColor: brandAmber,
                    dark: dark,
                    fg: fg,
                    muted: muted,
                    onTap: () => setState(() => _tab = 3),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard(
                    icon: Icons.error_outline_rounded,
                    iconColor: const Color(0xFFE0362B),
                    label: 'Signalements',
                    value:
                        '${openTickets.length} ouvert${openTickets.length > 1 ? 's' : ''}',
                    sub: inProgressTickets.isNotEmpty
                        ? '${inProgressTickets.length} en cours'
                        : null,
                    subColor: const Color(0xFFE0362B),
                    dark: dark,
                    fg: fg,
                    muted: muted,
                    onTap: () => setState(() => _tab = 2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // ── Quick actions ──────────────────────────
            Text('Actions rapides',
                style: TextStyle(
                    color: fg, fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 12),
            _quickActionsGrid(dark, fg),
            const SizedBox(height: 24),

            // ── Recent activity ────────────────────────
            if (_tickets.isNotEmpty) ...[
              Text('Activité récente',
                  style: TextStyle(
                      color: fg, fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 12),
              ..._tickets.take(3).map((t) {
                if (t is! Map) return const SizedBox.shrink();
                final status = (t['status'] ?? '').toString();
                final title =
                    (t['type'] ?? t['title'] ?? 'Signalement').toString();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () => setState(() => _tab = 2),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: dark ? darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                                color: _statusColor(status),
                                shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: fg,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14)),
                          ),
                          Text(_timeAgo(t['createdAt']?.toString()),
                              style: TextStyle(color: muted, fontSize: 11)),
                          const SizedBox(width: 6),
                          Icon(Icons.chevron_right_rounded,
                              size: 18, color: muted),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }

  Widget _iconButton(
      {required IconData icon,
      required bool dark,
      required VoidCallback onTap}) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: dark ? darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: IconButton(
        icon: Icon(icon, color: dark ? Colors.white : brandNavy, size: 22),
        onPressed: onTap,
      ),
    );
  }

  Widget _residenceCarousel(
      String ownerStatus, bool dark, Color fg, Color muted) {
    final properties = _properties.whereType<Map>().toList();
    if (properties.length == 1) {
      final property = Map<String, dynamic>.from(properties.first);
      final residence = property['Residence'] is Map
          ? Map<String, dynamic>.from(property['Residence'] as Map)
          : const <String, dynamic>{};
      return _myResidenceCard(property, residence, ownerStatus, dark, fg, muted);
    }

    return Column(
      children: [
        SizedBox(
          height: 216,
          child: PageView.builder(
            controller: _residenceCarouselController,
            itemCount: properties.length,
            onPageChanged: (i) => setState(() => _carouselPage = i),
            itemBuilder: (_, i) {
              final property = Map<String, dynamic>.from(properties[i]);
              final residence = property['Residence'] is Map
                  ? Map<String, dynamic>.from(property['Residence'] as Map)
                  : const <String, dynamic>{};
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: _myResidenceCard(
                    property, residence, ownerStatus, dark, fg, muted),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(properties.length, (i) {
            final active = i == _carouselPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active ? brandAmber : (dark ? darkBorder : const Color(0xFFE2DDCF)),
                borderRadius: BorderRadius.circular(20),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _myResidenceCard(Map property, Map residence, String ownerStatus,
      bool dark, Color fg, Color muted) {
    final name = (residence['name'] ?? '').toString();
    final address = (residence['address'] ?? '').toString();
    final localAsset = residenceImageAsset(
        id: (residence['id'] ?? property['residenceId'])?.toString(),
        name: name);
    final image = _imgUrl(residence['image']);
    final floor = (property['floor'] ?? '').toString();
    final surface = (property['surface'] ?? '').toString();
    final unitRaw = (property['lotNumber'] ?? '').toString();
    final unit = unitRaw.contains('-') ? unitRaw.split('-').last : unitRaw;
    final active = ownerStatus.isEmpty || ownerStatus == 'Actif';

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: dark ? darkCard : Colors.white,
          border:
              Border.all(color: dark ? darkBorder : const Color(0xFFE9E4D8)),
        ),
        child: Stack(
          children: [
            if (localAsset != null || image != null)
              Positioned.fill(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FractionallySizedBox(
                    widthFactor: 1,
                    child: ShaderMask(
                      shaderCallback: (rect) => LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          (dark ? darkCard : brandCream).withValues(alpha: .72),
                          (dark ? darkCard : brandCream).withValues(alpha: .08),
                        ],
                        stops: const [0.0, 0.72],
                      ).createShader(rect),
                      blendMode: BlendMode.dstIn,
                      child: localAsset != null
                          ? Image.asset(localAsset, fit: BoxFit.cover)
                          : Image.network(image!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const SizedBox.shrink()),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('MA RÉSIDENCE',
                            style: TextStyle(
                                color: muted,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1)),
                      ),
                      if (unit.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (dark ? darkSurface : brandCream),
                            border: Border.all(color: brandAmber, width: 1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('APT.$unit',
                              style: const TextStyle(
                                  color: brandAmber,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(name.isNotEmpty ? name : 'Résidence',
                      style: TextStyle(
                          color: fg,
                          fontSize: 18,
                          fontWeight: FontWeight.w800)),
                  if (address.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 15, color: brandAmber),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(address,
                              style: TextStyle(color: muted, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: (dark ? Colors.white : brandNavy)
                          .withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        if (floor.isNotEmpty)
                          _Stat(
                              label: 'Étage',
                              value: floor,
                              muted: muted,
                              fg: fg),
                        if (floor.isNotEmpty && surface.isNotEmpty)
                          _statDivider(dark),
                        if (surface.isNotEmpty)
                          _Stat(
                              label: 'Surface',
                              value: '$surface m²',
                              muted: muted,
                              fg: fg),
                        _statDivider(dark),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Statut',
                                  style: TextStyle(color: muted, fontSize: 11)),
                              const SizedBox(height: 2),
                              Text(active ? 'Actif' : ownerStatus,
                                  style: TextStyle(
                                      color: active
                                          ? const Color(0xFF16A34A)
                                          : const Color(0xFFDC2626),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statDivider(bool dark) => Container(
        width: 1,
        height: 26,
        color: dark ? darkBorder : const Color(0xFFE2DDCF),
        margin: const EdgeInsets.symmetric(horizontal: 10),
      );

  Widget _statCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    String? sub,
    required Color subColor,
    required bool dark,
    required Color fg,
    required Color muted,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: dark ? darkCard : Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10)),
                  alignment: Alignment.center,
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                const Spacer(),
                Icon(Icons.chevron_right_rounded, size: 16, color: muted),
              ],
            ),
            const SizedBox(height: 10),
            Text(label, style: TextStyle(color: muted, fontSize: 12)),
            const SizedBox(height: 2),
            Text(value,
                style: TextStyle(
                    color: fg, fontSize: 15, fontWeight: FontWeight.w800)),
            if (sub != null) ...[
              const SizedBox(height: 2),
              Text(sub,
                  style: TextStyle(
                      color: subColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ],
        ),
      ),
    );
  }

  Widget _quickActionsGrid(bool dark, Color fg) {
    final actions = [
      (
        const _QAction(
            icon: Icons.error_outline_rounded,
            color: Color(0xFFE0362B),
            label: 'Signalements'),
        () => setState(() => _tab = 2)
      ),
      (
        const _QAction(
            icon: Icons.campaign_outlined,
            color: Color(0xFF8B7CF6),
            label: 'Avis'),
        () => setState(() => _tab = 1)
      ),
      (
        const _QAction(
            icon: Icons.account_balance_wallet_outlined,
            color: brandAmber,
            label: 'Paiements'),
        () => setState(() => _tab = 3)
      ),
      (
        const _QAction(
            icon: Icons.description_outlined,
            color: Color(0xFF3B82F6),
            label: 'Documents'),
        () => _push(const MyPropertiesScreen())
      ),
      (
        _QAction(
            icon: Icons.person_outline_rounded,
            color: dark ? darkMuted : const Color(0xFF6B7280),
            label: 'Profil'),
        () => _push(const ResidentProfileScreen())
      ),
      (
        const _QAction(
            icon: Icons.add_home_work_outlined,
            color: Color(0xFF16A34A),
            label: 'Ajouter un bien'),
        () => _push(const PropertyAddRequestScreen())
      ),
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.92,
      children: actions.map((a) {
        final qa = a.$1;
        return GestureDetector(
          onTap: a.$2,
          child: Container(
            decoration: BoxDecoration(
              color: dark ? darkCard : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: qa.color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12)),
                  alignment: Alignment.center,
                  child: Icon(qa.icon, color: qa.color, size: 20),
                ),
                const SizedBox(height: 8),
                Text(qa.label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: TextStyle(
                        color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── Tab 4 — More ────────────────────────────────────────
  Widget _moreTab(Map? user, bool dark) {
    final fg = dark ? Colors.white : brandNavy;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: dark ? darkCard : Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      (dark ? Colors.white : brandNavy).withValues(alpha: 0.08),
                  border: Border.all(color: brandAmber, width: 2.5),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.person_rounded, size: 40, color: fg),
              ),
              const SizedBox(height: 14),
              Text(
                user?['name']?.toString() ?? '',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w900, color: fg),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                    color: brandAmber, borderRadius: BorderRadius.circular(20)),
                child: const Text('Résident',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w700)),
              ),
              if (user?['email'] != null) ...[
                const SizedBox(height: 8),
                Text(user!['email'].toString(),
                    style: TextStyle(
                        color: dark ? darkMuted : const Color(0xFF6B7280),
                        fontSize: 12)),
              ],
            ]),
          ),
          const SizedBox(height: 20),
          Text('Services',
              style: TextStyle(
                  color: fg, fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 10),
          _profileItem(
              icon: Icons.person_outline,
              label: 'Mon profil',
              dark: dark,
              onTap: () => _push(const ResidentProfileScreen())),
          const SizedBox(height: 10),
          _profileItem(
              icon: Icons.lock_outline,
              label: 'Changer le mot de passe',
              dark: dark,
              onTap: () => _push(const ChangePasswordScreen())),
          const SizedBox(height: 10),
          _profileItem(
              icon: Icons.notifications_outlined,
              label: 'Notifications',
              dark: dark,
              badge: _unreadCount,
              onTap: () => _push(const NotificationsScreen())),
          const SizedBox(height: 10),
          _profileItem(
              icon: Icons.business_outlined,
              label: 'Mes biens',
              dark: dark,
              onTap: () => _push(const MyPropertiesScreen())),
          const SizedBox(height: 10),
          _profileItem(
              icon: Icons.groups_outlined,
              label: 'Membres du foyer',
              dark: dark,
              onTap: () => _push(const HouseholdMembersScreen())),
          const SizedBox(height: 24),
          Text('Apparence',
              style: TextStyle(
                  color: fg, fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 10),
          Consumer<ThemeProvider>(
            builder: (_, theme, __) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                  color: dark ? darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                        color: brandAmber.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12)),
                    alignment: Alignment.center,
                    child: Icon(
                        theme.isDark
                            ? Icons.dark_mode_outlined
                            : Icons.light_mode_outlined,
                        color: brandAmber,
                        size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text('Thème sombre',
                        style:
                            TextStyle(fontWeight: FontWeight.w700, color: fg)),
                  ),
                  Switch(value: theme.isDark, onChanged: theme.setDark),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          OutlinedButton.icon(
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Se déconnecter'),
            onPressed: _confirmLogout,
            style: OutlinedButton.styleFrom(
              foregroundColor: fg,
              side: BorderSide(
                  color: dark ? darkBorder : const Color(0xFFCBD5E1),
                  width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
              minimumSize: const Size.fromHeight(52),
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileItem({
    required IconData icon,
    required String label,
    required bool dark,
    required VoidCallback onTap,
    int badge = 0,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: dark ? darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: brandAmber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12)),
            alignment: Alignment.center,
            child: Icon(icon, color: brandAmber, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: dark ? Colors.white : brandNavy))),
          if (badge > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: const Color(0xFFDC2626),
                  borderRadius: BorderRadius.circular(20)),
              child: Text('$badge',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
          const SizedBox(width: 4),
          Icon(Icons.arrow_forward_ios_rounded,
              size: 14, color: dark ? darkMuted : const Color(0xFFCBD5E1)),
        ]),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color muted;
  final Color fg;
  const _Stat(
      {required this.label,
      required this.value,
      required this.muted,
      required this.fg});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: muted, fontSize: 11)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  color: fg, fontSize: 14, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _QAction {
  final IconData icon;
  final Color color;
  final String label;
  const _QAction(
      {required this.icon, required this.color, required this.label});
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(
      {required this.icon, required this.activeIcon, required this.label});
}
