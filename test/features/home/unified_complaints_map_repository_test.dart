import 'package:flutter_test/flutter_test.dart';

import 'package:electronic_municipality_final/features/home/data/unified_complaints_map_repository_api.dart';

void main() {
  test('parses unified complaint map item from Laravel response', () {
    final item = UnifiedComplaintMapItemParser.fromJson(<String, dynamic>{
      'id': 51,
      'title': 'حفرة في الطريق',
      'canonical_description': 'حفرة عميقة قرب تقاطع الطريق الرئيسي.',
      'text_location': 'شارع بغداد',
      'latitude': '33.5192',
      'longitude': 36.2923,
      'updated_at': '2026-08-15T08:30:00.000000Z',
      'current_status': <String, dynamic>{
        'key': 'in_progress',
        'name': 'قيد المعالجة',
      },
      'category': <String, dynamic>{'name': 'حفرة في الطريق'},
      'municipality': <String, dynamic>{'name': 'بلدية دمشق'},
    });

    expect(item.id, 51);
    expect(item.latitude, closeTo(33.5192, .00001));
    expect(item.longitude, closeTo(36.2923, .00001));
    expect(item.statusKey, 'in_progress');
    expect(item.canonicalDescription, 'حفرة عميقة قرب تقاطع الطريق الرئيسي.');
    expect(item.hasValidCoordinates, isTrue);
  });

  test('marks a complaint without valid coordinates as unsuitable for the map', () {
    final item = UnifiedComplaintMapItemParser.fromJson(<String, dynamic>{
      'id': 52,
      'latitude': null,
      'longitude': null,
      'current_status': <String, dynamic>{
        'key': 'submitted',
        'name': 'تم الإرسال',
      },
    });

    expect(item.hasValidCoordinates, isFalse);
  });
}
