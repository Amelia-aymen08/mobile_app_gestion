import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/api_service.dart';
import '../theme/design_tokens.dart';
import '../theme/gi_colors.dart';
import '../widgets/gi_appear.dart';
import '../widgets/gi_card.dart';
import '../widgets/gi_primary_button.dart';
import '../widgets/gi_refresh.dart';
import '../widgets/gi_scroll_blur.dart';
import '../widgets/gi_skeleton.dart';
import 'admin/admin_sheet.dart';
import 'admin/admin_ui.dart';

/// Type d'un avis : libelle, couleur et icone.
class _Kind {
  final String label;
  final Color color;
  final IconData icon;
  const _Kind(this.label, this.color, this.icon);

  static const _all = {
    'URGENT': _Kind('Urgent', FigAlert.error, Icons.priority_high_rounded),
    'INFO': _Kind('Info', FigAccent.blue, Icons.info_outline_rounded),
    'EVENT': _Kind('Événement', FigAccent.violet, Icons.event_outlined),
  };

  static _Kind of(dynamic category) =>
      _all[(category ?? 'INFO').toString()] ?? _all['INFO']!;
}

const _statuses = {
  'PUBLISHED': ('Publiée', FigAlert.success),
  'SCHEDULED': ('Planifiée', FigAccent.blue),
  'DRAFT': ('Brouillon', FigBrand.amber),
  'EXPIRED': ('Expirée', Color(0xFF8E8E93)),
};

/// Avis et annonces publies aux residents.
///
/// Un en-tete et un seul bouton pour publier, puis deux rangees de puces
/// qui defilent de cote — l'etat, puis le type — au lieu de quatre lignes
/// de cases qui poussaient la liste hors de l'ecran. Chaque avis est une
/// carte : type en pastille de couleur, titre, debut du texte, residence
/// et date.
class AdminNoticesScreen extends StatefulWidget {
  /// Onglet de la barre du bas : pas de retour, et la place de la barre
  /// sous la liste.
  final bool asTab;
  const AdminNoticesScreen({super.key, this.asTab = false});

  @override
  State<AdminNoticesScreen> createState() => _AdminNoticesScreenState();
}

class _AdminNoticesScreenState extends State<AdminNoticesScreen> {
  final _api = ApiService();
  final _search = TextEditingController();
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String _error = '';
  String _category = 'ALL';
  String _status = 'ALL';
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
    _search.addListener(() {
      final q = _search.text.trim().toLowerCase();
      if (q != _query) setState(() => _query = q);
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final items = await _api.getManagedAnnouncements();
      if (!mounted) return;
      setState(() {
        _items = items
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
          ..sort((a, b) => _dateOf(b).compareTo(_dateOf(a)));
        _error = '';
        _loading = false;
      });
    } catch (e) {
      // Sans ce message, une coupure reseau s'affichait « Aucune annonce —
      // publiez une premiere annonce ».
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  static DateTime _dateOf(Map item) =>
      DateTime.tryParse('${item['publishAt'] ?? item['createdAt'] ?? ''}') ??
      DateTime(2000);

  bool _matches(Map item, {bool ignoreStatus = false}) {
    final query = _query;
    if (_category != 'ALL' && item['category'] != _category) return false;
    if (!ignoreStatus && _status != 'ALL' && item['status'] != _status) {
      return false;
    }
    return query.isEmpty ||
        '${item['title']} ${item['residenceName']} ${item['body']}'
            .toLowerCase()
            .contains(query);
  }

  Future<void> _newNotice() async {
    final title = TextEditingController();
    final body = TextEditingController();
    var category = 'INFO';
    var publish = true;
    var sending = false;

    final created = await showAdminSheet<bool>(
      context,
      title: 'Nouvelle annonce',
      subtitle: 'Elle apparaîtra dans l\'onglet Annonces des résidents.',
      builder: (sheet) => StatefulBuilder(
        builder: (sheet, setSheet) {
          final ready =
              title.text.trim().isNotEmpty && body.text.trim().isNotEmpty;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AdminField(
                  controller: title,
                  label: 'Titre',
                  hint: 'Coupure d\'eau mardi matin',
                  onChanged: (_) => setSheet(() {})),
              const SizedBox(height: FigSpace.lg),
              AdminField(
                  controller: body,
                  label: 'Message',
                  hint: 'Ce que les résidents doivent savoir…',
                  lines: 5,
                  onChanged: (_) => setSheet(() {})),
              const SizedBox(height: FigSpace.xl),
              AdminChoice<String>(
                label: 'Type',
                options: {
                  for (final e in _Kind._all.entries) e.key: e.value.label
                },
                value: category,
                colorOf: (k) => _Kind.of(k).color,
                onChanged: (v) => setSheet(() => category = v),
              ),
              const SizedBox(height: FigSpace.xl),
              AdminChoice<bool>(
                label: 'Diffusion',
                options: const {true: 'Publier maintenant', false: 'Brouillon'},
                value: publish,
                onChanged: (v) => setSheet(() => publish = v),
              ),
              const SizedBox(height: FigSpace.xxl),
              GiPrimaryButton(
                label: publish ? 'Publier' : 'Enregistrer le brouillon',
                isLoading: sending,
                onPressed: !ready
                    ? null
                    : () async {
                        setSheet(() => sending = true);
                        try {
                          await _api.createAnnouncement({
                            'title': title.text.trim(),
                            'body': body.text.trim(),
                            'category': category,
                            'status': publish ? 'PUBLISHED' : 'DRAFT',
                          });
                          if (sheet.mounted) Navigator.pop(sheet, true);
                        } catch (e) {
                          setSheet(() => sending = false);
                          if (sheet.mounted) {
                            showAdminToast(sheet,
                                e.toString().replaceAll('Exception: ', ''),
                                error: true);
                          }
                        }
                      },
              ),
            ],
          );
        },
      ),
    );
    if (created == true && mounted) {
      showAdminToast(context, publish ? 'Annonce publiée' : 'Brouillon enregistré');
      _load();
    }
  }

  void _open(Map item) {
    final kind = _Kind.of(item['category']);
    final status = _statuses[item['status']];
    final c = GiColors.of(context);
    showAdminSheet<void>(
      context,
      title: (item['title'] ?? '').toString(),
      builder: (_) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(spacing: 8, runSpacing: 8, children: [
            AdminPill(kind.label, kind.color, icon: kind.icon, dense: true),
            if (status != null)
              AdminPill(status.$1, status.$2, icon: Icons.circle, dense: true),
          ]),
          const SizedBox(height: FigSpace.lg),
          Text(_meta(item),
              style: FigText.label.copyWith(color: c.textMuted)),
          const SizedBox(height: FigSpace.xl),
          Text((item['body'] ?? item['content'] ?? '').toString(),
              style: FigText.body
                  .copyWith(fontSize: 15, height: 1.5, color: c.textBody)),
        ],
      ),
    );
  }

  String _meta(Map item) {
    final res = (item['residenceName'] ?? '').toString().trim();
    final date =
        DateTime.tryParse('${item['publishAt'] ?? item['createdAt'] ?? ''}');
    return [
      res.isEmpty ? 'Toutes les résidences' : res,
      if (date != null) DateFormat('dd/MM/yyyy').format(date.toLocal()),
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    final top = MediaQuery.paddingOf(context).top > 0 ? 14.0 : 24.0;
    final list = _items.where(_matches).toList();
    int countStatus(String s) => _items
        .where((i) => _matches(i, ignoreStatus: true))
        .where((i) => s == 'ALL' || i['status'] == s)
        .length;
    final published = _items.where((i) => i['status'] == 'PUBLISHED').length;
    final drafts = _items.where((i) => i['status'] == 'DRAFT').length;

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
                  FigSpace.pagePadding,
                  widget.asTab ? 150 : MediaQuery.paddingOf(context).bottom + 40),
              sliver: SliverToBoxAdapter(
                child: AdminContent(
                  maxWidth: 820,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AdminPageHeader(
                        back: !widget.asTab,
                        large: widget.asTab,
                        title: 'Annonces',
                        subtitle: _loading
                            ? 'Chargement…'
                            : '$published publiée${published > 1 ? 's' : ''}'
                                '${drafts > 0 ? ' · $drafts brouillon${drafts > 1 ? 's' : ''}' : ''}',
                        actions: [
                          AdminSquareButton(
                            filled: true,
                            tooltip: 'Nouvelle annonce',
                            onTap: _newNotice,
                            child: const Icon(Icons.add_rounded,
                                size: 22, color: Colors.black),
                          ),
                        ],
                      ),
                      const SizedBox(height: FigSpace.xl),
                      AdminSearchField(
                          controller: _search,
                          hint: 'Titre, résidence, contenu…'),
                      const SizedBox(height: FigSpace.lg),
                      _chips([
                        AdminFilterChip(
                            label: 'Tous',
                            count: countStatus('ALL'),
                            selected: _status == 'ALL',
                            onTap: () => setState(() => _status = 'ALL')),
                        for (final s in _statuses.entries)
                          AdminFilterChip(
                              label: s.value.$1,
                              count: countStatus(s.key),
                              dot: s.value.$2,
                              selected: _status == s.key,
                              onTap: () => setState(() => _status = s.key)),
                      ]),
                      const SizedBox(height: FigSpace.md),
                      _chips([
                        AdminFilterChip(
                            label: 'Tous types',
                            selected: _category == 'ALL',
                            onTap: () => setState(() => _category = 'ALL')),
                        for (final k in _Kind._all.entries)
                          AdminFilterChip(
                              label: k.value.label,
                              dot: k.value.color,
                              selected: _category == k.key,
                              onTap: () => setState(() => _category = k.key)),
                      ]),
                      const SizedBox(height: FigSpace.xl),
                      if (_loading)
                        const GiSkeletonList(padding: EdgeInsets.zero)
                      else if (_error.isNotEmpty && _items.isEmpty)
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
                            icon: Icons.campaign_outlined,
                            title: _items.isEmpty
                                ? 'Aucune annonce'
                                : 'Aucun résultat',
                            message: _items.isEmpty
                                ? 'Publiez une première annonce : elle sera envoyée aux résidents.'
                                : 'Aucune annonce ne correspond à ces filtres.',
                          ),
                        )
                      else
                        for (var i = 0; i < list.length; i++) ...[
                          if (i > 0) const SizedBox(height: FigSpace.lg),
                          GiAppear(
                              index: i.clamp(0, 8), child: _card(list[i])),
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

  /// Rangee de puces qui defile de cote et deborde jusqu'aux bords.
  Widget _chips(List<Widget> chips) => SizedBox(
        height: 34,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          physics: const BouncingScrollPhysics(),
          itemCount: chips.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) => chips[i],
        ),
      );

  Widget _card(Map item) {
    final c = GiColors.of(context);
    final kind = _Kind.of(item['category']);
    final status = _statuses[item['status']];
    final body = (item['body'] ?? item['content'] ?? '').toString().trim();

    return GiCard(
      onTap: () => _open(item),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: kind.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(kind.icon, size: 21, color: kind.color),
          ),
          const SizedBox(width: FigSpace.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text((item['title'] ?? '').toString(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: FigText.fieldLabel.copyWith(
                              fontWeight: FontWeight.w600,
                              color: c.textBody)),
                    ),
                    if (status != null) ...[
                      const SizedBox(width: FigSpace.md),
                      AdminPill(status.$1, status.$2,
                          icon: Icons.circle, dense: true),
                    ],
                  ],
                ),
                if (body.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: FigText.body
                          .copyWith(height: 1.35, color: c.textMuted)),
                ],
                const SizedBox(height: FigSpace.md),
                Row(
                  children: [
                    Icon(Icons.apartment_rounded, size: 14, color: c.textFaint),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(_meta(item),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: FigText.caption
                              .copyWith(fontSize: 12, color: c.textFaint)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
