abstract final class ApiEndpoints {
  // Authentication
  static const String login = 'auth/login';
  static const String registerCitizen = 'auth/register-citizen';
  static const String forgotPassword = 'auth/forgot-password';
  static const String verifyResetOtp = 'auth/verify-reset-otp';
  static const String resetPassword = 'auth/reset-password';
  static const String changeTemporaryPassword =
      'auth/change-temporary-password';
  static const String logout = 'auth/logout';
  static const String me = 'auth/me';

  // Public reference data
  static const String governorates = 'public/governorates';

  static String municipalitiesByGovernorate(int governorateId) {
    return 'public/governorates/$governorateId/municipalities';
  }

  // Citizen
  static const String uploadIdentityPhotos = 'citizen/identity-photos';

  // Field inspector
  static String fieldInspectorVerify(String verificationCode) {
    return 'field-inspector/documents/${Uri.encodeComponent(verificationCode)}/verify';
  }

  static String fieldInspectorFile(String verificationCode) {
    return 'field-inspector/documents/${Uri.encodeComponent(verificationCode)}/file';
  }
}
