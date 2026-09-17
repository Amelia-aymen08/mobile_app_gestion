// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../../data/api_service.dart';

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
                        Text('Avis', style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 20)),
                        Text('Communications officielles', style: TextStyle(color: muted, fontSize: 12)),
                      ],
                    ),
                  ),
                  if (unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: brandAmber, borderRadius: BorderRadius.circular(20)),
                      child: Text('$unreadCount nouveau${unreadCount > 1 ? 'x' : ''}',
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
                        child: Text(e.value,
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
                                              Text((n['body'] ?? '').toString(),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(color: muted, fontSize: 13, height: 1.4)),
                                              const SizedBox(height: 8),
                                              const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text('Lire la suite',
                                                      style: TextStyle(
                                                          color: brandAmber,
                                                          fontWeight: FontWeight.w700,
                                                          fontSize: 12)),
                                                  Icon(Icons.chevron_right_rounded, size: 16, color: brandAmber),
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
              Text('Aucun avis pour le moment',
                  style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 17)),
              const SizedBox(height: 8),
              Text(
                "Vous êtes à jour. Il n'y a aucun avis à afficher pour l'instant.",
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
