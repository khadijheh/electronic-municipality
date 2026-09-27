import '../../../core/network/api_exception.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/storage/token_storage.dart';
import 'auth_remote_data_source.dart';
import 'models/auth_session_model.dart';
import 'models/auth_user_model.dart';

/// API-backed implementation of the authentication contract.
class AuthRepositoryApi implements AuthRepository {
  AuthRepositoryApi({
    required AuthRemoteDataSource remoteDataSource,
    required TokenStorage tokenStorage,
  })  : _remoteDataSource = remoteDataSource,
        _tokenStorage = tokenStorage;

  final AuthRemoteDataSource _remoteDataSource;
  final TokenStorage _tokenStorage;

  AuthUserModel? _currentUser;

  @override
  AuthUserModel? get currentUser => _currentUser;

  @override
  Future<AuthLoginResult> login({
    required String identifier,
    required String password,
  }) async {
    final session = await loginWithIdentifier(
      identifier: _requireIdentifier(identifier),
      password: password,
    );
    return AuthLoginResult(
      user: session.user,
      requiresPasswordChange: session.requiresPasswordChange,
    );
  }

  Future<AuthSessionModel> loginWithIdentifier({
    required String identifier,
    required String password,
  }) async {
    final session = await _remoteDataSource.login(
      identifier: _requireIdentifier(identifier),
      password: password,
    );
    await _persistSession(session);
    return session;
  }

  @override
  Future<AuthUser> registerCitizen({
    required CitizenRegistration registration,
  }) async {
    final session = await registerCitizenWithRequest(
      CitizenRegistrationApiRequest.fromDomain(registration),
    );
    return session.user;
  }

  Future<AuthSessionModel> registerCitizenWithRequest(
    CitizenRegistrationApiRequest request,
  ) async {
    final session = await _remoteDataSource.registerCitizen(request);
    await _persistSession(session);
    return session;
  }

  @override
  Future<List<GovernorateOption>> getGovernorates() {
    return _remoteDataSource.getGovernorates();
  }

  @override
  Future<List<MunicipalityOption>> getMunicipalities({
    required int governorateId,
  }) {
    return _remoteDataSource.getMunicipalities(
      governorateId: governorateId,
    );
  }

  @override
  Future<void> requestOtp({required String contact}) {
    return requestPasswordReset(email: contact);
  }

  Future<void> requestPasswordReset({required String email}) {
    final normalizedEmail = _requireEmail(email);
    return _remoteDataSource.requestPasswordReset(
      email: normalizedEmail,
    );
  }

  @override
  Future<bool> verifyOtp({
    required String contact,
    required String code,
  }) async {
    final email = _requireEmail(contact);

    await _remoteDataSource.verifyResetOtp(
      email: email,
      otp: code,
    );
    return true;
  }

  @override
  Future<void> resetPassword({
    required String contact,
    required String newPassword,
  }) async {
    final email = _requireEmail(contact);

    await _remoteDataSource.resetPassword(
      email: email,
      password: newPassword,
    );
    await clearLocalSession();
  }

  @override
  Future<AuthStartupDestination> restoreSession() async {
    if (!await _tokenStorage.hasToken()) {
      return AuthStartupDestination.login;
    }

    if (await _tokenStorage.requiresPasswordChange()) {
      return AuthStartupDestination.changeTemporaryPassword;
    }

    try {
      await getCurrentUser();
      return AuthStartupDestination.authenticated;
    } on ApiException catch (error) {
      if (error.isUnauthorized) {
        await clearLocalSession();
        return AuthStartupDestination.login;
      }
      rethrow;
    }
  }

  @override
  Future<AuthUserModel> getCurrentUser() async {
    final user = await _remoteDataSource.fetchCurrentUser();
    _currentUser = user;
    return user;
  }

  @override
  Future<void> logout() async {
    try {
      if (await _tokenStorage.hasToken()) {
        await _remoteDataSource.logout();
      }
    } finally {
      await clearLocalSession();
    }
  }

  @override
  Future<void> changeTemporaryPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _remoteDataSource.changeTemporaryPassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    await clearLocalSession();
  }

  Future<void> clearLocalSession() async {
    await _tokenStorage.deleteToken();
    _currentUser = null;
  }

  Future<void> _persistSession(AuthSessionModel session) async {
    await _tokenStorage.writeSession(
      token: session.token,
      requiresPasswordChange: session.requiresPasswordChange,
    );
    _currentUser = session.user;
  }

  static String _requireIdentifier(String value) {
    final identifier = value.trim();
    if (identifier.isEmpty) {
      throw ApiException.validation(
        message: 'رقم الهاتف أو البريد الإلكتروني مطلوب.',
        errors: const {
          'login': ['رقم الهاتف أو البريد الإلكتروني مطلوب.'],
        },
      );
    }
    return identifier;
  }

  static String _requireEmail(String value) {
    final email = value.trim().toLowerCase();
    final isValid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    if (!isValid) {
      throw ApiException.validation(
        message: 'البريد الإلكتروني مطلوب وبصيغة صحيحة.',
        errors: const {
          'email': ['البريد الإلكتروني مطلوب وبصيغة صحيحة.'],
        },
      );
    }
    return email;
  }
}
