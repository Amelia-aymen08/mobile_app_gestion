// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../data/api_service.dart';
import '../../l10n/app_localizations.dart';
import '../services/file_opener.dart';
import '../theme/design_tokens.dart';
import '../theme/gi_colors.dart';
import '../widgets/gi_alert_dialog.dart';
import '../widgets/gi_appear.dart';
import '../widgets/gi_card.dart';
import '../widgets/gi_empty_state.dart';
import '../widgets/gi_header.dart';
import '../widgets/gi_pressable.dart';

/// Documents publies par l'administration — section « Residence Documents »
/// de la frame Figma « More LT » (0:4370), ici deployee en ecran.
///
/// Une ligne par document : pastille au type de fichier, nom, puis la
/// categorie, le poids et la date. L'appui telecharge et ouvre le fichier.
class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final ApiService _api = ApiService();

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _documents = const [];
  String? _busyId;

  /// Categorie retenue. `null` = toutes.
  String? _category;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _api.getResidentDocuments();
      if (!mounted) return;
      setState(() {
        _documents = list
            .whereType<Map>()
            .map((d) => Map<String, dynamic>.from(d))
            .toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _open(Map<String, dynamic> doc) async {
    final t = AppL10n.of(context);
    final id = (doc['id'] ?? '').toString();
    if (id.isEmpty || _busyId != null) return;

    setState(() => _busyId = id);
    try {
      final bytes = await _api.downloadResidentDocument(id);
      await FileOpener.openBytes(bytes, (doc['name'] ?? 'document').toString());
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
      if (mounted) setState(() => _busyId = null);
    }
  }


  /// Categories presentes dans ce que le serveur a renvoye, dans l'ordre
  /// d'usage de la gestion ; toute categorie inconnue est ajoutee ensuite,
  /// par ordre alphabetique, plutot que d'etre perdue.
  List<String> get _categories {
    const known = ['securite', 'sav', 'administratif', 'contrats'];
    final present = _documents
        .map((d) => (d['category'] ?? '').toString().trim())
        .where((c) => c.isNotEmpty)
        .toSet();
    final ordered = <String>[];
    for (final key in known) {
      final match = present.firstWhere((c) => _normalize(c) == key,
          orElse: () => '');
      if (match.isNotEmpty) ordered.add(match);
    }
    final rest = present.where((c) => !ordered.contains(c)).toList()..sort();
    return [...ordered, ...rest];
  }

  List<Map<String, dynamic>> get _visible => _category == null
      ? _documents
      : _documents
          .where((d) => (d['category'] ?? '').toString() == _category)
          .toList();

  /// Libelle traduit d'une categorie connue. Le serveur ecrit en francais :
  /// en anglais ou en arabe, une categorie qu'on ne reconnait pas s'affiche
  /// telle quelle, ce qui vaut mieux qu'une case vide.
  String _categoryLabel(AppL10n t, String raw) => switch (_normalize(raw)) {
        'securite' => t.docCatSecurity,
        'sav' => t.docCatSav,
        'administratif' => t.docCatAdmin,
        'contrats' => t.docCatContracts,
        'autres' || 'autre' => t.docCatOther,
        _ => raw,
      };

  static String _normalize(String value) {
    const accents = {
      'à': 'a', 'â': 'a', 'ä': 'a', 'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
      'î': 'i', 'ï': 'i', 'ô': 'o', 'ö': 'o', 'ù': 'u', 'û': 'u', 'ü': 'u',
      'ç': 'c',
    };
    var out = value.trim().toLowerCase();
    accents.forEach((a, b) => out = out.replaceAll(a, b));
    return out.replaceAll(RegExp(r'[^a-z]'), '');
  }

  /// Poids lisible. Le serveur renvoie des octets.
  String _formatBytes(dynamic raw) {
    final bytes = raw is num ? raw : num.tryParse('$raw');
    if (bytes == null || bytes <= 0) return '';
    if (bytes < 1024) return '${bytes.toInt()} o';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).round()} Ko';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} Mo';
  }

  String _formatDate(dynamic raw) {
    final d = DateTime.tryParse((raw ?? '').toString())?.toLocal();
    return d == null ? '' : DateFormat('dd/MM/yyyy').format(d);
  }

  /// Le type de fichier donne sa couleur a la pastille : un coup d'oeil
  /// suffit alors a separer un reglement d'un plan ou d'une photo.
  Color _accentFor(Map<String, dynamic> doc) {
    final name = '${doc['name'] ?? ''}${doc['type'] ?? ''}'.toLowerCase();
    if (name.contains('pdf')) return FigAlert.error;
    if (name.contains('sheet') ||
        name.contains('xls') ||
        name.contains('csv')) {
      return FigAlert.success;
    }
    if (name.contains('image') ||
        name.contains('png') ||
        name.contains('jpg') ||
        name.contains('jpeg')) {
      return FigAccent.violet;
    }
    return FigAccent.blue;
  }

  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    final t = AppL10n.of(context);

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
                    child: GiScreenHeader(
                      iconAsset: 'assets/figma/icons/documents_20.svg',
                      accent: FigAccent.blue,
                      title: t.documentsTitle,
                      subtitle: t.documentsSubtitle,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Les documents arrivent classes par la gestion : securite, SAV,
            // administratif, contrats. La rangee ne montre que les
            // categories reellement presentes.
            if (_categories.length > 1) ...[
              SizedBox(
                height: 28,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: FigSpace.pagePadding),
                  children: [
                    GiFilterChip(
                      label: t.filterAll,
                      selected: _category == null,
                      onTap: () => setState(() => _category = null),
                    ),
                    for (final category in _categories) ...[
                      const SizedBox(width: FigSpace.xs),
                      GiFilterChip(
                        label: _categoryLabel(t, category),
                        selected: _category == category,
                        onTap: () => setState(() => _category = category),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: FigBrand.amber))
                  : RefreshIndicator(
                      color: FigBrand.amber,
                      backgroundColor: c.card,
                      onRefresh: _load,
                      child: _visible.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(
                                  FigSpace.pagePadding, 24,
                                  FigSpace.pagePadding, 40),
                              children: [
                                GiEmptyState(
                                  illustration:
                                      'assets/figma/empty/notices.svg',
                                  title: t.emptyDocumentsTitle,
                                  message: _error ?? t.emptyDocumentsBody,
                                ),
                              ],
                            )
                          : ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(
                                  FigSpace.pagePadding, 0,
                                  FigSpace.pagePadding, 40),
                              itemCount: _visible.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: FigSpace.lg),
                              itemBuilder: (_, i) => GiAppear(
                                index: i,
                                child: _documentCard(c, t, _visible[i]),
                              ),
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _documentCard(GiColors c, AppL10n t, Map<String, dynamic> doc) {
    final accent = _accentFor(doc);
    final busy = _busyId == (doc['id'] ?? '').toString();
    // La residence d'abord : un resident qui possede plusieurs biens doit
    // voir a laquelle se rapporte le document.
    final meta = [
      (doc['residenceName'] ?? '').toString(),
      if (_category == null) _categoryLabel(t, (doc['category'] ?? '').toString()),
      _formatBytes(doc['size']),
      _formatDate(doc['createdAt']),
    ].where((s) => s.isNotEmpty).join(' · ');

    return GiCard(
      onTap: busy ? null : () => _open(doc),
      child: Row(
        children: [
          GiIconChip(
            accent: accent,
            icon: SvgPicture.asset(
              'assets/figma/icons/documents_20.svg',
              colorFilter: ColorFilter.mode(accent, BlendMode.srcIn),
            ),
          ),
          const SizedBox(width: FigSpace.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text((doc['name'] ?? '').toString(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: FigText.statValue
                        .copyWith(height: 1.2, color: c.textBody)),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: FigSpace.xs),
                  Text(meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: FigText.caption.copyWith(color: c.textFaint)),
                ],
              ],
            ),
          ),
          const SizedBox(width: FigSpace.lg),
          if (busy)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: FigBrand.amber),
            )
          else
            const GiChevron(),
        ],
      ),
    );
  }
}
