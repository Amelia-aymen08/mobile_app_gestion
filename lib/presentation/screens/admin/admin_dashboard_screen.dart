import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../data/person_name.dart';
import '../../theme/design_tokens.dart';
import '../../theme/gi_colors.dart';
import '../../theme/residence_images.dart';
import '../../theme/ticket_status.dart';
import '../../widgets/gi_appear.dart';
import '../../widgets/gi_card.dart';
import '../../widgets/gi_pressable.dart';
import '../../widgets/gi_refresh.dart';
import '../../widgets/gi_skeleton.dart';
import '../notifications_screen.dart';
import 'admin_residence_screen.dart';
import 'admin_store.dart';
import 'admin_ticket_screen.dart';
import 'admin_tickets_screen.dart';
import 'admin_ui.dart';
import '../../widgets/gi_scroll_blur.dart';

/// Accueil de l'administration.
///
/// Il repond, dans l'ordre, a trois questions : qu'est-ce qui m'attend,
/// qu'est-ce qui presse, ou en sont les residences. Chaque chiffre ouvre la
/// liste qu'il compte, chaque ticket s'ouvre, chaque residence aussi.
class AdminDashboardScreen extends StatelessWidget {
  final AdminStore store;
  final Map? user;
  final int unread;
  final void Function(AdminTicketFilter filter, {String residenceId})
      openTickets;
  final VoidCallback openResidences;
  final VoidCallback openProfile;
  final VoidCallback onNotificationsClosed;

  const AdminDashboardScreen({
    super.key,
    required this.store,
    required this.user,
    required this.unread,
    required this.openTickets,
    required this.openResidences,
    required this.openProfile,
    required this.onNotificationsClosed,
  });

  static const _weekdays = [
    'lundi',
    'mardi',
    'mercredi',
    'jeudi',
    'vendredi',
    'samedi',
    'dimanche'
  ];
  static const _months = [
    'janvier',
    'février',
    'mars',
    'avril',
    'mai',
    'juin',
    'juillet',
    'août',
    'septembre',
    'octobre',
    'novembre',
    'décembre',
  ];

  String _today() {
    final d = DateTime.now();
    final w = _weekdays[d.weekday - 1];
    return '${w[0].toUpperCase()}${w.substring(1)} ${d.day} ${_months[d.month - 1]}';
  }

  @override
  Widget build(BuildContext context) =>
      ListenableBuilder(listenable: store, builder: (c, _) => _build(c));

  Widget _build(BuildContext context) {
    final c = GiColors.of(context);
    final wide = MediaQuery.sizeOf(context).width >= kAdminWide;
    final top = MediaQuery.paddingOf(context).top > 0 ? 14.0 : 24.0;
    final first = PersonName.firstName(user?['name'] ?? user?['fullName']);

    final header = AdminPageHeader(
      title: first.isEmpty ? 'Bonjour' : 'Bonjour $first',
      subtitle: _today(),
      large: true,
      actions: [
        AdminSquareButton(
          tooltip: 'Notifications',
          onTap: () async {
            await adminPush(context, const NotificationsScreen());
            onNotificationsClosed();
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              SvgPicture.asset('assets/figma/icons/bell_16.svg',
                  colorFilter: ColorFilter.mode(c.textBody, BlendMode.srcIn)),
              if (unread > 0)
                const Positioned(
                  top: -3,
                  right: -3,
                  child:
                      CircleAvatar(radius: 4, backgroundColor: FigAlert.error),
                ),
            ],
          ),
        ),
        if (!wide)
          GiPressable(
            pressedScale: 0.88,
            onTap: openProfile,
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: FigBrand.amber.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: FigBrand.amber.withValues(alpha: 0.6)),
              ),
              child: Text(
                  PersonName.format(user?['name'] ?? user?['fullName'])
                      .split(' ')
                      .where((w) => w.isNotEmpty)
                      .take(2)
                      .map((w) => w[0].toUpperCase())
                      .join(),
                  style: FigText.label.copyWith(
                      fontWeight: FontWeight.w700, color: FigBrand.amber)),
            ),
          ),
      ],
    );

    final left = <Widget>[
      _focusCard(context, c),
      const SizedBox(height: FigSpace.xl + 4),
      AdminSectionTitle('Action requise',
          count: store.loading ? null : '${store.needsAction.length}',
          action: 'Tout voir',
          onAction: () => openTickets(AdminTicketFilter.toAssign)),
      const SizedBox(height: FigSpace.lg),
      _actionList(context),
      const SizedBox(height: FigSpace.xl + 4),
      AdminSectionTitle('Derniers tickets',
          action: 'Tout voir',
          onAction: () => openTickets(AdminTicketFilter.all)),
      const SizedBox(height: FigSpace.lg),
      _recent(context),
    ];
    final right = <Widget>[
      const AdminSectionTitle('Volume — 7 derniers jours'),
      const SizedBox(height: FigSpace.lg),
      _chart(c),
      const SizedBox(height: FigSpace.xl + 4),
      AdminSectionTitle('Résidences',
          count: store.loading ? null : '${store.residences.length}',
          action: 'Tout voir',
          onAction: openResidences),
      const SizedBox(height: FigSpace.lg),
      _residences(context, c),
      ..._serverStats(c),
    ];

    return Scaffold(
      backgroundColor: c.scaffold,
      body: GiScrollBlur(
        child: CustomScrollView(
          clipBehavior: Clip.none,
          physics: giRefreshPhysics,
          slivers: [
            GiRefreshControl(onRefresh: store.load),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                  FigSpace.pagePadding, top, FigSpace.pagePadding, 150),
              sliver: SliverToBoxAdapter(
                child: AdminContent(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      header,
                      const SizedBox(height: FigSpace.xl + 4),
                      GiAppear(child: _kpis(context)),
                      const SizedBox(height: FigSpace.xl + 4),
                      if (wide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: left),
                            ),
                            const SizedBox(width: FigSpace.xxl),
                            Expanded(
                              flex: 2,
                              child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: right),
                            ),
                          ],
                        )
                      else ...[
                        ...left,
                        const SizedBox(height: FigSpace.xl + 4),
                        ...right,
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kpis(BuildContext context) {
    String n(AdminTicketFilter f) =>
        store.loading ? '—' : '${store.count(f.test)}';
    final tiles = [
      AdminStatTile(
        icon: Icons.inbox_rounded,
        accent: FigBrand.amber,
        label: 'À traiter',
        value: n(AdminTicketFilter.active),
        onTap: () => openTickets(AdminTicketFilter.active),
      ),
      AdminStatTile(
        icon: Icons.person_add_alt_1_rounded,
        accent: FigAccent.violet,
        label: 'À assigner',
        value: n(AdminTicketFilter.toAssign),
        onTap: () => openTickets(AdminTicketFilter.toAssign),
      ),
      AdminStatTile(
        icon: Icons.priority_high_rounded,
        accent: FigAlert.error,
        label: 'Urgents',
        value: n(AdminTicketFilter.urgent),
        onTap: () => openTickets(AdminTicketFilter.urgent),
      ),
      AdminStatTile(
        icon: Icons.autorenew_rounded,
        accent: FigAccent.blue,
        label: 'En cours',
        value: n(AdminTicketFilter.inProgress),
        onTap: () => openTickets(AdminTicketFilter.inProgress),
      ),
    ];
    return LayoutBuilder(builder: (context, constraints) {
      final cols = constraints.maxWidth >= 640 ? 4 : 2;
      return AdminGrid(
          minTileWidth: constraints.maxWidth / cols - 1, children: tiles);
    });
  }

  /// Carte d'appel : le ticket le plus pressant, ou la confirmation que
  /// tout est en ordre.
  Widget _focusCard(BuildContext context, GiColors c) {
    if (store.loading) {
      return const GiSkeletonList(
          count: 1, itemHeight: 110, padding: EdgeInsets.zero);
    }
    final pending = store.needsAction;
    if (pending.isEmpty) {
      return GiCard(
        borderColor: FigAlert.success.withValues(alpha: 0.4),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: FigAlert.success.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified_rounded,
                  color: FigAlert.success, size: 24),
            ),
            const SizedBox(width: FigSpace.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tout est sous contrôle',
                      style: FigText.titleMd.copyWith(color: c.textBody)),
                  const SizedBox(height: 3),
                  Text('Aucun ticket urgent ni en attente d\'intervenant.',
                      style: FigText.body.copyWith(color: c.textMuted)),
                ],
              ),
            ),
          ],
        ),
      );
    }
    final next = pending.first;
    final urgent = ticketPriority(next['priority']) == TicketPriority.urgent;
    final accent = urgent ? FigAlert.error : FigBrand.amber;
    return GiPressable(
      pressedScale: 0.985,
      onTap: () => openAdminTicket(context, store, next),
      child: Container(
        padding: const EdgeInsets.all(FigSpace.cardPadding),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(FigRadius.card),
          border: Border.all(color: accent.withValues(alpha: 0.55)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [accent.withValues(alpha: 0.16), c.card],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                    urgent
                        ? Icons.local_fire_department_rounded
                        : Icons.bolt_rounded,
                    size: 18,
                    color: accent),
                const SizedBox(width: FigSpace.sm),
                Expanded(
                  child: Text(urgent ? 'Le plus urgent' : 'Prochain à traiter',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: FigText.label.copyWith(
                          fontWeight: FontWeight.w600, color: accent)),
                ),
                const SizedBox(width: FigSpace.md),
                Text(timeAgoLabel(TicketFields.created(next)),
                    style: FigText.label.copyWith(color: c.textMuted)),
              ],
            ),
            const SizedBox(height: FigSpace.lg),
            Text(TicketFields.title(next),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: FigText.titleMd
                    .copyWith(fontSize: 19, height: 1.25, color: c.textBody)),
            const SizedBox(height: 4),
            Text(
                [
                  store.residenceNameOf(next),
                  (next['location'] ?? '').toString(),
                ].where((s) => s.trim().isNotEmpty).join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: FigText.body.copyWith(color: c.textMuted)),
            const SizedBox(height: FigSpace.lg),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: FigBrand.amber,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Traiter',
                          style:
                              FigText.bodyActive.copyWith(color: Colors.black)),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_rounded,
                          size: 16, color: Colors.black),
                    ],
                  ),
                ),
                const SizedBox(width: FigSpace.md),
                if (pending.length > 1)
                  Flexible(
                    child: Text(
                        '+ ${pending.length - 1} autre${pending.length > 2 ? 's' : ''} en attente',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: FigText.label.copyWith(color: c.textMuted)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionList(BuildContext context) {
    if (store.loading) {
      return const GiSkeletonList(
          count: 2, itemHeight: 120, padding: EdgeInsets.zero);
    }
    final list = store.needsAction.skip(1).take(4).toList();
    if (list.isEmpty) {
      return GiCard(
        child: AdminEmpty(
          icon: Icons.task_alt_rounded,
          title: 'Rien d\'autre en attente',
          message: store.needsAction.isEmpty
              ? 'Les nouveaux tickets apparaîtront ici.'
              : 'Il ne reste que le ticket ci-dessus.',
        ),
      );
    }
    return Column(
      children: [
        for (var i = 0; i < list.length; i++) ...[
          if (i > 0) const SizedBox(height: FigSpace.lg),
          GiAppear(
            index: i + 1,
            child: AdminTicketCard(
              ticket: list[i],
              residenceName: store.residenceNameOf(list[i]),
              onTap: () => openAdminTicket(context, store, list[i]),
            ),
          ),
        ],
      ],
    );
  }

  Widget _recent(BuildContext context) {
    final c = GiColors.of(context);
    if (store.loading) {
      return const GiSkeletonList(
          count: 3, itemHeight: 76, padding: EdgeInsets.zero);
    }
    final list = store.tickets.take(5).toList();
    if (list.isEmpty) {
      return const GiCard(
        child: AdminEmpty(
            icon: Icons.inbox_outlined,
            title: 'Aucun ticket',
            message: 'Les signalements des résidents apparaîtront ici.'),
      );
    }
    return GiCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          for (var i = 0; i < list.length; i++) ...[
            if (i > 0) Divider(height: 1, color: c.innerBorder, indent: 50),
            _recentRow(context, c, list[i]),
          ],
        ],
      ),
    );
  }

  Widget _recentRow(BuildContext context, GiColors c, Map t) {
    final stage = ticketStage(t['status']);
    return GiPressable(
      pressedScale: 0.98,
      onTap: () => openAdminTicket(context, store, t),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            AdminCategoryTile(
                category: (t['category'] ?? '').toString(),
                color: stage.color,
                size: 26),
            const SizedBox(width: FigSpace.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(TicketFields.title(t),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: FigText.fieldLabel.copyWith(
                          fontWeight: FontWeight.w500, color: c.textBody)),
                  const SizedBox(height: 2),
                  Text(
                      [
                        store.residenceNameOf(t),
                        timeAgoLabel(TicketFields.created(t))
                      ].where((s) => s.isNotEmpty).join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: FigText.label.copyWith(color: c.textMuted)),
                ],
              ),
            ),
            const SizedBox(width: FigSpace.md),
            AdminPill.stage(stage, dense: true),
          ],
        ),
      ),
    );
  }

  /// Tickets recus par jour sur la derniere semaine, comptes sur la liste
  /// elle-meme : le chiffre du graphique et celui des listes concordent.
  Widget _chart(GiColors c) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = [
      for (var i = 6; i >= 0; i--) today.subtract(Duration(days: i))
    ];
    final counts = [
      for (final d in days)
        store.count((t) {
          final created = TicketFields.created(t);
          return created != null &&
              created.year == d.year &&
              created.month == d.month &&
              created.day == d.day;
        })
    ];
    final max = counts.fold<int>(0, (a, b) => b > a ? b : a);
    final total = counts.fold<int>(0, (a, b) => a + b);
    const labels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

    return GiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$total',
                  style: FigText.greeting.copyWith(color: c.textBody)),
              const SizedBox(width: FigSpace.md),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                    'ticket${total > 1 ? 's' : ''} reçu${total > 1 ? 's' : ''}',
                    style: FigText.body.copyWith(color: c.textMuted)),
              ),
            ],
          ),
          const SizedBox(height: FigSpace.xl),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < days.length; i++)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (counts[i] > 0)
                          Text('${counts[i]}',
                              style: FigText.caption
                                  .copyWith(fontSize: 11, color: c.textMuted)),
                        const SizedBox(height: 4),
                        // Les barres montent a l'ouverture.
                        TweenAnimationBuilder<double>(
                          tween: Tween(
                              begin: 0, end: max == 0 ? 0 : counts[i] / max),
                          duration: Duration(milliseconds: 500 + i * 60),
                          curve: Curves.easeOutCubic,
                          builder: (context, v, _) => Container(
                            width: 18,
                            height: 4 + 72 * v,
                            decoration: BoxDecoration(
                              color: i == days.length - 1
                                  ? FigBrand.amber
                                  : FigBrand.amber.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(labels[days[i].weekday - 1],
                            style: FigText.caption.copyWith(
                                fontSize: 11,
                                fontWeight: i == days.length - 1
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                color: i == days.length - 1
                                    ? FigBrand.amber
                                    : c.textFaint)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Residences triees par charge, avec une jauge des tickets a traiter.
  Widget _residences(BuildContext context, GiColors c) {
    if (store.loading) {
      return const GiSkeletonList(
          count: 3, itemHeight: 76, padding: EdgeInsets.zero);
    }
    final rows = [
      for (final r in store.residences)
        (
          r,
          store
              .ticketsOf((r['id'] ?? '').toString())
              .where((t) => ticketStage(t['status']).isActive)
              .length
        )
    ]..sort((a, b) => b.$2.compareTo(a.$2));
    if (rows.isEmpty) {
      return const GiCard(
        child: AdminEmpty(
            icon: Icons.apartment_rounded,
            title: 'Aucune résidence',
            message: 'Aucune résidence n\'est rattachée à votre compte.'),
      );
    }
    final max = rows.first.$2 == 0 ? 1 : rows.first.$2;
    final shown = rows.take(5).toList();
    return GiCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          for (var i = 0; i < shown.length; i++) ...[
            if (i > 0) Divider(height: 1, color: c.innerBorder, indent: 64),
            _residenceRow(context, c, shown[i].$1, shown[i].$2, max),
          ],
        ],
      ),
    );
  }

  Widget _residenceRow(
      BuildContext context, GiColors c, Map r, int active, int max) {
    final id = (r['id'] ?? '').toString();
    final name = (r['name'] ?? '').toString();
    final asset = residenceImageAsset(id: id, name: name);
    return GiPressable(
      pressedScale: 0.98,
      onTap: () => adminPush(
          context, AdminResidenceScreen(store: store, residenceId: id)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 40,
                height: 40,
                child: asset != null
                    ? Image.asset(asset, fit: BoxFit.cover)
                    : ColoredBox(
                        color: FigBrand.amber.withValues(alpha: 0.12),
                        child: const Icon(Icons.apartment_rounded,
                            size: 20, color: FigBrand.amber)),
              ),
            ),
            const SizedBox(width: FigSpace.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: FigText.fieldLabel.copyWith(
                          fontWeight: FontWeight.w600, color: c.textBody)),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: active / max),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                      builder: (context, v, _) => LinearProgressIndicator(
                        value: v,
                        minHeight: 5,
                        backgroundColor: c.innerBorder,
                        color: active == 0 ? FigAlert.success : FigBrand.amber,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: FigSpace.lg),
            Text(active == 0 ? 'OK' : '$active',
                style: FigText.titleMd.copyWith(
                    color: active == 0 ? FigAlert.success : c.textBody)),
            const SizedBox(width: FigSpace.md),
            GiChevron(color: c.textFaint),
          ],
        ),
      ),
    );
  }

  /// Chiffres calcules par le serveur : occupation et revenus du mois.
  List<Widget> _serverStats(GiColors c) {
    final stats = store.dashboard['stats'];
    if (stats is! Map) return const [];
    final occupancy = (stats['occupancyRate'] ?? '').toString();
    final revenue = (stats['monthlyRevenue'] ?? '').toString();
    if (occupancy.isEmpty && revenue.isEmpty) return const [];
    return [
      const SizedBox(height: FigSpace.lg),
      AdminGrid(
        minTileWidth: 150,
        children: [
          if (occupancy.isNotEmpty)
            AdminStatTile(
                icon: Icons.home_work_outlined,
                accent: FigAlert.success,
                label: 'Taux d\'occupation',
                value: occupancy),
          if (revenue.isNotEmpty)
            AdminStatTile(
                icon: Icons.account_balance_wallet_outlined,
                accent: FigBrand.amber,
                label: 'Revenus du mois',
                value: revenue),
        ],
      ),
    ];
  }
}
