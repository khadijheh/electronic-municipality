import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../features/authentication/presentation/screens/auth_screens.dart';
import '../features/authentication/presentation/screens/change_temporary_password_screen.dart';
import '../features/field_inspector/presentation/screens/field_inspector_screen.dart';
import '../features/home/presentation/screens/app_shell.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../l10n/app_locale_controller.dart';
import '../l10n/app_localizations.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class AppRoot extends StatefulWidget {
  const AppRoot({super.key, this.localeController});

  final AppLocaleController? localeController;

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  late final AppLocaleController _localeController =
      widget.localeController ?? AppLocaleController();
  late final bool _ownsController = widget.localeController == null;

  @override
  void dispose() {
    if (_ownsController) _localeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _localeController,
      builder: (context, _) => AppLocaleScope(
        controller: _localeController,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          onGenerateTitle: (context) => context.tr('بلديتنا الإلكترونية'),
          theme: buildAppTheme(),
          locale: _localeController.locale,
          supportedLocales: AppLocaleController.supportedLocales,
          localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          localeResolutionCallback: (deviceLocale, supportedLocales) {
            final requestedLanguage = deviceLocale?.languageCode;
            for (final locale in supportedLocales) {
              if (locale.languageCode == requestedLanguage) return locale;
            }
            return AppLocaleController.arabicLocale;
          },
          initialRoute: AppRoutes.splash,
          onGenerateRoute: (settings) {
            final routeName = settings.name;

            if (routeName == AppRoutes.shell) {
              final initialIndex =
                  settings.arguments is int ? settings.arguments as int : 0;
              return MaterialPageRoute<void>(
                builder: (_) => AppShell(initialIndex: initialIndex),
              );
            }

            final Widget page = switch (routeName) {
              AppRoutes.login => const AuthLoginScreen(),
              AppRoutes.signup => const AuthSignupScreen(),
              AppRoutes.forgot => const AuthForgotPasswordScreen(),
              AppRoutes.otp =>
                AuthOtpScreen.fromRouteArguments(settings.arguments),
              AppRoutes.reset => AuthResetPasswordScreen(
                  contact: settings.arguments is String
                      ? settings.arguments as String
                      : '',
                ),
              AppRoutes.changeTemporaryPassword =>
                const ChangeTemporaryPasswordScreen(),
              AppRoutes.profile => const ProfileScreen(),
              AppRoutes.fieldInspector => const FieldInspectorScreen(),
              _ => const AppSplashScreen(),
            };

            return MaterialPageRoute<void>(builder: (_) => page);
          },
        ),
      ),
    );
  }
}
