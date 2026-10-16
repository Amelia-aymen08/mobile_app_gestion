import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/design_tokens.dart';
import '../theme/gi_colors.dart';

/// Avancement d'un signalement en une bande : trois jalons — signale, pris
/// en charge, cloture — relies par une barre qui se remplit.
///
/// Version compacte du suivi vertical de la fiche, pour les ecrans ou le
/// signalement n'est pas le sujet principal (la conversation).
class TicketProgressStrip extends StatelessWidget {
  /// Statut du ticket tel que le serveur l'ecrit ("Signalé", "En cours",
  /// "Terminé"...).
  final String status;

  const TicketProgressStrip({super.key, required this.status});

  /// Nombre de jalons atteints, de 1 a 3.
  static int reached(String status) {
    final s = status.toUpperCase();
    if (s.startsWith('TERMIN') || s == 'RESOLU') return 3;
    if (s == 'EN COURS' || s == 'EN_COURS') return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    final t = AppL10n.of(context);
    final done = reached(status);
    final labels = [t.pipelineOpened, t.pipelineStarted, t.pipelineClosed];
    const amber = FigBrand.amber;
    final faint = c.textFaint.withValues(alpha: 0.35);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: c.card,
        border: Border.all(color: c.cardBorder),
        borderRadius: BorderRadius.circular(FigRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: i < done ? amber : faint,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                _dot(c, i < done, i == done - 1 && done < 3, amber, faint),
              ],
            ],
          ),
          const SizedBox(height: FigSpace.md),
          Row(
            children: [
              for (var i = 0; i < 3; i++)
                Expanded(
                  child: Text(
                    labels[i],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: switch (i) {
                      0 => TextAlign.start,
                      1 => TextAlign.center,
                      _ => TextAlign.end,
                    },
                    style: FigText.label.copyWith(
                      fontSize: 11,
                      fontWeight:
                          i == done - 1 ? FontWeight.w600 : FontWeight.w400,
                      color: i < done ? c.textBody : c.textFaint,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dot(GiColors c, bool on, bool current, Color amber, Color faint) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: on ? amber : Colors.transparent,
        border: Border.all(color: on ? amber : faint, width: 2),
        boxShadow: current
            ? [BoxShadow(color: amber.withValues(alpha: 0.25), spreadRadius: 4)]
            : null,
      ),
      child: on ? Icon(Icons.check_rounded, size: 13, color: c.ctaText) : null,
    );
  }
}
