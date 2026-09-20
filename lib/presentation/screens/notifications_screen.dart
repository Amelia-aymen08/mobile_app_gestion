import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/api_service.dart';
import '../theme/app_theme.dart';
import '../l10n/l10n.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ApiService _api = ApiService();

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = const [];
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _api.getNotifications();
      final items = data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '').tr;
        _loading = false;
      });
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) return '';
    try {
      final dt = DateTime.parse(value.toString()).toLocal();
      return DateFormat('dd/MM/yyyy HH:mm').format(dt);
    } catch (_) {
      return value.toString();
    }
  }

  Future<void> _markRead(Map<String, dynamic> n) async {
    final id = n['id']?.toString();
    if (id == null || id.isEmpty) return;
    if ((n['isRead'] == true)) return;
    try {
      await _api.markNotificationRead(id);
      if (!mounted) return;
      setState(() {
        _items = _items
            .map((x) => x['id']?.toString() == id ? { ...x, 'isRead': true } : x)
            .toList();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', '').tr)),
      );
    }
  }

  Future<void> _markAllRead() async {
    try {
      await _api.markAllNotificationsRead();
      if (!mounted) return;
      setState(() {
        _items = _items.map((x) => { ...x, 'isRead': true }).toList();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', '').tr)),
      );
    }
  }

  bool _isUrgent(Map n) => ['WARNING', 'ERROR'].contains((n['type'] ?? '').toString());

  List<Map<String, dynamic>> get _filtered {
    if (_filter == 'urgent') return _items.where(_isUrgent).toList();
    if (_filter == 'info') return _items.where((n) => !_isUrgent(n)).toList();
    return _items;
  }

  ({IconData icon, Color color}) _typeStyle(String type) {
    switch (type) {
      case 'WARNING':
        return (icon: Icons.report_problem_outlined, color: const Color(0xFFF59E0B));
      case 'ERROR':
        return (icon: Icons.error_outline_rounded, color: const Color(0xFFE0362B));
      case 'SUCCESS':
        return (icon: Icons.check_circle_outline_rounded, color: const Color(0xFF16A34A));
      default:
        return (icon: Icons.info_outline_rounded, color: const Color(0xFF3B82F6));
    }
  }

  void _openDetail(Map<String, dynamic> n) {
    _markRead(n);
    Navigator.push(context, MaterialPageRoute(builder: (_) => _NoticeDetailScreen(notice: n)));
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? Colors.white : brandNavy;
    final muted = dark ? darkMuted : const Color(0xFF6B7280);
    final unreadCount = _items.where((e) => e['isRead'] != true).length;
    final list = _filtered;

    return Scaffold(
      backgroundColor: dark ? darkSurface : brandCream,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: brandAmber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.campaign_outlined, color: brandAmber, size: 22),
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
                    GestureDetector(
                      onTap: _markAllRead,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: brandAmber, borderRadius: BorderRadius.circular(20)),
                        child: Text((unreadCount > 1 ? '{n} nouveaux' : '{n} nouveau').trp({'n': unreadCount}),
                            style: const TextStyle(
                                color: brandNavy, fontWeight: FontWeight.w700, fontSize: 12)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),

              // ── Filter chips ─────────────────────────────
              Row(
                children: [
                  _chip('Tout'.tr, 'all', dark, fg),
                  const SizedBox(width: 8),
                  _chip('Urgent'.tr, 'urgent', dark, fg),
                  const SizedBox(width: 8),
                  _chip('Info'.tr, 'info', dark, fg),
                ],
              ),
              const SizedBox(height: 18),

              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  child: Center(
                    child: Text(_error!,
                        style: const TextStyle(color: Color(0xFFE0362B), fontWeight: FontWeight.w600)),
                  ),
                )
              else if (list.isEmpty)
                _emptyState(dark, fg, muted)
              else
                ...list.map((n) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _noticeCard(n, dark, fg, muted),
                    )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, String value, bool dark, Color fg) {
    final active = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: active ? (dark ? brandAmber : brandNavy) : (dark ? darkCard : Colors.white),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                color: active ? (dark ? brandNavy : Colors.white) : fg,
                fontWeight: FontWeight.w600,
                fontSize: 13)),
      ),
    );
  }

  Widget _noticeCard(Map<String, dynamic> n, bool dark, Color fg, Color muted) {
    final title = (n['title'] ?? '').toString();
    final message = (n['message'] ?? '').toString();
    final isRead = n['isRead'] == true;
    final type = (n['type'] ?? 'INFO').toString();
    final style = _typeStyle(type);
    final createdAt = _formatDate(n['createdAt']);

    return GestureDetector(
      onTap: () => _openDetail(n),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: dark ? darkCard : Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (createdAt.isNotEmpty)
              Text(createdAt, style: TextStyle(color: muted, fontSize: 11)),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: style.color.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Icon(style.icon, color: style.color, size: 20),
                    ),
                    if (!isRead)
                      Positioned(
                        top: -3,
                        right: -3,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(color: brandAmber, shape: BoxShape.circle),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text((title.isEmpty ? 'Avis' : title).tr,
                          style: TextStyle(
                              color: fg,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              height: 1.25)),
                      if (message.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(message,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: muted, fontSize: 13, height: 1.4)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Lire la suite'.tr,
                      style: const TextStyle(color: brandAmber, fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded, size: 16, color: brandAmber),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(bool dark, Color fg, Color muted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: dark ? darkBorder : const Color(0xFFE2DDCF), width: 3),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.priority_high_rounded,
                size: 56, color: dark ? darkBorder : const Color(0xFFE2DDCF)),
          ),
          const SizedBox(height: 22),
          Text('Aucun avis'.tr, style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 8),
          Text('Vous êtes à jour. Aucun avis à afficher pour le moment.'.tr,
              textAlign: TextAlign.center, style: TextStyle(color: muted, fontSize: 13)),
        ],
      ),
    );
  }
}

// ─── Notice detail ──────────────────────────────────────────────────────────
class _NoticeDetailScreen extends StatelessWidget {
  final Map<String, dynamic> notice;
  const _NoticeDetailScreen({required this.notice});

  String _formatDate(dynamic value) {
    if (value == null) return '';
    try {
      final dt = DateTime.parse(value.toString()).toLocal();
      return DateFormat('dd/MM/yyyy · HH:mm').format(dt);
    } catch (_) {
      return value.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? Colors.white : brandNavy;
    final muted = dark ? darkMuted : const Color(0xFF6B7280);
    final title = (notice['title'] ?? '').toString();
    final message = (notice['message'] ?? '').toString();
    final createdAt = _formatDate(notice['createdAt']);

    return Scaffold(
      backgroundColor: dark ? darkSurface : brandCream,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Row(
              children: [
                _backButton(context, dark, fg),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Avis'.tr, style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 20)),
                      if (createdAt.isNotEmpty)
                        Text(createdAt, style: TextStyle(color: muted, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: dark ? darkCard : Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text((title.isEmpty ? 'Avis' : title).tr,
                      style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 19)),
                  if (message.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(message, style: TextStyle(color: muted, fontSize: 14, height: 1.6)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _backButton(BuildContext context, bool dark, Color fg) => Container(
        decoration: BoxDecoration(
          color: dark ? darkCard : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: fg),
          onPressed: () => Navigator.pop(context),
        ),
      );
}
