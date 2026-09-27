import 'dart:typed_data';

enum CitizenGender { male, female }

enum AuthStartupDestination {
  login,
  authenticated,
  changeTemporaryPassword,
}

enum CitizenVerificationStatus {
  notSubmitted,
  pending,
  verified,
}

class AuthUser {
  const AuthUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.roles,
    required this.accountType,
    this.citizenProfile,
    this.employeeProfile,
  });

  final int id;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final List<String> roles;
  final String accountType;
  final Map<String, dynamic>? citizenProfile;
  final Map<String, dynamic>? employeeProfile;

  bool get isCitizen => accountType == 'citizen';
  bool get isEmployee => accountType == 'employee';
  bool get isFieldInspector => roles.contains('field_inspector');

  String get displayName => fullName;

  bool? get isCitizenVerified {
    final value = citizenProfile?['is_verified'];
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      return value == '1' || value.toLowerCase() == 'true';
    }
    return null;
  }

  CitizenVerificationStatus get citizenVerificationStatus {
    if (isCitizenVerified == true) {
      return CitizenVerificationStatus.verified;
    }

    final hasFrontPhoto = _hasValue(citizenProfile?['front_id_photo']);
    final hasBackPhoto = _hasValue(citizenProfile?['back_id_photo']);
    if (hasFrontPhoto && hasBackPhoto) {
      return CitizenVerificationStatus.pending;
    }

    return CitizenVerificationStatus.notSubmitted;
  }

  static bool _hasValue(Object? value) {
    return value != null && value.toString().trim().isNotEmpty;
  }
}

class CitizenIdentityPhoto {
  const CitizenIdentityPhoto({
    required this.name,
    required this.bytes,
  });

  final String name;
  final Uint8List bytes;

  int get sizeInBytes => bytes.lengthInBytes;
}

abstract class CitizenVerificationRepository {
  Future<void> uploadIdentityPhotos({
    required CitizenIdentityPhoto frontPhoto,
    required CitizenIdentityPhoto backPhoto,
  });
}

class AuthLoginResult {
  const AuthLoginResult({
    required this.user,
    required this.requiresPasswordChange,
  });

  final AuthUser user;
  final bool requiresPasswordChange;
}

class GovernorateOption {
  const GovernorateOption({
    required this.id,
    required this.name,
  });

  final int id;
  final String name;
}

class MunicipalityOption {
  const MunicipalityOption({
    required this.id,
    required this.name,
    required this.governorateId,
  });

  final int id;
  final String name;
  final int governorateId;
}

class CitizenRegistration {
  const CitizenRegistration({
    required this.fullName,
    required this.nationalId,
    required this.dateOfBirth,
    required this.placeOfBirth,
    required this.municipalityId,
    required this.gender,
    required this.phone,
    required this.email,
    required this.password,
    required this.needsSpecialCare,
    required this.acceptedTerms,
  });

  final String fullName;
  final String nationalId;
  final DateTime dateOfBirth;
  final String placeOfBirth;
  final int municipalityId;
  final CitizenGender gender;
  final String phone;
  final String email;
  final String password;
  final bool needsSpecialCare;
  final bool acceptedTerms;
}

abstract class AuthRepository {
  AuthUser? get currentUser;

  /// Perform login using phone/email and password.
  Future<AuthLoginResult> login({
    required String identifier,
    required String password,
  });

  /// Create a citizen account using the fields required by Laravel.
  Future<AuthUser> registerCitizen({
    required CitizenRegistration registration,
  });

  /// Restore an existing Sanctum session during application startup.
  Future<AuthStartupDestination> restoreSession();

  /// Load the authenticated user's latest profile from Laravel.
  Future<AuthUser> getCurrentUser();

  /// Revoke the current Sanctum token and clear local session state.
  Future<void> logout();

  /// Replace an employee's temporary password, then clear the one-time token.
  Future<void> changeTemporaryPassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Load governorates used by citizen registration.
  Future<List<GovernorateOption>> getGovernorates();

  /// Load the active municipalities for a governorate.
  Future<List<MunicipalityOption>> getMunicipalities({
    required int governorateId,
  });

  /// Request a password-reset OTP to be sent to the given email.
  Future<void> requestOtp({required String contact});

  /// Verify a password-reset OTP for the given email.
  Future<bool> verifyOtp({required String contact, required String code});

  /// Reset the password for the verified email.
  Future<void> resetPassword(
      {required String contact, required String newPassword});
}
