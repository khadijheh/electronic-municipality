import 'package:flutter/material.dart' hide Text;
import 'package:electronic_municipality_final/l10n/localized_text.dart';
import 'package:electronic_municipality_final/l10n/app_localizations.dart';
import 'package:open_filex/open_filex.dart';

import '../../../../app/design_system.dart';
import '../../../../app/router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/di.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../shared/widgets/municipality_widgets.dart';
import '../../data/models/inspector_document_model.dart';
import '../widgets/document_info_list.dart';
import '../widgets/verification_checks_list.dart';
import '../widgets/verification_result_card.dart';
import 'qr_scanner_screen.dart';

/// شاشة المفتش الميداني: مسح QR -> تحقق -> نتيجة -> فتح PDF.
/// نقل لصفحة الويب FieldInspectorPage بنفس المنطق وبهوية الموبايل.
class FieldInspectorScreen extends StatefulWidget {
  const FieldInspectorScreen({super.key});

  @override
  State<FieldInspectorScreen> createState() => _FieldInspectorScreenState();
}

class _FieldInspectorScreenState extends State<FieldInspectorScreen> {
  final TextEditingController _codeController = TextEditingController();

  InspectorDocumentModel? _document;
  String _verifiedCode = '';
  String? _error;
  bool _isVerifying = false;
  bool _isOpeningDocument = false;
  bool _isLoggingOut = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    setState(() => _error = null);
    final raw = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        fullscreenDialog: true,
        builder: (_) => const QrScannerScreen(),
      ),
    );
    if (!mounted || raw == null) return;

    final code = extractVerificationCode(raw);
    if (code.isEmpty) {
      setState(() => _error = 'تعذر قراءة رمز التحقق من QR');
      return;
    }
    _codeController.text = code;
    await _verify(code);
  }

  Future<void> _verify([String? rawCode]) async {
    final code = extractVerificationCode(rawCode ?? _codeController.text);
    if (code.isEmpty) {
      setState(() => _error = 'يرجى مسح QR الوثيقة أولاً');
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _isVerifying = true;
      _error = null;
      _document = null;
    });

    try {
      final document = await DI.fieldInspector.verifyDocument(code);
      if (!mounted) return;
      setState(() {
        _document = document;
        _verifiedCode = code;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      if (error.isUnauthorized) {
        _goToLogin();
        return;
      }
      setState(() => _error = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'حدث خطأ أثناء التحقق من الوثيقة');
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _openDocument() async {
    if (_verifiedCode.isEmpty || _isOpeningDocument) return;

    setState(() {
      _isOpeningDocument = true;
      _error = null;
    });

    try {
      final path = await DI.fieldInspector.downloadDocument(_verifiedCode);
      final result = await OpenFilex.open(path);
      if (mounted && result.type != ResultType.done) {
        setState(() => _error =
            'تعذر فتح الوثيقة. تأكد من وجود تطبيق لعرض ملفات PDF على الجهاز.');
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      if (error.isUnauthorized) {
        _goToLogin();
        return;
      }
      setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'تعذر فتح وثيقة الخدمة');
    } finally {
      if (mounted) setState(() => _isOpeningDocument = false);
    }
  }

  void _reset() {
    _codeController.clear();
    setState(() {
      _document = null;
      _verifiedCode = '';
      _error = null;
    });
  }

  Future<void> _logout() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);
    try {
      await DI.auth.logout();
    } catch (_) {
      // تنتهي الجلسة محلياً حتى لو فشل إبلاغ الخادم.
    }
    if (mounted) _goToLogin();
  }

  void _goToLogin() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.login,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.lg),
                _ErrorBanner(
                  message: _error!,
                  onClose: () => setState(() => _error = null),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              AppPanel(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: _isVerifying
                    ? _buildVerifying()
                    : (_document == null ? _buildIdle() : _buildResult()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return AppPanel(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: PageHeader(
                  title: 'المفتش الميداني',
                  subtitle: 'التحقق من وثائق الخدمات باستخدام رمز QR',
                  dense: true,
                ),
              ),
              IconButton(
                tooltip: context.tr('تسجيل الخروج'),
                onPressed: _isLoggingOut ? null : _logout,
                icon: const Icon(Icons.logout_rounded, color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Align(
            alignment: AlignmentDirectional.centerStart,
            child: StatusPill(
              label: 'نظام التحقق من الوثائق',
              color: AppColors.success,
              pale: true,
              icon: Icons.verified_user_outlined,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: AppColors.mint.withOpacity(0.55),
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: const Icon(Icons.qr_code_scanner,
                color: AppColors.primary, size: 44),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const Text(
          'مسح QR وثيقة الخدمة',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          'وجّه كاميرا الجهاز نحو رمز QR الموجود على وثيقة الخدمة للتحقق من صلاحيتها وأصالتها.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, height: 1.6, color: AppColors.muted),
        ),
        const SizedBox(height: AppSpacing.xxl),
        PrimaryButton(
          label: 'مسح QR الوثيقة',
          icon: Icons.qr_code_scanner,
          onPressed: _scan,
        ),
        const SizedBox(height: AppSpacing.xxl),
        Row(
          children: const [
            Expanded(child: Divider(color: AppColors.divider)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                'أو إدخال الرمز يدويًا',
                style: TextStyle(fontSize: 12, color: AppColors.subtle),
              ),
            ),
            Expanded(child: Divider(color: AppColors.divider)),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: _codeController,
          textDirection: TextDirection.ltr,
          textInputAction: TextInputAction.search,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _verify(),
          decoration: InputDecoration(
            hintText: context.tr('أدخل رمز التحقق'),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SecondaryButton(
          label: 'تحقق',
          icon: Icons.search,
          onPressed: _codeController.text.trim().isEmpty ? null : _verify,
        ),
      ],
    );
  }

  Widget _buildVerifying() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.huge),
      child: Column(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3.5,
            ),
          ),
          SizedBox(height: AppSpacing.xl),
          Text(
            'جاري التحقق من الوثيقة...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'يتم التحقق من صحة التوقيع والهاش وصلاحية الوثيقة.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  Widget _buildResult() {
    final document = _document!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VerificationResultCard(isValid: document.isValid),
        const SizedBox(height: AppSpacing.xl),
        DocumentInfoList(document: document),
        const SizedBox(height: AppSpacing.xl),
        VerificationChecksList(document: document),
        const SizedBox(height: AppSpacing.lg),
        const Divider(color: AppColors.divider),
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(
          label: _isOpeningDocument
              ? 'جاري فتح الوثيقة...'
              : 'عرض وثيقة الخدمة',
          icon: Icons.description_outlined,
          onPressed: (_isOpeningDocument || !document.fileExists)
              ? null
              : _openDocument,
        ),
        const SizedBox(height: AppSpacing.md),
        SecondaryButton(
          label: 'مسح وثيقة أخرى',
          icon: Icons.qr_code_scanner,
          onPressed: _scan,
        ),
        const SizedBox(height: AppSpacing.sm),
        SecondaryButton(
          label: 'إعادة التحقق',
          onPressed: _reset,
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onClose});

  final String message;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.danger.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.error_outline,
                color: AppColors.danger, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.danger,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
          InkWell(
            onTap: onClose,
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(Icons.close, color: AppColors.danger, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
