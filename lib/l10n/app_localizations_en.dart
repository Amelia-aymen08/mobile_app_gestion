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
}
