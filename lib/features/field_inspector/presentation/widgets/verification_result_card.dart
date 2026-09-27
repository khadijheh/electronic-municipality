import 'package:flutter/material.dart' hide Text;
import 'package:electronic_municipality_final/l10n/localized_text.dart';

import '../../../../app/design_system.dart';
import '../../../../app/theme/app_colors.dart';

/// بطاقة "الوثيقة صالحة / غير صالحة" (مقابل Verification Result في الويب).
class VerificationResultCard extends StatelessWidget {
  const VerificationResultCard({super.key, required this.isValid});

  final bool isValid;

  @override
  Widget build(BuildContext context) {
    final color = isValid ? AppColors.success : AppColors.danger;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              isValid ? Icons.check_circle_outline : Icons.cancel_outlined,
              color: color,
              size: 30,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isValid ? 'الوثيقة صالحة' : 'الوثيقة غير صالحة',
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isValid
                      ? 'تم التحقق من صحة الوثيقة والتوقيع الإلكتروني.'
                      : 'تعذر اعتماد الوثيقة. يرجى التأكد من صلاحيتها.',
                  style: TextStyle(color: color, fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
