import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:electronic_municipality_final/core/network/api_exception.dart';
import 'package:electronic_municipality_final/core/repositories/auth_repository.dart';
import 'package:electronic_municipality_final/features/authentication/data/auth_remote_data_source.dart';
import 'package:electronic_municipality_final/features/authentication/data/models/auth_session_model.dart';

void main() {
  group('AuthSessionModel', () {
    test('parses the Laravel login payload', () {
      final session = AuthSessionModel.fromJson(
        <String, dynamic>{
          'token': '1|sanctum-token',
          'requires_password_change': false,
          'user': <String, dynamic>{
            'id': 7,
            'full_name': 'مالك الشحرور',
            'phone_number': '0991234567',
            'email': 'malik@example.sy',
            'roles': <String>['citizen'],
            'account_type': 'citizen',
            'citizen_profile': <String, dynamic>{
              'is_verified': false,
            },
            'employee_profile': null,
          },
        },
      );

      expect(session.token, '1|sanctum-token');
      expect(session.requiresPasswordChange, isFalse);
      expect(session.user.id, 7);
      expect(session.user.displayName, 'مالك الشحرور');
      expect(session.user.isCitizen, isTrue);
      expect(session.user.isCitizenVerified, isFalse);
    });

    test('rejects a payload without a token', () {
      expect(
        () => AuthSessionModel.fromJson(
          <String, dynamic>{
            'user': <String, dynamic>{},
          },
        ),
        throwsFormatException,
      );
    });
  });

  test('citizen registration matches the Laravel field names', () {
    final registration = CitizenRegistration(
      fullName: 'مالك الشحرور',
      nationalId: '01234567890',
      dateOfBirth: DateTime(2001, 2, 3),
      placeOfBirth: 'دمشق',
      municipalityId: 12,
      gender: CitizenGender.male,
      phone: '0991234567',
      email: 'malik@example.sy',
      password: 'Password123',
      needsSpecialCare: true,
      acceptedTerms: true,
    );
    final request = CitizenRegistrationApiRequest.fromDomain(registration);

    expect(
      request.toJson(),
      <String, dynamic>{
        'full_name': 'مالك الشحرور',
        'phone_number': '0991234567',
        'email': 'malik@example.sy',
        'password': 'Password123',
        'password_confirmation': 'Password123',
        'municipality_id': 12,
        'gender': 'Male',
        'birth_date': '2001-02-03',
        'national_id': '01234567890',
        'place_of_birth': 'دمشق',
        'needs_special_care': true,
      },
    );
  });

  test('maps Laravel validation errors to field errors', () {
    final requestOptions = RequestOptions(path: 'auth/login');
    final dioError = DioException(
      requestOptions: requestOptions,
      response: Response<Map<String, dynamic>>(
        requestOptions: requestOptions,
        statusCode: 422,
        data: <String, dynamic>{
          'message': 'The given data was invalid.',
          'errors': <String, dynamic>{
            'login': <String>['The login field is required.'],
          },
        },
      ),
      type: DioExceptionType.badResponse,
    );

    final error = ApiException.fromDioException(dioError);

    expect(error.kind, ApiExceptionKind.validation);
    expect(error.statusCode, 422);
    expect(error.message, 'حقل البريد الإلكتروني أو رقم الهاتف مطلوب.');
    expect(
      error.errorFor('login'),
      'حقل البريد الإلكتروني أو رقم الهاتف مطلوب.',
    );
    expect(error.technicalMessage, contains('The login field is required.'));
  });

  test('does not expose Laravel SQL errors to the user', () {
    final requestOptions = RequestOptions(
      path: 'public/governorates/1/municipalities',
    );
    final dioError = DioException(
      requestOptions: requestOptions,
      response: Response<Map<String, dynamic>>(
        requestOptions: requestOptions,
        statusCode: 500,
        data: <String, dynamic>{
          'message': "SQLSTATE[42S22]: Column not found: 1054 Unknown column "
              "'governorate_id' in 'field list'",
        },
      ),
      type: DioExceptionType.badResponse,
    );

    final error = ApiException.fromDioException(dioError);

    expect(error.kind, ApiExceptionKind.server);
    expect(error.message, 'حدث خطأ في الخادم. حاول لاحقًا.');
    expect(error.message, isNot(contains('SQLSTATE')));
    expect(error.technicalMessage, contains('SQLSTATE'));
    expect(error.cause, same(dioError));
  });

  test('uses local messages for every HTTP error category', () {
    final cases = <int, String>{
      401: 'بيانات تسجيل الدخول غير صحيحة.',
      403: 'لا تملك صلاحية تنفيذ هذه العملية.',
      404: 'المورد المطلوب غير موجود.',
      409: 'تتعارض العملية مع بيانات موجودة مسبقًا.',
      429: 'تم تجاوز عدد المحاولات المسموح. حاول لاحقًا.',
      500: 'حدث خطأ في الخادم. حاول لاحقًا.',
    };

    for (final entry in cases.entries) {
      final requestOptions = RequestOptions(path: 'auth/login');
      final dioError = DioException(
        requestOptions: requestOptions,
        response: Response<Map<String, dynamic>>(
          requestOptions: requestOptions,
          statusCode: entry.key,
          data: <String, dynamic>{
            'message': 'RAW BACKEND MESSAGE ${entry.key}',
          },
        ),
        type: DioExceptionType.badResponse,
      );

      final error = ApiException.fromDioException(dioError);

      expect(error.message, entry.value);
      expect(error.message, isNot(contains('RAW BACKEND MESSAGE')));
      expect(error.technicalMessage, contains('RAW BACKEND MESSAGE'));
    }
  });

  test('maps duplicate validation errors without exposing backend wording', () {
    final requestOptions = RequestOptions(path: 'auth/register-citizen');
    final dioError = DioException(
      requestOptions: requestOptions,
      response: Response<Map<String, dynamic>>(
        requestOptions: requestOptions,
        statusCode: 422,
        data: <String, dynamic>{
          'message': 'The given data was invalid.',
          'errors': <String, dynamic>{
            'phone_number': <String>[
              'The phone number has already been taken.',
            ],
          },
        },
      ),
      type: DioExceptionType.badResponse,
    );

    final error = ApiException.fromDioException(dioError);

    expect(error.message, 'رقم الهاتف مستخدم مسبقًا.');
    expect(error.errorFor('phone_number'), 'رقم الهاتف مستخدم مسبقًا.');
    expect(error.message, isNot(contains('already been taken')));
    expect(error.technicalMessage, contains('already been taken'));
  });
}
