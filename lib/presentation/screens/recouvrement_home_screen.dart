// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/api_service.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class RecouvrementHomeScreen extends StatefulWidget {
  const RecouvrementHomeScreen({super.key});
  @override
  State<RecouvrementHomeScreen> createState() => _RecouvrementHomeScreenState();
}

class _RecouvrementHomeScreenState extends State<RecouvrementHomeScreen> {
  final ApiService _api = ApiService();
  int _tab = 0;

  bool _loading = true;
  String _error = '';
  List<Map<String, dynamic>> _charges = [];

  String _statusFilter = 'Tous';
  String? _residenceFilter;
  final Set<String> _selectedIds = {};
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(
      () => setState(() => _searchQuery = _searchController.text.trim().toLowerCase()),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final data = await _api.getTransactions();
      if (!mounted) return;
      setState(() {
        _charges = data
            .whereType<Map>()
            .where((t) => (t['type']?.toString() ?? '') == 'Charge')
            .map((t) => Map<String, dynamic>.from(t))
            .toList();
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

  // ─── Helpers ─────────────────────────────────────────────
  int _toInt(dynamic v) => num.tryParse(v?.toString() ?? '')?.round() ?? 0;

  String _fmtAmt(int v) => '${NumberFormat.decimalPattern('fr_FR').format(v)} DA';

  int _periodMonths(Map t) {
    DateTime? s, e;
    try { s = DateTime.parse((t['periodStart'] ?? '').toString()); } catch (_) {}
    try { e = DateTime.parse((t['periodEnd'] ?? '').toString()); } catch (_) {}
    if (s == null || e == null) return 1;
    return ((e.year - s.year) * 12 + (e.month - s.month)).clamp(1, 120);
  }

  int _amt(Map t) {
    final a = _toInt(t['amount']);
    if ((t['type'] ?? '') != 'Charge') return a;
    return a * _periodMonths(t);
  }

  String _resName(Map t) =>
      (t['Residence'] is Map ? t['Residence']['name']?.toString() : null) ?? 'Inconnu';

  String _resId(Map t) =>
      (t['Residence'] is Map ? t['Residence']['id']?.toString() : null) ?? '';

  String _lotNumber(Map t) {
    final prop = t['property'] is Map ? t['property'] as Map : null;
    return prop?['lotNumber']?.toString() ?? '';
  }

  String _ownerName(Map t) {
    final prop = t['property'] is Map ? t['property'] as Map : null;
    if (prop == null) return '';
    final owner = prop['owner'] is Map ? prop['owner'] as Map : null;
    if (owner == null) return '';
    final fn = owner['firstName']?.toString() ?? '';
    final ln = owner['lastName']?.toString() ?? '';
    return '$fn $ln'.trim();
  }

  List<_ResGroup> get _groups {
    final map = <String, _ResGroup>{};
    for (final c in _charges) {
      final id = _resId(c);
      final name = _resName(c);
      map.putIfAbsent(id, () => _ResGroup(id: id, name: name));
      if ((c['status'] ?? '') == 'Payé') {
        map[id]!.paid++;
        map[id]!.paidAmt += _amt(c);
      } else {
        map[id]!.unpaid++;
        map[id]!.unpaidAmt += _amt(c);
      }
    }
    final list = map.values.toList()
      ..sort((a, b) => b.unpaid.compareTo(a.unpaid));
    return list;
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _searchQuery;
    var list = _charges.where((c) {
      final s = (c['status'] ?? '').toString();
      final matchS = _statusFilter == 'Tous' || s == _statusFilter;
      final matchR = _residenceFilter == null || _resId(c) == _residenceFilter;
      if (!matchS || !matchR) return false;
      if (q.isEmpty) return true;
      final lot = _lotNumber(c).toLowerCase();
      final owner = _ownerName(c).toLowerCase();
      final desc = (c['description'] ?? '').toString().toLowerCase();
      final res = _resName(c).toLowerCase();
      return lot.contains(q) || owner.contains(q) || desc.contains(q) || res.contains(q);
    }).toList();

    // Sort by residence name, then by lot number
    list.sort((a, b) {
      final r = _resName(a).compareTo(_resName(b));
      if (r != 0) return r;
      final lotA = _lotNumber(a);
      final lotB = _lotNumber(b);
      final numA = int.tryParse(lotA.replaceAll(RegExp(r'\D'), '')) ?? 0;
      final numB = int.tryParse(lotB.replaceAll(RegExp(r'\D'), '')) ?? 0;
      if (numA != numB) return numA.compareTo(numB);
      return lotA.compareTo(lotB);
    });

    return list;
  }

  Future<void> _toggle(Map<String, dynamic> tx) async {
    final id = (tx['id'] ?? '').toString();
    if (id.isEmpty) return;
    final isPaid = (tx['status'] ?? '') == 'Payé';
    final next = isPaid ? 'Impayé' : 'Payé';
    final label = isPaid ? 'Impayé' : 'Payé';
    final lot = _lotNumber(tx);
    final owner = _ownerName(tx);
    final subtitle = [if (owner.isNotEmpty) owner, if (lot.isNotEmpty) 'Lot $lot']
        .join(' · ');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirmer le changement',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subtitle.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(subtitle,
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
              ),
            RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
                children: [
                  const TextSpan(text: 'Passer le statut à '),
                  TextSpan(
                    text: label,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: isPaid
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF15803D),
                    ),
                  ),
                  const TextSpan(text: ' ?'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isPaid
                  ? const Color(0xFFDC2626)
                  : const Color(0xFF15803D),
            ),
            child: Text(label,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _api.updateTransaction(id: id, payload: {'status': next});
      if (!mounted) return;
      setState(() {
        for (var i = 0; i < _charges.length; i++) {
          if ((_charges[i]['id']?.toString() ?? '') == id) {
            _charges[i] = {..._charges[i], 'status': next};
            break;
          }
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))));
    }
  }

  Future<void> _batchStatus(String status) async {
    final ids = _selectedIds.toList();
    if (ids.isEmpty) return;

    final label = status;
    final color = status == 'Payé' ? const Color(0xFF15803D) : const Color(0xFFDC2626);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirmer l\'action',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
            children: [
              TextSpan(text: 'Passer ${ids.length} charge(s) à '),
              TextSpan(
                  text: label,
                  style: TextStyle(fontWeight: FontWeight.w800, color: color)),
              const TextSpan(text: ' ?'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: color),
            child: const Text('Confirmer',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      for (final id in ids) {
        await _api.updateTransaction(id: id, payload: {'status': status});
      }
      if (!mounted) return;
      setState(() {
        for (var i = 0; i < _charges.length; i++) {
          if (ids.contains(_charges[i]['id']?.toString() ?? '')) {
            _charges[i] = {..._charges[i], 'status': status};
          }
        }
        _selectedIds.clear();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))));
    }
  }

  // ─── Build ────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final selMode = _selectedIds.isNotEmpty && _tab == 1;

    return Scaffold(
      backgroundColor: brandBackground,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? _buildError()
              : IndexedStack(
                  index: _tab,
                  children: [
                    _buildResidencesTab(),
                    _buildChargesTab(selMode),
                    _buildProfilTab(user),
                  ],
                ),
      bottomNavigationBar: selMode ? _buildSelectionBar() : _buildNavBar(),
    );
  }

  Widget _buildNavBar() => NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shadowColor: Colors.black12,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.apartment_outlined),
            selectedIcon: Icon(Icons.apartment),
            label: 'Résidences',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Charges',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      );

  Widget _buildSelectionBar() => Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
        child: SafeArea(
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _selectedIds.clear()),
              ),
              Text('${_selectedIds.length} sélectionné(s)',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.check_circle_outline, color: Color(0xFF15803D)),
                label: const Text('Payé',
                    style: TextStyle(color: Color(0xFF15803D), fontWeight: FontWeight.w700)),
                onPressed: () => _batchStatus('Payé'),
              ),
              TextButton.icon(
                icon: const Icon(Icons.cancel_outlined, color: Color(0xFFDC2626)),
                label: const Text('Impayé',
                    style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w700)),
                onPressed: () => _batchStatus('Impayé'),
              ),
            ],
          ),
        ),
      );

  Widget _buildError() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 56, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 16),
            Text(_error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF64748B))),
            const SizedBox(height: 20),
            FilledButton(onPressed: _loadData, child: const Text('Réessayer')),
          ],
        ),
      );

  // ─── Tab 0 — Résidences ───────────────────────────────────
  Widget _buildResidencesTab() {
    final groups = _groups;
    final totalPaidAmt = groups.fold(0, (s, g) => s + g.paidAmt);
    final totalUnpaidAmt = groups.fold(0, (s, g) => s + g.unpaidAmt);
    final totalPaid = groups.fold(0, (s, g) => s + g.paid);
    final totalUnpaid = groups.fold(0, (s, g) => s + g.unpaid);

    return CustomScrollView(
      slivers: [
        _sliverHeader('Résidences', onRefresh: _loadData),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                    child: _statCard('Payées', totalPaid, _fmtAmt(totalPaidAmt),
                        const Color(0xFF15803D))),
                const SizedBox(width: 12),
                Expanded(
                    child: _statCard('Impayées', totalUnpaid, _fmtAmt(totalUnpaidAmt),
                        const Color(0xFFDC2626))),
              ],
            ),
          ),
        ),
        if (groups.isEmpty)
          const SliverFillRemaining(
            child: Center(
                child: Text('Aucune donnée.',
                    style: TextStyle(color: Color(0xFF94A3B8)))),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _residenceCard(groups[i]),
                childCount: groups.length,
              ),
            ),
          ),
      ],
    );
  }

  Widget _statCard(String label, int count, String amount, Color color) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                      color: color, borderRadius: BorderRadius.circular(4))),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700, color: color)),
            ]),
            const SizedBox(height: 8),
            Text('$count charges',
                style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
            const SizedBox(height: 2),
            Text(amount,
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w900, color: color)),
          ],
        ),
      );

  Widget _residenceCard(_ResGroup g) {
    final total = g.paid + g.unpaid;
    final pct = total == 0 ? 0.0 : g.paid / total;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() {
          _residenceFilter = _residenceFilter == g.id ? null : g.id;
          _statusFilter = 'Tous';
          _tab = 1;
        }),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: brandBlue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.apartment_outlined,
                      color: brandBlue, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(g.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15))),
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: Color(0xFFCBD5E1)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                _chip('${g.paid} payées', const Color(0xFF15803D)),
                const SizedBox(width: 8),
                _chip('${g.unpaid} impayées', const Color(0xFFDC2626)),
              ]),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 6,
                  backgroundColor:
                      const Color(0xFFDC2626).withValues(alpha: 0.15),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF15803D)),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_fmtAmt(g.paidAmt),
                      style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF15803D),
                          fontWeight: FontWeight.w700)),
                  Text(_fmtAmt(g.unpaidAmt),
                      style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFDC2626),
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, color: color)),
      );

  // ─── Tab 1 — Charges ──────────────────────────────────────
  Widget _buildChargesTab(bool selMode) {
    final list = _filtered;
    return CustomScrollView(
      slivers: [
        _sliverHeader('Charges', onRefresh: _loadData),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Search bar ────────────────────────────────
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher (lot, propriétaire, résidence…)',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['Tous', 'Payé', 'Impayé']
                        .map((f) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(f),
                                selected: _statusFilter == f,
                                onSelected: (_) => setState(() {
                                  _statusFilter = f;
                                  _selectedIds.clear();
                                }),
                                selectedColor:
                                    brandBlue.withValues(alpha: 0.12),
                                showCheckmark: false,
                                labelStyle: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: _statusFilter == f
                                      ? brandBlue
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
                if (_residenceFilter != null) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => setState(() => _residenceFilter = null),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: brandBlue.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.apartment_outlined,
                            size: 13, color: brandBlue),
                        const SizedBox(width: 4),
                        Text(
                          _groups
                              .firstWhere((g) => g.id == _residenceFilter,
                                  orElse: () =>
                                      _ResGroup(id: '', name: 'Résidence'))
                              .name,
                          style: const TextStyle(
                              fontSize: 12,
                              color: brandBlue,
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.close, size: 13, color: brandBlue),
                      ]),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        if (list.isEmpty)
          const SliverFillRemaining(
            child: Center(
                child: Text('Aucune charge.',
                    style: TextStyle(color: Color(0xFF94A3B8)))),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _chargeCard(list[i], selMode),
                childCount: list.length,
              ),
            ),
          ),
      ],
    );
  }

  Widget _chargeCard(Map<String, dynamic> tx, bool selMode) {
    final id = (tx['id'] ?? '').toString();
    final status = (tx['status'] ?? '').toString();
    final desc = (tx['description'] ?? '').toString();
    final resName = _resName(tx);
    final amount = _amt(tx);
    final isPaid = status == 'Payé';
    final sel = _selectedIds.contains(id);
    final color = isPaid ? const Color(0xFF15803D) : const Color(0xFFDC2626);
    final lot = _lotNumber(tx);
    final owner = _ownerName(tx);

    final subtitle = [
      if (owner.isNotEmpty) owner,
      if (lot.isNotEmpty) 'Lot $lot',
      resName,
    ].join(' · ');

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (selMode && id.isNotEmpty) {
            setState(
                () => sel ? _selectedIds.remove(id) : _selectedIds.add(id));
          } else {
            _toggle(tx);
          }
        },
        onLongPress: () {
          if (id.isNotEmpty) {
            setState(
                () => sel ? _selectedIds.remove(id) : _selectedIds.add(id));
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              if (selMode) ...[
                Checkbox(
                  value: sel,
                  onChanged: id.isEmpty
                      ? null
                      : (_) => setState(() =>
                          sel ? _selectedIds.remove(id) : _selectedIds.add(id)),
                  activeColor: brandBlue,
                ),
                const SizedBox(width: 4),
              ],
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(
                  isPaid
                      ? Icons.check_circle_outline
                      : Icons.radio_button_unchecked,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      desc.isNotEmpty ? desc : 'Charge',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF64748B)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_fmtAmt(amount),
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 13)),
                  const SizedBox(height: 5),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status.isEmpty ? 'N/A' : status,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: color),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Tab 2 — Profil ───────────────────────────────────────
  Widget _buildProfilTab(Map? user) {
    final total = _charges.length;
    final paid = _charges.where((c) => c['status'] == 'Payé').length;
    final unpaid = total - paid;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        const SizedBox(height: 24),
        Center(
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: brandBlue,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.payments_outlined,
                    size: 36, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                user?['name']?.toString() ?? '',
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: brandBlue),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: brandGold.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Recouvrement',
                  style: TextStyle(
                      fontSize: 13,
                      color: brandBlue,
                      fontWeight: FontWeight.w700),
                ),
              ),
              if (user?['email'] != null) ...[
                const SizedBox(height: 8),
                Text(
                  user!['email'].toString(),
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF94A3B8)),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 12,
                  offset: Offset(0, 4))
            ],
          ),
          child: Row(
            children: [
              Expanded(child: _pStat('Total', '$total', brandBlue)),
              Container(
                  width: 1, height: 40, color: const Color(0xFFE2E8F0)),
              Expanded(
                  child: _pStat(
                      'Payées', '$paid', const Color(0xFF15803D))),
              Container(
                  width: 1, height: 40, color: const Color(0xFFE2E8F0)),
              Expanded(
                  child: _pStat(
                      'Impayées', '$unpaid', const Color(0xFFDC2626))),
            ],
          ),
        ),
        const SizedBox(height: 32),
        OutlinedButton.icon(
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Se déconnecter'),
          onPressed: () {
            context.read<AuthProvider>().logout();
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const LoginScreen()));
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFDC2626),
            side: const BorderSide(color: Color(0xFFDC2626)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }

  Widget _pStat(String label, String value, Color color) => Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: Color(0xFF94A3B8))),
        ],
      );

  Widget _sliverHeader(String title, {VoidCallback? onRefresh}) =>
      SliverAppBar(
        floating: true,
        snap: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        shadowColor: Colors.black12,
        titleSpacing: 16,
        title: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: brandBlue,
                fontSize: 20)),
        actions: [
          if (onRefresh != null)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: brandBlue),
              onPressed: onRefresh,
            ),
        ],
      );
}

class _ResGroup {
  final String id;
  final String name;
  int paid = 0;
  int unpaid = 0;
  int paidAmt = 0;
  int unpaidAmt = 0;
  _ResGroup({required this.id, required this.name});
}
