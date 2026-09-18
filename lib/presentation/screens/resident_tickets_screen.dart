// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../l10n/app_localizations.dart';
import '../theme/design_tokens.dart';
import '../theme/gi_colors.dart';
import '../widgets/gi_card.dart';
import '../widgets/gi_empty_state.dart';
import '../widgets/gi_header.dart';
import '../widgets/gi_pressable.dart';
import '../widgets/gi_primary_button.dart';
import 'package:provider/provider.dart';
// `intl` exporte aussi un type TextDirection qui masque celui de Flutter.
import 'package:intl/intl.dart' hide TextDirection;
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../../data/api_service.dart';
import 'resident_create_ticket_screen.dart';
import 'chat_screen.dart';

class ResidentTicketsScreen extends StatefulWidget {
  const ResidentTicketsScreen({super.key});

  @override
  State<ResidentTicketsScreen> createState() => _ResidentTicketsScreenState();
}

class _ResidentTicketsScreenState extends State<ResidentTicketsScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();

  late final TabController _tabController;
  bool _loading = true;
  String _filter = 'all';

  List<dynamic> _myTickets = [];
  List<dynamic> _coproTickets = [];
  String? _residenceId;
  Map<String, dynamic>? _property;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _bootstrap();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _fmt(dynamic v) {
    try {
      if (v == null) return '';
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(v.toString()).toLocal());
    } catch (_) {
      return v?.toString() ?? '';
    }
  }

  String _fmtDateTime(dynamic v) {
    try {
      if (v == null) return '';
      return DateFormat('dd/MM/yyyy · HH:mm').format(DateTime.parse(v.toString()).toLocal());
    } catch (_) {
      return v?.toString() ?? '';
    }
  }

  String _ticketTitle(dynamic ticket) {
    final raw = (ticket is Map ? ticket['title'] : '').toString();
    switch (raw) {
      case 'Peinture écaillée':
      case 'Peinture escaliers':
        return 'Peinture Escalier';
      default:
        return raw;
    }
  }

  String _ref(dynamic ticket) {
    final id = (ticket is Map ? ticket['id'] : '').toString();
    if (id.isEmpty) return '';
    final tail = id.length > 6 ? id.substring(id.length - 6) : id;
    return '#${tail.toUpperCase()}';
  }

  Future<void> _bootstrap() async {
    try {
      final user = context.read<AuthProvider>().user;
      final email = (user?['email'] ?? '').toString();
      if (email.isNotEmpty) {
        final props = await _api.getMyProperties(email);
        if (props.isNotEmpty && props.first is Map) {
          _property = Map<String, dynamic>.from(props.first as Map);
          _residenceId = (_property!['residenceId'] ?? '').toString();
        }
      }
      await Future.wait([_fetchMy(), _fetchCopro()]);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _fetchMy() async {
    final list = await _api.getTickets();
    list.sort((a, b) => (b is Map ? b['createdAt'] : '').toString()
        .compareTo((a is Map ? a['createdAt'] : '').toString()));
    if (mounted) setState(() => _myTickets = list);
  }

  Future<void> _fetchCopro() async {
    if (_residenceId == null || _residenceId!.isEmpty) {
      if (mounted) setState(() => _coproTickets = []);
      return;
    }
    final list = await _api.getTickets(scope: 'residence', residenceId: _residenceId);
    list.sort((a, b) => (b is Map ? b['createdAt'] : '').toString()
        .compareTo((a is Map ? a['createdAt'] : '').toString()));
    if (mounted) setState(() => _coproTickets = list);
  }

  Future<void> _createNew() async {
    if (_property == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Aucun bien associé à votre compte.')));
      return;
    }
    final created = await Navigator.push<bool>(context,
        MaterialPageRoute(builder: (_) => ResidentCreateTicketScreen(property: _property!)));
    if (created == true) await _fetchMy();
  }

  // ─── Status helpers ───────────────────────────────────────
  Color _statusColor(String? s) {
    switch (s) {
      case 'Signalé':  return const Color(0xFFF59E0B);
      case 'En cours': return const Color(0xFF3B82F6);
      case 'Terminé':  return const Color(0xFF16A34A);
      case 'SAV':      return const Color(0xFF8B5CF6);
      case 'Rejeté':   return const Color(0xFFDC2626);
      default:         return const Color(0xFF94A3B8);
    }
  }

  bool _matchesFilter(Map t) {
    final status = (t['status'] ?? '').toString();
    if (_filter == 'progress') return status != 'Terminé';
    if (_filter == 'done') return status == 'Terminé';
    return true;
  }

  void _openDetails(dynamic ticket) {
    if (ticket is! Map) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => _ReportDetailScreen(
        ticket: Map<String, dynamic>.from(ticket),
        statusColor: _statusColor((ticket['status'] ?? '').toString()),
        ref: _ref(ticket),
        title: _ticketTitle(ticket),
        dateLabel: _fmt(ticket['createdAt']),
        dateTimeLabel: _fmtDateTime(ticket['createdAt']),
      ),
    ));
  }

  // ─── List builder ─────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    final t = AppL10n.of(context);

    return Scaffold(
      backgroundColor: c.scaffold,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // En-tete du Figma : pastille 35, titre 18, sous-titre 13, et le
            // bouton rond d'ajout a l'oppose.
            Padding(
              padding: EdgeInsets.fromLTRB(
                  FigSpace.pagePadding,
                  MediaQuery.paddingOf(context).top > 0 ? 22 : 32,
                  FigSpace.pagePadding,
                  0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: GiScreenHeader(
                      iconAsset: 'assets/figma/icons/alert_20.svg',
                      accent: FigAccent.amber,
                      title: t.reports,
                      subtitle: t.reportsSubtitle,
                    ),
                  ),
                  const SizedBox(width: FigSpace.lg),
                  GiPressable(
                    pressedScale: 0.88,
                    onTap: _createNew,
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: FigBrand.amber,
                        shape: BoxShape.circle,
                      ),
                      child: SvgPicture.asset(
                        'assets/figma/icons/plus_16.svg',
                        colorFilter: const ColorFilter.mode(
                            Colors.black, BlendMode.srcIn),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            SizedBox(
              height: 28,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: FigSpace.pagePadding),
                children: [
                  GiFilterChip(
                      label: t.filterAll,
                      selected: _filter == 'all',
                      onTap: () => setState(() => _filter = 'all')),
                  const SizedBox(width: FigSpace.xs),
                  GiFilterChip(
                      label: t.filterInProgress,
                      selected: _filter == 'progress',
                      onTap: () => setState(() => _filter = 'progress')),
                  const SizedBox(width: FigSpace.xs),
                  GiFilterChip(
                      label: t.filterDone,
                      selected: _filter == 'done',
                      onTap: () => setState(() => _filter = 'done')),
                ],
              ),
            ),
            const SizedBox(height: FigSpace.lg),
            // Onglets absents du Figma, conserves : la maquette ne montre que
            // les signalements du resident, l'app distingue aussi ceux de la
            // copropriete.
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: FigSpace.pagePadding),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: c.card,
                  border: Border.all(color: c.cardBorder),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: c.navbarBg,
                    borderRadius: BorderRadius.circular(FigRadius.chip * 2),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: c.textMuted,
                  labelStyle: FigText.bodyActive,
                  unselectedLabelStyle: FigText.body,
                  tabs: [
                    Tab(text: t.tabMyReports),
                    Tab(text: t.tabCommonAreas),
                  ],
                ),
              ),
            ),
            const SizedBox(height: FigSpace.xl),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: FigBrand.amber))
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildList(c, t, _myTickets),
                        _buildList(c, t, _coproTickets),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(GiColors c, AppL10n t, List<dynamic> tickets) {
    final filtered = tickets.whereType<Map>().where(_matchesFilter).toList();
    return RefreshIndicator(
      color: FigBrand.amber,
      backgroundColor: c.card,
      onRefresh: () => Future.wait([_fetchMy(), _fetchCopro()]),
      child: filtered.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                  FigSpace.pagePadding, 24, FigSpace.pagePadding, 150),
              children: [
                GiEmptyState(
                  illustration: 'assets/figma/empty/reports.svg',
                  title: t.emptyReportsTitle,
                  message: t.emptyReportsBody,
                  action: SizedBox(
                    width: 187,
                    child: GiPrimaryButton(
                      label: t.newReport,
                      onPressed: _createNew,
                    ),
                  ),
                ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                  FigSpace.pagePadding, 0, FigSpace.pagePadding, 150),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: FigSpace.lg),
              itemBuilder: (context, i) => _reportCard(c, t, filtered[i]),
            ),
    );
  }

  /// Carte de signalement — composant "Report Card" du Figma (0:4930).
  /// Padding 16, trois blocs espaces de 16 : categorie et lien de lecture,
  /// titre et description, puis reference, date et statut.
  Widget _reportCard(GiColors c, AppL10n t, Map ticket) {
    final title = _ticketTitle(ticket);
    final status = (ticket['status'] ?? '').toString();
    final category = (ticket['category'] ?? '').toString();
    final desc = (ticket['description'] ?? '').toString();

    return GiCard(
      onTap: () => _openDetails(ticket),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (category.isNotEmpty)
                Flexible(child: _badge(category, _reportBlue)),
              const Spacer(),
              const SizedBox(width: FigSpace.md),
              Text(t.readMore,
                  style: FigText.caption.copyWith(color: c.textBody)),
              const SizedBox(width: FigSpace.xs),
              Transform.flip(
                flipX: Directionality.of(context) == TextDirection.rtl,
                child: SvgPicture.asset(
                  'assets/figma/icons/arrow_readmore.svg',
                  colorFilter:
                      ColorFilter.mode(c.textBody, BlendMode.srcIn),
                ),
              ),
            ],
          ),
          const SizedBox(height: FigSpace.xl),
          Text(title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style:
                  FigText.statValue.copyWith(height: 1.2, color: c.textBody)),
          if (desc.isNotEmpty) ...[
            const SizedBox(height: FigSpace.sm),
            Text(desc,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: FigText.body.copyWith(color: c.textMuted)),
          ],
          const SizedBox(height: FigSpace.xl),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(_ref(ticket),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              FigText.caption.copyWith(color: c.textFaint)),
                    ),
                    const SizedBox(width: FigSpace.xs),
                    Container(
                      width: 3,
                      height: 3,
                      decoration: BoxDecoration(
                          color: c.textFaint, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: FigSpace.xs),
                    Text(_fmt(ticket['createdAt']),
                        style: FigText.caption.copyWith(color: c.textFaint)),
                  ],
                ),
              ),
              const SizedBox(width: FigSpace.xl),
              _badge(_statusLabel(t, status), _statusColor(status)),
            ],
          ),
        ],
      ),
    );
  }

  /// Pastille de statut ou de categorie : fond a 5 %, trait a 10 %, texte 10.
  Widget _badge(String label, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: FigAccent.chipFill(accent),
        border: Border.all(color: FigAccent.chipBorder(accent)),
        borderRadius: BorderRadius.circular(FigRadius.pill),
      ),
      child: Text(label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: FigText.caption.copyWith(color: accent)),
    );
  }

  String _statusLabel(AppL10n t, String status) {
    final s = status.toUpperCase();
    if (s.startsWith('TERMIN') || s == 'RESOLU') return t.statusResolved;
    if (s == 'EN_COURS' || s == 'EN COURS') return t.statusInProgress;
    return t.statusOpen;
  }
}

/// Bleu des pastilles de categorie, propre aux cartes de signalement.
const _reportBlue = Color(0xFF0088FF);

// ─── Report detail ──────────────────────────────────────────────────────────
class _ReportDetailScreen extends StatelessWidget {
  final Map<String, dynamic> ticket;
  final Color statusColor;
  final String ref;
  final String title;
  final String dateLabel;
  final String dateTimeLabel;

  const _ReportDetailScreen({
    required this.ticket,
    required this.statusColor,
    required this.ref,
    required this.title,
    required this.dateLabel,
    required this.dateTimeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? Colors.white : brandNavy;
    final muted = dark ? darkMuted : const Color(0xFF6B7280);
    final status = (ticket['status'] ?? '').toString();
    final desc = (ticket['description'] ?? '').toString();
    final category = (ticket['category'] ?? '').toString();
    final priority = (ticket['priority'] ?? '').toString();
    final location = (ticket['location'] ?? '').toString();
    final rejection = (ticket['rejectionReason'] ?? '').toString();
    final attachmentUrl = (ticket['attachmentUrl'] ?? '').toString();

    return Scaffold(
      backgroundColor: dark ? darkSurface : brandCream,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Row(
              children: [
                _iconBtn(Icons.arrow_back_rounded, dark, fg, () => Navigator.pop(context)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Détail du signalement',
                          style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 18)),
                      if (dateLabel.isNotEmpty)
                        Text(dateLabel, style: TextStyle(color: muted, fontSize: 12)),
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                        child: Text(status,
                            style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                      const Spacer(),
                      if (ref.isNotEmpty) Text(ref, style: TextStyle(color: muted, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(title, style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 18)),
                  if (desc.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(desc, style: TextStyle(color: muted, fontSize: 14, height: 1.5)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(color: dark ? darkCard : Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Column(
                children: [
                  if (dateTimeLabel.isNotEmpty) _row('Signalé le', dateTimeLabel, fg, muted, dark),
                  if (category.isNotEmpty) _row('Catégorie', category, fg, muted, dark),
                  if (priority.isNotEmpty) _row('Priorité', priority, fg, muted, dark),
                  if (location.isNotEmpty) _row('Lieu', location, fg, muted, dark, last: true),
                ],
              ),
            ),
            if (attachmentUrl.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text('Pièce jointe', style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 15)),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(attachmentUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                          height: 100,
                          color: dark ? darkCard : Colors.white,
                          alignment: Alignment.center,
                          child: Icon(Icons.insert_drive_file_outlined, color: muted),
                        )),
              ),
            ],
            if (rejection.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFDC2626).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.block_rounded, color: Color(0xFFDC2626), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Motif de rejet : $rejection',
                          style: const TextStyle(
                              color: Color(0xFFDC2626), fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                label: const Text('Report Chat'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      ticketId: (ticket['id'] ?? '').toString(),
                      title: 'Report Chat',
                      subtitle: title,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, Color fg, Color muted, bool dark, {bool last = false}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          border: last
              ? null
              : Border(bottom: BorderSide(color: dark ? darkBorder : const Color(0xFFF0EBDD))),
        ),
        child: Row(
          children: [
            Text(label, style: TextStyle(color: muted, fontSize: 13)),
            const Spacer(),
            Text(value, style: TextStyle(color: fg, fontSize: 13, fontWeight: FontWeight.w700)),
          ],
        ),
      );

  Widget _iconBtn(IconData icon, bool dark, Color fg, VoidCallback onTap) => Container(
        decoration: BoxDecoration(color: dark ? darkCard : Colors.white, borderRadius: BorderRadius.circular(12)),
        child: IconButton(icon: Icon(icon, color: fg), onPressed: onTap),
      );
}
