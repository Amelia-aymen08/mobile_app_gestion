import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/design_tokens.dart';
import '../../theme/gi_colors.dart';
import '../../theme/ticket_status.dart';
import '../../widgets/gi_appear.dart';
import '../../widgets/gi_card.dart';
import '../../widgets/gi_pressable.dart';
import '../../widgets/gi_refresh.dart';
import '../../widgets/gi_skeleton.dart';
import 'admin_residence_screen.dart';
import 'admin_store.dart';
import 'admin_ticket_screen.dart';
import 'admin_ui.dart';

/// Lecture des champs d'un resident, tels que `/owners` les renvoie.
abstract final class ResidentFields {
  static String name(Map r) {
    final full = '${r['firstName'] ?? ''} ${r['lastName'] ?? ''}'.trim();
    if (full.isNotEmpty) return full;
    return (r['name'] ?? r['fullName'] ?? 'Résident').toString();
  }

  static String email(Map r) => (r['email'] ?? '').toString().trim();
  static String phone(Map r) => (r['phone'] ?? r['telephone'] ?? '').toString();

  static String residenceName(Map r) {
    final res = r['residence'] ?? r['Residence'];
    return res is Map ? (res['name'] ?? '').toString() : '';
  }

  static String residenceId(Map r) {
    final res = r['residence'] ?? r['Residence'];
    return (r['residenceId'] ?? (res is Map ? res['id'] : '') ?? '').toString();
  }

  /// « Bloc B · Étage 3 · Porte 12 », sans les morceaux absents.
  static String unit(Map r) {
    final block = (r['block'] ?? '').toString().trim();
    final floor = (r['floor'] ?? '').toString().trim();
    final door = (r['doorNumber'] ?? r['door'] ?? '').toString().trim();
    return [
      if (block.isNotEmpty) 'Bloc $block',
      if (floor.isNotEmpty) 'Étage $floor',
      if (door.isNotEmpty) 'Porte $door',
    ].join(' · ');
  }

  static String initials(String name) => name
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .take(2)
      .map((w) => w[0].toUpperCase())
      .join();
}

/// Tickets ouverts par un resident : on les reconnait a son adresse.
List<Map<String, dynamic>> ticketsOfResident(AdminStore store, Map r) {
  final email = ResidentFields.email(r).toLowerCase();
  final name = ResidentFields.name(r).toLowerCase();
  return store.tickets.where((t) {
    final te = (t['email'] ?? '').toString().toLowerCase();
    if (email.isNotEmpty && te == email) return true;
    return email.isEmpty &&
        TicketFields.requester(t).toLowerCase() == name &&
        name.isNotEmpty;
  }).toList();
}

/// Ligne de resident : initiales, nom, logement, et ses tickets en cours.
Widget adminResidentRow(BuildContext context, AdminStore store, Map r,
    {bool showResidence = true}) {
  final c = GiColors.of(context);
  final name = ResidentFields.name(r);
  final active = ticketsOfResident(store, r)
      .where((t) => ticketStage(t['status']).isActive)
      .length;
  final sub = [
    if (showResidence && ResidentFields.residenceName(r).isNotEmpty)
      ResidentFields.residenceName(r),
    if (ResidentFields.unit(r).isNotEmpty) ResidentFields.unit(r),
  ].join(' · ');

  return GiPressable(
    pressedScale: 0.98,
    onTap: () => adminPush(
        context,
        AdminResidentScreen(
            store: store, resident: Map<String, dynamic>.from(r))),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: FigBrand.amber.withValues(alpha: 0.13),
              shape: BoxShape.circle,
            ),
            child: Text(ResidentFields.initials(name),
                style: FigText.label.copyWith(
                    fontWeight: FontWeight.w700, color: FigBrand.amber)),
          ),
          const SizedBox(width: FigSpace.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
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
          if (active > 0) ...[
            const SizedBox(width: FigSpace.md),
            AdminPill('$active', FigBrand.amber,
                icon: Icons.confirmation_number_outlined, dense: true),
          ],
          const SizedBox(width: FigSpace.md),
          GiChevron(color: c.textFaint),
        ],
      ),
    ),
  );
}

/// Liste des residents, avec recherche et filtre par residence.
class AdminResidentsScreen extends StatefulWidget {
  final AdminStore store;
  final String residenceId;
  const AdminResidentsScreen(
      {super.key, required this.store, this.residenceId = ''});

  @override
  State<AdminResidentsScreen> createState() => _AdminResidentsScreenState();
}

class _AdminResidentsScreenState extends State<AdminResidentsScreen> {
  final _search = TextEditingController();
  List<Map<String, dynamic>>? _all;
  String? _error;
  late String _residence = widget.residenceId;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load({bool refresh = false}) async {
    try {
      final list = await widget.store.residents(refresh: refresh);
      if (mounted) setState(() => _all = list);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  bool _inResidence(Map r) {
    if (_residence.isEmpty) return true;
    final id = ResidentFields.residenceId(r);
    if (id.isNotEmpty) return id == _residence;
    final name = (widget.store.residence(_residence)?['name'] ?? '').toString();
    return ResidentFields.residenceName(r).toLowerCase() == name.toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    final q = _search.text.trim().toLowerCase();
    final list = (_all ?? const <Map<String, dynamic>>[])
        .where(_inResidence)
        .where((r) =>
            q.isEmpty ||
            [
              ResidentFields.name(r),
              ResidentFields.email(r),
              ResidentFields.residenceName(r),
              ResidentFields.unit(r),
            ].join(' ').toLowerCase().contains(q))
        .toList()
      ..sort(
          (a, b) => ResidentFields.name(a).compareTo(ResidentFields.name(b)));
    final top = MediaQuery.paddingOf(context).top > 0 ? 14.0 : 24.0;
    final residences = widget.store.residences;

    return Scaffold(
      backgroundColor: c.scaffold,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: giRefreshPhysics,
          slivers: [
            GiRefreshControl(onRefresh: () => _load(refresh: true)),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                    FigSpace.pagePadding, top, FigSpace.pagePadding, 0),
                child: AdminContent(
                  maxWidth: 820,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AdminPageHeader(
                        back: true,
                        title: 'Résidents',
                        subtitle: _all == null
                            ? 'Chargement…'
                            : '${list.length} résident${list.length > 1 ? 's' : ''}',
                      ),
                      const SizedBox(height: FigSpace.xl),
                      AdminSearchField(
                          controller: _search, hint: 'Nom, e-mail, logement…'),
                    ],
                  ),
                ),
              ),
            ),
            if (residences.length > 1)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: FigSpace.lg),
                  child: SizedBox(
                    height: 34,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: FigSpace.pagePadding),
                      children: [
                        for (final (id, name) in [
                          ('', 'Toutes'),
                          for (final r in residences)
                            (
                              (r['id'] ?? '').toString(),
                              (r['name'] ?? '').toString()
                            ),
                        ]) ...[
                          AdminFilterChip(
                            label: name,
                            selected: id == _residence,
                            onTap: () => setState(() => _residence = id),
                          ),
                          const SizedBox(width: FigSpace.md),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                  FigSpace.pagePadding,
                  FigSpace.xl,
                  FigSpace.pagePadding,
                  MediaQuery.paddingOf(context).bottom + 40),
              sliver: SliverToBoxAdapter(
                child: AdminContent(
                  maxWidth: 820,
                  child: _all == null && _error == null
                      ? const GiSkeletonList(
                          itemHeight: 76, padding: EdgeInsets.zero)
                      : list.isEmpty
                          ? AdminEmpty(
                              icon: Icons.people_outline_rounded,
                              title: _error != null
                                  ? 'Liste indisponible'
                                  : 'Aucun résident',
                              message: _error ??
                                  (q.isEmpty
                                      ? 'Aucun résident inscrit ici.'
                                      : 'Aucun résident ne correspond à « ${_search.text} ».'),
                            )
                          : GiAppear(
                              child: GiCard(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Column(
                                  children: [
                                    for (var i = 0; i < list.length; i++) ...[
                                      if (i > 0)
                                        Divider(
                                            height: 1,
                                            color: c.innerBorder,
                                            indent: 64),
                                      adminResidentRow(
                                          context, widget.store, list[i],
                                          showResidence: _residence.isEmpty),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fiche d'un resident : coordonnees, logement et ses tickets.
class AdminResidentScreen extends StatelessWidget {
  final AdminStore store;
  final Map<String, dynamic> resident;
  const AdminResidentScreen(
      {super.key, required this.store, required this.resident});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => _build(context),
    );
  }

  Widget _build(BuildContext context) {
    final c = GiColors.of(context);
    final r = resident;
    final name = ResidentFields.name(r);
    final email = ResidentFields.email(r);
    final phone = ResidentFields.phone(r);
    final residenceName = ResidentFields.residenceName(r);
    final residenceId = ResidentFields.residenceId(r).isNotEmpty
        ? ResidentFields.residenceId(r)
        : (store.residences.firstWhere(
                    (x) =>
                        (x['name'] ?? '').toString().toLowerCase() ==
                        residenceName.toLowerCase(),
                    orElse: () => const {})['id'] ??
                '')
            .toString();
    final unit = ResidentFields.unit(r);
    final tickets = ticketsOfResident(store, r);
    final active = tickets.where((t) => ticketStage(t['status']).isActive);
    final top = MediaQuery.paddingOf(context).top > 0 ? 14.0 : 24.0;

    Widget info(IconData icon, String label, String value,
        {VoidCallback? onTap, IconData? action}) {
      final row = Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 19, color: c.textMuted),
            const SizedBox(width: FigSpace.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: FigText.label.copyWith(color: c.textFaint)),
                  const SizedBox(height: 2),
                  Text(value,
                      style: FigText.fieldLabel.copyWith(
                          fontWeight: FontWeight.w500,
                          color: onTap != null && action == null
                              ? FigBrand.amber
                              : c.textBody)),
                ],
              ),
            ),
            if (action != null)
              Icon(action, size: 17, color: c.textMuted)
            else if (onTap != null)
              const GiChevron(color: FigBrand.amber),
          ],
        ),
      );
      return onTap == null
          ? row
          : GiPressable(pressedScale: 0.98, onTap: onTap, child: row);
    }

    void copy(String v, String what) {
      Clipboard.setData(ClipboardData(text: v));
      showAdminToast(context, '$what copié');
    }

    final infos = <Widget>[
      if (email.isNotEmpty)
        info(Icons.mail_outline_rounded, 'E-mail', email,
            onTap: () => copy(email, 'E-mail'), action: Icons.copy_rounded),
      if (phone.isNotEmpty)
        info(Icons.phone_outlined, 'Téléphone', phone,
            onTap: () => copy(phone, 'Numéro'), action: Icons.copy_rounded),
      if (residenceName.isNotEmpty)
        info(Icons.apartment_rounded, 'Résidence', residenceName,
            onTap: residenceId.isEmpty
                ? null
                : () => adminPush(
                    context,
                    AdminResidenceScreen(
                        store: store, residenceId: residenceId))),
      if (unit.isNotEmpty)
        info(Icons.door_front_door_outlined, 'Logement', unit),
    ];

    return Scaffold(
      backgroundColor: c.scaffold,
      body: SafeArea(
        bottom: false,
        child: AdminContent(
          maxWidth: 820,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
                FigSpace.pagePadding,
                top,
                FigSpace.pagePadding,
                MediaQuery.paddingOf(context).bottom + 40),
            children: [
              const AdminPageHeader(back: true, title: 'Résident'),
              const SizedBox(height: FigSpace.xl),
              GiCard(
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: FigBrand.amber.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: FigBrand.amber.withValues(alpha: 0.5)),
                      ),
                      child: Text(ResidentFields.initials(name),
                          style: FigText.titleMd
                              .copyWith(color: FigBrand.amber)),
                    ),
                    const SizedBox(width: FigSpace.xl),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style: FigText.titleMd
                                  .copyWith(fontSize: 19, color: c.textBody)),
                          const SizedBox(height: 4),
                          Text(
                              '${active.length} ticket${active.length > 1 ? 's' : ''} en cours · ${tickets.length} au total',
                              style:
                                  FigText.body.copyWith(color: c.textMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (infos.isNotEmpty) ...[
                const SizedBox(height: FigSpace.lg),
                GiCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Column(
                    children: [
                      for (var i = 0; i < infos.length; i++) ...[
                        if (i > 0) Divider(height: 1, color: c.innerBorder),
                        infos[i],
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: FigSpace.xl + 4),
              AdminSectionTitle('Ses tickets', count: '${tickets.length}'),
              const SizedBox(height: FigSpace.lg),
              if (tickets.isEmpty)
                const GiCard(
                  child: AdminEmpty(
                    icon: Icons.task_alt_rounded,
                    title: 'Aucun ticket',
                    message: 'Ce résident n\'a encore rien signalé.',
                  ),
                )
              else
                for (var i = 0; i < tickets.length; i++) ...[
                  if (i > 0) const SizedBox(height: FigSpace.lg),
                  AdminTicketCard(
                    ticket: tickets[i],
                    residenceName: store.residenceNameOf(tickets[i]),
                    onTap: () => openAdminTicket(context, store, tickets[i]),
                  ),
                ],
            ],
          ),
        ),
      ),
    );
  }
}
