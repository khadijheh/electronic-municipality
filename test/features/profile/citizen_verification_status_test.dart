import 'package:flutter_test/flutter_test.dart';

import 'package:electronic_municipality_final/core/repositories/auth_repository.dart';

void main() {
  group('Citizen verification status', () {
    test('is not submitted when identity photos are missing', () {
      final user = _citizen(
        <String, dynamic>{
          'is_verified': false,
          'front_id_photo': null,
          'back_id_photo': null,
        },
      );

      expect(
        user.citizenVerificationStatus,
        CitizenVerificationStatus.notSubmitted,
      );
    });

    test('is pending after both identity photos are uploaded', () {
      final user = _citizen(
        <String, dynamic>{
          'is_verified': false,
          'front_id_photo': 'citizens/id_photos/front.jpg',
          'back_id_photo': 'citizens/id_photos/back.jpg',
        },
      );

      expect(
        user.citizenVerificationStatus,
        CitizenVerificationStatus.pending,
      );
    });

    test('is verified when the municipality approves the account', () {
      final user = _citizen(
        <String, dynamic>{
          'is_verified': true,
          'front_id_photo': 'citizens/id_photos/front.jpg',
          'back_id_photo': 'citizens/id_photos/back.jpg',
        },
      );

      expect(
        user.citizenVerificationStatus,
        CitizenVerificationStatus.verified,
      );
    });
  });
}

AuthUser _citizen(Map<String, dynamic> profile) {
  return AuthUser(
    id: 1,
    fullName: 'مالك الشحرور',
    email: 'malik@example.sy',
    phoneNumber: '0991234567',
    roles: const ['citizen'],
    accountType: 'citizen',
    citizenProfile: profile,
  );
}
