import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/screens/app_entry.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/services/system_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final themeProvider = ThemeProvider();
  await themeProvider.restore();
  runApp(GeranceImmoServiceApp(themeProvider: themeProvider));

  // Fire-and-forget: the OS permission prompt must never block the first
  // frame — awaiting it here caused "app isn't responding" on cold start.
  unawaited(SystemNotificationService.instance.init());
}

class GeranceImmoServiceApp extends StatelessWidget {
  final ThemeProvider themeProvider;
  const GeranceImmoServiceApp({super.key, required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider.value(value: themeProvider),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, theme, _) => MaterialApp(
          title: 'Gérance Immo Service',
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(),
          darkTheme: buildAppThemeDark(),
          themeMode: theme.mode,
          home: const AppEntry(),
        ),
      ),
    );
  }
}
