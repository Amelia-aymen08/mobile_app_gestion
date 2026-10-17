import 'package:flutter/material.dart';

import '../../theme/design_tokens.dart';
import '../../theme/gi_colors.dart';
import '../../widgets/gi_pressable.dart';
import '../../widgets/gi_primary_button.dart';

/// Feuilles du bas de l'administration : formulaires courts et
/// confirmations.
///
/// Elles remplacent les AlertDialog de l'ancienne administration, blancs en
/// toutes circonstances : la feuille prend la couleur du theme, garde le
/// pouce pres des boutons et se ferme d'un glissement.
Future<T?> showAdminSheet<T>(
  BuildContext context, {
  required String title,
  String? subtitle,
  required Widget Function(BuildContext sheetContext) builder,
}) {
  final c = GiColors.of(context);
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: c.scaffold,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(FigRadius.card)),
    ),
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            FigSpace.pagePadding,
            0,
            FigSpace.pagePadding,
            MediaQuery.paddingOf(sheetContext).bottom + FigSpace.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: FigText.titleMd.copyWith(color: c.textBody)),
            if (subtitle != null && subtitle.isNotEmpty) ...[
              const SizedBox(height: FigSpace.xs),
              Text(subtitle,
                  style: FigText.body.copyWith(height: 1.4, color: c.textMuted)),
            ],
            const SizedBox(height: FigSpace.xl),
            builder(sheetContext),
          ],
        ),
      ),
    ),
  );
}

/// Confirmation en feuille. Rend `null` si l'on renonce, sinon le motif
/// saisi (vide quand [reasonHint] est absent).
Future<String?> adminConfirm(
  BuildContext context, {
  required String title,
  String? message,
  required String confirmLabel,
  bool destructive = false,
  String? reasonHint,
}) {
  final reason = TextEditingController();
  return showAdminSheet<String>(
    context,
    title: title,
    subtitle: message,
    builder: (sheet) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (reasonHint != null) ...[
          AdminField(controller: reason, label: 'Motif', hint: reasonHint,
              lines: 3),
          const SizedBox(height: FigSpace.xl),
        ],
        destructive
            ? AdminDangerButton(
                label: confirmLabel,
                onTap: () => Navigator.pop(sheet, reason.text.trim()))
            : GiPrimaryButton(
                label: confirmLabel,
                onPressed: () => Navigator.pop(sheet, reason.text.trim())),
        const SizedBox(height: FigSpace.md),
        AdminGhostButton(
            label: 'Annuler', onTap: () => Navigator.pop(sheet)),
      ],
    ),
  );
}

/// Champ de saisie a libelle, sur une ou plusieurs lignes.
class AdminField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int lines;
  final bool obscure;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  const AdminField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.lines = 1,
    this.obscure = false,
    this.keyboardType,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    OutlineInputBorder border(Color color) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: 1.2),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: FigText.label.copyWith(color: c.textMuted)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          minLines: lines,
          maxLines: obscure ? 1 : lines,
          obscureText: obscure,
          keyboardType: keyboardType,
          onChanged: onChanged,
          cursorColor: FigBrand.amber,
          style: FigText.fieldLabel.copyWith(color: c.fieldText),
          decoration: InputDecoration(
            filled: true,
            fillColor: c.fieldBg,
            hintText: hint,
            hintStyle: FigText.fieldLabel.copyWith(color: c.fieldHint),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            border: border(c.fieldBorder),
            enabledBorder: border(c.fieldBorder),
            focusedBorder: border(FigBrand.amber),
          ),
        ),
      ],
    );
  }
}

/// Choix exclusif en pastilles, pour un formulaire de feuille.
class AdminChoice<T> extends StatelessWidget {
  final String label;
  final Map<T, String> options;
  final T value;
  final ValueChanged<T> onChanged;
  final Color Function(T)? colorOf;

  const AdminChoice({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
    this.colorOf,
  });

  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: FigText.label.copyWith(color: c.textMuted)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final e in options.entries)
              GiPressable(
                pressedScale: 0.94,
                onTap: () => onChanged(e.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: e.key == value
                        ? (colorOf?.call(e.key) ?? FigBrand.amber)
                            .withValues(alpha: 0.14)
                        : c.card,
                    border: Border.all(
                        color: e.key == value
                            ? (colorOf?.call(e.key) ?? FigBrand.amber)
                            : c.cardBorder),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(e.value,
                      style: FigText.body.copyWith(
                          fontWeight: e.key == value
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: e.key == value
                              ? (colorOf?.call(e.key) ?? FigBrand.amber)
                              : c.textBody)),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Bouton plein rouge : suppression, rejet.
class AdminDangerButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const AdminDangerButton({super.key, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) => GiPressable(
        pressedScale: 0.97,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: FigAlert.error,
            borderRadius: BorderRadius.circular(FigRadius.cta),
          ),
          child: Text(label,
              style: FigText.button.copyWith(color: Colors.white)),
        ),
      );
}

/// Bouton discret, sans fond : annuler, action secondaire.
class AdminGhostButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color? color;
  final IconData? icon;
  const AdminGhostButton(
      {super.key, required this.label, this.onTap, this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    final c = GiColors.of(context);
    final fg = color ?? c.textBody;
    return GiPressable(
      pressedScale: 0.97,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(
              color: color?.withValues(alpha: 0.4) ?? c.cardBorder),
          borderRadius: BorderRadius.circular(FigRadius.cta),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: FigSpace.sm),
            ],
            Flexible(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: FigText.bodyActive.copyWith(color: fg)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bouton plein compact, pour une action dans une carte.
class AdminSolidButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color color;
  final IconData? icon;
  final Color foreground;
  const AdminSolidButton({
    super.key,
    required this.label,
    this.onTap,
    this.color = FigBrand.amber,
    this.foreground = Colors.black,
    this.icon,
  });

  @override
  Widget build(BuildContext context) => GiPressable(
        pressedScale: 0.97,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(FigRadius.cta),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: foreground),
                const SizedBox(width: FigSpace.sm),
              ],
              Flexible(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FigText.bodyActive.copyWith(color: foreground)),
              ),
            ],
          ),
        ),
      );
}
