import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../complaints/data/complaint_endpoints.dart';
import '../domain/unified_complaints_map_repository.dart';

class UnifiedComplaintsMapRepositoryApi
    implements UnifiedComplaintsMapRepository {
  UnifiedComplaintsMapRepositoryApi({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<UnifiedComplaintsMapPage> getPage({
    int page = 1,
    int perPage = 50,
  }) async {
    if (page < 1 || perPage < 1 || perPage > 50) {
      throw ApiException.invalidResponse(
        message: 'إعدادات تحميل خريطة الشكاوى غير صالحة.',
      );
    }

    final response = await _apiClient.get(
      ComplaintEndpoints.unifiedComplaints,
      queryParameters: <String, dynamic>{
        'page': page,
        'per_page': perPage,
      },
    );
    final data = _readData(response);
    final rawItems = _readList(data['items'], field: 'items');
    final pagination = _readMap(data['pagination'], field: 'pagination');

    final items = rawItems
        .map(UnifiedComplaintMapItemParser.fromJson)
        .where((item) => item.hasValidCoordinates)
        .toList(growable: false);

    return UnifiedComplaintsMapPage(
      items: items,
      currentPage: _positiveInt(pagination['current_page'], field: 'current_page'),
      lastPage: _positiveInt(pagination['last_page'], field: 'last_page'),
      total: _nonNegativeInt(pagination['total'], field: 'total'),
    );
  }

  @override
  Future<List<UnifiedComplaintMapItem>> getAllForMap({
    int perPage = 50,
  }) async {
    final items = <UnifiedComplaintMapItem>[];
    var page = 1;
    var previousPage = 0;

    while (true) {
      final result = await getPage(page: page, perPage: perPage);
      items.addAll(result.items);

      if (!result.hasNextPage || result.currentPage <= previousPage) break;
      previousPage = result.currentPage;
      page = result.currentPage + 1;
    }

    return List<UnifiedComplaintMapItem>.unmodifiable(items);
  }

  Map<String, dynamic> _readData(Map<String, dynamic> response) {
    if (response['success'] != true) {
      throw ApiException.invalidResponse(
        message: 'أعاد الخادم استجابة شكاوى موحدة غير صالحة.',
      );
    }
    return _readMap(response['data'], field: 'data');
  }

  Map<String, dynamic> _readMap(Object? value, {required String field}) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map(
        (key, dynamic item) => MapEntry(key.toString(), item),
      );
    }
    throw ApiException.invalidResponse(
      message: 'لم تتضمن استجابة الخادم حقل $field صالحًا.',
    );
  }

  List<Map<String, dynamic>> _readList(Object? value, {required String field}) {
    if (value is! List) {
      throw ApiException.invalidResponse(
        message: 'لم تتضمن استجابة الخادم قائمة $field صالحة.',
      );
    }
    return value.map((item) => _readMap(item, field: field)).toList();
  }

  int _positiveInt(Object? value, {required String field}) {
    final parsed = _parseInt(value);
    if (parsed == null || parsed < 1) {
      throw ApiException.invalidResponse(
        message: 'حقل $field في استجابة الخادم غير صالح.',
      );
    }
    return parsed;
  }

  int _nonNegativeInt(Object? value, {required String field}) {
    final parsed = _parseInt(value);
    if (parsed == null || parsed < 0) {
      throw ApiException.invalidResponse(
        message: 'حقل $field في استجابة الخادم غير صالح.',
      );
    }
    return parsed;
  }

  int? _parseInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}

abstract final class UnifiedComplaintMapItemParser {
  static UnifiedComplaintMapItem fromJson(Map<String, dynamic> json) {
    final status = _asMap(json['current_status']);
    final category = _asMap(json['category']);
    final municipality = _asMap(json['municipality']);

    return UnifiedComplaintMapItem(
      id: _int(json['id']) ?? 0,
      latitude: _double(json['latitude']) ?? double.nan,
      longitude: _double(json['longitude']) ?? double.nan,
      statusKey: _string(status?['key']) ?? 'unknown',
      statusName: _string(status?['name']) ?? 'غير محددة',
      title: _string(json['title']),
      canonicalDescription: _string(json['canonical_description']),
      locationDescription: _string(json['text_location']),
      categoryName: _string(category?['name']),
      municipalityName: _string(municipality?['name']),
      updatedAt: _date(json['updated_at']),
    );
  }

  static Map<String, dynamic>? _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map(
        (key, dynamic item) => MapEntry(key.toString(), item),
      );
    }
    return null;
  }

  static String? _string(Object? value) {
    final result = value?.toString().trim();
    return result == null || result.isEmpty ? null : result;
  }

  static int? _int(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static double? _double(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static DateTime? _date(Object? value) =>
      DateTime.tryParse(value?.toString() ?? '')?.toLocal();
}
