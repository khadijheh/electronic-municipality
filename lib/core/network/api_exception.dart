import 'package:dio/dio.dart';

enum ApiExceptionKind {
  network,
  timeout,
  unauthorized,
  forbidden,
  notFound,
  conflict,
  validation,
  rateLimited,
  server,
  cancelled,
  invalidResponse,
  configuration,
  unknown,
}

/// A stable application-facing error independent of Dio and Laravel internals.
class ApiException implements Exception {
  const ApiException({
    required this.kind,
    required this.message,
    this.statusCode,
    this.errors = const {},
    this.cause,
    this.technicalMessage,
  });

  factory ApiException.fromDioException(DioException exception) {
    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return ApiException(
          kind: ApiExceptionKind.timeout,
          message: 'انتهت مهلة الاتصال بالخادم. حاول مرة أخرى.',
          cause: exception,
        );
      case DioExceptionType.connectionError:
        return ApiException(
          kind: ApiExceptionKind.network,
          message: 'تعذر الاتصال بالخادم. تحقق من الشبكة وعنوان الخادم.',
          cause: exception,
        );
      case DioExceptionType.cancel:
        return ApiException(
          kind: ApiExceptionKind.cancelled,
          message: 'تم إلغاء الطلب.',
          cause: exception,
        );
      case DioExceptionType.badCertificate:
        return ApiException(
          kind: ApiExceptionKind.network,
          message: 'تعذر التحقق من شهادة أمان الخادم.',
          cause: exception,
        );
      case DioExceptionType.badResponse:
        return _fromResponse(exception);
      case DioExceptionType.unknown:
        return ApiException(
          kind: ApiExceptionKind.unknown,
          message: 'حدث خطأ غير متوقع أثناء الاتصال بالخادم.',
          cause: exception,
        );
    }
  }

  factory ApiException.invalidResponse({
    String message = 'أعاد الخادم استجابة غير صالحة.',
    Object? cause,
    String? technicalMessage,
  }) {
    return ApiException(
      kind: ApiExceptionKind.invalidResponse,
      message: message,
      cause: cause,
      technicalMessage: technicalMessage,
    );
  }

  factory ApiException.configuration(String technicalMessage) {
    return ApiException(
      kind: ApiExceptionKind.configuration,
      message: 'تعذر إعداد الاتصال بالخادم.',
      technicalMessage: technicalMessage,
    );
  }

  factory ApiException.unauthorized({
    String message = 'يجب تسجيل الدخول للمتابعة.',
  }) {
    return ApiException(
      kind: ApiExceptionKind.unauthorized,
      message: message,
      statusCode: 401,
    );
  }

  factory ApiException.validation({
    required String message,
    Map<String, List<String>> errors = const {},
  }) {
    return ApiException(
      kind: ApiExceptionKind.validation,
      message: message,
      statusCode: 422,
      errors: errors,
    );
  }

  final ApiExceptionKind kind;
  final String message;
  final int? statusCode;
  final Map<String, List<String>> errors;
  final Object? cause;

  /// Kept for debug logging only. Never render this value in the UI.
  final String? technicalMessage;

  bool get isUnauthorized => kind == ApiExceptionKind.unauthorized;
  bool get isValidation => kind == ApiExceptionKind.validation;
  bool get requiresCitizenVerification =>
      isValidation && errors.containsKey('citizen');

  String? errorFor(String field) {
    final fieldErrors = errors[field];
    return fieldErrors == null || fieldErrors.isEmpty
        ? null
        : fieldErrors.first;
  }

  static ApiException _fromResponse(DioException exception) {
    final response = exception.response;
    final statusCode = response?.statusCode;
    final body = _asStringKeyedMap(response?.data);
    final rawErrors = _normalizeErrors(body?['errors']);
    final serverMessage = _nonEmptyString(body?['message']);
    final kind = _kindForStatus(statusCode);
    final path = exception.requestOptions.path;
    final errors = _userFacingValidationErrors(rawErrors);

    return ApiException(
      kind: kind,
      message: _userMessageFor(
        kind: kind,
        path: path,
        errors: errors,
      ),
      statusCode: statusCode,
      errors: errors,
      cause: exception,
      technicalMessage: _technicalMessage(
        responseData: response?.data,
        serverMessage: serverMessage,
      ),
    );
  }

  static Map<String, dynamic>? _asStringKeyedMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map(
        (key, dynamic item) => MapEntry(key.toString(), item),
      );
    }
    return null;
  }

  static Map<String, List<String>> _normalizeErrors(Object? value) {
    final map = _asStringKeyedMap(value);
    if (map == null) return const {};

    final result = <String, List<String>>{};
    for (final entry in map.entries) {
      final rawValue = entry.value;
      final messages = rawValue is Iterable
          ? rawValue
              .map((item) => item.toString().trim())
              .where((item) => item.isNotEmpty)
              .toList(growable: false)
          : <String>[
              if (rawValue != null && rawValue.toString().trim().isNotEmpty)
                rawValue.toString().trim(),
            ];

      if (messages.isNotEmpty) {
        result[entry.key] = List<String>.unmodifiable(messages);
      }
    }

    return Map<String, List<String>>.unmodifiable(result);
  }

  static String? _nonEmptyString(Object? value) {
    if (value is! String) return null;
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  static Map<String, List<String>> _userFacingValidationErrors(
    Map<String, List<String>> rawErrors,
  ) {
    if (rawErrors.isEmpty) return const {};

    final result = <String, List<String>>{};
    for (final entry in rawErrors.entries) {
      result[entry.key] = <String>[
        _validationMessageFor(
          field: entry.key,
          rawMessages: entry.value,
        ),
      ];
    }

    return Map<String, List<String>>.unmodifiable(result);
  }

  static String _validationMessageFor({
    required String field,
    required List<String> rawMessages,
  }) {
    final label = _fieldLabel(field);
    final normalized = rawMessages.join(' ').toLowerCase();
    final isIdentityPhoto =
        field == 'front_id_photo' || field == 'back_id_photo';
    final isComplaintImage = field == 'images' || field.startsWith('images.');

    if (_containsAny(normalized, const [
      'credentials',
      'بيانات الاعتماد',
      'بيانات الدخول',
    ])) {
      return 'بيانات تسجيل الدخول غير صحيحة.';
    }
    if (field == 'citizen' &&
        _containsAny(normalized, const [
          'must be verified',
          'account must be verified',
          'verified before submitting',
          'توثيق الحساب',
          'الحساب غير موثق',
        ])) {
      return 'حساب المواطن غير موثق. يجب توثيق الحساب قبل إرسال الشكوى.';
    }
    if (_containsAny(normalized, const [
      'required',
      'مطلوب',
      'يجب إدخال',
    ])) {
      return 'حقل $label مطلوب.';
    }
    if (_containsAny(normalized, const [
      'already been taken',
      'unique',
      'مستخدم مسبق',
      'موجود مسبق',
    ])) {
      return '$label مستخدم مسبقًا.';
    }
    if (_containsAny(normalized, const [
      'confirmed',
      'confirmation',
      'غير متطابق',
      'التأكيد',
    ])) {
      return 'تأكيد $label غير مطابق.';
    }
    if (isIdentityPhoto &&
        _containsAny(normalized, const [
          'max',
          'must not exceed',
          '4mb',
          '4096',
          'الحجم',
        ])) {
      return 'يجب ألا يتجاوز حجم كل صورة هوية 4 ميغابايت.';
    }
    if (isIdentityPhoto &&
        _containsAny(normalized, const [
          'mimes',
          'jpg',
          'jpeg',
          'png',
          'type',
          'صيغة',
        ])) {
      return 'يجب أن تكون صورة الهوية بصيغة JPG أو PNG.';
    }
    if (isIdentityPhoto &&
        _containsAny(normalized, const [
          'image',
          'صورة',
        ])) {
      return 'الملف المحدد ليس صورة هوية صالحة.';
    }
    if (isComplaintImage &&
        _containsAny(normalized, const [
          'max',
          'must not exceed',
          '5mb',
          '5120',
          'الحجم',
        ])) {
      return 'يجب ألا يتجاوز حجم كل صورة شكوى 5 ميغابايت.';
    }
    if (isComplaintImage &&
        _containsAny(normalized, const [
          'mimes',
          'jpg',
          'jpeg',
          'png',
          'type',
          'صيغة',
        ])) {
      return 'يجب أن تكون صور الشكوى بصيغة JPG أو PNG.';
    }
    if (isComplaintImage &&
        _containsAny(normalized, const [
          'image',
          'صورة',
        ])) {
      return 'أحد الملفات المحددة ليس صورة شكوى صالحة.';
    }
    if (_containsAny(normalized, const [
      'does not exist',
      'exists',
      'not found',
      'غير موجود',
    ])) {
      return '$label المحدد غير موجود.';
    }
    if (_containsAny(normalized, const [
      'email',
      'بريد',
    ])) {
      return 'صيغة البريد الإلكتروني غير صحيحة.';
    }
    if (_containsAny(normalized, const [
      'date',
      'تاريخ',
    ])) {
      return 'قيمة $label ليست تاريخًا صالحًا.';
    }
    if (_containsAny(normalized, const [
      'otp',
      'code',
      'رمز',
    ])) {
      return 'رمز التحقق غير صحيح أو منتهي الصلاحية.';
    }

    return 'تحقق من قيمة $label.';
  }

  static String _fieldLabel(String field) {
    const labels = <String, String>{
      'login': 'البريد الإلكتروني أو رقم الهاتف',
      'email': 'البريد الإلكتروني',
      'phone': 'رقم الهاتف',
      'phone_number': 'رقم الهاتف',
      'password': 'كلمة المرور',
      'password_confirmation': 'تأكيد كلمة المرور',
      'current_password': 'كلمة المرور الحالية',
      'otp': 'رمز التحقق',
      'code': 'رمز التحقق',
      'full_name': 'الاسم الكامل',
      'national_id': 'الرقم الوطني',
      'birth_date': 'تاريخ الميلاد',
      'place_of_birth': 'مكان الولادة',
      'gender': 'الجنس',
      'governorate_id': 'المحافظة',
      'municipality_id': 'البلدية',
      'category_id': 'تصنيف الشكوى',
      'title': 'عنوان الشكوى',
      'description': 'وصف الشكوى',
      'text_location': 'وصف الموقع',
      'latitude': 'خط العرض',
      'longitude': 'خط الطول',
      'images': 'صور الشكوى',
      'images.*': 'صور الشكوى',
      'needs_special_care': 'حالة الرعاية الخاصة',
      'front_id_photo': 'صورة الوجه الأمامي للهوية',
      'back_id_photo': 'صورة الوجه الخلفي للهوية',
      'identity': 'الهوية',
      'citizen': 'حساب المواطن',
    };

    if (field.startsWith('images.')) return labels['images']!;
    return labels[field] ?? 'البيانات المدخلة';
  }

  static bool _containsAny(String value, List<String> markers) {
    return markers.any(value.contains);
  }

  static String? _technicalMessage({
    required Object? responseData,
    required String? serverMessage,
  }) {
    if (responseData != null) return responseData.toString();
    return serverMessage;
  }

  static String _userMessageFor({
    required ApiExceptionKind kind,
    required String path,
    required Map<String, List<String>> errors,
  }) {
    if (kind == ApiExceptionKind.validation && errors.isNotEmpty) {
      return errors.values.first.first;
    }

    final normalizedPath = path.toLowerCase();
    if (kind == ApiExceptionKind.unauthorized &&
        normalizedPath.contains('login')) {
      return 'بيانات تسجيل الدخول غير صحيحة.';
    }
    if (kind == ApiExceptionKind.notFound &&
        normalizedPath.contains('forgot-password')) {
      return 'لم يتم العثور على حساب بهذه البيانات.';
    }

    return _fallbackMessageFor(kind);
  }

  static ApiExceptionKind _kindForStatus(int? statusCode) {
    if (statusCode == 401) return ApiExceptionKind.unauthorized;
    if (statusCode == 403) return ApiExceptionKind.forbidden;
    if (statusCode == 404) return ApiExceptionKind.notFound;
    if (statusCode == 409) return ApiExceptionKind.conflict;
    if (statusCode == 422) return ApiExceptionKind.validation;
    if (statusCode == 429) return ApiExceptionKind.rateLimited;
    if (statusCode != null && statusCode >= 500 && statusCode <= 599) {
      return ApiExceptionKind.server;
    }
    return ApiExceptionKind.unknown;
  }

  static String _fallbackMessageFor(ApiExceptionKind kind) {
    switch (kind) {
      case ApiExceptionKind.unauthorized:
        return 'بيانات الدخول غير صحيحة أو انتهت صلاحية الجلسة.';
      case ApiExceptionKind.forbidden:
        return 'لا تملك صلاحية تنفيذ هذه العملية.';
      case ApiExceptionKind.notFound:
        return 'المورد المطلوب غير موجود.';
      case ApiExceptionKind.conflict:
        return 'تتعارض العملية مع بيانات موجودة مسبقًا.';
      case ApiExceptionKind.validation:
        return 'تحقق من البيانات المدخلة.';
      case ApiExceptionKind.rateLimited:
        return 'تم تجاوز عدد المحاولات المسموح. حاول لاحقًا.';
      case ApiExceptionKind.server:
        return 'حدث خطأ في الخادم. حاول لاحقًا.';
      default:
        return 'تعذر إكمال الطلب.';
    }
  }

  @override
  String toString() {
    final code = statusCode == null ? '' : ', statusCode: $statusCode';
    return 'ApiException(kind: $kind$code, message: $message)';
  }
}
