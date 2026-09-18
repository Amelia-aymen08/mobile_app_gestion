import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppL10n
/// returned by `AppL10n.of(context)`.
///
/// Applications need to include `AppL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppL10n.localizationsDelegates,
///   supportedLocales: AppL10n.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppL10n.supportedLocales
/// property.
abstract class AppL10n {
  AppL10n(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppL10n of(BuildContext context) {
    return Localizations.of<AppL10n>(context, AppL10n)!;
  }

  static const LocalizationsDelegate<AppL10n> delegate = _AppL10nDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr')
  ];

  /// No description provided for @navHome.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get navHome;

  /// No description provided for @navNotice.
  ///
  /// In fr, this message translates to:
  /// **'Avis'**
  String get navNotice;

  /// No description provided for @navReport.
  ///
  /// In fr, this message translates to:
  /// **'Signaler'**
  String get navReport;

  /// No description provided for @navPayment.
  ///
  /// In fr, this message translates to:
  /// **'Paiements'**
  String get navPayment;

  /// No description provided for @navMore.
  ///
  /// In fr, this message translates to:
  /// **'Plus'**
  String get navMore;

  /// Titre du header de l'accueil
  ///
  /// In fr, this message translates to:
  /// **'Bonjour {name}'**
  String greeting(String name);

  /// No description provided for @myResidence.
  ///
  /// In fr, this message translates to:
  /// **'Ma résidence'**
  String get myResidence;

  /// No description provided for @apartmentBadge.
  ///
  /// In fr, this message translates to:
  /// **'Apt. {unit}'**
  String apartmentBadge(String unit);

  /// No description provided for @floor.
  ///
  /// In fr, this message translates to:
  /// **'Étage'**
  String get floor;

  /// No description provided for @area.
  ///
  /// In fr, this message translates to:
  /// **'Surface'**
  String get area;

  /// No description provided for @status.
  ///
  /// In fr, this message translates to:
  /// **'Statut'**
  String get status;

  /// No description provided for @statusActive.
  ///
  /// In fr, this message translates to:
  /// **'Actif'**
  String get statusActive;

  /// No description provided for @nextPayment.
  ///
  /// In fr, this message translates to:
  /// **'Prochain paiement'**
  String get nextPayment;

  /// No description provided for @paymentDeadline.
  ///
  /// In fr, this message translates to:
  /// **'Échéance : {date}'**
  String paymentDeadline(String date);

  /// No description provided for @reports.
  ///
  /// In fr, this message translates to:
  /// **'Signalements'**
  String get reports;

  /// No description provided for @reportsOpen.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun ouvert} =1{1 ouvert} other{{count} ouverts}}'**
  String reportsOpen(int count);

  /// No description provided for @reportsInProgress.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 en cours} other{{count} en cours}}'**
  String reportsInProgress(int count);

  /// No description provided for @quickActions.
  ///
  /// In fr, this message translates to:
  /// **'Actions rapides'**
  String get quickActions;

  /// No description provided for @notices.
  ///
  /// In fr, this message translates to:
  /// **'Avis'**
  String get notices;

  /// No description provided for @payments.
  ///
  /// In fr, this message translates to:
  /// **'Paiements'**
  String get payments;

  /// No description provided for @documents.
  ///
  /// In fr, this message translates to:
  /// **'Documents'**
  String get documents;

  /// No description provided for @profile.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get profile;

  /// No description provided for @recentActivity.
  ///
  /// In fr, this message translates to:
  /// **'Activité récente'**
  String get recentActivity;

  /// No description provided for @loginTitle.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue chez vous'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Connectez-vous à votre résidence.'**
  String get loginSubtitle;

  /// No description provided for @emailLabel.
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail'**
  String get emailLabel;

  /// No description provided for @emailHint.
  ///
  /// In fr, this message translates to:
  /// **'nom@exemple.com'**
  String get emailHint;

  /// No description provided for @passwordLabel.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get passwordLabel;

  /// No description provided for @passwordHint.
  ///
  /// In fr, this message translates to:
  /// **'Entrez votre mot de passe'**
  String get passwordHint;

  /// No description provided for @forgotPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié ?'**
  String get forgotPassword;

  /// No description provided for @loginCta.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get loginCta;

  /// No description provided for @firstLoginQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Première connexion ?'**
  String get firstLoginQuestion;

  /// No description provided for @firstLoginHelp.
  ///
  /// In fr, this message translates to:
  /// **' Utilisez les identifiants remis à la livraison des clés.'**
  String get firstLoginHelp;

  /// No description provided for @emailRequired.
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail requise'**
  String get emailRequired;

  /// No description provided for @passwordRequired.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe requis'**
  String get passwordRequired;

  /// No description provided for @noAccountQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Vous êtes résident et n\'avez pas encore de compte ?'**
  String get noAccountQuestion;

  /// No description provided for @signUp.
  ///
  /// In fr, this message translates to:
  /// **'S\'inscrire'**
  String get signUp;

  /// No description provided for @onbTitle1.
  ///
  /// In fr, this message translates to:
  /// **'QUI NOUS SOMMES'**
  String get onbTitle1;

  /// No description provided for @onbBody1.
  ///
  /// In fr, this message translates to:
  /// **'Des résidences d\'exception où le luxe, le confort et la vie moderne se rejoignent pour créer un art de vivre au-delà des attentes.'**
  String get onbBody1;

  /// No description provided for @onbTitle2.
  ///
  /// In fr, this message translates to:
  /// **'CE QUE NOUS OFFRONS'**
  String get onbTitle2;

  /// No description provided for @onbBody2.
  ///
  /// In fr, this message translates to:
  /// **'Des actualités de la résidence aux paiements, réservations et demandes d\'intervention : tout ce dont vous avez besoin, réuni dans une expérience fluide.'**
  String get onbBody2;

  /// No description provided for @onbTitle3.
  ///
  /// In fr, this message translates to:
  /// **'VIVRE L\'ESPRIT TRANQUILLE'**
  String get onbTitle3;

  /// No description provided for @onbBody3.
  ///
  /// In fr, this message translates to:
  /// **'Restez connecté, informé et pleinement maître de votre quotidien, avec des services haut de gamme pensés pour la vie moderne.'**
  String get onbBody3;

  /// No description provided for @skip.
  ///
  /// In fr, this message translates to:
  /// **'Passer'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get next;

  /// No description provided for @getStarted.
  ///
  /// In fr, this message translates to:
  /// **'Commencer'**
  String get getStarted;
}

class _AppL10nDelegate extends LocalizationsDelegate<AppL10n> {
  const _AppL10nDelegate();

  @override
  Future<AppL10n> load(Locale locale) {
    return SynchronousFuture<AppL10n>(lookupAppL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppL10nDelegate old) => false;
}

AppL10n lookupAppL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppL10nAr();
    case 'en':
      return AppL10nEn();
    case 'fr':
      return AppL10nFr();
  }

  throw FlutterError(
      'AppL10n.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
