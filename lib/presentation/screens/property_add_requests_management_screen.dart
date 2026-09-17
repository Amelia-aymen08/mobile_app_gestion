import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/api_service.dart';
import '../theme/app_theme.dart';

class PropertyAddRequestsManagementScreen extends StatefulWidget {
  const PropertyAddRequestsManagementScreen({super.key});

  @override
  State<PropertyAddRequestsManagementScreen> createState() =>
      _PropertyAddRequestsManagementScreenState();
}

class _PropertyAddRequestsManagementScreenState
    extends State<PropertyAddRequestsManagementScreen> {
  final ApiService _api = ApiService();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _requests = [];
  String _filter = 'PENDING';

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
      final data = await _api.getPropertyAddRequests(
        status: _filter.isEmpty ? null : _filter,
      );
      if (!mounted) return;
      setState(() {
        _requests = data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
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

  String _formatDate(dynamic value) {
    if (value == null) return '';
    try {
      return DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(value.toString()).toLocal());
    } catch (_) {
      return value.toString();
    }
  }

  Future<void> _approve(Map<String, dynamic> req) async {
    final id = req['id']?.toString() ?? '';
    if (id.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Valider la demande ?'),
        content: Text(
          'Valider la demande de ${req['email'] ?? ''} pour le bien dans la résidence ${req['residenceId'] ?? ''} ?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Valider')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _api.approvePropertyAddRequest(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demande validée.')),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  Future<void> _reject(Map<String, dynamic> req) async {
    final id = req['id']?.toString() ?? '';
    if (id.isEmpty) return;
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rejeter la demande ?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Rejeter la demande de ${req['email'] ?? ''} ?'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'Motif (optionnel)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _api.rejectPropertyAddRequest(id, reason: reasonCtrl.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demande rejetée.')),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'PENDING':
        return const Color(0xFFB45309);
      case 'APPROVED':
        return const Color(0xFF15803D);
      case 'REJECTED':
        return const Color(0xFFB91C1C);
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'PENDING':
        return 'En attente';
      case 'APPROVED':
        return 'Validée';
      case 'REJECTED':
        return 'Rejetée';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demandes ajout de bien'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                _FilterChip(label: 'En attente', value: 'PENDING', current: _filter, onTap: (v) { setState(() => _filter = v); _load(); }),
                const SizedBox(width: 8),
                _FilterChip(label: 'Toutes', value: '', current: _filter, onTap: (v) { setState(() => _filter = v); _load(); }),
                const SizedBox(width: 8),
                _FilterChip(label: 'Validées', value: 'APPROVED', current: _filter, onTap: (v) { setState(() => _filter = v); _load(); }),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(color: Color(0xFFB91C1C))))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: _requests.isEmpty
                            ? const Center(child: Text('Aucune demande.', style: TextStyle(color: Color(0xFF64748B))))
                            : ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: _requests.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 10),
                                itemBuilder: (context, i) {
                                  final r = _requests[i];
                                  final status = (r['status'] ?? '').toString();
                                  final isPending = status == 'PENDING';
                                  final color = _statusColor(status);
                                  return Card(
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  (r['email'] ?? '').toString(),
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                    color: scheme.primary,
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: color.withValues(alpha: 0.12),
                                                  borderRadius: BorderRadius.circular(999),
                                                ),
                                                child: Text(
                                                  _statusLabel(status),
                                                  style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Résidence: ${r['residenceId'] ?? '-'}  •  Porte: ${r['door'] ?? '-'}${(r['block'] ?? '').toString().isNotEmpty ? '  •  Bloc: ${r['block']}' : ''}${(r['floor'] ?? '').toString().isNotEmpty ? '  •  Étage: ${r['floor']}' : ''}',
                                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                                          ),
                                          if ((r['notes'] ?? '').toString().isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              'Note: ${r['notes']}',
                                              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                                            ),
                                          ],
                                          const SizedBox(height: 4),
                                          Text(
                                            _formatDate(r['createdAt']),
                                            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                                          ),
                                          if (isPending) ...[
                                            const SizedBox(height: 12),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: OutlinedButton(
                                                    style: OutlinedButton.styleFrom(
                                                      foregroundColor: const Color(0xFFB91C1C),
                                                      side: const BorderSide(color: Color(0xFFB91C1C)),
                                                    ),
                                                    onPressed: () => _reject(r),
                                                    child: const Text('Rejeter'),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: ElevatedButton(
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: const Color(0xFF15803D),
                                                      foregroundColor: Colors.white,
                                                    ),
                                                    onPressed: () => _approve(r),
                                                    child: const Text('Valider'),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final String current;
  final void Function(String) onTap;

  const _FilterChip({required this.label, required this.value, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final active = current == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? brandBlue : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : const Color(0xFF64748B),
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
