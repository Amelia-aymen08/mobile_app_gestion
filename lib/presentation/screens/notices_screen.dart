// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
// `intl` exporte aussi un type TextDirection, qui masque celui de Flutter et
// casse la lecture du sens d'ecriture.
import 'package:intl/intl.dart' hide TextDirection;
import 'package:flutter_svg/flutter_svg.dart';

import '../../data/api_service.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import '../theme/gi_colors.dart';
import '../widgets/gi_card.dart';
import '../widgets/gi_header.dart';

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

  Color _categoryColor(String cat) {
    switch (cat) {
      case 'URGENT':
        return const Color(0xFFDC2626);
      case 'EVENT':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF3B82F6);
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
    final category = (n['category'] ?? 'INFO').toString().toUpperCase();
    final isRead = n['isRead'] == true;
    final accent = _categoryColor(category);
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
                      width: 17,
                      height: 12,
                      colorFilter:
                          ColorFilter.mode(accent, BlendMode.srcIn),
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

  /// Etat vide — frame "Empty Notices" du Figma.
  Widget _emptyState(GiColors c, AppL10n t) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GiIconChip(
              accent: FigAccent.amber,
              size: 88,
              radius: 44,
              icon: SvgPicture.asset(
                'assets/figma/icons/notice_20.svg',
                width: 36,
                height: 36,
                colorFilter: ColorFilter.mode(
                    FigBrand.amber.withValues(alpha: 0.6), BlendMode.srcIn),
              ),
            ),
            const SizedBox(height: FigSpace.xxl),
            Text(t.emptyNoticesTitle,
                textAlign: TextAlign.center,
                style: FigText.titleMd
                    .copyWith(fontSize: 18, color: c.textBody)),
            const SizedBox(height: FigSpace.md),
            Text(
              t.emptyNoticesBody,
              textAlign: TextAlign.center,
              style: FigText.body.copyWith(height: 1.36, color: c.textMuted),
            ),
          ],
        ),
      );
}

class NoticeDetailScreen extends StatelessWidget {
  final Map<String, dynamic> notice;
  const NoticeDetailScreen({super.key, required this.notice});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? Colors.white : brandNavy;
    final muted = dark ? darkMuted : const Color(0xFF6B7280);

    final category = (notice['category'] ?? 'INFO').toString().toUpperCase();
    final title = (notice['title'] ?? '').toString();
    final body = (notice['body'] ?? '').toString();
    final publishAt = DateTime.tryParse((notice['publishAt'] ?? notice['createdAt'] ?? '').toString())?.toLocal();

    final categoryLabel = category == 'URGENT' ? 'Avis urgent' : (category == 'EVENT' ? 'Événement' : 'Information');
    final categoryColor = category == 'URGENT'
        ? const Color(0xFFDC2626)
        : (category == 'EVENT' ? const Color(0xFF8B5CF6) : const Color(0xFF3B82F6));

    return Scaffold(
      backgroundColor: dark ? darkSurface : brandCream,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                      color: dark ? darkCard : Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: IconButton(
                    icon: Icon(Icons.arrow_back_rounded, color: fg),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(categoryLabel, style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 18)),
                      if (publishAt != null)
                        Text(DateFormat("dd/MM/yyyy 'à' HH:mm").format(publishAt),
                            style: TextStyle(color: muted, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: dark ? darkCard : Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: categoryColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                    child: Text(categoryLabel,
                        style: TextStyle(color: categoryColor, fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 12),
                  Text(title, style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 19)),
                  const SizedBox(height: 12),
                  Text(body, style: TextStyle(color: muted, fontSize: 14, height: 1.6)),
                ],
              ),
            ),
            if ((notice['blocks'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: dark ? darkCard : Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    Icon(Icons.location_on_outlined, color: muted, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('Blocs concernés : ${notice['blocks']}',
                          style: TextStyle(color: fg, fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
