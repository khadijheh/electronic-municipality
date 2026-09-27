import 'package:flutter/foundation.dart';

@immutable
class UnifiedComplaintMapItem {
  const UnifiedComplaintMapItem({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.statusKey,
    required this.statusName,
    this.title,
    this.canonicalDescription,
    this.locationDescription,
    this.categoryName,
    this.municipalityName,
    this.updatedAt,
  });

  final int id;
  final double latitude;
  final double longitude;
  final String statusKey;
  final String statusName;
  final String? title;
  final String? canonicalDescription;
  final String? locationDescription;
  final String? categoryName;
  final String? municipalityName;
  final DateTime? updatedAt;

  bool get hasValidCoordinates =>
      latitude.isFinite &&
      longitude.isFinite &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;
}

@immutable
class UnifiedComplaintsMapPage {
  const UnifiedComplaintsMapPage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final List<UnifiedComplaintMapItem> items;
  final int currentPage;
  final int lastPage;
  final int total;

  bool get hasNextPage => currentPage < lastPage;
}

abstract class UnifiedComplaintsMapRepository {
  Future<UnifiedComplaintsMapPage> getPage({
    int page = 1,
    int perPage = 50,
  });

  Future<List<UnifiedComplaintMapItem>> getAllForMap({
    int perPage = 50,
  });
}
