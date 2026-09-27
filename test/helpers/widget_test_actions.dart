import 'package:flutter_test/flutter_test.dart';

/// Scrolls a widget into the test viewport before tapping it.
///
/// Authentication screens are intentionally scrollable on short devices. The
/// default widget-test viewport is only 800x600, so a direct [WidgetTester.tap]
/// can target an off-screen render object even though the widget exists.
Future<void> tapWhenVisible(
  WidgetTester tester,
  Finder finder,
) async {
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
}
