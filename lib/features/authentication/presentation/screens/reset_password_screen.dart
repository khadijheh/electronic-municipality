import 'package:flutter/material.dart' hide Text;
import 'package:electronic_municipality_final/l10n/localized_text.dart';
import 'package:electronic_municipality_final/l10n/app_localizations.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/di.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../shared/widgets/municipality_widgets.dart';

class AuthResetPasswordScreen extends StatefulWidget {
  const AuthResetPasswordScreen({
    super.key,
    required this.contact,
  });

  final String contact;

  @override
  State<AuthResetPasswordScreen> createState() =>
      _AuthResetPasswordScreenState();
}

class _AuthResetPasswordScreenState extends State<AuthResetPasswordScreen> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'كلمات المرور غير متطابقة');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await DI.auth.resetPassword(
        contact: widget.contact,
        newPassword: _newPasswordController.text,
      );

      if (!mounted) return;

      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.login,
        (route) => false,
      );
    } catch (error, stackTrace) {
      debugPrint('RESET PASSWORD ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _errorMessage = error is ApiException
              ? error.message
              : 'فشل تعيين كلمة المرور الجديدة';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onPasswordChanged(String _) {
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthCenterScaffold(
      verticalPadding: EdgeInsets.zero,
      decoratedBackground: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 448),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(32, 32, 32, 48),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1400120A),
                blurRadius: 30,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _ResetPasswordHeader(),
              const SizedBox(height: 32),
              if (_errorMessage != null) ...[
                _ResetPasswordErrorMessage(message: _errorMessage!),
                const SizedBox(height: 16),
              ],
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ResetPasswordField(
                    fieldKey: const ValueKey('reset_new_password_field'),
                    label: 'كلمة المرور الجديدة',
                    hint: 'أدخل كلمة المرور الجديدة',
                    leadingIcon: Icons.lock_outline_rounded,
                    controller: _newPasswordController,
                    textInputAction: TextInputAction.next,
                    onChanged: _onPasswordChanged,
                  ),
                  const SizedBox(height: 16),
                  _ResetPasswordField(
                    fieldKey: const ValueKey('reset_confirm_password_field'),
                    label: 'تأكيد كلمة المرور',
                    hint: 'أعد إدخال كلمة المرور',
                    leadingIcon: Icons.lock_clock_outlined,
                    controller: _confirmPasswordController,
                    textInputAction: TextInputAction.done,
                    onChanged: _onPasswordChanged,
                    onSubmitted: (_) {
                      if (!_isLoading) _resetPassword();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: SizedBox(
                  height: 52,
                  child: FilledButton(
                    key: const ValueKey('reset_password_button'),
                    onPressed: _isLoading ? null : _resetPassword,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF00120A),
                      disabledBackgroundColor:
                          const Color(0xFF00120A).withOpacity(0.55),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
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
                                'تغيير كلمة المرور',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontSize: 14,
                                      height: 20 / 14,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.east_rounded,
                                size: 18,
                                color: Colors.white,
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Center(
                  child: TextButton.icon(
                    key: const ValueKey('reset_back_button'),
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.of(context).pushNamedAndRemoveUntil(
                              AppRoutes.login,
                              (route) => false,
                            ),
                    icon: const Icon(Icons.west_rounded, size: 16),
                    label: const Text('العودة إلى تسجيل الدخول'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF775928),
                      disabledForegroundColor:
                          const Color(0xFF775928).withOpacity(0.45),
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: const TextStyle(
                        fontSize: 12,
                        height: 16 / 12,
                        fontWeight: FontWeight.w500,
                      ),
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

class _ResetPasswordHeader extends StatelessWidget {
  const _ResetPasswordHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const CircleIcon(
          icon: Icons.lock_reset_rounded,
          size: 64,
          color: Color(0xFFC2ECD6),
          iconColor: Color(0xFF002115),
        ),
        const SizedBox(height: 12),
        Text(
          'تعيين كلمة مرور جديدة',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: const Color(0xFF1B1C19),
                fontSize: 26,
                height: 34 / 26,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'الرجاء إدخال كلمة المرور الجديدة وتأكيدها\nللمتابعة.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: const Color(0xFF414844),
                fontSize: 16,
                height: 1.5,
                fontWeight: FontWeight.w400,
              ),
        ),
      ],
    );
  }
}

class _ResetPasswordField extends StatefulWidget {
  const _ResetPasswordField({
    required this.fieldKey,
    required this.label,
    required this.hint,
    required this.leadingIcon,
    required this.controller,
    required this.textInputAction,
    required this.onChanged,
    this.onSubmitted,
  });

  final Key fieldKey;
  final String label;
  final String hint;
  final IconData leadingIcon;
  final TextEditingController controller;
  final TextInputAction textInputAction;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<_ResetPasswordField> createState() => _ResetPasswordFieldState();
}

class _ResetPasswordFieldState extends State<_ResetPasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    const borderColor = Color(0xFFE8D8C3);

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: borderColor),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.label,
          textAlign: TextAlign.start,
          style: const TextStyle(
            color: Color(0xFF1B1C19),
            fontSize: 14,
            height: 20 / 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          key: widget.fieldKey,
          controller: widget.controller,
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          obscureText: _obscureText,
          obscuringCharacter: '•',
          autocorrect: false,
          enableSuggestions: false,
          textDirection: TextDirection.ltr,
          textInputAction: widget.textInputAction,
          style: const TextStyle(
            color: Color(0xFF1B1C19),
            fontSize: 16,
            height: 1.5,
          ),
          decoration: InputDecoration(
            hintText: context.tr(widget.hint),
            hintTextDirection: Directionality.of(context),
            hintStyle: const TextStyle(
              color: Color(0x80414844),
              fontSize: 16,
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
            isDense: true,
            filled: true,
            fillColor: Colors.white,
            constraints: const BoxConstraints(minHeight: 50),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 44,
              minHeight: 48,
            ),
            prefixIcon: Icon(
              widget.leadingIcon,
              size: 22,
              color: const Color(0xB3775928),
            ),
            suffixIconConstraints: const BoxConstraints(
              minWidth: 46,
              minHeight: 48,
            ),
            suffixIcon: IconButton(
              tooltip: context.tr(
                _obscureText ? 'إظهار كلمة المرور' : 'إخفاء كلمة المرور',
              ),
              onPressed: () => setState(() => _obscureText = !_obscureText),
              padding: EdgeInsets.zero,
              splashRadius: 20,
              icon: Icon(
                _obscureText
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 24,
                color: const Color(0xFF414844),
              ),
            ),
            border: border,
            enabledBorder: border,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFF775928),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ResetPasswordErrorMessage extends StatelessWidget {
  const _ResetPasswordErrorMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.danger),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.danger,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
