// ignore_for_file: use_build_context_synchronously
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../../data/api_service.dart';

/// "Report Chat" — messaging thread attached to a maintenance ticket.
class ChatScreen extends StatefulWidget {
  final String ticketId;
  final String title;
  final String? subtitle;

  const ChatScreen({super.key, required this.ticketId, required this.title, this.subtitle});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ApiService _api = ApiService();
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  bool _loading = true;
  bool _sending = false;
  List<Map<String, dynamic>> _messages = [];
  final List<String> _pendingAttachments = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _api.getTicketMessages(widget.ticketId);
      if (mounted) {
        setState(() => _messages = list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList());
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _scrollToBottom() {
    if (!_scrollCtrl.hasClients) return;
    _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  Future<void> _pickAttachment() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true, allowMultiple: true);
    if (result == null) return;
    for (final file in result.files) {
      if (file.bytes == null) continue;
      final ext = (file.extension ?? 'jpg').toLowerCase();
      final mime = ext == 'png' ? 'image/png' : (ext == 'webp' ? 'image/webp' : 'image/jpeg');
      setState(() => _pendingAttachments.add('data:$mime;base64,${base64Encode(file.bytes!)}'));
      if (_pendingAttachments.length >= 6) break;
    }
  }

  Future<void> _send() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty && _pendingAttachments.isEmpty) return;
    setState(() => _sending = true);
    try {
      final attachments = List<String>.from(_pendingAttachments);
      final sent = await _api.sendTicketMessage(widget.ticketId,
          body: text.isEmpty ? null : text, attachmentDataUrls: attachments);
      setState(() {
        _messages.add(Map<String, dynamic>.from(sent));
        _textCtrl.clear();
        _pendingAttachments.clear();
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _dayLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(d.year, d.month, d.day);
    if (that == today) return "Aujourd'hui";
    if (that == today.subtract(const Duration(days: 1))) return 'Hier';
    return DateFormat('dd/MM/yyyy').format(d);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? Colors.white : brandNavy;
    final muted = dark ? darkMuted : const Color(0xFF6B7280);
    final myId = context.watch<AuthProvider>().user?['id'];

    String? lastDay;

    return Scaffold(
      backgroundColor: dark ? darkSurface : brandCream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  _iconBtn(Icons.arrow_back_rounded, dark, fg, () => Navigator.pop(context)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title,
                            style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 17),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        if (widget.subtitle != null && widget.subtitle!.isNotEmpty)
                          Text(widget.subtitle!,
                              style: TextStyle(color: muted, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _messages.isEmpty
                      ? Center(
                          child: Text('Aucun message pour le moment.',
                              style: TextStyle(color: muted, fontSize: 14)))
                      : ListView.builder(
                          controller: _scrollCtrl,
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          itemCount: _messages.length,
                          itemBuilder: (context, i) {
                            final m = _messages[i];
                            final createdAt = DateTime.tryParse((m['createdAt'] ?? '').toString())?.toLocal();
                            final showDivider = createdAt != null && _dayLabel(createdAt) != lastDay;
                            if (showDivider) lastDay = _dayLabel(createdAt);
                            final isMine = m['senderId'] != null && myId != null && '${m['senderId']}' == '$myId';

                            return Column(
                              children: [
                                if (showDivider) _dateDivider(_dayLabel(createdAt), dark, muted),
                                _bubble(m, isMine, dark, fg, muted, createdAt),
                              ],
                            );
                          },
                        ),
            ),
            if (_pendingAttachments.isNotEmpty)
              SizedBox(
                height: 64,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _pendingAttachments.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(
                          base64Decode(_pendingAttachments[i].split(',').last),
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: -4,
                        right: -4,
                        child: GestureDetector(
                          onTap: () => setState(() => _pendingAttachments.removeAt(i)),
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(color: Color(0xFFDC2626), shape: BoxShape.circle),
                            child: const Icon(Icons.close_rounded, size: 13, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _pickAttachment,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                          color: dark ? darkCard : Colors.white, borderRadius: BorderRadius.circular(14)),
                      alignment: Alignment.center,
                      child: Icon(Icons.attach_file_rounded, color: muted),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                          color: dark ? darkCard : Colors.white, borderRadius: BorderRadius.circular(24)),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _textCtrl,
                        minLines: 1,
                        maxLines: 4,
                        style: TextStyle(color: fg),
                        decoration: const InputDecoration(
                          hintText: 'Écrire un message...',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _sending ? null : _send,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(color: brandAmber, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: _sending
                          ? const SizedBox(
                              width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: brandNavy))
                          : const Icon(Icons.arrow_upward_rounded, color: brandNavy),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateDivider(String label, bool dark, Color muted) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
                color: dark ? darkCard : Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Text(label, style: TextStyle(color: muted, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ),
      );

  Widget _bubble(Map<String, dynamic> m, bool isMine, bool dark, Color fg, Color muted, DateTime? createdAt) {
    final body = (m['body'] ?? '').toString();
    final attachments = (m['attachments'] is List) ? List<dynamic>.from(m['attachments']) : const [];
    final time = createdAt != null ? DateFormat('HH:mm').format(createdAt) : '';
    final bubbleColor = isMine ? brandAmber.withValues(alpha: 0.18) : (dark ? darkCard : Colors.white);

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (body.isNotEmpty)
              Text(body, style: TextStyle(color: fg, fontSize: 14, height: 1.4)),
            if (attachments.isNotEmpty) ...[
              if (body.isNotEmpty) const SizedBox(height: 8),
              _attachmentsGrid(attachments, dark),
            ],
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(time, style: TextStyle(color: muted, fontSize: 10)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _attachmentsGrid(List<dynamic> attachments, bool dark) {
    final urls = attachments
        .whereType<Map>()
        .map((a) => (a['url'] ?? '').toString())
        .where((u) => u.isNotEmpty)
        .toList();
    if (urls.isEmpty) return const SizedBox.shrink();

    final base = ApiService().baseUrl.replaceAll('/api', '');
    final shown = urls.take(4).toList();
    final extra = urls.length - shown.length;

    return SizedBox(
      width: 200,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, mainAxisSpacing: 6, crossAxisSpacing: 6),
        itemCount: shown.length,
        itemBuilder: (_, i) {
          final isLastWithMore = extra > 0 && i == shown.length - 1;
          return ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network('$base${shown[i]}',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: dark ? darkBorder : const Color(0xFFE2E8F0))),
                if (isLastWithMore)
                  Container(
                    color: Colors.black.withValues(alpha: 0.5),
                    alignment: Alignment.center,
                    child: Text('+$extra',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _iconBtn(IconData icon, bool dark, Color fg, VoidCallback onTap) => Container(
        decoration: BoxDecoration(color: dark ? darkCard : Colors.white, borderRadius: BorderRadius.circular(12)),
        child: IconButton(icon: Icon(icon, color: fg), onPressed: onTap),
      );
}
