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
    'password recovery accepts a complete OTP entered at once',
    (tester) async {
      const contact = 'otp-test@example.sy';
      const expectedCode = '1234';

      await tester.pumpWidget(const AppRoot());
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      await tapWhenVisible(tester, find.text('نسيت كلمة المرور؟'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('forgot_contact_field')),
        contact,
      );
      await tapWhenVisible(
        tester,
        find.byKey(const ValueKey('forgot_send_code_button')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      final codeField = find.byKey(const ValueKey('otp_code_field'));
      expect(codeField, findsOneWidget);

      await tester.enterText(codeField, expectedCode);
      await tester.pump();

      for (var index = 0; index < expectedCode.length; index++) {
        expect(
          find.descendant(
            of: find.byKey(ValueKey('otp_digit_$index')),
            matching: find.text(expectedCode[index]),
          ),
          findsOneWidget,
        );
      }

      await tapWhenVisible(
        tester,
        find.byKey(const ValueKey('otp_verify_button')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.text('تعيين كلمة مرور جديدة'), findsOneWidget);

      // Dispose the OTP route so its resend timer cannot leak past the test.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets(
    'returning from OTP restores forgot-password actions',
    (tester) async {
      await tester.pumpWidget(const AppRoot());
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      await tapWhenVisible(tester, find.text('نسيت كلمة المرور؟'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('forgot_contact_field')),
        'back-test@example.sy',
      );
      await tapWhenVisible(
        tester,
        find.byKey(const ValueKey('forgot_send_code_button')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.text('رمز التحقق'), findsOneWidget);

      await tapWhenVisible(
        tester,
        find.byKey(const ValueKey('otp_back_button')),
      );
      await tester.pumpAndSettle();

      expect(find.text('نسيت كلمة المرور'), findsOneWidget);

      final sendCodeButton = tester.widget<FilledButton>(
        find.byKey(const ValueKey('forgot_send_code_button')),
      );
      final backButton = tester.widget<TextButton>(
        find.byKey(const ValueKey('forgot_back_button')),
      );

      expect(sendCodeButton.onPressed, isNotNull);
      expect(backButton.onPressed, isNotNull);
    },
  );
}
