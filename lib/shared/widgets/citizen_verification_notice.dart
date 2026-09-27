import 'package:flutter/material.dart' hide Text;
import 'package:electronic_municipality_final/l10n/localized_text.dart';

import '../../app/theme/app_colors.dart';
import '../../core/repositories/auth_repository.dart';

class CitizenVerificationNotice extends StatelessWidget {
  const CitizenVerificationNotice({
    super.key,
    required this.status,
    required this.onAction,
  });

  final CitizenVerificationStatus status;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    if (status == CitizenVerificationStatus.verified) {
      return const SizedBox.shrink();
    }

    final pending = status == CitizenVerificationStatus.pending;
    final color = pending ? AppColors.gold : AppColors.danger;

    return Container(
      key: const ValueKey('citizen_verification_notice'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.11),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  pending
                      ? Icons.hourglass_top_rounded
                      : Icons.verified_user_outlined,
                  color: color,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      pending
                          ? 'توثيق الحساب قيد المراجعة'
                          : 'حساب المواطن غير موثق',
                      style: TextStyle(
                        color: color,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pending
                          ? 'يمكنك تجهيز المسودات، وسيصبح الإرسال متاحاً بعد اعتماد التوثيق من البلدية.'
                          : 'يمكنك تجهيز المسودة، لكن يجب توثيق حسابك قبل إرسال الشكاوى والمعاملات الرسمية.',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              key: const ValueKey('citizen_verification_notice_action'),
              onPressed: onAction,
              style: TextButton.styleFrom(foregroundColor: color),
              icon: Icon(
                pending ? Icons.refresh_rounded : Icons.arrow_forward_rounded,
                size: 19,
              ),
              label: Text(
                pending ? 'تحديث حالة التوثيق' : 'توثيق الحساب الآن',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
