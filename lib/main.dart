import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  // La barre d'etat prend la couleur de l'ecran au lieu du gris pose par
  // Android. Les icones restent sombres : nos fonds sont clairs, et le
  // theme sombre les repasse en clair au moment ou il s'applique.
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    // L'app s'ouvre en theme sombre : les icones de la barre d'etat sont
    // claires des la premiere image. Le theme les reprend ensuite, et les
    // repasse en sombre si le resident choisit le clair.
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  ));
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
            child: _GiScaffoldFrame(child: child),
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

  /// Arrive en bout de liste, le contenu continue un peu, resiste, puis
  /// revient : le geste dit de lui-meme qu'il n'y a plus rien en dessous.
  /// Un arret net laisse croire a un blocage.
  ///
  /// `RangeMaintainingScrollPhysics` en parent : quand une image finit de se
  /// charger au-dessus de ce qu'on lit, elle conserve la position au lieu de
  /// faire sauter la liste. C'est la principale source de saccade a l'usage.
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(parent: RangeMaintainingScrollPhysics());

  /// Le halo bleu d'Android en bout de liste n'existe pas dans le Figma et
  /// jure avec l'ambre. Le rebond dit deja qu'on est au bout.
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

/// Cadre applique a tous les ecrans.
///
/// Deux reglages qui ne dependent d'aucun ecran en particulier :
///
/// 1. La taille de police du systeme est ramenee dans une plage utilisable.
///    Android et iOS laissent la pousser jusqu'a deux fois : les cartes du
///    Figma, dont plusieurs ont une hauteur fixe, deborderaient. La borne
///    haute reste genereuse (1,25) pour rester lisible.
/// 2. Au-dela de 600 de large — tablette, fenetre de navigateur — le contenu
///    est centre sur une colonne de 560. Une maquette dessinee pour 375 ne
///    gagne rien a etre etiree sur toute la largeur.
class _GiScaffoldFrame extends StatelessWidget {
  final Widget? child;
  const _GiScaffoldFrame({required this.child});

  static const maxContentWidth = 560.0;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final scale = media.textScaler.clamp(minScaleFactor: 0.85, maxScaleFactor: 1.25);

    Widget content = child ?? const SizedBox.shrink();
    if (media.size.width > 600) {
      content = Align(
        alignment: Alignment.topCenter,
        child: SizedBox(width: maxContentWidth, child: content),
      );
    }
    return MediaQuery(data: media.copyWith(textScaler: scale), child: content);
  }
}
