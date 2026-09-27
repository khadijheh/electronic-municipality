import 'package:flutter/material.dart' hide Text;
import 'package:electronic_municipality_final/l10n/localized_text.dart';
import 'package:electronic_municipality_final/l10n/app_localizations.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/di.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/repositories/auth_repository.dart';
import '../../../../shared/widgets/municipality_widgets.dart';
import 'identity_verification_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  AuthUser? _user;
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _user = DI.auth.currentUser;
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await DI.auth.getCurrentUser();
      if (mounted) setState(() => _user = user);
    } catch (error, stackTrace) {
      debugPrint('LOAD PROFILE ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _errorMessage = error is ApiException
              ? error.message
              : 'تعذر تحميل الملف الشخصي.';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openVerification() async {
    final submitted = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const IdentityVerificationScreen(),
      ),
    );

    if (submitted == true && mounted) {
      await _loadProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _loadProfile,
          color: AppColors.primary,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(child: _ProfileHeader()),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 620),
                      child: _buildContent(user),
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

  Widget _buildContent(AuthUser? user) {
    if (_isLoading && user == null) {
      return const Padding(
        padding: EdgeInsets.only(top: 120),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (user == null) {
      return _ProfileLoadError(
        message: _errorMessage ?? 'لا توجد جلسة مستخدم نشطة.',
        onRetry: _loadProfile,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_isLoading) ...[
          const LinearProgressIndicator(
            minHeight: 2,
            color: AppColors.primary,
            backgroundColor: AppColors.surfaceMuted,
          ),
          const SizedBox(height: 10),
        ],
        _ProfileSummary(user: user),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          _ProfileLoadError(
            message: _errorMessage!,
            onRetry: _loadProfile,
            compact: true,
          ),
        ],
        if (user.isCitizen) ...[
          const SizedBox(height: 14),
          _VerificationPanel(
            status: user.citizenVerificationStatus,
            isRefreshing: _isLoading,
            onStartVerification: _openVerification,
            onRefresh: _loadProfile,
          ),
        ],
        const SizedBox(height: 14),
        _PersonalDataPanel(user: user),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            const MunicipalityLogo(size: 44),
            const Spacer(),
            const Text(
              'الملف الشخصي',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            IconButton(
              tooltip: context.tr('رجوع'),
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileSummary extends StatelessWidget {
  const _ProfileSummary({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    final status = user.citizenVerificationStatus;
    final statusStyle = _VerificationStatusStyle.from(status);

    return AppPanel(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
      borderRadius: 14,
      borderColor: const Color(0xFFD4D7D3),
      elevation: true,
      child: Column(
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE4E1D9)),
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              color: AppColors.primary,
              size: 40,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            user.displayName,
            translate: false,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
          ),
          if (user.isCitizen) ...[
            const SizedBox(height: 9),
            StatusPill(
              label: statusStyle.shortLabel,
              color: statusStyle.color,
              pale: true,
              icon: statusStyle.icon,
            ),
          ],
          const SizedBox(height: 14),
          Column(
            children: [
              if (user.phoneNumber != null)
                _ContactItem(
                  icon: Icons.phone_outlined,
                  text: user.phoneNumber!,
                ),
              if (user.phoneNumber != null) const SizedBox(height: 6),
              _ContactItem(
                icon: Icons.email_outlined,
                text: user.email,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContactItem extends StatelessWidget {
  const _ContactItem({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: AppColors.muted),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            text,
            translate: false,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textDirection: TextDirection.ltr,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

class _VerificationPanel extends StatelessWidget {
  const _VerificationPanel({
    required this.status,
    required this.isRefreshing,
    required this.onStartVerification,
    required this.onRefresh,
  });

  final CitizenVerificationStatus status;
  final bool isRefreshing;
  final VoidCallback onStartVerification;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final style = _VerificationStatusStyle.from(status);
    final isNotSubmitted = status == CitizenVerificationStatus.notSubmitted;
    final isPending = status == CitizenVerificationStatus.pending;

    return AppPanel(
      padding: const EdgeInsets.all(18),
      borderRadius: 14,
      borderColor: style.color.withOpacity(0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: style.color.withOpacity(0.11),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(style.icon, color: style.color, size: 25),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      style.title,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      style.description,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13.5,
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isNotSubmitted) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                key: const ValueKey('start_identity_verification'),
                onPressed: onStartVerification,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.upload_file_outlined, size: 21),
                label: const Text(
                  'توثيق الحساب الآن',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ] else if (isPending) ...[
            const SizedBox(height: 14),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                key: const ValueKey('refresh_verification_status'),
                onPressed: isRefreshing ? null : onRefresh,
                icon: const Icon(Icons.refresh_rounded, size: 19),
                label: const Text('تحديث حالة الطلب'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.gold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _VerificationStatusStyle {
  const _VerificationStatusStyle({
    required this.shortLabel,
    required this.title,
    required this.description,
    required this.color,
    required this.icon,
  });

  factory _VerificationStatusStyle.from(
    CitizenVerificationStatus status,
  ) {
    switch (status) {
      case CitizenVerificationStatus.notSubmitted:
        return const _VerificationStatusStyle(
          shortLabel: 'غير موثق',
          title: 'توثيق الحساب مطلوب',
          description: 'للوصول إلى كافة الخدمات والمعاملات الرسمية، أرسل صور '
              'الهوية المطلوبة ليتم التحقق منها.',
          color: AppColors.danger,
          icon: Icons.error_outline_rounded,
        );
      case CitizenVerificationStatus.pending:
        return const _VerificationStatusStyle(
          shortLabel: 'قيد المراجعة',
          title: 'طلب التوثيق قيد المراجعة',
          description: 'تم استلام صور الهوية بنجاح. ستظهر حالة الحساب الموثق '
              'بعد اعتماد الطلب من البلدية.',
          color: AppColors.gold,
          icon: Icons.hourglass_top_rounded,
        );
      case CitizenVerificationStatus.verified:
        return const _VerificationStatusStyle(
          shortLabel: 'موثق',
          title: 'الحساب موثق',
          description: 'تم التحقق من بيانات هويتك، ويمكنك الآن الوصول إلى '
              'الخدمات والمعاملات الرسمية.',
          color: AppColors.success,
          icon: Icons.verified_rounded,
        );
    }
  }

  final String shortLabel;
  final String title;
  final String description;
  final Color color;
  final IconData icon;
}

class _PersonalDataPanel extends StatelessWidget {
  const _PersonalDataPanel({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    final profile = user.citizenProfile ?? user.employeeProfile ?? const {};
    final fields = <_ProfileFieldData>[
      _ProfileFieldData(
        label: 'الاسم الكامل (كما في الهوية)',
        value: user.fullName,
      ),
      if (user.isCitizen) ...[
        _ProfileFieldData(
          label: 'الرقم الوطني',
          value: _value(profile['national_id']),
        ),
        _ProfileFieldData(
          label: 'تاريخ الميلاد',
          value: _dateValue(profile['birth_date']),
        ),
        _ProfileFieldData(
          label: 'الجنس',
          value: _genderValue(profile['gender']),
          translateValue: true,
        ),
        _ProfileFieldData(
          label: 'مكان الولادة',
          value: _value(profile['place_of_birth']),
        ),
        _ProfileFieldData(
          label: 'الرعاية الخاصة',
          value: _booleanValue(profile['needs_special_care']),
          translateValue: true,
        ),
      ] else
        _ProfileFieldData(
          label: 'تاريخ التوظيف',
          value: _dateValue(profile['hire_date']),
        ),
    ];

    return AppPanel(
      padding: const EdgeInsets.all(18),
      borderRadius: 14,
      borderColor: const Color(0xFFD4D7D3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.badge_outlined, color: AppColors.gold, size: 25),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'البيانات الشخصية',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 30, color: AppColors.divider),
          _ProfileFieldGrid(fields: fields),
        ],
      ),
    );
  }

  static String _value(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? 'غير متوفر' : text;
  }

  static String _dateValue(Object? value) {
    final raw = _value(value);
    if (raw == 'غير متوفر') return raw;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    final month = parsed.month.toString().padLeft(2, '0');
    final day = parsed.day.toString().padLeft(2, '0');
    return '${parsed.year}/$month/$day';
  }

  static String _genderValue(Object? value) {
    final normalized = value?.toString().trim().toLowerCase();
    if (normalized == 'male') return 'ذكر';
    if (normalized == 'female') return 'أنثى';
    return _value(value);
  }

  static String _booleanValue(Object? value) {
    if (value is bool) return value ? 'نعم' : 'لا';
    if (value is num) return value == 0 ? 'لا' : 'نعم';
    final normalized = value?.toString().trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') return 'نعم';
    if (normalized == 'false' || normalized == '0') return 'لا';
    return 'غير متوفر';
  }
}

class _ProfileFieldData {
  const _ProfileFieldData({
    required this.label,
    required this.value,
    this.translateValue = false,
  });

  final String label;
  final String value;
  final bool translateValue;
}

class _ProfileFieldGrid extends StatelessWidget {
  const _ProfileFieldGrid({required this.fields});

  final List<_ProfileFieldData> fields;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 520 ? 2 : 1;
        final fieldWidth = columns == 2
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final field in fields)
              SizedBox(
                width: fieldWidth,
                child: ReadonlyField(
                  label: field.label,
                  value: field.value,
                  translateValue: field.translateValue,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ProfileLoadError extends StatelessWidget {
  const _ProfileLoadError({
    required this.message,
    required this.onRetry,
    this.compact = false,
  });

  final String message;
  final VoidCallback onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      padding: EdgeInsets.all(compact ? 14 : 20),
      borderRadius: 12,
      borderColor: AppColors.danger.withOpacity(0.25),
      child: Column(
        children: [
          if (!compact) ...[
            const Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: AppColors.muted,
            ),
            const SizedBox(height: 10),
          ],
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.danger,
              fontSize: 13.5,
            ),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }
}
