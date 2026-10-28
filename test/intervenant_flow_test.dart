// Parcours de l'intervenant : accueil, commencer une mission, la terminer
// avec un compte rendu, la retrouver dans les terminees, ouvrir sa fiche,
// puis le profil. En clair et en sombre, sur telephone.
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
import 'package:gestimou_mobile/presentation/screens/admin/admin_ui.dart';
import 'package:gestimou_mobile/presentation/screens/intervenant/intervenant_mission_screen.dart';
import 'package:gestimou_mobile/presentation/screens/intervenant/intervenant_missions_screen.dart';
import 'package:gestimou_mobile/presentation/screens/intervenant/intervenant_today_screen.dart';
import 'package:gestimou_mobile/presentation/screens/intervenant_home_screen.dart';
import 'package:gestimou_mobile/presentation/theme/app_theme.dart';
import 'package:gestimou_mobile/presentation/widgets/gi_bottom_nav.dart';

import 'support/intervenant_fake_server.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 14; i++) {
    await tester.pump(const Duration(milliseconds: 150));
  }
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 100));
  await tester.tap(finder);
  await _settle(tester);
}

// Les trois onglets restent montes : on cherche dans celui qu'on regarde.
Finder _today(String text) => find.descendant(
    of: find.byType(IntervenantTodayScreen), matching: find.text(text));
Finder _missions(String text) => find.descendant(
    of: find.byType(IntervenantMissionsScreen), matching: find.text(text));
Finder _tab(String label) =>
    find.descendant(of: find.byType(GiBottomNav), matching: find.text(label));

void main() {
  for (final dark in [false, true]) {
    testWidgets('Intervenant — ${dark ? 'sombre' : 'clair'}', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final server = DemoIntervenantClient();
      ApiService().useClient(server);
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final auth = AuthProvider();
      await tester.runAsync(() => auth.login('rachid@demo.dz', 'demo'));

      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: auth),
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
          home: const IntervenantHomeScreen(),
        ),
      ));
      await _settle(tester);
      expect(tester.takeException(), isNull);

      // L'accueil met en avant la mission en cours et son bouton.
      expect(_today('Bonjour Rachid'), findsOneWidget);
      expect(_today('EN COURS'), findsOneWidget);
      expect(_today('Interphone hors service'), findsOneWidget);
      expect(_today("J'ai terminé"), findsOneWidget);

      // Commencer la plus urgente des missions en attente : un appui.
      await _tap(tester, _today('Commencer').first);
      expect(server.updates.last.$1, 'tk-d0e962');
      expect(server.updates.last.$2, {'status': 'En cours'});
      expect(server.ticket('tk-d0e962')['status'], 'En cours');
      expect(tester.takeException(), isNull);

      // Elle passe en tete : l'urgent d'abord. On la termine avec un
      // compte rendu choisi d'un appui.
      expect(_today('Éclairage parking en panne'), findsOneWidget);
      await _tap(tester, _today("J'ai terminé").first);
      expect(find.text('Terminer la mission'), findsOneWidget);
      await _tap(tester, find.text('Réparation effectuée'));
      await _tap(tester, find.text('Valider la fin de la mission'));
      expect(server.updates.last.$1, 'tk-d0e962');
      expect(server.updates.last.$2,
          {'status': 'Terminé', 'note': 'Réparation effectuée'});
      expect(find.text('Terminer la mission'), findsNothing);
      expect(tester.takeException(), isNull);

      // L'accueil revient a la mission qui reste en cours.
      expect(_today('Interphone hors service'), findsOneWidget);
      expect(_today('Éclairage parking en panne'), findsNothing);

      // Onglet Missions : elle est rangee dans les terminees.
      await _tap(tester, _tab('Missions'));
      expect(find.text('Mes missions'), findsOneWidget);
      // La puce est au bout de la rangee, qui defile de cote.
      await tester.scrollUntilVisible(_missions('Terminées'), 120,
          scrollable: find
              .descendant(
                  of: find.byType(IntervenantMissionsScreen),
                  matching: find.byType(Scrollable))
              .at(1));
      await _tap(tester, _missions('Terminées'));
      expect(_missions('Éclairage parking en panne'), findsOneWidget);

      // Sa fiche dit qu'elle est terminee et n'offre plus d'action.
      await _tap(tester, _missions('Éclairage parking en panne'));
      expect(find.byType(IntervenantMissionScreen), findsOneWidget);
      Finder detail(String text) => find.descendant(
          of: find.byType(IntervenantMissionScreen), matching: find.text(text));
      expect(detail('Terminée'), findsWidgets);
      expect(detail('Sur place'), findsOneWidget);
      expect(detail('Appeler'), findsOneWidget);
      expect(detail('Commencer'), findsNothing);
      expect(detail("J'ai terminé"), findsNothing);
      expect(tester.takeException(), isNull);

      await _tap(
          tester,
          find.descendant(
              of: find.byType(IntervenantMissionScreen),
              matching: find.byType(AdminBackButton)));

      // Profil : le compte des missions terminees a suivi.
      await _tap(tester, _tab('Profil'));
      expect(find.text('Missions terminées'), findsOneWidget);
      expect(find.text('4'), findsWidgets);
      expect(find.text('Électricien'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
