// Parcours de l'administration redessinee : accueil, tickets, fiche d'un
// ticket, residences, sur telephone et sur ordinateur, en clair et en
// sombre. Le faux serveur d'administration fournit les donnees.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gestimou_mobile/data/api_service.dart';
import 'package:gestimou_mobile/l10n/app_localizations.dart';
import 'package:gestimou_mobile/presentation/providers/auth_provider.dart';
import 'package:gestimou_mobile/presentation/providers/locale_provider.dart';
import 'package:gestimou_mobile/presentation/providers/theme_provider.dart';
import 'package:gestimou_mobile/presentation/screens/admin/admin_residence_screen.dart';
import 'package:gestimou_mobile/presentation/screens/admin/admin_ticket_screen.dart';
import 'package:gestimou_mobile/presentation/screens/manager_home_screen.dart';
import 'package:gestimou_mobile/presentation/theme/app_theme.dart';

import 'support/fake_server.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 150));
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ApiService().useClient(DemoAdminClient());
  });

  final cases = {
    'telephone': const Size(390, 844),
    'ordinateur': const Size(1440, 900),
  };

  for (final dark in [false, true]) {
    for (final entry in cases.entries) {
      final label = '${entry.key} ${dark ? 'sombre' : 'clair'}';
      testWidgets('Administration — $label', (tester) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(create: (_) => LocaleProvider()),
          ],
          child: MaterialApp(
            theme: buildAppTheme(),
            darkTheme: buildAppThemeDark(),
            themeMode: dark ? ThemeMode.dark : ThemeMode.light,
            localizationsDelegates: const [
              AppL10n.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppL10n.supportedLocales,
            home: const ManagerHomeScreen(),
          ),
        ));
        await _settle(tester);
        expect(tester.takeException(), isNull);

        // L'accueil propose le ticket le plus pressant : on l'ouvre.
        expect(find.text('Traiter'), findsOneWidget);
        await tester.tap(find.text('Traiter'));
        await _settle(tester);
        expect(find.byType(AdminTicketScreen), findsOneWidget);
        expect(find.text('Gestion'), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Depuis le ticket, la residence s'ouvre.
        await tester.tap(find.byIcon(Icons.apartment_rounded).first);
        await _settle(tester);
        expect(find.byType(AdminResidenceScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
