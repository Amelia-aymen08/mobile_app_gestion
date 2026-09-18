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
}
