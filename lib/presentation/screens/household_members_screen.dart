// ignore_for_file: use_build_context_synchronously
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../l10n/app_localizations.dart';
import '../theme/design_tokens.dart';
import '../theme/gi_colors.dart';
import '../widgets/gi_alert_dialog.dart';
import '../widgets/gi_card.dart';
import '../widgets/gi_pressable.dart';
import '../widgets/gi_primary_button.dart';
import '../widgets/gi_refresh.dart';
import '../widgets/gi_text_field.dart';
import '../../data/api_service.dart';
import '../../data/person_name.dart';
import '../providers/auth_provider.dart';

/// Nombre de comptes qu'un foyer peut ouvrir, limite posee par le serveur.
const int kMaxHouseholdMembers = 4;

class HouseholdMembersScreen extends StatefulWidget {
  const HouseholdMembersScreen({super.key});

  @override
  State<HouseholdMembersScreen> createState() => _HouseholdMembersScreenState();
}

class _HouseholdMembersScreenState extends State<HouseholdMembersScreen> {
  final ApiService _api = ApiService();
  bool _loading = true;
  List<dynamic> _members = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _api.getHouseholdMembers();
      if (mounted) setState(() => _members = list);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }



  Future<void> _openForm({Map<String, dynamic>? existing}) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => _MemberFormScreen(existing: existing)),
    );
    if (saved == true) _load();
  }

  Future<void> _remove(Map<String, dynamic> member) async {
    final t = AppL10n.of(context);
    var confirmed = false;
    await showGiAlert<void>(
      context: context,
      title: t.removeMemberTitle,
      message: t.removeMemberBody((member['fullName'] ?? '').toString()),
      closeLabel: t.cancel,
      primaryLabel: t.remove,
      onPrimary: () => confirmed = true,
    );
    if (!confirmed) return;
    try {
      await _api.removeHouseholdMember(member['id'].toString());
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))));
      }
    }
  }

  /// Renvoie au membre un mot de passe temporaire par courriel.
  Future<void> _resendAccess(Map<String, dynamic> member) async {
    final t = AppL10n.of(context);
    try {
      await _api.resendMemberAccess((member['id'] ?? '').toString());
      if (!mounted) return;
      showGiAlert<void>(
        context: context,
        title: t.resendAccess,
        message: t.accessResent,
        closeLabel: t.close,
        primaryLabel: t.close,
      );
    } catch (e) {
      if (!mounted) return;
      showGiAlert<void>(
        context: context,
        title: t.errorTitle,
        message: e.toString().replaceFirst('Exception: ', ''),
        closeLabel: t.close,
        primaryLabel: t.close,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    final t = AppL10n.of(context);

    return Scaffold(
      backgroundColor: c.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            // En-tete du Figma : pastille de retour de 32, ecart 16, titre 18.
            Padding(
              padding: EdgeInsets.fromLTRB(
                  FigSpace.pagePadding,
                  MediaQuery.paddingOf(context).top > 0 ? 22 : 32,
                  FigSpace.pagePadding,
                  0),
              child: Row(
                children: [
                  GiPressable(
                    onTap: () => Navigator.pop(context),
                    pressedScale: 0.88,
                    child: Container(
                      width: FigSize.chipMd,
                      height: FigSize.chipMd,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: c.headerChipBg,
                        border: Border.all(color: c.headerChipBorder),
                        borderRadius: BorderRadius.circular(FigRadius.chip),
                      ),
                      child: Transform.flip(
                        flipX:
                            Directionality.of(context) == TextDirection.rtl,
                        child: SvgPicture.asset(
                          'assets/figma/icons/back_14.svg',
                          colorFilter:
                              ColorFilter.mode(c.textBody, BlendMode.srcIn),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: FigSpace.xl),
                  // Expanded : avec la police du systeme agrandie, un titre
                  // libre depasse la largeur de l'ecran.
                  Expanded(
                    child: Text(t.householdMembers,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: FigText.titleMd
                            .copyWith(fontSize: 18, color: c.textBody)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: FigBrand.amber))
                  : CustomScrollView(
                      physics: giRefreshPhysics,
                      slivers: [
                        GiRefreshControl(onRefresh: _load),
                        SliverPadding(
                        padding: const EdgeInsets.fromLTRB(
                            FigSpace.pagePadding, 0, FigSpace.pagePadding, 120),
                        sliver: SliverList.list(children: [
                          Text(
                              t.memberCount(
                                  kMaxHouseholdMembers, _members.length),
                              style:
                                  FigText.field.copyWith(color: c.textMuted)),
                          const SizedBox(height: FigSpace.md),
                          // Chaque membre recoit un vrai compte : le dire
                          // evite d'inscrire un voisin par megarde.
                          Container(
                            padding: const EdgeInsets.all(FigSpace.lg),
                            decoration: BoxDecoration(
                              color: FigAccent.chipFill(FigBrand.amber),
                              border: Border.all(
                                  color: FigAccent.chipBorder(FigBrand.amber)),
                              borderRadius:
                                  BorderRadius.circular(FigRadius.chip),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SvgPicture.asset(
                                  'assets/figma/icons/info_16.svg',
                                  colorFilter: const ColorFilter.mode(
                                      FigBrand.amber, BlendMode.srcIn),
                                ),
                                const SizedBox(width: FigSpace.md),
                                Expanded(
                                  child: Text(
                                      t.householdHint(kMaxHouseholdMembers),
                                      style: FigText.body.copyWith(
                                          height: 1.4, color: c.textBody)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: FigSpace.lg),
                          // Le titulaire du bien, toujours en tete et sans
                          // menu : il ne peut ni etre modifie ni retire.
                          _memberCard(
                            c,
                            name: _meName(t),
                            relation: t.mainResident,
                            statusLabel: (_me?['email'] ?? '').toString(),
                            statusColor: c.textMuted,
                            photo: _api.mediaUrl(_me?['photo']),
                            member: null,
                          ),
                          // Figma : les cartes sont espacees de 4, pas de 12.
                          for (final m in _members.whereType<Map>()) ...[
                            const SizedBox(height: FigSpace.xs),
                            _memberCard(
                              c,
                              name: (m['fullName'] ?? '').toString(),
                              relation: [
                                (m['relation'] ?? '').toString(),
                                (m['email'] ?? '').toString(),
                              ].where((e) => e.isNotEmpty).join(' - '),
                              statusLabel: _statusLabel(t, m),
                              statusColor: _statusColor(m),
                              photo: _api.mediaUrl(m['photo']),
                              member: Map<String, dynamic>.from(m),
                            ),
                          ],
                        ]),
                        ),
                      ],
                    ),
            ),
            // Le Figma pose le bouton a 52 du bas, hors de la liste.
            Padding(
              padding: const EdgeInsets.fromLTRB(FigSpace.pagePadding, 0,
                  FigSpace.pagePadding, FigSpace.xxl),
              child: GiPrimaryButton(
                label: _isFull
                    ? t.maxMembersReached(kMaxHouseholdMembers)
                    : t.addMember,
                onPressed: _isFull ? null : () => _openForm(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _isFull => _members.length >= kMaxHouseholdMembers;

  Map<String, dynamic>? get _me => context.read<AuthProvider>().user;

  String _meName(AppL10n t) {
    final name = PersonName.format(_me?['name']);
    return name.isEmpty ? t.you : '$name (${t.you})';
  }

  /// Un membre n'a pas toujours de compte : l'invitation peut echouer, ou
  /// l'administration l'avoir desactive. L'etat se lit sur la carte.
  String _statusLabel(AppL10n t, Map m) {
    if (m['linkedUserId'] == null) return t.noAccountChip;
    return m['accountActive'] == false
        ? t.accountDisabledChip
        : t.accountActiveChip;
  }

  Color _statusColor(Map m) {
    if (m['linkedUserId'] == null) return FigNeutral.n40;
    return m['accountActive'] == false ? FigAlert.error : FigAlert.success;
  }

  /// Carte de membre — Figma 0:4180 : avatar rond de 36, ecart 12, trois
  /// lignes de texte espacees de 4, et le menu a trois points de 20.
  Widget _memberCard(
    GiColors c, {
    required String name,
    required String relation,
    required String statusLabel,
    required Color statusColor,
    required String? photo,
    required Map<String, dynamic>? member,
  }) {
    return GiCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _avatar(c, photo, name),
          const SizedBox(width: FigSpace.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(name.isEmpty ? '—' : name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FigText.statValue
                        .copyWith(height: 1.2, color: c.textBody)),
                if (relation.isNotEmpty) ...[
                  const SizedBox(height: FigSpace.xs),
                  Text(relation,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: FigText.body.copyWith(color: c.textMuted)),
                ],
                if (statusLabel.isNotEmpty) ...[
                  const SizedBox(height: FigSpace.xs),
                  Text(statusLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: FigText.body.copyWith(
                          fontWeight: FontWeight.w500, color: statusColor)),
                ],
              ],
            ),
          ),
          if (member != null) ...[
            const SizedBox(width: FigSpace.md),
            GiPressable(
              pressedScale: 0.82,
              ensureMinTapTarget: true,
              onTap: () => _openMemberMenu(c, member),
              child: SvgPicture.asset(
                'assets/figma/icons/dots_20.svg',
                colorFilter: ColorFilter.mode(c.textMuted, BlendMode.srcIn),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Avatar rond de 36. Sans photo servie par l'API, on retombe sur les
  /// initiales plutot que sur une silhouette generique : elles distinguent
  /// au moins les membres entre eux.
  Widget _avatar(GiColors c, String? photo, String name) {
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .take(2)
        .map((e) => e[0].toUpperCase())
        .join();

    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: FigAccent.chipFill(FigBrand.amber),
        border: Border.all(color: FigAccent.chipBorder(FigBrand.amber)),
      ),
      clipBehavior: Clip.antiAlias,
      child: photo != null && photo.startsWith('http')
          ? Image.network(photo,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _initials(initials))
          : _initials(initials),
    );
  }

  Widget _initials(String initials) => Text(
        initials.isEmpty ? '?' : initials,
        style: FigText.body.copyWith(
            fontWeight: FontWeight.w600, color: FigBrand.amber),
      );

  /// Menu du Figma : « Modifier » puis « Retirer » en rouge.
  Future<void> _openMemberMenu(GiColors c, Map<String, dynamic> member) async {
    final t = AppL10n.of(context);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: c.scaffold,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(FigRadius.card)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(FigSpace.pagePadding, 0,
              FigSpace.pagePadding, FigSpace.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GiCard(
                onTap: () {
                  Navigator.pop(sheetContext);
                  _openForm(existing: member);
                },
                child: Row(
                  children: [
                    SvgPicture.asset('assets/figma/icons/edit_13.svg',
                        colorFilter:
                            ColorFilter.mode(c.textBody, BlendMode.srcIn)),
                    const SizedBox(width: FigSpace.lg),
                    Text(t.edit,
                        style: FigText.field.copyWith(color: c.textBody)),
                  ],
                ),
              ),
              if (member['linkedUserId'] != null &&
                  member['accountActive'] != false) ...[
                const SizedBox(height: FigSpace.md),
                GiCard(
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _resendAccess(member);
                  },
                  child: Row(
                    children: [
                      SvgPicture.asset('assets/figma/icons/mail_16.svg',
                          colorFilter:
                              ColorFilter.mode(c.textBody, BlendMode.srcIn)),
                      const SizedBox(width: FigSpace.lg),
                      Text(t.resendAccess,
                          style: FigText.field.copyWith(color: c.textBody)),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: FigSpace.md),
              GiCard(
                onTap: () {
                  Navigator.pop(sheetContext);
                  _remove(member);
                },
                child: Row(
                  children: [
                    SvgPicture.asset('assets/figma/icons/trash_15.svg',
                        colorFilter: const ColorFilter.mode(
                            FigAlert.error, BlendMode.srcIn)),
                    const SizedBox(width: FigSpace.lg),
                    Text(t.remove,
                        style:
                            FigText.field.copyWith(color: FigAlert.error)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


/// Formulaire de membre du foyer — frames Figma « Add member LT » (0:3952 et
/// ses variantes).
///
/// C'est un ecran a part entiere dans la maquette, et non une feuille glissee
/// du bas : le formulaire est long — photo, trois champs, quatre niveaux
/// d'acces — et une feuille l'aurait comprime sous le clavier.
///
/// Geometrie relevee : en-tete a 66, contenu a 126, ecart 28 entre la photo
/// et les champs, 16 entre les champs, pastille photo de 68 cerclee d'ambre
/// avec l'icone d'appareil photo de 24 au centre.
class _MemberFormScreen extends StatefulWidget {
  final Map<String, dynamic>? existing;
  const _MemberFormScreen({this.existing});

  @override
  State<_MemberFormScreen> createState() => _MemberFormScreenState();
}

class _MemberFormScreenState extends State<_MemberFormScreen> {
  final ApiService _api = ApiService();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  String _relation = '';
  String? _photoDataUrl;
  bool _saving = false;
  bool _nameTouched = false;

  /// Relations proposees par la maquette. La liste reste ouverte : la
  /// relation est enregistree telle quelle, on ne fait que l'aider a la
  /// saisir.
  static const _relations = [
    'relFather',
    'relMother',
    'relWife',
    'relHusband',
    'relSon',
    'relDaughter',
    'relOther',
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameCtrl.text = (e['fullName'] ?? '').toString();
      _relation = (e['relation'] ?? '').toString();
      _emailCtrl.text = (e['email'] ?? '').toString();
      _phoneCtrl.text = (e['phone'] ?? '').toString();
      _photoDataUrl = (e['photoUrl'] ?? '').toString().isEmpty
          ? null
          : (e['photoUrl']).toString();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  String _relationLabel(AppL10n t, String key) => switch (key) {
        'relFather' => t.relFather,
        'relMother' => t.relMother,
        'relWife' => t.relWife,
        'relHusband' => t.relHusband,
        'relSon' => t.relSon,
        'relDaughter' => t.relDaughter,
        _ => t.relOther,
      };

  Future<void> _pickPhoto() async {
    final result =
        await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    final file = result?.files.single;
    if (file?.bytes == null) return;
    final ext = (file!.extension ?? 'jpg').toLowerCase();
    final mime =
        ext == 'png' ? 'image/png' : (ext == 'webp' ? 'image/webp' : 'image/jpeg');
    setState(
        () => _photoDataUrl = 'data:$mime;base64,${base64Encode(file.bytes!)}');
  }

  bool get _emailLooksValid {
    final value = _emailCtrl.text.trim();
    return value.contains('@') && value.contains('.') && value.length > 5;
  }

  Future<void> _save() async {
    final t = AppL10n.of(context);
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || !_emailLooksValid) {
      setState(() => _nameTouched = true);
      return;
    }
    setState(() => _saving = true);
    try {
      final id = widget.existing?['id']?.toString();
      if (id != null) {
        await _api.updateHouseholdMember(id,
            fullName: name,
            email: _emailCtrl.text.trim().toLowerCase(),
            relation: _relation,
            phone: _phoneCtrl.text.trim(),
            photoDataUrl: _photoDataUrl);
      } else {
        await _api.addHouseholdMember(
            fullName: name,
            email: _emailCtrl.text.trim().toLowerCase(),
            relation: _relation,
            phone: _phoneCtrl.text.trim(),
            photoDataUrl: _photoDataUrl);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showGiAlert<void>(
        context: context,
        title: t.errorTitle,
        message: e.toString().replaceAll('Exception: ', ''),
        closeLabel: t.close,
        primaryLabel: t.close,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    final t = AppL10n.of(context);
    final isEdit = widget.existing != null;

    return Scaffold(
      backgroundColor: c.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                    FigSpace.pagePadding,
                    MediaQuery.paddingOf(context).top > 0 ? 22 : 32,
                    FigSpace.pagePadding,
                    FigSpace.xl),
                children: [
                  // En-tete : pastille de retour de 32, ecart 16, titre 18.
                  Row(
                    children: [
                      GiPressable(
                        onTap: () => Navigator.pop(context),
                        pressedScale: 0.88,
                        child: Container(
                          width: FigSize.chipMd,
                          height: FigSize.chipMd,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: c.headerChipBg,
                            border: Border.all(color: c.headerChipBorder),
                            borderRadius: BorderRadius.circular(FigRadius.chip),
                          ),
                          child: Transform.flip(
                            flipX: Directionality.of(context) ==
                                TextDirection.rtl,
                            child: SvgPicture.asset(
                              'assets/figma/icons/back_14.svg',
                              colorFilter:
                                  ColorFilter.mode(c.textBody, BlendMode.srcIn),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: FigSpace.xl),
                      Expanded(
                        child: Text(isEdit ? t.editMember : t.addMember,
                            style: FigText.titleMd
                                .copyWith(fontSize: 18, color: c.textBody)),
                      ),
                    ],
                  ),
                  const SizedBox(height: FigSpace.xxl),
                  _photoBlock(c, t),
                  const SizedBox(height: FigSpace.xxl),
                  GiTextField(
                    label: t.fullNameLabel,
                    hint: t.fullNameHint,
                    controller: _nameCtrl,
                    textInputAction: TextInputAction.next,
                    errorText: _nameTouched && _nameCtrl.text.trim().isEmpty
                        ? t.nameRequired
                        : null,
                  ),
                  const SizedBox(height: FigSpace.xl),
                  GiTextField(
                    label: t.emailLabel,
                    hint: t.emailHint,
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    errorText:
                        _nameTouched && !_emailLooksValid ? t.emailRequired : null,
                  ),
                  const SizedBox(height: FigSpace.xl),
                  GiTextField(
                    label: t.phoneLabel,
                    hint: t.phoneHint,
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: FigSpace.xl),
                  _relationField(c, t),
                  const SizedBox(height: FigSpace.xl),
                  // Le compte est cree par le serveur, qui envoie lui-meme
                  // le mot de passe : autant le dire avant d'enregistrer.
                  Container(
                    padding: const EdgeInsets.all(FigSpace.lg),
                    decoration: BoxDecoration(
                      color: FigAccent.chipFill(FigBrand.amber),
                      border: Border.all(
                          color: FigAccent.chipBorder(FigBrand.amber)),
                      borderRadius: BorderRadius.circular(FigRadius.chip),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SvgPicture.asset(
                          'assets/figma/icons/mail_16.svg',
                          colorFilter: const ColorFilter.mode(
                              FigBrand.amber, BlendMode.srcIn),
                        ),
                        const SizedBox(width: FigSpace.md),
                        Expanded(
                          child: Text(
                              t.householdHint(kMaxHouseholdMembers),
                              style: FigText.body
                                  .copyWith(height: 1.4, color: c.textBody)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(FigSpace.pagePadding, 0,
                  FigSpace.pagePadding, FigSpace.xxl),
              child: GiPrimaryButton(
                label: isEdit ? t.saveLabel : t.continueAction,
                isLoading: _saving,
                onPressed: _saving ? null : _save,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Pastille photo : cercle de 68 cercle d'ambre, icone d'appareil photo de
  /// 24 au centre, puis le libelle en 16 SemiBold a 8.
  Widget _photoBlock(GiColors c, AppL10n t) {
    final photo = _photoDataUrl;
    return Center(
      child: GiPressable(
        pressedScale: 0.94,
        onTap: _pickPhoto,
        child: Column(
          children: [
            Container(
              width: 68,
              height: 68,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: FigAccent.chipFill(FigBrand.amber),
                border: Border.all(color: FigBrand.amber),
                image: photo == null
                    ? null
                    : DecorationImage(
                        image: _photoProvider(photo), fit: BoxFit.cover),
              ),
              child: photo != null
                  ? null
                  : SvgPicture.asset(
                      'assets/figma/icons/camera_24.svg',
                      colorFilter: const ColorFilter.mode(
                          FigBrand.amber, BlendMode.srcIn),
                    ),
            ),
            const SizedBox(height: FigSpace.md),
            Text(photo == null ? t.addPhoto : t.changePhoto,
                style: FigText.titleMd.copyWith(color: c.textBody)),
          ],
        ),
      ),
    );
  }

  ImageProvider _photoProvider(String value) => value.startsWith('data:')
      ? MemoryImage(base64Decode(value.split(',').last))
      : NetworkImage(value) as ImageProvider;

  /// Champ de relation : meme habillage que les champs de saisie, avec le
  /// chevron du Figma. La liste s'ouvre dans une feuille glissee du bas.
  Widget _relationField(GiColors c, AppL10n t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.relationshipLabel,
            style: FigText.fieldLabel.copyWith(color: c.textBody)),
        const SizedBox(height: FigSpace.xs),
        GiPressable(
          pressedScale: 0.99,
          onTap: () => _pickRelation(c, t),
          child: Container(
            padding: const EdgeInsets.all(FigSpace.xl - 1.5),
            decoration: BoxDecoration(
              color: c.fieldBg,
              borderRadius: BorderRadius.circular(FigRadius.field),
              border: Border.all(
                  color: _relation.isEmpty ? c.fieldBorder : c.fieldBorderFocus,
                  width: 1.5),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _relation.isEmpty ? t.chooseRelationship : _relation,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FigText.field.copyWith(
                        color: _relation.isEmpty ? c.fieldHint : c.fieldText),
                  ),
                ),
                const SizedBox(width: FigSpace.md),
                SvgPicture.asset(
                  'assets/figma/icons/chevron_down.svg',
                  colorFilter: ColorFilter.mode(c.textMuted, BlendMode.srcIn),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickRelation(GiColors c, AppL10n t) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: c.scaffold,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(FigRadius.card)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              FigSpace.pagePadding, 0, FigSpace.pagePadding, FigSpace.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.chooseRelationship,
                  style: FigText.titleMd.copyWith(color: c.textBody)),
              const SizedBox(height: FigSpace.xl),
              for (final key in _relations)
                Padding(
                  padding: const EdgeInsets.only(bottom: FigSpace.md),
                  child: GiCard(
                    onTap: () {
                      setState(() => _relation = _relationLabel(t, key));
                      Navigator.pop(sheetContext);
                    },
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(_relationLabel(t, key),
                              style: FigText.statValue
                                  .copyWith(color: c.textBody)),
                        ),
                        if (_relation == _relationLabel(t, key))
                          SvgPicture.asset(
                            'assets/figma/icons/check_14.svg',
                            colorFilter: const ColorFilter.mode(
                                FigBrand.amber, BlendMode.srcIn),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

}