// ignore_for_file: use_build_context_synchronously
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../data/api_service.dart';
import '../providers/auth_provider.dart';
import '../../l10n/app_localizations.dart';
import '../theme/design_tokens.dart';
import '../theme/gi_colors.dart';
import '../widgets/gi_bottom_nav.dart';
import '../widgets/gi_alert_dialog.dart';
import '../widgets/gi_card.dart';
import '../widgets/gi_pressable.dart';
import '../widgets/gi_settings.dart';
import '../theme/residence_images.dart';
import 'login_screen.dart';
import 'my_properties_screen.dart';
import 'my_charges_screen.dart';
import 'notifications_screen.dart';
import 'resident_profile_screen.dart';
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

  /// Bien affiche sur l'accueil. Il ne change que par le selecteur : une
  /// rotation automatique, ou un defilement qui ferait glisser la carte,
  /// changerait de residence sans que le resident l'ait demande.
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
    super.dispose();
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
      if (!mounted) return;
      final t = AppL10n.of(context);
      await showGiAlert<void>(
        context: context,
        title: t.alertPaymentTitle,
        message: t.alertPaymentBody(label),
        hint: t.alertPaymentHint,
        closeLabel: t.close,
        primaryLabel: t.viewPayment,
        onPrimary: () {
          if (mounted) setState(() => _tab = 3);
        },
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

  String? _imgUrl(dynamic raw) {
    final s = (raw ?? '').toString().trim();
    if (s.isEmpty) return null;
    if (s.startsWith('http')) return s;
    final base = _api.baseUrl.replaceAll(RegExp(r'/api/?$'), '');
    return '$base/${s.startsWith('/') ? s.substring(1) : s}';
  }

  /// Ouvre le selecteur de bien et aligne le carrousel sur le choix
  /// rapporte par l'ecran.
  Future<void> _openSwitch() async {
    final picked = await Navigator.push<int>(
      context,
      MaterialPageRoute(
          builder: (_) => MyPropertiesScreen(initialIndex: _carouselPage)),
    );
    if (!mounted) return;
    _fetchUnread();
    if (picked != null &&
        picked != _carouselPage &&
        picked < _properties.length) {
      setState(() => _carouselPage = picked);
    }
  }

  Future<void> _push(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    if (mounted) _fetchUnread();
  }

  Future<void> _confirmLogout() async {
    final t = AppL10n.of(context);
    await showGiAlert<void>(
      context: context,
      title: t.logoutTitle,
      message: t.logoutBody,
      hint: t.logoutHint,
      closeLabel: t.cancel,
      primaryLabel: t.logout,
      onPrimary: _logout,
    );
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
      backgroundColor: GiColors.of(context).scaffold,
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
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildNavBar() {
    final t = AppL10n.of(context);
    return GiBottomNav(
      currentIndex: _tab,
      onTap: (i) => setState(() => _tab = i),
      items: [
        GiNavItem(asset: 'assets/figma/icons/nav_home.svg', label: t.navHome),
        GiNavItem(
            asset: 'assets/figma/icons/nav_notice.svg', label: t.navNotice),
        GiNavItem(
            asset: 'assets/figma/icons/nav_report.svg', label: t.navReport),
        GiNavItem(
            asset: 'assets/figma/icons/nav_payment.svg', label: t.navPayment),
        GiNavItem(
            asset: 'assets/figma/icons/nav_more.svg',
            label: t.navMore,
            badge: _unreadCount),
      ],
    );
  }

  // ─── Tab 0 — Accueil ─────────────────────────────────────
  // Frames Figma "Home LT" (927:7894) et "Home DT" (960:6915).
  // Rythme vertical de la maquette : en-tete a 66, contenu a 118, blocs
  // espaces de 16, elements internes de 12.
  Widget _homeTab(Map? user, bool dark) {
    final c = GiColors.of(context);
    final t = AppL10n.of(context);
    final name = (user?['name'] ?? user?['fullName'] ?? '').toString();
    final firstName = name.trim().isEmpty ? '' : name.trim().split(' ').first;

    final openTickets = _tickets.where((e) {
      final s = (e is Map ? e['status'] : '').toString().toUpperCase();
      return !['TERMINE', 'TERMINEE', 'CLOTURE', 'RESOLU', 'REJETE']
          .contains(s);
    }).length;
    final inProgress = _tickets.where((e) {
      final s = (e is Map ? e['status'] : '').toString().toUpperCase();
      return s == 'EN_COURS';
    }).length;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: FigBrand.amber,
        backgroundColor: c.card,
        onRefresh: () async {
          await _fetchDashboard();
          await _fetchUnread();
        },
        child: ListView(
          // Le Figma pose l'en-tete a 66 dans une frame de 812, soit 22 sous
          // la barre d'etat. Sur un ecran sans encoche, SafeArea ne retire
          // rien et 22 colle au bord : on garde 22 comme minimum et on laisse
          // respirer davantage quand il n'y a pas d'encoche.
          padding: EdgeInsets.fromLTRB(
              FigSpace.pagePadding,
              MediaQuery.paddingOf(context).top > 0 ? 22 : 32,
              FigSpace.pagePadding,
              150),
          children: [
            _header(c, t, firstName),
            const SizedBox(height: 20),
            _heroSection(c, t),
            const SizedBox(height: FigSpace.lg),
            _statsRow(c, t, openTickets, inProgress),
            const SizedBox(height: FigSpace.xl),
            Text(t.quickActions,
                style: FigText.titleMd.copyWith(color: c.textBody)),
            const SizedBox(height: FigSpace.lg),
            _quickActionsGrid(c, t),
            const SizedBox(height: FigSpace.xl),
            Text(t.recentActivity,
                style: FigText.titleMd.copyWith(color: c.textBody)),
            const SizedBox(height: FigSpace.lg),
            _recentActivity(c),
          ],
        ),
      ),
    );
  }

  Widget _header(GiColors c, AppL10n t, String firstName) {
    return SizedBox(
      height: FigSize.chipMd,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              t.greeting(firstName),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: FigText.greeting.copyWith(color: c.title),
            ),
          ),
          const SizedBox(width: FigSpace.lg),
          Row(
            children: [
              GiPressable(
                pressedScale: 0.88,
                onTap: () => _push(const NotificationsScreen()),
                child: Container(
                  width: FigSize.chipMd,
                  height: FigSize.chipMd,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.headerChipBg,
                    border: Border.all(color: c.headerChipBorder),
                    borderRadius: BorderRadius.circular(FigRadius.chip),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      SvgPicture.asset('assets/figma/icons/bell_16.svg',
                          colorFilter:
                              ColorFilter.mode(c.textBody, BlendMode.srcIn)),
                      if (_unreadCount > 0)
                        PositionedDirectional(
                          top: -2,
                          end: -2,
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                                color: FigAlert.error, shape: BoxShape.circle),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: FigSpace.lg),
              GiPressable(
                pressedScale: 0.88,
                onTap: () => _push(const ResidentProfileScreen()),
                // Figma : photo dans un carre de 32, rayon 8, cercle d'un
                // trait ambre de 1. La bordure reste fine a dessein, elle ne
                // doit pas manger la photo.
                child: Container(
                  width: FigSize.chipMd,
                  height: FigSize.chipMd,
                  decoration: BoxDecoration(
                    border: Border.all(color: FigBrand.amber),
                    borderRadius: BorderRadius.circular(FigRadius.chip),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child:
                      Image.asset('assets/figma/avatar.png', fit: BoxFit.cover),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Carte « Ma residence ». Le Figma n'en montre qu'une ; l'app peut en
  // compter plusieurs, on garde donc le defilement horizontal, chaque carte
  // etant rendue a l'identique de la maquette.
  Widget _heroSection(GiColors c, AppL10n t) {
    if (_loadingDashboard) {
      return Container(
        height: FigSize.heroH,
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(FigRadius.card),
          border: Border.all(color: c.cardBorder),
        ),
      );
    }
    if (_properties.isEmpty) {
      return GiCard(
        child: SizedBox(
          height: 120,
          child: Center(
            child: Text(t.myResidence,
                style: FigText.body.copyWith(color: c.textMuted)),
          ),
        ),
      );
    }
    final index = _carouselPage.clamp(0, _properties.length - 1);
    return Column(
      children: [
        _heroCard(c, t, _properties[index] as Map),
        // Reperes de position, affiches seulement s'il y a plusieurs biens.
        // Ils indiquent lequel on regarde ; c'est la carte qu'on touche pour
        // en changer.
        if (_properties.length > 1) ...[
          const SizedBox(height: FigSpace.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < _properties.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOut,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == index ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == index ? FigBrand.amber : c.innerBorder,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _heroCard(GiColors c, AppL10n t, Map property) {
    final residence = property['Residence'] is Map
        ? Map<String, dynamic>.from(property['Residence'] as Map)
        : <String, dynamic>{};
    final resName = (residence['name'] ?? '').toString();
    final address = (residence['address'] ?? '').toString();
    final asset = residenceImageAsset(
        id: (residence['id'] ?? '').toString(), name: resName);
    final url = _imgUrl(residence['image']);
    final lot = (property['lotNumber'] ?? '').toString();
    final status = (property['status'] ?? '').toString();

    return GiPressable(
      pressedScale: 0.985,
      onTap: () => _openSwitch(),
      child: Container(
        height: FigSize.heroH,
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(FigRadius.card),
          border: Border.all(color: c.heroBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // La photo occupe la droite de la carte et se fond vers la
            // gauche : dans le Figma elle est masquee par un degrade qui la
            // ramene a la couleur de la carte.
            // Fondu de la photo vers la carte.
            //
            // Le Figma faisait monter la photo jusqu'a l'opacite pleine sur le
            // dernier tiers, ce qui creait une frontiere nette entre la carte
            // et l'image. On s'en ecarte volontairement : la photo couvre
            // desormais toute la largeur de la carte, sa montee est etalee sur
            // quatre paliers, et elle plafonne a 78 % d'opacite. Elle reste
            // donc teintee par la carte jusqu'au bord droit, au lieu de la
            // remplacer.
            Positioned.fill(
              child: ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (rect) => LinearGradient(
                  begin: AlignmentDirectional.centerStart,
                  end: AlignmentDirectional.centerEnd,
                  colors: [
                    Colors.white.withValues(alpha: 0),
                    Colors.white.withValues(alpha: 0.10),
                    Colors.white.withValues(alpha: 0.45),
                    Colors.white.withValues(alpha: 0.78),
                  ],
                  stops: const [0.12, 0.42, 0.72, 1.0],
                  // AlignmentDirectional ne peut se resoudre sans le sens de
                  // lecture : sans ce parametre createShader echoue et le
                  // ShaderMask ne peint plus rien du tout.
                ).createShader(rect, textDirection: Directionality.of(context)),
                child: asset != null
                    ? Image.asset(asset,
                        fit: BoxFit.cover,
                        alignment: AlignmentDirectional.centerEnd
                            .resolve(Directionality.of(context)))
                    : (url != null
                        ? Image.network(url,
                            fit: BoxFit.cover,
                            alignment: AlignmentDirectional.centerEnd
                                .resolve(Directionality.of(context)),
                            errorBuilder: (_, __, ___) =>
                                ColoredBox(color: c.card))
                        : ColoredBox(color: c.card)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(FigSpace.heroPadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t.myResidence,
                                    style: FigText.body
                                        .copyWith(color: c.textFaint)),
                                const SizedBox(height: FigSpace.xs),
                                Text(resName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: FigText.titleMd
                                        .copyWith(color: c.textBody)),
                              ],
                            ),
                          ),
                          if (lot.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: c.scaffold,
                                border: Border.all(color: c.cardBorder),
                                borderRadius:
                                    BorderRadius.circular(FigRadius.pill),
                              ),
                              child: Text(lot,
                                  style: FigText.body
                                      .copyWith(color: FigBrand.amber)),
                            ),
                        ],
                      ),
                      const SizedBox(height: FigSpace.lg),
                      Row(
                        children: [
                          SvgPicture.asset(
                              'assets/figma/icons/pin_location.svg',
                              colorFilter: const ColorFilter.mode(
                                  FigBrand.amber, BlendMode.srcIn)),
                          const SizedBox(width: FigSpace.md),
                          Expanded(
                            child: Text(address,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style:
                                    FigText.body.copyWith(color: c.textBody)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  _heroStats(c, t, property, status),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroStats(GiColors c, AppL10n t, Map property, String status) {
    Widget cell(String label, String value, {Color? valueColor}) => Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: FigText.label.copyWith(color: c.textFaint)),
            Text(value,
                style: FigText.statValue
                    .copyWith(color: valueColor ?? c.textBody)),
          ],
        );

    final divider = Container(width: 1, height: 37, color: c.innerBorder);
    final floor = (property['floor'] ?? '').toString();
    final surface = (property['surface'] ?? '').toString();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(FigRadius.card),
        border: Border.all(color: c.innerBorder),
        gradient: LinearGradient(
          begin: AlignmentDirectional.centerStart,
          end: AlignmentDirectional.centerEnd,
          colors: [c.card.withValues(alpha: 0), c.card],
        ),
      ),
      child: SizedBox(
        height: 40,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            cell(t.floor, floor),
            divider,
            cell(t.area, surface.isEmpty ? '' : '$surface m²'),
            divider,
            cell(t.status, status.isEmpty ? t.statusActive : status,
                valueColor: FigAlert.success),
          ],
        ),
      ),
    );
  }

  Widget _statsRow(GiColors c, AppL10n t, int open, int inProgress) {
    final amount = _chargesSummary['annualAmount'];
    final due = _chargesSummary['nextPaymentDate']?.toString();
    final dueDate = due == null ? null : DateTime.tryParse(due)?.toLocal();

    // IntrinsicHeight est indispensable : dans une ListView la hauteur est
    // non bornee, et un Row en CrossAxisAlignment.stretch ne peut alors pas
    // se dimensionner. Il donne aussi la meme hauteur aux deux cartes.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _statCard(
              c,
              asset: 'assets/figma/icons/payment_15.svg',
              accent: FigAccent.amber,
              label: t.nextPayment,
              value: amount == null ? '—' : '$amount DZD',
              sub: dueDate == null
                  ? ''
                  : t.paymentDeadline(_formatDate(dueDate)),
              subColor: FigBrand.amber,
              onTap: () => setState(() => _tab = 3),
            ),
          ),
          const SizedBox(width: FigSpace.lg),
          Expanded(
            child: _statCard(
              c,
              asset: 'assets/figma/icons/alert_16.svg',
              accent: FigAccent.red,
              label: t.reports,
              value: t.reportsOpen(open),
              sub: inProgress == 0 ? '' : t.reportsInProgress(inProgress),
              subColor: FigAlert.error,
              onTap: () => setState(() => _tab = 2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(
    GiColors c, {
    required String asset,
    required Color accent,
    required String label,
    required String value,
    required String sub,
    required Color subColor,
    required VoidCallback onTap,
  }) {
    return GiCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GiIconChip(
                accent: accent,
                size: FigSize.chipSm,
                radius: FigRadius.pill,
                icon: SvgPicture.asset(asset,
                    colorFilter: ColorFilter.mode(accent, BlendMode.srcIn)),
              ),
              const GiChevron(),
            ],
          ),
          const SizedBox(height: FigSpace.sm),
          Text(label, style: FigText.body.copyWith(color: c.textMuted)),
          const SizedBox(height: FigSpace.sm),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: FigText.titleMd.copyWith(color: c.textBody)),
          if (sub.isNotEmpty) ...[
            const SizedBox(height: FigSpace.sm),
            Text(sub,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: FigText.caption.copyWith(color: subColor)),
          ],
        ],
      ),
    );
  }

  Widget _quickActionsGrid(GiColors c, AppL10n t) {
    final actions = <(String?, IconData?, Color, String, VoidCallback)>[
      (
        'assets/figma/icons/alert_20.svg',
        null,
        FigAccent.red,
        t.reports,
        () => setState(() => _tab = 2)
      ),
      (
        'assets/figma/icons/notice_20.svg',
        null,
        FigAccent.violet,
        t.notices,
        () => setState(() => _tab = 1)
      ),
      (
        'assets/figma/icons/payment_20.svg',
        null,
        FigAccent.amber,
        t.payments,
        () => setState(() => _tab = 3)
      ),
      (
        'assets/figma/icons/documents_20.svg',
        null,
        FigAccent.blue,
        t.documents,
        () => _openSwitch()
      ),
      (
        'assets/figma/icons/profile_20.svg',
        null,
        FigAccent.purple,
        t.profile,
        () => _push(const ResidentProfileScreen())
      ),
      // Absente du Figma : la maquette ne prevoit que cinq actions, mais
      // l'ajout d'un bien existe dans l'app. On garde la fonctionnalite en
      // lui appliquant le meme habillage, faute d'icone fournie.
      (
        null,
        null,
        FigAlert.success,
        t.addProperty,
        () => _push(const PropertyAddRequestScreen())
      ),
    ];

    const columns = 3;
    final rows = <Widget>[];
    for (var i = 0; i < actions.length; i += columns) {
      final slice = actions.skip(i).take(columns).toList();
      rows.add(IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var j = 0; j < columns; j++) ...[
              if (j > 0) const SizedBox(width: FigSpace.lg),
              Expanded(
                child: j < slice.length
                    ? _quickTile(c, slice[j])
                    : const SizedBox.shrink(),
              ),
            ],
          ],
        ),
      ));
      if (i + columns < actions.length) {
        rows.add(const SizedBox(height: FigSpace.lg));
      }
    }
    return Column(children: rows);
  }

  Widget _quickTile(
      GiColors c, (String?, IconData?, Color, String, VoidCallback) a) {
    final (asset, icon, accent, label, onTap) = a;
    return GiCard(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GiIconChip(
            accent: accent,
            icon: asset != null
                ? SvgPicture.asset(asset,
                    colorFilter: ColorFilter.mode(accent, BlendMode.srcIn))
                : Icon(icon, size: 20, color: accent),
          ),
          const SizedBox(height: FigSpace.lg),
          // Les tuiles du Figma sont taillees pour « Reports ».
          // « Signalements » n'y tient pas et Flutter le brisait en plein
          // milieu, faute d'espace ou couper. On reduit le libelle plutot que
          // de le casser.
          SizedBox(
            height: 16,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: FigText.body.copyWith(color: c.textMuted)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _recentActivity(GiColors c) {
    final recent = _tickets.take(3).toList();
    if (recent.isEmpty) {
      return GiCard(
        child: SizedBox(
          height: 56,
          child: Center(
            child: Text('—', style: FigText.body.copyWith(color: c.textMuted)),
          ),
        ),
      );
    }
    return Column(
      children: [
        for (var i = 0; i < recent.length; i++) ...[
          if (i > 0) const SizedBox(height: FigSpace.lg),
          _activityRow(c, recent[i] as Map),
        ],
      ],
    );
  }

  Widget _activityRow(GiColors c, Map ticket) {
    final status = (ticket['status'] ?? '').toString().toUpperCase();
    final dot = status == 'EN_COURS'
        ? FigAccent.violet
        : status.startsWith('TERMIN')
            ? FigAlert.success
            : FigAlert.error;

    return GiCard(
      onTap: () => setState(() => _tab = 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: FigSize.activityDot,
                height: FigSize.activityDot,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              ),
              const SizedBox(width: FigSpace.md),
              Expanded(
                child: Text((ticket['title'] ?? '').toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FigText.bodyLg.copyWith(color: c.textBody)),
              ),
              const GiChevron(),
            ],
          ),
          const SizedBox(height: FigSpace.xs),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 14),
            child: Text(_timeAgo(ticket['createdAt']?.toString()),
                style: FigText.caption.copyWith(color: c.textMuted)),
          ),
        ],
      ),
    );
  }

  // ─── Tab 4 — Plus ────────────────────────────────────────
  // Frame Figma "More LT" (837:4435) : carte d'identite avec son bandeau de
  // trois colonnes, ligne de changement de residence, sections en listes
  // groupees, puis le bouton de deconnexion.
  Widget _moreTab(Map? user, bool dark) {
    final c = GiColors.of(context);
    final t = AppL10n.of(context);
    final name = (user?['name'] ?? user?['fullName'] ?? '').toString();

    final property = _properties.isNotEmpty && _properties.first is Map
        ? Map<String, dynamic>.from(_properties.first as Map)
        : <String, dynamic>{};
    final residence = property['Residence'] is Map
        ? Map<String, dynamic>.from(property['Residence'] as Map)
        : <String, dynamic>{};
    final resName = (residence['name'] ?? '').toString();
    final lot = (property['lotNumber'] ?? '').toString();
    final block = (property['block'] ?? '').toString();

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
            FigSpace.pagePadding,
            MediaQuery.paddingOf(context).top > 0 ? 22 : 32,
            FigSpace.pagePadding,
            150),
        children: [
          _identityCard(c, t, name, lot, resName, block),
          const SizedBox(height: FigSpace.xl),
          GiCard(
            onTap: () => _openSwitch(),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(t.changeResidence,
                          style: FigText.statValue
                              .copyWith(height: 1.2, color: c.textBody)),
                      const SizedBox(height: FigSpace.xs),
                      Text(
                        t.currentResidenceIs(resName.isEmpty ? '—' : resName),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: FigText.label.copyWith(color: c.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: FigSpace.md),
                const GiChevron(),
              ],
            ),
          ),
          const SizedBox(height: FigSpace.xl),
          GiSettingsGroup(
            title: t.services,
            rows: [
              GiSettingsRow(
                icon: SvgPicture.asset('assets/figma/icons/settings_16.svg',
                    colorFilter: ColorFilter.mode(c.textBody, BlendMode.srcIn)),
                label: t.settingsTitle,
                value: t.settingsSubtitle,
                onTap: () => _push(const ResidentProfileScreen()),
              ),
              GiSettingsRow(
                icon: SvgPicture.asset('assets/figma/icons/bell_16.svg',
                    colorFilter: ColorFilter.mode(c.textBody, BlendMode.srcIn)),
                label: t.notificationsTitle,
                onTap: () => _push(const NotificationsScreen()),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_unreadCount > 0)
                      Container(
                        constraints: const BoxConstraints(minWidth: 20),
                        height: 20,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: FigAlert.error,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('$_unreadCount',
                            style: FigText.caption.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                      ),
                    const SizedBox(width: FigSpace.md),
                    GiChevron(color: c.textMuted),
                  ],
                ),
              ),
              GiSettingsRow(
                icon: SvgPicture.asset('assets/figma/icons/nav_home.svg',
                    colorFilter: ColorFilter.mode(c.textBody, BlendMode.srcIn)),
                label: t.myProperties,
                onTap: () => _openSwitch(),
              ),
              GiSettingsRow(
                icon: SvgPicture.asset('assets/figma/icons/household_16.svg',
                    colorFilter: ColorFilter.mode(c.textBody, BlendMode.srcIn)),
                label: t.householdMembers,
                onTap: () => _push(const HouseholdMembersScreen()),
              ),
            ],
          ),
          const SizedBox(height: FigSpace.xl),
          // Le Figma place ici un bouton plein ; en rouge plutot qu'en ambre,
          // la deconnexion n'etant pas une action que l'on veut mettre en
          // avant comme les autres.
          GiPressable(
            onTap: _confirmLogout,
            pressedScale: 0.97,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: FigAlert.error.withValues(alpha: 0.08),
                border:
                    Border.all(color: FigAlert.error.withValues(alpha: 0.30)),
                borderRadius: BorderRadius.circular(FigRadius.cta),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(t.logout,
                      style: FigText.button.copyWith(color: FigAlert.error)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Carte d'identite du Figma : ligne avatar + nom + badge, puis un bandeau
  /// de trois colonnes separees par des traits, identique a celui de la carte
  /// residence de l'accueil.
  Widget _identityCard(GiColors c, AppL10n t, String name, String lot,
      String resName, String block) {
    Widget cell(String label, String value) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: FigText.label.copyWith(
                      fontSize: 10, letterSpacing: 0.4, color: c.textFaint)),
              const SizedBox(height: FigSpace.xs),
              Text(value.isEmpty ? '—' : value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: FigText.statValue.copyWith(color: c.textBody)),
            ],
          ),
        );

    return GiCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: FigSize.chipMd,
                height: FigSize.chipMd,
                decoration: BoxDecoration(
                  border: Border.all(color: FigBrand.amber),
                  borderRadius: BorderRadius.circular(FigRadius.chip),
                ),
                clipBehavior: Clip.antiAlias,
                child:
                    Image.asset('assets/figma/avatar.png', fit: BoxFit.cover),
              ),
              const SizedBox(width: FigSpace.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: FigText.titleMd.copyWith(color: c.textBody)),
                    const SizedBox(height: 2),
                    Text(
                      lot.isEmpty
                          ? t.roleResident
                          : '${t.roleResident} · ${t.apartmentShort(lot)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: FigText.body.copyWith(color: c.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: FigSpace.md),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: FigAccent.chipFill(FigAlert.success),
                  border:
                      Border.all(color: FigAccent.chipBorder(FigAlert.success)),
                  borderRadius: BorderRadius.circular(FigRadius.pill),
                ),
                child: Text(t.verified,
                    style: FigText.caption.copyWith(color: FigAlert.success)),
              ),
            ],
          ),
          const SizedBox(height: FigSpace.xl),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(FigRadius.card),
              border: Border.all(color: c.innerBorder),
            ),
            child: Row(
              children: [
                cell(t.residenceUpper, resName),
                Container(width: 1, height: 35, color: c.innerBorder),
                const SizedBox(width: FigSpace.lg),
                cell(t.blockUpper, block),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
