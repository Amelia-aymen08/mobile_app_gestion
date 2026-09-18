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

  /// No description provided for @forgotTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié'**
  String get forgotTitle;

  /// No description provided for @forgotSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Entrez votre adresse e-mail, nous vous enverrons un lien pour réinitialiser votre mot de passe.'**
  String get forgotSubtitle;

  /// No description provided for @sendLink.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer le lien'**
  String get sendLink;

  /// No description provided for @emailSentTitle.
  ///
  /// In fr, this message translates to:
  /// **'E-mail envoyé'**
  String get emailSentTitle;

  /// No description provided for @emailSentBody.
  ///
  /// In fr, this message translates to:
  /// **'Si un compte existe avec l\'adresse {email}, un lien de réinitialisation vient d\'être envoyé. Pensez à vérifier vos indésirables.'**
  String emailSentBody(String email);

  /// No description provided for @backToLogin.
  ///
  /// In fr, this message translates to:
  /// **'Retour à la connexion'**
  String get backToLogin;

  /// No description provided for @addProperty.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un bien'**
  String get addProperty;

  /// No description provided for @alertPaymentTitle.
  ///
  /// In fr, this message translates to:
  /// **'Paiement urgent'**
  String get alertPaymentTitle;

  /// No description provided for @alertPaymentBody.
  ///
  /// In fr, this message translates to:
  /// **'Votre prochain paiement est dû le {date}.'**
  String alertPaymentBody(String date);

  /// No description provided for @alertPaymentHint.
  ///
  /// In fr, this message translates to:
  /// **'Appuyez ci-dessous pour consulter le détail et régler votre échéance.'**
  String get alertPaymentHint;

  /// No description provided for @close.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get close;

  /// No description provided for @viewPayment.
  ///
  /// In fr, this message translates to:
  /// **'Voir le paiement'**
  String get viewPayment;

  /// No description provided for @noticesSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Communications officielles'**
  String get noticesSubtitle;

  /// No description provided for @filterAll.
  ///
  /// In fr, this message translates to:
  /// **'Tous'**
  String get filterAll;

  /// No description provided for @filterUrgent.
  ///
  /// In fr, this message translates to:
  /// **'Urgent'**
  String get filterUrgent;

  /// No description provided for @filterInfo.
  ///
  /// In fr, this message translates to:
  /// **'Info'**
  String get filterInfo;

  /// No description provided for @filterEvent.
  ///
  /// In fr, this message translates to:
  /// **'Événement'**
  String get filterEvent;

  /// No description provided for @readMore.
  ///
  /// In fr, this message translates to:
  /// **'Lire la suite'**
  String get readMore;

  /// No description provided for @newCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 nouveau} other{{count} nouveaux}}'**
  String newCount(int count);

  /// No description provided for @emptyNoticesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun avis'**
  String get emptyNoticesTitle;

  /// No description provided for @emptyNoticesBody.
  ///
  /// In fr, this message translates to:
  /// **'Vous êtes à jour. Il n\'y a aucun avis à afficher pour le moment.'**
  String get emptyNoticesBody;

  /// No description provided for @logoutTitle.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter ?'**
  String get logoutTitle;

  /// No description provided for @logoutBody.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous vraiment vous déconnecter ?'**
  String get logoutBody;

  /// No description provided for @logoutHint.
  ///
  /// In fr, this message translates to:
  /// **'Vous pourrez vous reconnecter à tout moment avec les mêmes identifiants.'**
  String get logoutHint;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @logout.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get logout;

  /// No description provided for @myAccount.
  ///
  /// In fr, this message translates to:
  /// **'Mon compte'**
  String get myAccount;

  /// No description provided for @services.
  ///
  /// In fr, this message translates to:
  /// **'Services'**
  String get services;

  /// No description provided for @changePassword.
  ///
  /// In fr, this message translates to:
  /// **'Changer le mot de passe'**
  String get changePassword;

  /// No description provided for @darkTheme.
  ///
  /// In fr, this message translates to:
  /// **'Thème sombre'**
  String get darkTheme;

  /// No description provided for @language.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get language;

  /// No description provided for @phoneLabel.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone'**
  String get phoneLabel;

  /// No description provided for @notProvided.
  ///
  /// In fr, this message translates to:
  /// **'Non renseigné'**
  String get notProvided;

  /// No description provided for @selectLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Choisir la langue'**
  String get selectLanguage;

  /// No description provided for @langFrench.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get langFrench;

  /// No description provided for @langEnglish.
  ///
  /// In fr, this message translates to:
  /// **'English'**
  String get langEnglish;

  /// No description provided for @langArabic.
  ///
  /// In fr, this message translates to:
  /// **'العربية'**
  String get langArabic;

  /// No description provided for @notificationsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notifAnnouncements.
  ///
  /// In fr, this message translates to:
  /// **'Annonces'**
  String get notifAnnouncements;

  /// No description provided for @notifMaintenance.
  ///
  /// In fr, this message translates to:
  /// **'Suivi des interventions'**
  String get notifMaintenance;

  /// No description provided for @notifBookings.
  ///
  /// In fr, this message translates to:
  /// **'Réservations'**
  String get notifBookings;

  /// No description provided for @notifPayments.
  ///
  /// In fr, this message translates to:
  /// **'Paiements'**
  String get notifPayments;

  /// No description provided for @reportsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Suivez vos demandes de maintenance'**
  String get reportsSubtitle;

  /// No description provided for @filterInProgress.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get filterInProgress;

  /// No description provided for @filterDone.
  ///
  /// In fr, this message translates to:
  /// **'Terminés'**
  String get filterDone;

  /// No description provided for @tabMyReports.
  ///
  /// In fr, this message translates to:
  /// **'Mes signalements'**
  String get tabMyReports;

  /// No description provided for @tabCommonAreas.
  ///
  /// In fr, this message translates to:
  /// **'Copropriété'**
  String get tabCommonAreas;

  /// No description provided for @newReport.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau signalement'**
  String get newReport;

  /// No description provided for @emptyReportsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun signalement'**
  String get emptyReportsTitle;

  /// No description provided for @emptyReportsBody.
  ///
  /// In fr, this message translates to:
  /// **'Vous n\'avez encore signalé aucun problème. Utilisez le bouton ci-dessous pour en créer un.'**
  String get emptyReportsBody;

  /// No description provided for @roleResident.
  ///
  /// In fr, this message translates to:
  /// **'Résident'**
  String get roleResident;

  /// No description provided for @verified.
  ///
  /// In fr, this message translates to:
  /// **'Vérifié'**
  String get verified;

  /// No description provided for @changeResidence.
  ///
  /// In fr, this message translates to:
  /// **'Changer de résidence'**
  String get changeResidence;

  /// No description provided for @currentResidenceIs.
  ///
  /// In fr, this message translates to:
  /// **'Résidence actuelle : {name}'**
  String currentResidenceIs(String name);

  /// No description provided for @residenceUpper.
  ///
  /// In fr, this message translates to:
  /// **'RÉSIDENCE'**
  String get residenceUpper;

  /// No description provided for @blockUpper.
  ///
  /// In fr, this message translates to:
  /// **'BLOC'**
  String get blockUpper;

  /// No description provided for @memberSinceUpper.
  ///
  /// In fr, this message translates to:
  /// **'MEMBRE DEPUIS'**
  String get memberSinceUpper;

  /// No description provided for @settingsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Réglages'**
  String get settingsTitle;

  /// No description provided for @settingsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Notifications, langue, sécurité'**
  String get settingsSubtitle;

  /// No description provided for @myProperties.
  ///
  /// In fr, this message translates to:
  /// **'Mes biens'**
  String get myProperties;

  /// No description provided for @householdMembers.
  ///
  /// In fr, this message translates to:
  /// **'Membres du foyer'**
  String get householdMembers;

  /// No description provided for @apartmentShort.
  ///
  /// In fr, this message translates to:
  /// **'Apt. {unit}'**
  String apartmentShort(String unit);

  /// No description provided for @serviceCharges.
  ///
  /// In fr, this message translates to:
  /// **'Charges'**
  String get serviceCharges;

  /// No description provided for @currentPeriod.
  ///
  /// In fr, this message translates to:
  /// **'Période en cours'**
  String get currentPeriod;

  /// No description provided for @statusDue.
  ///
  /// In fr, this message translates to:
  /// **'À régler'**
  String get statusDue;

  /// No description provided for @totalDue.
  ///
  /// In fr, this message translates to:
  /// **'Total à régler'**
  String get totalDue;

  /// No description provided for @chargeBreakdown.
  ///
  /// In fr, this message translates to:
  /// **'Détail des charges'**
  String get chargeBreakdown;

  /// No description provided for @hideLabel.
  ///
  /// In fr, this message translates to:
  /// **'Masquer'**
  String get hideLabel;

  /// No description provided for @showLabel.
  ///
  /// In fr, this message translates to:
  /// **'Afficher'**
  String get showLabel;

  /// No description provided for @totalLabel.
  ///
  /// In fr, this message translates to:
  /// **'Total'**
  String get totalLabel;

  /// No description provided for @paymentHistory.
  ///
  /// In fr, this message translates to:
  /// **'Historique des paiements'**
  String get paymentHistory;

  /// No description provided for @emptyPaymentsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun paiement'**
  String get emptyPaymentsTitle;

  /// No description provided for @emptyPaymentsBody.
  ///
  /// In fr, this message translates to:
  /// **'Vous n\'avez encore réglé aucune charge.'**
  String get emptyPaymentsBody;

  /// No description provided for @affectedAreas.
  ///
  /// In fr, this message translates to:
  /// **'Blocs concernés'**
  String get affectedAreas;

  /// No description provided for @blockNamed.
  ///
  /// In fr, this message translates to:
  /// **'Bloc {name}'**
  String blockNamed(String name);
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
