import 'package:flutter/material.dart' hide Text;
import 'package:electronic_municipality_final/l10n/localized_text.dart';
import 'package:electronic_municipality_final/l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/di.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/repositories/auth_repository.dart';
import '../../../../shared/widgets/municipality_widgets.dart';

enum _IdentitySide { front, back }

class IdentityVerificationScreen extends StatefulWidget {
  const IdentityVerificationScreen({super.key});

  @override
  State<IdentityVerificationScreen> createState() =>
      _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState
    extends State<IdentityVerificationScreen> {
  static const int _maximumPhotoSize = 4 * 1024 * 1024;
  static const Set<String> _allowedExtensions = {
    'jpg',
    'jpeg',
    'png',
  };

  final ImagePicker _picker = ImagePicker();

  CitizenIdentityPhoto? _frontPhoto;
  CitizenIdentityPhoto? _backPhoto;
  String? _errorMessage;
  bool _isSubmitting = false;

  bool get _canSubmit {
    return _frontPhoto != null && _backPhoto != null && !_isSubmitting;
  }

  Future<void> _selectPhoto(_IdentitySide side) async {
    final source = await _showImageSourceSheet();
    if (source == null || !mounted) return;

    try {
      final selectedFile = await _picker.pickImage(
        source: source,
        maxWidth: 2400,
        maxHeight: 2400,
        imageQuality: 85,
      );
      if (selectedFile == null || !mounted) return;

      final extension = _extensionOf(selectedFile.name);
      if (!_allowedExtensions.contains(extension)) {
        _showLocalError('صيغة الصورة غير مدعومة. استخدم JPG أو PNG.');
        return;
      }

      final bytes = await selectedFile.readAsBytes();
      if (bytes.lengthInBytes > _maximumPhotoSize) {
        _showLocalError('يجب ألا يتجاوز حجم كل صورة 4 ميغابايت.');
        return;
      }

      final photo = CitizenIdentityPhoto(
        name: selectedFile.name,
        bytes: bytes,
      );

      setState(() {
        if (side == _IdentitySide.front) {
          _frontPhoto = photo;
        } else {
          _backPhoto = photo;
        }
        _errorMessage = null;
      });
    } catch (error, stackTrace) {
      debugPrint('SELECT IDENTITY PHOTO ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        _showLocalError('تعذر اختيار الصورة. تحقق من صلاحيات الكاميرا والصور.');
      }
    }
  }

  Future<ImageSource?> _showImageSourceSheet() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'إضافة صورة الهوية',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  tileColor: AppColors.surfaceMuted,
                  leading: const Icon(
                    Icons.photo_camera_outlined,
                    color: AppColors.primary,
                  ),
                  title: const Text('التقاط صورة بالكاميرا'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                const SizedBox(height: 10),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  tileColor: AppColors.surfaceMuted,
                  leading: const Icon(
                    Icons.photo_library_outlined,
                    color: AppColors.primary,
                  ),
                  title: const Text('اختيار صورة من الجهاز'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _removePhoto(_IdentitySide side) {
    setState(() {
      if (side == _IdentitySide.front) {
        _frontPhoto = null;
      } else {
        _backPhoto = null;
      }
      _errorMessage = null;
    });
  }

  void _showLocalError(String message) {
    setState(() => _errorMessage = message);
  }

  Future<void> _submit() async {
    final frontPhoto = _frontPhoto;
    final backPhoto = _backPhoto;
    if (frontPhoto == null || backPhoto == null || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await DI.citizenVerification.uploadIdentityPhotos(
        frontPhoto: frontPhoto,
        backPhoto: backPhoto,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تم إرسال صور الهوية بنجاح، وسيتم إشعارك بعد مراجعتها.',
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (error, stackTrace) {
      debugPrint('UPLOAD IDENTITY PHOTOS ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _errorMessage = error is ApiException
              ? error.message
              : 'تعذر إرسال صور الهوية. حاول مرة أخرى.';
        });
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _VerificationHeader(),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _VerificationIntro(),
                        const SizedBox(height: 16),
                        _IdentityPhotoCard(
                          key: const ValueKey('front_identity_photo'),
                          title: 'الوجه الأمامي للهوية',
                          subtitle: 'تأكد من وضوح الصورة وكامل بيانات الهوية.',
                          photo: _frontPhoto,
                          onSelect: _isSubmitting
                              ? null
                              : () => _selectPhoto(_IdentitySide.front),
                          onRemove: _isSubmitting
                              ? null
                              : () => _removePhoto(_IdentitySide.front),
                        ),
                        const SizedBox(height: 14),
                        _IdentityPhotoCard(
                          key: const ValueKey('back_identity_photo'),
                          title: 'الوجه الخلفي للهوية',
                          subtitle: 'تأكد من ظهور كامل الهوية دون قص الحواف.',
                          photo: _backPhoto,
                          onSelect: _isSubmitting
                              ? null
                              : () => _selectPhoto(_IdentitySide.back),
                          onRemove: _isSubmitting
                              ? null
                              : () => _removePhoto(_IdentitySide.back),
                        ),
                        const SizedBox(height: 14),
                        const _PrivacyNotice(),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 14),
                          _VerificationError(message: _errorMessage!),
                        ],
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 54,
                          child: FilledButton(
                            key: const ValueKey(
                              'submit_identity_verification',
                            ),
                            onPressed: _canSubmit ? _submit : null,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  AppColors.primary.withOpacity(0.38),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'إرسال طلب التوثيق',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _extensionOf(String fileName) {
    final parts = fileName.toLowerCase().split('.');
    return parts.length < 2 ? '' : parts.last;
  }
}

class _VerificationHeader extends StatelessWidget {
  const _VerificationHeader();

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
              'توثيق الحساب',
              style: TextStyle(
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

class _VerificationIntro extends StatelessWidget {
  const _VerificationIntro();

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      padding: const EdgeInsets.all(18),
      borderRadius: 14,
      borderColor: const Color(0xFFD6D1C5),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleIcon(
            icon: Icons.verified_user_outlined,
            size: 52,
            color: Color(0xFFF5EFE1),
            iconColor: AppColors.gold,
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'أكمل توثيق هويتك',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'ارفع صورة واضحة للوجهين الأمامي والخلفي من هويتك. '
                  'تُراجع الصور من البلدية قبل تفعيل الحساب الموثق.',
                  style: TextStyle(
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
    );
  }
}

class _IdentityPhotoCard extends StatelessWidget {
  const _IdentityPhotoCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.photo,
    required this.onSelect,
    required this.onRemove,
  });

  final String title;
  final String subtitle;
  final CitizenIdentityPhoto? photo;
  final VoidCallback? onSelect;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final selectedPhoto = photo;

    return AppPanel(
      padding: const EdgeInsets.all(16),
      borderRadius: 14,
      borderColor: selectedPhoto == null ? AppColors.border : AppColors.success,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                selectedPhoto == null
                    ? Icons.badge_outlined
                    : Icons.check_circle_outline_rounded,
                color:
                    selectedPhoto == null ? AppColors.gold : AppColors.success,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: selectedPhoto == null
                ? _EmptyPhotoPreview(onTap: onSelect)
                : _SelectedPhotoPreview(
                    photo: selectedPhoto,
                    onReplace: onSelect,
                    onRemove: onRemove,
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPhotoPreview extends StatelessWidget {
  const _EmptyPhotoPreview({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: const ValueKey('empty_photo_preview'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 148,
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFD5D8D4),
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_a_photo_outlined,
              size: 34,
              color: AppColors.primary,
            ),
            SizedBox(height: 8),
            Text(
              'إضافة الصورة',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'JPG أو PNG — بحد أقصى 4MB',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedPhotoPreview extends StatelessWidget {
  const _SelectedPhotoPreview({
    required this.photo,
    required this.onReplace,
    required this.onRemove,
  });

  final CitizenIdentityPhoto photo;
  final VoidCallback? onReplace;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('selected_photo_preview'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.memory(
              photo.bytes,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onReplace,
                icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                label: const Text('استبدال'),
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              tooltip: context.tr('حذف الصورة'),
              onPressed: onRemove,
              color: AppColors.danger,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ),
      ],
    );
  }
}

class _PrivacyNotice extends StatelessWidget {
  const _PrivacyNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: 20,
            color: AppColors.success,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'تُستخدم صور الهوية للتحقق من الحساب فقط. تأكد من صحة '
              'الصور قبل الإرسال لأن الطلب سيصبح قيد المراجعة.',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 12.5,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerificationError extends StatelessWidget {
  const _VerificationError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.danger.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.danger,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.danger,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
