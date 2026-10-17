// Fiche residence : les commodites tiennent sur deux lignes qui defilent
// ensemble de cote, et aucune n'est perdue.
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
import 'package:gestimou_mobile/presentation/screens/residence_details_screen.dart';
import 'package:gestimou_mobile/presentation/theme/app_theme.dart';

import 'support/fake_server.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ApiService().useClient(DemoClient(demoMulti));
  });

  testWidgets('commodites sur deux lignes, defilement commun',
      (tester) async {
    const size = Size(393, 852);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final residenceId = ((demoMulti.properties.first as Map)['Residence']
            as Map)['id']
        .toString();
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: MaterialApp(
        theme: buildAppTheme(),
        locale: const Locale('fr'),
        localizationsDelegates: const [
          AppL10n.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppL10n.supportedLocales,
        home: ResidenceDetailsScreen(
            residenceId: residenceId, residenceName: 'Corail'),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 600));

    final first = tester.getRect(find.text('Ascenseur'));
    final second = tester.getRect(find.text('Parking de stationnement'));
    final last = find.text('Bâche à eau');

    // Deux lignes : la deuxieme commodite passe sous la premiere.
    expect(second.top, greaterThan(first.bottom));
    // La derniere est hors de l'ecran avant de faire defiler.
    expect(tester.getRect(last).left, greaterThan(size.width));

    await tester.drag(find.text('Ascenseur'), const Offset(-400, 0));
    await tester.pumpAndSettle();

    // Elle est revenue dans l'ecran, et les deux lignes ont bouge ensemble.
    expect(tester.getRect(last).right, lessThanOrEqualTo(size.width));
    expect(tester.getRect(find.text('Parking de stationnement')).left,
        lessThan(second.left));
  });
}
