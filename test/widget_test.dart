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
    'app shows splash then navigates to login',
    (WidgetTester tester) async {
      await tester.pumpWidget(const AppRoot());

      // شاشة البداية تظهر أولًا.
      expect(find.text('بلديتنا الإلكترونية'), findsOneWidget);
      expect(find.text('بوابة المواطن الرقمية'), findsOneWidget);

      // محاكاة مرور مدة شاشة البداية البالغة ثلاث ثوانٍ.
      await tester.pump(const Duration(seconds: 3));

      // إكمال حركة الانتقال إلى شاشة تسجيل الدخول.
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('تسجيل الدخول'), findsWidgets);
      expect(
        find.text('رقم الهاتف أو البريد الإلكتروني'),
        findsOneWidget,
      );
      expect(find.text('نسيت كلمة المرور؟'), findsOneWidget);
      expect(
        find.textContaining(
          'إنشاء حساب جديد',
          findRichText: true,
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'visitor can enter without credentials',
    (WidgetTester tester) async {
      await tester.pumpWidget(const AppRoot());
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('visitor_tab')));
      await tester.pump();

      expect(
        find.byKey(const ValueKey('login_identifier_field')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('login_password_field')),
        findsNothing,
      );
      expect(find.text('نسيت كلمة المرور؟'), findsNothing);
      expect(
        find.byKey(const ValueKey('visitor_message')),
        findsOneWidget,
      );

      await tapWhenVisible(
        tester,
        find.byKey(const ValueKey('login_submit_button')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
    },
  );
}
