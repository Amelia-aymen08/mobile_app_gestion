// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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

  String? _ticketSvg(String? title, String? cat) {
    switch (title) {
      case 'Peinture Escalier':
      case 'Peinture écaillée':
      case 'Peinture escaliers':
      case 'Retouches peinture couloir':
        return 'assets/icones/pbm_peinture.svg';
      case 'Rideau parking défaillant':
      case 'Demande de télécommande parking':
        return 'assets/icones/pbm_rideau.svg';
      case "Problème TAG d'accès":
      case "Demande de TAG d'accès":
        return 'assets/icones/pbm_tag.svg';
    }
    switch (cat) {
      case 'Peinture (Partie Commune)':     return 'assets/icones/pbm_peinture.svg';
      case 'Commande Télécommande Parking': return 'assets/icones/pbm_rideau.svg';
      case "Commande TAG d'accès":          return 'assets/icones/pbm_tag.svg';
      default:                              return null;
    }
  }

  IconData _categoryIcon(String? cat) {
    switch (cat) {
      case 'Plomberie (Partie Commune)': return Icons.water_drop_outlined;
      case 'Ascenseurs & Accès':         return Icons.elevator_outlined;
      case 'Hygiène & Sécurité':         return Icons.shield_outlined;
      case 'Espaces Extérieurs':         return Icons.park_outlined;
      case 'Problème Bâche à eau':       return Icons.water_outlined;
      default:                           return Icons.build_outlined;
    }
  }

  Widget _categoryWidget(String? title, String? cat, Color color, double size) {
    final svg = _ticketSvg(title, cat);
    if (svg != null) {
      return SvgPicture.asset(svg, width: size, height: size, colorFilter: ColorFilter.mode(color, BlendMode.srcIn));
    }
    return Icon(_categoryIcon(cat), color: color, size: size);
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
  Widget _buildList(List<dynamic> tickets, bool dark, Color fg, Color muted) {
    final filtered = tickets.whereType<Map>().where(_matchesFilter).toList();
    if (filtered.isEmpty) {
      return Center(
        child: Text('Aucun signalement.', style: TextStyle(color: muted, fontSize: 15)),
      );
    }
    return RefreshIndicator(
      onRefresh: () => Future.wait([_fetchMy(), _fetchCopro()]),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: filtered.length,
        itemBuilder: (context, i) {
          final t = filtered[i];
          final title = _ticketTitle(t);
          final status = (t['status'] ?? '').toString();
          final category = (t['category'] ?? '').toString();
          final desc = (t['description'] ?? '').toString();
          final date = _fmt(t['createdAt']);
          final ref = _ref(t);
          final sc = _statusColor(status);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () => _openDetails(t),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: dark ? darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (category.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(category,
                                style: const TextStyle(
                                    color: Color(0xFF3B82F6), fontSize: 11, fontWeight: FontWeight.w700)),
                          ),
                        const Spacer(),
                        const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Lire la suite',
                                style: TextStyle(color: brandAmber, fontWeight: FontWeight.w700, fontSize: 12)),
                            Icon(Icons.chevron_right_rounded, size: 16, color: brandAmber),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                              color: sc.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                          alignment: Alignment.center,
                          child: _categoryWidget(title, category, sc, 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title,
                                  style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 15)),
                              if (desc.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(desc,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: muted, fontSize: 13, height: 1.4)),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (ref.isNotEmpty)
                          Text(ref, style: TextStyle(color: muted, fontSize: 11)),
                        if (ref.isNotEmpty && date.isNotEmpty)
                          Text(' · ', style: TextStyle(color: muted, fontSize: 11)),
                        if (date.isNotEmpty)
                          Text(date, style: TextStyle(color: muted, fontSize: 11)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: sc.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: sc.withValues(alpha: 0.4)),
                          ),
                          child: Text(status, style: TextStyle(color: sc, fontSize: 11, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? Colors.white : brandNavy;
    final muted = dark ? darkMuted : const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: dark ? darkSurface : brandCream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                        color: brandAmber.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
                    alignment: Alignment.center,
                    child: const Icon(Icons.error_outline_rounded, color: brandAmber, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Signalements', style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 20)),
                        Text('Suivez vos demandes de maintenance', style: TextStyle(color: muted, fontSize: 12)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _createNew,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(color: brandAmber, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: const Icon(Icons.add_rounded, color: brandNavy, size: 26),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                          color: dark ? darkCard : Colors.white, borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.all(4),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                            color: dark ? brandAmber : brandNavy, borderRadius: BorderRadius.circular(16)),
                        dividerColor: Colors.transparent,
                        labelColor: dark ? brandNavy : Colors.white,
                        unselectedLabelColor: muted,
                        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        tabs: const [Tab(text: 'Mes signalements'), Tab(text: 'Copropriété')],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _chip('Tout', 'all', dark, fg, muted),
                  const SizedBox(width: 8),
                  _chip('En cours', 'progress', dark, fg, muted),
                  const SizedBox(width: 8),
                  _chip('Terminé', 'done', dark, fg, muted),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildList(_myTickets, dark, fg, muted),
                        _buildList(_coproTickets, dark, fg, muted),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, String value, bool dark, Color fg, Color muted) {
    final active = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
}

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
