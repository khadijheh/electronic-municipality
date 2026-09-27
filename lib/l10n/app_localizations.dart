import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  bool get isArabic => locale.languageCode.toLowerCase() == 'ar';

  static AppLocalizations of(BuildContext context) {
    final value = maybeOf(context);
    assert(value != null, 'AppLocalizations delegate is not registered.');
    return value!;
  }

  static AppLocalizations? maybeOf(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  String translate(String source) {
    if (isArabic || source.trim().isEmpty) return source;
    final exact = _english[source];
    if (exact != null) return exact;
    return _translateDynamic(source) ?? source;
  }

  String? _translateDynamic(String source) {
    Match? match;

    match = RegExp(r'^شكوى #(\d+)$').firstMatch(source);
    if (match != null) return 'Complaint #${match.group(1)}';

    match = RegExp(r'^رقم البلاغ #(\d+)$').firstMatch(source);
    if (match != null) return 'Report #${match.group(1)}';

    match = RegExp(r'^صورة مرفقة #(\d+)$').firstMatch(source);
    if (match != null) return 'Attached image #${match.group(1)}';

    match = RegExp(r'^صورة #(\d+)$').firstMatch(source);
    if (match != null) return 'Image #${match.group(1)}';

    match = RegExp(r'^تعديل المسودة #(\d+)$').firstMatch(source);
    if (match != null) return 'Edit draft #${match.group(1)}';

    match = RegExp(r'^تم عرض (\d+) من (\d+) شكوى\.$').firstMatch(source);
    if (match != null) {
      return 'Showing ${match.group(1)} of ${match.group(2)} complaints.';
    }

    match = RegExp(r'^تغيّرت الحالة من (.+) إلى (.+)$').firstMatch(source);
    if (match != null) {
      return 'Status changed from ${translate(match.group(1)!)} '
          'to ${translate(match.group(2)!)}';
    }

    match = RegExp(r'^تغيّرت الحالة إلى (.+)$').firstMatch(source);
    if (match != null) {
      return 'Status changed to ${translate(match.group(1)!)}';
    }

    match = RegExp(r'^بواسطة (.+)$').firstMatch(source);
    if (match != null) return 'By ${match.group(1)}';

    match = RegExp(r'^إعادة إرسال الرمز \((.+)\)$').firstMatch(source);
    if (match != null) return 'Resend code (${match.group(1)})';

    match = RegExp(r'^أدخل الرمز المكون من 4 أرقام المرسل إلى (.+)$')
        .firstMatch(source);
    if (match != null) {
      return 'Enter the 4-digit code sent to ${match.group(1)}';
    }

    match = RegExp(r'^رمز التحقق المكون من (\d+) أرقام$').firstMatch(source);
    if (match != null) return '${match.group(1)}-digit verification code';

    match = RegExp(r'^حقل (.+) مطلوب\.$').firstMatch(source);
    if (match != null) {
      return '${translate(match.group(1)!)} is required.';
    }

    match = RegExp(r'^قيمة (.+) ليست تاريخًا صالحًا\.$').firstMatch(source);
    if (match != null) {
      return '${translate(match.group(1)!)} is not a valid date.';
    }

    match = RegExp(r'^تأكيد (.+) غير مطابق\.$').firstMatch(source);
    if (match != null) {
      return '${translate(match.group(1)!)} confirmation does not match.';
    }

    match = RegExp(r'^(.+) المحدد غير موجود\.$').firstMatch(source);
    if (match != null) {
      return 'The selected ${translate(match.group(1)!)} was not found.';
    }

    match = RegExp(r'^(.+) مستخدم مسبقًا\.$').firstMatch(source);
    if (match != null) {
      return '${translate(match.group(1)!)} is already in use.';
    }

    match = RegExp(r'^تحقق من قيمة (.+)\.$').firstMatch(source);
    if (match != null) return 'Check ${translate(match.group(1)!)}.';

    const logoutSuffix = ' تم إنهاء الجلسة محليًا.';
    if (source.endsWith(logoutSuffix)) {
      final prefix = source.substring(0, source.length - logoutSuffix.length);
      return '${translate(prefix)} The local session was ended.';
    }

    return null;
  }

  static const Map<String, String> _english = <String, String>{
    // Field inspector.
    'المفتش الميداني': 'Field Inspector',
    'التحقق من وثائق الخدمات باستخدام رمز QR': 'Verify service documents using a QR code',
    'نظام التحقق من الوثائق': 'Document verification system',
    'مسح QR وثيقة الخدمة': 'Scan the service document QR',
    'وجّه كاميرا الجهاز نحو رمز QR الموجود على وثيقة الخدمة للتحقق من صلاحيتها وأصالتها.': 'Point your device camera at the QR code on the service document to verify its validity and authenticity.',
    'مسح QR الوثيقة': 'Scan document QR',
    'أو إدخال الرمز يدويًا': 'Or enter the code manually',
    'أدخل رمز التحقق': 'Enter the verification code',
    'جاري التحقق من الوثيقة...': 'Verifying the document...',
    'يتم التحقق من صحة التوقيع والهاش وصلاحية الوثيقة.': 'Checking the signature, hash and validity of the document.',
    'الوثيقة صالحة': 'Document is valid',
    'الوثيقة غير صالحة': 'Document is not valid',
    'تم التحقق من صحة الوثيقة والتوقيع الإلكتروني.': 'The document and its electronic signature have been verified.',
    'تعذر اعتماد الوثيقة. يرجى التأكد من صلاحيتها.': 'The document could not be approved. Please check its validity.',
    'رقم الوثيقة': 'Document number',
    'اسم المواطن': 'Citizen name',
    'نوع الخدمة': 'Service type',
    'تاريخ الإصدار': 'Issue date',
    'تاريخ الانتهاء': 'Expiry date',
    'تفاصيل التحقق': 'Verification details',
    'الملف موجود': 'File exists',
    'الوثيقة غير منتهية': 'Document not expired',
    'الوثيقة موقعة': 'Document is signed',
    'الهاش صحيح': 'Hash is valid',
    'التوقيع صحيح': 'Signature is valid',
    'صحيح': 'Valid',
    'غير صحيح': 'Not valid',
    'عرض وثيقة الخدمة': 'View service document',
    'جاري فتح الوثيقة...': 'Opening the document...',
    'مسح وثيقة أخرى': 'Scan another document',
    'إعادة التحقق': 'Verify again',
    'يرجى مسح QR الوثيقة أولاً': 'Please scan the document QR first',
    'تعذر قراءة رمز التحقق من QR': 'Could not read the verification code from the QR',
    'حدث خطأ أثناء التحقق من الوثيقة': 'An error occurred while verifying the document',
    'تعذر فتح وثيقة الخدمة': 'Could not open the service document',
    'تعذر فتح الوثيقة. تأكد من وجود تطبيق لعرض ملفات PDF على الجهاز.': 'Could not open the document. Make sure a PDF viewer is installed.',
    'وجّه الكاميرا نحو رمز QR الموجود على وثيقة الخدمة': 'Point the camera at the QR code on the service document',
    'تعذر تشغيل الكاميرا. تأكد من السماح للتطبيق باستخدام الكاميرا.': 'Could not start the camera. Make sure camera access is allowed.',
    // Settings, shell, and common navigation.
    'الإعدادات': 'Settings',
    'إدارة الحساب والتفضيلات': 'Manage your account and preferences',
    'الملف الشخصي': 'Profile',
    'البيانات الشخصية ومستندات التوثيق':
        'Personal information and verification documents',
    'الإشعارات': 'Notifications',
    'تنبيهات المعاملات والمنطقة': 'Transaction and area alerts',
    'اللغة': 'Language',
    'العربية': 'Arabic',
    'الإنجليزية': 'English',
    'العربية · RTL': 'Arabic · RTL',
    'حول التطبيق': 'About the app',
    'بوابة المواطن الرقمية - الإصدار 1.0':
        'Digital Citizen Portal — Version 1.0',
    'تسجيل الخروج': 'Sign out',
    'جارٍ تسجيل الخروج...': 'Signing out…',
    'إنهاء الجلسة الحالية بأمان': 'Securely end the current session',
    'اختيار اللغة': 'Choose language',
    'اختر لغة واجهة التطبيق': 'Choose the app interface language',
    'سيتم تطبيق اللغة مباشرة وحفظها على هذا الجهاز.':
        'The language is applied immediately and saved on this device.',
    'اللغة الحالية': 'Current language',
    'إدارة الخدمات': 'Service management',
    'الرئيسية': 'Home',
    'المعاملات': 'Transactions',
    'الشكاوى': 'Complaints',
    'الأخبار': 'News',
    'رجوع': 'Back',
    'إلغاء': 'Cancel',
    'حفظ': 'Save',
    'تأكيد': 'Confirm',
    'إعادة المحاولة': 'Try again',
    'مطلوب': 'Required',
    'يجب إدخال': 'Required',
    'غير متوفر': 'Unavailable',
    'غير موجود': 'Not found',
    'موجود مسبق': 'Already exists',
    'مستخدم مسبق': 'Already in use',
    'غير متطابق': 'Does not match',
    'التأكيد': 'Confirmation',
    'صيغة': 'Format',
    'رمز': 'Code',
    'تاريخ': 'Date',
    'بريد': 'Email',
    'نعم': 'Yes',
    'لا': 'No',

    // Home and public content.
    'بلديتنا الإلكترونية': 'Our E-Municipality',
    'بوابة المواطن الرقمية': 'Digital Citizen Portal',
    'جارٍ تحميل بوابة المواطن الرقمية':
        'Loading the Digital Citizen Portal',
    'الجمهورية العربية السورية': 'Syrian Arab Republic',
    'الخدمات الإلكترونية': 'Digital services',
    'الخدمات السريعة': 'Quick services',
    'ابدأ بالخدمة التي تحتاجها الآن': 'Start with the service you need now',
    'الخدمات والمعاملات الرسمية.': 'Official services and transactions.',
    'إبلاغ جديد': 'New report',
    'طلب رسمي': 'Official request',
    'بلّغ عن مشكلة في منطقتك': 'Report an issue in your area',
    'ابدأ أو تابع طلباتك الرسمية': 'Start or track your official requests',
    'عرض التفاصيل': 'View details',
    'تقديم شكوى': 'Submit a complaint',
    'التبليغ عن المشكلات': 'Report public issues',
    'تقديم معاملة': 'Submit a transaction',
    'إدارة الطلبات الرسمية': 'Manage official requests',
    'تبرع للمدينة': 'Donate to the city',
    'ساهم في تطوير مجتمعنا': 'Help improve our community',
    'سيتم توفير خدمة التبرع للمدينة قريبًا':
        'The city donation service will be available soon.',
    'ابحث في الخدمات...': 'Search services…',
    'أحدث الأخبار والإعلانات': 'Latest news and announcements',
    'تنبيهات المنطقة': 'Area alerts',
    'الشكاوى الموحدة على الخريطة': 'Unified complaints on the map',
    'عرض حيّ للمشكلات المبلّغ عنها ضمن بلديتك.':
        'A live view of reported issues in your municipality.',
    'شكاوى المنطقة': 'Area complaints',
    'عرض مواقع الشكاوى الرئيسية ضمن بلديتك.':
        'View locations of primary complaints in your municipality.',
    'جميع الحالات': 'All statuses',
    'قيد المتابعة': 'Active',
    'غير منتهية': 'Open',
    'منتهية': 'Closed',
    'إعادة تحميل الخريطة': 'Reload map',
    'جارٍ تحميل الشكاوى الموحدة...': 'Loading unified complaints…',
    'تعذر تحميل خريطة الشكاوى.': 'The complaints map could not be loaded.',
    'لا توجد شكاوى موحّدة ذات إحداثيات لعرضها على الخريطة.':
        'There are no unified complaints with coordinates to display on the map.',
    'شكوى موحدة': 'Unified complaint',
    'افتتاح حديقة جديدة في وسط المدينة':
        'A new park opens in the city center',
    'تحديث آلية استقبال معاملات البناء':
        'Updated process for receiving construction applications',
    'تطوير المدينة': 'City development',
    'إعلان رسمي': 'Official announcement',
    'إعلانات وخدمات البلدية': 'Municipal announcements and services',
    'تكبير الخريطة': 'Zoom in',
    'تصغير الخريطة': 'Zoom out',

    // Authentication and account access.
    'تسجيل الدخول': 'Sign in',
    'مواطن': 'Citizen',
    'زائر': 'Visitor',
    'رقم الهاتف أو البريد الإلكتروني': 'Phone number or email',
    'البريد الإلكتروني أو رقم الهاتف': 'Email address or phone number',
    'أدخل رقم الهاتف أو البريد': 'Enter your phone number or email',
    'كلمة المرور': 'Password',
    'أدخل كلمة المرور': 'Enter your password',
    'نسيت كلمة المرور؟': 'Forgot your password?',
    'نسيت كلمة المرور': 'Forgot password',
    'ليس لديك حساب؟': 'Don’t have an account?',
    'إنشاء حساب جديد': 'Create a new account',
    'يمكنك الدخول كزائر واستعراض الخدمات العامة دون بريد إلكتروني أو كلمة مرور.':
        'Continue as a guest to browse public services without an email or password.',
    'بيانات تسجيل الدخول غير صحيحة.': 'The sign-in details are incorrect.',
    'فشل تسجيل الدخول. حاول مرة أخرى.': 'Sign-in failed. Please try again.',
    'بريدك الإلكتروني': 'Your email',
    'أدخل بريدك الإلكتروني لاسترداد كلمة المرور':
        'Enter your email to recover your password',
    'أدخل هنا...': 'Enter here…',
    'إرسال الرمز': 'Send code',
    'فشل إرسال الرمز. حاول مرة أخرى.':
        'Failed to send the code. Please try again.',
    'تعذر التحقق من الرمز. حاول مرة أخرى.':
        'The code could not be verified. Please try again.',
    'تعذر تحديد وجهة رمز التحقق.':
        'The verification-code destination could not be determined.',
    'رمز التحقق': 'Verification code',
    'أدخل رمز التحقق المكون من 4 أرقام.':
        'Enter the 4-digit verification code.',
    'الرمز غير صحيح. حاول مرة أخرى.':
        'The code is incorrect. Please try again.',
    'لم تستلم الرمز؟': 'Didn’t receive the code?',
    'إعادة إرسال الرمز': 'Resend code',
    'تمت إعادة إرسال الرمز': 'The code was resent.',
    'فشل إعادة إرسال الرمز': 'Failed to resend the code.',
    'تحقق': 'Verify',
    'تعيين كلمة مرور جديدة': 'Set a new password',
    'كلمة المرور الجديدة': 'New password',
    'أدخل كلمة المرور الجديدة': 'Enter the new password',
    'تأكيد كلمة المرور': 'Confirm password',
    'أعد إدخال كلمة المرور': 'Re-enter the password',
    'كلمات المرور غير متطابقة': 'Passwords do not match.',
    'فشل تعيين كلمة المرور الجديدة': 'Failed to set the new password.',
    'العودة إلى تسجيل الدخول': 'Back to sign in',
    'تغيير كلمة المرور المؤقتة': 'Change temporary password',
    'لأمان حسابك، يجب استبدال كلمة المرور المؤقتة قبل متابعة استخدام النظام.':
        'For your account security, replace the temporary password before continuing.',
    'الرجاء إدخال كلمة المرور الجديدة وتأكيدها\nللمتابعة.':
        'Enter and confirm the new password to continue.',
    'كلمة المرور المؤقتة': 'Temporary password',
    'كلمة المرور الحالية': 'Current password',
    'تأكيد كلمة المرور الجديدة': 'Confirm new password',
    'تغيير كلمة المرور': 'Change password',
    'جارٍ التحقق...': 'Verifying…',
    'تم تغيير كلمة المرور. سجّل الدخول بكلمتك الجديدة.':
        'Password changed. Sign in with your new password.',
    'تعذر تغيير كلمة المرور المؤقتة.':
        'The temporary password could not be changed.',
    'إظهار كلمة المرور': 'Show password',
    'إخفاء كلمة المرور': 'Hide password',
    'يجب أن تحتوي كلمة المرور على:': 'Password must contain:',
    '8 أحرف على الأقل': 'At least 8 characters',
    'حرف كبير وحرف صغير': 'Uppercase and lowercase letters',
    'رقم أو رمز خاص': 'A number or special character',
    'يجب ألا تقل كلمة المرور عن 8 محارف':
        'Password must be at least 8 characters.',
    'يجب أن تختلف عن كلمة المرور المؤقتة':
        'Must differ from the temporary password.',

    // Registration.
    'البيانات الشخصية': 'Personal information',
    'إنشاء حساب مواطن': 'Create a citizen account',
    'إنشاء الحساب الرسمي': 'Create official account',
    'بوابة الخدمات الإلكترونية للجمهورية العربية السورية. يرجى إدخال بياناتك الرسمية بدقة.':
        'Syrian Arab Republic e-services portal. Enter your official information accurately.',
    'الاسم الكامل (كما في الهوية)': 'Full name (as shown on ID)',
    'الاسم الثلاثي': 'Full legal name',
    'أدخل الاسم الثلاثي كما في الهوية':
        'Enter your full legal name exactly as shown on your ID.',
    'الاسم الكامل': 'Full name',
    'الرقم الوطني': 'National ID number',
    'الرقم الوطني مطلوب': 'National ID number is required.',
    'يجب أن يتكون الرقم الوطني من 11 رقماً':
        'The national ID number must contain 11 digits.',
    'الجنس': 'Gender',
    'اختر الجنس...': 'Select gender…',
    'اختر الجنس': 'Select a gender.',
    'ذكر': 'Male',
    'أنثى': 'Female',
    'مكان الولادة': 'Place of birth',
    'مكان الولادة مطلوب': 'Place of birth is required.',
    'المحافظة - المدينة': 'Governorate — city',
    'بيانات السكن': 'Residence information',
    'المحافظة': 'Governorate',
    'اختر المحافظة': 'Select a governorate.',
    'اختر المحافظة...': 'Select a governorate…',
    'جاري تحميل المحافظات...': 'Loading governorates…',
    'البلدية التابع لها': 'Municipality',
    'البلدية': 'Municipality',
    'اختر البلدية': 'Select a municipality.',
    'اختر البلدية...': 'Select a municipality…',
    'جاري تحميل البلديات...': 'Loading municipalities…',
    'إعادة تحميل البلديات': 'Reload municipalities',
    'معلومات الدخول': 'Account credentials',
    'رقم الهاتف الجوال': 'Mobile phone number',
    'رقم الهاتف': 'Phone number',
    'رقم الهاتف مطلوب': 'Phone number is required.',
    'رقم الهاتف غير صحيح': 'Enter a valid phone number.',
    'أدخل رقماً سورياً صحيحاً يبدأ بـ 09':
        'Enter a valid Syrian mobile number starting with 09.',
    'البريد الإلكتروني': 'Email address',
    'البريد الإلكتروني غير صحيح': 'Enter a valid email address.',
    'أدخل بريداً إلكترونياً صحيحاً': 'Enter a valid email address.',
    'example@mail.sy': 'example@mail.sy',
    'شخص يحتاج إلى رعاية خاصة (ذوي الاحتياجات الخاصة، كبار السن)':
        'Person requiring special care (people with disabilities or older adults)',
    'أوافق على ': 'I agree to ',
    'الشروط والأحكام': 'Terms and Conditions',
    ' وسياسة الخصوصية الخاصة بالبوابة.':
        ' and the portal Privacy Policy.',
    'يجب الموافقة على الشروط والأحكام':
        'You must agree to the Terms and Conditions.',
    'إنشاء الحساب': 'Create account',
    'لديك حساب بالفعل؟': 'Already have an account?',
    'تعذر إنشاء الحساب حاليًا. حاول مرة أخرى لاحقًا.':
        'The account cannot be created right now. Please try again later.',
    'تعذر تحميل المحافظات حاليًا. حاول مرة أخرى لاحقًا.':
        'Governorates cannot be loaded right now. Please try again later.',
    'تعذر تحميل البلديات حاليًا. حاول مرة أخرى لاحقًا.':
        'Municipalities cannot be loaded right now. Please try again later.',
    'كلمة المرور يجب أن تكون 8 أحرف على الأقل':
        'Password must be at least 8 characters.',

    // Complaints and map.
    'أنشئ مسودة، أرفق الصور، ثم أرسلها للبلدية':
        'Create a draft, attach photos, then send it to the municipality',
    'بلاغ جديد': 'New report',
    'تعديل المسودة': 'Edit draft',
    'سجل الشكاوى': 'Complaint history',
    'تفاصيل الشكوى': 'Complaint details',
    'تاريخ الحالة': 'Status history',
    'لا توجد تحديثات عامة على حالة الشكوى حتى الآن.':
        'There are no public status updates for this complaint yet.',
    'تحديث على حالة الشكوى': 'Complaint status update',
    'جارٍ تحميل المزيد...': 'Loading more…',
    'تحميل المزيد': 'Load more',
    'إعدادات تحميل سجل الشكاوى غير صالحة.':
        'Complaint-history loading settings are invalid.',
    'رقم الشكوى الموحدة': 'Unified complaint number',
    'عدد المبلّغين': 'Number of reporters',
    'موقع الشكوى': 'Complaint location',
    'الصور المرفقة': 'Attached photos',
    'لا توجد صور مرفقة بهذه الشكوى.':
        'No photos are attached to this complaint.',
    'لم يُضف وصف للشكوى.': 'No complaint description was added.',
    'لم يُضف وصف للموقع.': 'No location description was added.',
    'تعذر تحميل الصورة.': 'The image could not be loaded.',
    'إغلاق': 'Close',
    'معلومات زمنية': 'Timeline',
    'تاريخ الإنشاء': 'Created',
    'آخر تحديث': 'Last updated',
    'تاريخ الإرسال': 'Submitted',
    'تاريخ الربط': 'Linked',
    'لا توجد معلومات زمنية متاحة.':
        'No timeline information is available.',
    'تعذر تحميل أحدث تفاصيل الشكوى. اسحب للأسفل للمحاولة مجددًا.':
        'The latest complaint details could not be loaded. Pull down to try again.',
    'إضافة شكوى جديدة': 'Add a new complaint',
    'مجال الشكوى': 'Complaint category',
    'تصنيف الشكوى': 'Complaint category',
    'اختر المجال الرئيسي': 'Select the main category',
    'نوع الشكوى': 'Complaint type',
    'اختر المجال أولًا': 'Select a category first',
    'اختر نوع المشكلة': 'Select the issue type',
    'العنوان': 'Title',
    'عنوان الشكوى': 'Complaint title',
    'أدخل عنوانًا واضحًا': 'Enter a clear title',
    'الوصف': 'Description',
    'وصف الشكوى': 'Complaint description',
    'اكتب تفاصيل المشكلة': 'Describe the issue',
    'وصف الموقع (اختياري)': 'Location description (optional)',
    'وصف الموقع': 'Location description',
    'مثال: المزة، الشارع الرئيسي': 'Example: Al-Mazzeh, main street',
    'موقع الشكوى على الخريطة': 'Complaint location on the map',
    'تم تحديد الموقع بنجاح': 'Location selected successfully',
    'اضغط لاختيار الموقع الدقيق': 'Tap to select the precise location',
    'تغيير الموقع': 'Change location',
    'اختيار من الخريطة': 'Select on map',
    'صور الشكوى (اختياري)': 'Complaint photos (optional)',
    'صور الشكوى': 'Complaint photos',
    'JPG أو PNG، حتى 5MB لكل صورة.':
        'JPG or PNG, up to 5 MB per image.',
    'ستُرفع بعد حفظ المسودة': 'Will be uploaded after saving the draft',
    'إضافة صور': 'Add photos',
    'حفظ كمسودة': 'Save as draft',
    'تحديث المسودة': 'Update draft',
    'إرسال الشكوى': 'Submit complaint',
    'إلغاء التعديل وبدء شكوى جديدة':
        'Cancel editing and start a new complaint',
    'الشكاوى السابقة': 'Previous complaints',
    'لا توجد شكاوى حتى الآن.': 'No complaints yet.',
    'تعديل': 'Edit',
    'حذف': 'Delete',
    'حذف المسودة': 'Delete draft',
    'هل تريد حذف هذه المسودة نهائيًا؟':
        'Do you want to permanently delete this draft?',
    'تم حذف المسودة.': 'Draft deleted.',
    'تم حفظ المسودة.': 'Draft saved.',
    'تم إرسال الشكوى بنجاح.': 'Complaint submitted successfully.',
    'تعذر تحديد بلديتك من الملف الشخصي. حدّث بيانات الحساب قبل الإرسال.':
        'Your municipality could not be identified from your profile. Update your account details before submitting.',
    'لا يمكن تعديل الشكوى بعد إرسالها.':
        'A complaint cannot be edited after submission.',
    'أكمل الحقول المطلوبة قبل إرسال الشكوى.':
        'Complete the required fields before submitting the complaint.',
    'اختيار موقع الشكوى': 'Choose complaint location',
    'حدّد النقطة الأقرب للمشكلة': 'Select the point nearest to the issue',
    'اضغط على الخريطة لتثبيت النقطة': 'Tap the map to place the pin',
    'سنضيف اسم المكان والإحداثيات تلقائيًا':
        'The place name and coordinates will be added automatically',
    'خط العرض': 'Latitude',
    'خط الطول': 'Longitude',
    'استخدام موقعي الحالي': 'Use my current location',
    'جارٍ تحديد موقعك...': 'Locating you…',
    'اعتماد هذا الموقع': 'Confirm this location',
    'اختر موقع المشكلة': 'Choose the issue location',
    'المس الخريطة أو استخدم موقعك الحالي للبدء.':
        'Tap the map or use your current location to begin.',
    'جارٍ التعرّف على المكان...': 'Identifying the place…',
    'لحظات ونحاول إظهار اسم الشارع أو الحي.':
        'Please wait while we find the street or neighborhood name.',
    'تم تحديد الموقع بالإحداثيات': 'Location identified by coordinates',
    'موقع محدد على الخريطة': 'Selected map location',
    'فتح إعدادات الموقع': 'Open location settings',
    'فتح إعدادات التطبيق': 'Open app settings',
    'لم يتوفر اسم لهذا الموضع، ويمكنك اعتماده بالإحداثيات.':
        'No place name is available; you can confirm the coordinates.',
    'تعذر جلب اسم المكان الآن، ويمكنك اعتماد الإحداثيات بأمان.':
        'The place name is unavailable; you can safely confirm the coordinates.',

    // Transaction and complaint statuses.
    'متابعة الطلبات الرسمية': 'Track official requests',
    'قيد المراجعة': 'Under review',
    'مكتملة': 'Completed',
    'بانتظار الدفع': 'Awaiting payment',
    'طلب رخصة بناء': 'Building permit request',
    'إخراج قيد عقاري': 'Property record extract',
    'تسديد رسوم النظافة': 'Sanitation fee payment',
    'مسودة': 'Draft',
    'تم الإرسال': 'Submitted',
    'مرسلة': 'Submitted',
    'قيد المعالجة': 'In progress',
    'مرفوضة': 'Rejected',
    'محلولة': 'Resolved',
    'مغلقة': 'Closed',

    // Identity verification and profile.
    'حساب المواطن': 'Citizen account',
    'مستخدم تجريبي': 'Demo user',
    'توثيق الحساب': 'Account verification',
    'توثيق الحساب مطلوب': 'Account verification required',
    'الحساب غير موثق': 'Account not verified',
    'حساب المواطن غير موثق': 'Citizen account not verified',
    'حساب المواطن غير موثق. يجب توثيق الحساب قبل إرسال الشكوى.':
        'Your citizen account is not verified. Verify it before submitting a complaint.',
    'توثيق الحساب الآن': 'Verify account now',
    'توثيق الحساب قيد المراجعة': 'Account verification under review',
    'طلب التوثيق قيد المراجعة': 'Verification request under review',
    'الحساب موثق': 'Account verified',
    'موثق': 'Verified',
    'غير موثق': 'Not verified',
    'أكمل توثيق هويتك': 'Complete identity verification',
    'إرسال طلب التوثيق': 'Submit verification request',
    'تحديث حالة التوثيق': 'Refresh verification status',
    'تحديث حالة الطلب': 'Refresh request status',
    'بعد اعتماد الطلب من البلدية.': 'after approval by the municipality.',
    'يمكنك تجهيز المسودات، وسيصبح الإرسال متاحاً بعد اعتماد التوثيق من البلدية.':
        'You can prepare drafts; submission becomes available after municipal approval.',
    'يمكنك تجهيز المسودة، لكن يجب توثيق حسابك قبل إرسال الشكاوى والمعاملات الرسمية.':
        'You can prepare a draft, but account verification is required before submitting official complaints and transactions.',
    'طلب توثيق حسابك قيد المراجعة. يمكنك إرسال الشكوى بعد اعتماد الطلب من البلدية.':
        'Your verification request is under review. You can submit the complaint after municipal approval.',
    'البيانات المدخلة': 'Submitted information',
    'JPG أو PNG — بحد أقصى 4MB': 'JPG or PNG — up to 4 MB',
    'ارفع صورة واضحة للوجهين الأمامي والخلفي من هويتك. تُراجع الصور من البلدية قبل تفعيل الحساب الموثق.':
        'Upload clear images of the front and back of your ID. The municipality will review them before verifying your account.',
    'تُستخدم صور الهوية للتحقق من الحساب فقط. تأكد من صحة الصور قبل الإرسال لأن الطلب سيصبح قيد المراجعة.':
        'ID images are used only for account verification. Check them before submitting because the request will enter review.',
    'للوصول إلى كافة الخدمات والمعاملات الرسمية، أرسل صور الهوية المطلوبة ليتم التحقق منها.':
        'To access all official services and transactions, submit the required ID images for verification.',
    'تم استلام صور الهوية بنجاح. ستظهر حالة الحساب الموثق بعد اعتماد الطلب من البلدية.':
        'Your ID images were received. Verified status will appear after municipal approval.',
    'تم التحقق من بيانات هويتك، ويمكنك الآن الوصول إلى الخدمات والمعاملات الرسمية.':
        'Your identity has been verified. You can now access official services and transactions.',
    'تاريخ الميلاد': 'Date of birth',
    'تاريخ التوظيف': 'Employment date',
    'الرعاية الخاصة': 'Special care',
    'حالة الرعاية الخاصة': 'Special-care status',
    'الهوية': 'Identity document',
    'إضافة صورة الهوية': 'Add ID photos',
    'الوجه الأمامي للهوية': 'Front of ID',
    'الوجه الخلفي للهوية': 'Back of ID',
    'صورة الوجه الأمامي للهوية': 'Front ID image',
    'صورة الوجه الخلفي للهوية': 'Back ID image',
    'التقاط صورة بالكاميرا': 'Take a photo',
    'اختيار صورة من الجهاز': 'Choose a photo from device',
    'إضافة الصورة': 'Add photo',
    'استبدال': 'Replace',
    'حذف الصورة': 'Delete image',
    'رفع ملف': 'Upload file',
    'صورة': 'Image',
    'الحجم': 'Size',
    'الصيغة': 'Format',
    'تأكد من وضوح الصورة وكامل بيانات الهوية.':
        'Make sure the image and all ID details are clear.',
    'تأكد من ظهور كامل الهوية دون قص الحواف.':
        'Make sure the entire ID is visible without cropped edges.',
    'تُراجع الصور من البلدية قبل تفعيل الحساب الموثق.':
        'The municipality reviews the images before verification is activated.',
    'تعذر اختيار الصورة. تحقق من صلاحيات الكاميرا والصور.':
        'The image could not be selected. Check camera and photo permissions.',
    'تعذر إرسال صور الهوية. حاول مرة أخرى.':
        'ID images could not be sent. Please try again.',
    'تم إرسال صور الهوية بنجاح، وسيتم إشعارك بعد مراجعتها.':
        'ID images were submitted successfully. You will be notified after review.',
    'تعذر تحميل الملف الشخصي.': 'The profile could not be loaded.',

    // Validation, network, and server messages.
    'هذا الحقل مطلوب.': 'This field is required.',
    'تاريخ الميلاد مطلوب': 'Date of birth is required.',
    'الاسم الكامل مطلوب': 'Full name is required.',
    'البريد الإلكتروني مطلوب': 'Email address is required.',
    'البريد الإلكتروني مطلوب وبصيغة صحيحة.':
        'A valid email address is required.',
    'رقم الهاتف أو البريد الإلكتروني مطلوب':
        'Phone number or email is required.',
    'رقم الهاتف أو البريد الإلكتروني مطلوب.':
        'Phone number or email is required.',
    'كلمة المرور مطلوبة': 'Password is required.',
    'كلمة المرور الجديدة مطلوبة': 'New password is required.',
    'كلمة المرور المؤقتة مطلوبة': 'Temporary password is required.',
    'صيغة البريد الإلكتروني غير صحيحة.': 'Enter a valid email address.',
    'تحقق من البيانات المدخلة.': 'Check the entered information.',
    'البيانات المدخلة غير صالحة.': 'The entered information is invalid.',
    'بيانات الاعتماد': 'Credentials',
    'بيانات الدخول': 'Sign-in details',
    'بيانات الدخول غير صحيحة أو انتهت صلاحية الجلسة.':
        'The credentials are incorrect or the session has expired.',
    'لم يتم العثور على حساب بهذه البيانات.':
        'No account was found with these details.',
    'رمز التحقق غير صحيح أو منتهي الصلاحية.':
        'The verification code is incorrect or expired.',
    'انتهت مهلة الاتصال بالخادم. حاول مرة أخرى.':
        'The server connection timed out. Please try again.',
    'تعذر الاتصال بالخادم. تحقق من الشبكة وعنوان الخادم.':
        'Could not connect to the server. Check the network and server address.',
    'تم إلغاء الطلب.': 'The request was cancelled.',
    'تعذر التحقق من شهادة أمان الخادم.':
        'The server security certificate could not be verified.',
    'حدث خطأ غير متوقع أثناء الاتصال بالخادم.':
        'An unexpected server connection error occurred.',
    'تعذر إعداد الاتصال بالخادم.':
        'The server connection could not be prepared.',
    'حدث خطأ غير متوقع أثناء تجهيز الطلب.':
        'An unexpected error occurred while preparing the request.',
    'حدث خطأ في الخادم. حاول لاحقًا.':
        'A server error occurred. Please try again later.',
    'المورد المطلوب غير موجود.': 'The requested resource was not found.',
    'لا تملك صلاحية تنفيذ هذه العملية.':
        'You do not have permission to perform this action.',
    'يجب تسجيل الدخول للمتابعة.': 'You must sign in to continue.',
    'لا توجد جلسة مستخدم نشطة.': 'There is no active user session.',
    'تتعارض العملية مع بيانات موجودة مسبقًا.':
        'This action conflicts with existing data.',
    'تم تجاوز عدد المحاولات المسموح. حاول لاحقًا.':
        'Too many attempts. Please try again later.',
    'أعاد الخادم استجابة غير صالحة.': 'The server returned an invalid response.',
    'أعاد الخادم استجابة ليست كائن JSON.':
        'The server response is not a JSON object.',
    'تعذر التحقق من استجابة الخادم.':
        'The server response could not be verified.',
    'تعذر إكمال الطلب.': 'The request could not be completed.',
    'تعذر إكمال العملية. حاول مرة أخرى.':
        'The action could not be completed. Please try again.',
    'تعذر إبلاغ الخادم، لكن تم إنهاء الجلسة محليًا.':
        'The server could not be notified, but the local session was ended.',
    'لم تتضمن استجابة الخادم بيانات المستخدم.':
        'The server response did not include user data.',
    'لم تتضمن استجابة الخادم حقل data صالحًا.':
        'The server response did not include a valid data field.',
    'لم تتضمن استجابة الخادم قائمة بيانات صالحة.':
        'The server response did not include a valid data list.',
    'أحد الملفات المحددة ليس صورة شكوى صالحة.':
        'One of the selected files is not a valid complaint image.',
    'اختر صورة واحدة على الأقل.': 'Select at least one image.',
    'يمكن إرفاق 5 صور كحد أقصى.': 'You can attach up to 5 images.',
    'يجب أن تكون صور الشكوى بصيغة JPG أو PNG.':
        'Complaint images must be JPG or PNG.',
    'يجب ألا يتجاوز حجم كل صورة شكوى 5 ميغابايت.':
        'Each complaint image must not exceed 5 MB.',
    'صيغة الصورة غير مدعومة. استخدم JPG أو PNG.':
        'Unsupported image format. Use JPG or PNG.',
    'يجب ألا يتجاوز حجم كل صورة 4 ميغابايت.':
        'Each image must not exceed 4 MB.',
    'يجب أن تكون صورة الهوية بصيغة JPG أو PNG.':
        'ID images must be JPG or PNG.',
    'يجب ألا يتجاوز حجم كل صورة هوية 4 ميغابايت.':
        'Each ID image must not exceed 4 MB.',
    'الملف المحدد ليس صورة هوية صالحة.':
        'The selected file is not a valid ID image.',
    'خدمة الموقع غير مفعّلة. فعّل GPS ثم حاول مجددًا.':
        'Location services are disabled. Enable GPS and try again.',
    'لم يتم منح إذن الموقع. يمكنك اختيار الموقع يدويًا من الخريطة.':
        'Location permission was not granted. You can select the location manually.',
    'إذن الموقع مرفوض نهائيًا. فعّله من إعدادات التطبيق أو اختر الموقع يدويًا.':
        'Location permission is permanently denied. Enable it in app settings or select manually.',
    'تعذر تثبيت موقعك بسرعة. اقترب من نافذة أو اختر الموقع يدويًا.':
        'Your location could not be fixed quickly. Move near a window or select it manually.',
    'تعذر تحديد موقعك الآن. حاول مجددًا أو اختر الموقع يدويًا.':
        'Your location is unavailable. Try again or select it manually.',
    'لم تتوفر أسماء للأماكن القريبة.': 'No nearby place names are available.',

    // Backend category names returned in Arabic.
    'الطرق والأرصفة': 'Roads and sidewalks',
    'حفرة في الطريق': 'Road pothole',
    'رصيف متضرر': 'Damaged sidewalk',
    'إشارة مرور متضررة': 'Damaged traffic sign',
    'تعدٍ على الطريق': 'Road encroachment',
    'النظافة': 'Sanitation',
    'تراكم النفايات': 'Waste accumulation',
    'حاوية ممتلئة': 'Full waste container',
    'حاوية متضررة': 'Damaged waste container',
    'مكب نفايات عشوائي': 'Illegal dumping site',
    'الإنارة': 'Street lighting',
    'مصباح شارع معطل': 'Broken streetlight',
    'عمود إنارة متضرر': 'Damaged lighting pole',
    'انقطاع إنارة شارع': 'Street lighting outage',
    'المياه والصرف الصحي': 'Water and sanitation',
    'تسرب مياه': 'Water leak',
    'انسداد صرف صحي': 'Sewer blockage',
    'فيضان مياه صرف': 'Sewage overflow',
    'الحدائق والمرافق العامة': 'Parks and public facilities',
    'تلف ألعاب الحديقة': 'Damaged playground equipment',
    'تلف مقاعد عامة': 'Damaged public seating',
    'أشجار بحاجة إلى تقليم': 'Trees requiring pruning',
    'بلدية كفرسوسة': 'Kafr Sousa Municipality',
    'بلدية دمشق': 'Damascus Municipality',
    'بلدية دوما': 'Douma Municipality',
    'دمشق': 'Damascus',
    'ريف دمشق': 'Rif Dimashq',
  };
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return locale.languageCode == 'ar' || locale.languageCode == 'en';
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsBuildContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  String tr(String source) {
    final localizations =
        AppLocalizations.maybeOf(this) ?? const AppLocalizations(Locale('ar'));
    return localizations.translate(source);
  }
}
