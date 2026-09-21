// ignore_for_file: use_build_context_synchronously
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../widgets/gi_alert_dialog.dart';
import '../services/file_opener.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../l10n/app_localizations.dart';
import '../theme/design_tokens.dart';
import '../widgets/gi_appear.dart';
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
            const SizedBox(height: 20),
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
                  // Un Tab ne sait pas rogner son libelle : avec la police
                  // du systeme agrandie, « Parties communes » depassait sur
                  // un ecran de 320. FittedBox le ramene dans sa moitie.
                  tabs: [
                    Tab(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(t.tabMyReports),
                      ),
                    ),
                    Tab(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(t.tabCommonAreas),
                      ),
                    ),
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
    // Tirer pour actualiser, facon iOS : l'indicateur vit dans l'espace que
    // le geste ouvre au-dessus de la liste. Il n'existe donc que pendant le
    // geste et le chargement. Le RefreshIndicator de Material se dessinait
    // par-dessus la liste et pouvait rester fige a mi-course — l'ecran
    // s'ouvrait alors avec la fleche affichee.
    return CustomScrollView(
      physics:
          const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: () => Future.wait([_fetchMy(), _fetchCopro()]),
          builder: _refreshIndicator,
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(FigSpace.pagePadding,
              filtered.isEmpty ? 24 : 0, FigSpace.pagePadding, 150),
          sliver: filtered.isEmpty
              ? SliverToBoxAdapter(
                  child: GiEmptyState(
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
                )
              : SliverList.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: FigSpace.lg),
                  itemBuilder: (context, i) => GiAppear(
                      index: i, child: _reportCard(c, t, filtered[i])),
                ),
        ),
      ],
    );
  }

  /// Indicateur ambre : il se revele au fil du geste, puis tourne pendant
  /// le chargement.
  static Widget _refreshIndicator(
    BuildContext context,
    RefreshIndicatorMode mode,
    double pulledExtent,
    double refreshTriggerPullDistance,
    double refreshIndicatorExtent,
  ) {
    final progress =
        (pulledExtent / refreshTriggerPullDistance).clamp(0.0, 1.0);
    final Widget indicator = switch (mode) {
      RefreshIndicatorMode.inactive => const SizedBox.shrink(),
      RefreshIndicatorMode.drag => CupertinoActivityIndicator.partiallyRevealed(
          progress: progress, color: FigBrand.amber, radius: 12),
      _ => const CupertinoActivityIndicator(color: FigBrand.amber, radius: 12),
    };
    return Center(child: Opacity(opacity: progress, child: indicator));
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
                    // Flexible aussi sur la date : avec la police du systeme
                    // agrandie, reference et date ne tiennent plus cote a
                    // cote sur un petit ecran.
                    Flexible(
                      child: Text(_fmt(ticket['createdAt']),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              FigText.caption.copyWith(color: c.textFaint)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: FigSpace.xl),
              Flexible(child: _badge(_statusLabel(t, status), _statusColor(status))),
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

/// Detail d'un signalement — frame Figma « Report Details LT » (0:4827),
/// completee par ce que le back-end expose depuis septembre : pieces
/// jointes multiples, messages de l'administration et historique date.
///
/// L'ecran recharge le signalement a l'ouverture : la liste d'ou l'on vient
/// ne porte pas les pieces jointes ni l'historique.
class _ReportDetailScreen extends StatefulWidget {
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
  State<_ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<_ReportDetailScreen> {
  final ApiService _api = ApiService();

  late Map<String, dynamic> _ticket = Map<String, dynamic>.from(widget.ticket);
  Map<String, dynamic>? _historyPayload;
  List<Map<String, dynamic>> _infos = const [];
  bool _loading = true;
  bool _uploading = false;
  String? _opening;

  String get _id => (_ticket['id'] ?? '').toString();

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Les trois appels sont independants : l'echec de l'un ne doit pas
  /// masquer les autres, l'ecran reste lisible avec ce qui a repondu.
  Future<void> _load() async {
    final results = await Future.wait<Object?>([
      _api.getTicket(_id).then<Object?>((v) => v).catchError((_) => null),
      _api.getTicketHistory(_id).then<Object?>((v) => v).catchError((_) => null),
      _api.getTicketMessages(_id).then<Object?>((v) => v).catchError((_) => null),
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
      _loading = false;
    });
  }

  // ─── Pieces jointes ───────────────────────────────────────
  List<Map<String, dynamic>> get _attachments {
    final raw = _ticket['attachments'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
  }

  static bool _isImage(Map a) {
    final type = (a['type'] ?? '').toString().toLowerCase();
    if (type.startsWith('image/')) return true;
    final name = ((a['name'] ?? a['url']) ?? '').toString().toLowerCase();
    return name.endsWith('.jpg') ||
        name.endsWith('.jpeg') ||
        name.endsWith('.png') ||
        name.endsWith('.webp');
  }

  String _formatBytes(num bytes) {
    if (bytes < 1024) return '${bytes.toInt()} o';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).round()} Ko';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} Mo';
  }

  Future<void> _openAttachment(Map<String, dynamic> a) async {
    final t = AppL10n.of(context);
    final url = (a['url'] ?? '').toString();
    if (_opening != null || url.isEmpty) return;

    if (_isImage(a)) {
      final full = _api.mediaUrl(url);
      if (full != null) _showImage(full);
      return;
    }
    setState(() => _opening = (a['id'] ?? url).toString());
    try {
      final bytes = await _api.downloadPublicFile(url);
      await FileOpener.openBytes(bytes, (a['name'] ?? 'document').toString());
    } catch (e) {
      if (!mounted) return;
      final raw = e.toString().replaceFirst('Exception: ', '');
      showGiAlert<void>(
        context: context,
        title: t.errorTitle,
        message: switch (raw) {
          'noAppToOpen' => t.noAppToOpen,
          'openFailed' => t.openFailed,
          _ => raw,
        },
        closeLabel: t.close,
        primaryLabel: t.close,
      );
    } finally {
      if (mounted) setState(() => _opening = null);
    }
  }

  /// Visionneuse plein ecran, avec zoom : une photo de fuite se lit mal dans
  /// une vignette de 95.
  void _showImage(String url) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 5,
                child: Center(
                  child: Image.network(url,
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
                  child: GiPressable(
                    pressedScale: 0.88,
                    onTap: () => Navigator.pop(dialogContext),
                    child: Container(
                      width: FigSize.chipMd,
                      height: FigSize.chipMd,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(FigRadius.chip),
                      ),
                      child: SvgPicture.asset(
                        'assets/figma/icons/close_16.svg',
                        colorFilter: const ColorFilter.mode(
                            Colors.white, BlendMode.srcIn),
                      ),
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

  /// Envoi de pieces jointes : quatre au maximum, dix megaoctets en tout.
  /// Les deux limites sont aussi verifiees par le serveur ; les controler
  /// ici evite un aller-retour et dit tout de suite ce qui bloque.
  Future<void> _addAttachments() async {
    final t = AppL10n.of(context);
    final restants = 4 - _attachments.length;
    if (restants <= 0 || _uploading) return;

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
      type: FileType.any,
    );
    final picked =
        (result?.files ?? const []).where((f) => f.bytes != null).toList();
    if (picked.isEmpty) return;

    if (picked.length > restants) {
      _warn(t.attachmentTooMany);
      return;
    }
    final total = picked.fold<int>(0, (sum, f) => sum + f.bytes!.length);
    if (total > 10 * 1024 * 1024) {
      _warn(t.attachmentTooBig);
      return;
    }

    setState(() => _uploading = true);
    try {
      final files = picked
          .map((f) => UploadFile(
                bytes: f.bytes!,
                filename: f.name,
                mimeType: _mimeFor(f.extension),
              ))
          .toList();
      final added =
          await _api.uploadTicketAttachments(ticketId: _id, files: files);
      if (!mounted) return;
      setState(() {
        _ticket = {
          ..._ticket,
          'attachments': [..._attachments, ...added],
        };
        _uploading = false;
      });
      _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploading = false);
      _warn(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  static String _mimeFor(String? extension) => switch ((extension ?? '').toLowerCase()) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        'jpg' || 'jpeg' => 'image/jpeg',
        'pdf' => 'application/pdf',
        'doc' => 'application/msword',
        'docx' =>
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        _ => 'application/octet-stream',
      };

  void _warn(String message) {
    final t = AppL10n.of(context);
    showGiAlert<void>(
      context: context,
      title: t.errorTitle,
      message: message,
      closeLabel: t.close,
      primaryLabel: t.close,
    );
  }

  // ─── Libelles de l'historique ─────────────────────────────
  String _actorLabel(AppL10n t, Map item) {
    switch ((item['actorRole'] ?? '').toString()) {
      case 'RESIDENT':
        final name = (item['actorName'] ?? '').toString();
        return name.isEmpty ? t.actorYou : name;
      case 'INTERVENANT':
        return t.actorTeam;
      case '':
        return '';
      default:
        return t.actorAdmin;
    }
  }

  String _historyLabel(AppL10n t, Map item) {
    switch ((item['action'] ?? '').toString()) {
      case 'CREATED':
        return t.historyCreated;
      case 'STATUS_CHANGED':
        final from = (item['fromStatus'] ?? '').toString();
        final to = (item['toStatus'] ?? '').toString();
        if (from.isEmpty) return t.historyStatus(_statusText(t, to));
        return t.historyStatusFromTo(_statusText(t, to), _statusText(t, from));
      case 'ASSIGNED':
        return t.historyAssigned;
      case 'INFO_MESSAGE':
        return t.historyInfo;
      case 'ATTACHMENT_ADDED':
        return t.historyAttachment;
      default:
        return (item['action'] ?? '').toString();
    }
  }

  String _statusText(AppL10n t, String status) {
    final s = status.toUpperCase();
    if (s.startsWith('TERMIN') || s == 'RESOLU') return t.statusResolved;
    if (s == 'EN_COURS' || s == 'EN COURS') return t.statusInProgress;
    if (s.isEmpty) return '';
    return t.statusOpen;
  }

  String _fmtDateTime(dynamic raw) {
    final d = DateTime.tryParse((raw ?? '').toString())?.toLocal();
    return d == null ? '' : DateFormat('dd/MM/yyyy · HH:mm').format(d);
  }

  // ─── Build ────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    final t = AppL10n.of(context);

    final status = (_ticket['status'] ?? '').toString();
    final category = (_ticket['category'] ?? '').toString();
    final priority = (_ticket['priority'] ?? '').toString();
    final description = (_ticket['description'] ?? '').toString();
    final history = ((_historyPayload?['history'] as List?) ?? const [])
        .whereType<Map>()
        .toList();

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
            const SizedBox(height: 22),
            Expanded(
              child: RefreshIndicator(
                color: FigBrand.amber,
                backgroundColor: c.card,
                onRefresh: _load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                      FigSpace.pagePadding, 0, FigSpace.pagePadding, 24),
                  children: [
                    _contentCard(c, t, status, description),
                    const SizedBox(height: FigSpace.lg),
                    _pipelineCard(c, t, status),
                    const SizedBox(height: FigSpace.lg),
                    _factsCard(c, t, category, priority),
                    if (_infos.isNotEmpty) ...[
                      const SizedBox(height: FigSpace.lg),
                      _infoCard(c, t),
                    ],
                    const SizedBox(height: FigSpace.lg),
                    _attachmentsCard(c, t),
                    if (_loading || history.isNotEmpty) ...[
                      const SizedBox(height: FigSpace.lg),
                      _historyCard(c, t, history),
                    ],
                  ],
                ),
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
                      ticketId: _id,
                      title: widget.title,
                      subtitle: widget.ref,
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
              Text(widget.dateLabel,
                  style: FigText.label.copyWith(color: c.textMuted)),
            ],
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
                  color: FigAccent.chipFill(widget.statusColor),
                  border:
                      Border.all(color: FigAccent.chipBorder(widget.statusColor)),
                  borderRadius: BorderRadius.circular(FigRadius.pill),
                ),
                child: Text(_statusText(t, status),
                    style:
                        FigText.caption.copyWith(color: widget.statusColor)),
              ),
              const Spacer(),
              Text(widget.ref,
                  style: FigText.label.copyWith(color: c.textFaint)),
            ],
          ),
          const SizedBox(height: FigSpace.xl),
          Text(widget.title,
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

  /// Fil de traitement : trois jalons du serveur — depot, prise en charge,
  /// cloture. Le point est plein quand l'etape a eu lieu, et porte son
  /// horodatage ; les etapes a venir restent grises.
  Widget _pipelineCard(GiColors c, AppL10n t, String status) {
    final opened = _fmtDateTime(_ticket['createdAt']);
    final started = _fmtDateTime(_historyPayload?['startedAt']);
    final closed = _fmtDateTime(_historyPayload?['closedAt']);

    final steps = <({String label, String date, bool done})>[
      (label: t.pipelineOpened, date: opened, done: opened.isNotEmpty),
      (
        label: t.pipelineStarted,
        date: started.isEmpty ? t.pipelinePending : started,
        done: started.isNotEmpty
      ),
      (
        label: t.pipelineClosed,
        date: closed.isEmpty ? t.pipelinePending : closed,
        done: closed.isNotEmpty
      ),
    ];

    return GiCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            if (i > 0)
              // Trait de liaison, a hauteur des pastilles.
              Container(
                width: 18,
                height: 2,
                margin: const EdgeInsets.only(top: 7),
                color: steps[i].done ? FigBrand.amber : c.innerBorder,
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: steps[i].done
                          ? FigBrand.amber
                          : Colors.transparent,
                      border: Border.all(
                          color: steps[i].done
                              ? FigBrand.amber
                              : c.innerBorder,
                          width: 2),
                    ),
                    child: steps[i].done
                        ? SvgPicture.asset(
                            'assets/figma/icons/check_14.svg',
                            width: 8,
                            height: 8,
                            colorFilter: const ColorFilter.mode(
                                Colors.white, BlendMode.srcIn),
                          )
                        : null,
                  ),
                  const SizedBox(height: FigSpace.md),
                  Text(steps[i].label,
                      style: FigText.caption.copyWith(
                          color: steps[i].done ? c.textBody : c.textFaint)),
                  const SizedBox(height: 2),
                  Text(steps[i].date,
                      style: FigText.caption.copyWith(
                          fontSize: 9, height: 1.3, color: c.textFaint)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _factsCard(GiColors c, AppL10n t, String category, String priority) {
    Widget row(String label, Widget value, {bool last = false}) => Container(
          padding: EdgeInsets.only(bottom: last ? 0 : FigSpace.lg),
          margin: EdgeInsets.only(bottom: last ? 0 : FigSpace.lg),
          decoration: last
              ? null
              : BoxDecoration(
                  border: Border(bottom: BorderSide(color: c.innerBorder)),
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
            Text(widget.dateTimeLabel,
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

  /// Messages postes par l'administration sur ce signalement. Ils sont
  /// distincts de la conversation : ce sont des informations, pas des
  /// echanges, d'ou le bandeau ambre plutot qu'une bulle.
  Widget _infoCard(GiColors c, AppL10n t) {
    return GiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SvgPicture.asset(
                'assets/figma/icons/info_16.svg',
                colorFilter:
                    const ColorFilter.mode(FigBrand.amber, BlendMode.srcIn),
              ),
              const SizedBox(width: FigSpace.md),
              Text(t.ticketInfo,
                  style: FigText.titleMd.copyWith(color: c.textBody)),
            ],
          ),
          const SizedBox(height: FigSpace.xl),
          for (var i = 0; i < _infos.length; i++) ...[
            if (i > 0) const SizedBox(height: FigSpace.md),
            Container(
              padding: const EdgeInsets.all(FigSpace.lg),
              decoration: BoxDecoration(
                color: FigAccent.chipFill(FigBrand.amber),
                border:
                    Border.all(color: FigAccent.chipBorder(FigBrand.amber)),
                borderRadius: BorderRadius.circular(FigRadius.chip),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      (_infos[i]['body'] ?? _infos[i]['message'] ?? '')
                          .toString(),
                      style: FigText.fieldLabel
                          .copyWith(height: 1.4, color: c.textBody)),
                  const SizedBox(height: FigSpace.sm),
                  Text(_fmtDateTime(_infos[i]['createdAt']),
                      style: FigText.caption.copyWith(color: c.textFaint)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Galerie : vignettes au rayon 8, puis la tuile d'ajout en trait
  /// discontinu tant qu'on n'a pas atteint les quatre fichiers.
  Widget _attachmentsCard(GiColors c, AppL10n t) {
    final files = _attachments;
    return GiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.attachmentsTitle(files.length),
              style: FigText.titleMd.copyWith(color: c.textBody)),
          const SizedBox(height: FigSpace.xs),
          Text(t.attachmentsHint,
              style: FigText.caption.copyWith(color: c.textFaint)),
          const SizedBox(height: FigSpace.xl),
          LayoutBuilder(
            builder: (context, constraints) {
              // Trois colonnes avec 8 d'ecart, comme la maquette.
              final w = (constraints.maxWidth - FigSpace.md * 2) / 3;
              return Wrap(
                spacing: FigSpace.md,
                runSpacing: FigSpace.md,
                children: [
                  for (final a in files) _thumb(c, a, w),
                  if (files.length < 4)
                    _AddPhotoTile(
                      width: w,
                      label: _uploading ? '…' : t.addMore,
                      color: c.textBody,
                      onTap: _uploading ? null : _addAttachments,
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _thumb(GiColors c, Map<String, dynamic> a, double w) {
    final url = _api.mediaUrl(a['url']);
    final busy = _opening == (a['id'] ?? a['url']).toString();
    final size = a['size'];

    return GiPressable(
      pressedScale: 0.95,
      onTap: () => _openAttachment(a),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(FigRadius.chip),
        child: SizedBox(
          width: w,
          height: 102,
          child: _isImage(a) && url != null
              ? Image.network(url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => ColoredBox(color: c.innerBorder))
              : Container(
                  color: c.innerBorder,
                  padding: const EdgeInsets.all(FigSpace.md),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (busy)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: FigBrand.amber),
                        )
                      else
                        SvgPicture.asset(
                          'assets/figma/icons/documents_20.svg',
                          colorFilter:
                              ColorFilter.mode(c.textBody, BlendMode.srcIn),
                        ),
                      const SizedBox(height: FigSpace.sm),
                      Text(
                        (a['name'] ?? '').toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: FigText.caption.copyWith(color: c.textBody),
                      ),
                      if (size is num)
                        Text(_formatBytes(size),
                            style:
                                FigText.caption.copyWith(color: c.textFaint)),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  /// Historique : une ligne par evenement, reliee par un trait vertical.
  /// C'est la chronologie demandee au back-end, telle qu'il la renvoie.
  Widget _historyCard(GiColors c, AppL10n t, List<Map<dynamic, dynamic>> items) {
    return GiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.ticketHistory,
              style: FigText.titleMd.copyWith(color: c.textBody)),
          const SizedBox(height: FigSpace.xl),
          if (_loading && items.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: FigSpace.lg),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: FigBrand.amber),
                ),
              ),
            )
          else
            for (var i = 0; i < items.length; i++)
              _historyRow(c, t, items[i], last: i == items.length - 1),
        ],
      ),
    );
  }

  Widget _historyRow(GiColors c, AppL10n t, Map item, {required bool last}) {
    final actor = _actorLabel(t, item);
    final note = (item['note'] ?? '').toString();

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 9,
                height: 9,
                margin: const EdgeInsets.only(top: 5),
                decoration: const BoxDecoration(
                    color: FigBrand.amber, shape: BoxShape.circle),
              ),
              if (!last)
                Expanded(
                  child: Container(
                    width: 1,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: c.innerBorder,
                  ),
                ),
            ],
          ),
          const SizedBox(width: FigSpace.lg),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : FigSpace.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_historyLabel(t, item),
                      style: FigText.fieldLabel
                          .copyWith(height: 1.3, color: c.textBody)),
                  if (note.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(note,
                        style: FigText.body
                            .copyWith(height: 1.4, color: c.textMuted)),
                  ],
                  const SizedBox(height: FigSpace.xs),
                  Row(
                    children: [
                      Text(_fmtDateTime(item['createdAt']),
                          style:
                              FigText.caption.copyWith(color: c.textFaint)),
                      if (actor.isNotEmpty) ...[
                        const SizedBox(width: FigSpace.xs),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                              color: c.textFaint, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: FigSpace.xs),
                        Flexible(
                          child: Text(actor,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: FigText.caption
                                  .copyWith(color: c.textFaint)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
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
  final VoidCallback? onTap;

  const _AddPhotoTile({
    required this.width,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GiPressable(
      pressedScale: 0.95,
      onTap: onTap,
      child: CustomPaint(
        painter: _DashedBorderPainter(
            color: color, radius: FigRadius.chip),
        child: SizedBox(
          width: width,
          height: 102,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset('assets/figma/icons/camera_24.svg',
                  width: 16,
                  height: 16,
                  colorFilter: ColorFilter.mode(color, BlendMode.srcIn)),
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

