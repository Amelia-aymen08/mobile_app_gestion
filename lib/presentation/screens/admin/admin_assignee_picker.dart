import 'package:flutter/material.dart';

import '../../services/gi_haptics.dart';
import '../../theme/design_tokens.dart';
import '../../theme/gi_colors.dart';
import '../../widgets/gi_card.dart';
import '../../widgets/gi_skeleton.dart';
import 'admin_store.dart';
import 'admin_ui.dart';

/// Choix de l'intervenant, sur une page entiere avec recherche.
///
/// Remplace la liste deroulante : avec des dizaines de sous-traitants et
/// d'employes, une liste qu'on ne peut pas filtrer se parcourt a l'aveugle.
/// Les intervenants sont groupes — sous-traitants, puis equipe — et la page
/// renvoie l'option choisie.
class AdminAssigneePicker extends StatefulWidget {
  final AdminStore store;
  final String current;
  const AdminAssigneePicker(
      {super.key, required this.store, required this.current});

  @override
  State<AdminAssigneePicker> createState() => _AdminAssigneePickerState();
}

class _AdminAssigneePickerState extends State<AdminAssigneePicker> {
  final _search = TextEditingController();
  List<AssigneeOption>? _options;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _search.addListener(() {
      final q = _search.text.trim().toLowerCase();
      if (q != _query) setState(() => _query = q);
    });
    _fetch();
  }

  void _fetch() {
    setState(() {
      _options = null;
      _error = null;
    });
    widget.store.assignees().then((v) {
      if (mounted) setState(() => _options = v);
    }).catchError((Object e) {
      if (mounted) setState(() => _error = e.toString());
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    final q = _query;
    final all = _options ?? const <AssigneeOption>[];
    final filtered = all
        .where((o) =>
            q.isEmpty || '${o.name} ${o.detail}'.toLowerCase().contains(q))
        .toList();
    final subs = filtered.where((o) => o.subcontractor).toList();
    final staff = filtered.where((o) => !o.subcontractor).toList();
    final top = MediaQuery.paddingOf(context).top > 0 ? 14.0 : 24.0;

    // Pas de fondu differe : la liste arrive avec la page, prete au choix.
    Widget row(AssigneeOption o) => _row(c, o);

    return Scaffold(
      backgroundColor: c.scaffold,
      body: SafeArea(
        bottom: false,
        child: AdminContent(
          maxWidth: 720,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                    FigSpace.pagePadding, top, FigSpace.pagePadding, 0),
                child: const AdminPageHeader(
                  back: true,
                  title: 'Choisir un intervenant',
                  subtitle: 'Sous-traitants et équipe',
                ),
              ),
              const SizedBox(height: FigSpace.xl),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: FigSpace.pagePadding),
                child: AdminSearchField(
                    controller: _search, hint: 'Nom, métier, zone…'),
              ),
              const SizedBox(height: FigSpace.lg),
              Expanded(
                child: _options == null && _error == null
                    ? const GiSkeletonList(count: 6, itemHeight: 76)
                    : ListView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                            FigSpace.pagePadding,
                            FigSpace.xs,
                            FigSpace.pagePadding,
                            MediaQuery.paddingOf(context).bottom + 32),
                        children: [
                          if (widget.current.isNotEmpty) ...[
                            _row(
                                c,
                                const AssigneeOption(
                                    '',
                                    'Retirer l\'intervenant',
                                    'Le ticket redevient à assigner'),
                                remove: true),
                            const SizedBox(height: FigSpace.xl),
                          ],
                          if (subs.isNotEmpty) ...[
                            AdminSectionTitle('Sous-traitants',
                                count: '${subs.length}'),
                            const SizedBox(height: FigSpace.md),
                            for (final o in subs) ...[
                              row(o),
                              const SizedBox(height: FigSpace.md),
                            ],
                            const SizedBox(height: FigSpace.lg),
                          ],
                          if (staff.isNotEmpty) ...[
                            AdminSectionTitle('Équipe',
                                count: '${staff.length}'),
                            const SizedBox(height: FigSpace.md),
                            for (final o in staff) ...[
                              row(o),
                              const SizedBox(height: FigSpace.md),
                            ],
                          ],
                          // Liste vide sans recherche : le chargement a echoue
                          // (les appels rendent une liste vide en cas
                          // d'erreur). « Aucun nom ne correspond a «  » »
                          // ne voulait rien dire.
                          if (filtered.isEmpty && (all.isEmpty || _error != null))
                            AdminEmpty(
                              icon: Icons.cloud_off_rounded,
                              title: 'Liste indisponible',
                              message:
                                  'La liste des intervenants n\'a pas pu être chargée.',
                              action: 'Réessayer',
                              onAction: _fetch,
                            )
                          else if (filtered.isEmpty)
                            AdminEmpty(
                              icon: Icons.person_search_rounded,
                              title: 'Aucun intervenant',
                              message:
                                  'Aucun nom ne correspond à « ${_search.text.trim()} ».',
                            ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(GiColors c, AssigneeOption o, {bool remove = false}) {
    final selected = !remove && o.value == widget.current;
    final accent = remove
        ? FigAlert.error
        : (o.subcontractor ? FigAccent.blue : FigAccent.violet);
    return GiCard(
      padding: const EdgeInsets.all(12),
      borderColor: selected ? FigBrand.amber : null,
      onTap: () {
        GiHaptics.select();
        Navigator.pop(context, o);
      },
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.13),
              shape: BoxShape.circle,
            ),
            child: remove
                ? Icon(Icons.person_remove_rounded, size: 19, color: accent)
                : Text(_initials(o.name),
                    style: FigText.label
                        .copyWith(fontWeight: FontWeight.w700, color: accent)),
          ),
          const SizedBox(width: FigSpace.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(o.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FigText.fieldLabel.copyWith(
                        fontWeight: FontWeight.w600,
                        color: remove ? FigAlert.error : c.textBody)),
                const SizedBox(height: 2),
                Text(o.detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FigText.label.copyWith(color: c.textMuted)),
              ],
            ),
          ),
          if (selected)
            const Icon(Icons.check_circle_rounded,
                size: 22, color: FigBrand.amber)
          else
            GiChevron(color: c.textFaint),
        ],
      ),
    );
  }

  static String _initials(String name) => name
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .take(2)
      .map((w) => w[0].toUpperCase())
      .join();
}
