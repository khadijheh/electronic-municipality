import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class AppLocaleStore {
  Future<String?> readLanguageCode();

  Future<void> writeLanguageCode(String languageCode);
}

class SecureAppLocaleStore implements AppLocaleStore {
  const SecureAppLocaleStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'preferred_app_language';
  final FlutterSecureStorage _storage;

  @override
  Future<String?> readLanguageCode() => _storage.read(key: _key);

  @override
  Future<void> writeLanguageCode(String languageCode) {
    return _storage.write(key: _key, value: languageCode);
  }
}

class MemoryAppLocaleStore implements AppLocaleStore {
  MemoryAppLocaleStore([this.languageCode]);

  String? languageCode;

  @override
  Future<String?> readLanguageCode() async => languageCode;

  @override
  Future<void> writeLanguageCode(String languageCode) async {
    this.languageCode = languageCode;
  }
}

class AppLocaleController extends ChangeNotifier {
  AppLocaleController({
    AppLocaleStore? store,
    Locale initialLocale = arabicLocale,
  })  : _store = store ?? const SecureAppLocaleStore(),
        _locale = _normalize(initialLocale);

  static const Locale arabicLocale = Locale('ar');
  static const Locale englishLocale = Locale('en');
  static const List<Locale> supportedLocales = <Locale>[
    arabicLocale,
    englishLocale,
  ];

  final AppLocaleStore _store;
  Locale _locale;
  bool _loaded = false;

  Locale get locale => _locale;
  bool get isArabic => _locale.languageCode == arabicLocale.languageCode;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    try {
      final languageCode = await _store.readLanguageCode();
      if (languageCode != null) {
        _locale = _normalize(Locale(languageCode));
      }
    } catch (error, stackTrace) {
      debugPrint('LOAD APP LANGUAGE ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale locale) async {
    final normalized = _normalize(locale);
    if (_locale == normalized) return;

    _locale = normalized;
    notifyListeners();

    try {
      await _store.writeLanguageCode(normalized.languageCode);
    } catch (error, stackTrace) {
      // The UI remains usable in the selected language for this session even
      // when the platform preference store is temporarily unavailable.
      debugPrint('SAVE APP LANGUAGE ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  static Locale _normalize(Locale locale) {
    return locale.languageCode.toLowerCase() == englishLocale.languageCode
        ? englishLocale
        : arabicLocale;
  }
}

class AppLocaleScope extends InheritedNotifier<AppLocaleController> {
  const AppLocaleScope({
    super.key,
    required AppLocaleController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppLocaleController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppLocaleScope>();
    assert(scope != null, 'AppLocaleScope was not found above this context.');
    return scope!.notifier!;
  }
}
