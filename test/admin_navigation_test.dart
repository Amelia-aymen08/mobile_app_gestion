// Fluidite de l'administration : glissement retour sur iOS, brouillon
// protege a la sortie d'un ticket, erreur reseau dite comme telle.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gestimou_mobile/data/api_service.dart';
import 'package:gestimou_mobile/l10n/app_localizations.dart';
import 'package:gestimou_mobile/presentation/providers/auth_provider.dart';
import 'package:gestimou_mobile/presentation/providers/locale_provider.dart';
import 'package:gestimou_mobile/presentation/providers/theme_provider.dart';
import 'package:gestimou_mobile/presentation/screens/admin/admin_ticket_screen.dart';
import 'package:gestimou_mobile/presentation/screens/admin/admin_ui.dart';
import 'package:gestimou_mobile/presentation/screens/admin/admin_assignee_picker.dart';
import 'package:gestimou_mobile/presentation/screens/admin/admin_store.dart';
import 'package:gestimou_mobile/presentation/screens/manager_home_screen.dart';
import 'package:gestimou_mobile/presentation/screens/recouvrement_financial_screen.dart';
import 'package:gestimou_mobile/presentation/screens/user_management_screen.dart';
import 'package:gestimou_mobile/presentation/theme/app_theme.dart';
import 'package:gestimou_mobile/presentation/theme/ticket_status.dart';
import 'package:gestimou_mobile/presentation/widgets/gi_primary_button.dart';

import 'support/fake_server.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 150));
  }
}

Future<void> _pumpAdmin(WidgetTester tester,
    {Widget home = const ManagerHomeScreen()}) async {
  tester.view.physicalSize = const Size(390, 844);
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
      localizationsDelegates: const [
        AppL10n.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppL10n.supportedLocales,
      home: home,
    ),
  ));
  await _settle(tester);
}

/// Pousse [page] par-dessus un ecran vide, pour pouvoir tester le retour.
Widget _pushed(Widget page) => Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => adminPush(context, page),
            child: const Text('ouvrir'),
          ),
        ),
      ),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('iOS : un glissement depuis le bord ferme le ticket',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    ApiService().useClient(DemoAdminClient());
    await _pumpAdmin(tester);

    await tester.tap(find.text('Traiter'));
    await _settle(tester);
    expect(find.byType(AdminTicketScreen), findsOneWidget);

    await tester.timedDragFrom(const Offset(4, 420), const Offset(300, 0),
        const Duration(milliseconds: 200));
    await _settle(tester);
    expect(find.byType(AdminTicketScreen), findsNothing);
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('Un brouillon non enregistre demande un second retour',
      (tester) async {
    ApiService().useClient(DemoAdminClient());
    await _pumpAdmin(tester);

    await tester.tap(find.text('Traiter'));
    await _settle(tester);
    await tester.tap(find.text(TicketStage.sav.label).last);
    await tester.pump();
    expect(find.text('Enregistrer'), findsOneWidget);

    await tester.tap(find.byType(AdminBackButton));
    await _settle(tester);
    expect(find.byType(AdminTicketScreen), findsOneWidget);
    expect(find.textContaining('Modifications non enregistrées'),
        findsOneWidget);

    await tester.tap(find.byType(AdminBackButton));
    await _settle(tester);
    expect(find.byType(AdminTicketScreen), findsNothing);
    // Laisse le bandeau finir de s'effacer.
    await tester.pump(const Duration(seconds: 4));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Sans serveur, l\'accueil dit que la connexion a echoue',
      (tester) async {
    ApiService().useClient(MockClient((_) async => http.Response('', 500)));
    await _pumpAdmin(tester);
    expect(find.text('Connexion impossible'), findsOneWidget);
    expect(find.text('Tout est sous contrôle'), findsNothing);
    expect(find.text('Réessayer'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Paiements : le retour quitte d\'abord la sélection',
      (tester) async {
    ApiService().useClient(DemoAdminClient());
    await _pumpAdmin(tester,
        home: _pushed(const RecouvrementFinancialScreen()));
    await tester.tap(find.text('ouvrir'));
    await _settle(tester);

    await tester.longPress(find.text('Nadia Ferhat').first);
    await _settle(tester);
    expect(find.text('1 sélectionnée'), findsOneWidget);

    await tester.tap(find.byType(AdminBackButton));
    await _settle(tester);
    expect(find.byType(RecouvrementFinancialScreen), findsOneWidget);
    expect(find.text('1 sélectionnée'), findsNothing);

    await tester.tap(find.byType(AdminBackButton));
    await _settle(tester);
    expect(find.byType(RecouvrementFinancialScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Employés : le mot de passe demande 8 caractères',
      (tester) async {
    ApiService().useClient(DemoAdminClient());
    await _pumpAdmin(tester, home: const UserManagementScreen());

    await tester.tap(find.text('Rachid Mansouri'));
    await _settle(tester);
    await tester.tap(find.text('Changer le mot de passe'));
    await _settle(tester);

    GiPrimaryButton save() =>
        tester.widget<GiPrimaryButton>(find.byType(GiPrimaryButton));
    await tester.enterText(find.byType(TextField).last, 'abc123');
    await tester.pump();
    expect(save().onPressed, isNull);
    await tester.enterText(find.byType(TextField).last, 'abcd1234');
    await tester.pump();
    expect(save().onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Intervenants : une liste vide propose de réessayer',
      (tester) async {
    ApiService().useClient(MockClient((_) async => http.Response('', 500)));
    await _pumpAdmin(tester,
        home: AdminAssigneePicker(store: AdminStore(role: 'ADMIN'), current: ''));
    expect(find.text('Liste indisponible'), findsOneWidget);
    expect(find.text('Réessayer'), findsOneWidget);

    ApiService().useClient(DemoAdminClient());
    await tester.tap(find.text('Réessayer'));
    await _settle(tester);
    expect(find.text('ElecPro Services'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
