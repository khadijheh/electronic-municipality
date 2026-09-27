import 'package:flutter/material.dart' hide Text;
import 'package:electronic_municipality_final/l10n/localized_text.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/di.dart';
import '../../../../core/repositories/auth_repository.dart';
import '../../../../shared/widgets/citizen_verification_notice.dart';
import '../../../../shared/widgets/municipality_widgets.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key, this.authRepository});

  final AuthRepository? authRepository;

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  late final AuthRepository _authRepository;
  CitizenVerificationStatus? _verificationStatus;

  @override
  void initState() {
    super.initState();
    _authRepository = widget.authRepository ?? DI.auth;
    final currentUser = _authRepository.currentUser;
    _verificationStatus = currentUser?.isCitizen == true
        ? currentUser!.citizenVerificationStatus
        : null;
    _refreshVerificationStatus();
  }

  Future<void> _refreshVerificationStatus() async {
    final currentUser = _authRepository.currentUser;
    if (currentUser == null || !currentUser.isCitizen) return;

    try {
      final user = await _authRepository.getCurrentUser();
      if (mounted) {
        setState(() {
          _verificationStatus = user.citizenVerificationStatus;
        });
      }
    } catch (_) {
      // The last known status remains visible; service requests still enforce
      // verification on the server.
    }
  }

  Future<void> _openVerification() async {
    await Navigator.of(context).pushNamed(AppRoutes.profile);
    if (mounted) await _refreshVerificationStatus();
  }

  @override
  Widget build(BuildContext context) {
    final verificationStatus = _verificationStatus;
    return ListView(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
        children: [
          const PageHeader(
            title: 'المعاملات',
            subtitle: 'متابعة الطلبات الرسمية',
          ),
          if (verificationStatus != null &&
              verificationStatus != CitizenVerificationStatus.verified) ...[
            const SizedBox(height: 14),
            CitizenVerificationNotice(
              status: verificationStatus,
              onAction:
                  verificationStatus == CitizenVerificationStatus.pending
                      ? _refreshVerificationStatus
                      : _openVerification,
            ),
          ],
          const SizedBox(height: 24),
          const TransactionCard(
              status: 'قيد المراجعة',
              title: 'طلب رخصة بناء',
              id: 'TRX-2023-441',
              icon: Icons.apartment_outlined),
          const SizedBox(height: 14),
          const TransactionCard(
              status: 'مكتملة',
              title: 'إخراج قيد عقاري',
              id: 'TRX-2023-396',
              icon: Icons.description_outlined,
              done: true),
          const SizedBox(height: 14),
          const TransactionCard(
              status: 'بانتظار الدفع',
              title: 'تسديد رسوم النظافة',
              id: 'TRX-2023-358',
              icon: Icons.payments_outlined),
        ]);
  }
}

class TransactionCard extends StatelessWidget {
  const TransactionCard(
      {super.key,
      required this.status,
      required this.title,
      required this.id,
      required this.icon,
      this.done = false});

  final String status;
  final String title;
  final String id;
  final IconData icon;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        child: Row(children: [
          CircleIcon(
              icon: icon,
              color: done ? const Color(0xFFDDE7E0) : AppColors.surfaceMuted,
              iconColor: done ? AppColors.primary : AppColors.gold),
          const SizedBox(width: 16),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  id,
                  translate: false,
                  style: const TextStyle(color: AppColors.muted),
                )
              ])),
          StatusPill(
              label: status, color: done ? AppColors.primary : AppColors.gold)
        ]));
  }
}
