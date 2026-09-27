import 'dart:ui' as ui;

import 'package:flutter/material.dart' hide Text;
import 'package:electronic_municipality_final/l10n/localized_text.dart';
import 'package:electronic_municipality_final/l10n/app_localizations.dart';
import '../../app/design_system.dart';
import '../../app/theme/app_colors.dart';
import '../../core/constants/app_assets.dart';

class MunicipalityTextField extends StatelessWidget {
  const MunicipalityTextField({
    super.key,
    this.label,
    required this.hint,
    this.icon,
    this.trailingIcon,
    this.iconColor = AppColors.muted,
    this.obscureText = false,
    this.maxLines = 1,
  });

  final String? label;
  final String hint;
  final IconData? icon;
  final IconData? trailingIcon;
  final Color iconColor;
  final bool obscureText;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.text),
          ),
          const SizedBox(height: 8),
        ],
        TextField(
          textDirection: Directionality.of(context),
          obscureText: obscureText,
          maxLines: maxLines,
          minLines: maxLines,
          decoration: InputDecoration(
            hintText: context.tr(hint),
            hintStyle: const TextStyle(color: Color(0xFF9B9D9A)),
            filled: true,
            fillColor: AppColors.surface,
            prefixIcon:
                icon == null ? null : Icon(icon, color: iconColor, size: 27),
            suffixIcon: trailingIcon == null
                ? null
                : Icon(trailingIcon, color: AppColors.muted),
            contentPadding: EdgeInsets.symmetric(
                horizontal: 16, vertical: maxLines > 1 ? 18 : 0),
            border: OutlineInputBorder(
                borderSide: const BorderSide(color: AppColors.border),
                borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: AppColors.border),
                borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5),
                borderRadius: BorderRadius.circular(8)),
            constraints: BoxConstraints(minHeight: maxLines > 1 ? 118 : 56),
          ),
        ),
      ],
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton(
      {super.key,
      required this.label,
      this.icon,
      this.onPressed,
      this.dense = false});

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: dense ? 42 : 60,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle:
              TextStyle(fontSize: dense ? 14 : 20, fontWeight: FontWeight.w800),
          elevation: dense ? 0 : 8,
          shadowColor: Colors.black.withOpacity(0.18),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: dense ? 18 : 26),
              const SizedBox(width: 10),
            ],
            Flexible(
                child:
                    Text(label, maxLines: 1, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton(
      {super.key,
      required this.label,
      this.onPressed,
      this.icon,
      this.dense = false});

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: dense ? 44 : 58,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.gold,
          side: const BorderSide(color: AppColors.gold, width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle:
              TextStyle(fontSize: dense ? 13 : 18, fontWeight: FontWeight.w800),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: dense ? 17 : 22),
              const SizedBox(width: 8),
            ],
            Flexible(
                child:
                    Text(label, maxLines: 1, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }
}

class BackTextButton extends StatelessWidget {
  const BackTextButton(
      {super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.arrow_forward),
      label: Text(label),
      style: TextButton.styleFrom(
          foregroundColor: AppColors.gold,
          textStyle:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
    );
  }
}

class AuthCenterScaffold extends StatelessWidget {
  const AuthCenterScaffold({
    super.key,
    required this.child,
    required this.verticalPadding,
    this.horizontalPadding = AppSpacing.xl,
    this.decoratedBackground = false,
  });

  final Widget child;
  final EdgeInsets verticalPadding;
  final double horizontalPadding;
  final bool decoratedBackground;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (decoratedBackground) const _AuthBackgroundDecoration(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final minContentHeight =
                    (constraints.maxHeight - verticalPadding.vertical)
                        .clamp(0.0, double.infinity)
                        .toDouble();

                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.only(
                    left: horizontalPadding,
                    top: verticalPadding.top,
                    right: horizontalPadding,
                    bottom: verticalPadding.bottom,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: minContentHeight),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 620),
                        child: child,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthBackgroundDecoration extends StatelessWidget {
  const _AuthBackgroundDecoration();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            width: 800,
            height: 800,
            left: -160,
            top: -160,
            child: _BlurredCircle(
              color: Color(0x80F0EEE9),
              blurSigma: 32,
            ),
          ),
          Positioned(
            width: 600,
            height: 600,
            right: -80,
            bottom: -80,
            child: _BlurredCircle(
              color: Color(0x4DFFDEAE),
              blurSigma: 32,
            ),
          ),
        ],
      ),
    );
  }
}

class _BlurredCircle extends StatelessWidget {
  const _BlurredCircle({
    required this.color,
    required this.blurSigma,
  });

  final Color color;
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ui.ImageFilter.blur(
        sigmaX: blurSigma,
        sigmaY: blurSigma,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class AuthCard extends StatelessWidget {
  const AuthCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      padding: EdgeInsets.zero,
      elevation: true,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            child: Container(
                height: 8,
                decoration: const BoxDecoration(
                    gradient: LinearGradient(
                        colors: [Color(0xFFF5D39A), AppColors.gold]))),
          ),
          Padding(
              padding: const EdgeInsets.fromLTRB(28, 42, 28, 42), child: child),
        ],
      ),
    );
  }
}

class AppPanel extends StatelessWidget {
  const AppPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
    this.borderColor = AppColors.border,
    this.elevation = false,
    this.borderRadius = AppRadius.md,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color borderColor;
  final bool elevation;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(elevation ? 0.08 : 0.035),
              blurRadius: elevation ? 30 : 18,
              offset: Offset(0, elevation ? 12 : 6)),
        ],
      ),
      child: child,
    );
  }
}

class MunicipalityLogo extends StatelessWidget {
  const MunicipalityLogo({super.key, required this.size, this.framed = true});

  final double size;
  final bool framed;

  @override
  Widget build(BuildContext context) {
    final assetPath = Theme.of(context).brightness == Brightness.dark
        ? AppAssets.municipalityLogoDark
        : AppAssets.municipalityLogoLight;

    final image = Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      gaplessPlayback: true,
    );

    if (!framed) return image;

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.08),
      decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 14,
                offset: const Offset(0, 4))
          ]),
      child: ClipOval(child: image),
    );
  }
}

class CircleIcon extends StatelessWidget {
  const CircleIcon(
      {super.key,
      required this.icon,
      this.size = 58,
      this.color = AppColors.surfaceMuted,
      this.iconColor = AppColors.primary});

  final IconData icon;
  final double size;
  final Color color;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: size * 0.45));
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title,
        textAlign: TextAlign.start,
        style: const TextStyle(
            fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.text));
  }
}

class PageHeader extends StatelessWidget {
  const PageHeader(
      {super.key,
      required this.title,
      required this.subtitle,
      this.dense = false});

  final String title;
  final String subtitle;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(title,
          style: TextStyle(
              fontSize: dense ? 26 : 28, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      Text(subtitle,
          style: TextStyle(fontSize: dense ? 15 : 16, color: AppColors.muted)),
    ]);
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill(
      {super.key,
      required this.label,
      required this.color,
      this.pale = false,
      this.icon});

  final String label;
  final Color color;
  final bool pale;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: pale ? color.withOpacity(0.12) : color,
          borderRadius: BorderRadius.circular(6)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4)
        ],
        Text(label,
            style: TextStyle(
                color: pale ? color : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800)),
      ]),
    );
  }
}

class BadgeDot extends StatelessWidget {
  const BadgeDot({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(clipBehavior: Clip.none, children: [
      child,
      Positioned(
          top: -2,
          right: -1,
          child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                  color: AppColors.danger,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1))))
    ]);
  }
}

class FloatingCircleButton extends StatelessWidget {
  const FloatingCircleButton(
      {super.key,
      required this.icon,
      this.color = AppColors.surfaceMuted,
      this.iconColor = AppColors.primary,
      this.size = 54});

  final IconData icon;
  final Color color;
  final Color iconColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
        width: size,
        height: size,
        decoration:
            BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.14),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ]),
        child: Icon(icon, color: iconColor));
  }
}

class InfoNotice extends StatelessWidget {
  const InfoNotice({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(8)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.gold, size: 22),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text,
                  style:
                      const TextStyle(color: AppColors.muted, fontSize: 13))),
        ],
      ),
    );
  }
}

class ReadonlyField extends StatelessWidget {
  const ReadonlyField(
      {super.key,
      required this.label,
      required this.value,
      this.dropdown = false,
      this.translateValue = false});

  final String label;
  final String value;
  final bool dropdown;
  final bool translateValue;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
      const SizedBox(height: 6),
      Container(
        height: 45,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: const Color(0xFFDAD7CE))),
        child: Row(children: [
          if (dropdown)
            const Icon(Icons.keyboard_arrow_down, color: AppColors.muted),
          Expanded(
              child: Text(value,
                  translate: translateValue,
                  textAlign: TextAlign.end,
                  style:
                      const TextStyle(color: AppColors.muted, fontSize: 14))),
        ]),
      ),
    ]);
  }
}

class CardTitleRow extends StatelessWidget {
  const CardTitleRow(
      {super.key, required this.icon, required this.title, this.action});

  final IconData icon;
  final String title;
  final String? action;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, color: AppColors.gold),
      const SizedBox(width: 8),
      Expanded(
          child: Text(title,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
      if (action != null)
        Text(action!,
            style: const TextStyle(
                color: AppColors.gold, fontWeight: FontWeight.w800)),
    ]);
  }
}

class UploadBox extends StatelessWidget {
  const UploadBox(
      {super.key,
      required this.icon,
      required this.title,
      required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 16,
      ),
      decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.muted, style: BorderStyle.solid)),
      child: Column(children: [
        CircleIcon(icon: icon, size: 52, color: Colors.white),
        const SizedBox(height: 14),
        Text(title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        const SizedBox(height: 12),
        const Text('رفع ملف',
            style:
                TextStyle(color: AppColors.gold, fontWeight: FontWeight.w800)),
      ]),
    );
  }
}

class PasswordRulesBox extends StatelessWidget {
  const PasswordRulesBox({super.key});

  @override
  Widget build(BuildContext context) {
    const rules = ['8 أحرف على الأقل', 'حرف كبير وحرف صغير', 'رقم أو رمز خاص'];
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 16,
      ),
      decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE0DED6))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('يجب أن تحتوي كلمة المرور على:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        for (final rule in rules)
          Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                const Icon(Icons.check_circle_outline,
                    color: AppColors.muted, size: 22),
                const SizedBox(width: 10),
                Text(rule, style: const TextStyle(fontSize: 17))
              ]))
      ]),
    );
  }
}

class OtpBox extends StatelessWidget {
  const OtpBox({super.key, this.focused = false});
  final bool focused;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: 72,
        height: 78,
        child: TextField(
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(0),
                    borderSide: BorderSide(
                        color:
                            focused ? const Color(0xFF2A68D8) : AppColors.muted,
                        width: focused ? 4 : 1.2)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(0),
                    borderSide: BorderSide(
                        color:
                            focused ? const Color(0xFF2A68D8) : AppColors.muted,
                        width: focused ? 4 : 1.2)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(0),
                    borderSide:
                        const BorderSide(color: Color(0xFF2A68D8), width: 4))),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)));
  }
}
