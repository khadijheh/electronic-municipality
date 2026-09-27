import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:electronic_municipality_final/shared/widgets/otp_input.dart';

void main() {
  Widget buildOtpInput({
    required ValueChanged<String> onChanged,
    ValueChanged<String>? onSubmitted,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 320,
            child: OtpInput(
              onChanged: onChanged,
              onSubmitted: onSubmitted,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets(
    'accepts four consecutive digits and displays them in separate boxes',
    (tester) async {
      var code = '';

      await tester.pumpWidget(
        buildOtpInput(onChanged: (value) => code = value),
      );
      await tester.enterText(
        find.byKey(const ValueKey('otp_code_field')),
        '1234',
      );
      await tester.pump();

      expect(code, '1234');
      for (var index = 0; index < code.length; index++) {
        expect(
          find.descendant(
            of: find.byKey(ValueKey('otp_digit_$index')),
            matching: find.text(code[index]),
          ),
          findsOneWidget,
        );
      }
    },
  );

  testWidgets(
    'normalizes Arabic digits and ignores pasted non-digit characters',
    (tester) async {
      var code = '';

      await tester.pumpWidget(
        buildOtpInput(onChanged: (value) => code = value),
      );
      await tester.enterText(
        find.byKey(const ValueKey('otp_code_field')),
        '١-۲ 3٤5',
      );
      await tester.pump();

      expect(code, '1234');
    },
  );

  testWidgets(
    'updates the code after deleting a digit and submits only a complete code',
    (tester) async {
      var code = '';
      String? submittedCode;
      final field = find.byKey(const ValueKey('otp_code_field'));

      await tester.pumpWidget(
        buildOtpInput(
          onChanged: (value) => code = value,
          onSubmitted: (value) => submittedCode = value,
        ),
      );
      await tester.enterText(field, '1234');
      await tester.pump();
      await tester.enterText(field, '123');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(code, '123');
      expect(submittedCode, isNull);

      await tester.enterText(field, '1234');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(submittedCode, '1234');
    },
  );
}
