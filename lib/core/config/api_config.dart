/// Central configuration for the Laravel API.
///
/// Never place private keys or server secrets in this class. The API URL is a
/// public runtime value and can be supplied with:
///
/// `--dart-define=API_BASE_URL=https://example.com/api`
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api',
  );

  static const String deviceName = String.fromEnvironment(
    'API_DEVICE_NAME',
    defaultValue: 'electronic-municipality-app',
  );

  static const bool allowInsecureHttp = bool.fromEnvironment(
    'ALLOW_INSECURE_HTTP',
    defaultValue: false,
  );

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration sendTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  static const bool _isRelease = bool.fromEnvironment('dart.vm.product');

  /// Returns a validated URL ending with `/`, which lets Dio resolve relative
  /// endpoint paths without dropping the `/api` segment.
  static String get normalizedBaseUrl {
    final value = baseUrl.trim();
    final uri = Uri.tryParse(value);

    if (value.isEmpty ||
        uri == null ||
        !uri.hasScheme ||
        uri.host.isEmpty ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw StateError(
        'API_BASE_URL must be a valid absolute HTTP(S) URL.',
      );
    }

    if (_isRelease && uri.scheme != 'https' && !allowInsecureHttp) {
      throw StateError(
        'Release builds require HTTPS. Set ALLOW_INSECURE_HTTP=true only '
        'for an explicitly approved development environment.',
      );
    }

    final normalizedPath = uri.path.endsWith('/') ? uri.path : '${uri.path}/';

    return uri
        .replace(path: normalizedPath, query: null, fragment: null)
        .toString();
  }

  /// Resolves backend-generated asset URLs against the configured API host.
  ///
  /// Laravel commonly emits `http://localhost/storage/...` in development.
  /// On a physical phone, `localhost` points to the phone itself, so local
  /// hosts are replaced with the host and port from [baseUrl].
  static String resolveServerUrl(String value) {
    var normalized = value.trim();
    final markdownLink = RegExp(r'^\[[^\]]+\]\(([^)]+)\)$')
        .firstMatch(normalized);
    if (markdownLink != null) {
      normalized = markdownLink.group(1)!.trim();
    }

    final origin = Uri.parse(normalizedBaseUrl).replace(
      path: '/',
      query: null,
      fragment: null,
    );
    final uri = Uri.tryParse(normalized);
    if (uri == null) return normalized;

    if (!uri.hasScheme || uri.host.isEmpty) {
      return origin.resolveUri(uri).toString();
    }

    const localHosts = <String>{'localhost', '127.0.0.1', '10.0.2.2'};
    if (localHosts.contains(uri.host.toLowerCase())) {
      return origin
          .replace(
            path: uri.path,
            query: uri.hasQuery ? uri.query : null,
            fragment: uri.hasFragment ? uri.fragment : null,
          )
          .toString();
    }

    return uri.toString();
  }
}
