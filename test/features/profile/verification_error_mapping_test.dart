import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:electronic_municipality_final/core/network/api_exception.dart';

void main() {
  test('maps identity photo validation without exposing backend text', () {
    final requestOptions = RequestOptions(
      path: 'citizen/identity-photos',
    );
    final dioError = DioException(
      requestOptions: requestOptions,
      response: Response<Map<String, dynamic>>(
        requestOptions: requestOptions,
        statusCode: 422,
        data: <String, dynamic>{
          'message': 'The given data was invalid.',
          'errors': <String, dynamic>{
            'front_id_photo': <String>[
              'The image size must not exceed 4MB.',
            ],
          },
        },
      ),
      type: DioExceptionType.badResponse,
    );

    final error = ApiException.fromDioException(dioError);

    expect(
      error.message,
      'يجب ألا يتجاوز حجم كل صورة هوية 4 ميغابايت.',
    );
    expect(error.message, isNot(contains('must not exceed')));
    expect(error.technicalMessage, contains('must not exceed'));
  });
}
