import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/repositories/auth_repository.dart';
import 'models/auth_session_model.dart';
import 'models/auth_user_model.dart';

/// Exact request contract required by Laravel's `RegisterCitizenRequest`.
class CitizenRegistrationApiRequest {
  const CitizenRegistrationApiRequest({
    required this.fullName,
    required this.phoneNumber,
    required this.email,
    required this.password,
    required this.municipalityId,
    required this.gender,
    required this.birthDate,
    required this.nationalId,
    required this.placeOfBirth,
    required this.needsSpecialCare,
  });

  factory CitizenRegistrationApiRequest.fromDomain(
    CitizenRegistration registration,
  ) {
    return CitizenRegistrationApiRequest(
      fullName: registration.fullName,
      phoneNumber: registration.phone,
      email: registration.email,
      password: registration.password,
      municipalityId: registration.municipalityId,
      gender: registration.gender,
      birthDate: registration.dateOfBirth,
      nationalId: registration.nationalId,
      placeOfBirth: registration.placeOfBirth,
      needsSpecialCare: registration.needsSpecialCare,
    );
  }

  final String fullName;
  final String phoneNumber;
  final String email;
  final String password;
  final int municipalityId;
  final CitizenGender gender;
  final DateTime birthDate;
  final String nationalId;
  final String placeOfBirth;
  final bool needsSpecialCare;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'full_name': fullName.trim(),
      'phone_number': phoneNumber.trim(),
      'email': email.trim(),
      'password': password,
      'password_confirmation': password,
      'municipality_id': municipalityId,
      'gender': gender == CitizenGender.male ? 'Male' : 'Female',
      'birth_date': _dateOnly(birthDate),
      'national_id': nationalId.trim(),
      'place_of_birth': placeOfBirth.trim(),
      'needs_special_care': needsSpecialCare,
    };
  }

  static String _dateOnly(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}

class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._client);

  final ApiClient _client;

  Future<AuthSessionModel> login({
    required String identifier,
    required String password,
  }) async {
    final envelope = await _client.post(
      ApiEndpoints.login,
      requiresAuth: false,
      data: <String, dynamic>{
        'login': identifier.trim(),
        'password': password,
        'device_name': ApiConfig.deviceName,
      },
    );

    return _sessionFromEnvelope(envelope);
  }

  Future<AuthSessionModel> registerCitizen(
    CitizenRegistrationApiRequest request,
  ) async {
    final envelope = await _client.post(
      ApiEndpoints.registerCitizen,
      requiresAuth: false,
      data: request.toJson(),
    );

    return _sessionFromEnvelope(envelope);
  }

  Future<List<GovernorateOption>> getGovernorates() async {
    final envelope = await _client.get(
      ApiEndpoints.governorates,
      requiresAuth: false,
    );

    try {
      return _requiredListData(envelope)
          .map(
            (item) => GovernorateOption(
              id: _requiredInt(item, 'id'),
              name: _requiredString(item, 'name'),
            ),
          )
          .toList(growable: false);
    } on FormatException catch (error) {
      throw ApiException.invalidResponse(cause: error);
    }
  }

  Future<List<MunicipalityOption>> getMunicipalities({
    required int governorateId,
  }) async {
    final envelope = await _client.get(
      ApiEndpoints.municipalitiesByGovernorate(governorateId),
      requiresAuth: false,
    );

    try {
      return _requiredListData(envelope)
          .map(
            (item) => MunicipalityOption(
              id: _requiredInt(item, 'id'),
              name: _requiredString(item, 'name'),
              governorateId: _requiredInt(item, 'governorate_id'),
            ),
          )
          .toList(growable: false);
    } on FormatException catch (error) {
      throw ApiException.invalidResponse(cause: error);
    }
  }

  Future<void> requestPasswordReset({required String email}) async {
    final envelope = await _client.post(
      ApiEndpoints.forgotPassword,
      requiresAuth: false,
      data: <String, dynamic>{'email': email.trim()},
    );
    _validateSuccess(envelope);
  }

  Future<void> verifyResetOtp({
    required String email,
    required String otp,
  }) async {
    final envelope = await _client.post(
      ApiEndpoints.verifyResetOtp,
      requiresAuth: false,
      data: <String, dynamic>{
        'email': email.trim(),
        'otp': otp.trim(),
      },
    );
    _validateSuccess(envelope);
  }

  Future<void> resetPassword({
    required String email,
    required String password,
  }) async {
    final envelope = await _client.post(
      ApiEndpoints.resetPassword,
      requiresAuth: false,
      data: <String, dynamic>{
        'email': email.trim(),
        'password': password,
        'password_confirmation': password,
      },
    );
    _validateSuccess(envelope);
  }

  Future<AuthUserModel> fetchCurrentUser() async {
    final envelope = await _client.get(ApiEndpoints.me);
    final data = _requiredData(envelope);
    final user = _nullableMap(data['user']);

    if (user == null) {
      throw ApiException.invalidResponse(
        message: 'لم تتضمن استجابة الخادم بيانات المستخدم.',
      );
    }

    try {
      return AuthUserModel.fromJson(user);
    } on FormatException catch (error) {
      throw ApiException.invalidResponse(cause: error);
    }
  }

  Future<void> logout() async {
    final envelope = await _client.post(ApiEndpoints.logout);
    _validateSuccess(envelope);
  }

  Future<void> changeTemporaryPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final envelope = await _client.post(
      ApiEndpoints.changeTemporaryPassword,
      data: <String, dynamic>{
        'current_password': currentPassword,
        'password': newPassword,
        'password_confirmation': newPassword,
      },
    );
    _validateSuccess(envelope);
  }

  static AuthSessionModel _sessionFromEnvelope(
    Map<String, dynamic> envelope,
  ) {
    final data = _requiredData(envelope);
    try {
      return AuthSessionModel.fromJson(data);
    } on FormatException catch (error) {
      throw ApiException.invalidResponse(cause: error);
    }
  }

  static Map<String, dynamic> _requiredData(
    Map<String, dynamic> envelope,
  ) {
    _validateSuccess(envelope);
    final data = _nullableMap(envelope['data']);
    if (data == null) {
      throw ApiException.invalidResponse(
        message: 'لم تتضمن استجابة الخادم حقل data صالحًا.',
      );
    }
    return data;
  }

  static List<Map<String, dynamic>> _requiredListData(
    Map<String, dynamic> envelope,
  ) {
    _validateSuccess(envelope);
    final data = envelope['data'];
    if (data is! Iterable) {
      throw ApiException.invalidResponse(
        message: 'لم تتضمن استجابة الخادم قائمة بيانات صالحة.',
      );
    }

    try {
      return data.map((item) {
        final map = _nullableMap(item);
        if (map == null) {
          throw const FormatException('Invalid list item.');
        }
        return map;
      }).toList(growable: false);
    } on FormatException catch (error) {
      throw ApiException.invalidResponse(cause: error);
    }
  }

  static void _validateSuccess(Map<String, dynamic> envelope) {
    if (envelope['success'] == true) return;

    final message = envelope['message']?.toString().trim();
    throw ApiException.invalidResponse(
      message: 'تعذر التحقق من استجابة الخادم.',
      technicalMessage:
          message == null || message.isEmpty ? envelope.toString() : message,
    );
  }

  static Map<String, dynamic>? _nullableMap(Object? value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map(
        (key, dynamic item) => MapEntry(key.toString(), item),
      );
    }
    return null;
  }

  static int _requiredInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is int) return value;
    if (value is num) return value.toInt();

    final parsed = int.tryParse(value?.toString() ?? '');
    if (parsed != null) return parsed;
    throw FormatException('Missing or invalid "$key".');
  }

  static String _requiredString(
    Map<String, dynamic> json,
    String key,
  ) {
    final value = json[key]?.toString().trim();
    if (value != null && value.isNotEmpty) return value;
    throw FormatException('Missing or invalid "$key".');
  }
}
