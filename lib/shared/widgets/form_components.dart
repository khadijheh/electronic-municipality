import 'package:flutter/material.dart' hide Text;
import 'package:electronic_municipality_final/l10n/localized_text.dart';
import 'package:electronic_municipality_final/l10n/app_localizations.dart';
import '../../app/design_system.dart';
import '../../app/theme/app_colors.dart';

// ============================================================================
// REUSABLE TEXT FIELDS
// ============================================================================

class PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const PasswordStrengthIndicator({super.key, required this.password});

  List<PasswordRequirement> _getRequirements() {
    return [
      PasswordRequirement(
        label: '8 أحرف على الأقل',
        met: password.length >= 8,
      ),
      PasswordRequirement(
        label: 'حرف كبير وحرف صغير',
        met: password.contains(RegExp(r'[a-z]')) &&
            password.contains(RegExp(r'[A-Z]')),
      ),
      PasswordRequirement(
        label: 'رقم أو رمز خاص',
        met: password.contains(RegExp(r'[0-9!@#$%^&*()_+\-=\[\]{};:",.<>?/]')),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final requirements = _getRequirements();

    return Container(
      key: const ValueKey('password_requirements'),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'يجب أن تحتوي كلمة المرور على:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (var req in requirements) ...[
            Row(
              children: [
                Icon(
                  req.met
                      ? Icons.check_circle_outline_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 22,
                  color: req.met ? AppColors.success : AppColors.muted,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    req.label,
                    style: TextStyle(
                      fontSize: 16,
                      color: req.met ? AppColors.success : AppColors.muted,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            if (req != requirements.last) const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class PasswordRequirement {
  final String label;
  final bool met;

  PasswordRequirement({required this.label, required this.met});
}

// ============================================================================
// OTP INPUT (Enhanced)
// ============================================================================

class OTPInputField extends StatefulWidget {
  final int length;
  final ValueChanged<String> onComplete;
  final TextStyle? textStyle;

  const OTPInputField({
    super.key,
    this.length = 4,
    required this.onComplete,
    this.textStyle,
  });

  @override
  State<OTPInputField> createState() => _OTPInputFieldState();
}

class _OTPInputFieldState extends State<OTPInputField> {
  late List<TextEditingController> controllers;
  late List<FocusNode> focusNodes;

  @override
  void initState() {
    super.initState();
    controllers = List.generate(widget.length, (i) => TextEditingController());
    focusNodes = List.generate(widget.length, (i) => FocusNode());
  }

  @override
  void dispose() {
    for (var controller in controllers) {
      controller.dispose();
    }
    for (var node in focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _handleInput(String value, int index) {
    if (value.isNotEmpty) {
      if (index < widget.length - 1) {
        focusNodes[index + 1].requestFocus();
      }
      _checkComplete();
    }
  }

  void _checkComplete() {
    final fullCode = controllers.map((c) => c.text).join();
    if (fullCode.length == widget.length) {
      widget.onComplete(fullCode);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        widget.length,
        (index) => Container(
          width: 60,
          height: 60,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          child: TextField(
            controller: controllers[index],
            focusNode: focusNodes[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            onChanged: (value) => _handleInput(value, index),
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: AppColors.surface,
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
                borderSide: const BorderSide(color: AppColors.info, width: 2),
              ),
            ),
            style: widget.textStyle ??
                const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// DOCUMENT UPLOAD AREA
// ============================================================================

class DocumentUploadArea extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback onTap;
  final bool isUploaded;
  final String? uploadedFileName;

  const DocumentUploadArea({
    super.key,
    required this.title,
    required this.description,
    required this.onTap,
    this.isUploaded = false,
    this.uploadedFileName,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: AppColors.border,
            style: BorderStyle.solid,
            strokeAlign: BorderSide.strokeAlignOutside,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isUploaded ? Icons.check_circle : Icons.image_outlined,
              size: 48,
              color: isUploaded ? AppColors.success : AppColors.muted,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              description,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.muted,
              ),
              textAlign: TextAlign.center,
            ),
            if (uploadedFileName != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                uploadedFileName!,
                translate: false,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// RESEND TIMER
// ============================================================================

class ResendCodeTimer extends StatefulWidget {
  final Duration duration;
  final VoidCallback onResend;
  final double fontSize;

  const ResendCodeTimer({
    super.key,
    this.duration = const Duration(minutes: 1),
    required this.onResend,
    this.fontSize = 14,
  });

  @override
  State<ResendCodeTimer> createState() => _ResendCodeTimerState();
}

class _ResendCodeTimerState extends State<ResendCodeTimer> {
  late int _secondsRemaining;
  bool _isExpired = false;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.duration.inSeconds;
    _startTimer();
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
        _startTimer();
      } else if (mounted && _secondsRemaining == 0) {
        setState(() => _isExpired = true);
      }
    });
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isExpired) {
      return GestureDetector(
        onTap: widget.onResend,
        child: Text(
          'إعادة إرسال الرمز (${_formatTime(_secondsRemaining)})',
          style: TextStyle(
            fontSize: widget.fontSize,
            color: AppColors.gold,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.underline,
          ),
        ),
      );
    }

    return Text(
      'لم تستلم الرمز؟ إعادة إرسال الرمز (${_formatTime(_secondsRemaining)})',
      style: TextStyle(
        fontSize: widget.fontSize,
        color: AppColors.muted,
      ),
    );
  }
}

// ============================================================================
// FORM VALIDATION HELPER
// ============================================================================

class FormValidator {
  static String? email(String? value) {
    if (value?.isEmpty ?? true) {
      return 'البريد الإلكتروني مطلوب';
    }
    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!regex.hasMatch(value!)) {
      return 'البريد الإلكتروني غير صحيح';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value?.isEmpty ?? true) {
      return 'رقم الهاتف مطلوب';
    }
    final regex = RegExp(r'^[0-9]{10,15}$');
    if (!regex.hasMatch(value!.replaceAll(RegExp(r'\D'), ''))) {
      return 'رقم الهاتف غير صحيح';
    }
    return null;
  }

  static String? password(String? value) {
    if (value?.isEmpty ?? true) {
      return 'كلمة المرور مطلوبة';
    }
    if (value!.length < 8) {
      return 'كلمة المرور يجب أن تكون 8 أحرف على الأقل';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    final result = FormValidator.password(value);
    if (result != null) return result;
    if (value != password) {
      return 'كلمات المرور غير متطابقة';
    }
    return null;
  }

  static String? required(String? value, String fieldName) {
    if (value?.isEmpty ?? true) {
      return '$fieldName مطلوب';
    }
    return null;
  }
}

// ============================================================================
// TEXT INPUT COMPONENTS
// ============================================================================

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.onChanged,
    this.obscureText = false,
    this.maxLines = 1,
  });

  final String label;
  final String? hint;
  final TextEditingController? controller;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final String? Function(String?)? validator;
  final Function(String)? onChanged;
  final bool obscureText;
  final int maxLines;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      focusNode: _focusNode,
      validator: (value) {
        final error = widget.validator?.call(value);
        return error == null ? null : context.tr(error);
      },
      onChanged: widget.onChanged,
      obscureText: widget.obscureText,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      textDirection: Directionality.of(context),
      decoration: InputDecoration(
        labelText: context.tr(widget.label),
        hintText: widget.hint == null ? null : context.tr(widget.hint!),
        prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon) : null,
        suffixIcon: widget.suffixIcon != null ? Icon(widget.suffixIcon) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
      ),
    );
  }
}

class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    this.validator,
    this.onChanged,
  });

  final TextEditingController controller;
  final String? Function(String?)? validator;
  final Function(String)? onChanged;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscureText = true;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _toggleVisibility() {
    setState(() => _obscureText = !_obscureText);
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      focusNode: _focusNode,
      validator: (value) {
        final error = widget.validator?.call(value);
        return error == null ? null : context.tr(error);
      },
      onChanged: widget.onChanged,
      obscureText: _obscureText,
      textDirection: Directionality.of(context),
      decoration: InputDecoration(
        labelText: context.tr('كلمة المرور'),
        hintText: context.tr('أدخل كلمة المرور'),
        prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureText ? Icons.visibility_off : Icons.visibility,
            color: AppColors.primary,
          ),
          onPressed: _toggleVisibility,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
      ),
    );
  }
}
