import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/api_service.dart';
import '../../theme/design_tokens.dart';
import '../../theme/gi_colors.dart';
import '../../widgets/gi_appear.dart';
import '../../widgets/gi_card.dart';
import '../../widgets/gi_refresh.dart';
import '../../widgets/gi_scroll_blur.dart';
import '../../widgets/gi_skeleton.dart';
import 'admin_sheet.dart';
import 'admin_ui.dart';

/// Etat d'une demande — inscription ou ajout de bien.
(String, Color) adminRequestStatus(dynamic status) =>
    switch ((status ?? '').toString()) {
      'PENDING' => ('En attente', FigBrand.amber),
      'APPROVED' => ('Validée', FigAlert.success),
      'REJECTED' => ('Rejetée', FigAlert.error),
      final s => (s.isEmpty ? '—' : s, const Color(0xFF8E8E93)),
    };

/// « Bloc B · Étage 3 · Porte 12 », sans les morceaux absents.
String adminUnitLine(Map r) {
  String v(String k) => (r[k] ?? '').toString().trim();
  final door = v('door').isEmpty ? v('doorNumber') : v('door');
  return [
    if (v('block').isNotEmpty) 'Bloc ${v('block')}',
    if (v('floor').isNotEmpty) 'Étage ${v('floor')}',
    if (door.isNotEmpty) 'Porte $door',
  ].join(' · ');
}

String adminRequestDate(dynamic value) {
  final d = DateTime.tryParse((value ?? '').toString());
  return d == null ? '' : DateFormat('dd/MM/yyyy · HH:mm').format(d.toLocal());
}

/// Carte d'une demande a traiter : qui, ou, quand, puis Rejeter / Valider
/// tant qu'elle attend.
class AdminRequestCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final dynamic status;
  final List<(IconData, String)> details;
  final String? note;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  /// Demande en cours d'envoi : les boutons laissent place a une attente.
  final bool busy;

  const AdminRequestCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.status,
    required this.details,
    this.note,
    this.onApprove,
    this.onReject,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    final s = adminRequestStatus(status);
    final pending = (status ?? '').toString() == 'PENDING';

    return GiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: s.$2.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 21, color: s.$2),
              ),
              const SizedBox(width: FigSpace.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: FigText.fieldLabel.copyWith(
                            fontWeight: FontWeight.w600, color: c.textBody)),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: FigText.label.copyWith(color: c.textMuted)),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: FigSpace.md),
              AdminPill(s.$1, s.$2, icon: Icons.circle, dense: true),
            ],
          ),
          if (details.isNotEmpty) ...[
            const SizedBox(height: FigSpace.lg),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: c.fieldBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < details.length; i++) ...[
                    if (i > 0) const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(details[i].$1, size: 16, color: c.textMuted),
                        const SizedBox(width: FigSpace.md),
                        Expanded(
                          child: Text(details[i].$2,
                              style: FigText.body.copyWith(color: c.textBody)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (note != null && note!.trim().isNotEmpty) ...[
            const SizedBox(height: FigSpace.md),
            Text('« ${note!.trim()} »',
                style: FigText.body.copyWith(
                    fontStyle: FontStyle.italic, color: c.textMuted)),
          ],
          if (pending && busy) ...[
            const SizedBox(height: FigSpace.lg),
            const SizedBox(
              height: 46,
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: FigBrand.amber),
                ),
              ),
            ),
          ] else if (pending && (onApprove != null || onReject != null)) ...[
            const SizedBox(height: FigSpace.lg),
            Row(
              children: [
                Expanded(
                  child: AdminGhostButton(
                      label: 'Rejeter',
                      icon: Icons.close_rounded,
                      color: FigAlert.error,
                      onTap: onReject),
                ),
                const SizedBox(width: FigSpace.md),
                Expanded(
                  child: AdminSolidButton(
                      label: 'Valider',
                      icon: Icons.check_rounded,
                      color: FigAlert.success,
                      foreground: Colors.white,
                      onTap: onApprove),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Page de demandes a traiter : inscriptions, ajouts de biens.
///
/// Les demandes en attente d'abord, les autres a une puce de la ; chacune
/// se valide ou se rejette depuis sa carte, le rejet demandant un motif
/// quand le serveur sait le garder.
class AdminRequestsPage extends StatefulWidget {
  final String title;
  final IconData icon;
  final String emptyTitle;
  final String emptyMessage;
  final Future<List<dynamic>> Function() load;
  final Future<void> Function(Map<String, dynamic> r) approve;
  final Future<void> Function(Map<String, dynamic> r, String reason) reject;
  final bool askReason;
  final String Function(Map<String, dynamic> r) titleOf;
  final String Function(Map<String, dynamic> r) subtitleOf;
  final List<(IconData, String)> Function(
      Map<String, dynamic> r, Map<String, String> residences) detailsOf;
  final String? Function(Map<String, dynamic> r)? noteOf;

  const AdminRequestsPage({
    super.key,
    required this.title,
    required this.icon,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.load,
    required this.approve,
    required this.reject,
    required this.titleOf,
    required this.subtitleOf,
    required this.detailsOf,
    this.noteOf,
    this.askReason = false,
  });

  @override
  State<AdminRequestsPage> createState() => _AdminRequestsPageState();
}

class _AdminRequestsPageState extends State<AdminRequestsPage> {
  final _search = TextEditingController();
  List<Map<String, dynamic>> _items = [];
  Map<String, String> _residences = const {};
  bool _loading = true;
  String _error = '';
  String _status = 'PENDING';
  String _query = '';

  // Demandes en cours d'envoi : un second appui sur « Valider » pendant
  // l'attente envoyait la meme decision deux fois.
  final Set<String> _busy = {};

  @override
  void initState() {
    super.initState();
    _search.addListener(() {
      final q = _search.text.trim().toLowerCase();
      if (q != _query) setState(() => _query = q);
    });
    _loadResidences();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  // Les demandes ne portent que l'identifiant de la residence : on lui
  // rend son nom.
  Future<void> _loadResidences() async {
    try {
      final list = await ApiService().getResidences();
      if (!mounted) return;
      setState(() => _residences = {
            for (final r in list.whereType<Map>())
              (r['id'] ?? '').toString(): (r['name'] ?? '').toString(),
          });
    } catch (_) {}
  }

  Future<void> _load() async {
    try {
      final data = await widget.load();
      if (!mounted) return;
      setState(() {
        _items = data
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
          ..sort((a, b) => (b['createdAt'] ?? '')
              .toString()
              .compareTo((a['createdAt'] ?? '').toString()));
        _error = '';
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _setLocal(Map r, String status) => setState(() {
        for (final i in _items) {
          if (i['id'] == r['id']) i['status'] = status;
        }
      });

  Future<void> _approve(Map<String, dynamic> r) async {
    final id = '${r['id']}';
    if (_busy.contains(id)) return;
    final ok = await adminConfirm(
      context,
      title: 'Valider la demande ?',
      message: '${widget.titleOf(r)} recevra l\'accès correspondant.',
      confirmLabel: 'Valider',
    );
    if (ok == null || !mounted) return;
    setState(() => _busy.add(id));
    try {
      await widget.approve(r);
      if (!mounted) return;
      _setLocal(r, 'APPROVED');
      showAdminToast(context, 'Demande validée');
    } catch (e) {
      if (mounted) {
        showAdminToast(context, e.toString().replaceAll('Exception: ', ''),
            error: true);
      }
    } finally {
      if (mounted) setState(() => _busy.remove(id));
    }
  }

  Future<void> _reject(Map<String, dynamic> r) async {
    final id = '${r['id']}';
    if (_busy.contains(id)) return;
    final reason = await adminConfirm(
      context,
      title: 'Rejeter la demande ?',
      message: 'La demande de ${widget.titleOf(r)} sera refusée.',
      confirmLabel: 'Rejeter',
      destructive: true,
      reasonHint: widget.askReason ? 'Facultatif — visible du demandeur' : null,
    );
    if (reason == null || !mounted) return;
    setState(() => _busy.add(id));
    try {
      await widget.reject(r, reason);
      if (!mounted) return;
      _setLocal(r, 'REJECTED');
      showAdminToast(context, 'Demande rejetée');
    } catch (e) {
      if (mounted) {
        showAdminToast(context, e.toString().replaceAll('Exception: ', ''),
            error: true);
      }
    } finally {
      if (mounted) setState(() => _busy.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    final top = MediaQuery.paddingOf(context).top > 0 ? 14.0 : 24.0;
    final q = _query;
    final searched = _items.where((r) {
      if (q.isEmpty) return true;
      final text = [
        widget.titleOf(r),
        widget.subtitleOf(r),
        for (final d in widget.detailsOf(r, _residences)) d.$2,
      ].join(' ').toLowerCase();
      return text.contains(q);
    }).toList();
    int count(String s) =>
        searched.where((r) => s.isEmpty || r['status'] == s).length;
    final list = searched
        .where((r) => _status.isEmpty || r['status'] == _status)
        .toList();
    final pending = _items.where((r) => r['status'] == 'PENDING').length;

    return Scaffold(
      backgroundColor: c.scaffold,
      body: GiScrollBlur(
        child: CustomScrollView(
          clipBehavior: Clip.none,
          physics: giRefreshPhysics,
          slivers: [
            GiRefreshControl(onRefresh: _load),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(FigSpace.pagePadding, top,
                  FigSpace.pagePadding, MediaQuery.paddingOf(context).bottom + 40),
              sliver: SliverToBoxAdapter(
                child: AdminContent(
                  maxWidth: 820,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AdminPageHeader(
                        back: true,
                        title: widget.title,
                        subtitle: _loading
                            ? 'Chargement…'
                            : (pending == 0
                                ? 'Aucune demande en attente'
                                : '$pending en attente'),
                      ),
                      const SizedBox(height: FigSpace.xl),
                      AdminSearchField(
                          controller: _search, hint: 'Nom, e-mail, résidence…'),
                      const SizedBox(height: FigSpace.lg),
                      SizedBox(
                        height: 34,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none,
                          physics: const BouncingScrollPhysics(),
                          children: [
                            for (final s in const [
                              'PENDING',
                              'APPROVED',
                              'REJECTED',
                              ''
                            ]) ...[
                              if (s != 'PENDING') const SizedBox(width: 8),
                              AdminFilterChip(
                                label: s.isEmpty
                                    ? 'Toutes'
                                    : adminRequestStatus(s).$1,
                                dot: s.isEmpty
                                    ? null
                                    : adminRequestStatus(s).$2,
                                count: count(s),
                                selected: _status == s,
                                onTap: () => setState(() => _status = s),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: FigSpace.xl),
                      if (_loading)
                        const GiSkeletonList(
                            padding: EdgeInsets.zero, itemHeight: 150)
                      else if (_error.isNotEmpty)
                        GiCard(
                          child: AdminLoadError(
                              message: _error,
                              onRetry: () {
                                setState(() => _loading = true);
                                _load();
                              }),
                        )
                      else if (list.isEmpty)
                        GiCard(
                          child: AdminEmpty(
                            icon: _status == 'PENDING'
                                ? Icons.task_alt_rounded
                                : widget.icon,
                            title: _status == 'PENDING'
                                ? widget.emptyTitle
                                : 'Aucune demande',
                            message: _status == 'PENDING'
                                ? widget.emptyMessage
                                : 'Aucune demande ne correspond à ces filtres.',
                          ),
                        )
                      else
                        for (var i = 0; i < list.length; i++) ...[
                          if (i > 0) const SizedBox(height: FigSpace.lg),
                          GiAppear(
                            key: ValueKey('${list[i]['id']}'),
                            index: i.clamp(0, 8),
                            child: AdminRequestCard(
                              busy: _busy.contains('${list[i]['id']}'),
                              title: widget.titleOf(list[i]),
                              subtitle: widget.subtitleOf(list[i]),
                              icon: widget.icon,
                              status: list[i]['status'],
                              details: widget.detailsOf(list[i], _residences),
                              note: widget.noteOf?.call(list[i]),
                              onApprove: () => _approve(list[i]),
                              onReject: () => _reject(list[i]),
                            ),
                          ),
                        ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
