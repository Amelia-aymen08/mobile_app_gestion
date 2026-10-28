// ignore_for_file: use_build_context_synchronously
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// `intl` exporte aussi un type TextDirection qui masque celui de Flutter.
import 'package:intl/intl.dart' hide TextDirection;
import 'package:url_launcher/url_launcher.dart';

import '../../../data/api_service.dart';
import '../../../data/person_name.dart';
import '../../theme/design_tokens.dart';
import '../../theme/gi_colors.dart';
import '../../theme/ticket_status.dart';
import '../../widgets/gi_card.dart';
import '../../widgets/gi_pressable.dart';
import '../../widgets/gi_refresh.dart';
import '../../widgets/gi_skeleton.dart';
import '../admin/admin_ui.dart';
import '../chat_screen.dart';
import 'intervenant_actions.dart';
import 'intervenant_store.dart';
import 'intervenant_ui.dart';

Future<void> openMission(
        BuildContext context, IntervenantStore store, Map ticket) =>
    adminPush(context,
        IntervenantMissionScreen(store: store, ticketId: TicketFields.id(ticket)));

/// Fiche d'une mission, pensee pour le terrain.
///
/// Dans l'ordre ou l'intervenant en a besoin : ou en est la mission, ce
/// qu'il faut faire, ou aller et qui appeler, les photos, l'historique. Le
/// geste suivant — commencer ou terminer — reste en bas de l'ecran, sous
/// le pouce, quelle que soit la position dans la page.
class IntervenantMissionScreen extends StatefulWidget {
  final IntervenantStore store;
  final String ticketId;
  const IntervenantMissionScreen(
      {super.key, required this.store, required this.ticketId});

  @override
  State<IntervenantMissionScreen> createState() =>
      _IntervenantMissionScreenState();
}

class _IntervenantMissionScreenState extends State<IntervenantMissionScreen> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _history;
  String _address = '';
  // Seule la fiche du ticket porte le numero du demandeur : la liste, qui se
  // recharge toutes les 45 secondes, ne l'a pas.
  String _phone = '';
  bool _loading = true;
  bool _addingPhotos = false;
  Timer? _tick;

  IntervenantStore get _store => widget.store;
  Map<String, dynamic> get _ticket =>
      _store.byId(widget.ticketId) ?? {'id': widget.ticketId};

  @override
  void initState() {
    super.initState();
    _load();
    // La duree « en cours depuis » avance seule.
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final residenceId = TicketFields.residenceId(_ticket);
    final results = await Future.wait<Object?>([
      _api
          .getTicket(widget.ticketId)
          .then<Object?>((v) => v)
          .catchError((_) => null),
      _api
          .getTicketHistory(widget.ticketId)
          .then<Object?>((v) => v)
          .catchError((_) => null),
      if (residenceId.isNotEmpty && _address.isEmpty)
        _api
            .getResidence(residenceId)
            .then<Object?>((v) => v)
            .catchError((_) => null),
    ]);
    if (!mounted) return;
    final fresh = results[0];
    if (fresh is Map<String, dynamic>) _store.merge(fresh);
    setState(() {
      if (fresh is Map) {
        _phone = (fresh['requesterPhone'] ?? '').toString().trim();
      }
      if (results[1] is Map<String, dynamic>) {
        _history = results[1] as Map<String, dynamic>;
      }
      if (results.length > 2 && results[2] is Map) {
        _address = ((results[2] as Map)['address'] ?? '').toString().trim();
      }
      _loading = false;
    });
  }

  // ─── Actions ──────────────────────────────────────────────

  Future<void> _act(MissionAction action) async {
    if (action == MissionAction.start) {
      await startMission(context, _store, _ticket);
    } else {
      await finishMission(context, _store, _ticket);
    }
    if (mounted) _load();
  }

  Future<void> _addPhotos() async {
    final files = _attachments;
    final picked = await pickPhotos(context,
        freeSlots: kMaxTicketFiles - files.length,
        usedBytes: files.fold<int>(
            0, (s, a) => s + ((a['size'] as num?)?.toInt() ?? 0)));
    if (picked.isEmpty || !mounted) return;
    setState(() => _addingPhotos = true);
    try {
      await _store.addPhotos(widget.ticketId, picked);
      if (mounted) {
        showAdminToast(context,
            picked.length == 1 ? 'Photo ajoutée' : '${picked.length} photos ajoutées');
      }
      _load();
    } catch (e) {
      if (mounted) {
        showAdminToast(context, e.toString().replaceFirst('Exception: ', ''),
            error: true);
      }
    } finally {
      if (mounted) setState(() => _addingPhotos = false);
    }
  }

  void _openChat() => adminPush(
        context,
        ChatScreen(
          ticketId: widget.ticketId,
          title: TicketFields.title(_ticket),
          subtitle: TicketFields.ref(_ticket),
          status: (_ticket['status'] ?? '').toString(),
        ),
      );

  Future<void> _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'\s'), ''));
    if (!await launchUrl(uri)) {
      await Clipboard.setData(ClipboardData(text: phone));
      if (mounted) showAdminToast(context, 'Numéro copié');
    }
  }

  Future<void> _directions() async {
    final query = [TicketFields.residenceName(_ticket), _address]
        .where((s) => s.isNotEmpty)
        .join(', ');
    final uri = Uri.https(
        'www.google.com', '/maps/search/', {'api': '1', 'query': query});
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      await Clipboard.setData(ClipboardData(text: query));
      if (mounted) showAdminToast(context, 'Adresse copiée');
    }
  }

  List<Map<String, dynamic>> get _attachments {
    final raw = _ticket['attachments'];
    return raw is List
        ? raw.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList()
        : <Map<String, dynamic>>[];
  }

  static bool _isImage(Map a) {
    final type = (a['type'] ?? '').toString().toLowerCase();
    if (type.startsWith('image/')) return true;
    final name = ((a['name'] ?? a['url']) ?? '').toString().toLowerCase();
    return RegExp(r'\.(jpe?g|png|webp|heic)$').hasMatch(name);
  }

  DateTime? get _startedAt =>
      DateTime.tryParse((_history?['startedAt'] ?? '').toString())?.toLocal() ??
      IntervenantStore.startedAt(_ticket);

  DateTime? get _closedAt =>
      DateTime.tryParse((_history?['closedAt'] ?? '').toString())?.toLocal();

  // ─── Build ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: _store, builder: (context, _) => _build(context));

  Widget _build(BuildContext context) {
    final c = GiColors.of(context);
    final top = MediaQuery.paddingOf(context).top > 0 ? 14.0 : 24.0;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final action = missionActionOf(_ticket);
    final busy = _store.busy.contains(widget.ticketId);

    return Scaffold(
      backgroundColor: c.scaffold,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                  FigSpace.pagePadding, top, FigSpace.pagePadding, 0),
              child: AdminPageHeader(
                back: true,
                title: 'Mission ${TicketFields.ref(_ticket)}',
                subtitle: missionPlace(_ticket),
                actions: [
                  AdminSquareButton(
                    tooltip: 'Écrire au résident',
                    onTap: _openChat,
                    child: Icon(Icons.forum_outlined,
                        size: 19, color: c.textBody),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: CustomScrollView(
                physics: giRefreshPhysics,
                slivers: [
                  GiRefreshControl(onRefresh: _load),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(FigSpace.pagePadding, 0,
                        FigSpace.pagePadding, action == null ? bottom + 32 : 24),
                    sliver: SliverList.list(children: [
                      _statusCard(c),
                      const SizedBox(height: FigSpace.lg),
                      _taskCard(c),
                      const SizedBox(height: FigSpace.lg),
                      _placeCard(c),
                      const SizedBox(height: FigSpace.lg),
                      _photosCard(c),
                      const SizedBox(height: FigSpace.lg),
                      _historyCard(c),
                    ]),
                  ),
                ],
              ),
            ),
            // Le geste suivant, toujours sous le pouce.
            AnimatedSize(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              child: action == null
                  ? const SizedBox(width: double.infinity)
                  : Container(
                      width: double.infinity,
                      padding: EdgeInsets.fromLTRB(FigSpace.pagePadding, 12,
                          FigSpace.pagePadding, bottom + 12),
                      decoration: BoxDecoration(
                        color: c.scaffold,
                        border: Border(top: BorderSide(color: c.innerBorder)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                              action == MissionAction.start
                                  ? "Sur place ? Commencez : l'administration et le résident sont prévenus."
                                  : 'Travail fini ? Ajoutez un mot et une photo, puis validez.',
                              textAlign: TextAlign.center,
                              style: FigText.label
                                  .copyWith(height: 1.35, color: c.textMuted)),
                          const SizedBox(height: 10),
                          MissionActionButton(
                            action: action,
                            busy: busy,
                            large: true,
                            onTap: () => _act(action),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Ou en est la mission, en trois etapes : confiee, en cours, terminee.
  Widget _statusCard(GiColors c) {
    final stage = IntervenantStore.stageOf(_ticket);
    final started = _startedAt;
    final closed = _closedAt;
    final fmt = DateFormat('dd/MM · HH:mm');

    final (headline, detail) = switch (stage) {
      TicketStage.open => (
          'À commencer',
          'Confiée ${timeAgoLabel(TicketFields.created(_ticket)).toLowerCase()}'
        ),
      TicketStage.inProgress || TicketStage.sav => (
          stage == TicketStage.sav ? 'En SAV' : 'En cours',
          started == null
              ? 'Intervention commencée'
              : 'Depuis ${durationLabel(DateTime.now().difference(started))} · commencée à ${DateFormat('HH:mm').format(started)}'
        ),
      TicketStage.done => (
          'Terminée',
          closed == null ? 'Mission clôturée' : 'Le ${fmt.format(closed)}'
        ),
      TicketStage.rejected => ('Annulée', "Ce ticket a été rejeté par l'administration"),
    };

    final reached = switch (stage) {
      TicketStage.open => 1,
      TicketStage.inProgress || TicketStage.sav => 2,
      _ => 3,
    };
    final accent = stage == TicketStage.rejected ? FigAlert.error : stage.color;
    final labels = ['Confiée', 'En cours', 'Terminée'];

    return GiCard(
      borderColor: accent.withValues(alpha: 0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(stage.icon, size: 24, color: accent),
              ),
              const SizedBox(width: FigSpace.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: Text(headline,
                          key: ValueKey(headline),
                          style: FigText.titleMd
                              .copyWith(fontSize: 19, color: c.textBody)),
                    ),
                    const SizedBox(height: 2),
                    Text(detail,
                        style: FigText.label.copyWith(color: c.textMuted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: FigSpace.xl),
          Row(
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0)
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 320),
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: i < reached
                            ? accent
                            : c.textFaint.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 320),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < reached ? accent : Colors.transparent,
                    border: Border.all(
                        color: i < reached
                            ? accent
                            : c.textFaint.withValues(alpha: 0.4),
                        width: 2),
                    boxShadow: i == reached - 1 && reached < 3
                        ? [
                            BoxShadow(
                                color: accent.withValues(alpha: 0.25),
                                spreadRadius: 4)
                          ]
                        : null,
                  ),
                  child: i < reached
                      ? const Icon(Icons.check_rounded,
                          size: 14, color: Colors.black)
                      : null,
                ),
              ],
            ],
          ),
          const SizedBox(height: FigSpace.md),
          Row(
            children: [
              for (var i = 0; i < 3; i++)
                Expanded(
                  child: Text(labels[i],
                      textAlign: switch (i) {
                        0 => TextAlign.start,
                        1 => TextAlign.center,
                        _ => TextAlign.end,
                      },
                      style: FigText.label.copyWith(
                          fontSize: 11,
                          fontWeight: i == reached - 1
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: i < reached ? c.textBody : c.textFaint)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Ce qu'il faut faire, avec les mots du resident.
  Widget _taskCard(GiColors c) {
    final stage = IntervenantStore.stageOf(_ticket);
    final priority = ticketPriority(_ticket['priority']);
    final category = (_ticket['category'] ?? '').toString();
    final description = (_ticket['description'] ?? '').toString().trim();

    return GiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminCategoryTile(
                  category: category, color: stage.color, size: 48),
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
                            fontSize: 18, height: 1.25, color: c.textBody)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: FigSpace.lg),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: AdminPill.priority(priority),
          ),
          const SizedBox(height: FigSpace.lg),
          Container(
            padding: const EdgeInsets.all(FigSpace.lg),
            decoration: BoxDecoration(
              color: c.fieldBg,
              borderRadius: BorderRadius.circular(FigRadius.field + 2),
            ),
            child: Text(
                description.isEmpty
                    ? "Le résident n'a pas laissé de description."
                    : description,
                style: FigText.fieldLabel.copyWith(
                    height: 1.45,
                    color: description.isEmpty ? c.textFaint : c.textBody)),
          ),
        ],
      ),
    );
  }

  /// Ou aller, et qui joindre.
  Widget _placeCard(GiColors c) {
    final residence = TicketFields.residenceName(_ticket);
    final location = (_ticket['location'] ?? '').toString().trim();
    final requester = PersonName.format(TicketFields.requester(_ticket));
    final phone = _phone;
    final place = adminPlaceLabel(residence, location, includeResidence: false);

    final rows = <Widget>[
      if (residence.isNotEmpty || _address.isNotEmpty)
        _row(
          c,
          Icons.apartment_rounded,
          residence.isNotEmpty ? 'Résidence $residence' : 'Adresse',
          _address.isNotEmpty
              ? _address
              : (_loading ? 'Chargement de l\'adresse…' : 'Adresse non renseignée'),
          button: _miniButton(c, Icons.near_me_rounded, 'Itinéraire',
              _directions),
        ),
      if (place.isNotEmpty)
        _row(c, Icons.place_outlined, 'Lieu exact', place),
      if (requester.isNotEmpty)
        _row(
          c,
          Icons.person_outline_rounded,
          'Demandeur',
          requester,
          sub: phone.isNotEmpty ? phone : null,
          button: phone.isNotEmpty
              ? _miniButton(c, Icons.call_rounded, 'Appeler', () => _call(phone))
              : _miniButton(c, Icons.forum_outlined, 'Écrire', _openChat),
        ),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();

    return GiCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Sur place', style: FigText.titleMd.copyWith(color: c.textBody)),
          const SizedBox(height: 4),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Divider(height: 1, color: c.innerBorder),
            rows[i],
          ],
        ],
      ),
    );
  }

  Widget _row(GiColors c, IconData icon, String label, String value,
      {String? sub, Widget? button}) {
    return Padding(
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
                        fontWeight: FontWeight.w500, color: c.textBody)),
                if (sub != null)
                  Text(sub,
                      style: FigText.label.copyWith(color: c.textMuted)),
              ],
            ),
          ),
          if (button != null) ...[
            const SizedBox(width: FigSpace.md),
            button,
          ],
        ],
      ),
    );
  }

  Widget _miniButton(
          GiColors c, IconData icon, String label, VoidCallback onTap) =>
      GiPressable(
        pressedScale: 0.94,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: FigBrand.amber.withValues(alpha: 0.12),
            border: Border.all(color: FigBrand.amber.withValues(alpha: 0.4)),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: FigBrand.amber),
              const SizedBox(width: 5),
              Text(label,
                  style: FigText.label.copyWith(
                      fontWeight: FontWeight.w600, color: FigBrand.amber)),
            ],
          ),
        ),
      );

  Widget _photosCard(GiColors c) {
    final files = _attachments;
    final active = IntervenantStore.stageOf(_ticket).isActive;
    final canAdd = active && files.length < kMaxTicketFiles;

    return GiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                    files.isEmpty ? 'Photos' : 'Photos (${files.length})',
                    style: FigText.titleMd.copyWith(color: c.textBody)),
              ),
              if (canAdd)
                _addingPhotos
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: FigBrand.amber))
                    : _miniButton(
                        c, Icons.add_a_photo_outlined, 'Ajouter', _addPhotos),
            ],
          ),
          const SizedBox(height: FigSpace.lg),
          if (files.isEmpty)
            Text(
                active
                    ? 'Prenez une photo avant et après : elle vaut mieux qu\'un long message.'
                    : 'Aucune photo sur cette mission.',
                style: FigText.body.copyWith(height: 1.4, color: c.textMuted))
          else
            LayoutBuilder(builder: (context, constraints) {
              const cols = 3;
              final w =
                  (constraints.maxWidth - FigSpace.md * (cols - 1)) / cols;
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
    final image = _isImage(a) && url != null;
    return GiPressable(
      pressedScale: 0.95,
      onTap: image
          ? () => Navigator.of(context).push(PageRouteBuilder(
                opaque: false,
                barrierColor: Colors.black,
                transitionDuration: const Duration(milliseconds: 260),
                pageBuilder: (_, anim, __) => FadeTransition(
                    opacity: anim, child: _PhotoViewer(url: url)),
              ))
          : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: w,
          height: w,
          child: image
              ? Image.network(url,
                  loadingBuilder: giImageLoading,
                  fit: BoxFit.cover,
                  cacheWidth:
                      (w * MediaQuery.devicePixelRatioOf(context)).round(),
                  errorBuilder: (_, __, ___) =>
                      ColoredBox(color: c.innerBorder))
              : Container(
                  color: c.fieldBg,
                  padding: const EdgeInsets.all(FigSpace.md),
                  alignment: Alignment.center,
                  child: Text((a['name'] ?? 'Fichier').toString(),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: FigText.caption.copyWith(color: c.textBody)),
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
          Text('Historique', style: FigText.titleMd.copyWith(color: c.textBody)),
          const SizedBox(height: FigSpace.xl),
          if (_loading && items.isEmpty)
            const GiShimmer(
              child: Column(children: [
                GiBone(height: 12),
                SizedBox(height: 12),
                GiBone(height: 12),
              ]),
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
    final to = ticketStage(item['toStatus']);
    final (icon, accent, label) = switch (action) {
      'CREATED' => (Icons.add_rounded, FigBrand.amber, 'Signalé par le résident'),
      'STATUS_CHANGED' => (
          to.icon,
          to.color,
          switch (to) {
            TicketStage.inProgress => 'Intervention commencée',
            TicketStage.done => 'Intervention terminée',
            TicketStage.rejected => 'Ticket rejeté',
            TicketStage.sav => 'Passé en SAV',
            TicketStage.open => 'Remis à faire',
          }
        ),
      'ASSIGNED' => (Icons.engineering_rounded, FigAccent.violet, 'Mission confiée'),
      'INFO_MESSAGE' => (Icons.campaign_rounded, FigBrand.amber, 'Information au résident'),
      'ATTACHMENT_ADDED' => (Icons.photo_outlined, FigAccent.purple, 'Photos ajoutées'),
      _ => (Icons.circle, FigNeutral.n40, action),
    };
    final note = action == 'ATTACHMENT_ADDED' || action == 'ASSIGNED'
        ? ''
        : (item['note'] ?? '').toString();
    final name = (item['actorName'] ?? '').toString();
    final d =
        DateTime.tryParse((item['createdAt'] ?? '').toString())?.toLocal();

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
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
              padding: EdgeInsets.only(top: 4, bottom: last ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: FigText.fieldLabel.copyWith(
                          fontWeight: FontWeight.w600, color: c.textBody)),
                  const SizedBox(height: 2),
                  Text(
                      [
                        if (d != null) DateFormat('dd/MM · HH:mm').format(d),
                        if (name.isNotEmpty) name,
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
}

/// Photo en plein ecran, avec zoom.
class _PhotoViewer extends StatelessWidget {
  final String url;
  const _PhotoViewer({required this.url});

  @override
  Widget build(BuildContext context) => Scaffold(
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
