// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/api_service.dart';
import '../l10n/l10n.dart';
import '../services/file_opener.dart';
import '../theme/app_theme.dart';

/// "Documents" space: the generic documents the administration published for
/// residents (règlement, guides, notices...). Read-only.
class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final ApiService _api = ApiService();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _documents = [];
  String _category = 'ALL';
  String _query = '';
  String? _openingId;

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
      setState(() => _documents =
          list.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList());
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(Map<String, dynamic> doc) async {
    final id = doc['id'].toString();
    if (_openingId != null) return;
    setState(() => _openingId = id);
    try {
      final bytes = await _api.downloadResidentDocument(id);
      final type = (doc['type'] ?? '').toString().toLowerCase();
      var name = (doc['name'] ?? 'document').toString();
      if (type.isNotEmpty && !name.toLowerCase().endsWith('.$type')) {
        name = '$name.$type';
      }
      await FileOpener.openBytes(bytes, name);
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg.tr)));
      }
    } finally {
      if (mounted) setState(() => _openingId = null);
    }
  }

  IconData _iconFor(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      case 'doc':
      case 'docx':
        return Icons.description_outlined;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart_outlined;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'webp':
        return Icons.image_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  Color _colorFor(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return const Color(0xFFDC2626);
      case 'doc':
      case 'docx':
        return const Color(0xFF3B82F6);
      case 'xls':
      case 'xlsx':
        return const Color(0xFF16A34A);
      default:
        return brandAmber;
    }
  }

  String _date(dynamic raw) {
    final d = DateTime.tryParse((raw ?? '').toString())?.toLocal();
    return d == null ? '' : DateFormat('dd/MM/yyyy').format(d);
  }

  List<String> get _categories {
    final set = <String>{};
    for (final d in _documents) {
      final c = (d['category'] ?? '').toString();
      if (c.isNotEmpty) set.add(c);
    }
    return set.toList()..sort();
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _query.trim().toLowerCase();
    return _documents.where((d) {
      if (_category != 'ALL' && (d['category'] ?? '').toString() != _category) {
        return false;
      }
      if (q.isEmpty) return true;
      return (d['name'] ?? '').toString().toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? Colors.white : brandNavy;
    final muted = dark ? darkMuted : const Color(0xFF6B7280);
    final docs = _filtered;

    return Scaffold(
      backgroundColor: dark ? darkSurface : brandCream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                        color: dark ? darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(12)),
                    child: IconButton(
                        icon: Icon(Icons.arrow_back_rounded, color: fg),
                        onPressed: () => Navigator.pop(context)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Documents'.tr,
                            style: TextStyle(
                                color: fg,
                                fontWeight: FontWeight.w800,
                                fontSize: 20)),
                        Text('Documents mis à disposition par l\'administration'.tr,
                            style: TextStyle(color: muted, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (!_loading && _error == null && _documents.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: TextField(
                  onChanged: (v) => setState(() => _query = v),
                  style: TextStyle(color: fg),
                  decoration: InputDecoration(
                    hintText: 'Rechercher un document'.tr,
                    prefixIcon: Icon(Icons.search_rounded, color: muted),
                  ),
                ),
              ),
              SizedBox(
                height: 52,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
                  children: [
                    _chip('Tous'.tr, 'ALL', dark, fg),
                    for (final c in _categories) _chip(c.tr, c, dark, fg),
                  ],
                ),
              ),
            ],
            Expanded(child: _body(docs, dark, fg, muted)),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, String value, bool dark, Color fg) {
    final active = _category == value;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: GestureDetector(
        onTap: () => setState(() => _category = value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: active
                ? (dark ? brandAmber : brandNavy)
                : (dark ? darkCard : Colors.white),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(label,
              style: TextStyle(
                  color: active ? (dark ? brandNavy : Colors.white) : fg,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
        ),
      ),
    );
  }

  Widget _body(List<Map<String, dynamic>> docs, bool dark, Color fg, Color muted) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.cloud_off_rounded, color: muted, size: 40),
            const SizedBox(height: 12),
            Text(_error!.tr,
                textAlign: TextAlign.center, style: TextStyle(color: muted)),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _load, child: Text('Réessayer'.tr)),
          ]),
        ),
      );
    }
    if (docs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.folder_open_rounded, color: muted, size: 48),
            const SizedBox(height: 12),
            Text(
                _documents.isEmpty
                    ? 'Aucun document disponible pour le moment.'.tr
                    : 'Aucun document ne correspond à votre recherche.'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(color: muted, fontSize: 14)),
          ]),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: docs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final d = docs[i];
          final type = (d['type'] ?? '').toString();
          final color = _colorFor(type);
          final opening = _openingId == d['id'].toString();
          final residence = (d['residenceName'] ?? '').toString();
          final meta = [
            (d['category'] ?? '').toString().tr,
            (d['size'] ?? '').toString(),
            _date(d['createdAt']),
          ].where((s) => s.isNotEmpty).join(' · ');

          return GestureDetector(
            onTap: () => _open(d),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: dark ? darkCard : Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14)),
                  alignment: Alignment.center,
                  child: Icon(_iconFor(type), color: color, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text((d['name'] ?? '').toString(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: fg,
                              fontWeight: FontWeight.w800,
                              fontSize: 14)),
                      const SizedBox(height: 3),
                      Text(meta, style: TextStyle(color: muted, fontSize: 12)),
                      if (residence.isNotEmpty)
                        Text(residence,
                            style: TextStyle(color: muted, fontSize: 11)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                opening
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.download_rounded, color: brandAmber),
              ]),
            ),
          );
        },
      ),
    );
  }
}
