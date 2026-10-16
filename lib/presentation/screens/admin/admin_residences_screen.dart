import 'package:flutter/material.dart';

import '../../../data/api_service.dart';
import '../../theme/design_tokens.dart';
import '../../theme/gi_colors.dart';
import '../../theme/ticket_status.dart';
import '../../widgets/gi_appear.dart';
import '../../widgets/gi_refresh.dart';
import '../../widgets/gi_residence_card.dart';
import '../../widgets/gi_skeleton.dart';
import 'admin_residence_screen.dart';
import 'admin_store.dart';
import 'admin_ui.dart';
import '../../widgets/gi_scroll_blur.dart';

/// Carte de residence de l'administration : la carte de l'accueil resident,
/// avec dans le bandeau ce qui interesse le gestionnaire.
Widget adminResidenceCard(
    BuildContext context, AdminStore store, Map<String, dynamic> r,
    {VoidCallback? onTap}) {
  final id = (r['id'] ?? '').toString();
  final tickets = store.ticketsOf(id);
  final active = tickets.where((t) => ticketStage(t['status']).isActive).length;
  final urgent = tickets
      .where((t) =>
          ticketStage(t['status']).isActive &&
          ticketPriority(t['priority']) == TicketPriority.urgent)
      .length;
  final units = r['totalUnits'];
  final occupancy = (r['occupancyRate'] ?? '').toString();
  final zone = (r['zone'] ?? '').toString().trim();

  return GiResidenceCard(
    id: id,
    name: (r['name'] ?? '').toString(),
    address: (r['address'] ?? '').toString(),
    imageUrl: ApiService().mediaUrl(r['image']),
    eyebrow: zone.isEmpty ? 'Résidence' : 'Zone $zone',
    badge: urgent > 0
        ? '$urgent urgent${urgent > 1 ? 's' : ''}'
        : (active > 0 ? '$active à traiter' : null),
    badgeColor: urgent > 0 ? FigAlert.error : FigBrand.amber,
    onTap: onTap,
    stats: [
      GiResidenceStat('À traiter', '$active',
          color: active > 0 ? FigBrand.amber : FigAlert.success),
      GiResidenceStat('Tickets', '${tickets.length}'),
      if (units != null)
        GiResidenceStat('Unités', '$units')
      else if (occupancy.isNotEmpty)
        GiResidenceStat('Occupation', occupancy),
    ],
  );
}

/// Liste des residences, onglet de la barre de navigation.
class AdminResidencesScreen extends StatefulWidget {
  final AdminStore store;
  const AdminResidencesScreen({super.key, required this.store});

  @override
  State<AdminResidencesScreen> createState() => _AdminResidencesScreenState();
}

class _AdminResidencesScreenState extends State<AdminResidencesScreen> {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) => _build(context),
    );
  }

  Widget _build(BuildContext context) {
    final c = GiColors.of(context);
    final store = widget.store;
    final q = _search.text.trim().toLowerCase();
    final list = store.residences
        .where((r) =>
            q.isEmpty ||
            '${r['name']} ${r['address']} ${r['zone']}'
                .toLowerCase()
                .contains(q))
        .toList()
      // Les residences qui ont le plus a traiter passent en tete.
      ..sort((a, b) {
        int load(Map r) => store
            .ticketsOf((r['id'] ?? '').toString())
            .where((t) => ticketStage(t['status']).isActive)
            .length;
        return load(b).compareTo(load(a));
      });
    final top = MediaQuery.paddingOf(context).top > 0 ? 14.0 : 24.0;

    return Scaffold(
      backgroundColor: c.scaffold,
      body: GiScrollBlur(
        child: CustomScrollView(
          clipBehavior: Clip.none,
          physics: giRefreshPhysics,
          slivers: [
            GiRefreshControl(onRefresh: store.load),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                  FigSpace.pagePadding, top, FigSpace.pagePadding, 150),
              sliver: SliverToBoxAdapter(
                child: AdminContent(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AdminPageHeader(
                        title: 'Résidences',
                        large: true,
                        subtitle: store.loading
                            ? 'Chargement…'
                            : '${store.residences.length} résidence${store.residences.length > 1 ? 's' : ''} gérée${store.residences.length > 1 ? 's' : ''}',
                      ),
                      if (store.residences.length > 3) ...[
                        const SizedBox(height: FigSpace.xl),
                        AdminSearchField(
                            controller: _search, hint: 'Nom, adresse, zone…'),
                      ],
                      const SizedBox(height: FigSpace.xl),
                      if (store.loading)
                        const GiSkeletonList(
                            hero: true, count: 2, padding: EdgeInsets.zero)
                      else if (list.isEmpty)
                        AdminEmpty(
                          icon: Icons.apartment_rounded,
                          title:
                              q.isEmpty ? 'Aucune résidence' : 'Aucun résultat',
                          message: q.isEmpty
                              ? 'Aucune résidence n\'est rattachée à votre compte.'
                              : 'Aucune résidence ne correspond à « ${_search.text} ».',
                        )
                      else
                        AdminGrid(
                          minTileWidth: 360,
                          spacing: FigSpace.xl,
                          children: [
                            for (var i = 0; i < list.length; i++)
                              GiAppear(
                                index: i.clamp(0, 8),
                                child: adminResidenceCard(
                                  context,
                                  store,
                                  list[i],
                                  onTap: () => adminPush(
                                    context,
                                    AdminResidenceScreen(
                                        store: store,
                                        residenceId:
                                            (list[i]['id'] ?? '').toString()),
                                  ),
                                ),
                              ),
                          ],
                        ),
                    ],
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
