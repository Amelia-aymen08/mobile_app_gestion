// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/api_service.dart';

class RecouvrementFinancialScreen extends StatefulWidget {
  const RecouvrementFinancialScreen({super.key});

  @override
  State<RecouvrementFinancialScreen> createState() => _RecouvrementFinancialScreenState();
}

class _RecouvrementFinancialScreenState extends State<RecouvrementFinancialScreen> {
  final ApiService _api = ApiService();
  bool _loading = true;
  String _error = '';
  List<dynamic> _transactions = [];
  int _page = 1;
  final Set<String> _selectedIds = {};

  int _toIntAmount(dynamic value) {
    if (value == null) return 0;
    final n = num.tryParse(value.toString());
    if (n == null) return 0;
    return n.round();
  }

  int _periodMonths(dynamic start, dynamic end) {
    DateTime? s, e;
    try { s = DateTime.parse((start ?? '').toString()); } catch (_) {}
    try { e = DateTime.parse((end ?? '').toString()); } catch (_) {}
    if (s == null || e == null) return 1;
    final months = (e.year - s.year) * 12 + (e.month - s.month);
    return months.clamp(1, 120);
  }

  String _formatAmount(Map tx) {
    final type = (tx['type'] ?? '').toString();
    final amount = _toIntAmount(tx['amount']);
    final months = type == 'Charge' ? _periodMonths(tx['periodStart'], tx['periodEnd']) : 1;
    return '${NumberFormat.decimalPattern('fr_FR').format(amount * months)} DA';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final data = await _api.getTransactions();
      if (!mounted) return;
      setState(() {
        _transactions = data.where((t) => t is Map && (t['type']?.toString() ?? '') == 'Charge').toList();
        final totalPages = (_transactions.length / 25).ceil().clamp(1, 1 << 30);
        if (_page > totalPages) _page = totalPages;
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

  Future<void> _toggleStatus(Map<String, dynamic> tx) async {
    final id = (tx['id'] ?? '').toString();
    if (id.isEmpty) return;
    final current = (tx['status'] ?? '').toString();
    final type = (tx['type'] ?? '').toString();
    final next = type == 'Charge'
        ? (current == 'Payé' ? 'Impayé' : 'Payé')
        : (current == 'Payé' ? 'En attente' : 'Payé');

    try {
      await _api.updateTransaction(id: id, payload: { 'status': next });
      if (!mounted) return;
      setState(() {
        _transactions = _transactions.map((t) {
          if (t is Map && (t['id']?.toString() ?? '') == id) {
            return { ...Map<String, dynamic>.from(t), 'status': next };
          }
          return t;
        }).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  Future<void> _setStatus(String id, String status) async {
    if (id.isEmpty) return;
    await _api.updateTransaction(id: id, payload: { 'status': status });
    if (!mounted) return;
    setState(() {
      _transactions = _transactions.map((t) {
        if (t is Map && (t['id']?.toString() ?? '') == id) {
          return { ...Map<String, dynamic>.from(t), 'status': status };
        }
        return t;
      }).toList();
    });
  }

  Future<void> _setStatusForSelection(String status) async {
    final ids = _selectedIds.toList();
    if (ids.isEmpty) return;
    try {
      for (final id in ids) {
        await _setStatus(id, status);
      }
      if (!mounted) return;
      setState(() {
        _selectedIds.clear();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedIds.clear();
    });
  }

  Widget _buildPaginationBar() {
    final totalPages = (_transactions.length / 25).ceil().clamp(1, 1 << 30);
    final from = _transactions.isEmpty ? 0 : ((_page - 1) * 25) + 1;
    final to = (_page * 25).clamp(0, _transactions.length);
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Affichage $from-$to sur ${_transactions.length}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
          ),
          Row(
            children: [
              TextButton(
                onPressed: _page <= 1
                    ? null
                    : () => setState(() {
                          _page = (_page - 1).clamp(1, totalPages);
                        }),
                child: const Text('Précédent'),
              ),
              Text(
                '$_page/$totalPages',
                style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A), fontWeight: FontWeight.w700),
              ),
              TextButton(
                onPressed: _page >= totalPages
                    ? null
                    : () => setState(() {
                          _page = (_page + 1).clamp(1, totalPages);
                        }),
                child: const Text('Suivant'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (_transactions.length / 25).ceil().clamp(1, 1 << 30);
    final start = (_page - 1) * 25;
    final pageTransactions = _transactions.skip(start).take(25).toList();
    final selectionMode = _selectedIds.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(selectionMode ? 'Sélection (${_selectedIds.length})' : 'Suivi des paiements'),
        actions: [
          if (selectionMode) ...[
            IconButton(
              icon: const Icon(Icons.check_circle_outline),
              onPressed: () => _setStatusForSelection('Payé'),
              tooltip: 'Marquer payé',
            ),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () => _setStatusForSelection('Impayé'),
              tooltip: 'Marquer impayé',
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _clearSelection,
              tooltip: 'Annuler',
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _load,
            )
          ]
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Text(_error))
              : Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: pageTransactions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final tx = pageTransactions[index];
                    if (tx is! Map) return const SizedBox.shrink();
                    final type = (tx['type'] ?? '').toString();
                    final status = (tx['status'] ?? '').toString();
                    final amountLabel = _formatAmount(tx);
                    final desc = (tx['description'] ?? '').toString();
                    final residenceName = (tx['Residence'] is Map)
                        ? (tx['Residence']['name']?.toString() ?? '')
                        : '';
                    final id = (tx['id'] ?? '').toString();
                    final selected = id.isNotEmpty && _selectedIds.contains(id);

                    return Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          if (id.isEmpty) return;
                          if (selectionMode) {
                            _toggleSelection(id);
                          } else {
                            _toggleStatus(Map<String, dynamic>.from(tx));
                          }
                        },
                        onLongPress: () {
                          if (id.isEmpty) return;
                          _toggleSelection(id);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (selectionMode) ...[
                                Checkbox(
                                  value: selected,
                                  onChanged: id.isEmpty ? null : (_) => _toggleSelection(id),
                                ),
                                const SizedBox(width: 6),
                              ],
                              Container(
                                height: 40,
                                width: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A).withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                alignment: Alignment.center,
                                child: const Icon(Icons.payments_outlined, color: Color(0xFF0F172A)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      type.isEmpty ? 'Charge' : type,
                                      style: const TextStyle(fontWeight: FontWeight.w800),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      desc,
                                      style: const TextStyle(color: Color(0xFF475569)),
                                    ),
                                    if (residenceName.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        residenceName,
                                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                                      ),
                                    ],
                                    const SizedBox(height: 6),
                                    Text(
                                      '$amountLabel • $status',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: status == 'Payé' ? const Color(0xFF15803D) : const Color(0xFFB45309),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      selectionMode ? 'Appui long pour sélectionner' : 'Appuyer pour basculer Payé/Impayé',
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.sync_alt, size: 18, color: Color(0xFF94A3B8)),
                            ],
                          ),
                        ),
                      ),
                    );
                        },
                      ),
                    ),
                    if (totalPages > 1) _buildPaginationBar(),
                  ],
                ),
    );
  }
}
