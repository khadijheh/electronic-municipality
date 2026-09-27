import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stores only the Laravel Sanctum token in platform-protected storage.
class TokenStorage {
  TokenStorage({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const String _tokenKey = 'auth.sanctum_token';
  static const String _requiresPasswordChangeKey =
      'auth.requires_password_change';

  final FlutterSecureStorage _secureStorage;

  Future<String?> readToken() async {
    final token = (await _secureStorage.read(key: _tokenKey))?.trim();
    return token == null || token.isEmpty ? null : token;
  }

  Future<bool> hasToken() async => await readToken() != null;

  Future<void> writeToken(String token) async {
    final normalized = token.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(token, 'token', 'Token must not be empty.');
    }

    await _secureStorage.write(
      key: _tokenKey,
      value: normalized,
    );
  }

  Future<bool> requiresPasswordChange() async {
    return await _secureStorage.read(key: _requiresPasswordChangeKey) == 'true';
  }

  Future<void> writeSession({
    required String token,
    required bool requiresPasswordChange,
  }) async {
    await writeToken(token);
    await _secureStorage.write(
      key: _requiresPasswordChangeKey,
      value: requiresPasswordChange.toString(),
    );
  }

  Future<void> deleteToken() async {
    await Future.wait<void>([
      _secureStorage.delete(key: _tokenKey),
      _secureStorage.delete(key: _requiresPasswordChangeKey),
    ]);
  }
}
