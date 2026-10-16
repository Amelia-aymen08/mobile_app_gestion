import 'package:flutter/material.dart';

import '../../theme/design_tokens.dart';
import '../../theme/gi_colors.dart';
import '../../theme/ticket_status.dart';
import '../../widgets/gi_appear.dart';
import '../../widgets/gi_refresh.dart';
import '../../widgets/gi_skeleton.dart';
import 'admin_new_ticket_screen.dart';
import 'admin_store.dart';
import 'admin_ticket_screen.dart';
import 'admin_ui.dart';
import '../../widgets/gi_scroll_blur.dart';

/// Filtres de la liste des tickets.
enum AdminTicketFilter {
  active,
  toAssign,
  urgent,
  open,
  inProgress,
  sav,
  done,
  rejected,
  all
}

extension AdminTicketFilterX on AdminTicketFilter {
  String get label => switch (this) {
        AdminTicketFilter.active => 'À traiter',
        AdminTicketFilter.toAssign => 'À assigner',
        AdminTicketFilter.urgent => 'Urgents',
        AdminTicketFilter.open => 'Nouveaux',
        AdminTicketFilter.inProgress => 'En cours',
        AdminTicketFilter.sav => 'SAV',
        AdminTicketFilter.done => 'Terminés',
        AdminTicketFilter.rejected => 'Rejetés',
        AdminTicketFilter.all => 'Tous',
      };

  Color? get dot => switch (this) {
        AdminTicketFilter.toAssign => FigBrand.amber,
        AdminTicketFilter.urgent => FigAlert.error,
        AdminTicketFilter.open => TicketStage.open.color,
        AdminTicketFilter.inProgress => TicketStage.inProgress.color,
        AdminTicketFilter.sav => TicketStage.sav.color,
        AdminTicketFilter.done => TicketStage.done.color,
        AdminTicketFilter.rejected => TicketStage.rejected.color,
        _ => null,
      };

  bool test(Map t) {
    final stage = ticketStage(t['status']);
    return switch (this) {
      AdminTicketFilter.active => stage.isActive,
      AdminTicketFilter.toAssign =>
        stage.isActive && TicketFields.assignee(t).isEmpty,
      AdminTicketFilter.urgent => stage.isActive &&
          ticketPriority(t['priority']) == TicketPriority.urgent,
      AdminTicketFilter.open => stage == TicketStage.open,
      AdminTicketFilter.inProgress => stage == TicketStage.inProgress,
      AdminTicketFilter.sav => stage == TicketStage.sav,
      AdminTicketFilter.done => stage == TicketStage.done,
      AdminTicketFilter.rejected => stage == TicketStage.rejected,
      AdminTicketFilter.all => true,
    };
  }
}

/// Filtre pose de l'exterieur : un chiffre de l'accueil ouvre la liste deja
/// filtree sur ce qu'il compte.
class AdminTicketsController extends ChangeNotifier {
  AdminTicketFilter filter = AdminTicketFilter.active;
  String residenceId = '';

  void show(AdminTicketFilter f, {String residenceId = ''}) {
    filter = f;
    this.residenceId = residenceId;
    notifyListeners();
  }
}

/// Liste des tickets de l'administration.
///
/// Ouverte par defaut sur « A traiter » : ce qui reste a faire, pas
/// l'archive. Chaque puce dit combien elle contient avant qu'on la touche.
/// Sur ordinateur les cartes se rangent en grille.
class AdminTicketsScreen extends StatefulWidget {
  final AdminStore store;
  final AdminTicketsController controller;
  const AdminTicketsScreen(
      {super.key, required this.store, required this.controller});

  @override
  State<AdminTicketsScreen> createState() => _AdminTicketsScreenState();
}

class _AdminTicketsScreenState extends State<AdminTicketsScreen> {
  final _search = TextEditingController();
  bool _urgentFirst = false;

  AdminStore get _store => widget.store;
  AdminTicketsController get _ctrl => widget.controller;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matchesQuery(Map t, String q) {
    if (q.isEmpty) return true;
    final hay = [
      t['title'],
      t['description'],
      t['category'],
      t['location'],
      TicketFields.ref(t),
      _store.residenceNameOf(t),
      TicketFields.assignee(t),
      TicketFields.requester(t),
    ].join(' ').toLowerCase();
    return hay.contains(q);
  }

  Future<void> _newTicket() async {
    final created = await adminPush<bool>(context,
        AdminNewTicketScreen(store: _store, residenceId: _ctrl.residenceId));
    if (created == true && mounted) {
      await _store.load();
      if (mounted) showAdminToast(context, 'Ticket créé');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_store, _ctrl]),
      builder: (context, _) => _build(context),
    );
  }

  Widget _build(BuildContext context) {
    final c = GiColors.of(context);
    final q = _search.text.trim().toLowerCase();
    final byResidence = _ctrl.residenceId.isEmpty
        ? _store.tickets
        : _store.ticketsOf(_ctrl.residenceId);
    final searched = byResidence.where((t) => _matchesQuery(t, q)).toList();
    final visible = searched.where(_ctrl.filter.test).toList();
    if (_urgentFirst) {
      visible.sort((a, b) => ticketPriority(a['priority'])
          .rank
          .compareTo(ticketPriority(b['priority']).rank));
    }
    final active = _store.count((t) => ticketStage(t['status']).isActive);
    final top = MediaQuery.paddingOf(context).top > 0 ? 14.0 : 24.0;

    return Scaffold(
      backgroundColor: c.scaffold,
      body: GiScrollBlur(
        child: CustomScrollView(
          clipBehavior: Clip.none,
          physics: giRefreshPhysics,
          slivers: [
            GiRefreshControl(onRefresh: _store.load),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                    FigSpace.pagePadding, top, FigSpace.pagePadding, 0),
                child: AdminContent(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AdminPageHeader(
                        title: 'Tickets',
                        large: true,
                        subtitle: _store.loading
                            ? 'Chargement…'
                            : '$active à traiter · ${_store.tickets.length} au total',
                        actions: [
                          AdminSquareButton(
                            tooltip: _urgentFirst
                                ? 'Trier par date'
                                : 'Urgents en premier',
                            onTap: () =>
                                setState(() => _urgentFirst = !_urgentFirst),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                  _urgentFirst
                                      ? Icons.local_fire_department_rounded
                                      : Icons.schedule_rounded,
                                  key: ValueKey(_urgentFirst),
                                  size: 19,
                                  color: _urgentFirst
                                      ? FigAlert.error
                                      : c.textBody),
                            ),
                          ),
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
                      AdminSearchField(
                          controller: _search,
                          hint: 'Titre, résidence, intervenant, #réf…'),
                    ],
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: FigSpace.lg)),
            SliverToBoxAdapter(child: _filters(searched)),
            if (_store.residences.length > 1) ...[
              const SliverToBoxAdapter(child: SizedBox(height: FigSpace.md)),
              SliverToBoxAdapter(child: _residenceFilters()),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: FigSpace.xl)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                  FigSpace.pagePadding, 0, FigSpace.pagePadding, 150),
              sliver: SliverToBoxAdapter(
                child: AdminContent(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    switchInCurve: Curves.easeOut,
                    child: KeyedSubtree(
                      key: ValueKey(
                          '${_store.loading}${_ctrl.filter}${_ctrl.residenceId}$_urgentFirst'),
                      child: _store.loading
                          ? const GiSkeletonList(
                              padding: EdgeInsets.zero, itemHeight: 120)
                          : visible.isEmpty
                              ? AdminEmpty(
                                  icon: q.isNotEmpty
                                      ? Icons.search_off_rounded
                                      : Icons.task_alt_rounded,
                                  title: q.isNotEmpty
                                      ? 'Aucun résultat'
                                      : 'Rien ici',
                                  message: q.isNotEmpty
                                      ? 'Aucun ticket ne correspond à « ${_search.text} ».'
                                      : 'Aucun ticket dans « ${_ctrl.filter.label} ».',
                                )
                              : AdminGrid(
                                  minTileWidth: 360,
                                  children: [
                                    for (var i = 0; i < visible.length; i++)
                                      GiAppear(
                                        index: i.clamp(0, 8),
                                        child: AdminTicketCard(
                                          ticket: visible[i],
                                          residenceName: _store
                                              .residenceNameOf(visible[i]),
                                          showResidence:
                                              _ctrl.residenceId.isEmpty,
                                          onTap: () => openAdminTicket(
                                              context, _store, visible[i]),
                                        ),
                                      ),
                                  ],
                                ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filters(List<Map<String, dynamic>> pool) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: FigSpace.pagePadding),
        itemCount: AdminTicketFilter.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: FigSpace.md),
        itemBuilder: (context, i) {
          final f = AdminTicketFilter.values[i];
          return AdminFilterChip(
            label: f.label,
            dot: f.dot,
            count: _store.loading ? null : pool.where(f.test).length,
            selected: f == _ctrl.filter,
            onTap: () => _ctrl.show(f, residenceId: _ctrl.residenceId),
          );
        },
      ),
    );
  }

  Widget _residenceFilters() {
    final items = [
      ('', 'Toutes les résidences'),
      for (final r in _store.residences)
        ((r['id'] ?? '').toString(), (r['name'] ?? '').toString()),
    ];
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: FigSpace.pagePadding),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: FigSpace.md),
        itemBuilder: (context, i) {
          final (id, name) = items[i];
          return AdminFilterChip(
            label: name,
            selected: id == _ctrl.residenceId,
            onTap: () => _ctrl.show(_ctrl.filter, residenceId: id),
          );
        },
      ),
    );
  }
}
