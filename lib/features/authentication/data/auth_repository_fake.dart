import 'dart:async';

import 'package:electronic_municipality_final/core/repositories/auth_repository.dart';

class AuthRepositoryFake implements AuthRepository {
  AuthRepositoryFake({AuthUser? currentUser}) : _currentUser = currentUser;

  static const developmentOtpCode = '1234';

  final Map<String, String> _otpStore = {};
  AuthUser? _currentUser;

  @override
  AuthUser? get currentUser => _currentUser;

  @override
  Future<List<GovernorateOption>> getGovernorates() async {
    return const [
      GovernorateOption(id: 1, name: 'دمشق'),
      GovernorateOption(id: 2, name: 'ريف دمشق'),
    ];
  }

  @override
  Future<List<MunicipalityOption>> getMunicipalities({
    required int governorateId,
  }) async {
    return [
      MunicipalityOption(
        id: governorateId * 10,
        name: governorateId == 1 ? 'بلدية دمشق' : 'بلدية دوما',
        governorateId: governorateId,
      ),
    ];
  }

  @override
  Future<AuthLoginResult> login({
    required String identifier,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    // Fake: accept any non-empty credentials
    if (identifier.isEmpty || password.isEmpty) {
      throw Exception('Credentials required');
    }
    _currentUser = _fakeCitizen;
    return AuthLoginResult(
      user: _currentUser!,
      requiresPasswordChange: false,
    );
  }

  @override
  Future<AuthUser> registerCitizen({
    required CitizenRegistration registration,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));

    if (registration.phone.trim().isEmpty ||
        registration.email.trim().isEmpty ||
        !registration.acceptedTerms) {
      throw Exception('Invalid registration data');
    }
    // Development fake only. A production repository must send this request
    // over TLS and must never persist the plain-text password locally.
    _currentUser = AuthUser(
      id: 2,
      fullName: registration.fullName,
      email: registration.email,
      phoneNumber: registration.phone,
      roles: const ['citizen'],
      accountType: 'citizen',
      citizenProfile: <String, dynamic>{
        'national_id': registration.nationalId,
        'birth_date': registration.dateOfBirth.toIso8601String(),
        'place_of_birth': registration.placeOfBirth,
        'needs_special_care': registration.needsSpecialCare,
        'is_verified': false,
      },
    );
    return _currentUser!;
  }

  @override
  Future<AuthStartupDestination> restoreSession() async {
    return _currentUser == null
        ? AuthStartupDestination.login
        : AuthStartupDestination.authenticated;
  }

  @override
  Future<AuthUser> getCurrentUser() async {
    _currentUser ??= _fakeCitizen;
    return _currentUser!;
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
  }

  @override
  Future<void> changeTemporaryPassword({
    required String currentPassword,
    required String newPassword,
  }) async {}

  @override
  Future<bool> verifyOtp(
      {required String contact, required String code}) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final expected = _otpStore[contact];
    return expected != null && expected == code;
  }

  @override
  Future<void> requestOtp({required String contact}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Development-only fake. A production repository must issue OTPs server-side.
    _otpStore[contact] = developmentOtpCode;
  }

  @override
  Future<void> resetPassword(
      {required String contact, required String newPassword}) async {
    await Future.delayed(const Duration(milliseconds: 600));
  }

  static const AuthUser _fakeCitizen = AuthUser(
    id: 1,
    fullName: 'مستخدم تجريبي',
    email: 'demo@example.sy',
    phoneNumber: '0990000000',
    roles: ['citizen'],
    accountType: 'citizen',
    citizenProfile: <String, dynamic>{
      'national_id': '00000000000',
      'birth_date': '2000-01-01',
      'place_of_birth': 'دمشق',
      'needs_special_care': false,
      'is_verified': false,
    },
  );
}
