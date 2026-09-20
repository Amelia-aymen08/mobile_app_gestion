// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/api_service.dart';
import '../l10n/l10n.dart';
import '../services/file_opener.dart';
import '../theme/app_theme.dart';
import '../theme/ticket_style.dart';
import 'chat_screen.dart';

/// Detail of one of the resident's tickets: description, attachments (up to
/// 4), information posted by the administration and the dated history of the
/// processing (creation, status changes...).
class ResidentTicketDetailScreen extends StatefulWidget {
  /// The ticket as listed; refreshed from the API on open.
  final Map<String, dynamic> ticket;

  const ResidentTicketDetailScreen({super.key, required this.ticket});

  @override
  State<ResidentTicketDetailScreen> createState() =>
      _ResidentTicketDetailScreenState();
}

class _ResidentTicketDetailScreenState
    extends State<ResidentTicketDetailScreen> {
  final ApiService _api = ApiService();
  late Map<String, dynamic> _ticket;
  Map<String, dynamic>? _historyPayload;
  List<Map<String, dynamic>> _infos = [];
  bool _loadingExtras = true;
  String? _openingAttachmentId;

  String get _ticketId => (_ticket['id'] ?? '').toString();

  @override
  void initState() {
    super.initState();
    _ticket = Map<String, dynamic>.from(widget.ticket);
    _load();
  }

  Future<void> _load() async {
    // Each part is optional: a failure must not hide the others.
    final results = await Future.wait<Object?>([
      _api.getTicket(_ticketId).then<Object?>((v) => v).catchError((_) => null),
      _api
          .getTicketHistory(_ticketId)
          .then<Object?>((v) => v)
          .catchError((_) => null),
      _api
          .getTicketMessages(_ticketId)
          .then<Object?>((v) => v)
          .catchError((_) => null),
    ]);
    if (!mounted) return;
    setState(() {
      final fresh = results[0];
      if (fresh is Map<String, dynamic>) _ticket = {..._ticket, ...fresh};
      final history = results[1];
      if (history is Map<String, dynamic>) _historyPayload = history;
      final messages = results[2];
      if (messages is List) {
        _infos = messages
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .where((m) => (m['kind'] ?? 'CHAT') == 'INFO')
            .toList();
      }
      _loadingExtras = false;
    });
  }

  // ── helpers ──────────────────────────────────────────────
  DateTime? _dt(dynamic raw) =>
      DateTime.tryParse((raw ?? '').toString())?.toLocal();

  String _fmtDate(dynamic raw) {
    final d = _dt(raw);
    return d == null ? '' : DateFormat('dd/MM/yyyy').format(d);
  }

  String _fmtDateTime(dynamic raw) {
    final d = _dt(raw);
    return d == null ? '' : DateFormat('dd/MM/yyyy · HH:mm').format(d);
  }

  String _ref() {
    final id = _ticketId;
    if (id.isEmpty) return '';
    final tail = id.length > 6 ? id.substring(id.length - 6) : id;
    return '#${tail.toUpperCase()}';
  }

  String _formatBytes(num bytes) {
    if (bytes < 1024) return '${bytes.toInt()} o';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).round()} Ko';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} Mo';
  }

  bool _isImage(Map a) {
    final type = (a['type'] ?? '').toString().toLowerCase();
    if (type.startsWith('image/')) return true;
    final name = ((a['name'] ?? a['url']) ?? '').toString().toLowerCase();
    return name.endsWith('.jpg') ||
        name.endsWith('.jpeg') ||
        name.endsWith('.png') ||
        name.endsWith('.webp');
  }

  List<Map<String, dynamic>> get _attachments {
    final raw = _ticket['attachments'];
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
  }

  Future<void> _openAttachment(Map<String, dynamic> a) async {
    final url = (a['url'] ?? '').toString();
    final key = (a['id'] ?? url).toString();
    if (_openingAttachmentId != null || url.isEmpty) return;

    if (_isImage(a)) {
      _showImage(ApiService().mediaUrl(url)!, (a['name'] ?? '').toString());
      return;
    }
    setState(() => _openingAttachmentId = key);
    try {
      final bytes = await _api.downloadPublicFile(url);
      final name = (a['name'] ?? url.split('/').last).toString();
      await FileOpener.openBytes(bytes, name);
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg.tr)));
      }
    } finally {
      if (mounted) setState(() => _openingAttachmentId = null);
    }
  }

  void _showImage(String url, String title) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(children: [
          Positioned.fill(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 5,
              child: Center(
                child: Image.network(url,
                    fit: BoxFit.contain,
                    loadingBuilder: (_, child, progress) => progress == null
                        ? child
                        : const Center(child: CircularProgressIndicator()),
                    errorBuilder: (_, __, ___) => const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white54,
                        size: 48)),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: AlignmentDirectional.topEnd,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  String _actorLabel(Map item) {
    final role = (item['actorRole'] ?? '').toString();
    switch (role) {
      case 'RESIDENT':
        final name = (item['actorName'] ?? '').toString();
        return name.isNotEmpty ? name : 'Vous'.tr;
      case 'INTERVENANT':
        return 'Intervenant'.tr;
      case '':
        return '';
      default:
        return 'Administration'.tr;
    }
  }

  String _historyLabel(Map item) {
    switch ((item['action'] ?? '').toString()) {
      case 'CREATED':
        return 'Signalement créé'.tr;
      case 'STATUS_CHANGED':
        final from = (item['fromStatus'] ?? '').toString();
        final to = (item['toStatus'] ?? '').toString();
        if (from.isEmpty) {
          return 'Statut : {status}'.trp({'status': to.tr});
        }
        return 'Statut : {from} → {to}'.trp({'from': from.tr, 'to': to.tr});
      case 'ASSIGNED':
        return 'Pris en charge par l\'équipe'.tr;
      case 'INFO_MESSAGE':
        return 'Information de l\'administration'.tr;
      case 'ATTACHMENT_ADDED':
        return 'Pièces jointes ajoutées'.tr;
      default:
        return (item['action'] ?? '').toString();
    }
  }

  // ── build ────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? Colors.white : brandNavy;
    final muted = dark ? darkMuted : const Color(0xFF6B7280);

    final status = (_ticket['status'] ?? '').toString();
    final statusColor = ticketStatusColor(status);
    final title = normalizeTicketTitle((_ticket['title'] ?? '').toString());
    final desc = (_ticket['description'] ?? '').toString();
    final category = (_ticket['category'] ?? '').toString();
    final priority = (_ticket['priority'] ?? '').toString();
    final location = (_ticket['location'] ?? '').toString();
    final rejection = (_ticket['rejectionReason'] ?? '').toString();
    final createdAt = _fmtDateTime(_ticket['createdAt']);
    final startedAt = _fmtDateTime(_historyPayload?['startedAt']);
    final closedAt = _fmtDateTime(_historyPayload?['closedAt']);
    final attachments = _attachments;
    final history = ((_historyPayload?['history'] as List?) ?? [])
        .whereType<Map>()
        .toList();

    return Scaffold(
      backgroundColor: dark ? darkSurface : brandCream,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Row(
                children: [
                  _iconBtn(Icons.arrow_back_rounded, dark, fg,
                      () => Navigator.pop(context)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Détail du signalement'.tr,
                            style: TextStyle(
                                color: fg,
                                fontWeight: FontWeight.w800,
                                fontSize: 18)),
                        if (_fmtDate(_ticket['createdAt']).isNotEmpty)
                          Text(_fmtDate(_ticket['createdAt']),
                              style: TextStyle(color: muted, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Title / status ─────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: dark ? darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20)),
                          child: Text(status.tr,
                              style: TextStyle(
                                  color: statusColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700)),
                        ),
                        const Spacer(),
                        if (_ref().isNotEmpty)
                          Text(_ref(),
                              style: TextStyle(color: muted, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(title.tr,
                        style: TextStyle(
                            color: fg,
                            fontWeight: FontWeight.w800,
                            fontSize: 18)),
                    if (desc.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(desc,
                          style: TextStyle(
                              color: muted, fontSize: 14, height: 1.5)),
                    ],
                  ],
                ),
              ),

              // ── Information from the administration ────────
              if (_infos.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: brandAmber.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: brandAmber.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.info_outline_rounded,
                            color: brandAmber, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text("Informations de l'administration".tr,
                              style: TextStyle(
                                  color: fg,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14)),
                        ),
                      ]),
                      for (final info in _infos) ...[
                        const SizedBox(height: 10),
                        Text((info['body'] ?? '').toString(),
                            style: TextStyle(color: fg, fontSize: 14, height: 1.45)),
                        const SizedBox(height: 2),
                        Text(_fmtDateTime(info['createdAt']),
                            style: TextStyle(color: muted, fontSize: 11)),
                      ],
                    ],
                  ),
                ),
              ],

              // ── Facts ──────────────────────────────────────
              const SizedBox(height: 14),
              Container(
                decoration: BoxDecoration(
                    color: dark ? darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(20)),
                child: Column(
                  children: [
                    if (createdAt.isNotEmpty)
                      _row('Signalé le'.tr, createdAt, fg, muted, dark),
                    if (startedAt.isNotEmpty)
                      _row('Début du traitement'.tr, startedAt, fg, muted, dark),
                    if (closedAt.isNotEmpty)
                      _row('Fin du traitement'.tr, closedAt, fg, muted, dark),
                    if (category.isNotEmpty)
                      _row('Catégorie'.tr, category.tr, fg, muted, dark),
                    if (priority.isNotEmpty)
                      _row('Priorité'.tr, priority.tr, fg, muted, dark),
                    if (location.isNotEmpty)
                      _row('Lieu'.tr, location, fg, muted, dark, last: true),
                  ],
                ),
              ),

              // ── Attachments ────────────────────────────────
              if (attachments.isNotEmpty) ...[
                const SizedBox(height: 22),
                _sectionTitle(
                    'Pièces jointes ({count})'
                        .trp({'count': attachments.length}),
                    fg),
                const SizedBox(height: 10),
                LayoutBuilder(builder: (context, c) {
                  const gap = 10.0;
                  final w = (c.maxWidth - gap) / 2;
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      for (final a in attachments)
                        SizedBox(
                            width: w,
                            child: _attachmentTile(a, dark, fg, muted)),
                    ],
                  );
                }),
              ],

              // ── Rejection ──────────────────────────────────
              if (rejection.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626).withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: const Color(0xFFDC2626).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.block_rounded,
                          color: Color(0xFFDC2626), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                            'Motif de rejet : {reason}'
                                .trp({'reason': rejection}),
                            style: const TextStyle(
                                color: Color(0xFFDC2626),
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              ],

              // ── History ────────────────────────────────────
              const SizedBox(height: 22),
              _sectionTitle('Historique du traitement'.tr, fg),
              const SizedBox(height: 10),
              _historyCard(history, dark, fg, muted),

              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                  label: Text('Report Chat'.tr),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        ticketId: _ticketId,
                        title: 'Report Chat'.tr,
                        subtitle: title.tr,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _historyCard(List<Map> history, bool dark, Color fg, Color muted) {
    if (_loadingExtras && history.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (history.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: dark ? darkCard : Colors.white,
            borderRadius: BorderRadius.circular(18)),
        child: Text("L'historique n'est pas disponible pour le moment.".tr,
            style: TextStyle(color: muted, fontSize: 13)),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 6),
      decoration: BoxDecoration(
          color: dark ? darkCard : Colors.white,
          borderRadius: BorderRadius.circular(18)),
      child: Column(
        children: [
          for (var i = 0; i < history.length; i++)
            _historyRow(history[i], isLast: i == history.length - 1,
                dark: dark, fg: fg, muted: muted),
        ],
      ),
    );
  }

  Widget _historyRow(Map item,
      {required bool isLast,
      required bool dark,
      required Color fg,
      required Color muted}) {
    final toStatus = (item['toStatus'] ?? '').toString();
    final dotColor = toStatus.isNotEmpty ? ticketStatusColor(toStatus) : brandAmber;
    final actor = _actorLabel(item);
    final note = (item['note'] ?? '').toString();
    final showNote = note.isNotEmpty &&
        (item['action'] == 'INFO_MESSAGE' || item['action'] == 'STATUS_CHANGED');

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 22,
            child: Column(children: [
              const SizedBox(height: 4),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: dark ? darkBorder : const Color(0xFFE2DDCF)),
                ),
            ]),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_historyLabel(item),
                      style: TextStyle(
                          color: fg, fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(
                      [
                        _fmtDateTime(item['createdAt']),
                        if (actor.isNotEmpty) actor,
                      ].join('  ·  '),
                      style: TextStyle(color: muted, fontSize: 12)),
                  if (showNote) ...[
                    const SizedBox(height: 4),
                    Text(note,
                        style: TextStyle(color: muted, fontSize: 12.5, height: 1.4)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _attachmentTile(Map<String, dynamic> a, bool dark, Color fg, Color muted) {
    final isImage = _isImage(a);
    final url = ApiService().mediaUrl(a['url']);
    final name = (a['name'] ?? (a['url'] ?? '').toString().split('/').last).toString();
    final key = (a['id'] ?? a['url']).toString();
    final opening = _openingAttachmentId == key;
    final size = a['size'] is num ? _formatBytes(a['size'] as num) : '';

    return GestureDetector(
      onTap: () => _openAttachment(a),
      child: Container(
        height: 128,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
            color: dark ? darkCard : Colors.white,
            borderRadius: BorderRadius.circular(16)),
        child: isImage && url != null
            ? Stack(fit: StackFit.expand, children: [
                Image.network(url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Icon(Icons.broken_image_outlined, color: muted)),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    color: Colors.black.withValues(alpha: 0.5),
                    child: Text(size.isEmpty ? name : '$name · $size',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 11)),
                  ),
                ),
              ])
            : Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    opening
                        ? const SizedBox(
                            width: 26,
                            height: 26,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.insert_drive_file_outlined,
                            color: brandAmber, size: 34),
                    const SizedBox(height: 8),
                    Text(name,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: fg, fontSize: 12, fontWeight: FontWeight.w700)),
                    if (size.isNotEmpty)
                      Text(size, style: TextStyle(color: muted, fontSize: 11)),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _sectionTitle(String text, Color fg) => Text(text,
      style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 15));

  Widget _row(String label, String value, Color fg, Color muted, bool dark,
          {bool last = false}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          border: last
              ? null
              : Border(
                  bottom: BorderSide(
                      color: dark ? darkBorder : const Color(0xFFF0EBDD))),
        ),
        child: Row(
          children: [
            Text(label, style: TextStyle(color: muted, fontSize: 13)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(value,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                      color: fg, fontSize: 13, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );

  Widget _iconBtn(IconData icon, bool dark, Color fg, VoidCallback onTap) =>
      Container(
        decoration: BoxDecoration(
            color: dark ? darkCard : Colors.white,
            borderRadius: BorderRadius.circular(12)),
        child: IconButton(icon: Icon(icon, color: fg), onPressed: onTap),
      );
}
