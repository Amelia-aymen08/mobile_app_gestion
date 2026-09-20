import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/l10n.dart';
import '../theme/app_theme.dart';

/// Bottom sheet to switch between French, English and Arabic.
Future<void> showLanguagePicker(BuildContext context) {
  final provider = context.read<LocaleProvider>();
  final dark = Theme.of(context).brightness == Brightness.dark;
  final fg = dark ? Colors.white : brandNavy;

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: BoxDecoration(
        color: dark ? darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: dark ? darkBorder : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(height: 16),
            Text('Langue'.tr,
                style: TextStyle(
                    color: fg, fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 12),
            for (final lang in AppLang.values)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                title: Text(lang.nativeName,
                    style: TextStyle(color: fg, fontWeight: FontWeight.w700)),
                trailing: lang == provider.lang
                    ? const Icon(Icons.check_circle_rounded, color: brandAmber)
                    : Icon(Icons.circle_outlined,
                        color: dark ? darkBorder : const Color(0xFFCBD5E1)),
                onTap: () {
                  // Close first: switching language rebuilds the navigator.
                  Navigator.pop(sheetContext);
                  provider.setLang(lang);
                },
              ),
          ],
        ),
      ),
    ),
  );
}

/// Compact "FR ▾" button, meant for screens that show no settings menu (login).
class LanguageChip extends StatelessWidget {
  final Color color;
  const LanguageChip({super.key, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocaleProvider>().lang;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => showLanguagePicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.6)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.language_rounded, size: 16, color: color),
          const SizedBox(width: 6),
          Text(lang.shortLabel,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w800, fontSize: 12)),
          Icon(Icons.arrow_drop_down_rounded, size: 18, color: color),
        ]),
      ),
    );
  }
}
