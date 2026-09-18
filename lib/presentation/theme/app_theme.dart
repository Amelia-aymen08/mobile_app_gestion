import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'design_tokens.dart';
import 'gi_colors.dart';

// ─── Brand Palette ────────────────────────────────────────────────────────────
const brandNavy  = Color(0xFF0C1620); // dark navy
const brandAmber = Color(0xFFDB9200); // CTA amber/gold
const brandCream = Color(0xFFF6F3EC); // icon bg on dark cards
const brandGoldDark = Color(0xFFA08851); // secondary gold

// Backward-compat aliases
const brandBlue       = brandNavy;
const brandGold       = brandAmber;
const brandBackground = Color(0xFFF6F3EC);

// ─── Dark theme surfaces ──────────────────────────────────────────────────────
const darkSurface  = Color(0xFF0F1922); // scaffold bg (dark)
const darkCard     = Color(0xFF16232F); // card / input bg (dark)
const darkBorder   = Color(0xFF2A3B4A); // subtle border (dark)
const darkMuted    = Color(0xFF8A97A3); // secondary text (dark)

// ─── Splash gradients ─────────────────────────────────────────────────────────
const splashGradientLight = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xFFFAF8F3), Color(0xFFC9C0AD)],
);
const splashGradientDark = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [brandNavy, Color(0xFF39424C)],
);

// ─── Background — simple (no blur) ───────────────────────────────────────────
BoxDecoration appBg() => const BoxDecoration(
  image: DecorationImage(
    image: AssetImage('assets/background.png'),
    fit: BoxFit.cover,
  ),
);

// ─── Background — blurred image + subtle dark overlay ────────────────────────
Widget appBgWidget({required Widget child}) {
  return Stack(
    fit: StackFit.expand,
    children: [
      ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: 7, sigmaY: 7),
        child: Image.asset('assets/background.png', fit: BoxFit.cover),
      ),
      Container(color: const Color(0x20000000)),
      child,
    ],
  );
}

// ─── Theme ───────────────────────────────────────────────────────────────────
ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: brandNavy,
    primary: brandNavy,
    secondary: brandAmber,
    surface: Colors.white,
    brightness: Brightness.light,
  );

  return ThemeData(
    useMaterial3: true,
    fontFamily: FigText.family,
    extensions: <ThemeExtension<dynamic>>[GiColors.light],
    colorScheme: scheme,
    scaffoldBackgroundColor: brandBackground,

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
      iconTheme: IconThemeData(color: Colors.white),
    ),

    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.10),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: brandAmber, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Color(0xFFDC2626), width: 2),
      ),
      hintStyle: const TextStyle(color: Color(0xFFADB5BD), fontSize: 15),
      labelStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: brandAmber,
        foregroundColor: Colors.white,
        disabledBackgroundColor: brandAmber.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        minimumSize: const Size.fromHeight(52),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        elevation: 0,
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: brandNavy,
        side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        minimumSize: const Size.fromHeight(52),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: brandAmber,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 12,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      height: 64,
      indicatorColor: Colors.transparent,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: brandAmber, size: 26);
        }
        return const IconThemeData(color: Color(0xFF9AA3AB), size: 24);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(color: brandAmber, fontWeight: FontWeight.w700, fontSize: 11);
        }
        return const TextStyle(color: Color(0xFF9AA3AB), fontSize: 11);
      }),
    ),

    dividerTheme: const DividerThemeData(color: Color(0xFFE2E8F0), thickness: 1),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? brandAmber : Colors.white),
      trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? brandAmber.withValues(alpha: 0.40)
              : const Color(0xFFCBD5E1)),
    ),
  );
}

// ─── Theme — Dark ────────────────────────────────────────────────────────────
ThemeData buildAppThemeDark() {
  final scheme = ColorScheme.fromSeed(
    seedColor: brandAmber,
    primary: brandAmber,
    secondary: brandGoldDark,
    surface: darkCard,
    brightness: Brightness.dark,
  );

  return ThemeData(
    useMaterial3: true,
    fontFamily: FigText.family,
    extensions: <ThemeExtension<dynamic>>[GiColors.dark],
    colorScheme: scheme,
    scaffoldBackgroundColor: darkSurface,

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
      iconTheme: IconThemeData(color: Colors.white),
    ),

    cardTheme: CardThemeData(
      color: darkCard,
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.40),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkCard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: darkBorder, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: darkBorder, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: brandAmber, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
      ),
      hintStyle: const TextStyle(color: darkMuted, fontSize: 15),
      labelStyle: const TextStyle(color: darkMuted, fontSize: 14),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: brandAmber,
        foregroundColor: Colors.white,
        disabledBackgroundColor: brandAmber.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        minimumSize: const Size.fromHeight(52),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        elevation: 0,
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: brandAmber,
        side: const BorderSide(color: darkBorder, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        minimumSize: const Size.fromHeight(52),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: brandAmber,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: darkCard,
      surfaceTintColor: Colors.transparent,
      elevation: 12,
      shadowColor: Colors.black.withValues(alpha: 0.40),
      height: 64,
      indicatorColor: Colors.transparent,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: brandAmber, size: 26);
        }
        return const IconThemeData(color: darkMuted, size: 24);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(color: brandAmber, fontWeight: FontWeight.w700, fontSize: 11);
        }
        return const TextStyle(color: darkMuted, fontSize: 11);
      }),
    ),

    dividerTheme: const DividerThemeData(color: darkBorder, thickness: 1),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? brandAmber : darkMuted),
      trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? brandAmber.withValues(alpha: 0.40)
              : darkBorder),
    ),
  );
}
