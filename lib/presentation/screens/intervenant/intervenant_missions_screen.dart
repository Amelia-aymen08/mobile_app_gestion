import 'package:flutter/material.dart';

import '../../theme/design_tokens.dart';
import '../../theme/gi_colors.dart';
import '../../theme/ticket_status.dart';
import '../../widgets/gi_appear.dart';
import '../../widgets/gi_refresh.dart';
import '../../widgets/gi_scroll_blur.dart';
import '../../widgets/gi_skeleton.dart';
import '../admin/admin_ui.dart';
import 'intervenant_actions.dart';
import 'intervenant_mission_screen.dart';
import 'intervenant_store.dart';
import 'intervenant_ui.dart';

/// Les piles de l'onglet Missions.
enum MissionFilter { todo, current, toStart, done }

extension MissionFilterX on MissionFilter {
  String get label => switch (this) {
        MissionFilter.todo => 'À faire',
        MissionFilter.current => 'En cours',
        MissionFilter.toStart => 'Nouvelles',
        MissionFilter.done => 'Terminées',
      };

  Color? get dot => switch (this) {
        MissionFilter.todo => null,
        MissionFilter.current => TicketStage.inProgress.color,
        MissionFilter.toStart => TicketStage.open.color,
        MissionFilter.done => TicketStage.done.color,
      };

  /// En cours d'abord : on finit ce qu'on a commence avant d'en ouvrir une
  /// autre.
  List<Map<String, dynamic>> of(IntervenantStore s) => switch (this) {
        MissionFilter.todo => [...s.current, ...s.toStart],
        MissionFilter.current => s.current,
        MissionFilter.toStart => s.toStart,
        MissionFilter.done => s.done,
      };
}

/// Onglet Missions : toutes les missions confiees, par pile, avec le bouton
/// qui les fait avancer directement sur la carte.
class IntervenantMissionsScreen extends StatefulWidget {
  final IntervenantStore store;
  final ValueNotifier<MissionFilter> filter;

  const IntervenantMissionsScreen(
      {super.key, required this.store, required this.filter});

  @override
  State<IntervenantMissionsScreen> createState() =>
      _IntervenantMissionsScreenState();
}

class _IntervenantMissionsScreenState extends State<IntervenantMissionsScreen> {
  final _appear = GiAppearWindow();

  IntervenantStore get _store => widget.store;

  Future<void> _act(Map ticket, MissionAction action) =>
      action == MissionAction.start
          ? startMission(context, _store, ticket)
          : finishMission(context, _store, ticket);

  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: Listenable.merge([_store, widget.filter]),
      builder: (context, _) => _build(context));

  Widget _build(BuildContext context) {
    final c = GiColors.of(context);
    final top = MediaQuery.paddingOf(context).top > 0 ? 14.0 : 24.0;
    final filter = widget.filter.value;
    final visible = filter.of(_store);
    final todo = MissionFilter.todo.of(_store).length;

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
                child: AdminPageHeader(
                  title: 'Mes missions',
                  large: true,
                  subtitle: _store.loading
                      ? 'Chargement…'
                      : todo == 0
                          ? 'Tout est à jour'
                          : '$todo à faire · ${_store.done.length} terminées',
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: FigSpace.xl)),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 34,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                      horizontal: FigSpace.pagePadding),
                  itemCount: MissionFilter.values.length,
                  separatorBuilder: (_, __) => const SizedBox(width: FigSpace.md),
                  itemBuilder: (context, i) {
                    final f = MissionFilter.values[i];
                    return AdminFilterChip(
                      label: f.label,
                      dot: f.dot,
                      count: _store.loading ? null : f.of(_store).length,
                      selected: f == filter,
                      onTap: () => widget.filter.value = f,
                    );
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: FigSpace.xl)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                  FigSpace.pagePadding, 0, FigSpace.pagePadding, 150),
              sliver: _list(visible, filter),
            ),
          ],
        ),
      ),
    );
  }

  Widget _list(List<Map<String, dynamic>> visible, MissionFilter filter) {
    Widget box(Widget child) => SliverToBoxAdapter(
        child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220), child: child));
    if (_store.loading) {
      return box(const GiSkeletonList(
          key: ValueKey('loading'), padding: EdgeInsets.zero, itemHeight: 150));
    }
    if (_store.error != null && _store.tickets.isEmpty) {
      return box(AdminLoadError(
          key: const ValueKey('error'),
          message: _store.error,
          onRetry: _store.load));
    }
    if (visible.isEmpty) {
      return box(AdminEmpty(
        key: ValueKey('empty$filter'),
        icon: filter == MissionFilter.done
            ? Icons.history_rounded
            : Icons.task_alt_rounded,
        title: filter == MissionFilter.done
            ? 'Rien de terminé pour l\'instant'
            : 'Aucune mission ici',
        message: filter == MissionFilter.done
            ? 'Vos missions terminées s\'afficheront ici.'
            : 'Quand l\'administration vous confie un ticket, il arrive ici et vous recevez une notification.',
      ));
    }
    _appear.reset(filter);
    return SliverList.separated(
      key: ValueKey(filter),
      itemCount: visible.length,
      separatorBuilder: (_, __) => const SizedBox(height: FigSpace.lg),
      itemBuilder: (context, i) {
        final t = visible[i];
        final id = TicketFields.id(t);
        return _appear.wrap(
          i,
          MissionCard(
            key: ValueKey(id),
            ticket: t,
            busy: _store.busy.contains(id),
            onTap: () => openMission(context, _store, t),
            onAction: (a) => _act(t, a),
          ),
        );
      },
    );
  }
}
