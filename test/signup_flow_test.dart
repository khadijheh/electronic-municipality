import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:electronic_municipality_final/app/app.dart';
import 'package:electronic_municipality_final/core/di.dart';
import 'package:electronic_municipality_final/features/authentication/data/auth_repository_fake.dart';

import 'helpers/widget_test_actions.dart';

void main() {
  setUp(() {
    DI.overrideAuth(AuthRepositoryFake());
  });

  tearDown(DI.resetAuth);

  testWidgets(
    'login opens the citizen signup form',
    (tester) async {
      await tester.pumpWidget(const AppRoot());
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      await tapWhenVisible(
        tester,
        find.byKey(const ValueKey('login_signup_button')),
      );
      await tester.pumpAndSettle();

      expect(find.text('إنشاء حساب مواطن'), findsOneWidget);
      expect(find.text('البيانات الشخصية'), findsOneWidget);
      expect(find.text('بيانات السكن'), findsOneWidget);
      expect(find.text('معلومات الدخول'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('signup_full_name_field')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('signup_submit_button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('signup_gender_field')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('signup_governorate_field')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('signup_municipality_field')),
        findsOneWidget,
      );
    },
  );
}
