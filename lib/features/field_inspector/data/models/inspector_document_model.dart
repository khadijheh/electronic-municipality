/// نتيجة التحقق من وثيقة خدمة عبر رمز QR.
///
/// الحقول مطابقة لاستجابة:
/// GET /api/field-inspector/documents/{code}/verify  ->  { success, message, data }
class InspectorDocumentModel {
  const InspectorDocumentModel({
    required this.isValid,
    required this.fileExists,
    required this.isSigned,
    required this.isHashValid,
    required this.isSignatureValid,
    this.isExpired,
    this.documentNumber,
    this.citizenName,
    this.serviceName,
    this.municipality,
    this.issuedAt,
    this.expiresAt,
  });

  factory InspectorDocumentModel.fromJson(Map<String, dynamic> json) {
    return InspectorDocumentModel(
      isValid: _bool(json['is_valid']) ?? false,
      fileExists: _bool(json['file_exists']) ?? false,
      isSigned: _bool(json['is_signed']) ?? false,
      isHashValid: _bool(json['is_hash_valid']) ?? false,
      isSignatureValid: _bool(json['is_signature_valid']) ?? false,
      isExpired: _bool(json['is_expired']),
      documentNumber: _string(json['document_number']),
      citizenName: _string(json['citizen_name']),
      serviceName: _string(json['service_name']),
      municipality: _string(json['municipality']),
      issuedAt: _string(json['issued_at']),
      expiresAt: _string(json['expires_at']),
    );
  }

  final bool isValid;
  final bool fileExists;
  final bool isSigned;
  final bool isHashValid;
  final bool isSignatureValid;

  /// null = غير معروف. الويب يعتبر الوثيقة "غير منتهية" فقط عندما تكون false.
  final bool? isExpired;

  final String? documentNumber;
  final String? citizenName;
  final String? serviceName;
  final String? municipality;
  final String? issuedAt;
  final String? expiresAt;

  bool get isNotExpired => isExpired == false;

  static bool? _bool(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final v = value.trim().toLowerCase();
      if (v == 'true' || v == '1') return true;
      if (v == 'false' || v == '0') return false;
    }
    return null;
  }

  static String? _string(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }
}

/// يستخرج verification_code من نص الـ QR. (نفس منطق الويب)
///
/// يدعم: كود فقط، أو رابط ينتهي بالكود، أو رابط ينتهي بـ /verify.
String extractVerificationCode(String? decodedText) {
  final value = decodedText?.trim() ?? '';
  if (value.isEmpty) return '';

  final uri = Uri.tryParse(value);
  if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
    final parts = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (parts.isNotEmpty) {
      // .../documents/{code}/verify  ->  نأخذ الكود وليس كلمة verify/file
      final last = parts.last.toLowerCase();
      if ((last == 'verify' || last == 'file') && parts.length >= 2) {
        return parts[parts.length - 2];
      }
      return parts.last;
    }
  }
  return value;
}

/// تنسيق تاريخ بسيط yyyy/MM/dd دون الحاجة لحزمة intl.
String formatInspectorDate(String? raw) {
  if (raw == null || raw.isEmpty) return '-';
  final date = DateTime.tryParse(raw);
  if (date == null) return raw;
  final local = date.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${local.year}/${two(local.month)}/${two(local.day)}';
}
