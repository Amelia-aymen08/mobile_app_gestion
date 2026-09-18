// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppL10nAr extends AppL10n {
  AppL10nAr([String locale = 'ar']) : super(locale);

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navNotice => 'الإعلانات';

  @override
  String get navReport => 'إبلاغ';

  @override
  String get navPayment => 'المدفوعات';

  @override
  String get navMore => 'المزيد';

  @override
  String greeting(String name) {
    return 'مرحبًا $name';
  }

  @override
  String get myResidence => 'إقامتي';

  @override
  String apartmentBadge(String unit) {
    return 'شقة $unit';
  }

  @override
  String get floor => 'الطابق';

  @override
  String get area => 'المساحة';

  @override
  String get status => 'الحالة';

  @override
  String get statusActive => 'نشط';

  @override
  String get nextPayment => 'الدفعة القادمة';

  @override
  String paymentDeadline(String date) {
    return 'آخر أجل: $date';
  }

  @override
  String get reports => 'البلاغات';

  @override
  String reportsOpen(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count بلاغ مفتوح',
      many: '$count بلاغًا مفتوحًا',
      few: '$count بلاغات مفتوحة',
      two: 'بلاغان مفتوحان',
      one: 'بلاغ واحد مفتوح',
      zero: 'لا يوجد بلاغ مفتوح',
    );
    return '$_temp0';
  }

  @override
  String reportsInProgress(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count بلاغ قيد المعالجة',
      many: '$count بلاغًا قيد المعالجة',
      few: '$count بلاغات قيد المعالجة',
      two: 'بلاغان قيد المعالجة',
      one: 'بلاغ واحد قيد المعالجة',
    );
    return '$_temp0';
  }

  @override
  String get quickActions => 'إجراءات سريعة';

  @override
  String get notices => 'الإعلانات';

  @override
  String get payments => 'المدفوعات';

  @override
  String get documents => 'المستندات';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get recentActivity => 'النشاط الأخير';

  @override
  String get loginTitle => 'أهلًا بك في بيتك';

  @override
  String get loginSubtitle => 'سجّل الدخول إلى إقامتك.';

  @override
  String get emailLabel => 'البريد الإلكتروني';

  @override
  String get emailHint => 'name@example.com';

  @override
  String get passwordLabel => 'كلمة المرور';

  @override
  String get passwordHint => 'أدخل كلمة المرور';

  @override
  String get forgotPassword => 'هل نسيت كلمة المرور؟';

  @override
  String get loginCta => 'تسجيل الدخول';

  @override
  String get firstLoginQuestion => 'تسجيل الدخول لأول مرة؟';

  @override
  String get firstLoginHelp =>
      ' استخدم بيانات الدخول المسلّمة عند تسليم المفاتيح.';

  @override
  String get emailRequired => 'البريد الإلكتروني مطلوب';

  @override
  String get passwordRequired => 'كلمة المرور مطلوبة';

  @override
  String get noAccountQuestion => 'أنت مقيم وليس لديك حساب بعد؟';

  @override
  String get signUp => 'إنشاء حساب';

  @override
  String get onbTitle1 => 'من نحن';

  @override
  String get onbBody1 =>
      'إقامات استثنائية يلتقي فيها الفخامة والراحة والحياة العصرية لتصنع أسلوب حياة يفوق التوقعات.';

  @override
  String get onbTitle2 => 'ما نقدّمه';

  @override
  String get onbBody2 =>
      'من أخبار الإقامة إلى المدفوعات والحجوزات وطلبات الصيانة: كل ما تحتاجه مجتمعًا في تجربة واحدة سلسة.';

  @override
  String get onbTitle3 => 'عِش براحة بال';

  @override
  String get onbBody3 =>
      'ابقَ على اتصال ومطّلعًا ومتحكّمًا بالكامل في يومياتك، مع خدمات راقية مصمّمة للحياة العصرية.';

  @override
  String get skip => 'تخطٍّ';

  @override
  String get next => 'التالي';

  @override
  String get getStarted => 'ابدأ';

  @override
  String get forgotTitle => 'نسيت كلمة المرور';

  @override
  String get forgotSubtitle =>
      'أدخل بريدك الإلكتروني وسنرسل لك رابطًا لإعادة تعيين كلمة المرور.';

  @override
  String get sendLink => 'إرسال الرابط';

  @override
  String get emailSentTitle => 'تم إرسال البريد';

  @override
  String emailSentBody(String email) {
    return 'إذا كان هناك حساب مرتبط بالعنوان $email، فقد أُرسل رابط إعادة التعيين للتو. لا تنسَ التحقق من مجلد الرسائل غير المرغوب فيها.';
  }

  @override
  String get backToLogin => 'العودة إلى تسجيل الدخول';

  @override
  String get addProperty => 'إضافة عقار';

  @override
  String get alertPaymentTitle => 'دفعة عاجلة';

  @override
  String alertPaymentBody(String date) {
    return 'دفعتك القادمة مستحقة في $date.';
  }

  @override
  String get alertPaymentHint => 'اضغط أدناه لعرض التفاصيل وتسوية دفعتك.';

  @override
  String get close => 'إغلاق';

  @override
  String get viewPayment => 'عرض الدفعة';

  @override
  String get noticesSubtitle => 'بلاغات رسمية';

  @override
  String get filterAll => 'الكل';

  @override
  String get filterUrgent => 'عاجل';

  @override
  String get filterInfo => 'معلومة';

  @override
  String get filterEvent => 'حدث';

  @override
  String get readMore => 'اقرأ المزيد';

  @override
  String newCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count جديد',
      many: '$count جديدًا',
      few: '$count جديدة',
      two: 'جديدان',
      one: 'جديد واحد',
    );
    return '$_temp0';
  }

  @override
  String get emptyNoticesTitle => 'لا توجد إعلانات';

  @override
  String get emptyNoticesBody =>
      'أنت على اطلاع كامل. لا توجد إعلانات لعرضها في الوقت الحالي.';

  @override
  String get logoutTitle => 'تسجيل الخروج؟';

  @override
  String get logoutBody => 'هل تريد فعلاً تسجيل الخروج من حسابك؟';

  @override
  String get logoutHint => 'يمكنك تسجيل الدخول مجددًا في أي وقت بنفس البيانات.';

  @override
  String get cancel => 'إلغاء';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get myAccount => 'حسابي';

  @override
  String get services => 'الخدمات';

  @override
  String get changePassword => 'تغيير كلمة المرور';

  @override
  String get darkTheme => 'الوضع الداكن';

  @override
  String get language => 'اللغة';

  @override
  String get phoneLabel => 'الهاتف';

  @override
  String get notProvided => 'غير محدد';

  @override
  String get selectLanguage => 'اختر اللغة';

  @override
  String get langFrench => 'Français';

  @override
  String get langEnglish => 'English';

  @override
  String get langArabic => 'العربية';

  @override
  String get notificationsTitle => 'الإشعارات';

  @override
  String get notifAnnouncements => 'الإعلانات';

  @override
  String get notifMaintenance => 'متابعة الصيانة';

  @override
  String get notifBookings => 'الحجوزات';

  @override
  String get notifPayments => 'المدفوعات';
}
