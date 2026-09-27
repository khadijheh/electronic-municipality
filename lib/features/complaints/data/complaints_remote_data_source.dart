import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'complaint_endpoints.dart';
import 'models/complaint_models.dart';

class ComplaintsRemoteDataSource {
  const ComplaintsRemoteDataSource(this._client);

  final ApiClient _client;

  Future<List<ComplaintCategory>> getCategories() async {
    final envelope = await _client.get(ComplaintEndpoints.categories);

    try {
      return _requiredListData(envelope)
          .map(ComplaintCategory.fromJson)
          .where((category) => category.isActive)
          .toList(growable: false);
    } on FormatException catch (error) {
      throw ApiException.invalidResponse(cause: error);
    }
  }

  Future<List<ComplaintReport>> getReports() async {
    final reportsPage = await getReportsPage();
    return reportsPage.items;
  }

  Future<ComplaintReportsPage> getReportsPage({
    int page = 1,
    int perPage = 15,
  }) async {
    if (page < 1 || perPage < 1) {
      throw const ApiException(
        kind: ApiExceptionKind.configuration,
        message: 'إعدادات تحميل سجل الشكاوى غير صالحة.',
      );
    }

    final envelope = await _client.get(
      ComplaintEndpoints.reports,
      queryParameters: <String, dynamic>{
        'page': page,
        'per_page': perPage,
      },
    );

    try {
      final data = _requiredSuccessfulData(envelope);
      final dataMap = _nullableMap(data);
      if (dataMap == null) {
        throw const FormatException('Missing complaint reports page data.');
      }
      return ComplaintReportsPage.fromJson(dataMap);
    } on FormatException catch (error) {
      throw ApiException.invalidResponse(cause: error);
    }
  }

  Future<ComplaintReport> getReport(int reportId) async {
    final envelope = await _client.get(ComplaintEndpoints.report(reportId));
    return _reportFromEnvelope(envelope);
  }

  Future<ComplaintReport> createDraft(ComplaintDraftInput input) async {
    final envelope = await _client.post(
      ComplaintEndpoints.drafts,
      data: input.toJson(),
    );
    return _reportFromEnvelope(envelope);
  }

  Future<ComplaintReport> updateDraft({
    required int reportId,
    required ComplaintDraftInput input,
  }) async {
    final envelope = await _client.patch(
      ComplaintEndpoints.report(reportId),
      data: input.toJson(),
    );
    _validateSuccess(envelope);
    return getReport(reportId);
  }

  Future<void> uploadImages({
    required int reportId,
    required List<ComplaintAttachment> images,
  }) async {
    final formData = FormData();
    for (final image in images) {
      formData.files.add(
        MapEntry(
          'images[]',
          MultipartFile.fromBytes(
            image.bytes,
            filename: _safeFileName(image.name),
          ),
        ),
      );
    }

    final envelope = await _client.post(
      ComplaintEndpoints.images(reportId),
      data: formData,
    );
    _validateSuccess(envelope);
  }

  Future<void> deleteImage({
    required int reportId,
    required int imageId,
  }) async {
    final envelope = await _client.delete(
      ComplaintEndpoints.image(reportId, imageId),
    );
    _validateSuccess(envelope);
  }

  Future<void> deleteDraft(int reportId) async {
    final envelope = await _client.delete(
      ComplaintEndpoints.report(reportId),
    );
    _validateSuccess(envelope);
  }

  Future<ComplaintReport> submitDraft(int reportId) async {
    final envelope = await _client.post(
      ComplaintEndpoints.submit(reportId),
    );
    _validateSuccess(envelope);
    return getReport(reportId);
  }

  static ComplaintReport _reportFromEnvelope(
    Map<String, dynamic> envelope,
  ) {
    try {
      final data = _requiredSuccessfulData(envelope);
      final dataMap = _nullableMap(data);
      if (dataMap == null) {
        throw const FormatException('Missing complaint report data.');
      }
      final nested = _nullableMap(dataMap['report']) ??
          _nullableMap(dataMap['complaint']) ??
          dataMap;
      return ComplaintReport.fromJson(nested);
    } on FormatException catch (error) {
      throw ApiException.invalidResponse(cause: error);
    }
  }

  static List<Map<String, dynamic>> _requiredListData(
    Map<String, dynamic> envelope,
  ) {
    return _requiredMapList(_requiredSuccessfulData(envelope));
  }

  static Object? _requiredSuccessfulData(Map<String, dynamic> envelope) {
    _validateSuccess(envelope);
    if (!envelope.containsKey('data')) {
      throw const FormatException('Missing data in API response.');
    }
    return envelope['data'];
  }

  static List<Map<String, dynamic>> _requiredMapList(Object? value) {
    if (value is! Iterable) {
      throw const FormatException('Expected a list in API response.');
    }

    return value.map((item) {
      final map = _nullableMap(item);
      if (map == null) {
        throw const FormatException('Expected an object in API list.');
      }
      return map;
    }).toList(growable: false);
  }

  static void _validateSuccess(Map<String, dynamic> envelope) {
    if (envelope['success'] == true) return;
    throw ApiException.invalidResponse(
      technicalMessage: envelope.toString(),
    );
  }

  static Map<String, dynamic>? _nullableMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map(
        (key, dynamic item) => MapEntry(key.toString(), item),
      );
    }
    return null;
  }

  static String _safeFileName(String value) {
    final normalized = value.trim().replaceAll(RegExp(r'[/\\]'), '_');
    return normalized.isEmpty ? 'complaint-image.jpg' : normalized;
  }
}
