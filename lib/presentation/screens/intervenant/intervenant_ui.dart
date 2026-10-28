import 'package:flutter/material.dart';

import '../../theme/design_tokens.dart';
import '../../theme/gi_colors.dart';
import '../../theme/ticket_status.dart';
import '../../widgets/gi_card.dart';
import '../../widgets/gi_pressable.dart';
import '../admin/admin_ui.dart';
import 'intervenant_store.dart';

/// Ou se trouve la mission : « Corail · Bloc B ».
String missionPlace(Map t) => adminPlaceLabel(
    TicketFields.residenceName(t), (t['location'] ?? '').toString());

/// « 40 min », « 1 h 20 », « 2 j ».
String durationLabel(Duration d) {
  if (d.inMinutes < 1) return "moins d'une minute";
  if (d.inMinutes < 60) return '${d.inMinutes} min';
  if (d.inHours < 24) {
    final m = d.inMinutes % 60;
    return m == 0 ? '${d.inHours} h' : '${d.inHours} h ${m.toString().padLeft(2, '0')}';
  }
  return '${d.inDays} j';
}

/// Ce que la carte dit du temps : depuis quand la mission attend, ou depuis
/// quand elle est commencee.
String missionTimeLabel(Map t) {
  final started = IntervenantStore.startedAt(t);
  if (started != null) {
    final d = DateTime.now().difference(started);
    return d.inMinutes < 1
        ? "Commencée à l'instant"
        : 'Commencée il y a ${durationLabel(d)}';
  }
  return timeAgoLabel(TicketFields.created(t));
}

/// La seule action qui fait avancer une mission depuis l'etat ou elle est.
enum MissionAction { start, finish }

MissionAction? missionActionOf(Map t) => switch (IntervenantStore.stageOf(t)) {
      TicketStage.open => MissionAction.start,
      TicketStage.inProgress || TicketStage.sav => MissionAction.finish,
      _ => null,
    };

extension MissionActionX on MissionAction {
  String get label => switch (this) {
        MissionAction.start => 'Commencer',
        MissionAction.finish => "J'ai terminé",
      };

  IconData get icon => switch (this) {
        MissionAction.start => Icons.play_arrow_rounded,
        MissionAction.finish => Icons.check_rounded,
      };

  Color get color => switch (this) {
        MissionAction.start => FigBrand.amber,
        MissionAction.finish => FigAlert.success,
      };
}

/// Bouton d'action d'une mission. Pendant l'envoi, le libelle laisse la
/// place a une roue, a la meme taille : la carte ne saute pas.
class MissionActionButton extends StatelessWidget {
  final MissionAction action;
  final bool busy;
  final VoidCallback onTap;
  final bool large;

  const MissionActionButton({
    super.key,
    required this.action,
    required this.busy,
    required this.onTap,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = (large ? FigText.button : FigText.bodyActive)
        .copyWith(color: Colors.black);
    return GiPressable(
      pressedScale: 0.97,
      onTap: busy ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: EdgeInsets.symmetric(vertical: large ? 16 : 12, horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: action.color.withValues(alpha: busy ? 0.6 : 1),
          borderRadius: BorderRadius.circular(FigRadius.cta),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: busy
              ? SizedBox(
                  key: const ValueKey('busy'),
                  width: style.fontSize! * 1.25,
                  height: style.fontSize! * 1.25,
                  child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.black)),
                )
              : Row(
                  key: ValueKey(action),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(action.icon, size: large ? 22 : 18, color: Colors.black),
                    const SizedBox(width: FigSpace.sm),
                    Flexible(
                      child: Text(action.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: style),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Carte d'une mission.
///
/// Elle dit de quoi il s'agit, ou, avec quelle urgence et depuis quand, et
/// porte le bouton qui fait avancer la mission : commencer ou terminer se
/// fait depuis la liste, sans ouvrir la fiche.
class MissionCard extends StatelessWidget {
  final Map ticket;
  final bool busy;
  final VoidCallback onTap;
  final ValueChanged<MissionAction>? onAction;

  const MissionCard({
    super.key,
    required this.ticket,
    required this.onTap,
    this.busy = false,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    final stage = IntervenantStore.stageOf(ticket);
    final priority = ticketPriority(ticket['priority']);
    final place = missionPlace(ticket);
    final action = onAction == null ? null : missionActionOf(ticket);
    final urgent =
        priority == TicketPriority.urgent || priority == TicketPriority.high;

    return GiCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      borderColor: priority == TicketPriority.urgent && stage.isActive
          ? FigAlert.error.withValues(alpha: 0.35)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminCategoryTile(
                  category: (ticket['category'] ?? '').toString(),
                  color: stage.color),
              const SizedBox(width: FigSpace.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(TicketFields.title(ticket),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: FigText.statValue.copyWith(
                            fontSize: 15, height: 1.25, color: c.textBody)),
                    if (place.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.place_outlined,
                              size: 13, color: c.textMuted),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(place,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: FigText.label
                                    .copyWith(color: c.textMuted)),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: FigSpace.md),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: GiChevron(color: c.textFaint),
              ),
            ],
          ),
          const SizedBox(height: FigSpace.lg),
          Row(
            children: [
              Flexible(child: AdminPill.stage(stage, dense: true)),
              if (urgent) ...[
                const SizedBox(width: FigSpace.sm),
                Flexible(child: AdminPill.priority(priority, dense: true)),
              ],
              const SizedBox(width: FigSpace.md),
              // Le temps cede la place aux pastilles, jamais l'inverse.
              Expanded(
                child: Text(missionTimeLabel(ticket),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: FigText.caption
                        .copyWith(fontSize: 11, color: c.textFaint)),
              ),
            ],
          ),
          if (action != null) ...[
            const SizedBox(height: FigSpace.lg),
            MissionActionButton(
              action: action,
              busy: busy,
              onTap: () => onAction!(action),
            ),
          ],
        ],
      ),
    );
  }
}
