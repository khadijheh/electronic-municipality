import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/repositories/auth_repository.dart';

class CitizenVerificationRemoteDataSource {
  const CitizenVerificationRemoteDataSource(this._client);

  final ApiClient _client;

  Future<void> uploadIdentityPhotos({
    required CitizenIdentityPhoto frontPhoto,
    required CitizenIdentityPhoto backPhoto,
  }) async {
    final envelope = await _client.post(
      ApiEndpoints.uploadIdentityPhotos,
      data: FormData.fromMap(
        <String, dynamic>{
          'front_id_photo': MultipartFile.fromBytes(
            frontPhoto.bytes,
            filename: _safeFileName(frontPhoto.name, fallback: 'front-id.jpg'),
          ),
          'back_id_photo': MultipartFile.fromBytes(
            backPhoto.bytes,
            filename: _safeFileName(backPhoto.name, fallback: 'back-id.jpg'),
          ),
        },
      ),
    );

    if (envelope['success'] == true) return;

    final technicalMessage = envelope['message']?.toString().trim();
    throw ApiException.invalidResponse(
      message: 'تعذر إرسال صور الهوية. حاول مرة أخرى.',
      technicalMessage: technicalMessage == null || technicalMessage.isEmpty
          ? envelope.toString()
          : technicalMessage,
    );
  }

  static String _safeFileName(
    String value, {
    required String fallback,
  }) {
    final normalized = value.trim().replaceAll(RegExp(r'[/\\]'), '_');
    return normalized.isEmpty ? fallback : normalized;
  }
}
