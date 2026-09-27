import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:electronic_municipality_final/features/settings/presentation/screens/settings_screen.dart';
import 'package:electronic_municipality_final/l10n/app_locale_controller.dart';
import 'package:electronic_municipality_final/l10n/app_localizations.dart';

void main() {
  test('loads and persists the selected language', () async {
    final store = MemoryAppLocaleStore();
    final controller = AppLocaleController(store: store);

    await controller.load();
    expect(controller.locale, AppLocaleController.arabicLocale);

    await controller.setLocale(AppLocaleController.englishLocale);
    expect(store.languageCode, 'en');

    final restored = AppLocaleController(store: store);
    await restored.load();
    expect(restored.locale, AppLocaleController.englishLocale);
  });

  testWidgets('changes the whole settings screen between Arabic and English',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final store = MemoryAppLocaleStore();
    final controller = AppLocaleController(store: store);
    await controller.load();

    await tester.pumpWidget(_LanguageHarness(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('الإعدادات'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('الإعدادات'))),
      TextDirection.rtl,
    );

    await tester.tap(find.byKey(const ValueKey('settings_language_tile')));
    await tester.pumpAndSettle();
    expect(find.text('اختيار اللغة'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('select_english_language')));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('Settings'))),
      TextDirection.ltr,
    );
    expect(store.languageCode, 'en');

    await tester.tap(find.byKey(const ValueKey('settings_language_tile')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('select_arabic_language')));
    await tester.pumpAndSettle();

    expect(find.text('الإعدادات'), findsOneWidget);
    expect(store.languageCode, 'ar');
  });

  test('translates dynamic complaint and validation messages', () {
    const english = AppLocalizations(Locale('en'));

    expect(english.translate('شكوى #34'), 'Complaint #34');
    expect(
      english.translate('حقل العنوان مطلوب.'),
      'Title is required.',
    );
    expect(
      english.translate(
        'حساب المواطن غير موثق. يجب توثيق الحساب قبل إرسال الشكوى.',
      ),
      'Your citizen account is not verified. Verify it before submitting a complaint.',
    );
    expect(
      english.translate('تغيّرت الحالة من مسودة إلى قيد المعالجة'),
      'Status changed from Draft to In progress',
    );
    expect(
      english.translate('تم عرض 15 من 33 شكوى.'),
      'Showing 15 of 33 complaints.',
    );
    expect(
      english.translate('شكاوى المنطقة'),
      'Area complaints',
    );
    expect(
      english.translate('إعادة تحميل الخريطة'),
      'Reload map',
    );
    expect(
      english.translate('ابدأ بالخدمة التي تحتاجها الآن'),
      'Start with the service you need now',
    );
  });
}

class _LanguageHarness extends StatelessWidget {
  const _LanguageHarness({required this.controller});

  final AppLocaleController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => AppLocaleScope(
        controller: controller,
        child: MaterialApp(
          locale: controller.locale,
          supportedLocales: AppLocaleController.supportedLocales,
          localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          home: const Scaffold(
            body: SettingsScreen(onOpenProfile: _ignore),
          ),
        ),
      ),
    );
  }

  static void _ignore() {}
}
