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

  @override
  String get reportsSubtitle => 'تابع طلبات الصيانة';

  @override
  String get filterInProgress => 'قيد المعالجة';

  @override
  String get filterDone => 'منتهية';

  @override
  String get tabMyReports => 'بلاغاتي';

  @override
  String get tabCommonAreas => 'الأجزاء المشتركة';

  @override
  String get newReport => 'بلاغ جديد';

  @override
  String get emptyReportsTitle => 'لا توجد بلاغات';

  @override
  String get emptyReportsBody =>
      'لم تقم بأي بلاغ بعد. استخدم الزر أدناه لإنشاء واحد.';

  @override
  String get roleResident => 'مقيم';

  @override
  String get verified => 'موثّق';

  @override
  String get changeResidence => 'تغيير الإقامة';

  @override
  String currentResidenceIs(String name) {
    return 'الإقامة الحالية: $name';
  }

  @override
  String get residenceUpper => 'الإقامة';

  @override
  String get blockUpper => 'العمارة';

  @override
  String get memberSinceUpper => 'عضو منذ';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get settingsSubtitle => 'الإشعارات واللغة والأمان';

  @override
  String get myProperties => 'ممتلكاتي';

  @override
  String get householdMembers => 'أفراد الأسرة';

  @override
  String apartmentShort(String unit) {
    return 'شقة $unit';
  }

  @override
  String get serviceCharges => 'الأعباء';

  @override
  String get currentPeriod => 'الشهر الجاري';

  @override
  String get statusDue => 'مستحق';

  @override
  String get totalDue => 'إجمالي المبلغ المستحق';

  @override
  String get chargeBreakdown => 'تفصيل الأعباء';

  @override
  String get hideLabel => 'إخفاء';

  @override
  String get showLabel => 'إظهار';

  @override
  String get totalLabel => 'المجموع';

  @override
  String get paymentHistory => 'سجل المدفوعات';

  @override
  String get emptyPaymentsTitle => 'لا توجد مدفوعات';

  @override
  String get emptyPaymentsBody => 'لم تسدد أي أعباء بعد.';

  @override
  String get affectedAreas => 'العمارات المعنية';

  @override
  String blockNamed(String name) {
    return 'عمارة $name';
  }

  @override
  String get timelineTitle => 'التسلسل الزمني';

  @override
  String get dateLabel => 'التاريخ';

  @override
  String get timeLabel => 'التوقيت';

  @override
  String get whatToDo => 'ماذا عليك أن تفعل؟';

  @override
  String get shareNotice => 'مشاركة الإعلان';

  @override
  String get markAsRead => 'تعليم كمقروء';

  @override
  String get estimated => 'تقديري';

  @override
  String get category => 'الفئة';

  @override
  String get issueType => 'نوع المشكلة';

  @override
  String get descriptionLabel => 'الوصف';

  @override
  String get describeProblem => 'صف المشكلة بالتفصيل…';

  @override
  String get priorityLabel => 'الأولوية';

  @override
  String get priorityLow => 'منخفضة';

  @override
  String get priorityMedium => 'متوسطة';

  @override
  String get priorityHigh => 'عالية';

  @override
  String get priorityUrgent => 'عاجلة';

  @override
  String get attachPhoto => 'إرفاق صورة';

  @override
  String get submitReport => 'إرسال البلاغ';

  @override
  String get you => 'أنت';

  @override
  String get primaryResident => 'المقيم الرئيسي';

  @override
  String get fullAccess => 'وصول كامل';

  @override
  String get residentAccess => 'وصول مقيم';

  @override
  String get visitorAccess => 'وصول زائر';

  @override
  String get customAccess => 'وصول مخصص';

  @override
  String get addMember => 'إضافة فرد';

  @override
  String get edit => 'تعديل';

  @override
  String get remove => 'إزالة';

  @override
  String get statusOpen => 'مفتوح';

  @override
  String get statusInProgress => 'قيد المعالجة';

  @override
  String get statusResolved => 'منتهٍ';

  @override
  String get reportDetails => 'تفاصيل البلاغ';

  @override
  String get reportedOn => 'تاريخ البلاغ';

  @override
  String photosCount(int count) {
    return 'الصور ($count)';
  }

  @override
  String get addMore => 'إضافة';

  @override
  String get reportChat => 'المحادثة';

  @override
  String get editLabel => 'تعديل';

  @override
  String get noPhotos => 'لا توجد صور';

  @override
  String get typeMessage => 'اكتب رسالة…';

  @override
  String get noMessages => 'لا توجد رسائل بعد.';

  @override
  String get today => 'اليوم';

  @override
  String get yesterday => 'أمس';

  @override
  String get switchResidenceSubtitle => 'انتقل بين ممتلكاتك المسجلة';

  @override
  String yourProperties(int count) {
    return 'ممتلكاتك ($count)';
  }

  @override
  String get switchAction => 'تغيير';

  @override
  String get unitLabel => 'الشقة';

  @override
  String get noPropertyYet => 'لا يوجد أي عقار مرتبط بحسابك بعد.';

  @override
  String get selectResidenceTitle => 'اختر إقامتك';

  @override
  String get selectResidenceSubtitle => 'اختر الإقامة التي تريد الوصول إليها';

  @override
  String get continueAction => 'متابعة';

  @override
  String get residenceLabel => 'الإقامة';

  @override
  String get apartmentLabel => 'الشقة';

  @override
  String get chooseResidence => 'اختر إقامة';

  @override
  String get chooseFloor => 'اختر طابقًا';

  @override
  String get chooseApartment => 'اختر شقة';

  @override
  String get selectResidenceFirst => 'اختر إقامة أولاً';

  @override
  String get selectFloorFirst => 'اختر طابقًا أولاً';

  @override
  String get noFloorAvailable => 'لا يوجد طابق متاح';

  @override
  String get noApartmentAvailable => 'لا توجد شقة متاحة';

  @override
  String get groundFloor => 'الطابق الأرضي';

  @override
  String floorNumber(String floor) {
    return 'الطابق $floor';
  }

  @override
  String get loadingEllipsis => 'جارٍ التحميل…';

  @override
  String get accountLabel => 'الحساب';

  @override
  String get sendRequest => 'إرسال الطلب';

  @override
  String get addPropertyNotice =>
      'يُرسل طلبك إلى مسيّر الإقامة. سيظهر العقار ضمن ممتلكاتك بمجرد الموافقة عليه.';

  @override
  String get requestSentTitle => 'تم إرسال الطلب';

  @override
  String get requestSentBody =>
      'استلم مسيّر الإقامة طلبك. سيتم إشعارك فور معالجته.';

  @override
  String get errorTitle => 'حدث خطأ';

  @override
  String get notificationsSubtitle => 'تنبيهاتك وتذكيراتك';

  @override
  String get emptyNotificationsTitle => 'لا توجد إشعارات';

  @override
  String get emptyNotificationsBody =>
      'أنت على اطلاع. لا جديد في الوقت الحالي.';

  @override
  String get editMember => 'تعديل العضو';

  @override
  String get addPhoto => 'إضافة صورة';

  @override
  String get changePhoto => 'تغيير الصورة';

  @override
  String get fullNameLabel => 'الاسم الكامل';

  @override
  String get fullNameHint => 'أدخل الاسم الكامل';

  @override
  String get emailOrPhone => 'البريد / الهاتف';

  @override
  String get emailOrPhoneHint => 'أدخل البريد أو الهاتف';

  @override
  String get relationshipLabel => 'صلة القرابة';

  @override
  String get chooseRelationship => 'اختر صلة القرابة';

  @override
  String get selectAccessLevel => 'اختر مستوى الوصول';

  @override
  String get accessFull => 'وصول كامل';

  @override
  String get accessFullDesc => 'يمكنه استخدام جميع الميزات.';

  @override
  String get accessResident => 'وصول مقيم';

  @override
  String get accessResidentDesc =>
      'يمكنه الاطلاع على الإعلانات وإنشاء البلاغات وإدارة الزوار.';

  @override
  String get accessVisitor => 'وصول زائر';

  @override
  String get accessVisitorDesc => 'يمكنه إدارة الزوار فقط.';

  @override
  String get accessCustom => 'وصول مخصص';

  @override
  String get accessCustomDesc => 'اختر أذونات محددة.';

  @override
  String get relFather => 'الأب';

  @override
  String get relMother => 'الأم';

  @override
  String get relWife => 'الزوجة';

  @override
  String get relHusband => 'الزوج';

  @override
  String get relSon => 'الابن';

  @override
  String get relDaughter => 'الابنة';

  @override
  String get relOther => 'أخرى';

  @override
  String get removeMemberTitle => 'إزالة هذا العضو؟';

  @override
  String removeMemberBody(String name) {
    return 'لن يظهر $name ضمن أفراد أسرتك بعد الآن.';
  }

  @override
  String get nameRequired => 'الاسم مطلوب.';

  @override
  String get saveLabel => 'حفظ';

  @override
  String get registerTitle => 'أنشئ حسابك';

  @override
  String get registerSubtitle => 'انضم إلى إقامتك بملء بعض الحقول.';

  @override
  String get firstNameLabel => 'الاسم';

  @override
  String get firstNameHint => 'اسمك';

  @override
  String get lastNameLabel => 'اللقب';

  @override
  String get lastNameHint => 'لقبك';

  @override
  String get phoneHint => 'رقم هاتفك';

  @override
  String get alreadyHaveAccount => 'لديك حساب بالفعل؟';

  @override
  String get signIn => 'سجّل الدخول';

  @override
  String get registrationSentTitle => 'تم إرسال الطلب';

  @override
  String get registrationSentBody =>
      'تم استلام طلب التسجيل. ستصلك بيانات الدخول عبر البريد بعد الموافقة.';

  @override
  String get firstNameRequired => 'الاسم مطلوب';

  @override
  String get lastNameRequired => 'اللقب مطلوب';

  @override
  String get phoneRequired => 'رقم الهاتف مطلوب';

  @override
  String get residenceRequired => 'اختر إقامة';

  @override
  String get floorRequired => 'اختر طابقًا';

  @override
  String get apartmentRequired => 'اختر شقة';

  @override
  String get ticketHistory => 'سجل المعالجة';

  @override
  String get ticketInfo => 'رسائل من الإدارة';

  @override
  String get pipelineOpened => 'تم الإبلاغ';

  @override
  String get pipelineStarted => 'قيد المعالجة';

  @override
  String get pipelineClosed => 'مغلق';

  @override
  String get pipelinePending => 'في الانتظار';

  @override
  String get historyCreated => 'تم إنشاء البلاغ';

  @override
  String historyStatusFromTo(String from, String to) {
    return 'الحالة: $from ← $to';
  }

  @override
  String historyStatus(String status) {
    return 'الحالة: $status';
  }

  @override
  String get historyAssigned => 'تكفّل الفريق بالبلاغ';

  @override
  String get historyInfo => 'رسالة من الإدارة';

  @override
  String get historyAttachment => 'تمت إضافة مرفقات';

  @override
  String get actorYou => 'أنت';

  @override
  String get actorTeam => 'تقني';

  @override
  String get actorAdmin => 'الإدارة';

  @override
  String attachmentsTitle(int count) {
    return 'المرفقات ($count)';
  }

  @override
  String get attachmentsHint => '4 ملفات كحد أقصى، 10 ميغابايت إجمالاً.';

  @override
  String get attachmentTooMany => '4 ملفات كحد أقصى.';

  @override
  String get attachmentTooBig => '10 ميغابايت إجمالاً كحد أقصى.';

  @override
  String get noAppToOpen => 'لا يوجد تطبيق يفتح هذا الملف.';

  @override
  String get openFailed => 'تعذّر فتح الملف.';

  @override
  String get documentsTitle => 'الوثائق';

  @override
  String get documentsSubtitle => 'وثائق إقامتك';

  @override
  String get emptyDocumentsTitle => 'لا توجد وثائق';

  @override
  String get emptyDocumentsBody => 'لم تنشر الإدارة أي وثيقة حتى الآن.';

  @override
  String get downloadLabel => 'تنزيل';

  @override
  String get openLabel => 'فتح';

  @override
  String get residenceDetails => 'إقامتي';

  @override
  String get amenitiesTitle => 'المرافق';

  @override
  String get aboutTitle => 'نبذة';

  @override
  String memberCount(int count, int max) {
    return '$count من $max أعضاء';
  }

  @override
  String householdHint(int max) {
    return 'يتلقى كل عضو بيانات الدخول عبر بريده الإلكتروني. يمكنك إضافة $max أشخاص كحد أقصى.';
  }

  @override
  String get accountActiveChip => 'الحساب مفعّل';

  @override
  String get accountDisabledChip => 'الحساب معطّل';

  @override
  String get noAccountChip => 'بدون حساب';

  @override
  String get resendAccess => 'إعادة إرسال البيانات';

  @override
  String get accessResent => 'أُعيد إرسال بيانات الدخول عبر البريد.';

  @override
  String maxMembersReached(int max) {
    return 'بلغت الحد الأقصى $max أعضاء';
  }

  @override
  String get mainResident => 'المقيم الرئيسي';

  @override
  String get noOtherMember => 'لا يوجد أعضاء آخرون بعد.';

  @override
  String get removePhoto => 'إزالة الصورة';

  @override
  String get photoTooBig => 'الصورة كبيرة جدًا (5 ميغابايت كحد أقصى).';

  @override
  String get accountDisabled => 'تم تعطيل هذا الحساب. يرجى الاتصال بالإدارة.';

  @override
  String get editLabelShort => 'تعديل';

  @override
  String get amenity_climatisation => 'تكييف مركزي';

  @override
  String get amenity_reception => 'الاستقبال';

  @override
  String get amenity_bache_eau => 'خزان مياه';

  @override
  String get amenity_ascenseur => 'مصعد';

  @override
  String get amenity_cuisine => 'مطبخ مجهز';

  @override
  String get amenity_groupe_electrogene => 'مولد كهربائي';

  @override
  String get amenity_parking => 'موقف سيارات';

  @override
  String get amenity_domotique => 'أتمتة المنزل';

  @override
  String get amenity_dressing => 'غرفة ملابس';

  @override
  String get amenity_isolation_phonique => 'عزل صوتي';

  @override
  String get amenity_aire_jeux => 'مساحة ألعاب';

  @override
  String get amenity_piscine_commune => 'مسبح مشترك';

  @override
  String get amenity_piscine_privative => 'مسبح خاص';

  @override
  String get amenity_fenetre => 'نوافذ مزدوجة';

  @override
  String get amenity_salle_eau => 'حمّام';

  @override
  String get amenity_salle_sport => 'قاعة رياضة';

  @override
  String get amenity_spa => 'سبا / حمّام / ساونا';

  @override
  String get amenity_gestion_copropriete => 'تسيير الملكية المشتركة';

  @override
  String get amenity_creche => 'حضانة';

  @override
  String get unsupportedFileType => 'نوع الملف غير مدعوم.';

  @override
  String get remindIn24h => 'ذكّرني بعد 24 ساعة';

  @override
  String get reminderSetTitle => 'تم ضبط التذكير';

  @override
  String get reminderSetBody => 'سيصلك إشعار يذكّرك بهذا الإعلان بعد 24 ساعة.';

  @override
  String get reminderUnavailable => 'التذكير متاح في تطبيق الهاتف فقط.';

  @override
  String get docCatSecurity => 'السلامة';

  @override
  String get docCatSav => 'خدمة ما بعد البيع';

  @override
  String get docCatAdmin => 'إداري';

  @override
  String get docCatContracts => 'العقود';

  @override
  String get docCatOther => 'أخرى';

  @override
  String get changePasswordSubtitle => 'أنشئ كلمة مرور جديدة لحماية حسابك.';

  @override
  String get currentPassword => 'كلمة المرور الحالية';

  @override
  String get newPassword => 'كلمة المرور الجديدة';

  @override
  String get newPasswordHint => '8 أحرف على الأقل';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get confirmPasswordHint => 'أعد إدخال كلمة المرور';

  @override
  String get passwordTooShort => '8 أحرف على الأقل';

  @override
  String get passwordMismatch => 'كلمتا المرور غير متطابقتين';

  @override
  String get passwordChangedTitle => 'تم تغيير كلمة المرور';

  @override
  String get passwordChangedBody =>
      'تم حفظ كلمة المرور الجديدة. استخدمها في تسجيل الدخول القادم.';

  @override
  String get paymentsUpToDate => 'لا مستحقات';

  @override
  String get chatReadOnly => 'هذه المحادثة للقراءة فقط. ترد الإدارة هنا.';

  @override
  String get chatEmptyReadOnly =>
      'لا توجد رسائل بعد. ستكتب الإدارة هنا إذا احتاج بلاغك إلى توضيح.';

  @override
  String get annualCharge => 'الرسوم السنوية';

  @override
  String get upToDateTitle => 'لا مستحقات';

  @override
  String get amountOwed => 'المبلغ المستحق';

  @override
  String get apartmentShortLabel => 'الشقة';

  @override
  String get apartmentUpper => 'الشقة';
}
