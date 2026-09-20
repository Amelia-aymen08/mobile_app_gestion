import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../data/api_service.dart';
import '../../data/charges.dart';
import '../../l10n/app_localizations.dart';
import '../theme/design_tokens.dart';
import '../widgets/gi_appear.dart';
import '../theme/gi_colors.dart';
import '../widgets/gi_card.dart';
import '../widgets/gi_empty_state.dart';
import '../widgets/gi_header.dart';
import '../widgets/gi_pressable.dart';

class MyChargesScreen extends StatefulWidget {
  const MyChargesScreen({super.key});

  @override
  State<MyChargesScreen> createState() => _MyChargesScreenState();
}

class _MyChargesScreenState extends State<MyChargesScreen> {
  final ApiService _api = ApiService();
  bool _loading = true;
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
        _loading = false;
      });
    }
  }

  static const _months = [
    'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
    'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
  ];

  String _formatDate(dynamic value) {
    if (value == null) return '';
    try {
      final d = DateTime.parse(value.toString()).toLocal();
      return '${d.day} ${_months[d.month - 1].substring(0, 3)} ${d.year}';
    } catch (_) {
      return value.toString();
    }
  }

  String _monthLabel(Map charge) {
    final raw = (charge['periodEnd'] ?? charge['periodStart'] ?? '').toString();
    try {
      final d = DateTime.parse(raw).toLocal();
      return '${_months[d.month - 1]} ${d.year}';
    } catch (_) {
      return (charge['description'] ?? 'Charge').toString();
    }
  }

  int _amountValue(Map charge) => Charges.amount(charge);

  String _formatAmount(int value) => Charges.format(value);

  /// Replie le detail des charges. Le Figma prevoit ce bouton « Masquer » :
  /// la liste peut etre longue et l'historique se trouve juste en dessous.
  bool _breakdownOpen = true;

  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    final t = AppL10n.of(context);

    final due = Charges.due(_charges);
    final paidHistory = Charges.paid(_charges);

    final totalDue = Charges.totalDue(_charges);

    return Scaffold(
      backgroundColor: c.scaffold,
      body: SafeArea(
        bottom: false,
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: FigBrand.amber))
            : RefreshIndicator(
                color: FigBrand.amber,
                backgroundColor: c.card,
                onRefresh: _load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                      FigSpace.pagePadding,
                      MediaQuery.paddingOf(context).top > 0 ? 22 : 32,
                      FigSpace.pagePadding,
                      150),
                  children: [
                    GiScreenHeader(
                      iconAsset: 'assets/figma/icons/payment_20.svg',
                      accent: FigAccent.amber,
                      title: t.serviceCharges,
                      subtitle: _propertyLine(),
                    ),
                    const SizedBox(height: 20),
                    _summaryCard(c, t, due, totalDue),
                    const SizedBox(height: FigSpace.xl),
                    _breakdown(c, t, due, totalDue),
                    const SizedBox(height: FigSpace.xl),
                    Text(t.paymentHistory,
                        style: FigText.titleMd.copyWith(color: c.textBody)),
                    const SizedBox(height: FigSpace.lg),
                    if (paidHistory.isEmpty)
                      _emptyHistory(c, t)
                    else
                      for (var i = 0; i < paidHistory.length; i++) ...[
                        if (i > 0) const SizedBox(height: FigSpace.lg),
                        GiAppear(
                            index: i, child: _historyCard(c, paidHistory[i])),
                      ],
                  ],
                ),
              ),
      ),
    );
  }

  /// Sous-titre de l'en-tete : le bien concerne, comme dans la maquette
  /// (« Apartment 3B — Résidence Les Pins »).
  String _propertyLine() {
    final res = (_summary['residenceName'] ?? '').toString();
    return res.isEmpty ? '' : res;
  }

  /// Carte de resume — Figma 335 x 164 : periode et pastille d'etat en haut,
  /// puis le total du et son echeance.
  Widget _summaryCard(
      GiColors c, AppL10n t, List<Map<String, dynamic>> due, int totalDue) {
    final current = due.isNotEmpty ? due.first : null;
    final deadlineRaw =
        (current?['periodEnd'] ?? _summary['nextPaymentDate'])?.toString();
    final deadline = deadlineRaw == null ? null : DateTime.tryParse(deadlineRaw);
    final late = current != null && current['status'] == 'En retard';
    final stateColor = totalDue == 0
        ? FigAlert.success
        : (late ? FigAlert.error : FigBrand.amber);
    // Montant annuel annonce par le serveur. Il ne se confond pas avec ce
    // qui reste du : c'est le cout de l'annee, rappele pour situer la
    // somme a regler.
    // Le serveur annonce le prochain paiement dans le resume ; a defaut,
    // on prend la premiere charge impayee.
    final nextPayment = Charges.nextPayment(_charges, _summary);

    return GiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(t.currentPeriod,
                        style: FigText.body.copyWith(color: c.textMuted)),
                    const SizedBox(height: FigSpace.xs),
                    Text(
                      current == null ? '—' : _monthLabel(current),
                      style: FigText.statValue.copyWith(color: c.textBody),
                    ),
                  ],
                ),
              ),
              // Pastille d'etat : point de couleur puis libelle, comme le
              // Figma (62 x 28).
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: FigAccent.chipFill(stateColor),
                  border: Border.all(color: FigAccent.chipBorder(stateColor)),
                  borderRadius: BorderRadius.circular(FigRadius.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                          color: stateColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: FigSpace.sm),
                    Text(totalDue > 0 ? t.statusDue : t.upToDateTitle,
                        style: FigText.body.copyWith(color: stateColor)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: FigSpace.lg),
          // Prochain paiement : le montant annonce par le serveur, avec son
          // echeance. C'est la somme que le resident va devoir regler.
          Text(t.nextPayment, style: FigText.body.copyWith(color: c.textMuted)),
          const SizedBox(height: FigSpace.xs),
          Text(_formatAmount(nextPayment),
              style: FigText.greeting.copyWith(color: c.textBody)),
          if (deadline != null) ...[
            const SizedBox(height: FigSpace.xs),
            Text(
              t.paymentDeadline(_formatDate(deadline.toIso8601String())),
              style: FigText.body.copyWith(color: stateColor),
            ),
          ],
          // Argent du : ce qui reste impaye, tous mois confondus. Zero
          // quand le resident est a jour.
          const SizedBox(height: FigSpace.lg),
          Container(
            padding: const EdgeInsets.only(top: FigSpace.lg),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: c.innerBorder)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(t.amountOwed,
                      style: FigText.body.copyWith(color: c.textMuted)),
                ),
                Text(_formatAmount(totalDue),
                    style: FigText.field.copyWith(
                        fontWeight: FontWeight.w600,
                        color: totalDue > 0 ? stateColor : c.textBody)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Detail des charges : un titre avec son bouton de repli, puis une carte
  /// unique dont chaque ligne porte un libelle et un montant. La derniere
  /// ligne est le total, mise en avant.
  Widget _breakdown(
      GiColors c, AppL10n t, List<Map<String, dynamic>> due, int totalDue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(t.chargeBreakdown,
                  style: FigText.titleMd.copyWith(color: c.textBody)),
            ),
            GiPressable(
              pressedScale: 0.92,
              onTap: () => setState(() => _breakdownOpen = !_breakdownOpen),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_breakdownOpen ? t.hideLabel : t.showLabel,
                      style: FigText.caption.copyWith(color: c.textMuted)),
                  const SizedBox(width: FigSpace.xs),
                  AnimatedRotation(
                    turns: _breakdownOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 240),
                    child: SvgPicture.asset(
                      'assets/figma/icons/chevron_down.svg',
                      colorFilter:
                          ColorFilter.mode(c.textMuted, BlendMode.srcIn),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: FigSpace.lg),
        // Le repli se joue en hauteur : la liste glisse derriere le titre au
        // lieu de disparaitre d'un coup.
        AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: !_breakdownOpen
              ? const SizedBox(width: double.infinity)
              : ClipRRect(
                  borderRadius: BorderRadius.circular(FigRadius.card),
                  child: Container(
                    decoration: BoxDecoration(
                      color: c.card,
                      borderRadius: BorderRadius.circular(FigRadius.card),
                      border: Border.all(color: c.cardBorder),
                    ),
                    child: Column(
                      children: [
                        if (due.isEmpty)
                          _breakdownRow(c, t.totalLabel, 0, total: true)
                        else ...[
                          for (final charge in due) ...[
                            _breakdownRow(
                              c,
                              (charge['description'] ?? charge['type'] ?? '')
                                  .toString(),
                              _amountValue(charge),
                            ),
                            Divider(
                                height: 1,
                                thickness: 1,
                                color: c.innerBorder),
                          ],
                          _breakdownRow(c, t.totalLabel, totalDue,
                              total: true),
                        ],
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _breakdownRow(GiColors c, String label, int amount,
      {bool total = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: FigSpace.cardPadding, vertical: FigSpace.xl),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: total
                    ? FigText.titleMd.copyWith(color: c.textBody)
                    : FigText.body.copyWith(color: c.textMuted)),
          ),
          const SizedBox(width: FigSpace.lg),
          Text(_formatAmount(amount),
              style: total
                  ? FigText.titleMd.copyWith(color: FigBrand.amber)
                  : FigText.body.copyWith(color: c.textBody)),
        ],
      ),
    );
  }

  /// Ligne d'historique — Figma 335 x 96 : mois et montant sur la premiere
  /// ligne, date et moyen de paiement sur la seconde.
  Widget _historyCard(GiColors c, Map<String, dynamic> charge) {
    final amount = _amountValue(charge);
    final paidOn = _formatDate(charge['periodEnd']);
    final method = (charge['method'] ?? charge['type'] ?? '').toString();

    return GiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(_monthLabel(charge),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FigText.statValue.copyWith(color: c.textBody)),
              ),
              const SizedBox(width: FigSpace.lg),
              Text(_formatAmount(amount),
                  style: FigText.titleMd.copyWith(color: c.textBody)),
            ],
          ),
          const SizedBox(height: FigSpace.md),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                    color: FigAlert.success, shape: BoxShape.circle),
              ),
              const SizedBox(width: FigSpace.md),
              Expanded(
                child: Text(
                  method.isEmpty ? paidOn : '$paidOn · $method',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: FigText.caption.copyWith(color: c.textMuted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Etat vide — frame "Empty Payment" du Figma.
  Widget _emptyHistory(GiColors c, AppL10n t) => Padding(
        padding: const EdgeInsets.only(top: FigSpace.xl),
        child: GiEmptyState(
          illustration: 'assets/figma/empty/payments.svg',
          title: t.emptyPaymentsTitle,
          message: t.emptyPaymentsBody,
        ),
      );
}
