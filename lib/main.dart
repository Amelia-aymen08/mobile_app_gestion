import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'l10n/app_localizations.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/locale_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/screens/app_entry.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/services/system_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final themeProvider = ThemeProvider();
  final localeProvider = LocaleProvider();
  await Future.wait([themeProvider.restore(), localeProvider.restore()]);
  runApp(GeranceImmoServiceApp(
    themeProvider: themeProvider,
    localeProvider: localeProvider,
  ));

  // Fire-and-forget: the OS permission prompt must never block the first
  // frame — awaiting it here caused "app isn't responding" on cold start.
  unawaited(SystemNotificationService.instance.init());
}

class GeranceImmoServiceApp extends StatelessWidget {
  final ThemeProvider themeProvider;
  final LocaleProvider localeProvider;
  const GeranceImmoServiceApp({
    super.key,
    required this.themeProvider,
    required this.localeProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: localeProvider),
      ],
      child: Consumer2<ThemeProvider, LocaleProvider>(
        builder: (context, theme, locale, _) => MaterialApp(
          title: 'Gérance Immo Service',
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(),
          darkTheme: buildAppThemeDark(),
          themeMode: theme.mode,
          scrollBehavior: const GiScrollBehavior(),
          locale: locale.locale,
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: const [
            AppL10n.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          // Un appui hors d'un champ referme le clavier, sur tous les ecrans.
          // Pose ici plutot que dans chaque page : tout ecran ajoute plus tard
          // en herite sans rien avoir a faire.
          //
          // `translucent` laisse passer les appuis vers les widgets en dessous,
          // qui gagnent l'arbitrage des gestes : les boutons continuent donc de
          // repondre normalement.
          builder: (context, child) => GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: child,
          ),
          home: const AppEntry(),
        ),
      ),
    );
  }
}


/// Physique de defilement commune a toute l'app.
///
/// Par defaut Flutter applique le rebond iOS : arrive en bout de liste, le
/// contenu continue puis revient en arriere. Cet effet elastique gene la
/// lecture des listes longues, on lui prefere un arret net.
///
/// Les appareils de pointage sont ajoutes pour que le defilement a la souris
/// fonctionne dans le navigateur, ou l'app est testee.
class GiScrollBehavior extends MaterialScrollBehavior {
  const GiScrollBehavior();

  /// `RangeMaintainingScrollPhysics` en parent : quand une image finit de se
  /// charger au-dessus de ce qu'on lit, elle conserve la position au lieu de
  /// faire sauter la liste. C'est la principale source de saccade a l'usage.
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const ClampingScrollPhysics(parent: RangeMaintainingScrollPhysics());

  /// Le halo bleu d'Android en bout de liste n'existe pas dans le Figma, et
  /// jure avec l'ambre. L'arret net suffit a dire qu'on est au bout.
  @override
  Widget buildOverscrollIndicator(
          BuildContext context, Widget child, ScrollableDetails details) =>
      child;

  /// Avec deux doigts poses, suivre le dernier evite le blocage du defilement
  /// quand un doigt reste immobile.
  @override
  MultitouchDragStrategy getMultitouchDragStrategy(BuildContext context) =>
      MultitouchDragStrategy.latestPointer;

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}
