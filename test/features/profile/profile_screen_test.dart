import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:electronic_municipality_final/core/di.dart';
import 'package:electronic_municipality_final/core/repositories/auth_repository.dart';
import 'package:electronic_municipality_final/features/authentication/data/auth_repository_fake.dart';
import 'package:electronic_municipality_final/features/profile/presentation/screens/identity_verification_screen.dart';
import 'package:electronic_municipality_final/features/profile/presentation/screens/profile_screen.dart';

void main() {
  tearDown(DI.resetAuth);

  testWidgets('unverified citizen can open identity verification', (
    WidgetTester tester,
  ) async {
    DI.overrideAuth(
      AuthRepositoryFake(
        currentUser: _citizen(
          <String, dynamic>{
            'is_verified': false,
            'national_id': '01234567890',
            'birth_date': '2001-02-03',
            'gender': 'Male',
            'place_of_birth': 'دمشق',
          },
        ),
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: ProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('مالك شحرور'), findsWidgets);
    expect(find.text('غير موثق'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('start_identity_verification')),
      findsOneWidget,
    );

    await tester.ensureVisible(
      find.byKey(const ValueKey('start_identity_verification')),
    );
    await tester.tap(
      find.byKey(const ValueKey('start_identity_verification')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(IdentityVerificationScreen), findsOneWidget);
    expect(find.text('الوجه الأمامي للهوية'), findsOneWidget);
    expect(find.text('الوجه الخلفي للهوية'), findsOneWidget);
  });

  testWidgets('pending verification cannot be submitted again', (
    WidgetTester tester,
  ) async {
    DI.overrideAuth(
      AuthRepositoryFake(
        currentUser: _citizen(
          <String, dynamic>{
            'is_verified': false,
            'front_id_photo': 'citizens/id_photos/front.jpg',
            'back_id_photo': 'citizens/id_photos/back.jpg',
          },
        ),
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: ProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('قيد المراجعة'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('start_identity_verification')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('refresh_verification_status')),
      findsOneWidget,
    );
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
