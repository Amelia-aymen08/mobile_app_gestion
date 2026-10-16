// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import '../widgets/gi_skeleton.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../l10n/app_localizations.dart';
import '../theme/design_tokens.dart';
import '../theme/gi_colors.dart';
import '../widgets/gi_pressable.dart';
import '../widgets/ticket_progress_strip.dart';
// `intl` exporte aussi un type TextDirection qui masque celui de Flutter.
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../data/api_service.dart';

/// "Report Chat" — messaging thread attached to a maintenance ticket.
class ChatScreen extends StatefulWidget {
  final String ticketId;
  final String title;
  final String? subtitle;

  /// Statut du ticket, pour la bande d'avancement en tete d'ecran. Absent,
  /// la bande n'est pas affichee.
  final String? status;

  const ChatScreen(
      {super.key,
      required this.ticketId,
      required this.title,
      this.subtitle,
      this.status});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ApiService _api = ApiService();
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  bool _loading = true;
  List<Map<String, dynamic>> _messages = [];

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
    final c = GiColors.of(context);
    final t = AppL10n.of(context);
    final myId = context.watch<AuthProvider>().user?['id'];

    String? lastDay;

    return Scaffold(
      backgroundColor: c.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            // En-tete du Figma : pastille de retour, reference en 16 Medium et
            // le titre du signalement en 12 dessous.
            Padding(
              padding: EdgeInsets.fromLTRB(
                  FigSpace.pagePadding,
                  MediaQuery.paddingOf(context).top > 0 ? 22 : 32,
                  FigSpace.pagePadding,
                  FigSpace.xl),
              child: Row(
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
                        flipX:
                            Directionality.of(context) == TextDirection.rtl,
                        child: SvgPicture.asset(
                          'assets/figma/icons/back_14.svg',
                          colorFilter:
                              ColorFilter.mode(c.textBody, BlendMode.srcIn),
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
                        Text(widget.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: FigText.titleMd
                                .copyWith(fontSize: 18, color: c.textBody)),
                        if (widget.subtitle?.isNotEmpty == true) ...[
                          const SizedBox(height: 2),
                          Text(widget.subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  FigText.label.copyWith(color: c.textMuted)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if ((widget.status ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    FigSpace.pagePadding, 0, FigSpace.pagePadding, FigSpace.lg),
                child: TicketProgressStrip(status: widget.status!),
              ),
            Expanded(
              child: _loading
                  ? const GiSkeletonList(count: 3, itemHeight: 72)
                  : _messages.isEmpty
                      ? _emptyState(c, t)
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          controller: _scrollCtrl,
                          padding: const EdgeInsets.fromLTRB(
                              FigSpace.pagePadding, 0,
                              FigSpace.pagePadding, FigSpace.xl),
                          itemCount: _messages.length,
                          itemBuilder: (context, i) {
                            final m = _messages[i];
                            final createdAt = DateTime.tryParse(
                                    (m['createdAt'] ?? '').toString())
                                ?.toLocal();
                            final showDivider = createdAt != null &&
                                _dayLabel(createdAt) != lastDay;
                            if (showDivider) lastDay = _dayLabel(createdAt);
                            final isMine = m['senderId'] != null &&
                                myId != null &&
                                '${m['senderId']}' == '$myId';

                            return Column(
                              children: [
                                if (showDivider)
                                  _dayPill(c, _dayLabel(createdAt)),
                                _bubble(c, m, isMine, createdAt),
                                const SizedBox(height: FigSpace.lg),
                              ],
                            );
                          },
                        ),
            ),
            _readOnlyNote(c, t),
          ],
        ),
      ),
    );
  }

  /// Pastille de date, centree entre deux journees de messages.
  Widget _dayPill(GiColors c, String label) => Padding(
        padding: const EdgeInsets.only(bottom: FigSpace.lg),
        child: Center(
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
            decoration: BoxDecoration(
              color: c.card,
              border: Border.all(color: c.cardBorder),
              borderRadius: BorderRadius.circular(FigRadius.pill),
            ),
            child: Text(label,
                style: FigText.label.copyWith(color: c.textMuted)),
          ),
        ),
      );

  /// Bulle de message — Figma : largeur 280, padding 16, rayon 16 sauf l'angle
  /// tourne vers son auteur, qui reste droit. L'angle plat indique d'ou vient
  /// le message sans avoir besoin de couleur.
  Widget _bubble(
      GiColors c, Map<String, dynamic> m, bool isMine, DateTime? createdAt) {
    final text = (m['message'] ?? m['body'] ?? '').toString();
    final attachment = (m['attachmentUrl'] ?? '').toString();
    final time = createdAt == null
        ? ''
        : '${createdAt.hour.toString().padLeft(2, '0')}:'
            '${createdAt.minute.toString().padLeft(2, '0')}';

    return Align(
      alignment:
          isMine ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: Container(
          padding: const EdgeInsets.all(FigSpace.cardPadding),
          decoration: BoxDecoration(
            // Le message recu est un cran plus sombre que celui envoye : le
            // Figma les distingue par la densite, pas par la teinte.
            color: isMine ? c.card : c.innerBorder.withValues(alpha: 0.45),
            border: Border.all(color: c.cardBorder),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(FigRadius.card),
              topRight: const Radius.circular(FigRadius.card),
              bottomLeft: Radius.circular(isMine ? FigRadius.card : 0),
              bottomRight: Radius.circular(isMine ? 0 : FigRadius.card),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (text.isNotEmpty)
                Text(text,
                    style: FigText.fieldLabel
                        .copyWith(height: 1.4, color: c.textBody)),
              if (attachment.isNotEmpty) ...[
                const SizedBox(height: FigSpace.lg),
                ClipRRect(
                  borderRadius: BorderRadius.circular(FigRadius.chip),
                  child: Image.network(attachment,
                      loadingBuilder: giImageLoading,
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          ColoredBox(color: c.innerBorder)),
                ),
              ],
              const SizedBox(height: FigSpace.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(time,
                      style: FigText.label.copyWith(color: c.textMuted)),
                  if (isMine) ...[
                    const SizedBox(width: FigSpace.sm),
                    SvgPicture.asset(
                      'assets/figma/icons/check_14.svg',
                      colorFilter:
                          ColorFilter.mode(c.textMuted, BlendMode.srcIn),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Fil vide : une pastille d'icone et le texte centre, avec des marges —
  /// sans elles le texte touchait les bords de l'ecran.
  Widget _emptyState(GiColors c, AppL10n t) {
    // Defilant : en paysage ou clavier ouvert, la hauteur ne suffit pas.
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: FigBrand.amber.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.forum_rounded,
                  size: 28, color: FigBrand.amber),
            ),
            const SizedBox(height: FigSpace.xl),
            Text(t.chatEmptyReadOnly,
                textAlign: TextAlign.center,
                style: FigText.fieldLabel
                    .copyWith(height: 1.5, color: c.textMuted)),
          ],
        ),
      ),
    );
  }

  /// Le resident ne repond pas ici : le signalement porte deja sa
  /// description, et l'administration s'en sert pour transmettre une
  /// information. Une barre de saisie laisserait croire a un echange.
  Widget _readOnlyNote(GiColors c, AppL10n t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          FigSpace.pagePadding, 0, FigSpace.pagePadding, FigSpace.xl),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: c.fieldBg,
          borderRadius: BorderRadius.circular(FigRadius.card),
        ),
        child: Row(
          children: [
            Icon(Icons.lock_outline_rounded, size: 18, color: c.textMuted),
            const SizedBox(width: FigSpace.lg),
            Expanded(
              child: Text(t.chatReadOnly,
                  style: FigText.label
                      .copyWith(fontSize: 13, height: 1.4, color: c.textMuted)),
            ),
          ],
        ),
      ),
    );
  }
}

