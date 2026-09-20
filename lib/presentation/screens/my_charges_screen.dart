import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/api_service.dart';
import '../theme/app_theme.dart';
import '../l10n/l10n.dart';

class MyChargesScreen extends StatefulWidget {
  const MyChargesScreen({super.key});

  @override
  State<MyChargesScreen> createState() => _MyChargesScreenState();
}

class _MyChargesScreenState extends State<MyChargesScreen> {
  final ApiService _api = ApiService();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _charges = [];
  Map<String, dynamic> _summary = const {};

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
      final results = await Future.wait([
        _api.getMyCharges(),
        _api.getMyChargesSummary(),
      ]);
      final rawCharges = results[0] as List;
      final summary = results[1] as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _charges = rawCharges.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        _summary = summary;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '').tr;
        _loading = false;
      });
    }
  }

  static const _months = [
    'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
    'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
  ];

  /// Month name in the current language; abbreviated (3 letters) for latin scripts.
  String _monthName(int month, {bool short = false}) {
    final name = _months[month - 1].tr;
    return short && L10n.current != AppLang.ar ? name.substring(0, 3) : name;
  }

  String _formatDate(dynamic value) {
    if (value == null) return '';
    try {
      final d = DateTime.parse(value.toString()).toLocal();
      return '${d.day} ${_monthName(d.month, short: true)} ${d.year}';
    } catch (_) {
      return value.toString();
    }
  }

  String _monthLabel(Map charge) {
    final raw = (charge['periodEnd'] ?? charge['periodStart'] ?? '').toString();
    try {
      final d = DateTime.parse(raw).toLocal();
      return '${_monthName(d.month)} ${d.year}';
    } catch (_) {
      return (charge['description'] ?? 'Charge'.tr).toString();
    }
  }

  int _periodMonths(Map charge) {
    DateTime? s, e;
    try { s = DateTime.parse((charge['periodStart'] ?? '').toString()); } catch (_) {}
    try { e = DateTime.parse((charge['periodEnd'] ?? '').toString()); } catch (_) {}
    if (s == null || e == null) return 1;
    return ((e.year - s.year) * 12 + (e.month - s.month)).clamp(1, 120);
  }

  int _amountValue(Map charge) {
    final base = int.tryParse((charge['amount'] ?? '0').toString()) ?? 0;
    final months = (charge['type'] ?? '').toString() == 'Charge' ? _periodMonths(charge) : 1;
    return base * months;
  }

  String _formatAmount(int value) => '${NumberFormat.decimalPattern('fr_FR').format(value)} DZD';

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? Colors.white : brandNavy;
    final muted = dark ? darkMuted : const Color(0xFF6B7280);

    final ownerStatus = (_summary['ownerStatus'] ?? _summary['status'] ?? 'Non Actif').toString();
    final isActive = ownerStatus == 'Actif';
    final message = (_summary['message'] ?? '').toString();

    final due = _charges.where((c) => c['status'] != 'Payé').toList()
      ..sort((a, b) => (a['periodEnd'] ?? '').toString().compareTo((b['periodEnd'] ?? '').toString()));
    final currentDue = due.isNotEmpty ? due.first : null;
    final paidHistory = _charges.where((c) => c['status'] == 'Payé').toList()
      ..sort((a, b) => (b['periodEnd'] ?? '').toString().compareTo((a['periodEnd'] ?? '').toString()));

    return Scaffold(
      backgroundColor: dark ? darkSurface : brandCream,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Text(_error!,
                        style: const TextStyle(color: Color(0xFFE0362B), fontWeight: FontWeight.w600)))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                  color: brandAmber.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
                              alignment: Alignment.center,
                              child: const Icon(Icons.credit_card_outlined, color: brandAmber, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Charges'.tr, style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 20)),
                                  Text('Suivez vos charges de copropriété'.tr, style: TextStyle(color: muted, fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        if (!isActive)
                          Container(
                            padding: const EdgeInsets.all(14),
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline, color: Color(0xFFB45309)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    (message.isNotEmpty
                                            ? message
                                            : "Votre compte est en attente d'activation par l'administration.")
                                        .tr,
                                    style: const TextStyle(color: Color(0xFFB45309), fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // ── Current due card ──────────────────
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(color: dark ? darkCard : Colors.white, borderRadius: BorderRadius.circular(20)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text('MOIS EN COURS'.tr,
                                      style: TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
                                  const Spacer(),
                                  if (currentDue != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                          color: brandAmber.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(20)),
                                      child: Text('Dû'.tr,
                                          style: const TextStyle(color: brandAmber, fontSize: 11, fontWeight: FontWeight.w700)),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currentDue != null ? _monthLabel(currentDue) : 'À jour'.tr,
                                style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 18),
                              ),
                              Divider(height: 26, color: dark ? darkBorder : const Color(0xFFF0EBDD)),
                              if (currentDue != null) ...[
                                Text('MONTANT DÛ'.tr,
                                    style: TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
                                const SizedBox(height: 4),
                                Text(_formatAmount(_amountValue(currentDue)),
                                    style: const TextStyle(color: brandAmber, fontWeight: FontWeight.w900, fontSize: 26)),
                                const SizedBox(height: 4),
                                if (currentDue['periodEnd'] != null)
                                  Text('Échéance : {date}'.trp({'date': _formatDate(currentDue['periodEnd'])}),
                                      style: const TextStyle(color: brandAmber, fontSize: 12, fontWeight: FontWeight.w600)),
                              ] else
                                Text('Aucune charge en attente de paiement.'.tr,
                                    style: TextStyle(color: muted, fontSize: 13)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),

                        Text('Historique des paiements'.tr,
                            style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 16)),
                        const SizedBox(height: 12),

                        if (paidHistory.isEmpty)
                          _emptyHistory(dark, fg, muted)
                        else
                          ...paidHistory.map((c) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(color: dark ? darkCard : Colors.white, borderRadius: BorderRadius.circular(16)),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 34,
                                        height: 34,
                                        decoration: BoxDecoration(
                                            color: const Color(0xFF16A34A).withValues(alpha: 0.14),
                                            borderRadius: BorderRadius.circular(10)),
                                        alignment: Alignment.center,
                                        child: const Icon(Icons.check_rounded, color: Color(0xFF16A34A), size: 18),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(_monthLabel(c).isNotEmpty
                                                    ? '${_monthLabel(c)[0].toUpperCase()}${_monthLabel(c).substring(1)}'
                                                    : 'Charge'.tr,
                                                style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 14)),
                                            if (c['periodEnd'] != null)
                                              Text(_formatDate(c['periodEnd']),
                                                  style: TextStyle(color: muted, fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                      Text(_formatAmount(_amountValue(c)),
                                          style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 14)),
                                    ],
                                  ),
                                ),
                              )),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _emptyHistory(bool dark, Color fg, Color muted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: dark ? darkBorder : const Color(0xFFE2DDCF), width: 3),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.receipt_long_outlined, size: 44, color: dark ? darkBorder : const Color(0xFFE2DDCF)),
          ),
          const SizedBox(height: 18),
          Text('Aucun paiement'.tr, style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 6),
          Text("Vous n'avez encore effectué aucun paiement de charges.".tr,
              textAlign: TextAlign.center, style: TextStyle(color: muted, fontSize: 13)),
        ],
      ),
    );
  }
}
