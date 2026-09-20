// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppL10nEn extends AppL10n {
  AppL10nEn([String locale = 'en']) : super(locale);

  @override
  String get navHome => 'Home';

  @override
  String get navNotice => 'Notice';

  @override
  String get navReport => 'Report';

  @override
  String get navPayment => 'Payment';

  @override
  String get navMore => 'More';

  @override
  String greeting(String name) {
    return 'Welcome $name';
  }

  @override
  String get myResidence => 'My Residence';

  @override
  String apartmentBadge(String unit) {
    return 'Apt. $unit';
  }

  @override
  String get floor => 'Floor';

  @override
  String get area => 'Area';

  @override
  String get status => 'Status';

  @override
  String get statusActive => 'Active';

  @override
  String get nextPayment => 'Next payment';

  @override
  String paymentDeadline(String date) {
    return 'Deadline: $date';
  }

  @override
  String get reports => 'Reports';

  @override
  String reportsOpen(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count open',
      one: '1 open',
      zero: 'None open',
    );
    return '$_temp0';
  }

  @override
  String reportsInProgress(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count in progress',
      one: '1 in progress',
    );
    return '$_temp0';
  }

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get notices => 'Notices';

  @override
  String get payments => 'Payments';

  @override
  String get documents => 'Documents';

  @override
  String get profile => 'Profile';

  @override
  String get recentActivity => 'Recent Activity';

  @override
  String get loginTitle => 'Welcome home';

  @override
  String get loginSubtitle => 'Connect to your residence.';

  @override
  String get emailLabel => 'Email address';

  @override
  String get emailHint => 'name@example.com';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordHint => 'Enter Password';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get loginCta => 'Login';

  @override
  String get firstLoginQuestion => 'First login?';

  @override
  String get firstLoginHelp => ' Use the credentials provided at key handover.';

  @override
  String get emailRequired => 'Email address required';

  @override
  String get passwordRequired => 'Password required';

  @override
  String get noAccountQuestion =>
      'You are a resident and don\'t have an account yet?';

  @override
  String get signUp => 'Sign up';

  @override
  String get onbTitle1 => 'WHO WE ARE';

  @override
  String get onbBody1 =>
      'Crafting exceptional residences where luxury, comfort, and modern living come together to create a lifestyle beyond expectations.';

  @override
  String get onbTitle2 => 'WHAT WE PROVIDE';

  @override
  String get onbBody2 =>
      'From residence updates to payments, bookings, and maintenance requests, everything you need is beautifully organized in one seamless experience.';

  @override
  String get onbTitle3 => 'EXPERIENCE PEACE OF MIND';

  @override
  String get onbBody3 =>
      'Stay connected, informed, and fully in control with premium services designed for modern living.';

  @override
  String get skip => 'Skip';

  @override
  String get next => 'Next';

  @override
  String get getStarted => 'Get Started';

  @override
  String get forgotTitle => 'Forgot password';

  @override
  String get forgotSubtitle =>
      'Enter your email address and we will send you a link to reset your password.';

  @override
  String get sendLink => 'Send the link';

  @override
  String get emailSentTitle => 'Email sent';

  @override
  String emailSentBody(String email) {
    return 'If an account exists for $email, a reset link has just been sent. Remember to check your spam folder.';
  }

  @override
  String get backToLogin => 'Back to login';

  @override
  String get addProperty => 'Add a property';

  @override
  String get alertPaymentTitle => 'Urgent payment';

  @override
  String alertPaymentBody(String date) {
    return 'Your next payment is due on $date.';
  }

  @override
  String get alertPaymentHint =>
      'Tap below to view the details and settle your instalment.';

  @override
  String get close => 'Close';

  @override
  String get viewPayment => 'View payment';

  @override
  String get noticesSubtitle => 'Official communications';

  @override
  String get filterAll => 'All';

  @override
  String get filterUrgent => 'Urgent';

  @override
  String get filterInfo => 'Info';

  @override
  String get filterEvent => 'Event';

  @override
  String get readMore => 'Read more';

  @override
  String newCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new',
      one: '1 new',
    );
    return '$_temp0';
  }

  @override
  String get emptyNoticesTitle => 'No Notices Yet';

  @override
  String get emptyNoticesBody =>
      'You are all caught up. There are no notices to display at this moment.';

  @override
  String get logoutTitle => 'Log Out?';

  @override
  String get logoutBody => 'Are you sure you want to log out of your account?';

  @override
  String get logoutHint =>
      'You can sign back in anytime with the same credentials.';

  @override
  String get cancel => 'Cancel';

  @override
  String get logout => 'Log out';

  @override
  String get myAccount => 'My account';

  @override
  String get services => 'Services';

  @override
  String get changePassword => 'Change password';

  @override
  String get darkTheme => 'Dark theme';

  @override
  String get language => 'Language';

  @override
  String get phoneLabel => 'Phone';

  @override
  String get notProvided => 'Not provided';

  @override
  String get selectLanguage => 'Choose a language';

  @override
  String get langFrench => 'Français';

  @override
  String get langEnglish => 'English';

  @override
  String get langArabic => 'العربية';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notifAnnouncements => 'Announcements';

  @override
  String get notifMaintenance => 'Maintenance updates';

  @override
  String get notifBookings => 'Bookings';

  @override
  String get notifPayments => 'Payments';

  @override
  String get reportsSubtitle => 'Track your maintenance requests';

  @override
  String get filterInProgress => 'In progress';

  @override
  String get filterDone => 'Resolved';

  @override
  String get tabMyReports => 'My reports';

  @override
  String get tabCommonAreas => 'Common areas';

  @override
  String get newReport => 'New Report';

  @override
  String get emptyReportsTitle => 'No Reports Yet';

  @override
  String get emptyReportsBody =>
      'You have not submitted any reports yet. Use the button below to create one.';

  @override
  String get roleResident => 'Resident';

  @override
  String get verified => 'Verified';

  @override
  String get changeResidence => 'Change residence';

  @override
  String currentResidenceIs(String name) {
    return 'Current residence: $name';
  }

  @override
  String get residenceUpper => 'RESIDENCE';

  @override
  String get blockUpper => 'BLOCK';

  @override
  String get memberSinceUpper => 'MEMBER SINCE';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSubtitle => 'Notifications, language, security';

  @override
  String get myProperties => 'My properties';

  @override
  String get householdMembers => 'Household members';

  @override
  String apartmentShort(String unit) {
    return 'Apt. $unit';
  }

  @override
  String get serviceCharges => 'Service Charges';

  @override
  String get currentPeriod => 'Current month';

  @override
  String get statusDue => 'Due';

  @override
  String get totalDue => 'Total amount due';

  @override
  String get chargeBreakdown => 'Charge Breakdown';

  @override
  String get hideLabel => 'Hide';

  @override
  String get showLabel => 'Show';

  @override
  String get totalLabel => 'Total';

  @override
  String get paymentHistory => 'Payment History';

  @override
  String get emptyPaymentsTitle => 'No Payments Yet';

  @override
  String get emptyPaymentsBody => 'You have not made any charge payments yet.';

  @override
  String get affectedAreas => 'Affected Areas';

  @override
  String blockNamed(String name) {
    return 'Block $name';
  }

  @override
  String get timelineTitle => 'Timeline';

  @override
  String get dateLabel => 'Date';

  @override
  String get timeLabel => 'Time';

  @override
  String get whatToDo => 'What should you do?';

  @override
  String get shareNotice => 'Share notice';

  @override
  String get markAsRead => 'Mark as read';

  @override
  String get estimated => 'estimated';

  @override
  String get category => 'Category';

  @override
  String get issueType => 'Issue type';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get describeProblem => 'Describe the problem in detail…';

  @override
  String get priorityLabel => 'Priority';

  @override
  String get priorityLow => 'Low';

  @override
  String get priorityMedium => 'Medium';

  @override
  String get priorityHigh => 'High';

  @override
  String get priorityUrgent => 'Urgent';

  @override
  String get attachPhoto => 'Attach Photo';

  @override
  String get submitReport => 'Submit Report';

  @override
  String get you => 'You';

  @override
  String get primaryResident => 'Primary Resident';

  @override
  String get fullAccess => 'Full Access';

  @override
  String get residentAccess => 'Resident Access';

  @override
  String get visitorAccess => 'Visitor Access';

  @override
  String get customAccess => 'Custom Access';

  @override
  String get addMember => 'Add member';

  @override
  String get edit => 'Edit';

  @override
  String get remove => 'Remove';

  @override
  String get statusOpen => 'Open';

  @override
  String get statusInProgress => 'In progress';

  @override
  String get statusResolved => 'Resolved';

  @override
  String get reportDetails => 'Report Details';

  @override
  String get reportedOn => 'Report on';

  @override
  String photosCount(int count) {
    return 'Photos ($count)';
  }

  @override
  String get addMore => 'Add more';

  @override
  String get reportChat => 'Report Chat';

  @override
  String get editLabel => 'Edit';

  @override
  String get noPhotos => 'No photo';

  @override
  String get typeMessage => 'Type a message…';

  @override
  String get noMessages => 'No messages yet.';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get switchResidenceSubtitle =>
      'Switch between your registered properties';

  @override
  String yourProperties(int count) {
    return 'Your properties ($count)';
  }

  @override
  String get switchAction => 'Switch';

  @override
  String get unitLabel => 'Unit';

  @override
  String get noPropertyYet => 'No property is linked to your account yet.';

  @override
  String get selectResidenceTitle => 'Select Your Residence';

  @override
  String get selectResidenceSubtitle =>
      'Choose the residence you want to access';

  @override
  String get continueAction => 'Continue';

  @override
  String get residenceLabel => 'Residence';

  @override
  String get apartmentLabel => 'Apartment';

  @override
  String get chooseResidence => 'Choose a residence';

  @override
  String get chooseFloor => 'Choose a floor';

  @override
  String get chooseApartment => 'Choose an apartment';

  @override
  String get selectResidenceFirst => 'Select a residence first';

  @override
  String get selectFloorFirst => 'Select a floor first';

  @override
  String get noFloorAvailable => 'No floor available';

  @override
  String get noApartmentAvailable => 'No apartment available';

  @override
  String get groundFloor => 'Ground floor';

  @override
  String floorNumber(String floor) {
    return 'Floor $floor';
  }

  @override
  String get loadingEllipsis => 'Loading…';

  @override
  String get accountLabel => 'Account';

  @override
  String get sendRequest => 'Send request';

  @override
  String get addPropertyNotice =>
      'Your request goes to the residence manager. The property will appear in your properties once it is approved.';

  @override
  String get requestSentTitle => 'Request sent';

  @override
  String get requestSentBody =>
      'The residence manager has received your request. You will be notified as soon as it is processed.';

  @override
  String get errorTitle => 'Something went wrong';

  @override
  String get notificationsSubtitle => 'Your alerts and reminders';

  @override
  String get emptyNotificationsTitle => 'No notifications';

  @override
  String get emptyNotificationsBody =>
      'You are up to date. Nothing to report right now.';

  @override
  String get editMember => 'Edit member';

  @override
  String get addPhoto => 'Add photo';

  @override
  String get changePhoto => 'Change photo';

  @override
  String get fullNameLabel => 'Full name';

  @override
  String get fullNameHint => 'Enter the full name';

  @override
  String get emailOrPhone => 'Email / Phone';

  @override
  String get emailOrPhoneHint => 'Enter email or phone';

  @override
  String get relationshipLabel => 'Relationship';

  @override
  String get chooseRelationship => 'Choose a relationship';

  @override
  String get selectAccessLevel => 'Select access level';

  @override
  String get accessFull => 'Full access';

  @override
  String get accessFullDesc => 'Can access all features.';

  @override
  String get accessResident => 'Resident access';

  @override
  String get accessResidentDesc =>
      'Can view notices, create reports and manage visitors.';

  @override
  String get accessVisitor => 'Visitor access';

  @override
  String get accessVisitorDesc => 'Can manage visitors only.';

  @override
  String get accessCustom => 'Custom access';

  @override
  String get accessCustomDesc => 'Choose specific permissions.';

  @override
  String get relFather => 'Father';

  @override
  String get relMother => 'Mother';

  @override
  String get relWife => 'Wife';

  @override
  String get relHusband => 'Husband';

  @override
  String get relSon => 'Son';

  @override
  String get relDaughter => 'Daughter';

  @override
  String get relOther => 'Other';

  @override
  String get removeMemberTitle => 'Remove this member?';

  @override
  String removeMemberBody(String name) {
    return '$name will no longer be listed in your household.';
  }

  @override
  String get nameRequired => 'A name is required.';

  @override
  String get saveLabel => 'Save';

  @override
  String get registerTitle => 'Create your account';

  @override
  String get registerSubtitle => 'Join your residence in a few fields.';

  @override
  String get firstNameLabel => 'First name';

  @override
  String get firstNameHint => 'Your first name';

  @override
  String get lastNameLabel => 'Last name';

  @override
  String get lastNameHint => 'Your last name';

  @override
  String get phoneHint => 'Your phone number';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get signIn => 'Sign in';

  @override
  String get registrationSentTitle => 'Request sent';

  @override
  String get registrationSentBody =>
      'Your registration request has been received. You will get your credentials by email once it is approved.';

  @override
  String get firstNameRequired => 'First name required';

  @override
  String get lastNameRequired => 'Last name required';

  @override
  String get phoneRequired => 'Phone number required';

  @override
  String get residenceRequired => 'Choose a residence';

  @override
  String get floorRequired => 'Choose a floor';

  @override
  String get apartmentRequired => 'Choose an apartment';

  @override
  String get ticketHistory => 'Processing history';

  @override
  String get ticketInfo => 'Messages from the administration';

  @override
  String get pipelineOpened => 'Reported';

  @override
  String get pipelineStarted => 'Taken in charge';

  @override
  String get pipelineClosed => 'Closed';

  @override
  String get pipelinePending => 'Pending';

  @override
  String get historyCreated => 'Report created';

  @override
  String historyStatusFromTo(String from, String to) {
    return 'Status: $from → $to';
  }

  @override
  String historyStatus(String status) {
    return 'Status: $status';
  }

  @override
  String get historyAssigned => 'Taken over by the team';

  @override
  String get historyInfo => 'Message from the administration';

  @override
  String get historyAttachment => 'Attachments added';

  @override
  String get actorYou => 'You';

  @override
  String get actorTeam => 'Technician';

  @override
  String get actorAdmin => 'Administration';

  @override
  String attachmentsTitle(int count) {
    return 'Attachments ($count)';
  }

  @override
  String get attachmentsHint => 'Up to 4 files, 10 MB in total.';

  @override
  String get attachmentTooMany => 'Up to 4 files.';

  @override
  String get attachmentTooBig => '10 MB in total at most.';

  @override
  String get noAppToOpen => 'No app can open this file.';

  @override
  String get openFailed => 'The file could not be opened.';

  @override
  String get documentsTitle => 'Documents';

  @override
  String get documentsSubtitle => 'Documents for your residence';

  @override
  String get emptyDocumentsTitle => 'No documents';

  @override
  String get emptyDocumentsBody =>
      'The administration has not published any document yet.';

  @override
  String get downloadLabel => 'Download';

  @override
  String get openLabel => 'Open';

  @override
  String get residenceDetails => 'My residence';

  @override
  String get amenitiesTitle => 'Amenities';

  @override
  String get aboutTitle => 'About';

  @override
  String memberCount(int count, int max) {
    return '$count of $max members';
  }

  @override
  String householdHint(int max) {
    return 'Each member receives their login details by email. You can add up to $max people.';
  }

  @override
  String get accountActiveChip => 'Account active';

  @override
  String get accountDisabledChip => 'Account disabled';

  @override
  String get noAccountChip => 'No account';

  @override
  String get resendAccess => 'Resend access';

  @override
  String get accessResent => 'Access details have been emailed again.';

  @override
  String maxMembersReached(int max) {
    return 'Maximum of $max members reached';
  }

  @override
  String get mainResident => 'Main resident';

  @override
  String get noOtherMember => 'No other member yet.';

  @override
  String get removePhoto => 'Remove photo';

  @override
  String get photoTooBig => 'Photo too large (5 MB maximum).';

  @override
  String get accountDisabled =>
      'This account has been disabled. Please contact the administration.';

  @override
  String get editLabelShort => 'Edit';

  @override
  String get amenity_climatisation => 'Central air conditioning';

  @override
  String get amenity_reception => 'Reception';

  @override
  String get amenity_bache_eau => 'Water tank';

  @override
  String get amenity_ascenseur => 'Lift';

  @override
  String get amenity_cuisine => 'Fitted kitchen';

  @override
  String get amenity_groupe_electrogene => 'Backup generator';

  @override
  String get amenity_parking => 'Parking';

  @override
  String get amenity_domotique => 'Home automation';

  @override
  String get amenity_dressing => 'Walk-in closet';

  @override
  String get amenity_isolation_phonique => 'Sound insulation';

  @override
  String get amenity_aire_jeux => 'Playground';

  @override
  String get amenity_piscine_commune => 'Shared pool';

  @override
  String get amenity_piscine_privative => 'Private pool';

  @override
  String get amenity_fenetre => 'Double glazing';

  @override
  String get amenity_salle_eau => 'Shower room';

  @override
  String get amenity_salle_sport => 'Gym';

  @override
  String get amenity_spa => 'Spa / Hammam / Sauna';

  @override
  String get amenity_gestion_copropriete => 'Building management';

  @override
  String get amenity_creche => 'Nursery';

  @override
  String get unsupportedFileType => 'Unsupported file type.';

  @override
  String get remindIn24h => 'Remind me in 24 h';

  @override
  String get reminderSetTitle => 'Reminder set';

  @override
  String get reminderSetBody =>
      'A notification will remind you of this notice in 24 hours.';

  @override
  String get reminderUnavailable =>
      'Reminders are only available in the mobile app.';

  @override
  String get docCatSecurity => 'Safety';

  @override
  String get docCatSav => 'After-sales';

  @override
  String get docCatAdmin => 'Administrative';

  @override
  String get docCatContracts => 'Contracts';

  @override
  String get docCatOther => 'Other';

  @override
  String get changePasswordSubtitle =>
      'Create a new password to keep your account safe.';

  @override
  String get currentPassword => 'Current password';

  @override
  String get newPassword => 'New password';

  @override
  String get newPasswordHint => '8 characters minimum';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get confirmPasswordHint => 'Type the password again';

  @override
  String get passwordTooShort => '8 characters minimum';

  @override
  String get passwordMismatch => 'The two passwords differ';

  @override
  String get passwordChangedTitle => 'Password changed';

  @override
  String get passwordChangedBody =>
      'Your new password is saved. Use it the next time you sign in.';

  @override
  String get paymentsUpToDate => 'All charges paid';

  @override
  String get chatReadOnly =>
      'This conversation is read-only. The administration replies here.';

  @override
  String get chatEmptyReadOnly =>
      'No message yet. The administration will write here if your report needs anything.';

  @override
  String get annualCharge => 'Annual charge';

  @override
  String get upToDateTitle => 'Up to date';

  @override
  String get amountOwed => 'Amount owed';
}
