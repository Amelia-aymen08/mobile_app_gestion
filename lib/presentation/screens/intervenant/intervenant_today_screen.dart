import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../data/person_name.dart';
import '../../theme/design_tokens.dart';
import '../../theme/gi_colors.dart';
import '../../theme/ticket_status.dart';
import '../../widgets/gi_appear.dart';
import '../../widgets/gi_pressable.dart';
import '../../widgets/gi_refresh.dart';
import '../../widgets/gi_scroll_blur.dart';
import '../../widgets/gi_skeleton.dart';
import '../admin/admin_ui.dart';
import 'intervenant_actions.dart';
import 'intervenant_mission_screen.dart';
import 'intervenant_missions_screen.dart';
import 'intervenant_store.dart';
import 'intervenant_ui.dart';

/// Accueil de l'intervenant : la mission a traiter maintenant, en grand,
/// avec son bouton ; puis ce qui attend.
///
/// Il ouvre l'app sur le terrain, souvent d'une main : la premiere chose a
/// l'ecran repond a « qu'est-ce que je fais maintenant ? ».
class IntervenantTodayScreen extends StatefulWidget {
  final IntervenantStore store;
  final Map? user;
  final int unread;
  final VoidCallback openNotifications;
  final ValueChanged<MissionFilter> openMissions;

  const IntervenantTodayScreen({
    super.key,
    required this.store,
    required this.user,
    required this.unread,
    required this.openNotifications,
    required this.openMissions,
  });

  @override
  State<IntervenantTodayScreen> createState() => _IntervenantTodayScreenState();
}

class _IntervenantTodayScreenState extends State<IntervenantTodayScreen> {
  final _scroll = ScrollController();
  Timer? _tick;

  IntervenantStore get _store => widget.store;

  @override
  void initState() {
    super.initState();
    // « Commencee il y a… » avance seul.
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _act(Map ticket, MissionAction action) async {
    if (action == MissionAction.finish) {
      await finishMission(context, _store, ticket);
      return;
    }
    await startMission(context, _store, ticket);
    // La mission commencee devient celle du moment, en haut de l'ecran :
    // on y remonte pour qu'il la voie avec son bouton « J'ai terminé ».
    if (mounted && _scroll.hasClients && _scroll.offset > 0) {
      _scroll.animateTo(0,
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) =>
      ListenableBuilder(listenable: _store, builder: (context, _) => _build(context));

  Widget _build(BuildContext context) {
    final c = GiColors.of(context);
    final top = MediaQuery.paddingOf(context).top > 0 ? 14.0 : 24.0;
    final first = PersonName.format(
            widget.user?['name'] ?? widget.user?['fullName'])
        .split(' ')
        .first;
    final today = _frenchDate(DateTime.now());

    final current = _store.current;
    final toStart = _store.toStart;
    // La mission mise en avant : celle qu'il a en main, sinon la plus
    // urgente de celles qui attendent.
    final focus = current.isNotEmpty
        ? current.first
        : (toStart.isNotEmpty ? toStart.first : null);
    final focusId = focus == null ? '' : TicketFields.id(focus);
    final others = [...current, ...toStart]
        .where((t) => TicketFields.id(t) != focusId)
        .toList();

    var i = 0;
    Widget appear(Widget w) => GiAppear(index: i++, child: w);

    return Scaffold(
      backgroundColor: c.scaffold,
      body: GiScrollBlur(
        child: CustomScrollView(
          controller: _scroll,
          clipBehavior: Clip.none,
          physics: giRefreshPhysics,
          slivers: [
            GiRefreshControl(onRefresh: _store.load),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                  FigSpace.pagePadding, top, FigSpace.pagePadding, 150),
              sliver: SliverList.list(children: [
                AdminPageHeader(
                  title: first.isEmpty ? 'Bonjour' : 'Bonjour $first',
                  subtitle: today,
                  large: true,
                  actions: [_bell(c)],
                ),
                const SizedBox(height: FigSpace.xl + 4),
                if (_store.loading) ...[
                  const GiShimmer(child: GiBone(height: 210, radius: 20)),
                  const SizedBox(height: FigSpace.lg),
                  const GiShimmer(child: GiBone(height: 96, radius: 16)),
                ] else if (_store.error != null && _store.tickets.isEmpty)
                  AdminLoadError(message: _store.error, onRetry: _store.load)
                else ...[
                  appear(focus == null
                      ? _allClear(c)
                      : _FocusCard(
                          ticket: focus,
                          busy: _store.busy.contains(focusId),
                          onOpen: () => openMission(context, _store, focus),
                          onAction: (a) => _act(focus, a),
                        )),
                  const SizedBox(height: FigSpace.lg),
                  appear(_stats(c)),
                  if (others.isNotEmpty) ...[
                    const SizedBox(height: FigSpace.xxl),
                    appear(AdminSectionTitle(
                      'Ensuite',
                      count: '${others.length}',
                      action: others.length > 3 ? 'Tout voir' : null,
                      onAction: () => widget.openMissions(MissionFilter.todo),
                    )),
                    const SizedBox(height: FigSpace.lg),
                    for (final t in others.take(3)) ...[
                      appear(MissionCard(
                        key: ValueKey(TicketFields.id(t)),
                        ticket: t,
                        busy: _store.busy.contains(TicketFields.id(t)),
                        onTap: () => openMission(context, _store, t),
                        onAction: (a) => _act(t, a),
                      )),
                      const SizedBox(height: FigSpace.lg),
                    ],
                  ],
                ],
              ]),
            ),
          ],
        ),
      ),
    );
  }

  /// « Mardi 28 octobre ». Ecrit a la main : les symboles de date d'intl ne
  /// sont charges que pour la langue de l'app, et l'espace est en francais.
  static String _frenchDate(DateTime d) {
    const days = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    const months = ['janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet',
        'août', 'septembre', 'octobre', 'novembre', 'décembre'];
    return '${days[d.weekday - 1]} ${d.day} ${months[d.month - 1]}';
  }

  Widget _bell(GiColors c) => Stack(
        clipBehavior: Clip.none,
        children: [
          AdminSquareButton(
            tooltip: 'Notifications',
            onTap: widget.openNotifications,
            child: SvgPicture.asset('assets/figma/icons/bell_16.svg',
                width: 18,
                colorFilter: ColorFilter.mode(c.textBody, BlendMode.srcIn)),
          ),
          if (widget.unread > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                constraints: const BoxConstraints(minWidth: 18),
                height: 18,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: FigBrand.amber,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: c.scaffold, width: 2),
                ),
                child: Text(widget.unread > 9 ? '9+' : '${widget.unread}',
                    style: FigText.caption.copyWith(
                        fontSize: 10,
                        color: Colors.black,
                        fontWeight: FontWeight.w700)),
              ),
            ),
        ],
      );

  Widget _stats(GiColors c) {
    Widget tile(String value, String label, Color accent, IconData icon,
            MissionFilter f) =>
        Expanded(
          child: GiPressable(
            pressedScale: 0.96,
            onTap: () => widget.openMissions(f),
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              decoration: BoxDecoration(
                color: c.card,
                border: Border.all(color: c.cardBorder),
                borderRadius: BorderRadius.circular(FigRadius.card),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 18, color: accent),
                  const SizedBox(height: FigSpace.md),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    child: Text(value,
                        key: ValueKey(value),
                        style: FigText.greeting
                            .copyWith(fontSize: 24, color: c.textBody)),
                  ),
                  Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: FigText.label.copyWith(color: c.textMuted)),
                ],
              ),
            ),
          ),
        );

    return Row(
      children: [
        tile('${_store.toStart.length}', 'Nouvelles', TicketStage.open.color,
            Icons.inbox_rounded, MissionFilter.toStart),
        const SizedBox(width: FigSpace.md),
        tile('${_store.current.length}', 'En cours',
            TicketStage.inProgress.color, Icons.autorenew_rounded,
            MissionFilter.current),
        const SizedBox(width: FigSpace.md),
        tile('${_store.doneThisWeek}', 'Finies · 7 j', TicketStage.done.color,
            Icons.check_circle_outline_rounded, MissionFilter.done),
      ],
    );
  }

  Widget _allClear(GiColors c) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: FigAlert.success.withValues(alpha: 0.08),
          border: Border.all(color: FigAlert.success.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: FigAlert.success.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.task_alt_rounded,
                  size: 28, color: FigAlert.success),
            ),
            const SizedBox(width: FigSpace.xl),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tout est à jour',
                      style: FigText.titleMd
                          .copyWith(fontSize: 18, color: c.textBody)),
                  const SizedBox(height: 4),
                  Text(
                      'Aucune mission en attente. Vous serez prévenu dès qu\'on vous en confie une.',
                      style: FigText.body
                          .copyWith(height: 1.4, color: c.textMuted)),
                ],
              ),
            ),
          ],
        ),
      );
}

/// La mission du moment, sur la surface sombre de la marque : ce qu'elle
/// est, ou, depuis quand, et le bouton pour la faire avancer.
class _FocusCard extends StatelessWidget {
  final Map ticket;
  final bool busy;
  final VoidCallback onOpen;
  final ValueChanged<MissionAction> onAction;

  const _FocusCard({
    required this.ticket,
    required this.busy,
    required this.onOpen,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    final stage = IntervenantStore.stageOf(ticket);
    final priority = ticketPriority(ticket['priority']);
    final action = missionActionOf(ticket);
    final started = IntervenantStore.startedAt(ticket);
    final place = missionPlace(ticket);
    final inProgress = started != null;

    final eyebrow = inProgress ? 'EN COURS' : 'PROCHAINE MISSION';
    final when = inProgress
        ? (DateTime.now().difference(started).inMinutes < 1
            ? "Commencée à l'instant"
            : 'Depuis ${durationLabel(DateTime.now().difference(started))}')
        : 'Confiée ${timeAgoLabel(TicketFields.created(ticket)).toLowerCase()}';
    const white = Colors.white;
    final soft = white.withValues(alpha: 0.7);

    return GiPressable(
      pressedScale: 0.985,
      onTap: onOpen,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: c.navbarBg,
          border: Border.all(color: c.navbarBorder),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _Pulse(color: stage.color, active: inProgress),
                const SizedBox(width: FigSpace.md),
                Text(eyebrow,
                    style: FigText.caption.copyWith(
                        fontSize: 11,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w700,
                        color: stage.color)),
                const Spacer(),
                if (priority == TicketPriority.urgent ||
                    priority == TicketPriority.high)
                  AdminPill.priority(priority, dense: true),
              ],
            ),
            const SizedBox(height: FigSpace.lg),
            Text(TicketFields.title(ticket),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: FigText.titleMd
                    .copyWith(fontSize: 21, height: 1.2, color: white)),
            if (place.isNotEmpty) ...[
              const SizedBox(height: FigSpace.sm),
              Row(
                children: [
                  Icon(Icons.place_outlined, size: 15, color: soft),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(place,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: FigText.body.copyWith(color: soft)),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.schedule_rounded, size: 15, color: soft),
                const SizedBox(width: 4),
                Text(when, style: FigText.body.copyWith(color: soft)),
              ],
            ),
            const SizedBox(height: FigSpace.xl),
            if (action != null)
              MissionActionButton(
                action: action,
                busy: busy,
                large: true,
                onTap: () => onAction(action),
              ),
            const SizedBox(height: FigSpace.md),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Voir la fiche',
                        style: FigText.bodyActive.copyWith(color: soft)),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded, size: 18, color: soft),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Point qui bat doucement tant que la mission est en cours.
class _Pulse extends StatefulWidget {
  final Color color;
  final bool active;
  const _Pulse({required this.color, required this.active});

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400));

  @override
  void initState() {
    super.initState();
    if (widget.active) _c.repeat();
  }

  @override
  void didUpdateWidget(_Pulse old) {
    super.didUpdateWidget(old);
    if (widget.active && !_c.isAnimating) _c.repeat();
    if (!widget.active) _c.stop();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 14,
        height: 14,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => Stack(
            alignment: Alignment.center,
            children: [
              if (widget.active)
                Container(
                  width: 6 + 8 * _c.value,
                  height: 6 + 8 * _c.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color.withValues(alpha: 0.5 * (1 - _c.value)),
                  ),
                ),
              Container(
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(shape: BoxShape.circle, color: widget.color),
              ),
            ],
          ),
        ),
      );
}
