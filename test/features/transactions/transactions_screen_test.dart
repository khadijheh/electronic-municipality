import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:electronic_municipality_final/core/repositories/auth_repository.dart';
import 'package:electronic_municipality_final/features/authentication/data/auth_repository_fake.dart';
import 'package:electronic_municipality_final/features/transactions/presentation/screens/transactions_screen.dart';

void main() {
  testWidgets('shows verification notice for an unverified citizen', (
    WidgetTester tester,
  ) async {
    final authRepository = AuthRepositoryFake(
      currentUser: const AuthUser(
        id: 1,
        fullName: 'مواطن غير موثق',
        email: 'citizen@example.sy',
        phoneNumber: '0990000000',
        roles: <String>['citizen'],
        accountType: 'citizen',
        citizenProfile: <String, dynamic>{'is_verified': false},
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TransactionsScreen(authRepository: authRepository),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('citizen_verification_notice')),
      findsOneWidget,
    );
    expect(find.text('حساب المواطن غير موثق'), findsOneWidget);
  });
}
