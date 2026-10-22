import 'package:flutter/material.dart';

import '../../../data/api_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../theme/amenities.dart';
import '../../theme/design_tokens.dart';
import '../../theme/gi_colors.dart';
import '../../widgets/gi_appear.dart';
import '../../widgets/gi_card.dart';
import '../../widgets/gi_refresh.dart';
import '../../widgets/gi_residence_card.dart';
import '../../widgets/gi_skeleton.dart';
import 'admin_new_ticket_screen.dart';
import 'admin_resident_screen.dart';
import 'admin_store.dart';
import 'admin_ticket_screen.dart';
import 'admin_tickets_screen.dart';
import 'admin_ui.dart';

/// Fiche d'une residence pour l'administration.
///
/// La photo et le bandeau de l'espace resident, puis tout ce qui s'y passe :
/// les chiffres du jour, les tickets — chacun s'ouvre —, les residents et
/// la presentation. Sur ordinateur, tickets a gauche, residents et
/// presentation a droite.
class AdminResidenceScreen extends StatefulWidget {
  final AdminStore store;
  final String residenceId;
  const AdminResidenceScreen(
      {super.key, required this.store, required this.residenceId});

  @override
  State<AdminResidenceScreen> createState() => _AdminResidenceScreenState();
}

class _AdminResidenceScreenState extends State<AdminResidenceScreen> {
  final ApiService _api = ApiService();
  Map<String, dynamic> _details = const {};
  List<Map<String, dynamic>>? _residents;
  bool _residentsFailed = false;
  AdminTicketFilter _filter = AdminTicketFilter.active;

  AdminStore get _store => widget.store;
  Map<String, dynamic> get _residence => {
        ...?_store.residence(widget.residenceId),
        ..._details,
      };

  @override
  void initState() {
    super.initState();
    _loadExtras();
  }

  Future<void> _loadExtras() async {
    final results = await Future.wait<Object?>([
      _api
          .getResidence(widget.residenceId)
          .then<Object?>((v) => v)
          .catchError((_) => null),
      _store.residents().then<Object?>((v) => v).catchError((_) => null),
    ]);
    if (!mounted) return;
    setState(() {
      if (results[0] is Map<String, dynamic>) {
        _details = results[0] as Map<String, dynamic>;
      }
      final all = results[1];
      _residentsFailed = all is! List<Map<String, dynamic>>;
      _residents = all is List<Map<String, dynamic>>
          ? all.where(_livesHere).toList()
          : const [];
    });
  }

  bool _livesHere(Map r) {
    final res = r['residence'] ?? r['Residence'];
    final id =
        (r['residenceId'] ?? (res is Map ? res['id'] : '') ?? '').toString();
    if (id.isNotEmpty) return id == widget.residenceId;
    final name = res is Map ? (res['name'] ?? '').toString() : '';
    return name.isNotEmpty &&
        name.toLowerCase() ==
            (_residence['name'] ?? '').toString().toLowerCase();
  }

  Future<void> _refresh() async {
    await Future.wait([_store.load(), _loadExtras()]);
  }

  Future<void> _newTicket() async {
    final ok = await openAdminTicketForm(context, _residence);
    if (ok && mounted) {
      await _store.load();
      if (mounted) showAdminToast(context, 'Ticket créé');
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: _store,
        builder: (context, _) => _build(context),
      );

  Widget _build(BuildContext context) {
    final c = GiColors.of(context);
    final r = _residence;
    final name = (r['name'] ?? '').toString();
    final address = (r['address'] ?? '').toString();
    final tickets = _store.ticketsOf(widget.residenceId);
    final wide = MediaQuery.sizeOf(context).width >= kAdminWide;
    final top = MediaQuery.paddingOf(context).top > 0 ? 14.0 : 24.0;

    final units = r['totalUnits'];
    final delivered = r['deliveredUnits'];
    final occupancy = (r['occupancyRate'] ?? '').toString();
    final zone = (r['zone'] ?? '').toString().trim();

    final cover = GiResidenceCard(
      id: widget.residenceId,
      name: name,
      address: address,
      imageUrl: _api.mediaUrl(r['image']),
      eyebrow: zone.isEmpty ? 'Résidence' : 'Zone $zone',
      height: wide ? 230 : FigSize.heroH,
      stats: [
        if (units != null) GiResidenceStat('Unités', '$units'),
        if (delivered != null) GiResidenceStat('Livrées', '$delivered'),
        if (occupancy.isNotEmpty) GiResidenceStat('Occupation', occupancy),
        if (units == null && delivered == null && occupancy.isEmpty) ...[
          GiResidenceStat('Tickets', '${tickets.length}'),
          GiResidenceStat('Résidents', '${_residents?.length ?? '—'}'),
        ],
      ],
    );

    final ticketsColumn = <Widget>[
      _kpis(tickets),
      const SizedBox(height: FigSpace.xl + 4),
      AdminSectionTitle('Tickets',
          count: '${tickets.length}', action: 'Nouveau', onAction: _newTicket),
      const SizedBox(height: FigSpace.lg),
      _ticketFilters(tickets),
      const SizedBox(height: FigSpace.lg),
      _ticketList(tickets),
    ];

    final sideColumn = <Widget>[
      AdminSectionTitle('Résidents',
          count: _residents == null ? null : '${_residents!.length}'),
      const SizedBox(height: FigSpace.lg),
      _residentsCard(c),
      ..._about(c),
    ];

    return Scaffold(
      backgroundColor: c.scaffold,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: giRefreshPhysics,
          slivers: [
            GiRefreshControl(onRefresh: _refresh),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                  FigSpace.pagePadding,
                  top,
                  FigSpace.pagePadding,
                  MediaQuery.paddingOf(context).bottom + 40),
              sliver: SliverToBoxAdapter(
                child: AdminContent(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AdminPageHeader(
                        back: true,
                        title: name.isEmpty ? 'Résidence' : name,
                        subtitle: address,
                        actions: [
                          AdminSquareButton(
                            tooltip: 'Nouveau ticket',
                            filled: true,
                            onTap: _newTicket,
                            child: const Icon(Icons.add_rounded,
                                size: 22, color: Colors.black),
                          ),
                        ],
                      ),
                      const SizedBox(height: FigSpace.xl),
                      // La photo arrive avec la page, sans fondu differe.
                      cover,
                      const SizedBox(height: FigSpace.xl),
                      if (wide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: ticketsColumn),
                            ),
                            const SizedBox(width: FigSpace.xxl),
                            Expanded(
                              flex: 2,
                              child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: sideColumn),
                            ),
                          ],
                        )
                      else ...[
                        ...ticketsColumn,
                        const SizedBox(height: FigSpace.xl + 4),
                        ...sideColumn,
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

  /// Quatre chiffres, qui filtrent la liste juste en dessous.
  Widget _kpis(List<Map<String, dynamic>> tickets) {
    int n(AdminTicketFilter f) => tickets.where(f.test).length;
    Widget tile(AdminTicketFilter f, IconData icon, Color accent) =>
        AdminStatTile(
          icon: icon,
          accent: accent,
          label: f.label,
          value: '${n(f)}',
          onTap: () => setState(() => _filter = f),
        );
    return LayoutBuilder(builder: (context, constraints) {
      final tiles = [
        tile(AdminTicketFilter.active, Icons.inbox_rounded, FigBrand.amber),
        tile(AdminTicketFilter.toAssign, Icons.person_add_alt_1_rounded,
            FigAccent.violet),
        tile(AdminTicketFilter.urgent, Icons.priority_high_rounded,
            FigAlert.error),
        tile(AdminTicketFilter.done, Icons.check_circle_outline_rounded,
            FigAlert.success),
      ];
      final cols = constraints.maxWidth > 560 ? 4 : 2;
      return AdminGrid(
          minTileWidth: constraints.maxWidth / cols - 1, children: tiles);
    });
  }

  Widget _ticketFilters(List<Map<String, dynamic>> tickets) {
    const filters = [
      AdminTicketFilter.active,
      AdminTicketFilter.toAssign,
      AdminTicketFilter.urgent,
      AdminTicketFilter.done,
      AdminTicketFilter.all,
    ];
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: FigSpace.md),
        itemBuilder: (context, i) => AdminFilterChip(
          label: filters[i].label,
          dot: filters[i].dot,
          count: tickets.where(filters[i].test).length,
          selected: filters[i] == _filter,
          onTap: () => setState(() => _filter = filters[i]),
        ),
      ),
    );
  }

  Widget _ticketList(List<Map<String, dynamic>> tickets) {
    final visible = tickets.where(_filter.test).toList();
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      child: KeyedSubtree(
        key: ValueKey('$_filter${_store.loading}'),
        child: _store.loading
            ? const GiSkeletonList(
                count: 3, itemHeight: 120, padding: EdgeInsets.zero)
            : visible.isEmpty
                ? GiCard(
                    child: AdminEmpty(
                      icon: Icons.task_alt_rounded,
                      title: 'Rien à signaler',
                      message: 'Aucun ticket dans « ${_filter.label} ».',
                    ),
                  )
                : AdminGrid(
                    minTileWidth: 360,
                    children: [
                      for (var i = 0; i < visible.length; i++)
                        GiAppear(
                          index: i.clamp(0, 6),
                          child: AdminTicketCard(
                            ticket: visible[i],
                            residenceName: _store.residenceNameOf(visible[i]),
                            showResidence: false,
                            onTap: () =>
                                openAdminTicket(context, _store, visible[i]),
                          ),
                        ),
                    ],
                  ),
      ),
    );
  }

  Widget _residentsCard(GiColors c) {
    final list = _residents;
    if (list == null) {
      return const GiSkeletonList(
          count: 3, itemHeight: 76, padding: EdgeInsets.zero);
    }
    if (list.isEmpty && _residentsFailed) {
      return GiCard(
        child: AdminLoadError(
            message: 'La liste des résidents n\'a pas pu être chargée.',
            onRetry: () {
              setState(() => _residents = null);
              _loadExtras();
            }),
      );
    }
    if (list.isEmpty) {
      return const GiCard(
        child: AdminEmpty(
          icon: Icons.people_outline_rounded,
          title: 'Aucun résident',
          message: 'Aucun résident n\'est encore inscrit ici.',
        ),
      );
    }
    const max = 6;
    return GiCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          for (var i = 0; i < list.length && i < max; i++) ...[
            if (i > 0) Divider(height: 1, color: c.innerBorder, indent: 64),
            adminResidentRow(context, _store, list[i], showResidence: false),
          ],
          if (list.length > max) ...[
            Divider(height: 1, color: c.innerBorder),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: AdminSectionTitle('',
                  action: 'Voir les ${list.length} résidents',
                  onAction: () => adminPush(
                      context,
                      AdminResidentsScreen(
                          store: _store, residenceId: widget.residenceId))),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _about(GiColors c) {
    final description = (_details['description'] ?? '').toString().trim();
    final raw = _details['amenities'];
    final amenities = raw is List
        ? raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
        : raw is String
            ? raw
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList()
            : <String>[];
    if (description.isEmpty && amenities.isEmpty) return const [];
    final t = AppL10n.of(context);
    return [
      const SizedBox(height: FigSpace.xl + 4),
      const AdminSectionTitle('Présentation'),
      const SizedBox(height: FigSpace.lg),
      GiCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (description.isNotEmpty)
              Text(description,
                  style: FigText.fieldLabel
                      .copyWith(height: 1.55, color: c.textMuted)),
            if (description.isNotEmpty && amenities.isNotEmpty)
              const SizedBox(height: FigSpace.xl),
            if (amenities.isNotEmpty)
              Wrap(
                spacing: FigSpace.md,
                runSpacing: FigSpace.md,
                children: [
                  for (final key in amenities)
                    AdminPill(amenityLabel(t, key), FigBrand.amber,
                        icon: Icons.circle, dense: true),
                ],
              ),
          ],
        ),
      ),
    ];
  }
}
