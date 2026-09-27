import 'package:flutter/material.dart' hide Text;
import 'package:electronic_municipality_final/l10n/localized_text.dart';
import 'package:electronic_municipality_final/l10n/app_localizations.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_colors.dart';

typedef OtpSubmit = void Function(String code);

class OtpInput extends StatefulWidget {
  const OtpInput({
    super.key,
    this.length = 4,
    required this.onChanged,
    this.onSubmitted,
    this.textStyle,
    this.enabled = true,
  }) : assert(length > 0);

  final int length;
  final ValueChanged<String> onChanged;
  final OtpSubmit? onSubmitted;
  final TextStyle? textStyle;
  final bool enabled;

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode()..addListener(_rebuild);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_rebuild)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  void _onChanged(String value) {
    setState(() {});
    widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = constraints.maxWidth < 240 ? 8.0 : 12.0;
        final fieldWidth = constraints.hasBoundedWidth
            ? ((constraints.maxWidth - (gap * (widget.length - 1))) /
                    widget.length)
                .clamp(44.0, 72.0)
                .toDouble()
            : 60.0;
        final code = _controller.text;
        final activeIndex = code.length.clamp(0, widget.length - 1);

        return Semantics(
          label: context.tr(
            'رمز التحقق المكون من ${widget.length} أرقام',
          ),
          textField: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.enabled ? _focusNode.requestFocus : null,
            child: Stack(
              children: [
                IgnorePointer(
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(widget.length, (index) {
                        final isActive = _focusNode.hasFocus &&
                            (index == activeIndex ||
                                (code.length == widget.length &&
                                    index == widget.length - 1));

                        return Padding(
                          padding: EdgeInsets.only(
                            right: index == widget.length - 1 ? 0 : gap,
                          ),
                          child: AnimatedContainer(
                            key: ValueKey('otp_digit_$index'),
                            duration: const Duration(milliseconds: 120),
                            width: fieldWidth,
                            height: 64,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              border: Border.all(
                                color: isActive
                                    ? const Color(0xFF2A68D8)
                                    : AppColors.muted,
                                width: isActive ? 3 : 1,
                              ),
                            ),
                            child: Text(
                              index < code.length ? code[index] : '',
                              translate: false,
                              style: widget.textStyle ??
                                  const TextStyle(
                                    color: AppColors.text,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Opacity(
                    opacity: 0,
                    child: TextField(
                      key: const ValueKey('otp_code_field'),
                      controller: _controller,
                      focusNode: _focusNode,
                      enabled: widget.enabled,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.center,
                      textInputAction: TextInputAction.done,
                      maxLength: widget.length,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      enableSuggestions: false,
                      autocorrect: false,
                      inputFormatters: [
                        _OtpDigitsFormatter(widget.length),
                      ],
                      onChanged: _onChanged,
                      onSubmitted: (value) {
                        if (value.length == widget.length) {
                          widget.onSubmitted?.call(value);
                        }
                      },
                      decoration: const InputDecoration(
                        counterText: '',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OtpDigitsFormatter extends TextInputFormatter {
  const _OtpDigitsFormatter(this.maxLength);

  final int maxLength;

  static const _arabicIndicDigits = '٠١٢٣٤٥٦٧٨٩';
  static const _easternArabicDigits = '۰۱۲۳۴۵۶۷۸۹';

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = StringBuffer();

    for (final rune in newValue.text.runes) {
      final character = String.fromCharCode(rune);
      final western = int.tryParse(character);
      final arabicIndic = _arabicIndicDigits.indexOf(character);
      final easternArabic = _easternArabicDigits.indexOf(character);

      if (western != null) {
        digits.write(western);
      } else if (arabicIndic >= 0) {
        digits.write(arabicIndic);
      } else if (easternArabic >= 0) {
        digits.write(easternArabic);
      }

      if (digits.length >= maxLength) break;
    }

    final text = digits.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
