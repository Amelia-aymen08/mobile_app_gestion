// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../../data/api_service.dart';
import '../l10n/l10n.dart';

// ── Alert pipeline ─────────────────────────────────────────────────────────
// An announcement may carry a time window (startsAt -> endsAt), e.g. a water
// cut from 09:00 to 12:00. Residents see it move through
// "À venir" -> "En cours" -> "Terminée".
enum _AlertPhase { upcoming, ongoing, ended }

DateTime? _parseDt(dynamic v) => DateTime.tryParse((v ?? '').toString())?.toLocal();

_AlertPhase? _phaseOf(Map n) {
  final start = _parseDt(n['startsAt']);
  if (start == null) return null;
  final end = _parseDt(n['endsAt']);
  final now = DateTime.now();
  if (now.isBefore(start)) return _AlertPhase.upcoming;
  if (end != null && !now.isBefore(end)) return _AlertPhase.ended;
  return _AlertPhase.ongoing;
}

String _phaseLabel(_AlertPhase p) {
  switch (p) {
    case _AlertPhase.upcoming:
      return 'À venir'.tr;
    case _AlertPhase.ongoing:
      return 'En cours'.tr;
    case _AlertPhase.ended:
      return 'Terminée'.tr;
  }
}

Color _phaseColor(_AlertPhase p) {
  switch (p) {
    case _AlertPhase.upcoming:
      return const Color(0xFF3B82F6);
    case _AlertPhase.ongoing:
      return const Color(0xFFF59E0B);
    case _AlertPhase.ended:
      return const Color(0xFF16A34A);
  }
}

/// "20/09/2026 · 09:00 → 12:00" (or with both dates when it spans days).
String _alertRange(Map n) {
  final start = _parseDt(n['startsAt']);
  if (start == null) return '';
  final end = _parseDt(n['endsAt']);
  final day = DateFormat('dd/MM/yyyy');
  final hm = DateFormat('HH:mm');
  if (end == null) return '${day.format(start)} · ${hm.format(start)}';
  final sameDay = day.format(start) == day.format(end);
  return sameDay
      ? '${day.format(start)} · ${hm.format(start)} → ${hm.format(end)}'
      : '${day.format(start)} ${hm.format(start)} → ${day.format(end)} ${hm.format(end)}';
}

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
    'ALL': 'Tous',
    'URGENT': 'Urgent',
    'INFO': 'Info',
    'EVENT': 'Événement',
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
    if (that == today) return "Aujourd'hui, {time}".trp({'time': time});
    if (that == today.subtract(const Duration(days: 1))) {
      return 'Hier, {time}'.trp({'time': time});
    }
    return '${DateFormat('dd/MM/yyyy').format(d)}, $time';
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? Colors.white : brandNavy;
    final muted = dark ? darkMuted : const Color(0xFF6B7280);

    final filtered = _notices.whereType<Map>().where((n) {
      if (_filter == 'ALL') return true;
      return (n['category'] ?? '').toString().toUpperCase() == _filter;
    }).toList();
    final unreadCount = _notices.whereType<Map>().where((n) => n['isRead'] != true).length;

    return Scaffold(
      backgroundColor: dark ? darkSurface : brandCream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                        color: brandAmber.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
                    alignment: Alignment.center,
                    child: const Icon(Icons.campaign_rounded, color: brandAmber, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Avis'.tr, style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 20)),
                        Text('Communications officielles'.tr, style: TextStyle(color: muted, fontSize: 12)),
                      ],
                    ),
                  ),
                  if (unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: brandAmber, borderRadius: BorderRadius.circular(20)),
                      child: Text((unreadCount > 1 ? '{n} nouveaux' : '{n} nouveau').trp({'n': unreadCount}),
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: _categories.entries.map((e) {
                  final active = _filter == e.key;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _filter = e.key),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                        decoration: BoxDecoration(
                          color: active ? (dark ? brandAmber : brandNavy) : (dark ? darkCard : Colors.white),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        alignment: Alignment.center,
                        child: Text(e.value.tr,
                            style: TextStyle(
                                color: active ? (dark ? brandNavy : Colors.white) : fg,
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                      ? _emptyState(fg, muted)
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: filtered.length,
                            itemBuilder: (context, i) {
                              final n = Map<String, dynamic>.from(filtered[i]);
                              final category = (n['category'] ?? 'INFO').toString().toUpperCase();
                              final isRead = n['isRead'] == true;
                              final color = _categoryColor(category);

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: GestureDetector(
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
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: dark ? darkCard : Colors.white,
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Stack(
                                          children: [
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                  color: color.withValues(alpha: 0.14),
                                                  borderRadius: BorderRadius.circular(12)),
                                              alignment: Alignment.center,
                                              child: Icon(
                                                category == 'URGENT'
                                                    ? Icons.warning_amber_rounded
                                                    : category == 'EVENT'
                                                        ? Icons.event_rounded
                                                        : Icons.info_outline_rounded,
                                                color: color,
                                                size: 20,
                                              ),
                                            ),
                                            if (!isRead)
                                              Positioned(
                                                top: 0,
                                                right: 0,
                                                child: Container(
                                                  width: 9,
                                                  height: 9,
                                                  decoration: BoxDecoration(
                                                    color: brandAmber,
                                                    shape: BoxShape.circle,
                                                    border: Border.all(color: dark ? darkCard : Colors.white, width: 2),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(_dayTimeLabel((n['publishAt'] ?? n['createdAt'])?.toString()),
                                                  style: TextStyle(color: muted, fontSize: 11)),
                                              const SizedBox(height: 4),
                                              Text((n['title'] ?? '').toString(),
                                                  style: TextStyle(
                                                      color: fg, fontWeight: FontWeight.w800, fontSize: 15)),
                                              const SizedBox(height: 4),
                                              if (_phaseOf(n) != null) ...[
                                                Wrap(
                                                  spacing: 8,
                                                  runSpacing: 4,
                                                  crossAxisAlignment: WrapCrossAlignment.center,
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: _phaseColor(_phaseOf(n)!).withValues(alpha: 0.14),
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                      child: Text(_phaseLabel(_phaseOf(n)!),
                                                          style: TextStyle(
                                                              color: _phaseColor(_phaseOf(n)!),
                                                              fontSize: 11,
                                                              fontWeight: FontWeight.w800)),
                                                    ),
                                                    Text(_alertRange(n),
                                                        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
                                                  ],
                                                ),
                                                const SizedBox(height: 6),
                                              ],
                                              Text((n['body'] ?? '').toString(),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(color: muted, fontSize: 13, height: 1.4)),
                                              const SizedBox(height: 8),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text('Lire la suite'.tr,
                                                      style: const TextStyle(
                                                          color: brandAmber,
                                                          fontWeight: FontWeight.w700,
                                                          fontSize: 12)),
                                                  const Icon(Icons.chevron_right_rounded, size: 16, color: brandAmber),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(Color fg, Color muted) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(shape: BoxShape.circle, color: muted.withValues(alpha: 0.10)),
                alignment: Alignment.center,
                child: Icon(Icons.priority_high_rounded, size: 52, color: muted.withValues(alpha: 0.5)),
              ),
              const SizedBox(height: 20),
              Text('Aucun avis pour le moment'.tr,
                  style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 17)),
              const SizedBox(height: 8),
              Text(
                "Vous êtes à jour. Il n'y a aucun avis à afficher pour l'instant.".tr,
                textAlign: TextAlign.center,
                style: TextStyle(color: muted, fontSize: 13, height: 1.5),
              ),
            ],
          ),
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

    final categoryLabel = (category == 'URGENT' ? 'Avis urgent' : (category == 'EVENT' ? 'Événement' : 'Information')).tr;
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
                        Text('{date} à {time}'.trp({'date': DateFormat('dd/MM/yyyy').format(publishAt), 'time': DateFormat('HH:mm').format(publishAt)}),
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
            if (_phaseOf(notice) != null) ...[
              const SizedBox(height: 14),
              _AlertPipeline(notice: notice, dark: dark, fg: fg, muted: muted),
            ],
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
                      child: Text('Blocs concernés : {blocks}'.trp({'blocks': notice['blocks']}),
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

/// Three-step tracker "À venir -> En cours -> Terminée" with the start and end times.
class _AlertPipeline extends StatelessWidget {
  final Map notice;
  final bool dark;
  final Color fg;
  final Color muted;
  const _AlertPipeline(
      {required this.notice, required this.dark, required this.fg, required this.muted});

  @override
  Widget build(BuildContext context) {
    final phase = _phaseOf(notice)!;
    final start = _parseDt(notice['startsAt']);
    final end = _parseDt(notice['endsAt']);
    final fmt = DateFormat('dd/MM/yyyy · HH:mm');
    final current = _AlertPhase.values.indexOf(phase);

    Widget step(int index, String label, String? time) {
      final reached = index <= current;
      final color = reached ? _phaseColor(_AlertPhase.values[index]) : (dark ? darkBorder : const Color(0xFFD5D0C2));
      return SizedBox(
        width: 92,
        child: Column(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: reached ? color : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
              child: reached
                  ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(height: 6),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: index == current ? fg : muted,
                    fontWeight: index == current ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 12)),
            if (time != null)
              Text(time,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: muted, fontSize: 10.5)),
          ],
        ),
      );
    }

    Widget line(int afterIndex) => Expanded(
          child: Container(
            height: 2,
            margin: const EdgeInsets.only(bottom: 34),
            color: afterIndex < current
                ? _phaseColor(_AlertPhase.values[afterIndex + 1])
                : (dark ? darkBorder : const Color(0xFFD5D0C2)),
          ),
        );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: dark ? darkCard : Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Déroulement de l'alerte".tr,
              style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              step(0, 'À venir'.tr, null),
              line(0),
              step(1, 'En cours'.tr, start != null ? fmt.format(start) : null),
              line(1),
              step(2, 'Terminée'.tr, end != null ? fmt.format(end) : null),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.schedule_rounded, size: 16, color: muted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                    end != null
                        ? 'Début : {start} — Fin : {end}'.trp({'start': fmt.format(start!), 'end': fmt.format(end)})
                        : 'Début : {start} — Fin non précisée'.trp({'start': fmt.format(start!)}),
                    style: TextStyle(color: muted, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
