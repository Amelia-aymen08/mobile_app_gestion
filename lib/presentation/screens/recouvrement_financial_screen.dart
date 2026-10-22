import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/api_service.dart';
import '../../data/charges.dart';
import '../services/gi_haptics.dart';
import '../theme/design_tokens.dart';
import '../theme/gi_colors.dart';
import '../widgets/gi_appear.dart';
import '../widgets/gi_card.dart';
import '../widgets/gi_pressable.dart';
import '../widgets/gi_refresh.dart';
import '../widgets/gi_scroll_blur.dart';
import '../widgets/gi_skeleton.dart';
import 'admin/admin_sheet.dart';
import 'admin/admin_ui.dart';

/// Lecture des champs d'une charge, telle que `/financial` la renvoie.
abstract final class _Tx {
  static String id(Map t) => (t['id'] ?? '').toString();

  static String residenceId(Map t) {
    final r = t['Residence'] ?? t['residence'];
    return (t['residenceId'] ?? (r is Map ? r['id'] : null) ?? '').toString();
  }

  static String residenceName(Map t) {
    final r = t['Residence'] ?? t['residence'];
    final name = r is Map ? (r['name'] ?? '').toString() : '';
    return name.isEmpty ? (t['residenceName'] ?? '').toString() : name;
  }

  /// Le payeur : le serveur ne le nomme pas toujours de la meme facon.
  static String payer(Map t) {
    for (final k in ['clientName', 'ownerName', 'residentName', 'client']) {
      final v = (t[k] ?? '').toString().trim();
      if (v.isNotEmpty) return v;
    }
    final o = t['Owner'] ?? t['owner'] ?? t['User'] ?? t['user'];
    if (o is Map) {
      final full = '${o['firstName'] ?? ''} ${o['lastName'] ?? ''}'.trim();
      if (full.isNotEmpty) return full;
      final n = (o['name'] ?? '').toString().trim();
      if (n.isNotEmpty) return n;
    }
    return (t['email'] ?? t['clientEmail'] ?? '').toString();
  }

  static const _months = [
    'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 'Juillet', //
    'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
  ];

  /// « Mars 2026 », ou « Janv. – Mars 2026 » pour une charge trimestrielle.
  static String period(Map t) {
    final s = DateTime.tryParse((t['periodStart'] ?? '').toString());
    final e = DateTime.tryParse((t['periodEnd'] ?? '').toString());
    if (s == null) return '';
    final months = Charges.periodMonths(t);
    if (e == null || months <= 1) return '${_months[s.month - 1]} ${s.year}';
    final last = DateTime(s.year, s.month + months - 1);
    String short(DateTime d) => _months[d.month - 1].substring(0, 4);
    return '${short(s)}. – ${short(last)}. ${last.year}';
  }

  static bool late(Map t) {
    if (Charges.isPaid(t)) return false;
    final status = (t['status'] ?? '').toString().toLowerCase();
    if (status.contains('retard')) return true;
    final end = DateTime.tryParse((t['periodEnd'] ?? '').toString());
    return end != null && end.isBefore(DateTime.now());
  }
}

enum _Show { all, unpaid, paid }

/// Suivi des paiements de l'administration.
///
/// Construit comme la page Paiements du resident : un resume en tete — ce
/// qui reste a encaisser, ce qui l'est deja, le taux de recouvrement — puis
/// les charges. On choisit une residence dans une rangee de puces, on filtre
/// impayes / payes, on cherche un resident. Sur « Toutes », les charges se
/// rangent par residence, chacune avec ce qu'elle doit encore.
///
/// Toucher une charge ouvre sa fiche et le bouton qui la marque payee ou
/// impayee ; un appui long en selectionne plusieurs, pour les solder d'un
/// coup.
class RecouvrementFinancialScreen extends StatefulWidget {
  const RecouvrementFinancialScreen({super.key});

  @override
  State<RecouvrementFinancialScreen> createState() =>
      _RecouvrementFinancialScreenState();
}

class _RecouvrementFinancialScreenState
    extends State<RecouvrementFinancialScreen> {
  final ApiService _api = ApiService();
  final _search = TextEditingController();
  final _money = NumberFormat.decimalPattern('fr_FR');

  bool _loading = true;
  String _error = '';
  List<Map<String, dynamic>> _charges = [];
  String _residence = '';
  _Show _show = _Show.unpaid;
  final Set<String> _selected = {};
  bool _busy = false;
  String _query = '';
  final _appear = GiAppearWindow();

  @override
  void initState() {
    super.initState();
    _search.addListener(() {
      final q = _search.text.trim().toLowerCase();
      if (q != _query) setState(() => _query = q);
    });
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _fmt(int amount) => '${_money.format(amount)} DA';

  Future<void> _load() async {
    try {
      final data = await _api.getTransactions();
      if (!mounted) return;
      setState(() {
        _charges = data
            .whereType<Map>()
            .where((t) => (t['type'] ?? '').toString() == 'Charge')
            .map((t) => Map<String, dynamic>.from(t))
            .toList()
          // Les plus recentes d'abord ; la vue « Impayees » inverse l'ordre.
          ..sort((a, b) => (b['periodStart'] ?? '')
              .toString()
              .compareTo((a['periodStart'] ?? '').toString()));
        _error = '';
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

  /// Residences presentes dans les charges, par nom.
  List<(String, String)> get _residences {
    final seen = <String, String>{};
    for (final t in _charges) {
      final id = _Tx.residenceId(t);
      final key = id.isEmpty ? _Tx.residenceName(t) : id;
      if (key.isEmpty) continue;
      seen.putIfAbsent(key, () => _Tx.residenceName(t));
    }
    final list = seen.entries.map((e) => (e.key, e.value)).toList()
      ..sort((a, b) => a.$2.compareTo(b.$2));
    return list;
  }

  String _resKey(Map t) {
    final id = _Tx.residenceId(t);
    return id.isEmpty ? _Tx.residenceName(t) : id;
  }

  Iterable<Map<String, dynamic>> get _inResidence => _residence.isEmpty
      ? _charges
      : _charges.where((t) => _resKey(t) == _residence);

  bool _matchesSearch(Map t) {
    final q = _query;
    return q.isEmpty ||
        '${_Tx.payer(t)} ${t['description']} ${_Tx.residenceName(t)} ${_Tx.period(t)}'
            .toLowerCase()
            .contains(q);
  }

  bool _matchesShow(Map t) => switch (_show) {
        _Show.all => true,
        _Show.unpaid => !Charges.isPaid(t),
        _Show.paid => Charges.isPaid(t),
      };

  Future<void> _setStatus(List<String> ids, bool paid) async {
    if (ids.isEmpty || _busy) return;
    final status = paid ? 'Payé' : 'Impayé';
    setState(() => _busy = true);
    var done = 0;
    try {
      for (final id in ids) {
        await _api.updateTransaction(id: id, payload: {'status': status});
        done++;
        if (!mounted) return;
        setState(() {
          for (final t in _charges) {
            if (_Tx.id(t) == id) t['status'] = status;
          }
        });
      }
      if (!mounted) return;
      showAdminToast(
          context,
          ids.length == 1
              ? (paid ? 'Charge marquée payée' : 'Charge marquée impayée')
              : '$done charges marquées ${paid ? 'payées' : 'impayées'}');
      setState(_selected.clear);
    } catch (e) {
      if (mounted) {
        // Une serie interrompue : on dit combien sont passees, et seules
        // celles qui restent a traiter demeurent selectionnees.
        setState(() => _selected.removeAll(ids.take(done)));
        final reason = e.toString().replaceAll('Exception: ', '');
        showAdminToast(
            context,
            done > 0
                ? '$done sur ${ids.length} mises à jour — $reason'
                : reason,
            error: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toggle(String id) {
    if (id.isEmpty) return;
    GiHaptics.select();
    setState(() =>
        _selected.contains(id) ? _selected.remove(id) : _selected.add(id));
  }

  void _openCharge(Map<String, dynamic> t) {
    final c = GiColors.of(context);
    final paid = Charges.isPaid(t);
    final color = _statusColor(t);
    Widget line(String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 110,
                child: Text(label,
                    style: FigText.body.copyWith(color: c.textMuted)),
              ),
              Expanded(
                child: Text(value.isEmpty ? '—' : value,
                    textAlign: TextAlign.end,
                    style: FigText.bodyActive.copyWith(color: c.textBody)),
              ),
            ],
          ),
        );

    showAdminSheet<void>(
      context,
      title: _Tx.payer(t).isEmpty ? 'Charge' : _Tx.payer(t),
      subtitle: (t['description'] ?? '').toString(),
      builder: (sheet) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GiCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(_fmt(Charges.amount(t)),
                          style: FigText.greeting.copyWith(color: c.textBody)),
                    ),
                    AdminPill(_statusLabel(t), color,
                        icon: Icons.circle, dense: true),
                  ],
                ),
                const SizedBox(height: FigSpace.md),
                Divider(height: 1, color: c.innerBorder),
                line('Période', _Tx.period(t)),
                line('Résidence', _Tx.residenceName(t)),
                if ((t['email'] ?? '').toString().isNotEmpty)
                  line('E-mail', t['email'].toString()),
              ],
            ),
          ),
          const SizedBox(height: FigSpace.xl),
          paid
              ? AdminGhostButton(
                  label: 'Marquer impayée',
                  icon: Icons.undo_rounded,
                  color: FigAlert.error,
                  onTap: () {
                    Navigator.pop(sheet);
                    _setStatus([_Tx.id(t)], false);
                  })
              : AdminSolidButton(
                  label: 'Marquer payée',
                  icon: Icons.check_rounded,
                  color: FigAlert.success,
                  foreground: Colors.white,
                  onTap: () {
                    Navigator.pop(sheet);
                    _setStatus([_Tx.id(t)], true);
                  }),
        ],
      ),
    );
  }

  Color _statusColor(Map t) => Charges.isPaid(t)
      ? FigAlert.success
      : (_Tx.late(t) ? FigAlert.error : FigBrand.amber);

  String _statusLabel(Map t) =>
      Charges.isPaid(t) ? 'Payée' : (_Tx.late(t) ? 'En retard' : 'Impayée');

  // ─── Build ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    final top = MediaQuery.paddingOf(context).top > 0 ? 14.0 : 24.0;
    final selecting = _selected.isNotEmpty;

    final scope = _inResidence.where(_matchesSearch).toList();
    final list = scope.where(_matchesShow).toList();
    // Impayees : les plus anciennes d'abord, ce sont elles qu'on relance.
    if (_show == _Show.unpaid) {
      final reversed = list.reversed.toList();
      list
        ..clear()
        ..addAll(reversed);
    }
    _appear.reset('$_residence$_show');

    // Sur « Toutes », la liste se range par residence.
    final rows = <Object>[];
    if (_residence.isEmpty) {
      final groups = <String, List<Map<String, dynamic>>>{};
      for (final t in list) {
        groups.putIfAbsent(_resKey(t), () => []).add(t);
      }
      final keys = groups.keys.toList()
        ..sort((a, b) => _owed(groups[b]!).compareTo(_owed(groups[a]!)));
      for (final k in keys) {
        rows.add((k, groups[k]!));
        rows.addAll(groups[k]!);
      }
    } else {
      rows.addAll(list);
    }

    // Retour avec une selection : on la quitte d'abord, comme sur iOS.
    return PopScope(
      canPop: !selecting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && selecting) setState(_selected.clear);
      },
      child: Scaffold(
      backgroundColor: c.scaffold,
      body: Stack(
        children: [
          GiScrollBlur(
            child: _loading
                ? Padding(
                    padding: EdgeInsets.fromLTRB(
                        FigSpace.pagePadding, top, FigSpace.pagePadding, 0),
                    child: const Column(children: [
                      AdminPageHeader(back: true, title: 'Paiements'),
                      SizedBox(height: FigSpace.xl),
                      Expanded(
                          child: GiSkeletonList(
                              hero: true, padding: EdgeInsets.zero)),
                    ]),
                  )
                : CustomScrollView(
                    clipBehavior: Clip.none,
                    physics: giRefreshPhysics,
                    slivers: [
                      GiRefreshControl(onRefresh: _load),
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                            FigSpace.pagePadding, top, FigSpace.pagePadding, 0),
                        sliver: SliverToBoxAdapter(
                          child: AdminContent(
                            maxWidth: 820,
                            child: _head(scope),
                          ),
                        ),
                      ),
                      if (_error.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(FigSpace.pagePadding),
                            child: GiCard(
                              child: AdminLoadError(
                                message: _error,
                                onRetry: () {
                                  setState(() => _loading = true);
                                  _load();
                                },
                              ),
                            ),
                          ),
                        )
                      else if (rows.isEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(FigSpace.pagePadding),
                            child: GiCard(
                              child: AdminEmpty(
                                icon: _show == _Show.unpaid
                                    ? Icons.task_alt_rounded
                                    : Icons.receipt_long_outlined,
                                title: _show == _Show.unpaid &&
                                        _search.text.isEmpty
                                    ? 'Tout est encaissé'
                                    : 'Aucune charge',
                                message: _show == _Show.unpaid &&
                                        _search.text.isEmpty
                                    ? 'Aucune charge impayée ici.'
                                    : 'Aucune charge ne correspond à ces filtres.',
                              ),
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                              FigSpace.pagePadding,
                              0,
                              FigSpace.pagePadding,
                              MediaQuery.paddingOf(context).bottom +
                                  (selecting ? 120 : 40)),
                          sliver: SliverList.builder(
                            itemCount: rows.length,
                            itemBuilder: (context, i) {
                              final row = rows[i];
                              return AdminContent(
                                maxWidth: 820,
                                child:
                                    row is (String, List<Map<String, dynamic>>)
                                        ? _groupHeader(row.$2, first: i == 0)
                                        : Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: FigSpace.md),
                                            child: _appear.wrap(
                                                i,
                                                _chargeRow(row
                                                    as Map<String, dynamic>)),
                                          ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
          ),
          // Barre d'actions de la selection.
          AnimatedPositioned(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            left: FigSpace.pagePadding,
            right: FigSpace.pagePadding,
            bottom:
                selecting ? MediaQuery.paddingOf(context).bottom + 16 : -120,
            child: _selectionBar(),
          ),
        ],
      ),
      ),
    );
  }

  int _owed(List<Map> list) => list
      .where((t) => !Charges.isPaid(t))
      .fold(0, (s, t) => s + Charges.amount(t));

  Widget _head(List<Map<String, dynamic>> scope) {
    final c = GiColors.of(context);
    final owed = _owed(scope);
    final collected =
        scope.where(Charges.isPaid).fold(0, (s, t) => s + Charges.amount(t));
    final total = owed + collected;
    final rate = total == 0 ? 1.0 : collected / total;
    final unpaidCount = scope.where((t) => !Charges.isPaid(t)).length;
    final lateCount = scope.where(_Tx.late).length;
    final residences = _residences;
    final stateColor = owed == 0
        ? FigAlert.success
        : (lateCount > 0 ? FigAlert.error : FigBrand.amber);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminPageHeader(
          back: true,
          title: 'Paiements',
          subtitle:
              '${_charges.length} charge${_charges.length > 1 ? 's' : ''} · ${residences.length} résidence${residences.length > 1 ? 's' : ''}',
        ),
        const SizedBox(height: FigSpace.xl),
        // Le resume, comme la carte du haut des Paiements du resident.
        GiAppear(
          child: GiCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('Reste à encaisser',
                          style: FigText.body.copyWith(color: c.textMuted)),
                    ),
                    AdminPill(
                        owed == 0
                            ? 'À jour'
                            : '$unpaidCount impayée${unpaidCount > 1 ? 's' : ''}',
                        stateColor,
                        icon: Icons.circle,
                        dense: true),
                  ],
                ),
                const SizedBox(height: FigSpace.xs),
                Text(_fmt(owed),
                    style: FigText.greeting
                        .copyWith(color: owed == 0 ? c.textBody : stateColor)),
                if (lateCount > 0) ...[
                  const SizedBox(height: 2),
                  Text('dont $lateCount en retard',
                      style: FigText.body.copyWith(color: FigAlert.error)),
                ],
                const SizedBox(height: FigSpace.lg),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: rate),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, __) => LinearProgressIndicator(
                      value: v,
                      minHeight: 7,
                      backgroundColor: c.innerBorder,
                      color: FigAlert.success,
                    ),
                  ),
                ),
                const SizedBox(height: FigSpace.lg),
                Row(
                  children: [
                    Expanded(
                        child: _figure(
                            'Encaissé', _fmt(collected), FigAlert.success)),
                    Container(width: 1, height: 34, color: c.innerBorder),
                    const SizedBox(width: FigSpace.lg),
                    Expanded(
                        child: _figure('Recouvrement',
                            '${(rate * 100).round()} %', c.textBody)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: FigSpace.xl),
        // Choix de la residence.
        if (residences.length > 1) ...[
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              physics: const BouncingScrollPhysics(),
              children: [
                AdminFilterChip(
                    label: 'Toutes',
                    selected: _residence.isEmpty,
                    onTap: () => setState(() {
                          _residence = '';
                          _selected.clear();
                        })),
                for (final r in residences) ...[
                  const SizedBox(width: 8),
                  AdminFilterChip(
                    label: r.$2.isEmpty ? 'Sans résidence' : r.$2,
                    dot: _charges.any(
                            (t) => _resKey(t) == r.$1 && !Charges.isPaid(t))
                        ? FigBrand.amber
                        : FigAlert.success,
                    selected: _residence == r.$1,
                    onTap: () => setState(() {
                      _residence = r.$1;
                      _selected.clear();
                    }),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: FigSpace.md),
        ],
        // Impayes / payes : un selecteur en trois parts egales, toujours
        // entier a l'ecran, plutot que des puces qui debordaient.
        _showSwitch(scope),
        const SizedBox(height: FigSpace.lg),
        AdminSearchField(
            controller: _search, hint: 'Résident, période, libellé…'),
        const SizedBox(height: FigSpace.xl),
      ],
    );
  }

  Widget _showSwitch(List<Map<String, dynamic>> scope) {
    final c = GiColors.of(context);
    int count(_Show s) => scope
        .where((t) => switch (s) {
              _Show.all => true,
              _Show.unpaid => !Charges.isPaid(t),
              _Show.paid => Charges.isPaid(t),
            })
        .length;
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.fieldBg,
        border: Border.all(color: c.fieldBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (final s in _Show.values)
            Expanded(
              child: GiPressable(
                pressedScale: 0.96,
                onTap: () {
                  if (_show != s) GiHaptics.select();
                  // Une selection cachee par le filtre serait soldee sans
                  // qu'on la voie : on la quitte en changeant de vue.
                  setState(() {
                    if (_show != s) _selected.clear();
                    _show = s;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _show == s ? c.card : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: _show == s
                        ? [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 6,
                                offset: const Offset(0, 2)),
                          ]
                        : null,
                  ),
                  child: Text(
                    '${switch (s) {
                      _Show.all => 'Toutes',
                      _Show.unpaid => 'Impayées',
                      _Show.paid => 'Payées',
                    }} · ${count(s)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FigText.body.copyWith(
                        fontWeight:
                            _show == s ? FontWeight.w600 : FontWeight.w400,
                        color: _show == s
                            ? (s == _Show.paid
                                ? FigAlert.success
                                : (s == _Show.unpaid
                                    ? FigBrand.amber
                                    : c.textBody))
                            : c.textMuted),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _figure(String label, String value, Color color) {
    final c = GiColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: FigText.label.copyWith(color: c.textMuted)),
        const SizedBox(height: 2),
        Text(value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: FigText.statValue.copyWith(color: color)),
      ],
    );
  }

  Widget _groupHeader(List<Map<String, dynamic>> group, {required bool first}) {
    final c = GiColors.of(context);
    final name = _Tx.residenceName(group.first);
    final owed = _owed(group);
    return Padding(
      padding:
          EdgeInsets.only(top: first ? 0 : FigSpace.lg, bottom: FigSpace.md),
      child: Row(
        children: [
          Icon(Icons.apartment_rounded, size: 18, color: c.textMuted),
          const SizedBox(width: FigSpace.sm),
          Expanded(
            child: Text(name.isEmpty ? 'Sans résidence' : name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    FigText.titleMd.copyWith(fontSize: 16, color: c.textBody)),
          ),
          if (owed > 0)
            Text(_fmt(owed),
                style: FigText.bodyActive.copyWith(color: FigBrand.amber)),
        ],
      ),
    );
  }

  Widget _chargeRow(Map<String, dynamic> t) {
    final c = GiColors.of(context);
    final id = _Tx.id(t);
    final selected = _selected.contains(id);
    final color = _statusColor(t);
    final paid = Charges.isPaid(t);
    final payer = _Tx.payer(t);
    final sub = [
      _Tx.period(t),
      if (_residence.isNotEmpty || payer.isEmpty)
        (t['description'] ?? '').toString(),
    ].where((s) => s.trim().isNotEmpty).join(' · ');

    return GiPressable(
      pressedScale: 0.98,
      onTap: () => _selected.isNotEmpty ? _toggle(id) : _openCharge(t),
      onLongPress: () => _toggle(id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? FigBrand.amber.withValues(alpha: 0.08) : c.card,
          border: Border.all(color: selected ? FigBrand.amber : c.cardBorder),
          borderRadius: BorderRadius.circular(FigRadius.card),
        ),
        child: Row(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Container(
                key: ValueKey(selected),
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color:
                      selected ? FigBrand.amber : color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                    selected
                        ? Icons.check_rounded
                        : (paid
                            ? Icons.check_circle_outline_rounded
                            : Icons.schedule_rounded),
                    size: 20,
                    color: selected ? Colors.black : color),
              ),
            ),
            const SizedBox(width: FigSpace.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      payer.isEmpty
                          ? (t['description'] ?? 'Charge').toString()
                          : payer,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: FigText.fieldLabel.copyWith(
                          fontWeight: FontWeight.w600, color: c.textBody)),
                  if (sub.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(sub,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: FigText.label.copyWith(color: c.textMuted)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: FigSpace.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_fmt(Charges.amount(t)),
                    style: FigText.bodyActive.copyWith(color: c.textBody)),
                const SizedBox(height: 4),
                Text(_statusLabel(t),
                    style: FigText.caption.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _selectionBar() {
    final c = GiColors.of(context);
    final ids = _selected.toList();
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: c.card,
        border: Border.all(color: c.cardBorder),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 24,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          AdminSquareButton(
            tooltip: 'Annuler',
            onTap: () => setState(_selected.clear),
            child: Icon(Icons.close_rounded, size: 20, color: c.textBody),
          ),
          const SizedBox(width: FigSpace.md),
          Expanded(
            child: Text(
                '${ids.length} sélectionnée${ids.length > 1 ? 's' : ''}',
                style: FigText.bodyActive.copyWith(color: c.textBody)),
          ),
          AdminSquareButton(
            tooltip: 'Marquer impayées',
            onTap: _busy ? null : () => _setStatus(ids, false),
            child:
                const Icon(Icons.undo_rounded, size: 20, color: FigAlert.error),
          ),
          const SizedBox(width: FigSpace.md),
          AdminSolidButton(
            label: 'Payées',
            icon: Icons.check_rounded,
            color: FigAlert.success,
            foreground: Colors.white,
            onTap: _busy ? null : () => _setStatus(ids, true),
          ),
        ],
      ),
    );
  }
}
