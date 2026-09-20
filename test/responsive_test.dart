// Verifie qu'aucun ecran resident ne deborde aux tailles d'ecran reelles.
//
// Flutter signale un debordement par une exception ; `tester.takeException()`
// la rend visible ici. Les tailles couvrent le plus petit Android encore
// courant jusqu'a une tablette, en portrait, avec la police du systeme au
// maximum de ce que l'app autorise.
//
// Les ecrans parlent au faux serveur (DemoClient) : le test n'a pas besoin
// du back-end.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gestimou_mobile/data/api_service.dart';

import 'support/fake_server.dart';
import 'package:gestimou_mobile/l10n/app_localizations.dart';
import 'package:gestimou_mobile/presentation/providers/auth_provider.dart';
import 'package:gestimou_mobile/presentation/providers/locale_provider.dart';
import 'package:gestimou_mobile/presentation/providers/theme_provider.dart';
import 'package:gestimou_mobile/presentation/screens/change_password_screen.dart';
import 'package:gestimou_mobile/presentation/screens/chat_screen.dart';
import 'package:gestimou_mobile/presentation/screens/forgot_password_screen.dart';
import 'package:gestimou_mobile/presentation/screens/onboarding_screen.dart';
import 'package:gestimou_mobile/presentation/screens/property_add_request_screen.dart';
import 'package:gestimou_mobile/presentation/screens/splash_screen.dart';
import 'package:gestimou_mobile/presentation/screens/documents_screen.dart';
import 'package:gestimou_mobile/presentation/screens/residence_details_screen.dart';
import 'package:gestimou_mobile/presentation/screens/resident_create_ticket_screen.dart';
import 'package:gestimou_mobile/presentation/screens/household_members_screen.dart';
import 'package:gestimou_mobile/presentation/screens/login_screen.dart';
import 'package:gestimou_mobile/presentation/screens/my_charges_screen.dart';
import 'package:gestimou_mobile/presentation/screens/my_properties_screen.dart';
import 'package:gestimou_mobile/presentation/screens/notices_screen.dart';
import 'package:gestimou_mobile/presentation/screens/notifications_screen.dart';
import 'package:gestimou_mobile/presentation/screens/registration_screen.dart';
import 'package:gestimou_mobile/presentation/screens/resident_home_screen.dart';
import 'package:gestimou_mobile/presentation/screens/resident_profile_screen.dart';
import 'package:gestimou_mobile/presentation/screens/resident_tickets_screen.dart';
import 'package:gestimou_mobile/presentation/theme/app_theme.dart';

/// Tailles logiques, en points, telles que Flutter les voit.
const _sizes = <String, Size>{
  'petit Android (320x568)': Size(320, 568),
  'Android courant (360x640)': Size(360, 640),
  'iPhone 15 (393x852)': Size(393, 852),
  'iPhone Max (430x932)': Size(430, 932),
  'tablette (768x1024)': Size(768, 1024),
  // Paysage : un telephone tourne garde la meme largeur de contenu mais
  // perd les deux tiers de sa hauteur.
  'paysage (640x360)': Size(640, 360),
};

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    // Le faux serveur repond a la place du back-end.
    ApiService().useClient(DemoClient(demoMulti));
  });

  Widget harness(Widget screen,
      {Brightness brightness = Brightness.light, Locale? locale}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: MaterialApp(
        theme: brightness == Brightness.dark ? buildAppThemeDark() : buildAppTheme(),
        localizationsDelegates: const [
          AppL10n.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppL10n.supportedLocales,
        locale: locale,
        home: screen,
      ),
    );
  }

  /// Pose l'ecran a la taille voulue, laisse les chargements se terminer, et
  /// echoue si Flutter a signale un debordement.
  Future<void> pumpAt(WidgetTester tester, Widget screen, Size size,
      {double textScale = 1.25,
      Brightness brightness = Brightness.light,
      Locale? locale,
      double keyboard = 0}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
          // Encoche et barre de geste d'un telephone recent.
          padding: const EdgeInsets.only(top: 47, bottom: 34),
          viewInsets: EdgeInsets.only(bottom: keyboard),
        ),
        child: harness(screen, brightness: brightness, locale: locale),
      ),
    );
    // Les ecrans chargent leurs donnees : on laisse passer la latence du
    // faux serveur, puis les animations d'entree.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 600));

    final error = tester.takeException();
    expect(error, isNull, reason: '$screen a leve : $error');
  }

  final screens = <String, Widget Function()>{
    'Connexion': () => const LoginScreen(),
    'Inscription': () => const RegistrationScreen(),
    'Accueil': () => const ResidentHomeScreen(),
    'Avis': () => const NoticesScreen(),
    'Signalements': () => const ResidentTicketsScreen(),
    'Paiements': () => const MyChargesScreen(),
    'Mes biens': () => const MyPropertiesScreen(),
    'Notifications': () => const NotificationsScreen(),
    'Foyer': () => const HouseholdMembersScreen(),
    'Documents': () => const DocumentsScreen(),
    'Reglages': () => const ResidentProfileScreen(),
    'Detail avis': () => NoticeDetailScreen(
          notice: Map<String, dynamic>.from(demoMulti.announcements.first),
        ),
    'Fiche residence': () => ResidenceDetailsScreen(
          residenceId: (Map<String, dynamic>.from(
                  demoMulti.properties.first as Map)['Residence']
              as Map)['id']
              .toString(),
          residenceName: 'Corail',
        ),
    'Nouveau signalement': () => ResidentCreateTicketScreen(
          property: Map<String, dynamic>.from(
              demoMulti.properties.first as Map),
        ),
    'Splash': () => const SplashScreen(),
    'Onboarding': () => OnboardingScreen(onComplete: () {}),
    'Mot de passe oublie': () => const ForgotPasswordScreen(),
    'Changer le mot de passe': () => const ChangePasswordScreen(),
    'Ajout de bien': () => const PropertyAddRequestScreen(),
    'Conversation': () => const ChatScreen(
          ticketId: 't1',
          title: 'Interphone du bloc A hors service',
          subtitle: '#T1',
        ),
  };

  for (final entry in screens.entries) {
    for (final size in _sizes.entries) {
      testWidgets('${entry.key} — ${size.key}', (tester) async {
        await pumpAt(tester, entry.value(), size.value);
      });
    }
  }

  // Clavier ouvert : sur un telephone, il mange environ 300 points. Les
  // ecrans de saisie doivent rester utilisables sans rien couper.
  const formulaires = <String>[
    'Connexion',
    'Inscription',
    'Mot de passe oublie',
    'Changer le mot de passe',
    'Nouveau signalement',
    'Ajout de bien',
    'Conversation',
    'Foyer',
  ];
  for (final name in formulaires) {
    testWidgets('$name — clavier ouvert', (tester) async {
      await pumpAt(tester, screens[name]!(), const Size(360, 640),
          keyboard: 300);
    });
  }

  // L'arabe ecrit de droite a gauche et allonge certains libelles : une
  // passe sur le format le plus contraint suffit a reperer un debordement
  // propre a cette langue.
  for (final entry in screens.entries) {
    testWidgets('${entry.key} — arabe, petit ecran', (tester) async {
      await pumpAt(tester, entry.value(), const Size(320, 568),
          locale: const Locale('ar'));
    });
  }

  // Le theme sombre change les couleurs, pas les tailles ; une passe sur le
  // format le plus contraint suffit a verifier qu'il ne casse rien.
  for (final entry in screens.entries) {
    testWidgets('${entry.key} — sombre, petit ecran', (tester) async {
      await pumpAt(tester, entry.value(), const Size(320, 568),
          brightness: Brightness.dark);
    });
  }
}
