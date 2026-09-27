import 'package:flutter/material.dart' hide Text;
import 'package:electronic_municipality_final/l10n/localized_text.dart';

import '../../../../app/design_system.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/municipality_widgets.dart';
import '../../data/models/inspector_document_model.dart';

/// "تفاصيل التحقق": ستة فحوصات صح/غير صح (مقابل VerificationItem في الويب).
class VerificationChecksList extends StatelessWidget {
  const VerificationChecksList({super.key, required this.document});

  final InspectorDocumentModel document;

  @override
  Widget build(BuildContext context) {
    final checks = <(String, bool)>[
      ('الملف موجود', document.fileExists),
      ('الوثيقة غير منتهية', document.isNotExpired),
      ('الوثيقة موقعة', document.isSigned),
      ('الهاش صحيح', document.isHashValid),
      ('التوقيع صحيح', document.isSignatureValid),
      ('الوثيقة صالحة', document.isValid),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: const [
            Icon(Icons.verified_user_outlined,
                color: AppColors.success, size: 20),
            SizedBox(width: AppSpacing.sm),
            Text(
              'تفاصيل التحقق',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        for (final check in checks) ...[
          _CheckTile(label: check.$1, ok: check.$2),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _CheckTile extends StatelessWidget {
  const _CheckTile({required this.label, required this.ok});

  final String label;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: AppColors.text),
            ),
          ),
          StatusPill(
            label: ok ? 'صحيح' : 'غير صحيح',
            color: ok ? AppColors.success : AppColors.danger,
            pale: true,
            icon: ok ? Icons.check_circle_outline : Icons.cancel_outlined,
          ),
        ],
      ),
    );
  }
}
