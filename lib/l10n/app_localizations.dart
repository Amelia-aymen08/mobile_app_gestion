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

  /// No description provided for @timelineTitle.
  ///
  /// In fr, this message translates to:
  /// **'Chronologie'**
  String get timelineTitle;

  /// No description provided for @dateLabel.
  ///
  /// In fr, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// No description provided for @timeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Horaire'**
  String get timeLabel;

  /// No description provided for @whatToDo.
  ///
  /// In fr, this message translates to:
  /// **'Que devez-vous faire ?'**
  String get whatToDo;

  /// No description provided for @shareNotice.
  ///
  /// In fr, this message translates to:
  /// **'Partager l\'avis'**
  String get shareNotice;

  /// No description provided for @markAsRead.
  ///
  /// In fr, this message translates to:
  /// **'Marquer comme lu'**
  String get markAsRead;

  /// No description provided for @estimated.
  ///
  /// In fr, this message translates to:
  /// **'estimé'**
  String get estimated;

  /// No description provided for @category.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie'**
  String get category;

  /// No description provided for @issueType.
  ///
  /// In fr, this message translates to:
  /// **'Type de problème'**
  String get issueType;

  /// No description provided for @descriptionLabel.
  ///
  /// In fr, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @describeProblem.
  ///
  /// In fr, this message translates to:
  /// **'Décrivez le problème en détail…'**
  String get describeProblem;

  /// No description provided for @priorityLabel.
  ///
  /// In fr, this message translates to:
  /// **'Priorité'**
  String get priorityLabel;

  /// No description provided for @priorityLow.
  ///
  /// In fr, this message translates to:
  /// **'Basse'**
  String get priorityLow;

  /// No description provided for @priorityMedium.
  ///
  /// In fr, this message translates to:
  /// **'Moyenne'**
  String get priorityMedium;

  /// No description provided for @priorityHigh.
  ///
  /// In fr, this message translates to:
  /// **'Haute'**
  String get priorityHigh;

  /// No description provided for @priorityUrgent.
  ///
  /// In fr, this message translates to:
  /// **'Urgente'**
  String get priorityUrgent;

  /// No description provided for @attachPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Joindre une photo'**
  String get attachPhoto;

  /// No description provided for @submitReport.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer le signalement'**
  String get submitReport;

  /// No description provided for @you.
  ///
  /// In fr, this message translates to:
  /// **'Vous'**
  String get you;

  /// No description provided for @primaryResident.
  ///
  /// In fr, this message translates to:
  /// **'Résident principal'**
  String get primaryResident;

  /// No description provided for @fullAccess.
  ///
  /// In fr, this message translates to:
  /// **'Accès complet'**
  String get fullAccess;

  /// No description provided for @residentAccess.
  ///
  /// In fr, this message translates to:
  /// **'Accès résident'**
  String get residentAccess;

  /// No description provided for @visitorAccess.
  ///
  /// In fr, this message translates to:
  /// **'Accès visiteur'**
  String get visitorAccess;

  /// No description provided for @customAccess.
  ///
  /// In fr, this message translates to:
  /// **'Accès personnalisé'**
  String get customAccess;

  /// No description provided for @addMember.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un membre'**
  String get addMember;

  /// No description provided for @edit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get edit;

  /// No description provided for @remove.
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get remove;

  /// No description provided for @statusOpen.
  ///
  /// In fr, this message translates to:
  /// **'Ouvert'**
  String get statusOpen;

  /// No description provided for @statusInProgress.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get statusInProgress;

  /// No description provided for @statusResolved.
  ///
  /// In fr, this message translates to:
  /// **'Terminé'**
  String get statusResolved;

  /// No description provided for @reportDetails.
  ///
  /// In fr, this message translates to:
  /// **'Détail du signalement'**
  String get reportDetails;

  /// No description provided for @reportedOn.
  ///
  /// In fr, this message translates to:
  /// **'Signalé le'**
  String get reportedOn;

  /// No description provided for @photosCount.
  ///
  /// In fr, this message translates to:
  /// **'Photos ({count})'**
  String photosCount(int count);

  /// No description provided for @addMore.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get addMore;

  /// No description provided for @reportChat.
  ///
  /// In fr, this message translates to:
  /// **'Conversation'**
  String get reportChat;

  /// No description provided for @editLabel.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get editLabel;

  /// No description provided for @noPhotos.
  ///
  /// In fr, this message translates to:
  /// **'Aucune photo'**
  String get noPhotos;

  /// No description provided for @typeMessage.
  ///
  /// In fr, this message translates to:
  /// **'Écrivez un message…'**
  String get typeMessage;

  /// No description provided for @noMessages.
  ///
  /// In fr, this message translates to:
  /// **'Aucun message pour le moment.'**
  String get noMessages;

  /// No description provided for @today.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In fr, this message translates to:
  /// **'Hier'**
  String get yesterday;

  /// No description provided for @switchResidenceSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Passez d\'un bien à l\'autre'**
  String get switchResidenceSubtitle;

  /// No description provided for @yourProperties.
  ///
  /// In fr, this message translates to:
  /// **'Vos biens ({count})'**
  String yourProperties(int count);

  /// No description provided for @switchAction.
  ///
  /// In fr, this message translates to:
  /// **'Changer'**
  String get switchAction;

  /// No description provided for @unitLabel.
  ///
  /// In fr, this message translates to:
  /// **'Lot'**
  String get unitLabel;

  /// No description provided for @noPropertyYet.
  ///
  /// In fr, this message translates to:
  /// **'Aucun bien n\'est encore rattaché à votre compte.'**
  String get noPropertyYet;

  /// No description provided for @selectResidenceTitle.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez votre résidence'**
  String get selectResidenceTitle;

  /// No description provided for @selectResidenceSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez la résidence à laquelle accéder'**
  String get selectResidenceSubtitle;

  /// No description provided for @continueAction.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get continueAction;

  /// No description provided for @residenceLabel.
  ///
  /// In fr, this message translates to:
  /// **'Résidence'**
  String get residenceLabel;

  /// No description provided for @apartmentLabel.
  ///
  /// In fr, this message translates to:
  /// **'Appartement'**
  String get apartmentLabel;

  /// No description provided for @chooseResidence.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une résidence'**
  String get chooseResidence;

  /// No description provided for @chooseFloor.
  ///
  /// In fr, this message translates to:
  /// **'Choisir un étage'**
  String get chooseFloor;

  /// No description provided for @chooseApartment.
  ///
  /// In fr, this message translates to:
  /// **'Choisir un appartement'**
  String get chooseApartment;

  /// No description provided for @selectResidenceFirst.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez d\'abord une résidence'**
  String get selectResidenceFirst;

  /// No description provided for @selectFloorFirst.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez d\'abord un étage'**
  String get selectFloorFirst;

  /// No description provided for @noFloorAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Aucun étage disponible'**
  String get noFloorAvailable;

  /// No description provided for @noApartmentAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Aucun appartement libre'**
  String get noApartmentAvailable;

  /// No description provided for @groundFloor.
  ///
  /// In fr, this message translates to:
  /// **'Rez-de-chaussée'**
  String get groundFloor;

  /// No description provided for @floorNumber.
  ///
  /// In fr, this message translates to:
  /// **'Étage {floor}'**
  String floorNumber(String floor);

  /// No description provided for @loadingEllipsis.
  ///
  /// In fr, this message translates to:
  /// **'Chargement…'**
  String get loadingEllipsis;

  /// No description provided for @accountLabel.
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get accountLabel;

  /// No description provided for @sendRequest.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer la demande'**
  String get sendRequest;

  /// No description provided for @addPropertyNotice.
  ///
  /// In fr, this message translates to:
  /// **'Votre demande est transmise au gestionnaire de la résidence. Le bien apparaîtra dans vos biens une fois la demande validée.'**
  String get addPropertyNotice;

  /// No description provided for @requestSentTitle.
  ///
  /// In fr, this message translates to:
  /// **'Demande envoyée'**
  String get requestSentTitle;

  /// No description provided for @requestSentBody.
  ///
  /// In fr, this message translates to:
  /// **'Le gestionnaire de la résidence a reçu votre demande. Vous serez notifié dès qu\'elle sera traitée.'**
  String get requestSentBody;

  /// No description provided for @errorTitle.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue'**
  String get errorTitle;

  /// No description provided for @notificationsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Vos alertes et rappels'**
  String get notificationsSubtitle;

  /// No description provided for @emptyNotificationsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune notification'**
  String get emptyNotificationsTitle;

  /// No description provided for @emptyNotificationsBody.
  ///
  /// In fr, this message translates to:
  /// **'Vous êtes à jour. Rien à signaler pour le moment.'**
  String get emptyNotificationsBody;

  /// No description provided for @editMember.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le membre'**
  String get editMember;

  /// No description provided for @addPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une photo'**
  String get addPhoto;

  /// No description provided for @changePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Changer la photo'**
  String get changePhoto;

  /// No description provided for @fullNameLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nom complet'**
  String get fullNameLabel;

  /// No description provided for @fullNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Entrez le nom complet'**
  String get fullNameHint;

  /// No description provided for @emailOrPhone.
  ///
  /// In fr, this message translates to:
  /// **'E-mail / Téléphone'**
  String get emailOrPhone;

  /// No description provided for @emailOrPhoneHint.
  ///
  /// In fr, this message translates to:
  /// **'Entrez l\'e-mail ou le téléphone'**
  String get emailOrPhoneHint;

  /// No description provided for @relationshipLabel.
  ///
  /// In fr, this message translates to:
  /// **'Relation'**
  String get relationshipLabel;

  /// No description provided for @chooseRelationship.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une relation'**
  String get chooseRelationship;

  /// No description provided for @selectAccessLevel.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner le niveau d\'accès'**
  String get selectAccessLevel;

  /// No description provided for @accessFull.
  ///
  /// In fr, this message translates to:
  /// **'Accès complet'**
  String get accessFull;

  /// No description provided for @accessFullDesc.
  ///
  /// In fr, this message translates to:
  /// **'Accès à toutes les fonctionnalités.'**
  String get accessFullDesc;

  /// No description provided for @accessResident.
  ///
  /// In fr, this message translates to:
  /// **'Accès résident'**
  String get accessResident;

  /// No description provided for @accessResidentDesc.
  ///
  /// In fr, this message translates to:
  /// **'Peut consulter les avis, créer des signalements et gérer les visiteurs.'**
  String get accessResidentDesc;

  /// No description provided for @accessVisitor.
  ///
  /// In fr, this message translates to:
  /// **'Accès visiteur'**
  String get accessVisitor;

  /// No description provided for @accessVisitorDesc.
  ///
  /// In fr, this message translates to:
  /// **'Peut uniquement gérer les visiteurs.'**
  String get accessVisitorDesc;

  /// No description provided for @accessCustom.
  ///
  /// In fr, this message translates to:
  /// **'Accès personnalisé'**
  String get accessCustom;

  /// No description provided for @accessCustomDesc.
  ///
  /// In fr, this message translates to:
  /// **'Choisir des autorisations précises.'**
  String get accessCustomDesc;

  /// No description provided for @relFather.
  ///
  /// In fr, this message translates to:
  /// **'Père'**
  String get relFather;

  /// No description provided for @relMother.
  ///
  /// In fr, this message translates to:
  /// **'Mère'**
  String get relMother;

  /// No description provided for @relWife.
  ///
  /// In fr, this message translates to:
  /// **'Épouse'**
  String get relWife;

  /// No description provided for @relHusband.
  ///
  /// In fr, this message translates to:
  /// **'Époux'**
  String get relHusband;

  /// No description provided for @relSon.
  ///
  /// In fr, this message translates to:
  /// **'Fils'**
  String get relSon;

  /// No description provided for @relDaughter.
  ///
  /// In fr, this message translates to:
  /// **'Fille'**
  String get relDaughter;

  /// No description provided for @relOther.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get relOther;

  /// No description provided for @removeMemberTitle.
  ///
  /// In fr, this message translates to:
  /// **'Retirer ce membre ?'**
  String get removeMemberTitle;

  /// No description provided for @removeMemberBody.
  ///
  /// In fr, this message translates to:
  /// **'{name} ne figurera plus dans votre foyer.'**
  String removeMemberBody(String name);

  /// No description provided for @nameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le nom est requis.'**
  String get nameRequired;

  /// No description provided for @saveLabel.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get saveLabel;

  /// No description provided for @registerTitle.
  ///
  /// In fr, this message translates to:
  /// **'Créer votre compte'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Rejoignez votre résidence en quelques champs.'**
  String get registerSubtitle;

  /// No description provided for @firstNameLabel.
  ///
  /// In fr, this message translates to:
  /// **'Prénom'**
  String get firstNameLabel;

  /// No description provided for @firstNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Votre prénom'**
  String get firstNameHint;

  /// No description provided for @lastNameLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get lastNameLabel;

  /// No description provided for @lastNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Votre nom'**
  String get lastNameHint;

  /// No description provided for @phoneHint.
  ///
  /// In fr, this message translates to:
  /// **'Votre numéro de téléphone'**
  String get phoneHint;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez déjà un compte ?'**
  String get alreadyHaveAccount;

  /// No description provided for @signIn.
  ///
  /// In fr, this message translates to:
  /// **'Connectez-vous'**
  String get signIn;

  /// No description provided for @registrationSentTitle.
  ///
  /// In fr, this message translates to:
  /// **'Demande envoyée'**
  String get registrationSentTitle;

  /// No description provided for @registrationSentBody.
  ///
  /// In fr, this message translates to:
  /// **'Votre demande d\'inscription a bien été reçue. Vous recevrez vos accès par e-mail après validation.'**
  String get registrationSentBody;

  /// No description provided for @firstNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Prénom requis'**
  String get firstNameRequired;

  /// No description provided for @lastNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Nom requis'**
  String get lastNameRequired;

  /// No description provided for @phoneRequired.
  ///
  /// In fr, this message translates to:
  /// **'Numéro de téléphone requis'**
  String get phoneRequired;

  /// No description provided for @residenceRequired.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez une résidence'**
  String get residenceRequired;

  /// No description provided for @floorRequired.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez un étage'**
  String get floorRequired;

  /// No description provided for @apartmentRequired.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez un appartement'**
  String get apartmentRequired;

  /// No description provided for @ticketHistory.
  ///
  /// In fr, this message translates to:
  /// **'Historique du traitement'**
  String get ticketHistory;

  /// No description provided for @ticketInfo.
  ///
  /// In fr, this message translates to:
  /// **'Informations de l\'administration'**
  String get ticketInfo;

  /// No description provided for @pipelineOpened.
  ///
  /// In fr, this message translates to:
  /// **'Signalé'**
  String get pipelineOpened;

  /// No description provided for @pipelineStarted.
  ///
  /// In fr, this message translates to:
  /// **'Prise en charge'**
  String get pipelineStarted;

  /// No description provided for @pipelineClosed.
  ///
  /// In fr, this message translates to:
  /// **'Clôturé'**
  String get pipelineClosed;

  /// No description provided for @pipelinePending.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get pipelinePending;

  /// No description provided for @historyCreated.
  ///
  /// In fr, this message translates to:
  /// **'Signalement créé'**
  String get historyCreated;

  /// No description provided for @historyStatusFromTo.
  ///
  /// In fr, this message translates to:
  /// **'Statut : {from} → {to}'**
  String historyStatusFromTo(String from, String to);

  /// No description provided for @historyStatus.
  ///
  /// In fr, this message translates to:
  /// **'Statut : {status}'**
  String historyStatus(String status);

  /// No description provided for @historyAssigned.
  ///
  /// In fr, this message translates to:
  /// **'Pris en charge par l\'équipe'**
  String get historyAssigned;

  /// No description provided for @historyInfo.
  ///
  /// In fr, this message translates to:
  /// **'Information de l\'administration'**
  String get historyInfo;

  /// No description provided for @historyAttachment.
  ///
  /// In fr, this message translates to:
  /// **'Pièces jointes ajoutées'**
  String get historyAttachment;

  /// No description provided for @actorYou.
  ///
  /// In fr, this message translates to:
  /// **'Vous'**
  String get actorYou;

  /// No description provided for @actorTeam.
  ///
  /// In fr, this message translates to:
  /// **'Intervenant'**
  String get actorTeam;

  /// No description provided for @actorAdmin.
  ///
  /// In fr, this message translates to:
  /// **'Administration'**
  String get actorAdmin;

  /// No description provided for @attachmentsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Pièces jointes ({count})'**
  String attachmentsTitle(int count);

  /// No description provided for @attachmentsHint.
  ///
  /// In fr, this message translates to:
  /// **'4 fichiers au maximum, 10 Mo au total.'**
  String get attachmentsHint;

  /// No description provided for @attachmentTooMany.
  ///
  /// In fr, this message translates to:
  /// **'4 fichiers au maximum.'**
  String get attachmentTooMany;

  /// No description provided for @attachmentTooBig.
  ///
  /// In fr, this message translates to:
  /// **'10 Mo au total au maximum.'**
  String get attachmentTooBig;

  /// No description provided for @noAppToOpen.
  ///
  /// In fr, this message translates to:
  /// **'Aucune application ne peut ouvrir ce fichier.'**
  String get noAppToOpen;

  /// No description provided for @openFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'ouvrir le fichier.'**
  String get openFailed;

  /// No description provided for @documentsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Documents'**
  String get documentsTitle;

  /// No description provided for @documentsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Documents de votre résidence'**
  String get documentsSubtitle;

  /// No description provided for @emptyDocumentsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun document'**
  String get emptyDocumentsTitle;

  /// No description provided for @emptyDocumentsBody.
  ///
  /// In fr, this message translates to:
  /// **'L\'administration n\'a publié aucun document pour le moment.'**
  String get emptyDocumentsBody;

  /// No description provided for @downloadLabel.
  ///
  /// In fr, this message translates to:
  /// **'Télécharger'**
  String get downloadLabel;

  /// No description provided for @openLabel.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir'**
  String get openLabel;

  /// No description provided for @residenceDetails.
  ///
  /// In fr, this message translates to:
  /// **'Ma résidence'**
  String get residenceDetails;

  /// No description provided for @amenitiesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Commodités'**
  String get amenitiesTitle;

  /// No description provided for @aboutTitle.
  ///
  /// In fr, this message translates to:
  /// **'À propos'**
  String get aboutTitle;

  /// No description provided for @memberCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} sur {max} membres'**
  String memberCount(int count, int max);

  /// No description provided for @householdHint.
  ///
  /// In fr, this message translates to:
  /// **'Chaque membre reçoit ses accès de connexion par e-mail. Vous pouvez ajouter jusqu\'à {max} personnes.'**
  String householdHint(int max);

  /// No description provided for @accountActiveChip.
  ///
  /// In fr, this message translates to:
  /// **'Compte actif'**
  String get accountActiveChip;

  /// No description provided for @accountDisabledChip.
  ///
  /// In fr, this message translates to:
  /// **'Compte désactivé'**
  String get accountDisabledChip;

  /// No description provided for @noAccountChip.
  ///
  /// In fr, this message translates to:
  /// **'Sans compte'**
  String get noAccountChip;

  /// No description provided for @resendAccess.
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer les accès'**
  String get resendAccess;

  /// No description provided for @accessResent.
  ///
  /// In fr, this message translates to:
  /// **'Les accès ont été renvoyés par e-mail.'**
  String get accessResent;

  /// No description provided for @maxMembersReached.
  ///
  /// In fr, this message translates to:
  /// **'Maximum de {max} membres atteint'**
  String maxMembersReached(int max);

  /// No description provided for @mainResident.
  ///
  /// In fr, this message translates to:
  /// **'Résident principal'**
  String get mainResident;

  /// No description provided for @noOtherMember.
  ///
  /// In fr, this message translates to:
  /// **'Aucun autre membre pour le moment.'**
  String get noOtherMember;

  /// No description provided for @removePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Retirer la photo'**
  String get removePhoto;

  /// No description provided for @photoTooBig.
  ///
  /// In fr, this message translates to:
  /// **'Photo trop lourde (5 Mo maximum).'**
  String get photoTooBig;

  /// No description provided for @accountDisabled.
  ///
  /// In fr, this message translates to:
  /// **'Ce compte a été désactivé. Contactez l\'administration.'**
  String get accountDisabled;

  /// No description provided for @editLabelShort.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get editLabelShort;

  /// No description provided for @amenity_climatisation.
  ///
  /// In fr, this message translates to:
  /// **'Climatisation centralisée'**
  String get amenity_climatisation;

  /// No description provided for @amenity_reception.
  ///
  /// In fr, this message translates to:
  /// **'Réception'**
  String get amenity_reception;

  /// No description provided for @amenity_bache_eau.
  ///
  /// In fr, this message translates to:
  /// **'Bâche à eau'**
  String get amenity_bache_eau;

  /// No description provided for @amenity_ascenseur.
  ///
  /// In fr, this message translates to:
  /// **'Ascenseur'**
  String get amenity_ascenseur;

  /// No description provided for @amenity_cuisine.
  ///
  /// In fr, this message translates to:
  /// **'Cuisine équipée'**
  String get amenity_cuisine;

  /// No description provided for @amenity_groupe_electrogene.
  ///
  /// In fr, this message translates to:
  /// **'Groupe électrogène'**
  String get amenity_groupe_electrogene;

  /// No description provided for @amenity_parking.
  ///
  /// In fr, this message translates to:
  /// **'Parking de stationnement'**
  String get amenity_parking;

  /// No description provided for @amenity_domotique.
  ///
  /// In fr, this message translates to:
  /// **'Domotique'**
  String get amenity_domotique;

  /// No description provided for @amenity_dressing.
  ///
  /// In fr, this message translates to:
  /// **'Dressing'**
  String get amenity_dressing;

  /// No description provided for @amenity_isolation_phonique.
  ///
  /// In fr, this message translates to:
  /// **'Isolation phonique'**
  String get amenity_isolation_phonique;

  /// No description provided for @amenity_aire_jeux.
  ///
  /// In fr, this message translates to:
  /// **'Aire de jeux'**
  String get amenity_aire_jeux;

  /// No description provided for @amenity_piscine_commune.
  ///
  /// In fr, this message translates to:
  /// **'Piscine commune'**
  String get amenity_piscine_commune;

  /// No description provided for @amenity_piscine_privative.
  ///
  /// In fr, this message translates to:
  /// **'Piscine privative'**
  String get amenity_piscine_privative;

  /// No description provided for @amenity_fenetre.
  ///
  /// In fr, this message translates to:
  /// **'Fenêtres double vitrage'**
  String get amenity_fenetre;

  /// No description provided for @amenity_salle_eau.
  ///
  /// In fr, this message translates to:
  /// **'Salle d\'eau'**
  String get amenity_salle_eau;

  /// No description provided for @amenity_salle_sport.
  ///
  /// In fr, this message translates to:
  /// **'Salle de sport'**
  String get amenity_salle_sport;

  /// No description provided for @amenity_spa.
  ///
  /// In fr, this message translates to:
  /// **'Spa / Hammam / Sauna'**
  String get amenity_spa;

  /// No description provided for @amenity_gestion_copropriete.
  ///
  /// In fr, this message translates to:
  /// **'Gestion copropriété'**
  String get amenity_gestion_copropriete;

  /// No description provided for @amenity_creche.
  ///
  /// In fr, this message translates to:
  /// **'Crèche / Garderie'**
  String get amenity_creche;

  /// No description provided for @unsupportedFileType.
  ///
  /// In fr, this message translates to:
  /// **'Type de fichier non pris en charge.'**
  String get unsupportedFileType;

  /// No description provided for @remindIn24h.
  ///
  /// In fr, this message translates to:
  /// **'Me le rappeler dans 24 h'**
  String get remindIn24h;

  /// No description provided for @reminderSetTitle.
  ///
  /// In fr, this message translates to:
  /// **'Rappel programmé'**
  String get reminderSetTitle;

  /// No description provided for @reminderSetBody.
  ///
  /// In fr, this message translates to:
  /// **'Une notification vous rappellera cet avis dans 24 heures.'**
  String get reminderSetBody;

  /// No description provided for @reminderUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Le rappel n\'est disponible que sur l\'application mobile.'**
  String get reminderUnavailable;

  /// No description provided for @docCatSecurity.
  ///
  /// In fr, this message translates to:
  /// **'Sécurité'**
  String get docCatSecurity;

  /// No description provided for @docCatSav.
  ///
  /// In fr, this message translates to:
  /// **'SAV'**
  String get docCatSav;

  /// No description provided for @docCatAdmin.
  ///
  /// In fr, this message translates to:
  /// **'Administratif'**
  String get docCatAdmin;

  /// No description provided for @docCatContracts.
  ///
  /// In fr, this message translates to:
  /// **'Contrats'**
  String get docCatContracts;

  /// No description provided for @docCatOther.
  ///
  /// In fr, this message translates to:
  /// **'Autres'**
  String get docCatOther;

  /// No description provided for @changePasswordSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Créez un nouveau mot de passe pour protéger votre compte.'**
  String get changePasswordSubtitle;

  /// No description provided for @currentPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe actuel'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau mot de passe'**
  String get newPassword;

  /// No description provided for @newPasswordHint.
  ///
  /// In fr, this message translates to:
  /// **'8 caractères minimum'**
  String get newPasswordHint;

  /// No description provided for @confirmPassword.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le mot de passe'**
  String get confirmPassword;

  /// No description provided for @confirmPasswordHint.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez à nouveau le mot de passe'**
  String get confirmPasswordHint;

  /// No description provided for @passwordTooShort.
  ///
  /// In fr, this message translates to:
  /// **'8 caractères minimum'**
  String get passwordTooShort;

  /// No description provided for @passwordMismatch.
  ///
  /// In fr, this message translates to:
  /// **'Les deux mots de passe diffèrent'**
  String get passwordMismatch;

  /// No description provided for @passwordChangedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe modifié'**
  String get passwordChangedTitle;

  /// No description provided for @passwordChangedBody.
  ///
  /// In fr, this message translates to:
  /// **'Votre nouveau mot de passe est enregistré. Utilisez-le à votre prochaine connexion.'**
  String get passwordChangedBody;

  /// No description provided for @paymentsUpToDate.
  ///
  /// In fr, this message translates to:
  /// **'Charges à jour'**
  String get paymentsUpToDate;

  /// No description provided for @chatReadOnly.
  ///
  /// In fr, this message translates to:
  /// **'Cette conversation est en lecture seule. L\'administration vous répond ici.'**
  String get chatReadOnly;

  /// No description provided for @chatEmptyReadOnly.
  ///
  /// In fr, this message translates to:
  /// **'Aucun message pour le moment. L\'administration écrira ici si votre signalement demande une précision.'**
  String get chatEmptyReadOnly;

  /// No description provided for @annualCharge.
  ///
  /// In fr, this message translates to:
  /// **'Charge annuelle'**
  String get annualCharge;

  /// No description provided for @upToDateTitle.
  ///
  /// In fr, this message translates to:
  /// **'À jour'**
  String get upToDateTitle;

  /// No description provided for @amountOwed.
  ///
  /// In fr, this message translates to:
  /// **'Argent dû'**
  String get amountOwed;
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
