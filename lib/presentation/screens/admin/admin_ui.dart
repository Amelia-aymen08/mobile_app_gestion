import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../services/gi_haptics.dart';
import '../../theme/design_tokens.dart';
import '../../theme/gi_colors.dart';
import '../../theme/page_transition.dart';
import '../../theme/ticket_categories.dart';
import '../../theme/ticket_status.dart';
import '../../widgets/gi_card.dart';
import '../../widgets/gi_pressable.dart';

/// Briques communes des ecrans d'administration.
///
/// Elles reprennent les surfaces de l'espace resident — cartes, pastilles,
/// puces — pour que l'administration parle la meme langue visuelle, avec en
/// plus ce qu'un gestionnaire doit lire d'un coup d'oeil : statut, urgence,
/// residence et intervenant.

/// Ouverture d'une page d'administration, avec le meme glissement sur toutes
/// les plateformes. Le theme ne le fixe que pour iOS et Android : sur un
/// ordinateur, dans le navigateur, Flutter retombait sur son zoom par defaut.
class AdminRoute<T> extends MaterialPageRoute<T> {
  AdminRoute(Widget page) : super(builder: (_) => page);

  @override
  Duration get transitionDuration =>
      const GiPageTransitionsBuilder().transitionDuration;

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation, Widget child) =>
      const GiPageTransitionsBuilder().buildTransitions(
          this, context, animation, secondaryAnimation, child);
}

Future<T?> adminPush<T>(BuildContext context, Widget page) =>
    Navigator.of(context).push<T>(AdminRoute<T>(page));

/// Largeur a partir de laquelle on passe en mise en page d'ordinateur :
/// barre laterale, grilles de cartes.
const double kAdminWide = 900;

bool isAdminWide(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= kAdminWide;

/// Nombre de colonnes d'une grille de cartes pour une largeur donnee.
int adminColumns(double width, {double min = 340}) =>
    (width / min).floor().clamp(1, 3);

/// Contenu centre et borne en largeur : sur un grand ecran, des lignes de
/// 1 800 pixels ne se lisent plus.
class AdminContent extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  const AdminContent({super.key, required this.child, this.maxWidth = 1180});

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      );
}

/// Grille de cartes qui retombe en colonne unique sur telephone. Les cartes
/// gardent leur hauteur propre : une rangee prend celle de la plus haute.
class AdminGrid extends StatelessWidget {
  final List<Widget> children;
  final double minTileWidth;
  final double spacing;
  const AdminGrid({
    super.key,
    required this.children,
    this.minTileWidth = 340,
    this.spacing = FigSpace.lg,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final cols = adminColumns(constraints.maxWidth, min: minTileWidth);
      if (cols == 1) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) SizedBox(height: spacing),
              children[i],
            ],
          ],
        );
      }
      final rows = <Widget>[];
      for (var i = 0; i < children.length; i += cols) {
        if (i > 0) rows.add(SizedBox(height: spacing));
        rows.add(IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var j = 0; j < cols; j++) ...[
                if (j > 0) SizedBox(width: spacing),
                Expanded(
                  child: i + j < children.length
                      ? children[i + j]
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ));
      }
      return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
    });
  }
}

/// Bouton carre de l'en-tete — retour, cloche, action.
class AdminSquareButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool filled;
  final String? tooltip;
  const AdminSquareButton({
    super.key,
    required this.child,
    this.onTap,
    this.filled = false,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    final box = Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: filled ? FigBrand.amber : c.headerChipBg,
        border: Border.all(color: filled ? FigBrand.amber : c.headerChipBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
    final button = GiPressable(pressedScale: 0.88, onTap: onTap, child: box);
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

/// Bouton retour de l'espace resident.
class AdminBackButton extends StatelessWidget {
  const AdminBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    return AdminSquareButton(
      onTap: () => Navigator.maybePop(context),
      child: Transform.flip(
        flipX: Directionality.of(context) == TextDirection.rtl,
        child: SvgPicture.asset('assets/figma/icons/back_14.svg',
            colorFilter: ColorFilter.mode(c.textBody, BlendMode.srcIn)),
      ),
    );
  }
}

/// En-tete de page : retour facultatif, titre, sous-titre, actions.
class AdminPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool back;
  final List<Widget> actions;
  final bool large;

  const AdminPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.back = false,
    this.actions = const [],
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    return Row(
      children: [
        if (back) ...[
          const AdminBackButton(),
          const SizedBox(width: FigSpace.xl),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: large
                      ? FigText.greeting.copyWith(color: c.title)
                      : FigText.titleMd
                          .copyWith(fontSize: 20, color: c.textBody)),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FigText.body.copyWith(color: c.textMuted)),
              ],
            ],
          ),
        ),
        for (final a in actions) ...[
          const SizedBox(width: FigSpace.md),
          a,
        ],
      ],
    );
  }
}

/// Titre de section, avec un lien « Tout voir » facultatif.
class AdminSectionTitle extends StatelessWidget {
  final String title;
  final String? count;
  final String? action;
  final VoidCallback? onAction;
  const AdminSectionTitle(this.title,
      {super.key, this.count, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    return Row(
      children: [
        Flexible(
          child: Text(title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: FigText.titleMd.copyWith(fontSize: 17, color: c.textBody)),
        ),
        if (count != null) ...[
          const SizedBox(width: FigSpace.md),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: c.fieldBg,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(count!,
                style: FigText.label
                    .copyWith(fontWeight: FontWeight.w600, color: c.textMuted)),
          ),
        ],
        const Spacer(),
        if (action != null)
          GiPressable(
            pressedScale: 0.94,
            onTap: onAction,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(action!,
                      style: FigText.body.copyWith(
                          color: FigBrand.amber, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 4),
                  const GiChevron(color: FigBrand.amber),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Pilule teintee : statut, priorite, etiquette.
class AdminPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool dense;
  const AdminPill(this.label, this.color,
      {super.key, this.icon, this.dense = false});

  factory AdminPill.stage(TicketStage s, {bool dense = false}) =>
      AdminPill(s.label, s.color, icon: Icons.circle, dense: dense);

  factory AdminPill.priority(TicketPriority p, {bool dense = false}) =>
      AdminPill(p.label, p.color, icon: Icons.flag_rounded, dense: dense);

  @override
  Widget build(BuildContext context) {
    final small = icon == Icons.circle;
    return Container(
      padding: EdgeInsets.fromLTRB(
          dense ? 8 : 10, dense ? 3 : 5, dense ? 9 : 12, dense ? 3 : 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.32)),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon,
                size: small ? (dense ? 6 : 8) : (dense ? 11 : 14),
                color: color),
            SizedBox(width: dense ? 4 : 6),
          ],
          Flexible(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: (dense
                        ? FigText.caption.copyWith(fontSize: 11)
                        : FigText.label)
                    .copyWith(color: color, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

/// Pastille d'icone de la categorie d'un ticket, teintee par son statut.
class AdminCategoryTile extends StatelessWidget {
  final String category;
  final Color color;
  final double size;
  const AdminCategoryTile(
      {super.key, required this.category, required this.color, this.size = 44});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
          borderRadius: BorderRadius.circular(size * 0.28),
        ),
        child:
            Icon(ticketCategoryIcon(category), size: size * 0.5, color: color),
      );
}

/// Carte de ticket de l'administration.
///
/// Tout ce qui decide de l'action tient sur la carte : de quoi il s'agit,
/// ou, depuis quand, a quel stade, avec quelle urgence, et qui s'en occupe.
/// Un ticket sans intervenant le dit en ambre : c'est le premier travail du
/// gestionnaire.
class AdminTicketCard extends StatelessWidget {
  final Map ticket;
  final String residenceName;
  final VoidCallback onTap;
  final bool showResidence;

  const AdminTicketCard({
    super.key,
    required this.ticket,
    required this.residenceName,
    required this.onTap,
    this.showResidence = true,
  });

  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    final stage = ticketStage(ticket['status']);
    final priority = ticketPriority(ticket['priority']);
    final category = (ticket['category'] ?? '').toString();
    final location = (ticket['location'] ?? '').toString().trim();
    final assignee = TicketFields.assignee(ticket);
    final place = [
      if (showResidence && residenceName.isNotEmpty) residenceName,
      if (location.isNotEmpty && location != residenceName) location,
    ].join(' · ');

    return GiCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminCategoryTile(category: category, color: stage.color),
              const SizedBox(width: FigSpace.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(TicketFields.title(ticket),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: FigText.statValue.copyWith(
                            fontSize: 15, height: 1.25, color: c.textBody)),
                    if (place.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(place,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: FigText.label.copyWith(color: c.textMuted)),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: FigSpace.md),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: GiChevron(color: c.textFaint),
              ),
            ],
          ),
          const SizedBox(height: FigSpace.lg),
          Row(
            children: [
              Flexible(child: AdminPill.stage(stage, dense: true)),
              if (priority == TicketPriority.urgent ||
                  priority == TicketPriority.high) ...[
                const SizedBox(width: FigSpace.sm),
                Flexible(child: AdminPill.priority(priority, dense: true)),
              ],
              const Spacer(),
              const SizedBox(width: FigSpace.md),
              Text(timeAgoLabel(TicketFields.created(ticket)),
                  style: FigText.caption
                      .copyWith(fontSize: 11, color: c.textFaint)),
            ],
          ),
          if (stage.isActive) ...[
            const SizedBox(height: FigSpace.md + 2),
            Container(
              padding: const EdgeInsets.only(top: FigSpace.md + 2),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: c.innerBorder)),
              ),
              child: Row(
                children: [
                  Icon(
                      assignee.isEmpty
                          ? Icons.person_add_alt_1_rounded
                          : Icons.engineering_rounded,
                      size: 15,
                      color: assignee.isEmpty ? FigBrand.amber : c.textMuted),
                  const SizedBox(width: FigSpace.sm),
                  Expanded(
                    child: Text(assignee.isEmpty ? 'À assigner' : assignee,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: FigText.label.copyWith(
                            fontWeight: assignee.isEmpty
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: assignee.isEmpty
                                ? FigBrand.amber
                                : c.textMuted)),
                  ),
                  Text(TicketFields.ref(ticket),
                      style: FigText.caption
                          .copyWith(fontSize: 11, color: c.textFaint)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Tuile de chiffre cle, cliquable : elle mene a la liste qu'elle compte.
class AdminStatTile extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String label;
  final String value;
  final String? hint;
  final VoidCallback? onTap;

  const AdminStatTile({
    super.key,
    required this.icon,
    required this.accent,
    required this.label,
    required this.value,
    this.hint,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    return GiCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: accent),
              ),
              const Spacer(),
              if (onTap != null) const GiChevron(),
            ],
          ),
          const SizedBox(height: FigSpace.lg),
          // Le chiffre change en fondu quand la liste se met a jour.
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            transitionBuilder: (child, a) => FadeTransition(
              opacity: a,
              child: SlideTransition(
                position: Tween(begin: const Offset(0, 0.25), end: Offset.zero)
                    .animate(a),
                child: child,
              ),
            ),
            child: Text(value,
                key: ValueKey(value),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    FigText.greeting.copyWith(fontSize: 26, color: c.textBody)),
          ),
          const SizedBox(height: 2),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: FigText.body.copyWith(color: c.textMuted)),
          if (hint != null && hint!.isNotEmpty) ...[
            const SizedBox(height: FigSpace.xs),
            Text(hint!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: FigText.caption.copyWith(fontSize: 11, color: accent)),
          ],
        ],
      ),
    );
  }
}

/// Champ de recherche aux couleurs des champs du formulaire.
class AdminSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  const AdminSearchField(
      {super.key, required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: c.fieldBg,
        border: Border.all(color: c.fieldBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          Icon(Icons.search_rounded, size: 20, color: c.textMuted),
          const SizedBox(width: FigSpace.md),
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              cursorColor: FigBrand.amber,
              style: FigText.fieldLabel.copyWith(color: c.fieldText),
              decoration: InputDecoration(
                isCollapsed: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: hint,
                hintStyle: FigText.fieldLabel.copyWith(color: c.fieldHint),
              ),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) => AnimatedOpacity(
              duration: const Duration(milliseconds: 160),
              opacity: value.text.isEmpty ? 0 : 1,
              child: IgnorePointer(
                ignoring: value.text.isEmpty,
                child: GiPressable(
                  pressedScale: 0.85,
                  onTap: controller.clear,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child:
                        Icon(Icons.close_rounded, size: 18, color: c.textMuted),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Puce de filtre avec compteur. Selectionnee, elle prend la surface sombre
/// des puces de l'espace resident.
class AdminFilterChip extends StatelessWidget {
  final String label;
  final int? count;
  final bool selected;
  final Color? dot;
  final VoidCallback onTap;

  const AdminFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
    this.dot,
  });

  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    final fg = selected ? Colors.white : c.textMuted;
    return GiPressable(
      pressedScale: 0.94,
      haptic: false,
      onTap: () {
        if (!selected) GiHaptics.select();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? c.navbarBg : c.card,
          border: Border.all(color: selected ? FigBrand.amber : c.cardBorder),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dot != null) ...[
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              ),
              const SizedBox(width: 7),
            ],
            Text(label,
                style: FigText.body.copyWith(
                    color: fg,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
            if (count != null) ...[
              const SizedBox(width: 7),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: selected
                      ? FigBrand.amber
                      : c.textFaint.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text('$count',
                    style: FigText.caption.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.black : c.textMuted)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Bandeau de confirmation, glisse depuis le haut puis s'efface seul.
///
/// Il remplace les SnackBar et les boites de dialogue de l'ancienne
/// administration : il dit ce qui vient de se passer sans rien bloquer.
void showAdminToast(BuildContext context, String message,
    {bool error = false}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  error ? GiHaptics.error() : GiHaptics.success();
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _AdminToast(
      message: message,
      error: error,
      onDone: () => entry.remove(),
    ),
  );
  overlay.insert(entry);
}

class _AdminToast extends StatefulWidget {
  final String message;
  final bool error;
  final VoidCallback onDone;
  const _AdminToast(
      {required this.message, required this.error, required this.onDone});

  @override
  State<_AdminToast> createState() => _AdminToastState();
}

class _AdminToastState extends State<_AdminToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
      reverseDuration: const Duration(milliseconds: 260));

  @override
  void initState() {
    super.initState();
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 2600), () async {
      if (!mounted) return;
      await _ctrl.reverse();
      widget.onDone();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    final accent = widget.error ? FigAlert.error : FigAlert.success;
    final curved = CurvedAnimation(
        parent: _ctrl, curve: Curves.easeOutBack, reverseCurve: Curves.easeIn);
    return Positioned(
      left: 16,
      right: 16,
      top: MediaQuery.paddingOf(context).top + 12,
      child: IgnorePointer(
        child: Center(
          child: FadeTransition(
            opacity: _ctrl,
            child: SlideTransition(
              position: Tween(begin: const Offset(0, -0.6), end: Offset.zero)
                  .animate(curved),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 440),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: c.navbarBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: accent.withValues(alpha: 0.5)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 24,
                          offset: const Offset(0, 8)),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                          widget.error
                              ? Icons.error_outline_rounded
                              : Icons.check_circle_rounded,
                          size: 20,
                          color: accent),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(widget.message,
                            style: FigText.body.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Etat vide sobre : icone, titre, phrase.
class AdminEmpty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  const AdminEmpty(
      {super.key,
      required this.icon,
      required this.title,
      required this.message});

  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: FigBrand.amber.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 30, color: FigBrand.amber),
          ),
          const SizedBox(height: FigSpace.xl),
          Text(title,
              textAlign: TextAlign.center,
              style: FigText.titleMd.copyWith(color: c.textBody)),
          const SizedBox(height: FigSpace.sm),
          Text(message,
              textAlign: TextAlign.center,
              style: FigText.body.copyWith(height: 1.4, color: c.textMuted)),
        ],
      ),
    );
  }
}
