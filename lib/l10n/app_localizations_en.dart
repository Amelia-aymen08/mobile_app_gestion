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
}
