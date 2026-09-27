import 'package:flutter/material.dart' hide Text;
import 'package:electronic_municipality_final/l10n/localized_text.dart';
import '../../../../app/router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/di.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../l10n/app_locale_controller.dart';
import '../../../../shared/widgets/municipality_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.onOpenProfile});
  final VoidCallback onOpenProfile;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoggingOut = false;

  Future<void> _openLanguagePicker() async {
    final controller = AppLocaleScope.of(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _LanguagePickerSheet(
        selectedLocale: controller.locale,
        onSelected: (locale) {
          Navigator.of(sheetContext).pop();
          controller.setLocale(locale);
        },
      ),
    );
  }

  Future<void> _logout() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);

    String? warningMessage;

    try {
      await DI.auth.logout();
    } catch (error) {
      warningMessage = error is ApiException
          ? '${error.message} تم إنهاء الجلسة محليًا.'
          : 'تعذر إبلاغ الخادم، لكن تم إنهاء الجلسة محليًا.';
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }

    if (!mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.login,
      (route) => false,
    );

    if (warningMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(warningMessage)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
        children: [
          const PageHeader(
              title: 'الإعدادات', subtitle: 'إدارة الحساب والتفضيلات'),
          const SizedBox(height: 24),
          _SettingsTile(
              icon: Icons.person_outline,
              title: 'الملف الشخصي',
              subtitle: 'البيانات الشخصية ومستندات التوثيق',
              onTap: widget.onOpenProfile),
          const SizedBox(height: 12),
          const _SettingsTile(
              icon: Icons.notifications_none,
              title: 'الإشعارات',
              subtitle: 'تنبيهات المعاملات والمنطقة'),
          const SizedBox(height: 12),
          _SettingsTile(
            key: const ValueKey('settings_language_tile'),
            icon: Icons.language,
            title: 'اللغة',
            subtitle: AppLocaleScope.of(context).isArabic
                ? 'العربية'
                : 'English',
            onTap: _openLanguagePicker,
          ),
          const SizedBox(height: 12),
          const _SettingsTile(
              icon: Icons.info_outline,
              title: 'حول التطبيق',
              subtitle: 'بوابة المواطن الرقمية - الإصدار 1.0'),
          const SizedBox(height: 12),
          _SettingsTile(
            icon: Icons.logout_rounded,
            title: _isLoggingOut ? 'جارٍ تسجيل الخروج...' : 'تسجيل الخروج',
            subtitle: 'إنهاء الجلسة الحالية بأمان',
            onTap: _isLoggingOut ? null : _logout,
          ),
        ]);
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile(
      {super.key,
      required this.icon,
      required this.title,
      required this.subtitle,
      this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AppPanel(
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 16,
            ),
            child: Row(children: [
              CircleIcon(icon: icon, iconColor: AppColors.primary),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 13))
                  ])),
              Icon(
                Directionality.of(context) == TextDirection.rtl
                    ? Icons.chevron_left
                    : Icons.chevron_right,
                color: AppColors.muted,
              )
            ])));
  }
}

class _LanguagePickerSheet extends StatelessWidget {
  const _LanguagePickerSheet({
    required this.selectedLocale,
    required this.onSelected,
  });

  final Locale selectedLocale;
  final ValueChanged<Locale> onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Row(
              children: [
                CircleIcon(
                  icon: Icons.translate_rounded,
                  size: 48,
                  color: Color(0xFFE1EEE8),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'اختيار اللغة',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'اختر لغة واجهة التطبيق',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _LanguageOption(
              key: const ValueKey('select_arabic_language'),
              locale: AppLocaleController.arabicLocale,
              nativeName: 'العربية',
              description: 'العربية · RTL',
              selected: selectedLocale.languageCode == 'ar',
              onTap: onSelected,
            ),
            const SizedBox(height: 10),
            _LanguageOption(
              key: const ValueKey('select_english_language'),
              locale: AppLocaleController.englishLocale,
              nativeName: 'English',
              description: 'English · LTR',
              selected: selectedLocale.languageCode == 'en',
              onTap: onSelected,
            ),
            const SizedBox(height: 14),
            const Text(
              'سيتم تطبيق اللغة مباشرة وحفظها على هذا الجهاز.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 12.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    super.key,
    required this.locale,
    required this.nativeName,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final Locale locale;
  final String nativeName;
  final String description;
  final bool selected;
  final ValueChanged<Locale> onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFEAF4EF) : AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => onTap(locale),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : AppColors.surface,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  locale.languageCode.toUpperCase(),
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nativeName,
                      translate: false,
                      textDirection: locale.languageCode == 'ar'
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      translate: false,
                      textDirection: locale.languageCode == 'ar'
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.circle_outlined,
                color: selected ? AppColors.success : AppColors.subtle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
