import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import '../../data/api_service.dart';
import '../l10n/l10n.dart';
import '../theme/app_theme.dart';

class ResidentCreateTicketScreen extends StatefulWidget {
  final Map<String, dynamic> property;

  const ResidentCreateTicketScreen({super.key, required this.property});

  @override
  State<ResidentCreateTicketScreen> createState() => _ResidentCreateTicketScreenState();
}

class _ResidentCreateTicketScreenState extends State<ResidentCreateTicketScreen> {
  final ApiService _api = ApiService();

  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();

  bool _loading = true;
  bool _submitting = false;

  List<Map<String, dynamic>> _categories = [];
  String? _selectedCategory;
  String? _selectedSubCategory;

  String _priority = 'Moyenne';

  /// Up to 4 files, 10 MB in total (the backend enforces the same limits).
  static const int _maxFiles = 4;
  static const int _maxTotalBytes = 10 * 1024 * 1024;
  final List<PlatformFile> _attachments = [];

  int get _attachmentsBytes => _attachments.fold(0, (sum, f) => sum + f.size);

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes o';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).round()} Ko';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} Mo';
  }

  String _apartmentNumberFromLotNumber(dynamic lotNumber) {
    final raw = (lotNumber ?? '').toString().trim();
    if (raw.isEmpty) return '';
    final parts = raw.split('-').where((p) => p.trim().isNotEmpty).toList();
    return (parts.isNotEmpty ? parts.last : raw).trim();
  }

  String? _mimeTypeForFilename(String filename) {
    final parts = filename.split('.');
    if (parts.length < 2) return null;
    final ext = parts.last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      default:
        return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _api.getMaintenanceCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _selectedCategory = _categories.isNotEmpty ? (_categories.first['category']?.toString()) : null;
        _selectedSubCategory = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur catégories : {error}'.trp({'error': e}))));
    }
  }

  List<String> get _subCategoriesForSelected {
    final cat = _selectedCategory;
    if (cat == null) return [];
    final entry = _categories.firstWhere(
      (c) => (c['category'] ?? '').toString() == cat,
      orElse: () => <String, dynamic>{},
    );
    final items = entry['items'];
    if (items is List) {
      return items.map((e) => (e ?? '').toString()).where((e) => e.trim().isNotEmpty).toList();
    }
    return [];
  }

  /// [localized] = false builds the French text saved on the ticket (data seen
  /// by the staff); true builds the one shown on screen in the current language.
  String _locationLabel({bool localized = false}) {
    String fill(String template, Map<String, String> params) {
      if (localized) return template.trp(params);
      var out = template;
      params.forEach((k, v) => out = out.replaceAll('{$k}', v));
      return out;
    }

    final p = widget.property;
    final apt = _apartmentNumberFromLotNumber(p['lotNumber']);
    final block = (p['block'] ?? '').toString().trim();
    final floor = (p['floor'] ?? '').toString().trim();
    final residenceName = (p['Residence'] is Map ? (p['Residence']['name'] ?? '') : '').toString().trim();

    final parts = <String>[
      if (residenceName.isNotEmpty) residenceName,
      if (apt.isNotEmpty) fill('Appartement n° {apt}', {'apt': apt}),
      if (block.isNotEmpty) fill('Bloc {block}', {'block': block}),
      if (floor.isNotEmpty) fill('Étage {floor}', {'floor': floor}),
    ];
    return parts.join(' • ');
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickAttachments() async {
    if (_attachments.length >= _maxFiles) {
      _snack('{max} pièces jointes maximum.'.trp({'max': _maxFiles}));
      return;
    }
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp', 'doc', 'docx', 'xls', 'xlsx'],
      allowMultiple: true,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final next = [..._attachments];
    var total = _attachmentsBytes;
    String? problem;
    for (final picked in result.files) {
      if (picked.bytes == null) {
        problem = 'Impossible de lire le fichier sélectionné.'.tr;
        continue;
      }
      if (_mimeTypeForFilename(picked.name) == null) {
        problem = 'Type de fichier non supporté.'.tr;
        continue;
      }
      if (next.length >= _maxFiles) {
        problem = '{max} pièces jointes maximum.'.trp({'max': _maxFiles});
        break;
      }
      if (total + picked.size > _maxTotalBytes) {
        problem = 'Les pièces jointes ne doivent pas dépasser 10 Mo au total.'.tr;
        continue;
      }
      next.add(picked);
      total += picked.size;
    }
    setState(() {
      _attachments
        ..clear()
        ..addAll(next);
    });
    if (problem != null) _snack(problem);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null || _selectedSubCategory == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Choisissez une catégorie et un type de problème.'.tr)));
      return;
    }

    setState(() => _submitting = true);
    try {
      final p = widget.property;
      final residenceId = (p['residenceId'] ?? '').toString().trim();
      final location = _locationLabel();

      final payload = <String, dynamic>{
        'title': _selectedSubCategory,
        'description': _descController.text.trim(),
        'priority': _priority,
        'status': 'Signalé',
        'category': _selectedCategory,
        'location': location,
        if (residenceId.isNotEmpty) 'residenceId': residenceId,
      };

      final created = await _api.createTicket(payload);

      // The ticket exists at this point: a failed upload must not lose it.
      String? uploadError;
      if (_attachments.isNotEmpty) {
        try {
          await _api.uploadTicketAttachments(
            ticketId: created['id'].toString(),
            files: [
              for (final f in _attachments)
                if (f.bytes != null && _mimeTypeForFilename(f.name) != null)
                  UploadFile(
                      bytes: f.bytes!,
                      filename: f.name,
                      mimeType: _mimeTypeForFilename(f.name)!),
            ],
          );
        } catch (e) {
          uploadError = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
        }
      }

      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(uploadError == null
              ? 'Signalement envoyé.'.tr
              : 'Signalement envoyé, mais les pièces jointes n\'ont pas pu être envoyées : {reason}'
                  .trp({'reason': uploadError.tr}))));
    } catch (e) {
      if (mounted) {
        final raw = e.toString();
        final msg = raw.replaceFirst(RegExp(r'^Exception:\s*'), '');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg.isNotEmpty ? msg.tr : 'Erreur'.tr)));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? Colors.white : brandNavy;
    final muted = dark ? darkMuted : const Color(0xFF6B7280);
    final fieldFill = dark ? darkCard : const Color(0xFFECE7DA);
    final p = widget.property;
    final apt = _apartmentNumberFromLotNumber(p['lotNumber']);

    return Scaffold(
      backgroundColor: dark ? darkSurface : brandCream,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          _backButton(context, dark, fg),
                          const SizedBox(width: 12),
                          Text('Nouveau signalement'.tr,
                              style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 20)),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── Bien concerné ──────────────────────
                      Container(
                        decoration: BoxDecoration(
                          color: dark ? darkCard : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Bien concerné'.tr, style: TextStyle(fontWeight: FontWeight.w800, color: fg)),
                            const SizedBox(height: 6),
                            Text(
                              apt.isNotEmpty ? 'Appartement n° {apt}'.trp({'apt': apt}) : (p['title'] ?? 'Appartement'.tr).toString(),
                              style: TextStyle(fontWeight: FontWeight.w700, color: fg),
                            ),
                            const SizedBox(height: 4),
                            Text(_locationLabel(localized: true), style: TextStyle(color: muted, fontSize: 12)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Catégorie ───────────────────────────
                      _label('Catégorie'.tr, fg),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _categories.map((c) {
                          final name = (c['category'] ?? '').toString();
                          final active = name == _selectedCategory;
                          return GestureDetector(
                            onTap: () => setState(() {
                              _selectedCategory = name;
                              _selectedSubCategory = null;
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: active ? brandAmber.withValues(alpha: 0.16) : fieldFill,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: active ? brandAmber : Colors.transparent, width: 1.4),
                              ),
                              child: Text(name.tr,
                                  style: TextStyle(
                                      color: active ? brandAmber : muted,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),

                      // ── Type de problème (sous-catégorie) ──
                      _label('Type de problème'.tr, fg),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _subCategoriesForSelected.map((s) {
                          final active = s == _selectedSubCategory;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedSubCategory = s),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: active ? brandAmber : fieldFill,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(s.tr,
                                  style: TextStyle(
                                      color: active ? brandNavy : muted,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // ── Description ─────────────────────────
                      _label('Description'.tr, fg),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descController,
                        maxLines: 4,
                        maxLength: 100,
                        style: TextStyle(color: fg),
                        inputFormatters: [LengthLimitingTextInputFormatter(100)],
                        decoration: InputDecoration(
                          hintText: 'Décrivez le problème en détail...'.tr,
                          hintStyle: TextStyle(color: muted.withValues(alpha: 0.7)),
                          filled: true,
                          fillColor: fieldFill,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // ── Priorité ────────────────────────────
                      _label('Priorité'.tr, fg),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(color: fieldFill, borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _priority,
                            isExpanded: true,
                            dropdownColor: dark ? darkCard : Colors.white,
                            style: TextStyle(color: fg, fontSize: 15),
                            items: const ['Basse', 'Moyenne', 'Haute', 'Urgent']
                                .map((e) => DropdownMenuItem(value: e, child: Text(e.tr)))
                                .toList(),
                            onChanged: (v) => setState(() => _priority = v ?? _priority),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // ── Pièces jointes ──────────────────────
                      Row(
                        children: [
                          _label('Pièces jointes'.tr, fg),
                          const Spacer(),
                          Text(
                              '{count}/{max} · {size} / 10 Mo'.trp({
                                'count': _attachments.length,
                                'max': _maxFiles,
                                'size': _formatBytes(_attachmentsBytes),
                              }),
                              style: TextStyle(color: muted, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      for (var i = 0; i < _attachments.length; i++)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: dark ? darkCard : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                  (_mimeTypeForFilename(_attachments[i].name) ?? '').startsWith('image/')
                                      ? Icons.image_outlined
                                      : Icons.insert_drive_file_outlined,
                                  color: brandAmber,
                                  size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_attachments[i].name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 13)),
                                    Text(_formatBytes(_attachments[i].size),
                                        style: TextStyle(color: muted, fontSize: 11)),
                                  ],
                                ),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                icon: Icon(Icons.close_rounded, color: muted, size: 20),
                                onPressed: _submitting ? null : () => setState(() => _attachments.removeAt(i)),
                              ),
                            ],
                          ),
                        ),
                      if (_attachments.length < _maxFiles)
                        GestureDetector(
                          onTap: _submitting ? null : _pickAttachments,
                          child: Container(
                            decoration: BoxDecoration(
                              color: brandAmber.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: brandAmber.withValues(alpha: 0.4), style: BorderStyle.solid),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.camera_alt_outlined, color: brandAmber, size: 20),
                                const SizedBox(width: 10),
                                Text('Joindre des photos ou des documents'.tr,
                                    style: const TextStyle(color: brandAmber, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 26),

                      ElevatedButton(
                        onPressed: _submitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brandAmber,
                          foregroundColor: brandNavy,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          minimumSize: const Size.fromHeight(54),
                          elevation: 0,
                        ),
                        child: _submitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: brandNavy, strokeWidth: 2))
                            : Text('Envoyer le signalement'.tr,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _label(String text, Color fg) =>
      Text(text, style: TextStyle(color: fg, fontSize: 13, fontWeight: FontWeight.w700));

  Widget _backButton(BuildContext context, bool dark, Color fg) => Container(
        decoration: BoxDecoration(
          color: dark ? darkCard : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: fg),
          onPressed: () => Navigator.pop(context),
        ),
      );
}
