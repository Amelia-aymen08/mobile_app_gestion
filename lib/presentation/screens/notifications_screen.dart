import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
// `intl` exporte aussi un type TextDirection qui masque celui de Flutter.
import 'package:intl/intl.dart' hide TextDirection;

import '../../data/api_service.dart';
import '../../l10n/app_localizations.dart';
import '../theme/design_tokens.dart';
import '../widgets/gi_appear.dart';
import '../theme/gi_colors.dart';
import '../widgets/gi_card.dart';
import '../widgets/gi_empty_state.dart';
import '../widgets/gi_header.dart';
import '../widgets/gi_pressable.dart';

/// Notifications du resident.
///
/// Le Figma ne dessine pas cet ecran : il reprend la frame « Notices LT »,
/// dont il partage la matiere — en-tete a pastille, rangee de filtres et
/// cartes de 16 de rayon. Le compteur de l'en-tete sert aussi de bouton :
/// l'appuyer marque tout comme lu.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ApiService _api = ApiService();

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = const [];
  String _filter = 'all';

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
      final data = await _api.getNotifications();
      final items =
          data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      if (!mounted) return;
      setState(() {
        _items = items;
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

  Future<void> _markRead(Map<String, dynamic> n) async {
    final id = n['id']?.toString();
    if (id == null || id.isEmpty || n['isRead'] == true) return;
    try {
      await _api.markNotificationRead(id);
      if (!mounted) return;
      setState(() {
        _items = _items
            .map((x) => x['id']?.toString() == id ? {...x, 'isRead': true} : x)
            .toList();
      });
    } catch (_) {
      // Marquer comme lu est accessoire : un echec ne doit pas interrompre
      // l'ouverture de la notification.
    }
  }

  Future<void> _markAllRead() async {
    try {
      await _api.markAllNotificationsRead();
      if (!mounted) return;
      setState(() {
        _items = _items.map((x) => {...x, 'isRead': true}).toList();
      });
    } catch (_) {}
  }

  bool _isUrgent(Map n) =>
      ['WARNING', 'ERROR'].contains((n['type'] ?? '').toString());

  List<Map<String, dynamic>> get _filtered {
    if (_filter == 'urgent') return _items.where(_isUrgent).toList();
    if (_filter == 'info') return _items.where((n) => !_isUrgent(n)).toList();
    return _items;
  }

  /// Couleur et pastille par type, alignees sur les accents du Figma.
  ({String asset, Color color}) _typeStyle(String type) => switch (type) {
        'WARNING' => (
            asset: 'assets/figma/icons/alert_20.svg',
            color: FigBrand.amber
          ),
        'ERROR' => (
            asset: 'assets/figma/icons/alert_20.svg',
            color: FigAlert.error
          ),
        'SUCCESS' => (
            asset: 'assets/figma/icons/notif_booking_16.svg',
            color: FigAlert.success
          ),
        'PAYMENT' => (
            asset: 'assets/figma/icons/notif_payment_16.svg',
            color: FigAccent.violet
          ),
        _ => (
            asset: 'assets/figma/icons/notif_announce_16.svg',
            color: FigAccent.blue
          ),
      };

  String _typeLabel(AppL10n t, String type) => switch (type) {
        'WARNING' || 'ERROR' => t.filterUrgent,
        'SUCCESS' => t.notifBookings,
        'PAYMENT' => t.notifPayments,
        _ => t.filterInfo,
      };

  String _formatDate(dynamic value) {
    if (value == null) return '';
    try {
      final dt = DateTime.parse(value.toString()).toLocal();
      return DateFormat('dd/MM/yyyy · HH:mm').format(dt);
    } catch (_) {
      return value.toString();
    }
  }

  void _openDetail(Map<String, dynamic> n) {
    _markRead(n);
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => _NotificationDetailScreen(
              notification: n,
              accent: _typeStyle((n['type'] ?? '').toString()).color)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    final t = AppL10n.of(context);
    final unread = _items.where((e) => e['isRead'] != true).length;
    final list = _filtered;

    return Scaffold(
      backgroundColor: c.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                  FigSpace.pagePadding,
                  MediaQuery.paddingOf(context).top > 0 ? 22 : 32,
                  FigSpace.pagePadding,
                  0),
              child: Row(
                children: [
                  // Cet ecran s'ouvre depuis la cloche de l'accueil : sans
                  // retour, on ne peut plus en sortir.
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
                  Expanded(
                    child: GiScreenHeader(
                      iconAsset: 'assets/figma/icons/bell_16.svg',
                      accent: FigBrand.amber,
                      title: t.notificationsTitle,
                      subtitle: t.notificationsSubtitle,
                    ),
                  ),
                  if (unread > 0) ...[
                    const SizedBox(width: FigSpace.md),
                    // Le compteur fait aussi office de « tout marquer comme
                    // lu » : deux elements pour la meme information seraient
                    // redondants dans un en-tete deja charge.
                    GiPressable(
                      pressedScale: 0.92,
                      onTap: _markAllRead,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: FigBrand.amber,
                          borderRadius: BorderRadius.circular(FigRadius.pill),
                        ),
                        child: Text(t.newCount(unread),
                            style: FigText.label.copyWith(
                                fontWeight: FontWeight.w500,
                                color: Colors.black)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 28,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: FigSpace.pagePadding),
                children: [
                  GiFilterChip(
                      label: t.filterAll,
                      selected: _filter == 'all',
                      onTap: () => setState(() => _filter = 'all')),
                  const SizedBox(width: FigSpace.xs),
                  GiFilterChip(
                      label: t.filterUrgent,
                      selected: _filter == 'urgent',
                      onTap: () => setState(() => _filter = 'urgent')),
                  const SizedBox(width: FigSpace.xs),
                  GiFilterChip(
                      label: t.filterInfo,
                      selected: _filter == 'info',
                      onTap: () => setState(() => _filter = 'info')),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: FigBrand.amber))
                  : RefreshIndicator(
                      color: FigBrand.amber,
                      backgroundColor: c.card,
                      onRefresh: _load,
                      child: list.isEmpty
                          ? ListView(
                              padding: const EdgeInsets.fromLTRB(
                                  FigSpace.pagePadding, 24,
                                  FigSpace.pagePadding, 40),
                              children: [
                                GiEmptyState(
                                  illustration:
                                      'assets/figma/empty/notices.svg',
                                  title: t.emptyNotificationsTitle,
                                  message:
                                      _error ?? t.emptyNotificationsBody,
                                ),
                              ],
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                  FigSpace.pagePadding, 0,
                                  FigSpace.pagePadding, 40),
                              itemCount: list.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: FigSpace.lg),
                              itemBuilder: (_, i) =>
                                  GiAppear(index: i, child: _card(c, t, list[i])),
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Carte de notification — meme grammaire que la « Notice Card » du Figma :
  /// pastille de type, titre, extrait, puis date et lien de lecture.
  Widget _card(GiColors c, AppL10n t, Map<String, dynamic> n) {
    final title = (n['title'] ?? '').toString();
    final message = (n['message'] ?? '').toString();
    final type = (n['type'] ?? 'INFO').toString();
    final style = _typeStyle(type);
    final isRead = n['isRead'] == true;

    return GiCard(
      onTap: () => _openDetail(n),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: FigAccent.chipFill(style.color),
                    border:
                        Border.all(color: FigAccent.chipBorder(style.color)),
                    borderRadius: BorderRadius.circular(FigRadius.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(style.asset,
                          width: 11,
                          height: 11,
                          colorFilter:
                              ColorFilter.mode(style.color, BlendMode.srcIn)),
                      const SizedBox(width: FigSpace.xs),
                      Flexible(
                        child: Text(_typeLabel(t, type),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: FigText.caption.copyWith(color: style.color)),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              // Point ambre tant que la notification n'a pas ete ouverte.
              if (!isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: FigBrand.amber, shape: BoxShape.circle),
                ),
            ],
          ),
          const SizedBox(height: FigSpace.xl),
          Text(title.isEmpty ? t.notificationsTitle : title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: FigText.statValue.copyWith(
                  height: 1.2,
                  fontWeight: isRead ? FontWeight.w500 : FontWeight.w600,
                  color: c.textBody)),
          if (message.isNotEmpty) ...[
            const SizedBox(height: FigSpace.sm),
            Text(message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: FigText.body.copyWith(height: 1.4, color: c.textMuted)),
          ],
          const SizedBox(height: FigSpace.xl),
          Row(
            children: [
              Expanded(
                child: Text(_formatDate(n['createdAt']),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FigText.caption.copyWith(color: c.textFaint)),
              ),
              const SizedBox(width: FigSpace.lg),
              Text(t.readMore,
                  style: FigText.caption.copyWith(color: c.textBody)),
              const SizedBox(width: FigSpace.xs),
              Transform.flip(
                flipX: Directionality.of(context) == TextDirection.rtl,
                child: SvgPicture.asset(
                  'assets/figma/icons/arrow_readmore.svg',
                  colorFilter: ColorFilter.mode(c.textBody, BlendMode.srcIn),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Detail d'une notification — reprend la mise en page de « Notice Detail
/// LT » : en-tete a pastille, carte de contenu, puis le corps du message.
class _NotificationDetailScreen extends StatelessWidget {
  final Map<String, dynamic> notification;
  final Color accent;

  const _NotificationDetailScreen(
      {required this.notification, required this.accent});

  String _formatDate(dynamic value) {
    if (value == null) return '';
    try {
      final dt = DateTime.parse(value.toString()).toLocal();
      return DateFormat('dd/MM/yyyy · HH:mm').format(dt);
    } catch (_) {
      return value.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    final t = AppL10n.of(context);
    final title = (notification['title'] ?? '').toString();
    final message = (notification['message'] ?? '').toString();
    final date = _formatDate(notification['createdAt']);

    return Scaffold(
      backgroundColor: c.scaffold,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
              FigSpace.pagePadding,
              MediaQuery.paddingOf(context).top > 0 ? 22 : 32,
              FigSpace.pagePadding,
              40),
          children: [
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
                      flipX: Directionality.of(context) == TextDirection.rtl,
                      child: SvgPicture.asset(
                        'assets/figma/icons/back_14.svg',
                        colorFilter:
                            ColorFilter.mode(c.textBody, BlendMode.srcIn),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 17),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(t.notificationsTitle,
                          style: FigText.titleMd
                              .copyWith(fontSize: 18, color: c.textBody)),
                      if (date.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(date,
                            style:
                                FigText.label.copyWith(color: c.textMuted)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            GiCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 3,
                    width: 44,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(FigRadius.pill),
                    ),
                  ),
                  const SizedBox(height: FigSpace.xl),
                  Text(title.isEmpty ? t.notificationsTitle : title,
                      style: FigText.greeting
                          .copyWith(fontSize: 20, height: 1.2, color: c.textBody)),
                  if (message.isNotEmpty) ...[
                    const SizedBox(height: FigSpace.lg),
                    Text(message,
                        style: FigText.fieldLabel
                            .copyWith(height: 1.6, color: c.textMuted)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
