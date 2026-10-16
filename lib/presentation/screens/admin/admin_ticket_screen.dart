// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
// `intl` exporte aussi un type TextDirection qui masque celui de Flutter.
import 'package:intl/intl.dart' hide TextDirection;

import '../../../data/api_service.dart';
import '../../services/file_opener.dart';
import '../../services/gi_haptics.dart';
import '../../theme/design_tokens.dart';
import '../../theme/gi_colors.dart';
import '../../theme/ticket_status.dart';
import '../../widgets/gi_appear.dart';
import '../../widgets/gi_card.dart';
import '../../widgets/gi_pressable.dart';
import '../../widgets/gi_primary_button.dart';
import '../../widgets/gi_skeleton.dart';
import '../chat_screen.dart';
import 'admin_assignee_picker.dart';
import 'admin_residence_screen.dart';
import 'admin_store.dart';
import 'admin_ui.dart';

/// Ouvre un ticket depuis n'importe quel ecran de l'administration.
Future<void> openAdminTicket(
        BuildContext context, AdminStore store, Map ticket) =>
    adminPush(
        context,
        AdminTicketScreen(
            store: store, ticket: Map<String, dynamic>.from(ticket)));

/// Fiche d'un ticket pour l'administration.
///
/// Remplace la boite de dialogue d'autrefois — du texte brut et deux listes
/// deroulantes. On y retrouve la fiche du resident (en-tete, suivi, pieces
/// jointes, historique) et, a cote, le panneau de gestion : statut en puces,
/// intervenant choisi sur une page de recherche, rejet motive sans quitter
/// l'ecran. Sur ordinateur les deux colonnes se font face.
class AdminTicketScreen extends StatefulWidget {
  final AdminStore store;
  final Map<String, dynamic> ticket;
  const AdminTicketScreen(
      {super.key, required this.store, required this.ticket});

  @override
  State<AdminTicketScreen> createState() => _AdminTicketScreenState();
}

const _rejectReasons = [
  'Charges non payées',
  'Problème non justifié',
  'Hors périmètre de la copropriété',
  'Doublon de ticket existant',
];

class _AdminTicketScreenState extends State<AdminTicketScreen> {
  final ApiService _api = ApiService();
  late Map<String, dynamic> _ticket = Map<String, dynamic>.from(widget.ticket);
  Map<String, dynamic>? _history;
  bool _loading = true;
  String _chargeStatus = '';

  // Panneau de gestion : brouillon tant qu'on n'a pas enregistre.
  late TicketStage _stage = ticketStage(_ticket['status']);
  late String _assignee = AdminStore.assigneeValue(_ticket);
  String _assigneeLabel = '';
  String _assigneeDetail = '';
  bool _saving = false;
  bool _rejecting = false;
  String? _reason;
  String? _opening;

  AdminStore get _store => widget.store;
  String get _id => TicketFields.id(_ticket);

  bool get _dirty =>
      _stage != ticketStage(_ticket['status']) ||
      _assignee != AdminStore.assigneeValue(_ticket);

  @override
  void initState() {
    super.initState();
    _assigneeLabel = TicketFields.assignee(_ticket);
    _load();
  }

  Future<void> _load() async {
    final email = (_ticket['email'] ?? '').toString();
    final results = await Future.wait<Object?>([
      _api.getTicket(_id).then<Object?>((v) => v).catchError((_) => null),
      _api
          .getTicketHistory(_id)
          .then<Object?>((v) => v)
          .catchError((_) => null),
      if (_store.canReject && email.isNotEmpty)
        _store
            .chargeStatus(email)
            .then<Object?>((v) => v)
            .catchError((_) => ''),
    ]);
    if (!mounted) return;
    setState(() {
      final fresh = results[0];
      if (fresh is Map<String, dynamic> && fresh.isNotEmpty) {
        final wasDirty = _dirty;
        _ticket = {..._ticket, ...fresh};
        if (!wasDirty) {
          _stage = ticketStage(_ticket['status']);
          _assignee = AdminStore.assigneeValue(_ticket);
          _assigneeLabel = TicketFields.assignee(_ticket);
        }
      }
      final h = results[1];
      if (h is Map<String, dynamic>) _history = h;
      if (results.length > 2) _chargeStatus = (results[2] ?? '').toString();
      _loading = false;
    });
  }

  // ─── Actions ──────────────────────────────────────────────

  Future<void> _pickAssignee() async {
    final picked = await adminPush<AssigneeOption?>(
      context,
      AdminAssigneePicker(store: _store, current: _assignee),
    );
    if (picked == null || !mounted) return;
    GiHaptics.select();
    setState(() {
      _assignee = picked.value;
      _assigneeLabel = picked.name;
      _assigneeDetail = picked.detail;
      // Designer quelqu'un sur un ticket nouveau, c'est le prendre en
      // charge : on avance le statut, l'administrateur peut le ramener.
      if (picked.value.isNotEmpty && _stage == TicketStage.open) {
        _stage = TicketStage.inProgress;
      }
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final payload = <String, dynamic>{'status': _stage.apiValue};
    final local = <String, dynamic>{};
    // On n'envoie l'intervenant que s'il a change : le renvoyer tel quel
    // relance cote serveur le controle d'attribution, qui echoue quand un
    // autre responsable a deja pris le ticket.
    if (_assignee != AdminStore.assigneeValue(_ticket)) {
      if (_assignee.isEmpty) {
        payload['assignee'] = null;
        payload['subcontractorId'] = null;
        local['subcontractor'] = null;
      } else if (_assignee.startsWith('sub:')) {
        final id = _assignee.substring(4);
        payload['subcontractorId'] = id;
        payload['assignee'] = null;
        local['subcontractor'] = {'id': id, 'name': _assigneeLabel};
      } else {
        payload['assignee'] = _assignee.substring(6);
        payload['subcontractorId'] = null;
        local['subcontractor'] = null;
      }
    }
    try {
      final merged = await _store.update(_id, payload, local: local);
      if (!mounted) return;
      setState(() {
        _ticket = {..._ticket, ...merged};
        _saving = false;
      });
      showAdminToast(context, 'Ticket mis à jour');
      _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAdminToast(context, _clean(e), error: true);
    }
  }

  Future<void> _reject() async {
    if (_reason == null) return;
    setState(() => _saving = true);
    try {
      final merged = await _store.update(_id, {
        'status': TicketStage.rejected.apiValue,
        'rejectionReason': _reason
      });
      if (!mounted) return;
      setState(() {
        _ticket = {..._ticket, ...merged};
        _stage = TicketStage.rejected;
        _rejecting = false;
        _saving = false;
      });
      showAdminToast(context, 'Ticket rejeté');
      _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAdminToast(context, _clean(e), error: true);
    }
  }

  void _openChat() => adminPush(
        context,
        ChatScreen(
          ticketId: _id,
          title: TicketFields.title(_ticket),
          subtitle: TicketFields.ref(_ticket),
          status: (_ticket['status'] ?? '').toString(),
        ),
      );

  void _openResidence() {
    final id = TicketFields.residenceId(_ticket);
    if (id.isEmpty) return;
    adminPush(context, AdminResidenceScreen(store: _store, residenceId: id));
  }

  static String _clean(Object e) =>
      e.toString().replaceFirst('Exception: ', '');

  // ─── Pieces jointes ───────────────────────────────────────

  List<Map<String, dynamic>> get _attachments {
    final raw = _ticket['attachments'];
    final list = raw is List
        ? raw.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList()
        : <Map<String, dynamic>>[];
    // Les anciens tickets n'ont qu'une piece jointe, dans deux champs a part.
    final legacy = (_ticket['attachmentUrl'] ?? '').toString();
    if (list.isEmpty && legacy.isNotEmpty) {
      list.add({
        'url': legacy,
        'name': (_ticket['attachmentName'] ?? 'Pièce jointe').toString(),
      });
    }
    return list;
  }

  static bool _isImage(Map a) {
    final type = (a['type'] ?? '').toString().toLowerCase();
    if (type.startsWith('image/')) return true;
    final name = ((a['name'] ?? a['url']) ?? '').toString().toLowerCase();
    return RegExp(r'\.(jpe?g|png|webp)$').hasMatch(name);
  }

  Future<void> _openAttachment(Map<String, dynamic> a) async {
    final url = (a['url'] ?? '').toString();
    if (_opening != null || url.isEmpty) return;
    if (_isImage(a)) {
      final full = _api.mediaUrl(url);
      if (full != null) {
        Navigator.of(context).push(PageRouteBuilder(
          opaque: false,
          barrierColor: Colors.black,
          transitionDuration: const Duration(milliseconds: 260),
          pageBuilder: (_, a, __) =>
              FadeTransition(opacity: a, child: _ImageViewer(url: full)),
        ));
      }
      return;
    }
    setState(() => _opening = url);
    try {
      final bytes = await _api.downloadPublicFile(url);
      await FileOpener.openBytes(bytes, (a['name'] ?? 'document').toString());
    } catch (e) {
      if (!mounted) return;
      final raw = _clean(e);
      if (raw == 'noAppToOpen' || raw == 'openFailed') {
        await Clipboard.setData(ClipboardData(text: _api.mediaUrl(url) ?? url));
        if (mounted) {
          showAdminToast(context, 'Impossible d\'ouvrir — lien copié');
        }
      } else {
        showAdminToast(context, raw, error: true);
      }
    } finally {
      if (mounted) setState(() => _opening = null);
    }
  }

  // ─── Build ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    final wide = MediaQuery.sizeOf(context).width >= kAdminWide;
    final top = MediaQuery.paddingOf(context).top > 0 ? 14.0 : 24.0;
    final created = TicketFields.created(_ticket);

    final header = Padding(
      padding: EdgeInsets.fromLTRB(
          FigSpace.pagePadding, top, FigSpace.pagePadding, 0),
      child: AdminContent(
        child: AdminPageHeader(
          back: true,
          title: 'Ticket ${TicketFields.ref(_ticket)}',
          subtitle: created == null
              ? null
              : 'Signalé ${timeAgoLabel(created).toLowerCase()}',
          actions: [
            AdminSquareButton(
              tooltip: 'Conversation',
              onTap: _openChat,
              child: Icon(Icons.forum_outlined, size: 19, color: c.textBody),
            ),
          ],
        ),
      ),
    );

    final main = <Widget>[
      _contentCard(c),
      const SizedBox(height: FigSpace.lg),
      if (!wide) ...[
        _manageCard(c),
        const SizedBox(height: FigSpace.lg),
      ],
      _contextCard(c),
      const SizedBox(height: FigSpace.lg),
      _pipelineCard(c),
      if (_attachments.isNotEmpty) ...[
        const SizedBox(height: FigSpace.lg),
        _attachmentsCard(c),
      ],
      const SizedBox(height: FigSpace.lg),
      _historyCard(c),
    ];

    final body = wide
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < main.length; i++)
                      GiAppear(index: i ~/ 2, child: main[i]),
                  ],
                ),
              ),
              const SizedBox(width: FigSpace.xl + 4),
              SizedBox(
                width: 360,
                child: GiAppear(index: 1, child: _manageCard(c)),
              ),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < main.length; i++)
                GiAppear(index: i ~/ 2, child: main[i]),
            ],
          );

    return Scaffold(
      backgroundColor: c.scaffold,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            header,
            const SizedBox(height: 18),
            Expanded(
              child: RefreshIndicator(
                color: FigBrand.amber,
                backgroundColor: c.card,
                onRefresh: _load,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics()),
                  padding: EdgeInsets.fromLTRB(
                      FigSpace.pagePadding,
                      0,
                      FigSpace.pagePadding,
                      MediaQuery.paddingOf(context).bottom + 32),
                  child: AdminContent(child: body),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// En-tete : pastille de la categorie, titre, statut et priorite, puis la
  /// description telle que le resident l'a ecrite.
  Widget _contentCard(GiColors c) {
    final stage = ticketStage(_ticket['status']);
    final priority = ticketPriority(_ticket['priority']);
    final category = (_ticket['category'] ?? '').toString();
    final description = (_ticket['description'] ?? '').toString().trim();
    final reason = (_ticket['rejectionReason'] ?? '').toString().trim();

    return GiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminCategoryTile(
                  category: category, color: stage.color, size: 52),
              const SizedBox(width: FigSpace.lg + 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (category.isNotEmpty)
                      Text(category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: FigText.label.copyWith(color: c.textMuted)),
                    const SizedBox(height: 2),
                    Text(TicketFields.title(_ticket),
                        style: FigText.titleMd.copyWith(
                            fontSize: 19, height: 1.25, color: c.textBody)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: FigSpace.lg),
          Wrap(
            spacing: FigSpace.md,
            runSpacing: FigSpace.md,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: KeyedSubtree(
                    key: ValueKey(stage), child: AdminPill.stage(stage)),
              ),
              AdminPill.priority(priority),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: FigSpace.lg),
            Container(
              padding: const EdgeInsets.all(FigSpace.lg),
              decoration: BoxDecoration(
                color: c.fieldBg,
                borderRadius: BorderRadius.circular(FigRadius.field + 2),
              ),
              child: Text(description,
                  style: FigText.fieldLabel
                      .copyWith(height: 1.45, color: c.textBody)),
            ),
          ],
          if (stage == TicketStage.rejected && reason.isNotEmpty) ...[
            const SizedBox(height: FigSpace.lg),
            Container(
              padding: const EdgeInsets.all(FigSpace.lg),
              decoration: BoxDecoration(
                color: FigAlert.error.withValues(alpha: 0.08),
                border:
                    Border.all(color: FigAlert.error.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(FigRadius.field + 2),
              ),
              child: Row(
                children: [
                  const Icon(Icons.block_rounded,
                      size: 18, color: FigAlert.error),
                  const SizedBox(width: FigSpace.md),
                  Expanded(
                    child: Text('Rejeté : $reason',
                        style: FigText.fieldLabel.copyWith(
                            fontWeight: FontWeight.w500,
                            color: FigAlert.error)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Le panneau de gestion. Les choix restent un brouillon jusqu'a
  /// « Enregistrer », qui n'apparait que lorsqu'il y a quelque chose a
  /// enregistrer.
  Widget _manageCard(GiColors c) {
    final current = ticketStage(_ticket['status']);
    final closed = current == TicketStage.rejected;
    final canEdit = _store.canAssign || _store.allowedStages.isNotEmpty;

    return GiCard(
      borderColor: FigBrand.amber.withValues(alpha: 0.35),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.tune_rounded, size: 20, color: FigBrand.amber),
                const SizedBox(width: FigSpace.md),
                Text('Gestion',
                    style: FigText.titleMd.copyWith(color: c.textBody)),
              ],
            ),
            if (closed) ...[
              const SizedBox(height: FigSpace.lg),
              Text(
                  'Ce ticket a été rejeté. Il reste consultable, '
                  'mais ne peut plus être modifié.',
                  style:
                      FigText.body.copyWith(height: 1.4, color: c.textMuted)),
            ] else if (canEdit) ...[
              const SizedBox(height: FigSpace.xl),
              _fieldLabel(c, 'Statut'),
              const SizedBox(height: FigSpace.md),
              Wrap(
                spacing: FigSpace.md,
                runSpacing: FigSpace.md,
                children: [
                  for (final s in _store.allowedStages) _stageChip(c, s),
                ],
              ),
              if (_store.canAssign) ...[
                const SizedBox(height: FigSpace.xl),
                _fieldLabel(c, 'Intervenant'),
                const SizedBox(height: FigSpace.md),
                _assigneeRow(c),
              ],
              // Le bouton n'existe que s'il y a un changement a enregistrer.
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, a) => FadeTransition(
                  opacity: a,
                  child: SizeTransition(sizeFactor: a, child: child),
                ),
                child: _dirty
                    ? Padding(
                        key: const ValueKey('save'),
                        padding: const EdgeInsets.only(top: FigSpace.xl),
                        child: Row(
                          children: [
                            Expanded(
                              child: _ghostButton(c, 'Annuler', () {
                                setState(() {
                                  _stage = ticketStage(_ticket['status']);
                                  _assignee = AdminStore.assigneeValue(_ticket);
                                  _assigneeLabel =
                                      TicketFields.assignee(_ticket);
                                  _assigneeDetail = '';
                                });
                              }),
                            ),
                            const SizedBox(width: FigSpace.md),
                            Expanded(
                              flex: 2,
                              child: GiPrimaryButton(
                                label: 'Enregistrer',
                                isLoading: _saving && !_rejecting,
                                onPressed: _save,
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox(
                        key: ValueKey('none'), width: double.infinity),
              ),
              if (_store.canReject && current != TicketStage.done) ...[
                const SizedBox(height: FigSpace.xl),
                Divider(height: 1, color: c.innerBorder),
                const SizedBox(height: FigSpace.md),
                _rejectSection(c),
              ],
            ],
            const SizedBox(height: FigSpace.lg),
            _ghostButton(c, 'Ouvrir la conversation', _openChat,
                icon: Icons.forum_outlined),
          ],
        ),
      ),
    );
  }

  Widget _fieldLabel(GiColors c, String text) => Text(text,
      style: FigText.fieldLabel
          .copyWith(fontWeight: FontWeight.w600, color: c.textBody));

  Widget _stageChip(GiColors c, TicketStage s) {
    final on = s == _stage;
    return GiPressable(
      pressedScale: 0.94,
      haptic: false,
      onTap: () {
        if (on) return;
        GiHaptics.select();
        setState(() => _stage = s);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.fromLTRB(12, 9, 14, 9),
        decoration: BoxDecoration(
          color: on ? s.color.withValues(alpha: 0.16) : c.fieldBg,
          border: Border.all(
              color: on ? s.color : c.fieldBorder, width: on ? 1.4 : 1),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(s.icon, size: 16, color: on ? s.color : c.textMuted),
            const SizedBox(width: 7),
            Text(s.label,
                style: FigText.fieldLabel.copyWith(
                    fontSize: 13.5,
                    fontWeight: on ? FontWeight.w600 : FontWeight.w500,
                    color: on ? s.color : c.textBody)),
          ],
        ),
      ),
    );
  }

  Widget _assigneeRow(GiColors c) {
    final empty = _assignee.isEmpty;
    return GiPressable(
      pressedScale: 0.98,
      onTap: _pickAssignee,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.fieldBg,
          border: Border.all(
              color: empty
                  ? FigBrand.amber.withValues(alpha: 0.6)
                  : c.fieldBorder),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: (empty ? FigBrand.amber : FigAccent.violet)
                    .withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: empty
                  ? const Icon(Icons.person_add_alt_1_rounded,
                      size: 19, color: FigBrand.amber)
                  : Text(_initials(_assigneeLabel),
                      style: FigText.label.copyWith(
                          fontWeight: FontWeight.w700,
                          color: FigAccent.violet)),
            ),
            const SizedBox(width: FigSpace.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(empty ? 'Choisir un intervenant' : _assigneeLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: FigText.fieldLabel.copyWith(
                          fontWeight: FontWeight.w600,
                          color: empty ? FigBrand.amber : c.textBody)),
                  const SizedBox(height: 2),
                  Text(
                      empty
                          ? 'Personne ne s\'en occupe encore'
                          : (_assigneeDetail.isEmpty
                              ? 'Toucher pour changer'
                              : _assigneeDetail),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: FigText.label.copyWith(color: c.textMuted)),
                ],
              ),
            ),
            GiChevron(color: c.textMuted),
          ],
        ),
      ),
    );
  }

  /// Le rejet se deplie sur place : motif en puces, puis confirmation.
  Widget _rejectSection(GiColors c) {
    if (!_rejecting) {
      return GiPressable(
        pressedScale: 0.97,
        onTap: () => setState(() => _rejecting = true),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.block_rounded, size: 18, color: FigAlert.error),
              const SizedBox(width: FigSpace.md),
              Text('Rejeter le ticket',
                  style: FigText.fieldLabel.copyWith(
                      fontWeight: FontWeight.w600, color: FigAlert.error)),
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: FigSpace.md),
        Row(
          children: [
            Expanded(
              child: Text('Motif du rejet',
                  style: FigText.fieldLabel.copyWith(
                      fontWeight: FontWeight.w600, color: FigAlert.error)),
            ),
            if (_chargeStatus.isNotEmpty)
              AdminPill('Charges : $_chargeStatus',
                  _chargeStatus == 'Payé' ? FigAlert.success : FigAlert.error,
                  dense: true),
          ],
        ),
        const SizedBox(height: FigSpace.md),
        for (final r in _rejectReasons) ...[
          _reasonRow(c, r),
          const SizedBox(height: FigSpace.sm),
        ],
        const SizedBox(height: FigSpace.md),
        Row(
          children: [
            Expanded(
              child: _ghostButton(c, 'Annuler', () {
                setState(() {
                  _rejecting = false;
                  _reason = null;
                });
              }),
            ),
            const SizedBox(width: FigSpace.md),
            Expanded(
              flex: 2,
              child: GiPressable(
                pressedScale: 0.97,
                onTap: _reason == null || _saving ? null : _reject,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _reason == null
                        ? FigAlert.error.withValues(alpha: 0.25)
                        : FigAlert.error,
                    borderRadius: BorderRadius.circular(FigRadius.cta),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text('Confirmer le rejet',
                          style: FigText.button.copyWith(color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _reasonRow(GiColors c, String r) {
    final on = r == _reason;
    return GiPressable(
      pressedScale: 0.98,
      haptic: false,
      onTap: () {
        GiHaptics.select();
        setState(() => _reason = r);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: on ? FigAlert.error.withValues(alpha: 0.1) : c.fieldBg,
          border: Border.all(color: on ? FigAlert.error : c.fieldBorder),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: on ? FigAlert.error : c.textFaint,
                    width: on ? 5 : 1.5),
              ),
            ),
            const SizedBox(width: FigSpace.lg),
            Expanded(
              child: Text(r,
                  style: FigText.fieldLabel.copyWith(color: c.textBody)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ghostButton(GiColors c, String label, VoidCallback onTap,
      {IconData? icon}) {
    return GiPressable(
      pressedScale: 0.97,
      onTap: onTap,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: c.fieldBorder),
          borderRadius: BorderRadius.circular(FigRadius.cta),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: c.textBody),
              const SizedBox(width: FigSpace.md),
            ],
            Flexible(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: FigText.button.copyWith(color: c.textBody)),
            ),
          ],
        ),
      ),
    );
  }

  /// Demandeur et lieu : qui, ou, quand, et l'etat de ses charges.
  Widget _contextCard(GiColors c) {
    final requester = TicketFields.requester(_ticket);
    final email = (_ticket['email'] ?? '').toString();
    final residence = _store.residenceNameOf(_ticket);
    final location = (_ticket['location'] ?? '').toString().trim();
    final created = TicketFields.created(_ticket);

    final rows = <Widget>[
      if (requester.isNotEmpty || email.isNotEmpty)
        _infoRow(
          c,
          Icons.person_outline_rounded,
          'Demandeur',
          requester.isNotEmpty ? requester : email,
          sub: requester.isNotEmpty ? email : null,
          trailing: _chargeStatus.isEmpty
              ? null
              : AdminPill(_chargeStatus,
                  _chargeStatus == 'Payé' ? FigAlert.success : FigAlert.error,
                  icon: Icons.payments_outlined, dense: true),
        ),
      if (residence.isNotEmpty)
        _infoRow(c, Icons.apartment_rounded, 'Résidence', residence,
            onTap: _openResidence),
      if (location.isNotEmpty)
        _infoRow(c, Icons.place_outlined, 'Lieu', location),
      if (created != null)
        _infoRow(c, Icons.event_outlined, 'Signalé le',
            DateFormat('dd/MM/yyyy · HH:mm').format(created)),
    ];

    return GiCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Divider(height: 1, color: c.innerBorder),
            rows[i],
          ],
        ],
      ),
    );
  }

  Widget _infoRow(GiColors c, IconData icon, String label, String value,
      {String? sub, Widget? trailing, VoidCallback? onTap}) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 19, color: c.textMuted),
          const SizedBox(width: FigSpace.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: FigText.label.copyWith(color: c.textFaint)),
                const SizedBox(height: 2),
                Text(value,
                    style: FigText.fieldLabel.copyWith(
                        fontWeight: FontWeight.w500,
                        color: onTap != null ? FigBrand.amber : c.textBody)),
                if (sub != null && sub.isNotEmpty)
                  Text(sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: FigText.label.copyWith(color: c.textMuted)),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: FigSpace.md),
            trailing,
          ],
          if (onTap != null) const GiChevron(color: FigBrand.amber),
        ],
      ),
    );
    return onTap == null
        ? row
        : GiPressable(pressedScale: 0.98, onTap: onTap, child: row);
  }

  /// Suivi en trois etapes, comme chez le resident.
  Widget _pipelineCard(GiColors c) {
    final stage = ticketStage(_ticket['status']);
    final finished = stage == TicketStage.done;
    final started =
        finished || stage == TicketStage.inProgress || stage == TicketStage.sav;
    String fmt(Object? raw) {
      final d = DateTime.tryParse((raw ?? '').toString())?.toLocal();
      return d == null ? '' : DateFormat('dd/MM/yyyy · HH:mm').format(d);
    }

    final startedAt = fmt(_history?['startedAt']);
    final closedAt = fmt(_history?['closedAt']);
    final steps = <({String label, String detail, bool done})>[
      (label: 'Signalé', detail: fmt(_ticket['createdAt']), done: true),
      (
        label: stage == TicketStage.sav ? 'En SAV' : 'Pris en charge',
        detail: startedAt.isNotEmpty
            ? startedAt
            : (started
                ? 'En cours de traitement'
                : 'En attente d\'un intervenant'),
        done: started,
      ),
      (
        label: stage == TicketStage.rejected ? 'Rejeté' : 'Clôturé',
        detail: closedAt.isNotEmpty
            ? closedAt
            : (stage == TicketStage.rejected
                ? 'Ticket refusé'
                : 'Après vérification de l\'intervention'),
        done: finished || stage == TicketStage.rejected,
      ),
    ];
    final current = finished || stage == TicketStage.rejected
        ? -1
        : steps.lastIndexWhere((e) => e.done);
    final accent =
        stage == TicketStage.rejected ? FigAlert.error : FigBrand.amber;

    return GiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Suivi', style: FigText.titleMd.copyWith(color: c.textBody)),
          const SizedBox(height: FigSpace.xl),
          for (var i = 0; i < steps.length; i++)
            _stepRow(c,
                label: steps[i].label,
                detail: steps[i].detail,
                done: steps[i].done,
                current: i == current,
                accent: accent,
                lineActive: i + 1 < steps.length && steps[i + 1].done,
                last: i == steps.length - 1),
        ],
      ),
    );
  }

  Widget _stepRow(GiColors c,
      {required String label,
      required String detail,
      required bool done,
      required bool current,
      required Color accent,
      required bool lineActive,
      required bool last}) {
    final faint = c.textFaint.withValues(alpha: 0.35);
    final node = done
        ? Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
              boxShadow: current
                  ? [
                      BoxShadow(
                          color: accent.withValues(alpha: 0.25),
                          spreadRadius: 5)
                    ]
                  : null,
            ),
            child: Icon(
                accent == FigAlert.error && last
                    ? Icons.close_rounded
                    : Icons.check_rounded,
                size: 16,
                color: Colors.black),
          )
        : Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: faint, width: 2),
            ),
          );

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 26,
            child: Column(
              children: [
                node,
                if (!last)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: lineActive ? accent : faint,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: FigSpace.lg + 2),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 3, bottom: last ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(label,
                            style: FigText.fieldLabel.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: done ? c.textBody : c.textMuted)),
                      ),
                      if (current) ...[
                        const SizedBox(width: FigSpace.md),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text('Étape actuelle',
                              style: FigText.caption.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: accent)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(detail,
                      style: FigText.label
                          .copyWith(color: done ? c.textMuted : c.textFaint)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _attachmentsCard(GiColors c) {
    final files = _attachments;
    return GiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Pièces jointes (${files.length})',
              style: FigText.titleMd.copyWith(color: c.textBody)),
          const SizedBox(height: FigSpace.lg),
          LayoutBuilder(builder: (context, constraints) {
            final cols = constraints.maxWidth > 520 ? 4 : 3;
            final w = (constraints.maxWidth - FigSpace.md * (cols - 1)) / cols;
            return Wrap(
              spacing: FigSpace.md,
              runSpacing: FigSpace.md,
              children: [for (final a in files) _thumb(c, a, w)],
            );
          }),
        ],
      ),
    );
  }

  Widget _thumb(GiColors c, Map<String, dynamic> a, double w) {
    final url = _api.mediaUrl(a['url']);
    final busy = _opening == (a['url'] ?? '').toString();
    return GiPressable(
      pressedScale: 0.95,
      onTap: () => _openAttachment(a),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: w,
          height: 100,
          child: _isImage(a) && url != null
              ? Image.network(url,
                  loadingBuilder: giImageLoading,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      ColoredBox(color: c.innerBorder))
              : Container(
                  color: c.fieldBg,
                  padding: const EdgeInsets.all(FigSpace.md),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (busy)
                        const GiShimmer(
                            child: GiBone(width: 18, height: 18, radius: 9))
                      else
                        SvgPicture.asset('assets/figma/icons/documents_20.svg',
                            colorFilter:
                                ColorFilter.mode(c.textBody, BlendMode.srcIn)),
                      const SizedBox(height: FigSpace.sm),
                      Text((a['name'] ?? '').toString(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: FigText.caption.copyWith(color: c.textBody)),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _historyCard(GiColors c) {
    final items =
        ((_history?['history'] as List?) ?? const []).whereType<Map>().toList();
    if (!_loading && items.isEmpty) return const SizedBox.shrink();
    return GiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.history_rounded, size: 20, color: c.textBody),
              const SizedBox(width: FigSpace.md),
              Expanded(
                child: Text('Historique',
                    style: FigText.titleMd.copyWith(color: c.textBody)),
              ),
              if (items.isNotEmpty)
                Text('${items.length}',
                    style: FigText.label.copyWith(color: c.textMuted)),
            ],
          ),
          const SizedBox(height: FigSpace.xl),
          if (_loading && items.isEmpty)
            const GiShimmer(
              child: Column(
                children: [
                  GiBone(height: 12),
                  SizedBox(height: 12),
                  GiBone(height: 12),
                ],
              ),
            )
          else
            for (var i = 0; i < items.length; i++)
              _historyRow(c, items[i], last: i == items.length - 1),
        ],
      ),
    );
  }

  Widget _historyRow(GiColors c, Map item, {required bool last}) {
    final action = (item['action'] ?? '').toString();
    final (icon, accent, label) = switch (action) {
      'CREATED' => (Icons.add_rounded, FigBrand.amber, 'Ticket créé'),
      'STATUS_CHANGED' => (
          Icons.sync_rounded,
          FigAccent.blue,
          (item['fromStatus'] ?? '').toString().isEmpty
              ? 'Statut : ${ticketStage(item['toStatus']).label}'
              : '${ticketStage(item['fromStatus']).label} → '
                  '${ticketStage(item['toStatus']).label}'
        ),
      'ASSIGNED' => (
          Icons.engineering_rounded,
          FigAccent.violet,
          'Intervenant désigné'
        ),
      'INFO_MESSAGE' => (
          Icons.campaign_rounded,
          FigBrand.amber,
          'Information publiée'
        ),
      'ATTACHMENT_ADDED' => (
          Icons.attach_file_rounded,
          FigAccent.purple,
          'Pièce jointe ajoutée'
        ),
      _ => (Icons.circle, FigNeutral.n40, action),
    };
    final name = (item['actorName'] ?? '').toString();
    final actor = name.isNotEmpty
        ? name
        : switch ((item['actorRole'] ?? '').toString()) {
            'RESIDENT' => 'Résident',
            'INTERVENANT' => 'Intervenant',
            '' => '',
            _ => 'Administration',
          };
    final note = (item['note'] ?? '').toString();
    final d =
        DateTime.tryParse((item['createdAt'] ?? '').toString())?.toLocal();

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 30,
            child: Column(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon,
                      size: icon == Icons.circle ? 8 : 15, color: accent),
                ),
                if (!last)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: c.textFaint.withValues(alpha: 0.25),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: FigSpace.lg),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 5, bottom: last ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: FigText.fieldLabel.copyWith(
                          fontWeight: FontWeight.w600, color: c.textBody)),
                  const SizedBox(height: 3),
                  Text(
                      [
                        if (d != null)
                          DateFormat('dd/MM/yyyy · HH:mm').format(d),
                        if (actor.isNotEmpty) actor,
                      ].join('  ·  '),
                      style: FigText.label.copyWith(color: c.textFaint)),
                  if (note.isNotEmpty) ...[
                    const SizedBox(height: FigSpace.md),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: c.fieldBg,
                        borderRadius: BorderRadius.circular(FigRadius.field),
                      ),
                      child: Text(note,
                          style: FigText.body
                              .copyWith(height: 1.4, color: c.textBody)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _initials(String name) => name
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .take(2)
      .map((w) => w[0].toUpperCase())
      .join();
}

/// Visionneuse plein ecran, avec zoom.
class _ImageViewer extends StatelessWidget {
  final String url;
  const _ImageViewer({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 5,
              child: Center(
                child: Image.network(url,
                    loadingBuilder: giImageLoading,
                    fit: BoxFit.contain,
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
              child: Padding(
                padding: const EdgeInsets.all(FigSpace.lg),
                child: AdminSquareButton(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close_rounded,
                      size: 20, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
