import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import '../../data/api_service.dart';
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
  PlatformFile? _attachment;

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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur catégories: $e')));
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

  String _locationLabel() {
    final p = widget.property;
    final apt = _apartmentNumberFromLotNumber(p['lotNumber']);
    final block = (p['block'] ?? '').toString().trim();
    final floor = (p['floor'] ?? '').toString().trim();
    final residenceName = (p['Residence'] is Map ? (p['Residence']['name'] ?? '') : '').toString().trim();

    final parts = <String>[
      if (residenceName.isNotEmpty) residenceName,
      if (apt.isNotEmpty) 'Appartement n° $apt',
      if (block.isNotEmpty) 'Bloc $block',
      if (floor.isNotEmpty) 'Étage $floor',
    ];
    return parts.join(' • ');
  }

  Future<void> _pickAttachment() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp', 'doc', 'docx', 'xls', 'xlsx'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final picked = result.files.first;
    if (picked.bytes == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Impossible de lire le fichier sélectionné.')));
      return;
    }
    if (picked.size > 2 * 1024 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fichier trop grand (max 2 Mo).')));
      return;
    }
    final mime = _mimeTypeForFilename(picked.name);
    if (mime == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Type de fichier non supporté.')));
      return;
    }
    setState(() => _attachment = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null || _selectedSubCategory == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Choisissez une catégorie et un type de problème.')));
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

      if (_attachment != null && _attachment!.bytes != null) {
        final mime = _mimeTypeForFilename(_attachment!.name);
        if (mime != null) {
          await _api.uploadTicketAttachment(
            ticketId: created['id'].toString(),
            bytes: _attachment!.bytes!,
            filename: _attachment!.name,
            mimeType: mime,
          );
        }
      }

      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signalement envoyé.')));
    } catch (e) {
      if (mounted) {
        final raw = e.toString();
        final msg = raw.replaceFirst(RegExp(r'^Exception:\s*'), '');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg.isNotEmpty ? msg : 'Erreur')));
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
                          Text('Nouveau signalement',
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
                            Text('Bien concerné', style: TextStyle(fontWeight: FontWeight.w800, color: fg)),
                            const SizedBox(height: 6),
                            Text(
                              apt.isNotEmpty ? 'Appartement n° $apt' : (p['title'] ?? 'Appartement').toString(),
                              style: TextStyle(fontWeight: FontWeight.w700, color: fg),
                            ),
                            const SizedBox(height: 4),
                            Text(_locationLabel(), style: TextStyle(color: muted, fontSize: 12)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Catégorie ───────────────────────────
                      _label('Catégorie', fg),
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
                              child: Text(name,
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
                      _label('Type de problème', fg),
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
                              child: Text(s,
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
                      _label('Description', fg),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descController,
                        maxLines: 4,
                        maxLength: 100,
                        style: TextStyle(color: fg),
                        inputFormatters: [LengthLimitingTextInputFormatter(100)],
                        decoration: InputDecoration(
                          hintText: 'Décrivez le problème en détail...',
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
                      _label('Priorité', fg),
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
                                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                .toList(),
                            onChanged: (v) => setState(() => _priority = v ?? _priority),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // ── Pièce jointe ────────────────────────
                      GestureDetector(
                        onTap: _submitting ? null : _pickAttachment,
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
                              Text(_attachment?.name ?? 'Joindre une photo ou un document',
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
                            : const Text('Envoyer le signalement',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
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
