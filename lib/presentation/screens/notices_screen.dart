// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
// `intl` exporte aussi un type TextDirection, qui masque celui de Flutter et
// casse la lecture du sens d'ecriture.
import 'package:intl/intl.dart' hide TextDirection;
import 'package:flutter_svg/flutter_svg.dart';

import '../../data/api_service.dart';
import '../../l10n/app_localizations.dart';
import '../theme/design_tokens.dart';
import '../theme/gi_colors.dart';
import '../widgets/gi_card.dart';
import '../widgets/gi_header.dart';
import '../widgets/gi_empty_state.dart';
import '../widgets/gi_pressable.dart';

class NoticesScreen extends StatefulWidget {
  const NoticesScreen({super.key});

  @override
  State<NoticesScreen> createState() => _NoticesScreenState();
}

class _NoticesScreenState extends State<NoticesScreen> {
  final ApiService _api = ApiService();
  bool _loading = true;
  List<dynamic> _notices = [];
  String _filter = 'ALL';

  static const _categories = {
    'ALL': 'All',
    'URGENT': 'Urgent',
    'INFO': 'Info',
    'EVENT': 'Event',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _api.getAnnouncements();
      if (mounted) setState(() => _notices = list);
    } catch (_) {
      // Silently fall back to empty state — this feed shouldn't block the tab.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }


  String _dayTimeLabel(String? iso) {
    if (iso == null) return '';
    final d = DateTime.tryParse(iso)?.toLocal();
    if (d == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(d.year, d.month, d.day);
    final time = DateFormat('HH:mm').format(d);
    if (that == today) return "Aujourd'hui, $time";
    if (that == today.subtract(const Duration(days: 1))) return 'Hier, $time';
    return '${DateFormat('dd/MM/yyyy').format(d)}, $time';
  }

  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    final t = AppL10n.of(context);

    final labels = {
      'ALL': t.filterAll,
      'URGENT': t.filterUrgent,
      'INFO': t.filterInfo,
      'EVENT': t.filterEvent,
    };

    final filtered = _notices.whereType<Map>().where((n) {
      if (_filter == 'ALL') return true;
      return (n['category'] ?? '').toString().toUpperCase() == _filter;
    }).toList();
    final unreadCount =
        _notices.whereType<Map>().where((n) => n['isRead'] != true).length;

    return Scaffold(
      backgroundColor: c.scaffold,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Figma : en-tete a 66, filtres a 126, liste a 174.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  FigSpace.pagePadding, 22, FigSpace.pagePadding, 0),
              child: GiScreenHeader(
                iconAsset: 'assets/figma/icons/notice_20.svg',
                accent: FigAccent.amber,
                title: t.notices,
                subtitle: t.noticesSubtitle,
                badge: unreadCount > 0 ? t.newCount(unreadCount) : null,
              ),
            ),
            const SizedBox(height: 25),
            SizedBox(
              height: 28,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: FigSpace.pagePadding),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: FigSpace.xs),
                itemBuilder: (_, i) {
                  final key = _categories.keys.elementAt(i);
                  return GiFilterChip(
                    label: labels[key] ?? key,
                    selected: _filter == key,
                    onTap: () => setState(() => _filter = key),
                  );
                },
              ),
            ),
            const SizedBox(height: FigSpace.xl),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: FigBrand.amber))
                  : RefreshIndicator(
                      color: FigBrand.amber,
                      backgroundColor: c.card,
                      onRefresh: _load,
                      child: filtered.isEmpty
                          ? ListView(
                              physics:
                                  const AlwaysScrollableScrollPhysics(),
                              children: [
                                SizedBox(
                                    height: MediaQuery.sizeOf(context).height *
                                        0.12),
                                _emptyState(c, t),
                              ],
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                  FigSpace.pagePadding, 0,
                                  FigSpace.pagePadding, 150),
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: FigSpace.lg),
                              itemBuilder: (context, i) => _noticeCard(
                                  c, t, Map<String, dynamic>.from(filtered[i])),
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Carte d'avis — composant "Notice Card" du Figma (837:1940).
  /// Padding 16, ecart 16 entre les trois blocs, ecart 6 dans le texte.
  /// Une fois lu, titre et corps passent au gris et la pastille disparait.
  Widget _noticeCard(GiColors c, AppL10n t, Map<String, dynamic> n) {
    final isRead = n['isRead'] == true;
    // Le Figma emploie la meme teinte ambree sur toutes les cartes : la
    // categorie pilote le filtre, pas la couleur de la pastille.
    const accent = FigBrand.amber;
    final titleColor = isRead ? c.textFaint : c.textBody;
    final bodyColor = isRead ? c.textFaint : c.textBody;

    return GiCard(
      onTap: () async {
        if (!isRead) {
          _api.markAnnouncementRead(n['id'].toString()).catchError((_) {});
        }
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => NoticeDetailScreen(notice: n)),
        );
        _load();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _dayTimeLabel((n['publishAt'] ?? n['createdAt'])?.toString()),
            style: FigText.caption.copyWith(color: c.textMuted),
          ),
          const SizedBox(height: FigSpace.xl),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  GiIconChip(
                    accent: accent,
                    size: FigSize.chipSm,
                    radius: FigRadius.pill,
                    icon: SvgPicture.asset(
                      'assets/figma/icons/notice_card_20.svg',
                      colorFilter:
                          const ColorFilter.mode(accent, BlendMode.srcIn),
                    ),
                  ),
                  if (!isRead)
                    PositionedDirectional(
                      top: -3,
                      start: 21,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                            color: FigBrand.amber, shape: BoxShape.circle),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: FigSpace.xl),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (n['title'] ?? '').toString(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: FigText.statValue
                          .copyWith(height: 1.2, color: titleColor),
                    ),
                    const SizedBox(height: FigSpace.sm),
                    Text(
                      (n['body'] ?? '').toString(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: FigText.body.copyWith(color: bodyColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: FigSpace.xl),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(t.readMore,
                    style: FigText.caption.copyWith(color: c.textBody)),
                const SizedBox(width: FigSpace.xs),
                Transform.flip(
                  flipX: Directionality.of(context) == TextDirection.rtl,
                  child: SvgPicture.asset(
                    'assets/figma/icons/arrow_readmore.svg',
                    width: 9,
                    height: 8,
                    colorFilter:
                        ColorFilter.mode(c.textBody, BlendMode.srcIn),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Etat vide — frame "Empty Notices" du Figma (837:1963).
  Widget _emptyState(GiColors c, AppL10n t) => Padding(
        padding: const EdgeInsets.only(top: 24),
        child: GiEmptyState(
          title: t.emptyNoticesTitle,
          message: t.emptyNoticesBody,
        ),
      );
}

/// Detail d'un avis — frame Figma "Notice Detail LT" (837:1712).
///
/// La maquette prevoit quatre blocs : le contenu avec sa fenetre
/// d'intervention, la chronologie, les blocs concernes et les consignes.
/// L'API ne sert pour l'instant que titre, corps, categorie, date et blocs ;
/// les autres champs suivent le contrat propose a l'equipe back-end
/// (`scheduledDate`, `scheduledFrom`, `scheduledTo`, `timeline[]`,
/// `instructions[]`) et chaque bloc n'apparait que si sa donnee est presente.
class NoticeDetailScreen extends StatelessWidget {
  final Map<String, dynamic> notice;
  const NoticeDetailScreen({super.key, required this.notice});

  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    final t = AppL10n.of(context);

    final category = (notice['category'] ?? 'INFO').toString().toUpperCase();
    final title = (notice['title'] ?? '').toString();
    final body = (notice['body'] ?? '').toString();
    final publishAt = DateTime.tryParse(
            (notice['publishAt'] ?? notice['createdAt'] ?? '').toString())
        ?.toLocal();

    final label = switch (category) {
      'URGENT' => t.filterUrgent,
      'EVENT' => t.filterEvent,
      _ => t.filterInfo,
    };

    final blocks = notice['blocks'];
    final blockList = blocks is List
        ? blocks.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
        : const <String>[];

    final steps = notice['timeline'] is List
        ? (notice['timeline'] as List).whereType<Map>().toList()
        : const <Map>[];
    final instructions = notice['instructions'] is List
        ? (notice['instructions'] as List)
            .map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList()
        : const <String>[];

    final scheduledDate = (notice['scheduledDate'] ?? '').toString();
    final from = (notice['scheduledFrom'] ?? '').toString();
    final to = (notice['scheduledTo'] ?? '').toString();

    return Scaffold(
      backgroundColor: c.scaffold,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
              FigSpace.pagePadding,
              MediaQuery.paddingOf(context).top > 0 ? 22 : 32,
              FigSpace.pagePadding,
              40),
          children: [
            _header(context, c, t, label, publishAt),
            const SizedBox(height: FigSpace.xl),
            _contentCard(c, t, title, body, scheduledDate, from, to),
            if (steps.isNotEmpty) ...[
              const SizedBox(height: FigSpace.lg),
              _timelineCard(c, t, steps),
            ],
            if (blockList.isNotEmpty) ...[
              const SizedBox(height: FigSpace.lg),
              _blocksCard(c, t, blockList),
            ],
            if (instructions.isNotEmpty) ...[
              const SizedBox(height: FigSpace.lg),
              _instructionsCard(c, t, instructions),
            ],
            const SizedBox(height: FigSpace.xxl),
            _actions(context, t),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, GiColors c, AppL10n t, String label,
      DateTime? publishAt) {
    return Row(
      children: [
        GiPressable(
          onTap: () => Navigator.pop(context),
          pressedScale: 0.88,
          child: Container(
            width: FigSize.chipMd,
            height: FigSize.chipMd,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.headerChipBg,
              border: Border.all(color: c.headerChipBorder),
              borderRadius: BorderRadius.circular(FigRadius.chip),
            ),
            child: Transform.flip(
              flipX: Directionality.of(context) == TextDirection.rtl,
              child: SvgPicture.asset(
                'assets/figma/icons/back_14.svg',
                colorFilter: ColorFilter.mode(c.textBody, BlendMode.srcIn),
              ),
            ),
          ),
        ),
        const SizedBox(width: FigSpace.xl),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style: FigText.titleMd
                      .copyWith(fontSize: 18, color: c.textBody)),
              if (publishAt != null) ...[
                const SizedBox(height: 2),
                Text(
                  DateFormat("dd/MM/yyyy 'à' HH:mm").format(publishAt),
                  style: FigText.body.copyWith(color: c.textMuted),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Carte de contenu, avec le bandeau Date / Horaire du Figma quand la
  /// fenetre d'intervention est renseignee.
  Widget _contentCard(GiColors c, AppL10n t, String title, String body,
      String date, String from, String to) {
    return GiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: FigText.statValue.copyWith(height: 1.2, color: c.textBody)),
          const SizedBox(height: FigSpace.lg),
          Text(body,
              style: FigText.body.copyWith(height: 1.5, color: c.textMuted)),
          if (date.isNotEmpty || from.isNotEmpty) ...[
            const SizedBox(height: FigSpace.xl),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: FigSpace.lg),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(FigRadius.card),
                border: Border.all(color: c.innerBorder),
              ),
              child: Row(
                children: [
                  Expanded(child: _pair(c, t.dateLabel, _prettyDate(date))),
                  Expanded(
                    child: _pair(
                      c,
                      t.timeLabel,
                      from.isEmpty ? '' : (to.isEmpty ? from : '$from - $to'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _pair(GiColors c, String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: FigText.label.copyWith(color: c.textMuted)),
          const SizedBox(height: FigSpace.sm),
          Text(value.isEmpty ? '—' : value,
              style: FigText.statValue.copyWith(color: c.textBody)),
        ],
      );

  static String _prettyDate(String iso) {
    final d = DateTime.tryParse(iso);
    return d == null ? iso : DateFormat('dd/MM/yyyy').format(d);
  }

  /// Chronologie : une pastille par etape, reliees par un trait pointille.
  /// La derniere etape passe au vert, c'est le retablissement ; celles
  /// marquees « estime » le signalent a cote de l'heure.
  Widget _timelineCard(GiColors c, AppL10n t, List<Map> steps) {
    return GiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.timelineTitle,
              style: FigText.statValue.copyWith(color: c.textBody)),
          const SizedBox(height: FigSpace.xl),
          for (var i = 0; i < steps.length; i++)
            _step(c, t, steps[i], i, i == steps.length - 1),
        ],
      ),
    );
  }

  Widget _step(GiColors c, AppL10n t, Map step, int index, bool last) {
    final color = last
        ? FigAlert.success
        : index == 0
            ? FigAlert.error
            : FigBrand.amber;
    final estimated = step['estimated'] == true;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Icon(Icons.place, size: 16, color: color),
              if (!last)
                Expanded(
                  child: _DashedLine(color: c.innerBorder),
                ),
            ],
          ),
          const SizedBox(width: FigSpace.lg),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : FigSpace.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text((step['label'] ?? '').toString(),
                      style: FigText.body.copyWith(color: c.textMuted)),
                  const SizedBox(height: FigSpace.xs),
                  Row(
                    children: [
                      Text((step['time'] ?? '').toString(),
                          style: FigText.statValue
                              .copyWith(color: c.textBody)),
                      if (estimated) ...[
                        const SizedBox(width: FigSpace.md),
                        Text('(${t.estimated})',
                            style:
                                FigText.caption.copyWith(color: c.textFaint)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _blocksCard(GiColors c, AppL10n t, List<String> blocks) {
    return GiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GiIconChip(
                accent: FigBrand.amber,
                size: FigSize.chipSm,
                radius: FigRadius.pill,
                icon: SvgPicture.asset('assets/figma/icons/pin_location.svg',
                    colorFilter: const ColorFilter.mode(
                        FigBrand.amber, BlendMode.srcIn)),
              ),
              const SizedBox(width: FigSpace.lg),
              Text(t.affectedAreas,
                  style: FigText.statValue.copyWith(color: c.textBody)),
            ],
          ),
          const SizedBox(height: FigSpace.lg),
          Wrap(
            spacing: FigSpace.md,
            runSpacing: FigSpace.md,
            children: [
              for (final b in blocks)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: FigAccent.chipFill(FigBrand.amber),
                    border:
                        Border.all(color: FigAccent.chipBorder(FigBrand.amber)),
                    borderRadius: BorderRadius.circular(FigRadius.pill),
                  ),
                  child: Text(t.blockNamed(b),
                      style: FigText.body.copyWith(color: FigBrand.amber)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _instructionsCard(GiColors c, AppL10n t, List<String> lines) {
    return GiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GiIconChip(
                accent: FigAccent.blue,
                size: FigSize.chipSm,
                radius: FigRadius.pill,
                icon: SvgPicture.asset(
                    'assets/figma/icons/documents_20.svg',
                    colorFilter: const ColorFilter.mode(
                        FigAccent.blue, BlendMode.srcIn)),
              ),
              const SizedBox(width: FigSpace.lg),
              Expanded(
                child: Text(t.whatToDo,
                    style: FigText.statValue.copyWith(color: c.textBody)),
              ),
            ],
          ),
          const SizedBox(height: FigSpace.lg),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: FigSpace.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.only(top: 7, end: 10),
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                          color: c.textFaint, shape: BoxShape.circle),
                    ),
                  ),
                  Expanded(
                    child: Text(line,
                        style: FigText.body
                            .copyWith(height: 1.45, color: c.textMuted)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Deux actions cote a cote, comme la maquette : partage en trait ambre,
  /// « marquer comme lu » en plein.
  Widget _actions(BuildContext context, AppL10n t) {
    return Row(
      children: [
        Expanded(
          child: GiPressable(
            pressedScale: 0.96,
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: FigBrand.amber, width: 1.5),
                borderRadius: BorderRadius.circular(FigRadius.cta),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(t.shareNotice,
                    style: FigText.button
                        .copyWith(fontSize: 14, color: FigBrand.amber)),
              ),
            ),
          ),
        ),
        const SizedBox(width: FigSpace.md),
        Expanded(
          child: GiPressable(
            pressedScale: 0.96,
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: FigBrand.amber,
                borderRadius: BorderRadius.circular(FigRadius.cta),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(t.markAsRead,
                    style: FigText.button
                        .copyWith(fontSize: 14, color: Colors.black)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Trait pointille vertical reliant les etapes de la chronologie.
class _DashedLine extends StatelessWidget {
  final Color color;
  const _DashedLine({required this.color});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dash = 3.0, gap = 3.0;
        final count = (constraints.maxHeight / (dash + gap)).floor();
        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: List.generate(
            count < 0 ? 0 : count,
            (_) => Container(
              width: 1.5,
              height: dash,
              margin: const EdgeInsets.only(bottom: gap),
              color: color,
            ),
          ),
        );
      },
    );
  }
}
