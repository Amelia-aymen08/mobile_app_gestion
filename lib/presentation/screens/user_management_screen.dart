import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/api_service.dart';
import '../providers/auth_provider.dart';
import '../theme/design_tokens.dart';
import '../theme/gi_colors.dart';
import '../widgets/gi_card.dart';
import '../widgets/gi_pressable.dart';
import '../widgets/gi_primary_button.dart';
import '../widgets/gi_refresh.dart';
import '../widgets/gi_scroll_blur.dart';
import '../widgets/gi_skeleton.dart';
import 'admin/admin_sheet.dart';
import 'admin/admin_ui.dart';

/// Libelle et couleur de chaque role.
const _roles = {
  'ADMIN': ('Administrateur', FigAlert.error),
  'MANAGER': ('Manager', FigBrand.amber),
  'RESPONSABLE_ZONE': ('Responsable de zone', FigAccent.violet),
  'HSE': ('HSE', Color(0xFF26A69A)),
  'INTERVENANT': ('Intervenant', FigAlert.success),
  'GESTIONNAIRE_TAG': ('Gestionnaire TAG', FigAccent.purple),
  'RECOUVREMENT': ('Recouvrement', Color(0xFFEF8A3C)),
  'RESIDENT': ('Résident', FigAccent.blue),
};

(String, Color) _roleOf(dynamic role) =>
    _roles[(role ?? '').toString()] ??
    ((role ?? '—').toString(), const Color(0xFF8E8E93));

/// Comptes de l'application : employes et residents.
///
/// Une recherche, une rangee de puces par role avec leur nombre, puis les
/// comptes dans une seule carte. Toucher un compte ouvre ses actions —
/// mot de passe, appareils, suppression — dans une feuille du bas, au lieu
/// d'un menu a trois points et de boites de dialogue blanches.
class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final ApiService _api = ApiService();
  final _search = TextEditingController();
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;
  String _error = '';
  String _role = '';
  String _query = '';

  @override
  void initState() {
    super.initState();
    _search.addListener(() {
      final q = _search.text.trim().toLowerCase();
      if (q != _query) setState(() => _query = q);
    });
    _load();
  }

  /// Le compte connecte : on ne lui propose pas de se supprimer lui-meme.
  bool _isMe(Map u) {
    final me = context.read<AuthProvider>().user;
    if (me == null) return false;
    final id = (me['id'] ?? '').toString();
    final email = (me['email'] ?? '').toString().toLowerCase();
    return (id.isNotEmpty && id == (u['id'] ?? '').toString()) ||
        (email.isNotEmpty &&
            email == (u['email'] ?? '').toString().toLowerCase());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final users = await _api.getUsers();
      if (!mounted) return;
      setState(() {
        _users = users
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
          ..sort((a, b) => _name(a).toLowerCase().compareTo(_name(b).toLowerCase()));
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

  static String _name(Map u) {
    final n = (u['name'] ?? u['fullName'] ?? '').toString().trim();
    if (n.isNotEmpty) return n;
    final full = '${u['firstName'] ?? ''} ${u['lastName'] ?? ''}'.trim();
    return full.isEmpty ? (u['email'] ?? 'Utilisateur').toString() : full;
  }

  static String _initials(String name) => name
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .take(2)
      .map((w) => w[0].toUpperCase())
      .join();

  String _err(Object e) => e.toString().replaceAll('Exception: ', '');

  Future<void> _delete(Map u) async {
    final ok = await adminConfirm(
      context,
      title: 'Supprimer ${_name(u)} ?',
      message: 'Le compte et son accès à l\'application seront supprimés. '
          'Cette action est irréversible.',
      confirmLabel: 'Supprimer le compte',
      destructive: true,
    );
    if (ok == null || !mounted) return;
    try {
      await _api.deleteUser(u['id'].toString());
      if (!mounted) return;
      showAdminToast(context, 'Compte supprimé');
      _load();
    } catch (e) {
      if (mounted) showAdminToast(context, _err(e), error: true);
    }
  }

  Future<void> _resetDevices(Map u) async {
    final ok = await adminConfirm(
      context,
      title: 'Réinitialiser les appareils ?',
      message: 'Les appareils enregistrés de ${_name(u)} seront oubliés : '
          'il pourra se reconnecter depuis un nouveau téléphone.',
      confirmLabel: 'Réinitialiser',
    );
    if (ok == null || !mounted) return;
    try {
      await _api.resetUserDevices(u['id'].toString());
      if (mounted) showAdminToast(context, 'Appareils réinitialisés');
    } catch (e) {
      if (mounted) showAdminToast(context, _err(e), error: true);
    }
  }

  Future<void> _changePassword(Map u) async {
    final field = TextEditingController();
    var sending = false;
    final saved = await showAdminSheet<bool>(
      context,
      title: 'Nouveau mot de passe',
      subtitle: 'Pour ${_name(u)}. Communiquez-le lui de vive voix.',
      builder: (sheet) => StatefulBuilder(
        builder: (sheet, setSheet) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AdminField(
              controller: field,
              label: 'Mot de passe',
              hint: '8 caractères minimum',
              obscure: true,
              onChanged: (_) => setSheet(() {}),
            ),
            const SizedBox(height: FigSpace.xl),
            // Meme regle que l'ecran « Changer le mot de passe » : 8
            // caracteres. Le bouton s'allumait des 6, contre l'indication.
            GiPrimaryButton(
              label: 'Enregistrer',
              isLoading: sending,
              onPressed: field.text.length < 8
                  ? null
                  : () async {
                      setSheet(() => sending = true);
                      try {
                        await _api.updateUserPassword(
                            u['id'].toString(), field.text);
                        if (sheet.mounted) Navigator.pop(sheet, true);
                      } catch (e) {
                        if (sheet.mounted) {
                          setSheet(() => sending = false);
                          showAdminToast(sheet, _err(e), error: true);
                        }
                      }
                    },
            ),
          ],
        ),
      ),
    );
    if (saved == true && mounted) {
      showAdminToast(context, 'Mot de passe mis à jour');
    }
  }

  void _actions(Map u) {
    final c = GiColors.of(context);
    final role = _roleOf(u['role']);
    Widget action(IconData icon, String label, VoidCallback onTap,
            {Color? color}) =>
        GiPressable(
          pressedScale: 0.98,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
            child: Row(
              children: [
                Icon(icon, size: 20, color: color ?? c.textBody),
                const SizedBox(width: FigSpace.lg),
                Expanded(
                  child: Text(label,
                      style: FigText.fieldLabel
                          .copyWith(color: color ?? c.textBody)),
                ),
                GiChevron(color: color ?? c.textFaint),
              ],
            ),
          ),
        );

    showAdminSheet<void>(
      context,
      title: _name(u),
      subtitle: (u['email'] ?? '').toString(),
      builder: (sheet) {
        void run(Future<void> Function(Map) f) {
          Navigator.pop(sheet);
          f(u);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminPill(role.$1, role.$2,
                icon: Icons.verified_user_outlined, dense: true),
            const SizedBox(height: FigSpace.lg),
            GiCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              child: Column(
                children: [
                  action(Icons.key_rounded, 'Changer le mot de passe',
                      () => run(_changePassword)),
                  if (u['role'] == 'RESIDENT') ...[
                    Divider(height: 1, color: c.innerBorder),
                    action(Icons.phonelink_erase_rounded,
                        'Réinitialiser les appareils',
                        () => run(_resetDevices)),
                  ],
                  if (!_isMe(u)) ...[
                    Divider(height: 1, color: c.innerBorder),
                    action(Icons.delete_outline_rounded, 'Supprimer le compte',
                        () => run(_delete),
                        color: FigAlert.error),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    final top = MediaQuery.paddingOf(context).top > 0 ? 14.0 : 24.0;
    final q = _query;
    final searched = _users
        .where((u) =>
            q.isEmpty ||
            '${_name(u)} ${u['email']} ${_roleOf(u['role']).$1}'
                .toLowerCase()
                .contains(q))
        .toList();
    final list = searched
        .where((u) => _role.isEmpty || (u['role'] ?? '').toString() == _role)
        .toList();
    // Les roles presents, dans l'ordre du tableau.
    final present = {for (final u in _users) (u['role'] ?? '').toString()};
    final roles = [
      ..._roles.keys.where(present.contains),
      ...present.where((r) => r.isNotEmpty && !_roles.containsKey(r)),
    ];
    final staff = _users.where((u) => u['role'] != 'RESIDENT').length;

    return Scaffold(
      backgroundColor: c.scaffold,
      body: GiScrollBlur(
        child: CustomScrollView(
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AdminPageHeader(
                        back: true,
                        title: 'Employés',
                        subtitle: _loading
                            ? 'Chargement…'
                            : '$staff employé${staff > 1 ? 's' : ''} · ${_users.length - staff} résident${_users.length - staff > 1 ? 's' : ''}',
                      ),
                      const SizedBox(height: FigSpace.xl),
                      AdminSearchField(
                          controller: _search, hint: 'Nom, e-mail, rôle…'),
                      if (roles.length > 1) ...[
                        const SizedBox(height: FigSpace.lg),
                        SizedBox(
                          height: 34,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            clipBehavior: Clip.none,
                            physics: const BouncingScrollPhysics(),
                            children: [
                              AdminFilterChip(
                                  label: 'Tous',
                                  count: searched.length,
                                  selected: _role.isEmpty,
                                  onTap: () => setState(() => _role = '')),
                              for (final r in roles) ...[
                                const SizedBox(width: 8),
                                AdminFilterChip(
                                  label: _roleOf(r).$1,
                                  dot: _roleOf(r).$2,
                                  count: searched
                                      .where((u) => u['role'] == r)
                                      .length,
                                  selected: _role == r,
                                  onTap: () => setState(() => _role = r),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: FigSpace.xl),
                      if (_loading)
                        const GiSkeletonList(padding: EdgeInsets.zero)
                      else if (_error.isNotEmpty)
                        GiCard(
                          child: AdminLoadError(
                              message: _error,
                              onRetry: () {
                                setState(() => _loading = true);
                                _load();
                              }),
                        )
                      else if (list.isEmpty)
                        const GiCard(
                          child: AdminEmpty(
                              icon: Icons.person_search_rounded,
                              title: 'Aucun compte',
                              message: 'Aucun compte ne correspond à ces filtres.'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            // Les comptes, residents compris, peuvent se compter par
            // centaines : la liste ne batit que les lignes a l'ecran.
            if (!_loading && _error.isEmpty && list.isNotEmpty)
              SliverPadding(
                padding: EdgeInsets.fromLTRB(FigSpace.pagePadding, 0,
                    FigSpace.pagePadding, MediaQuery.paddingOf(context).bottom + 40),
                sliver: SliverList.builder(
                  itemCount: list.length,
                  itemBuilder: (context, i) => AdminContent(
                    maxWidth: 820,
                    child: _segment(
                      first: i == 0,
                      last: i == list.length - 1,
                      child: _row(list[i]),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Un morceau de la carte qui regroupe les comptes : la carte entiere
  /// n'existe plus d'un bloc, chaque ligne en dessine sa part.
  Widget _segment(
      {required bool first, required bool last, required Widget child}) {
    final c = GiColors.of(context);
    const r = Radius.circular(FigRadius.card);
    final radius = BorderRadius.vertical(
        top: first ? r : Radius.zero, bottom: last ? r : Radius.zero);
    return Container(
      padding: EdgeInsets.fromLTRB(1, first ? 1 : 0, 1, last ? 1 : 0),
      decoration: BoxDecoration(color: c.cardBorder, borderRadius: radius),
      child: Container(
        padding: EdgeInsets.only(top: first ? 4 : 0, bottom: last ? 4 : 0),
        decoration: BoxDecoration(color: c.card, borderRadius: radius),
        child: Column(
          children: [
            if (!first) Divider(height: 1, indent: 66, color: c.innerBorder),
            child,
          ],
        ),
      ),
    );
  }

  Widget _row(Map<String, dynamic> u) {
    final c = GiColors.of(context);
    final role = _roleOf(u['role']);
    final name = _name(u);
    return GiPressable(
      pressedScale: 0.98,
      onTap: () => _actions(u),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: role.$2.withValues(alpha: 0.13),
                shape: BoxShape.circle,
              ),
              child: Text(_initials(name),
                  style: FigText.label.copyWith(
                      fontWeight: FontWeight.w700, color: role.$2)),
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
                  const SizedBox(height: 2),
                  Text((u['email'] ?? '').toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: FigText.label.copyWith(color: c.textMuted)),
                ],
              ),
            ),
            const SizedBox(width: FigSpace.md),
            AdminPill(role.$1, role.$2, dense: true),
          ],
        ),
      ),
    );
  }
}
