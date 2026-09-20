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

  @override
  String get category => 'Catégorie';

  @override
  String get issueType => 'Type de problème';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get describeProblem => 'Décrivez le problème en détail…';

  @override
  String get priorityLabel => 'Priorité';

  @override
  String get priorityLow => 'Basse';

  @override
  String get priorityMedium => 'Moyenne';

  @override
  String get priorityHigh => 'Haute';

  @override
  String get priorityUrgent => 'Urgente';

  @override
  String get attachPhoto => 'Joindre une photo';

  @override
  String get submitReport => 'Envoyer le signalement';

  @override
  String get you => 'Vous';

  @override
  String get primaryResident => 'Résident principal';

  @override
  String get fullAccess => 'Accès complet';

  @override
  String get residentAccess => 'Accès résident';

  @override
  String get visitorAccess => 'Accès visiteur';

  @override
  String get customAccess => 'Accès personnalisé';

  @override
  String get addMember => 'Ajouter un membre';

  @override
  String get edit => 'Modifier';

  @override
  String get remove => 'Retirer';

  @override
  String get statusOpen => 'Ouvert';

  @override
  String get statusInProgress => 'En cours';

  @override
  String get statusResolved => 'Terminé';

  @override
  String get reportDetails => 'Détail du signalement';

  @override
  String get reportedOn => 'Signalé le';

  @override
  String photosCount(int count) {
    return 'Photos ($count)';
  }

  @override
  String get addMore => 'Ajouter';

  @override
  String get reportChat => 'Conversation';

  @override
  String get editLabel => 'Modifier';

  @override
  String get noPhotos => 'Aucune photo';

  @override
  String get typeMessage => 'Écrivez un message…';

  @override
  String get noMessages => 'Aucun message pour le moment.';

  @override
  String get today => 'Aujourd\'hui';

  @override
  String get yesterday => 'Hier';

  @override
  String get switchResidenceSubtitle => 'Passez d\'un bien à l\'autre';

  @override
  String yourProperties(int count) {
    return 'Vos biens ($count)';
  }

  @override
  String get switchAction => 'Changer';

  @override
  String get unitLabel => 'Lot';

  @override
  String get noPropertyYet =>
      'Aucun bien n\'est encore rattaché à votre compte.';

  @override
  String get selectResidenceTitle => 'Sélectionnez votre résidence';

  @override
  String get selectResidenceSubtitle =>
      'Choisissez la résidence à laquelle accéder';

  @override
  String get continueAction => 'Continuer';

  @override
  String get residenceLabel => 'Résidence';

  @override
  String get apartmentLabel => 'Appartement';

  @override
  String get chooseResidence => 'Choisir une résidence';

  @override
  String get chooseFloor => 'Choisir un étage';

  @override
  String get chooseApartment => 'Choisir un appartement';

  @override
  String get selectResidenceFirst => 'Sélectionnez d\'abord une résidence';

  @override
  String get selectFloorFirst => 'Sélectionnez d\'abord un étage';

  @override
  String get noFloorAvailable => 'Aucun étage disponible';

  @override
  String get noApartmentAvailable => 'Aucun appartement libre';

  @override
  String get groundFloor => 'Rez-de-chaussée';

  @override
  String floorNumber(String floor) {
    return 'Étage $floor';
  }

  @override
  String get loadingEllipsis => 'Chargement…';

  @override
  String get accountLabel => 'Compte';

  @override
  String get sendRequest => 'Envoyer la demande';

  @override
  String get addPropertyNotice =>
      'Votre demande est transmise au gestionnaire de la résidence. Le bien apparaîtra dans vos biens une fois la demande validée.';

  @override
  String get requestSentTitle => 'Demande envoyée';

  @override
  String get requestSentBody =>
      'Le gestionnaire de la résidence a reçu votre demande. Vous serez notifié dès qu\'elle sera traitée.';

  @override
  String get errorTitle => 'Une erreur est survenue';

  @override
  String get notificationsSubtitle => 'Vos alertes et rappels';

  @override
  String get emptyNotificationsTitle => 'Aucune notification';

  @override
  String get emptyNotificationsBody =>
      'Vous êtes à jour. Rien à signaler pour le moment.';

  @override
  String get editMember => 'Modifier le membre';

  @override
  String get addPhoto => 'Ajouter une photo';

  @override
  String get changePhoto => 'Changer la photo';

  @override
  String get fullNameLabel => 'Nom complet';

  @override
  String get fullNameHint => 'Entrez le nom complet';

  @override
  String get emailOrPhone => 'E-mail / Téléphone';

  @override
  String get emailOrPhoneHint => 'Entrez l\'e-mail ou le téléphone';

  @override
  String get relationshipLabel => 'Relation';

  @override
  String get chooseRelationship => 'Choisir une relation';

  @override
  String get selectAccessLevel => 'Sélectionner le niveau d\'accès';

  @override
  String get accessFull => 'Accès complet';

  @override
  String get accessFullDesc => 'Accès à toutes les fonctionnalités.';

  @override
  String get accessResident => 'Accès résident';

  @override
  String get accessResidentDesc =>
      'Peut consulter les avis, créer des signalements et gérer les visiteurs.';

  @override
  String get accessVisitor => 'Accès visiteur';

  @override
  String get accessVisitorDesc => 'Peut uniquement gérer les visiteurs.';

  @override
  String get accessCustom => 'Accès personnalisé';

  @override
  String get accessCustomDesc => 'Choisir des autorisations précises.';

  @override
  String get relFather => 'Père';

  @override
  String get relMother => 'Mère';

  @override
  String get relWife => 'Épouse';

  @override
  String get relHusband => 'Époux';

  @override
  String get relSon => 'Fils';

  @override
  String get relDaughter => 'Fille';

  @override
  String get relOther => 'Autre';

  @override
  String get removeMemberTitle => 'Retirer ce membre ?';

  @override
  String removeMemberBody(String name) {
    return '$name ne figurera plus dans votre foyer.';
  }

  @override
  String get nameRequired => 'Le nom est requis.';

  @override
  String get saveLabel => 'Enregistrer';

  @override
  String get registerTitle => 'Créer votre compte';

  @override
  String get registerSubtitle =>
      'Rejoignez votre résidence en quelques champs.';

  @override
  String get firstNameLabel => 'Prénom';

  @override
  String get firstNameHint => 'Votre prénom';

  @override
  String get lastNameLabel => 'Nom';

  @override
  String get lastNameHint => 'Votre nom';

  @override
  String get phoneHint => 'Votre numéro de téléphone';

  @override
  String get alreadyHaveAccount => 'Vous avez déjà un compte ?';

  @override
  String get signIn => 'Connectez-vous';

  @override
  String get registrationSentTitle => 'Demande envoyée';

  @override
  String get registrationSentBody =>
      'Votre demande d\'inscription a bien été reçue. Vous recevrez vos accès par e-mail après validation.';

  @override
  String get firstNameRequired => 'Prénom requis';

  @override
  String get lastNameRequired => 'Nom requis';

  @override
  String get phoneRequired => 'Numéro de téléphone requis';

  @override
  String get residenceRequired => 'Choisissez une résidence';

  @override
  String get floorRequired => 'Choisissez un étage';

  @override
  String get apartmentRequired => 'Choisissez un appartement';

  @override
  String get ticketHistory => 'Historique du traitement';

  @override
  String get ticketInfo => 'Informations de l\'administration';

  @override
  String get pipelineOpened => 'Signalé';

  @override
  String get pipelineStarted => 'Prise en charge';

  @override
  String get pipelineClosed => 'Clôturé';

  @override
  String get pipelinePending => 'En attente';

  @override
  String get historyCreated => 'Signalement créé';

  @override
  String historyStatusFromTo(String from, String to) {
    return 'Statut : $from → $to';
  }

  @override
  String historyStatus(String status) {
    return 'Statut : $status';
  }

  @override
  String get historyAssigned => 'Pris en charge par l\'équipe';

  @override
  String get historyInfo => 'Information de l\'administration';

  @override
  String get historyAttachment => 'Pièces jointes ajoutées';

  @override
  String get actorYou => 'Vous';

  @override
  String get actorTeam => 'Intervenant';

  @override
  String get actorAdmin => 'Administration';

  @override
  String attachmentsTitle(int count) {
    return 'Pièces jointes ($count)';
  }

  @override
  String get attachmentsHint => '4 fichiers au maximum, 10 Mo au total.';

  @override
  String get attachmentTooMany => '4 fichiers au maximum.';

  @override
  String get attachmentTooBig => '10 Mo au total au maximum.';

  @override
  String get noAppToOpen => 'Aucune application ne peut ouvrir ce fichier.';

  @override
  String get openFailed => 'Impossible d\'ouvrir le fichier.';

  @override
  String get documentsTitle => 'Documents';

  @override
  String get documentsSubtitle => 'Documents de votre résidence';

  @override
  String get emptyDocumentsTitle => 'Aucun document';

  @override
  String get emptyDocumentsBody =>
      'L\'administration n\'a publié aucun document pour le moment.';

  @override
  String get downloadLabel => 'Télécharger';

  @override
  String get openLabel => 'Ouvrir';

  @override
  String get residenceDetails => 'Ma résidence';

  @override
  String get amenitiesTitle => 'Commodités';

  @override
  String get aboutTitle => 'À propos';

  @override
  String memberCount(int count, int max) {
    return '$count sur $max membres';
  }

  @override
  String householdHint(int max) {
    return 'Chaque membre reçoit ses accès de connexion par e-mail. Vous pouvez ajouter jusqu\'à $max personnes.';
  }

  @override
  String get accountActiveChip => 'Compte actif';

  @override
  String get accountDisabledChip => 'Compte désactivé';

  @override
  String get noAccountChip => 'Sans compte';

  @override
  String get resendAccess => 'Renvoyer les accès';

  @override
  String get accessResent => 'Les accès ont été renvoyés par e-mail.';

  @override
  String maxMembersReached(int max) {
    return 'Maximum de $max membres atteint';
  }

  @override
  String get mainResident => 'Résident principal';

  @override
  String get noOtherMember => 'Aucun autre membre pour le moment.';

  @override
  String get removePhoto => 'Retirer la photo';

  @override
  String get photoTooBig => 'Photo trop lourde (5 Mo maximum).';

  @override
  String get accountDisabled =>
      'Ce compte a été désactivé. Contactez l\'administration.';

  @override
  String get editLabelShort => 'Modifier';

  @override
  String get amenity_climatisation => 'Climatisation centralisée';

  @override
  String get amenity_reception => 'Réception';

  @override
  String get amenity_bache_eau => 'Bâche à eau';

  @override
  String get amenity_ascenseur => 'Ascenseur';

  @override
  String get amenity_cuisine => 'Cuisine équipée';

  @override
  String get amenity_groupe_electrogene => 'Groupe électrogène';

  @override
  String get amenity_parking => 'Parking de stationnement';

  @override
  String get amenity_domotique => 'Domotique';

  @override
  String get amenity_dressing => 'Dressing';

  @override
  String get amenity_isolation_phonique => 'Isolation phonique';

  @override
  String get amenity_aire_jeux => 'Aire de jeux';

  @override
  String get amenity_piscine_commune => 'Piscine commune';

  @override
  String get amenity_piscine_privative => 'Piscine privative';

  @override
  String get amenity_fenetre => 'Fenêtres double vitrage';

  @override
  String get amenity_salle_eau => 'Salle d\'eau';

  @override
  String get amenity_salle_sport => 'Salle de sport';

  @override
  String get amenity_spa => 'Spa / Hammam / Sauna';

  @override
  String get amenity_gestion_copropriete => 'Gestion copropriété';

  @override
  String get amenity_creche => 'Crèche / Garderie';

  @override
  String get unsupportedFileType => 'Type de fichier non pris en charge.';

  @override
  String get remindIn24h => 'Me le rappeler dans 24 h';

  @override
  String get reminderSetTitle => 'Rappel programmé';

  @override
  String get reminderSetBody =>
      'Une notification vous rappellera cet avis dans 24 heures.';

  @override
  String get reminderUnavailable =>
      'Le rappel n\'est disponible que sur l\'application mobile.';

  @override
  String get docCatSecurity => 'Sécurité';

  @override
  String get docCatSav => 'SAV';

  @override
  String get docCatAdmin => 'Administratif';

  @override
  String get docCatContracts => 'Contrats';

  @override
  String get docCatOther => 'Autres';

  @override
  String get changePasswordSubtitle =>
      'Créez un nouveau mot de passe pour protéger votre compte.';

  @override
  String get currentPassword => 'Mot de passe actuel';

  @override
  String get newPassword => 'Nouveau mot de passe';

  @override
  String get newPasswordHint => '8 caractères minimum';

  @override
  String get confirmPassword => 'Confirmer le mot de passe';

  @override
  String get confirmPasswordHint => 'Saisissez à nouveau le mot de passe';

  @override
  String get passwordTooShort => '8 caractères minimum';

  @override
  String get passwordMismatch => 'Les deux mots de passe diffèrent';

  @override
  String get passwordChangedTitle => 'Mot de passe modifié';

  @override
  String get passwordChangedBody =>
      'Votre nouveau mot de passe est enregistré. Utilisez-le à votre prochaine connexion.';

  @override
  String get paymentsUpToDate => 'Charges à jour';

  @override
  String get chatReadOnly =>
      'Cette conversation est en lecture seule. L\'administration vous répond ici.';

  @override
  String get chatEmptyReadOnly =>
      'Aucun message pour le moment. L\'administration écrira ici si votre signalement demande une précision.';

  @override
  String get annualCharge => 'Charge annuelle';

  @override
  String get upToDateTitle => 'À jour';
}
