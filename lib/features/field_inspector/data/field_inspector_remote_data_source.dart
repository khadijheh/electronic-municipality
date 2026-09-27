import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import 'models/inspector_document_model.dart';

class FieldInspectorRemoteDataSource {
  FieldInspectorRemoteDataSource(this._client);

  final ApiClient _client;

  /// GET field-inspector/documents/{code}/verify
  Future<InspectorDocumentModel> verifyDocument(String code) async {
    final body = await _client.get(ApiEndpoints.fieldInspectorVerify(code));

    if (body['success'] != true) {
      throw ApiException(
        kind: ApiExceptionKind.unknown,
        message: body['message']?.toString().trim().isNotEmpty == true
            ? body['message'].toString()
            : 'تعذر التحقق من الوثيقة',
      );
    }

    final data = body['data'];
    if (data is Map) {
      return InspectorDocumentModel.fromJson(
        data.map((key, dynamic value) => MapEntry(key.toString(), value)),
      );
    }

    throw ApiException.invalidResponse(
      message: 'استجابة التحقق لا تحتوي بيانات الوثيقة.',
    );
  }

  /// GET field-inspector/documents/{code}/file  ->  يحفظ الملف مؤقتاً ويعيد مساره.
  Future<String> downloadDocument(String code) async {
    final file = await _client.getBytes(ApiEndpoints.fieldInspectorFile(code));

    final directory = await getTemporaryDirectory();
    final safeCode = code.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    final shortCode = safeCode.length > 12 ? safeCode.substring(0, 12) : safeCode;
    final path = '${directory.path}/service_document_$shortCode.pdf';

    await File(path).writeAsBytes(file.bytes, flush: true);
    return path;
  }
}
