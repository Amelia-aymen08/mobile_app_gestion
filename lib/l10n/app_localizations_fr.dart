// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppL10nFr extends AppL10n {
  AppL10nFr([String locale = 'fr']) : super(locale);

  @override
  String get navHome => 'Accueil';

  @override
  String get navNotice => 'Avis';

  @override
  String get navReport => 'Signaler';

  @override
  String get navPayment => 'Paiements';

  @override
  String get navMore => 'Plus';

  @override
  String greeting(String name) {
    return 'Bonjour $name';
  }

  @override
  String get myResidence => 'Ma résidence';

  @override
  String apartmentBadge(String unit) {
    return 'Apt. $unit';
  }

  @override
  String get floor => 'Étage';

  @override
  String get area => 'Surface';

  @override
  String get status => 'Statut';

  @override
  String get statusActive => 'Actif';

  @override
  String get nextPayment => 'Prochain paiement';

  @override
  String paymentDeadline(String date) {
    return 'Échéance : $date';
  }

  @override
  String get reports => 'Signalements';

  @override
  String reportsOpen(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ouverts',
      one: '1 ouvert',
      zero: 'Aucun ouvert',
    );
    return '$_temp0';
  }

  @override
  String reportsInProgress(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count en cours',
      one: '1 en cours',
    );
    return '$_temp0';
  }

  @override
  String get quickActions => 'Actions rapides';

  @override
  String get notices => 'Avis';

  @override
  String get payments => 'Paiements';

  @override
  String get documents => 'Documents';

  @override
  String get profile => 'Profil';

  @override
  String get recentActivity => 'Activité récente';

  @override
  String get loginTitle => 'Bienvenue chez vous';

  @override
  String get loginSubtitle => 'Connectez-vous à votre résidence.';

  @override
  String get emailLabel => 'Adresse e-mail';

  @override
  String get emailHint => 'nom@exemple.com';

  @override
  String get passwordLabel => 'Mot de passe';

  @override
  String get passwordHint => 'Entrez votre mot de passe';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get loginCta => 'Se connecter';

  @override
  String get firstLoginQuestion => 'Première connexion ?';

  @override
  String get firstLoginHelp =>
      ' Utilisez les identifiants remis à la livraison des clés.';

  @override
  String get emailRequired => 'Adresse e-mail requise';

  @override
  String get passwordRequired => 'Mot de passe requis';

  @override
  String get noAccountQuestion =>
      'Vous êtes résident et n\'avez pas encore de compte ?';

  @override
  String get signUp => 'S\'inscrire';

  @override
  String get onbTitle1 => 'QUI NOUS SOMMES';

  @override
  String get onbBody1 =>
      'Des résidences d\'exception où le luxe, le confort et la vie moderne se rejoignent pour créer un art de vivre au-delà des attentes.';

  @override
  String get onbTitle2 => 'CE QUE NOUS OFFRONS';

  @override
  String get onbBody2 =>
      'Des actualités de la résidence aux paiements, réservations et demandes d\'intervention : tout ce dont vous avez besoin, réuni dans une expérience fluide.';

  @override
  String get onbTitle3 => 'VIVRE L\'ESPRIT TRANQUILLE';

  @override
  String get onbBody3 =>
      'Restez connecté, informé et pleinement maître de votre quotidien, avec des services haut de gamme pensés pour la vie moderne.';

  @override
  String get skip => 'Passer';

  @override
  String get next => 'Suivant';

  @override
  String get getStarted => 'Commencer';

  @override
  String get forgotTitle => 'Mot de passe oublié';

  @override
  String get forgotSubtitle =>
      'Entrez votre adresse e-mail, nous vous enverrons un lien pour réinitialiser votre mot de passe.';

  @override
  String get sendLink => 'Envoyer le lien';

  @override
  String get emailSentTitle => 'E-mail envoyé';

  @override
  String emailSentBody(String email) {
    return 'Si un compte existe avec l\'adresse $email, un lien de réinitialisation vient d\'être envoyé. Pensez à vérifier vos indésirables.';
  }

  @override
  String get backToLogin => 'Retour à la connexion';

  @override
  String get addProperty => 'Ajouter un bien';

  @override
  String get alertPaymentTitle => 'Paiement urgent';

  @override
  String alertPaymentBody(String date) {
    return 'Votre prochain paiement est dû le $date.';
  }

  @override
  String get alertPaymentHint =>
      'Appuyez ci-dessous pour consulter le détail et régler votre échéance.';

  @override
  String get close => 'Fermer';

  @override
  String get viewPayment => 'Voir le paiement';

  @override
  String get noticesSubtitle => 'Communications officielles';

  @override
  String get filterAll => 'Tous';

  @override
  String get filterUrgent => 'Urgent';

  @override
  String get filterInfo => 'Info';

  @override
  String get filterEvent => 'Événement';

  @override
  String get readMore => 'Lire la suite';

  @override
  String newCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nouveaux',
      one: '1 nouveau',
    );
    return '$_temp0';
  }

  @override
  String get emptyNoticesTitle => 'Aucun avis';

  @override
  String get emptyNoticesBody =>
      'Vous êtes à jour. Il n\'y a aucun avis à afficher pour le moment.';

  @override
  String get logoutTitle => 'Se déconnecter ?';

  @override
  String get logoutBody => 'Voulez-vous vraiment vous déconnecter ?';

  @override
  String get logoutHint =>
      'Vous pourrez vous reconnecter à tout moment avec les mêmes identifiants.';

  @override
  String get cancel => 'Annuler';

  @override
  String get logout => 'Se déconnecter';

  @override
  String get myAccount => 'Mon compte';

  @override
  String get services => 'Services';

  @override
  String get changePassword => 'Changer le mot de passe';

  @override
  String get darkTheme => 'Thème sombre';

  @override
  String get language => 'Langue';

  @override
  String get phoneLabel => 'Téléphone';

  @override
  String get notProvided => 'Non renseigné';

  @override
  String get selectLanguage => 'Choisir la langue';

  @override
  String get langFrench => 'Français';

  @override
  String get langEnglish => 'English';

  @override
  String get langArabic => 'العربية';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notifAnnouncements => 'Annonces';

  @override
  String get notifMaintenance => 'Suivi des interventions';

  @override
  String get notifBookings => 'Réservations';

  @override
  String get notifPayments => 'Paiements';

  @override
  String get reportsSubtitle => 'Suivez vos demandes de maintenance';

  @override
  String get filterInProgress => 'En cours';

  @override
  String get filterDone => 'Terminés';

  @override
  String get tabMyReports => 'Mes signalements';

  @override
  String get tabCommonAreas => 'Copropriété';

  @override
  String get newReport => 'Nouveau signalement';

  @override
  String get emptyReportsTitle => 'Aucun signalement';

  @override
  String get emptyReportsBody =>
      'Vous n\'avez encore signalé aucun problème. Utilisez le bouton ci-dessous pour en créer un.';

  @override
  String get roleResident => 'Résident';

  @override
  String get verified => 'Vérifié';

  @override
  String get changeResidence => 'Changer de résidence';

  @override
  String currentResidenceIs(String name) {
    return 'Résidence actuelle : $name';
  }

  @override
  String get residenceUpper => 'RÉSIDENCE';

  @override
  String get blockUpper => 'BLOC';

  @override
  String get memberSinceUpper => 'MEMBRE DEPUIS';

  @override
  String get settingsTitle => 'Réglages';

  @override
  String get settingsSubtitle => 'Notifications, langue, sécurité';

  @override
  String get myProperties => 'Mes biens';

  @override
  String get householdMembers => 'Membres du foyer';

  @override
  String apartmentShort(String unit) {
    return 'Apt. $unit';
  }

  @override
  String get serviceCharges => 'Charges';

  @override
  String get currentPeriod => 'Période en cours';

  @override
  String get statusDue => 'À régler';

  @override
  String get totalDue => 'Total à régler';

  @override
  String get chargeBreakdown => 'Détail des charges';

  @override
  String get hideLabel => 'Masquer';

  @override
  String get showLabel => 'Afficher';

  @override
  String get totalLabel => 'Total';

  @override
  String get paymentHistory => 'Historique des paiements';

  @override
  String get emptyPaymentsTitle => 'Aucun paiement';

  @override
  String get emptyPaymentsBody => 'Vous n\'avez encore réglé aucune charge.';

  @override
  String get affectedAreas => 'Blocs concernés';

  @override
  String blockNamed(String name) {
    return 'Bloc $name';
  }

  @override
  String get timelineTitle => 'Chronologie';

  @override
  String get dateLabel => 'Date';

  @override
  String get timeLabel => 'Horaire';

  @override
  String get whatToDo => 'Que devez-vous faire ?';

  @override
  String get shareNotice => 'Partager l\'avis';

  @override
  String get markAsRead => 'Marquer comme lu';

  @override
  String get estimated => 'estimé';
}
