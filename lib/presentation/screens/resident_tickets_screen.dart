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

/// Detail d'un signalement — frame Figma "Report Details LT" (0:4827).
///
/// Trois cartes : l'etat et le contenu, les caracteristiques ligne a ligne,
/// puis la galerie de photos. Le bouton de conversation ferme l'ecran.
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
    final c = GiColors.of(context);
    final t = AppL10n.of(context);

    final status = (ticket['status'] ?? '').toString();
    final category = (ticket['category'] ?? '').toString();
    final priority = (ticket['priority'] ?? '').toString();
    final description = (ticket['description'] ?? '').toString();
    // L'API renvoie aujourd'hui une seule piece jointe, `attachmentUrl`. La
    // maquette en prevoit plusieurs. On lit donc aussi `attachments[]`, le
    // champ propose a l'equipe back-end : le jour ou il arrive, la galerie se
    // remplit sans toucher a cet ecran. En attendant, c'est la piece unique
    // qui s'affiche.
    final photos = <String>[
      ...?(ticket['attachments'] as List?)
          ?.map((e) => e is Map ? (e['url'] ?? '').toString() : e.toString())
          .where((e) => e.isNotEmpty),
      if (ticket['attachments'] == null)
        ...[(ticket['attachmentUrl'] ?? '').toString()].where((e) => e.isNotEmpty),
    ];

    return Scaffold(
      backgroundColor: c.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                  FigSpace.pagePadding,
                  MediaQuery.paddingOf(context).top > 0 ? 22 : 32,
                  FigSpace.pagePadding,
                  0),
              child: _header(context, c, t),
            ),
            const SizedBox(height: FigSpace.xxl),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    FigSpace.pagePadding, 0, FigSpace.pagePadding, 24),
                children: [
                  _contentCard(c, t, status, description),
                  const SizedBox(height: FigSpace.lg),
                  _factsCard(c, t, category, priority),
                  const SizedBox(height: FigSpace.lg),
                  _photosCard(c, t, photos),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(FigSpace.pagePadding, 0,
                  FigSpace.pagePadding, FigSpace.xxl),
              child: GiPrimaryButton(
                label: t.reportChat,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      ticketId: ticket['id'].toString(),
                      title: title,
                      subtitle: ref,
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

  Widget _header(BuildContext context, GiColors c, AppL10n t) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
              flipX: Directionality.of(context) == TextDirection.rtl,
              child: SvgPicture.asset(
                'assets/figma/icons/back_14.svg',
                colorFilter: ColorFilter.mode(c.textBody, BlendMode.srcIn),
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
              Text(t.reportDetails,
                  style:
                      FigText.titleMd.copyWith(fontSize: 18, color: c.textBody)),
              const SizedBox(height: 2),
              Text(dateLabel,
                  style: FigText.label.copyWith(color: c.textMuted)),
            ],
          ),
        ),
        const SizedBox(width: FigSpace.lg),
        // Bouton « Modifier » du Figma : pastille ambre pleine, rayon 6.
        GiPressable(
          pressedScale: 0.92,
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: FigBrand.amber,
              borderRadius: BorderRadius.circular(FigRadius.pill),
            ),
            child: Text(t.editLabel,
                style: FigText.bodyActive
                    .copyWith(fontWeight: FontWeight.w500, color: Colors.black)),
          ),
        ),
      ],
    );
  }

  Widget _contentCard(
      GiColors c, AppL10n t, String status, String description) {
    return GiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: FigAccent.chipFill(statusColor),
                  border: Border.all(color: FigAccent.chipBorder(statusColor)),
                  borderRadius: BorderRadius.circular(FigRadius.pill),
                ),
                child: Text(status,
                    style: FigText.caption.copyWith(color: statusColor)),
              ),
              const Spacer(),
              Text(ref, style: FigText.label.copyWith(color: c.textFaint)),
            ],
          ),
          const SizedBox(height: FigSpace.xl),
          Text(title,
              style:
                  FigText.statValue.copyWith(height: 1.2, color: c.textBody)),
          if (description.isNotEmpty) ...[
            const SizedBox(height: FigSpace.md),
            Text(description,
                style: FigText.body.copyWith(height: 1.4, color: c.textMuted)),
          ],
        ],
      ),
    );
  }

  /// Caracteristiques ligne a ligne, separees par un trait comme le Figma :
  /// libelle a gauche en 13, valeur a droite en 16.
  Widget _factsCard(GiColors c, AppL10n t, String category, String priority) {
    Widget row(String label, Widget value, {bool last = false}) => Container(
          padding: EdgeInsets.only(bottom: last ? 0 : FigSpace.lg),
          margin: EdgeInsets.only(bottom: last ? 0 : FigSpace.lg),
          decoration: last
              ? null
              : BoxDecoration(
                  border: Border(
                      bottom: BorderSide(color: c.innerBorder)),
                ),
          child: Row(
            children: [
              Expanded(
                child: Text(label,
                    style: FigText.body.copyWith(color: c.textMuted)),
              ),
              const SizedBox(width: FigSpace.lg),
              value,
            ],
          ),
        );

    return GiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          row(
            t.reportedOn,
            Text(dateTimeLabel,
                style: FigText.field.copyWith(color: c.textBody)),
          ),
          if (category.isNotEmpty)
            row(
              t.category,
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: FigAccent.chipFill(_reportBlue),
                    border:
                        Border.all(color: FigAccent.chipBorder(_reportBlue)),
                    borderRadius: BorderRadius.circular(FigRadius.pill),
                  ),
                  child: Text(category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: FigText.caption.copyWith(color: _reportBlue)),
                ),
              ),
            ),
          row(
            t.priorityLabel,
            Text(priority.isEmpty ? '—' : priority,
                style: FigText.field.copyWith(color: c.textBody)),
            last: true,
          ),
        ],
      ),
    );
  }

  /// Galerie : vignettes de 95,667 x 102 au rayon 8, puis la tuile d'ajout
  /// en trait discontinu.
  ///
  /// L'API ne renvoie qu'une seule piece jointe (`attachmentUrl`). La
  /// maquette en prevoit jusqu'a cinq : la grille est donc prete, elle se
  /// remplira quand le back-end servira une liste.
  Widget _photosCard(GiColors c, AppL10n t, List<String> photos) {
    return GiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.photosCount(photos.length),
              style: FigText.titleMd.copyWith(color: c.textBody)),
          const SizedBox(height: FigSpace.xl),
          LayoutBuilder(
            builder: (context, constraints) {
              // Trois colonnes avec 8 d'ecart, comme la maquette.
              final w = (constraints.maxWidth - FigSpace.md * 2) / 3;
              return Wrap(
                spacing: FigSpace.md,
                runSpacing: FigSpace.md,
                children: [
                  for (final url in photos)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(FigRadius.chip),
                      child: SizedBox(
                        width: w,
                        height: 102,
                        child: Image.network(url,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                ColoredBox(color: c.innerBorder)),
                      ),
                    ),
                  _AddPhotoTile(width: w, label: t.addMore, color: c.textBody),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Tuile d'ajout de photo : cadre en trait discontinu, icone puis libelle.
class _AddPhotoTile extends StatelessWidget {
  final double width;
  final String label;
  final Color color;

  const _AddPhotoTile({
    required this.width,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GiPressable(
      pressedScale: 0.95,
      onTap: () {},
      child: CustomPaint(
        painter: _DashedBorderPainter(
            color: color, radius: FigRadius.chip),
        child: SizedBox(
          width: width,
          height: 102,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_photo_alternate_outlined, size: 16, color: color),
              const SizedBox(height: FigSpace.sm),
              Text(label,
                  style: FigText.fieldLabel.copyWith(color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cadre en trait discontinu. Flutter n'en propose pas : Border.all ne sait
/// tracer qu'un trait plein, d'ou ce trace manuel.
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  const _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final rect = RRect.fromRectAndRadius(
        Offset.zero & size, Radius.circular(radius));
    final path = Path()..addRRect(rect);

    const dash = 4.0, gap = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = (distance + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => old.color != color;
}

