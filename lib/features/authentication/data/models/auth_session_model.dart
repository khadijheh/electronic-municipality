import 'auth_user_model.dart';

class AuthSessionModel {
  const AuthSessionModel({
    required this.token,
    required this.user,
    required this.requiresPasswordChange,
  });

  factory AuthSessionModel.fromJson(Map<String, dynamic> json) {
    final token = json['token']?.toString().trim() ?? '';
    final rawUser = json['user'];

    if (token.isEmpty) {
      throw const FormatException('Missing token in authentication payload.');
    }

    if (rawUser is! Map) {
      throw const FormatException('Missing user in authentication payload.');
    }

    final userJson = rawUser is Map<String, dynamic>
        ? rawUser
        : rawUser.map(
            (key, dynamic value) => MapEntry(key.toString(), value),
          );

    return AuthSessionModel(
      token: token,
      user: AuthUserModel.fromJson(userJson),
      requiresPasswordChange:
          _readBool(json['requires_password_change']) ?? false,
    );
  }

  final String token;
  final AuthUserModel user;
  final bool requiresPasswordChange;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'token': token,
      'user': user.toJson(),
      'requires_password_change': requiresPasswordChange,
    };
  }

  static bool? _readBool(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1') return true;
      if (normalized == 'false' || normalized == '0') return false;
    }
    return null;
  }
}
