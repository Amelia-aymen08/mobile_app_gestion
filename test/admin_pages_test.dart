// Pages de l'administration ouvertes depuis « Plus » : avis, paiements,
// employes, inscriptions, ajouts de biens. Chacune doit s'ouvrir sans
// erreur ni debordement, en clair comme en sombre, sur un petit telephone.
// Et l'onglet quitte ne doit plus rester affiche par-dessus le suivant.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gestimou_mobile/data/api_service.dart';
import 'package:gestimou_mobile/l10n/app_localizations.dart';
import 'package:gestimou_mobile/presentation/providers/auth_provider.dart';
import 'package:gestimou_mobile/presentation/providers/locale_provider.dart';
import 'package:gestimou_mobile/presentation/providers/theme_provider.dart';
import 'package:gestimou_mobile/presentation/screens/admin/admin_residences_screen.dart';
import 'package:gestimou_mobile/presentation/screens/admin_notices_screen.dart';
import 'package:gestimou_mobile/presentation/screens/manager_home_screen.dart';
import 'package:gestimou_mobile/presentation/screens/property_add_requests_management_screen.dart';
import 'package:gestimou_mobile/presentation/screens/recouvrement_financial_screen.dart';
import 'package:gestimou_mobile/presentation/screens/registration_requests_screen.dart';
import 'package:gestimou_mobile/presentation/screens/user_management_screen.dart';
import 'package:gestimou_mobile/presentation/theme/app_theme.dart';

import 'support/fake_server.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 150));
  }
}

Widget _app(Widget home, {bool dark = false}) => MultiProvider(
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
        home: home,
      ),
    );

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ApiService().useClient(DemoAdminClient());
  });

  final pages = <String, Widget Function()>{
    'Annonces': () => const AdminNoticesScreen(),
    'Paiements': () => const RecouvrementFinancialScreen(),
    'Employés': () => const UserManagementScreen(),
    'Inscriptions': () => const RegistrationRequestsScreen(),
    'Ajouts de biens': () => const PropertyAddRequestsManagementScreen(),
  };

  for (final dark in [false, true]) {
    for (final page in pages.entries) {
      testWidgets('${page.key} — ${dark ? 'sombre' : 'clair'}', (tester) async {
        tester.view.physicalSize = const Size(360, 740);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(_app(page.value(), dark: dark));
        await _settle(tester);
        expect(tester.takeException(), isNull);
        expect(find.text(page.key), findsWidgets);
      });
    }
  }

  testWidgets('Paiements — filtre par residence et charge ouverte',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(const RecouvrementFinancialScreen()));
    await _settle(tester);
    await tester.tap(find.text('Péridot').first);
    await _settle(tester);
    await tester.tap(find.textContaining('Payées ·'));
    await _settle(tester);
    await tester.scrollUntilVisible(find.text('Karim Haddad'), 200,
        scrollable: find
            .descendant(
                of: find.byType(CustomScrollView),
                matching: find.byType(Scrollable))
            .first);
    await tester.tap(find.text('Karim Haddad').first);
    await _settle(tester);
    expect(find.text('Marquer impayée'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Onglet quitte : il ne reste pas affiche', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(const ManagerHomeScreen()));
    await _settle(tester);
    await tester.tap(find.text('Résidences').last);
    await _settle(tester);
    await tester.tap(find.text('Accueil').last);
    await _settle(tester);

    final fade = tester.renderObject<RenderAnimatedOpacity>(find
        .ancestor(
            of: find.byType(AdminResidencesScreen),
            matching: find.byType(AnimatedOpacity))
        .first);
    expect(fade.opacity.value, 0);
  });
}
