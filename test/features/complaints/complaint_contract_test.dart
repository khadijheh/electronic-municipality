import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:electronic_municipality_final/core/config/api_config.dart';
import 'package:electronic_municipality_final/core/network/api_exception.dart';
import 'package:electronic_municipality_final/features/complaints/data/complaint_endpoints.dart';
import 'package:electronic_municipality_final/features/complaints/data/models/complaint_models.dart';

void main() {
  test('category model matches the authenticated hierarchical response', () {
    final category = ComplaintCategory.fromJson(
      <String, dynamic>{
        'id': 1,
        'parent_id': null,
        'name': 'الطرق والأرصفة',
        'children': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 2,
            'parent_id': 1,
            'name': 'حفرة في الطريق',
          },
        ],
      },
    );

    expect(category.id, 1);
    expect(category.parentId, isNull);
    expect(category.key, isNull);
    expect(category.name, 'الطرق والأرصفة');
    expect(category.isGroup, isTrue);
    expect(category.children, hasLength(1));
    expect(category.children.single.id, 2);
    expect(category.children.single.parentId, 1);
    expect(category.children.single.name, 'حفرة في الطريق');
    expect(ComplaintEndpoints.categories, 'ComplaintCategories');
  });

  test('inactive complaint categories are excluded while older APIs stay compatible', () {
    final root = ComplaintCategory.fromJson(
      <String, dynamic>{
        'id': 1,
        'name': 'الخدمات',
        'is_active': true,
        'children': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 2,
            'parent_id': 1,
            'name': 'خدمة فعالة',
            'is_active': true,
          },
          <String, dynamic>{
            'id': 3,
            'parent_id': 1,
            'name': 'خدمة معطلة',
            'is_active': false,
          },
        ],
      },
    );

    expect(root.isActive, isTrue);
    expect(root.children.map((item) => item.id), <int>[2]);
    expect(
      ComplaintCategory.fromJson(<String, dynamic>{'id': 4, 'name': 'قديمة'})
          .isActive,
      isTrue,
    );
  });

  test('draft request uses exactly the Laravel complaint field names', () {
    const input = ComplaintDraftInput(
      municipalityId: 12,
      categoryId: 2,
      title: '  انقطاع المياه  ',
      description: '  انقطاع منذ الصباح  ',
      textLocation: '  قرب الحديقة  ',
      latitude: 33.5138,
      longitude: 36.2765,
    );

    expect(
      input.toJson(),
      <String, dynamic>{
        'municipality_id': 12,
        'category_id': 2,
        'title': 'انقطاع المياه',
        'description': 'انقطاع منذ الصباح',
        'text_location': 'قرب الحديقة',
        'latitude': 33.5138,
        'longitude': 36.2765,
      },
    );
    expect(input.submissionErrors(), isEmpty);
  });

  test('submission validation reports the six backend-required fields', () {
    const input = ComplaintDraftInput();

    expect(
      input.submissionErrors().keys,
      <String>[
        'municipality_id',
        'category_id',
        'title',
        'description',
        'latitude',
        'longitude',
      ],
    );
  });

  test('can_edit from backend overrides draft fallback', () {
    final report = ComplaintReport.fromJson(
      <String, dynamic>{
        'id': 7,
        'status': <String, dynamic>{
          'key': 'draft',
          'label': 'مسودة',
        },
        'can_edit': false,
        'images': <Object>[],
      },
    );

    expect(report.status.isDraft, isTrue);
    expect(report.canEdit, isFalse);
  });

  test('report model matches detail response image and coordinate fields', () {
    final report = ComplaintReport.fromJson(
      <String, dynamic>{
        'id': 31,
        'title': 'حاوية ممتلئة',
        'latitude': '33.4730210',
        'longitude': '36.2496910',
        'status': <String, dynamic>{
          'id': 1,
          'key': 'draft',
          'name': 'مسودة',
        },
        'images': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 1,
            'original_name': 'evidence.jpg',
            'view_url': 'http://server/storage/evidence.jpg',
          },
        ],
      },
    );

    expect(report.latitude, 33.473021);
    expect(report.longitude, 36.249691);
    expect(report.status.label, 'مسودة');
    expect(report.images.single.name, 'evidence.jpg');
    expect(
      report.images.single.url,
      'http://server/storage/evidence.jpg',
    );
  });

  test('report model matches the complete citizen complaints response item', () {
    final report = ComplaintReport.fromJson(
      <String, dynamic>{
        'id': 34,
        'complaint_id': null,
        'title': 'عمود إنارة',
        'description': 'العمود متضرر ويحتاج إلى صيانة',
        'text_location': 'قرب الحديقة العامة',
        'latitude': '33.4728700',
        'longitude': '36.2497910',
        'municipality': <String, dynamic>{
          'id': 1,
          'name': 'بلدية كفرسوسة',
        },
        'category': <String, dynamic>{
          'id': 13,
          'name': 'عمود إنارة متضرر',
          'parent_id': 11,
        },
        'status': <String, dynamic>{
          'id': 2,
          'key': 'submitted',
          'name': 'تم الإرسال',
          'is_terminal': false,
        },
        'images': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 5,
            'original_name': 'scaled_125865.jpg',
            'mime_type': 'image/jpeg',
            'file_size': 149020,
            'view_url':
                'http://localhost/storage/complaint-reports/34/image.jpg',
          },
        ],
        'reporters_count': null,
        'is_linked': false,
        'can_edit': false,
        'submitted_at': '2026-08-14T15:45:23.000000Z',
        'linked_at': null,
        'created_at': '2026-08-14T15:45:21.000000Z',
        'updated_at': '2026-08-14T15:45:23.000000Z',
      },
    );

    expect(report.id, 34);
    expect(report.municipalityId, 1);
    expect(report.municipalityName, 'بلدية كفرسوسة');
    expect(report.categoryId, 13);
    expect(report.category?.parentId, 11);
    expect(report.status.id, 2);
    expect(report.status.label, 'تم الإرسال');
    expect(report.status.isTerminal, isFalse);
    expect(report.canEdit, isFalse);
    expect(report.isLinked, isFalse);
    expect(report.submittedAt, DateTime.parse('2026-08-14T15:45:23Z'));
    expect(report.images.single.name, 'scaled_125865.jpg');
    expect(report.images.single.mimeType, 'image/jpeg');
    expect(report.images.single.fileSize, 149020);

    final imageUri = Uri.parse(report.images.single.url);
    final apiUri = Uri.parse(ApiConfig.normalizedBaseUrl);
    expect(imageUri.host, apiUri.host);
    expect(imageUri.port, apiUri.port);
    expect(imageUri.path, '/storage/complaint-reports/34/image.jpg');
  });

  test('server URL resolver accepts markdown-wrapped image URLs', () {
    final url = ApiConfig.resolveServerUrl(
      '[http://localhost/storage/image.jpg]'
      '(http://localhost/storage/image.jpg)',
    );
    final resolved = Uri.parse(url);
    final api = Uri.parse(ApiConfig.normalizedBaseUrl);

    expect(resolved.host, api.host);
    expect(resolved.port, api.port);
    expect(resolved.path, '/storage/image.jpg');
  });

  test('detail response parses public complaint status history', () {
    final report = ComplaintReport.fromJson(
      <String, dynamic>{
        'id': 21,
        'status': <String, dynamic>{'key': 'submitted', 'name': 'مرسلة'},
        'images': <Object>[],
        'status_history': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 5,
            'from_status': <String, dynamic>{'key': 'draft', 'name': 'مسودة'},
            'to_status': <String, dynamic>{
              'key': 'submitted',
              'name': 'مرسلة',
            },
            'changed_by': <String, dynamic>{'full_name': 'مواطن تجريبي'},
            'note': 'تم إرسال الشكوى.',
            'created_at': '2026-08-15T10:30:00.000000Z',
          },
        ],
      },
    );

    expect(report.statusHistory, hasLength(1));
    expect(report.statusHistory.single.fromStatus?.key, 'draft');
    expect(report.statusHistory.single.toStatus?.label, 'مرسلة');
    expect(report.statusHistory.single.changedByName, 'مواطن تجريبي');
  });

  test('paginated reports match the Laravel items and pagination envelope', () {
    final page = ComplaintReportsPage.fromJson(
      <String, dynamic>{
        'items': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 11,
            'status': <String, dynamic>{'key': 'draft', 'name': 'مسودة'},
            'images': <Object>[],
          },
        ],
        'pagination': <String, dynamic>{
          'current_page': 1,
          'last_page': 3,
          'per_page': 15,
          'total': 33,
        },
      },
    );

    expect(page.items.single.id, 11);
    expect(page.currentPage, 1);
    expect(page.total, 33);
    expect(page.hasNextPage, isTrue);
  });

  test('draft status is fallback when can_edit is absent', () {
    final report = ComplaintReport.fromJson(
      <String, dynamic>{
        'id': 8,
        'status': <String, dynamic>{
          'key': 'draft',
          'label': 'مسودة',
        },
        'images': <Object>[],
      },
    );

    expect(report.canEdit, isTrue);
  });

  test('complaint images are limited to five JPG or PNG files', () {
    final valid = ComplaintAttachment(
      name: 'evidence.JPG',
      bytes: Uint8List(10),
    );

    expect(
      () => ComplaintAttachment.validateSelection(
        <ComplaintAttachment>[valid],
        existingCount: 4,
      ),
      returnsNormally,
    );
    expect(
      () => ComplaintAttachment.validateSelection(
        <ComplaintAttachment>[valid, valid],
        existingCount: 4,
      ),
      throwsA(isA<ApiException>()),
    );
    expect(
      () => ComplaintAttachment.validateSelection(
        <ComplaintAttachment>[
          ComplaintAttachment(name: 'file.pdf', bytes: Uint8List(10)),
        ],
      ),
      throwsA(isA<ApiException>()),
    );
  });

  test('maps complaint validation fields to safe Arabic messages', () {
    final requestOptions = RequestOptions(
      path: 'citizen/complaints/drafts',
    );
    final dioError = DioException(
      requestOptions: requestOptions,
      response: Response<Map<String, dynamic>>(
        requestOptions: requestOptions,
        statusCode: 422,
        data: <String, dynamic>{
          'message': 'The given data was invalid.',
          'errors': <String, dynamic>{
            'category_id': <String>['The category id field is required.'],
          },
        },
      ),
      type: DioExceptionType.badResponse,
    );

    final error = ApiException.fromDioException(dioError);

    expect(error.message, 'حقل تصنيف الشكوى مطلوب.');
    expect(error.errorFor('category_id'), 'حقل تصنيف الشكوى مطلوب.');
  });

  test('maps unverified citizen rule without treating before as a date', () {
    final requestOptions = RequestOptions(
      path: 'citizen/complaints/32/submit',
    );
    final dioError = DioException(
      requestOptions: requestOptions,
      response: Response<Map<String, dynamic>>(
        requestOptions: requestOptions,
        statusCode: 422,
        data: <String, dynamic>{
          'message':
              'The citizen account must be verified before submitting a complaint.',
          'errors': <String, dynamic>{
            'citizen': <String>[
              'The citizen account must be verified before submitting a complaint.',
            ],
          },
        },
      ),
      type: DioExceptionType.badResponse,
    );

    final error = ApiException.fromDioException(dioError);

    expect(
      error.message,
      'حساب المواطن غير موثق. يجب توثيق الحساب قبل إرسال الشكوى.',
    );
    expect(error.requiresCitizenVerification, isTrue);
  });

  test('complaint endpoint paths preserve the draft workflow', () {
    expect(ComplaintEndpoints.drafts, 'citizen/complaints/drafts');
    expect(ComplaintEndpoints.report(9), 'citizen/complaints/9');
    expect(ComplaintEndpoints.images(9), 'citizen/complaints/9/images');
    expect(
      ComplaintEndpoints.image(9, 3),
      'citizen/complaints/9/images/3',
    );
    expect(ComplaintEndpoints.submit(9), 'citizen/complaints/9/submit');
  });
}
