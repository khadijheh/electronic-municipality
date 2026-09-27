import 'package:flutter/material.dart' hide Text;
import 'package:electronic_municipality_final/l10n/localized_text.dart';
import 'package:electronic_municipality_final/l10n/app_localizations.dart';

import '../../../../app/design_system.dart';
import '../../../../app/router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/di.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../shared/widgets/municipality_widgets.dart';

class AuthForgotPasswordScreen extends StatefulWidget {
  const AuthForgotPasswordScreen({super.key});

  @override
  State<AuthForgotPasswordScreen> createState() =>
      _AuthForgotPasswordScreenState();
}

class _AuthForgotPasswordScreenState extends State<AuthForgotPasswordScreen> {
  final _contactController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;

  @override
  void dispose() {
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final contact = _contactController.text.trim();
    setState(() => _isLoading = true);

    try {
      await DI.auth.requestOtp(contact: contact);

      if (!mounted) return;

      await Navigator.of(context).pushNamed(
        AppRoutes.otp,
        arguments: contact,
      );
    } catch (error, stackTrace) {
      debugPrint('FORGOT PASSWORD ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is ApiException
                  ? error.message
                  : 'فشل إرسال الرمز. حاول مرة أخرى.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthCenterScaffold(
      verticalPadding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.xxxl,
        ),
        child: AuthCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: MunicipalityLogo(
                  size: 104,
                  framed: false,
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),
              Text(
                'نسيت كلمة المرور',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppColors.text,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'أدخل بريدك الإلكتروني لاسترداد كلمة المرور',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.muted,
                      fontSize: 17,
                      height: 1.7,
                    ),
              ),
              const SizedBox(height: AppSpacing.huge),
              Form(
                key: _formKey,
                child: _ContactField(
                  controller: _contactController,
                  onSubmitted: (_) {
                    if (!_isLoading) _sendCode();
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),
              SizedBox(
                height: 64,
                child: FilledButton(
                  key: const ValueKey('forgot_send_code_button'),
                  onPressed: _isLoading ? null : _sendCode,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.deepPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    elevation: 8,
                    shadowColor: Colors.black.withOpacity(0.18),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'إرسال الرمز',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            const Icon(Icons.send_rounded, size: 27),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.huge),
              Center(
                child: TextButton.icon(
                  key: const ValueKey('forgot_back_button'),
                  onPressed:
                      _isLoading ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 27),
                  label: const Text('العودة إلى تسجيل الدخول'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.gold,
                    textStyle: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactField extends StatelessWidget {
  const _ContactField({
    required this.controller,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'البريد الإلكتروني',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.text,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          key: const ValueKey('forgot_contact_field'),
          controller: controller,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return context.tr('البريد الإلكتروني مطلوب');
            }
            final email = value.trim();
            final isValid =
                RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
            return isValid
                ? null
                : context.tr('أدخل بريداً إلكترونياً صحيحاً');
          },
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          autofillHints: const [
            AutofillHints.email,
          ],
          onFieldSubmitted: onSubmitted,
          textDirection: TextDirection.ltr,
          decoration: InputDecoration(
            hintText: context.tr('أدخل هنا...'),
            prefixIcon: const Icon(
              Icons.contact_mail_outlined,
              color: AppColors.gold,
              size: 30,
            ),
            filled: true,
            fillColor: AppColors.surface,
            constraints: const BoxConstraints(minHeight: 64),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.lg,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
