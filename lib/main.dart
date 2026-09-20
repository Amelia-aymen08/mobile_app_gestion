import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'presentation/l10n/l10n.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/screens/app_entry.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/services/system_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final themeProvider = ThemeProvider();
  await themeProvider.restore();
  final localeProvider = LocaleProvider();
  await localeProvider.restore();
  runApp(GeranceImmoServiceApp(
      themeProvider: themeProvider, localeProvider: localeProvider));

  // Fire-and-forget: the OS permission prompt must never block the first
  // frame — awaiting it here caused "app isn't responding" on cold start.
  unawaited(SystemNotificationService.instance.init());
}

class GeranceImmoServiceApp extends StatelessWidget {
  final ThemeProvider themeProvider;
  final LocaleProvider localeProvider;
  const GeranceImmoServiceApp(
      {super.key, required this.themeProvider, required this.localeProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: localeProvider),
      ],
      child: Consumer2<ThemeProvider, LocaleProvider>(
        builder: (context, theme, localeState, _) => MaterialApp(
          title: 'Gérance Immo Service',
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(),
          darkTheme: buildAppThemeDark(),
          themeMode: theme.mode,
          locale: localeState.locale,
          supportedLocales: AppLang.values.map((l) => l.locale).toList(),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          // UI strings are resolved through a global (see l10n.dart), so a
          // language change rebuilds the whole navigator: every screen is
          // recreated in the new language and text direction.
          builder: (context, child) => KeyedSubtree(
            key: ValueKey(localeState.lang),
            child: child ?? const SizedBox.shrink(),
          ),
          home: const AppEntry(),
        ),
      ),
    );
  }
}
