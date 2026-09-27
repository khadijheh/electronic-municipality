import 'package:flutter/material.dart';
import 'app/app.dart';
import 'l10n/app_locale_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final localeController = AppLocaleController();
  await localeController.load();
  runApp(AppRoot(localeController: localeController));
}
