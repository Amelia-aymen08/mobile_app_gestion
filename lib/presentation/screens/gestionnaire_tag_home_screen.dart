// ignore_for_file: use_build_context_synchronously
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/api_service.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'notifications_screen.dart';

class GestionnaireTagHomeScreen extends StatefulWidget {
  const GestionnaireTagHomeScreen({super.key});
  @override
  State<GestionnaireTagHomeScreen> createState() => _GestionnaireTagHomeScreenState();
}

class _GestionnaireTagHomeScreenState extends State<GestionnaireTagHomeScreen> {
  final ApiService _api = ApiService();
  int _tab = 0;

  // Charges payées
  bool _loadingCharges = true;
  String _chargesError = '';
  List<Map<String, dynamic>> _paidCharges = [];

  // Tags créés
  bool _loadingTags = true;
  List<Map<String, dynamic>> _tags = [];

  // Notifications badge
  int _unreadCount = 0;
  Timer? _notifTimer;

  // Track which transaction IDs already have a tag
  final Set<String> _taggedTransactionIds = {};

  @override
  void initState() {
    super.initState();
    _loadAll();
    _fetchUnread();
    _notifTimer = Timer.periodic(
        const Duration(seconds: 30), (_) { if (mounted) _fetchUnread(); });
  }

  @override
  void dispose() {
    _notifTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadCharges(), _loadTags()]);
  }

  Future<void> _loadCharges() async {
    setState(() { _loadingCharges = true; _chargesError = ''; });
    try {
      final data = await _api.getTransactions();
      if (!mounted) return;
      final paid = data
          .whereType<Map>()
          .where((t) =>
              (t['type']?.toString() ?? '') == 'Charge' &&
              (t['status']?.toString() ?? '') == 'Payé')
          .map((t) => Map<String, dynamic>.from(t))
          .toList();
      // Sort most recent first
      paid.sort((a, b) =>
          (b['updatedAt'] ?? b['createdAt'] ?? '').toString()
              .compareTo((a['updatedAt'] ?? a['createdAt'] ?? '').toString()));
      setState(() { _paidCharges = paid; _loadingCharges = false; });
    } catch (e) {
      if (mounted) setState(() { _chargesError = e.toString().replaceAll('Exception: ', ''); _loadingCharges = false; });
    }
  }

  Future<void> _loadTags() async {
    setState(() => _loadingTags = true);
    try {
      final data = await _api.getTags();
      if (!mounted) return;
      final tags = data.whereType<Map>().map((t) => Map<String, dynamic>.from(t)).toList();
      final ids = tags.map((t) => (t['transactionId'] ?? '').toString()).where((id) => id.isNotEmpty).toSet();
      setState(() { _tags = tags; _taggedTransactionIds..clear()..addAll(ids); _loadingTags = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingTags = false);
    }
  }

  Future<void> _fetchUnread() async {
    try {
      final list = await _api.getNotifications();
      if (!mounted) return;
      setState(() => _unreadCount =
          list.whereType<Map>().where((n) => n['isRead'] != true).length);
    } catch (_) {}
  }

  // ─── Helpers ─────────────────────────────────────────────
  String _fmtAmt(dynamic v) {
    final n = num.tryParse(v?.toString() ?? '')?.round() ?? 0;
    return '${NumberFormat.decimalPattern('fr_FR').format(n)} DA';
  }

  String _resName(Map t) =>
      (t['Residence'] is Map ? t['Residence']['name']?.toString() : null) ?? '';

  String _resId(Map t) =>
      (t['Residence'] is Map ? t['Residence']['id']?.toString() : null) ?? '';

  String _ownerEmail(Map t) {
    if (t['Property'] is Map) {
      final owner = t['Property']['owner'];
      if (owner is Map) return (owner['email'] ?? '').toString();
    }
    return '';
  }

  String _fmtDate(dynamic v) {
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(v.toString()).toLocal());
    } catch (_) { return ''; }
  }

  // ─── Create TAG dialog ────────────────────────────────────
  Future<void> _createTag(Map<String, dynamic> charge) async {
    final txId = (charge['id'] ?? '').toString();
    final ownerEmail = _ownerEmail(charge);
    final resName = _resName(charge);
    final resId = _resId(charge);
    final desc = (charge['description'] ?? '').toString();

    final notesCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Créer TAG ACTIVE'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (ownerEmail.isNotEmpty)
              _dialogRow(Icons.person_outline, ownerEmail),
            if (resName.isNotEmpty)
              _dialogRow(Icons.apartment_outlined, resName),
            if (desc.isNotEmpty)
              _dialogRow(Icons.receipt_outlined, desc),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Notes (optionnel)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Créer TAG')),
        ],
      ),
    );

    if (confirmed != true) return;
    if (ownerEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email résident introuvable pour cette charge.')));
      return;
    }

    try {
      await _api.createTag(
        residentEmail: ownerEmail,
        residenceId: resId.isNotEmpty ? resId : null,
        residenceName: resName.isNotEmpty ? resName : null,
        transactionId: txId.isNotEmpty ? txId : null,
        transactionDescription: desc.isNotEmpty ? desc : null,
        notes: notesCtrl.text.isNotEmpty ? notesCtrl.text : null,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('TAG ACTIVE créé. Recouvrement notifié.')));
      await _loadTags();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))));
    }
  }

  Widget _dialogRow(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(children: [
          Icon(icon, size: 15, color: const Color(0xFF64748B)),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ]),
      );

  // ─── Build ────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Scaffold(
      backgroundColor: brandBackground,
      body: IndexedStack(
        index: _tab,
        children: [
          _chargesTab(),
          _tagsTab(),
          _profilTab(user),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shadowColor: Colors.black12,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Charges payées',
          ),
          const NavigationDestination(
            icon: Icon(Icons.nfc_outlined),
            selectedIcon: Icon(Icons.nfc_rounded),
            label: 'Tags créés',
          ),
          NavigationDestination(
            icon: _unreadCount > 0
                ? Badge(label: Text('$_unreadCount'), child: const Icon(Icons.person_outline))
                : const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  // ─── Tab 0 — Charges payées ───────────────────────────────
  Widget _chargesTab() => CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true, snap: true,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 2, shadowColor: Colors.black12,
            titleSpacing: 16,
            title: const Text('Charges payées',
                style: TextStyle(fontWeight: FontWeight.w900, color: brandBlue, fontSize: 20)),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: brandBlue),
                onPressed: _loadAll,
              ),
            ],
          ),
          if (_loadingCharges)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else if (_chargesError.isNotEmpty)
            SliverFillRemaining(
              child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.wifi_off_rounded, size: 48, color: Color(0xFFCBD5E1)),
                const SizedBox(height: 12),
                Text(_chargesError, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(onPressed: _loadCharges, child: const Text('Réessayer')),
              ])),
            )
          else if (_paidCharges.isEmpty)
            const SliverFillRemaining(
              child: Center(child: Text('Aucune charge payée.',
                  style: TextStyle(color: Color(0xFF94A3B8)))),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _chargeCard(_paidCharges[i]),
                  childCount: _paidCharges.length,
                ),
              ),
            ),
        ],
      );

  Widget _chargeCard(Map<String, dynamic> tx) {
    final id = (tx['id'] ?? '').toString();
    final desc = (tx['description'] ?? '').toString();
    final resName = _resName(tx);
    final ownerEmail = _ownerEmail(tx);
    final amount = _fmtAmt(tx['amount']);
    final date = _fmtDate(tx['updatedAt'] ?? tx['createdAt']);
    final alreadyTagged = _taggedTransactionIds.contains(id);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF15803D).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.check_circle_outline, color: Color(0xFF15803D)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(desc.isNotEmpty ? desc : 'Charge',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (ownerEmail.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(ownerEmail,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                  if (resName.isNotEmpty) ...[
                    const SizedBox(height: 1),
                    Text(resName,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 3),
                  Row(children: [
                    Text(amount,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: brandBlue)),
                    if (date.isNotEmpty) ...[
                      const Text(' · ', style: TextStyle(color: Color(0xFFCBD5E1))),
                      Text(date, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                    ],
                  ]),
                ],
              ),
            ),
            const SizedBox(width: 8),
            alreadyTagged
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF15803D).withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('TAG actif',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF15803D))),
                  )
                : FilledButton.tonal(
                    onPressed: ownerEmail.isEmpty ? null : () => _createTag(tx),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: brandBlue.withValues(alpha: 0.10),
                      foregroundColor: brandBlue,
                    ),
                    child: const Text('Créer TAG', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
          ],
        ),
      ),
    );
  }

  // ─── Tab 1 — Tags créés ───────────────────────────────────
  Widget _tagsTab() => CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true, snap: true,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 2, shadowColor: Colors.black12,
            titleSpacing: 16,
            title: const Text('Tags créés',
                style: TextStyle(fontWeight: FontWeight.w900, color: brandBlue, fontSize: 20)),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: brandBlue),
                onPressed: _loadTags,
              ),
            ],
          ),
          if (_loadingTags)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else if (_tags.isEmpty)
            const SliverFillRemaining(
              child: Center(child: Text('Aucun TAG créé.',
                  style: TextStyle(color: Color(0xFF94A3B8)))),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _tagCard(_tags[i]),
                  childCount: _tags.length,
                ),
              ),
            ),
        ],
      );

  Widget _tagCard(Map<String, dynamic> tag) {
    final email = (tag['residentEmail'] ?? '').toString();
    final res = (tag['residenceName'] ?? '').toString();
    final desc = (tag['transactionDescription'] ?? '').toString();
    final date = _fmtDate(tag['createdAt']);
    final notes = (tag['notes'] ?? '').toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: brandBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.nfc_rounded, color: brandBlue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(email,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (res.isNotEmpty)
                    Text(res, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  if (desc.isNotEmpty)
                    Text(desc, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (notes.isNotEmpty)
                    Text(notes, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontStyle: FontStyle.italic),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(date, style: const TextStyle(fontSize: 11, color: Color(0xFFCBD5E1))),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF15803D).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('ACTIF',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF15803D))),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Tab 2 — Profil ───────────────────────────────────────
  Widget _profilTab(Map? user) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: const BoxDecoration(color: brandBlue, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: const Icon(Icons.nfc_rounded, size: 38, color: Colors.white),
                ),
                const SizedBox(height: 14),
                Text(user?['name']?.toString() ?? '',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: brandBlue),
                    textAlign: TextAlign.center),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: brandGold.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Gestionnaire TAG',
                      style: TextStyle(fontSize: 13, color: brandBlue, fontWeight: FontWeight.w700)),
                ),
                if (user?['email'] != null) ...[
                  const SizedBox(height: 6),
                  Text(user!['email'].toString(),
                      style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
                ],
              ],
            ),
          ),
          const SizedBox(height: 28),
          // Stats
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(children: [
              Expanded(child: _pStat('Tags créés', '${_tags.length}', brandBlue)),
              Container(width: 1, height: 40, color: const Color(0xFFE2E8F0)),
              Expanded(child: _pStat('Charges payées', '${_paidCharges.length}', const Color(0xFF15803D))),
            ]),
          ),
          const SizedBox(height: 16),
          Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                _fetchUnread();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                        color: brandBlue.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12)),
                    alignment: Alignment.center,
                    child: const Icon(Icons.notifications_outlined, color: brandBlue, size: 20),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(child: Text('Notifications', style: TextStyle(fontWeight: FontWeight.w700))),
                  if (_unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: const Color(0xFFDC2626), borderRadius: BorderRadius.circular(20)),
                      child: Text('$_unreadCount', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFFCBD5E1)),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Se déconnecter'),
            onPressed: () {
              context.read<AuthProvider>().logout();
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFDC2626),
              side: const BorderSide(color: Color(0xFFDC2626)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      );

  Widget _pStat(String label, String value, Color color) => Column(
        children: [
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
        ],
      );
}
