import 'dart:typed_data';

import '../../../../core/config/api_config.dart';
import '../../../../core/network/api_exception.dart';

class ComplaintCategory {
  const ComplaintCategory({
    required this.id,
    required this.name,
    this.parentId,
    this.key,
    this.isActive = true,
    this.children = const <ComplaintCategory>[],
  });

  factory ComplaintCategory.fromJson(Map<String, dynamic> json) {
    return ComplaintCategory(
      id: _requiredInt(json, 'id'),
      name: _requiredString(json, 'name'),
      parentId: _nullableInt(json['parent_id']),
      key: _nullableString(json['key']),
      isActive: _nullableBool(json['is_active']) ?? true,
      children: _mapList(json['children'])
          .map(ComplaintCategory.fromJson)
          .where((category) => category.isActive)
          .toList(growable: false),
    );
  }

  final int id;
  final int? parentId;
  final String? key;
  final String name;
  final bool isActive;
  final List<ComplaintCategory> children;

  bool get isGroup => parentId == null && children.isNotEmpty;
}

class ComplaintStatus {
  const ComplaintStatus({
    required this.key,
    required this.label,
    this.id,
    this.isTerminal,
  });

  factory ComplaintStatus.fromJson(Object? value) {
    if (value is String && value.trim().isNotEmpty) {
      final key = value.trim();
      return ComplaintStatus(key: key, label: key);
    }

    final json = _nullableMap(value);
    if (json == null) {
      throw const FormatException('Missing or invalid complaint status.');
    }

    final key = _requiredString(json, 'key');
    return ComplaintStatus(
      key: key,
      label: _nullableString(json['label']) ??
          _nullableString(json['name']) ??
          key,
      id: _nullableInt(json['id']),
      isTerminal: _nullableBool(json['is_terminal']),
    );
  }

  final String key;
  final String label;
  final int? id;
  final bool? isTerminal;

  bool get isDraft => key.toLowerCase() == 'draft';
}

class ComplaintStatusHistory {
  const ComplaintStatusHistory({
    required this.id,
    this.fromStatus,
    this.toStatus,
    this.changedByName,
    this.note,
    this.createdAt,
  });

  factory ComplaintStatusHistory.fromJson(Map<String, dynamic> json) {
    return ComplaintStatusHistory(
      id: _requiredInt(json, 'id'),
      fromStatus: _nullableComplaintStatus(json['from_status']),
      toStatus: _nullableComplaintStatus(json['to_status']),
      changedByName:
          _nullableString(_nullableMap(json['changed_by'])?['full_name']),
      note: _nullableString(json['note']),
      createdAt: _nullableDateTime(json['created_at']),
    );
  }

  final int id;
  final ComplaintStatus? fromStatus;
  final ComplaintStatus? toStatus;
  final String? changedByName;
  final String? note;
  final DateTime? createdAt;
}

class ComplaintImage {
  const ComplaintImage({
    required this.id,
    required this.url,
    this.name,
    this.mimeType,
    this.fileSize,
  });

  factory ComplaintImage.fromJson(Map<String, dynamic> json) {
    return ComplaintImage(
      id: _requiredInt(json, 'id'),
      url: ApiConfig.resolveServerUrl(
        _requiredStringFromKeys(
          json,
          const <String>['url', 'view_url', 'image_url', 'path'],
        ),
      ),
      name: _nullableString(json['name']) ??
          _nullableString(json['file_name']) ??
          _nullableString(json['original_name']),
      mimeType: _nullableString(json['mime_type']),
      fileSize: _nullableInt(json['file_size']),
    );
  }

  final int id;
  final String url;
  final String? name;
  final String? mimeType;
  final int? fileSize;
}

class ComplaintReport {
  const ComplaintReport({
    required this.id,
    required this.status,
    required this.images,
    this.statusHistory = const <ComplaintStatusHistory>[],
    this.municipalityId,
    this.municipalityName,
    this.categoryId,
    this.category,
    this.complaintId,
    this.title,
    this.description,
    this.textLocation,
    this.latitude,
    this.longitude,
    this.serverCanEdit,
    this.reportersCount,
    this.isLinked,
    this.submittedAt,
    this.linkedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory ComplaintReport.fromJson(Map<String, dynamic> json) {
    final statusValue = json['status'] ?? json['status_key'];
    final categoryJson = _nullableMap(json['category']);
    final municipalityJson = _nullableMap(json['municipality']);

    return ComplaintReport(
      id: _requiredInt(json, 'id'),
      status: ComplaintStatus.fromJson(statusValue),
      images: _mapList(json['images'])
          .map(ComplaintImage.fromJson)
          .toList(growable: false),
      statusHistory: _mapList(json['status_history'])
          .map(ComplaintStatusHistory.fromJson)
          .toList(growable: false),
      municipalityId: _nullableInt(json['municipality_id']) ??
          _nullableInt(municipalityJson?['id']),
      municipalityName: _nullableString(municipalityJson?['name']),
      categoryId:
          _nullableInt(json['category_id']) ?? _nullableInt(categoryJson?['id']),
      category: categoryJson == null
          ? null
          : ComplaintCategory(
              id: _requiredInt(categoryJson, 'id'),
              name: _requiredString(categoryJson, 'name'),
              parentId: _nullableInt(categoryJson['parent_id']),
              key: _nullableString(categoryJson['key']),
            ),
      title: _nullableString(json['title']),
      complaintId: _nullableInt(json['complaint_id']),
      description: _nullableString(json['description']),
      textLocation: _nullableString(json['text_location']),
      latitude: _nullableDouble(json['latitude']),
      longitude: _nullableDouble(json['longitude']),
      serverCanEdit: _nullableBool(json['can_edit']),
      reportersCount: _nullableInt(json['reporters_count']),
      isLinked: _nullableBool(json['is_linked']),
      submittedAt: _nullableDateTime(json['submitted_at']),
      linkedAt: _nullableDateTime(json['linked_at']),
      createdAt: _nullableDateTime(json['created_at']),
      updatedAt: _nullableDateTime(json['updated_at']),
    );
  }

  final int id;
  final ComplaintStatus status;
  final List<ComplaintImage> images;
  final List<ComplaintStatusHistory> statusHistory;
  final int? municipalityId;
  final String? municipalityName;
  final int? categoryId;
  final ComplaintCategory? category;
  final int? complaintId;
  final String? title;
  final String? description;
  final String? textLocation;
  final double? latitude;
  final double? longitude;

  /// If the backend sends `can_edit`, it is the authority. The draft status is
  /// used only as a compatibility fallback when that field is absent.
  final bool? serverCanEdit;
  final int? reportersCount;
  final bool? isLinked;
  final DateTime? submittedAt;
  final DateTime? linkedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get canEdit => serverCanEdit ?? status.isDraft;
}

class ComplaintReportsPage {
  const ComplaintReportsPage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory ComplaintReportsPage.fromJson(Map<String, dynamic> json) {
    final pagination = _nullableMap(json['pagination']);
    if (pagination == null) {
      throw const FormatException('Missing complaint pagination data.');
    }

    return ComplaintReportsPage(
      items: _mapList(json['items'])
          .map(ComplaintReport.fromJson)
          .toList(growable: false),
      currentPage: _requiredPositiveInt(pagination, 'current_page'),
      lastPage: _requiredPositiveInt(pagination, 'last_page'),
      perPage: _requiredPositiveInt(pagination, 'per_page'),
      total: _requiredNonNegativeInt(pagination, 'total'),
    );
  }

  final List<ComplaintReport> items;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  bool get hasNextPage => currentPage < lastPage;
}

class ComplaintDraftInput {
  const ComplaintDraftInput({
    this.municipalityId,
    this.categoryId,
    this.title,
    this.description,
    this.textLocation,
    this.latitude,
    this.longitude,
  });

  final int? municipalityId;
  final int? categoryId;
  final String? title;
  final String? description;
  final String? textLocation;
  final double? latitude;
  final double? longitude;

  Map<String, dynamic> toJson() {
    final normalizedTitle = _trimmed(title);
    final normalizedDescription = _trimmed(description);
    final normalizedTextLocation = _trimmed(textLocation);

    return <String, dynamic>{
      if (municipalityId != null) 'municipality_id': municipalityId,
      if (categoryId != null) 'category_id': categoryId,
      if (normalizedTitle != null) 'title': normalizedTitle,
      if (normalizedDescription != null) 'description': normalizedDescription,
      if (normalizedTextLocation != null)
        'text_location': normalizedTextLocation,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }

  /// Use before submit when the UI needs immediate field-level feedback.
  Map<String, List<String>> submissionErrors() {
    final errors = <String, List<String>>{};
    void required(String field, bool missing) {
      if (missing) errors[field] = <String>['هذا الحقل مطلوب.'];
    }

    required('municipality_id', municipalityId == null);
    required('category_id', categoryId == null);
    required('title', _trimmed(title) == null);
    required('description', _trimmed(description) == null);
    required('latitude', latitude == null);
    required('longitude', longitude == null);
    return Map<String, List<String>>.unmodifiable(errors);
  }
}

class ComplaintAttachment {
  const ComplaintAttachment({
    required this.name,
    required this.bytes,
  });

  static const int maxCount = 5;
  static const int maxBytes = 5 * 1024 * 1024;

  final String name;
  final Uint8List bytes;

  int get sizeInBytes => bytes.lengthInBytes;

  static void validateSelection(
    List<ComplaintAttachment> attachments, {
    int existingCount = 0,
  }) {
    if (attachments.isEmpty) {
      throw ApiException.validation(
        message: 'اختر صورة واحدة على الأقل.',
        errors: const <String, List<String>>{
          'images': <String>['اختر صورة واحدة على الأقل.'],
        },
      );
    }
    if (existingCount + attachments.length > maxCount) {
      throw ApiException.validation(
        message: 'يمكن إرفاق 5 صور كحد أقصى.',
        errors: const <String, List<String>>{
          'images': <String>['يمكن إرفاق 5 صور كحد أقصى.'],
        },
      );
    }

    for (final attachment in attachments) {
      final extension = attachment.name.split('.').last.toLowerCase();
      if (!const <String>{'jpg', 'jpeg', 'png'}.contains(extension)) {
        throw ApiException.validation(
          message: 'يجب أن تكون صور الشكوى بصيغة JPG أو PNG.',
          errors: const <String, List<String>>{
            'images': <String>['يجب أن تكون صور الشكوى بصيغة JPG أو PNG.'],
          },
        );
      }
      if (attachment.sizeInBytes > maxBytes) {
        throw ApiException.validation(
          message: 'يجب ألا يتجاوز حجم كل صورة شكوى 5 ميغابايت.',
          errors: const <String, List<String>>{
            'images': <String>[
              'يجب ألا يتجاوز حجم كل صورة شكوى 5 ميغابايت.',
            ],
          },
        );
      }
    }
  }
}

String? _trimmed(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}

ComplaintStatus? _nullableComplaintStatus(Object? value) {
  if (value == null) return null;
  return ComplaintStatus.fromJson(value);
}

String? _nullableString(Object? value) {
  if (value == null) return null;
  final normalized = value.toString().trim();
  return normalized.isEmpty ? null : normalized;
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = _nullableString(json[key]);
  if (value != null) return value;
  throw FormatException('Missing or invalid "$key" in complaint payload.');
}

String _requiredStringFromKeys(
  Map<String, dynamic> json,
  List<String> keys,
) {
  for (final key in keys) {
    final value = _nullableString(json[key]);
    if (value != null) return value;
  }
  throw const FormatException('Missing complaint image URL.');
}

int _requiredInt(Map<String, dynamic> json, String key) {
  final value = _nullableInt(json[key]);
  if (value != null) return value;
  throw FormatException('Missing or invalid "$key" in complaint payload.');
}

int? _nullableInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

int _requiredPositiveInt(Map<String, dynamic> json, String key) {
  final value = _nullableInt(json[key]);
  if (value != null && value > 0) return value;
  throw FormatException('Missing or invalid positive "$key" in complaint payload.');
}

int _requiredNonNegativeInt(Map<String, dynamic> json, String key) {
  final value = _nullableInt(json[key]);
  if (value != null && value >= 0) return value;
  throw FormatException(
    'Missing or invalid non-negative "$key" in complaint payload.',
  );
}

double? _nullableDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}

bool? _nullableBool(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.toLowerCase().trim();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
  }
  return null;
}

DateTime? _nullableDateTime(Object? value) {
  final normalized = _nullableString(value);
  return normalized == null ? null : DateTime.tryParse(normalized);
}

Map<String, dynamic>? _nullableMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map(
      (key, dynamic item) => MapEntry(key.toString(), item),
    );
  }
  return null;
}

List<Map<String, dynamic>> _mapList(Object? value) {
  if (value == null) return const <Map<String, dynamic>>[];
  if (value is! Iterable) {
    throw const FormatException('Invalid complaint images payload.');
  }
  return value.map((item) {
    final map = _nullableMap(item);
    if (map == null) {
      throw const FormatException('Invalid complaint image item.');
    }
    return map;
  }).toList(growable: false);
}
