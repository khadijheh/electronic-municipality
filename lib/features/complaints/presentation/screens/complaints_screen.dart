import 'package:flutter/material.dart' hide Text;
import 'package:image_picker/image_picker.dart';

import '../../../../l10n/localized_text.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/di.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/repositories/auth_repository.dart';
import '../../../../shared/widgets/citizen_verification_notice.dart';
import '../../../../shared/widgets/municipality_widgets.dart';
import '../../data/models/complaint_models.dart';
import '../../domain/complaints_repository.dart';
import 'complaint_details_screen.dart';
import 'complaint_location_picker_screen.dart';

typedef ComplaintImagePicker = Future<List<ComplaintAttachment>> Function();
typedef ComplaintLocationSelector = Future<ComplaintLocation?> Function(
  BuildContext context,
  ComplaintLocation? initialLocation,
);

class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({
    super.key,
    this.repository,
    this.authRepository,
    this.municipalityId,
    this.imagePicker,
    this.locationSelector,
  });

  final ComplaintsRepository? repository;
  final AuthRepository? authRepository;
  final int? municipalityId;
  final ComplaintImagePicker? imagePicker;
  final ComplaintLocationSelector? locationSelector;

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> {
  static const int _reportsPerPage = 15;

  final _title = TextEditingController();
  final _description = TextEditingController();
  final _textLocation = TextEditingController();
  final _latitude = TextEditingController();
  final _longitude = TextEditingController();
  final _devicePicker = ImagePicker();

  late final ComplaintsRepository _repository;
  late final AuthRepository _authRepository;
  int? _municipalityId;
  CitizenVerificationStatus? _verificationStatus;
  List<ComplaintCategory> _categories = const [];
  List<ComplaintReport> _reports = const [];
  ComplaintReportsPage? _reportsPage;
  List<ComplaintAttachment> _pendingImages = const [];
  ComplaintReport? _draft;
  int? _categoryGroupId;
  int? _categoryId;
  int _mode = 0;
  bool _loading = true;
  bool _loadingMoreReports = false;
  bool _busy = false;
  String? _pageError;
  String? _formError;
  Map<String, List<String>> _fieldErrors = const {};

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? DI.complaints;
    _authRepository = widget.authRepository ?? DI.auth;
    final currentUser = _authRepository.currentUser;
    _municipalityId =
        widget.municipalityId ?? _municipalityIdFromUser(currentUser);
    _verificationStatus = currentUser?.isCitizen == true
        ? currentUser!.citizenVerificationStatus
        : null;
    _load();
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _textLocation.dispose();
    _latitude.dispose();
    _longitude.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _pageError = null;
    });
    final errors = <String>{};

    try {
      final categories = await _repository.getCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _categoryGroupId = _groupIdForCategory(categories, _categoryId);
      });
    } catch (error, stackTrace) {
      debugPrint('LOAD COMPLAINT CATEGORIES ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);
      errors.add(_messageFor(error));
    }

    try {
      final reportsPage = await _repository.getReportsPage(
        perPage: _reportsPerPage,
      );
      if (!mounted) return;
      setState(() {
        _reports = reportsPage.items;
        _reportsPage = reportsPage;
      });
    } catch (error, stackTrace) {
      debugPrint('LOAD COMPLAINT REPORTS ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);
      errors.add(_messageFor(error));
    }

    await _refreshVerificationStatus();
    if (!mounted) return;
    setState(() {
      _pageError = errors.isEmpty ? null : errors.join('\n');
      _loading = false;
    });
  }

  Future<void> _refreshVerificationStatus() async {
    final currentUser = _authRepository.currentUser;
    if (currentUser == null || !currentUser.isCitizen) return;

    try {
      final user = await _authRepository.getCurrentUser();
      if (!mounted) return;
      setState(() {
        _verificationStatus = user.citizenVerificationStatus;
        _municipalityId =
            widget.municipalityId ?? _municipalityIdFromUser(user);
      });
    } catch (error, stackTrace) {
      debugPrint('LOAD CITIZEN VERIFICATION ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _refreshReports() async {
    try {
      final reportsPage = await _repository.getReportsPage(
        perPage: _reportsPerPage,
      );
      if (mounted) {
        setState(() {
          _reports = reportsPage.items;
          _reportsPage = reportsPage;
          _pageError = null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _pageError = _messageFor(error));
    }
  }

  Future<void> _loadMoreReports() async {
    final currentPage = _reportsPage;
    if (_loadingMoreReports || currentPage == null || !currentPage.hasNextPage) {
      return;
    }

    setState(() => _loadingMoreReports = true);
    try {
      final nextPage = await _repository.getReportsPage(
        page: currentPage.currentPage + 1,
        perPage: _reportsPerPage,
      );
      if (!mounted) return;
      setState(() {
        _reports = List<ComplaintReport>.unmodifiable(
          <ComplaintReport>[..._reports, ...nextPage.items],
        );
        _reportsPage = nextPage;
        _pageError = null;
      });
    } catch (error) {
      if (mounted) setState(() => _pageError = _messageFor(error));
    } finally {
      if (mounted) setState(() => _loadingMoreReports = false);
    }
  }

  ComplaintDraftInput _input() => ComplaintDraftInput(
        municipalityId: _municipalityId,
        categoryId: _categoryId,
        title: _title.text,
        description: _description.text,
        textLocation: _textLocation.text,
        latitude: _coordinate(_latitude.text),
        longitude: _coordinate(_longitude.text),
      );

  Future<void> _save({required bool submit}) async {
    if (_busy) return;
    if (submit &&
        _verificationStatus != null &&
        _verificationStatus != CitizenVerificationStatus.verified) {
      setState(() {
        _formError = _verificationMessage(_verificationStatus!);
        _fieldErrors = const {};
        _pageError = null;
      });
      return;
    }
    final input = _input();
    final errors =
        submit ? input.submissionErrors() : const <String, List<String>>{};
    if (errors.isNotEmpty) {
      setState(() {
        _fieldErrors = errors;
        _formError = 'أكمل الحقول المطلوبة قبل إرسال الشكوى.';
      });
      return;
    }

    setState(() {
      _busy = true;
      _formError = null;
      _fieldErrors = const {};
      _pageError = null;
    });
    try {
      final currentDraft = _draft;
      var report = currentDraft == null
          ? await _repository.createDraft(input)
          : await _repository.updateDraft(
              report: currentDraft,
              input: input,
            );

      // Store the id before uploading. A failed upload can then be retried
      // without creating a second draft.
      if (!mounted) return;
      setState(() => _draft = report);

      if (_pendingImages.isNotEmpty) {
        await _repository.uploadImages(report: report, images: _pendingImages);
        if (!mounted) return;
        setState(() => _pendingImages = const []);
        report = await _repository.getReport(report.id);
        if (!mounted) return;
        setState(() => _draft = report);
      }

      if (submit) {
        await _repository.submitDraft(report);
        if (!mounted) return;
        _clearEditor();
        setState(() => _mode = 1);
        _success('تم إرسال الشكوى بنجاح.');
      } else {
        _success('تم حفظ المسودة.');
      }
      await _refreshReports();
    } catch (error, stackTrace) {
      debugPrint('SAVE COMPLAINT ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() {
        _formError = _messageFor(error);
        _fieldErrors = error is ApiException ? error.errors : const {};
        if (error is ApiException && error.requiresCitizenVerification) {
          final cachedStatus = _authRepository
              .currentUser?.citizenVerificationStatus;
          _verificationStatus =
              cachedStatus == CitizenVerificationStatus.pending
                  ? CitizenVerificationStatus.pending
                  : CitizenVerificationStatus.notSubmitted;
        }
      });
      if (error is ApiException && error.requiresCitizenVerification) {
        await _refreshVerificationStatus();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickImages() async {
    try {
      final selected = widget.imagePicker == null
          ? await _pickFromDevice()
          : await widget.imagePicker!();
      if (selected.isEmpty || !mounted) return;
      final combined = <ComplaintAttachment>[..._pendingImages, ...selected];
      ComplaintAttachment.validateSelection(
        combined,
        existingCount: _draft?.images.length ?? 0,
      );
      setState(() {
        _pendingImages = List.unmodifiable(combined);
        _formError = null;
      });
    } catch (error) {
      if (mounted) setState(() => _formError = _messageFor(error));
    }
  }

  Future<List<ComplaintAttachment>> _pickFromDevice() async {
    final files = await _devicePicker.pickMultiImage(
      maxWidth: 2400,
      maxHeight: 2400,
      imageQuality: 85,
    );
    final result = <ComplaintAttachment>[];
    for (final file in files) {
      result.add(ComplaintAttachment(
          name: file.name, bytes: await file.readAsBytes()));
    }
    return result;
  }

  Future<void> _pickLocation() async {
    final latitude = _coordinate(_latitude.text);
    final longitude = _coordinate(_longitude.text);
    final initial = latitude == null || longitude == null
        ? null
        : ComplaintLocation(latitude: latitude, longitude: longitude);

    final locationSelector = widget.locationSelector;
    final selectionFuture = locationSelector == null
        ? Navigator.of(context).push<ComplaintLocation>(
            MaterialPageRoute<ComplaintLocation>(
              builder: (_) => ComplaintLocationPickerScreen(
                initialLocation: initial,
              ),
            ),
          )
        : locationSelector(context, initial);
    final selected = await selectionFuture;
    if (selected == null || !mounted) return;

    final errors = Map<String, List<String>>.of(_fieldErrors)
      ..remove('latitude')
      ..remove('longitude')
      ..remove('text_location');
    final placeDescription = selected.placeDescription?.trim();
    setState(() {
      _latitude.text = selected.latitude.toStringAsFixed(6);
      _longitude.text = selected.longitude.toStringAsFixed(6);
      if (_textLocation.text.trim().isEmpty &&
          placeDescription != null &&
          placeDescription.isNotEmpty) {
        _textLocation.text = placeDescription;
      }
      _fieldErrors = Map.unmodifiable(errors);
      _formError = null;
    });
  }

  Future<void> _edit(ComplaintReport summary) async {
    setState(() => _busy = true);
    try {
      final report = await _repository.getReport(summary.id);
      if (!mounted) return;
      if (!report.canEdit) {
        setState(() => _pageError = 'لا يمكن تعديل الشكوى بعد إرسالها.');
        return;
      }
      _categoryId = report.categoryId;
      _categoryGroupId = _groupIdForCategory(_categories, report.categoryId);
      _title.text = report.title ?? '';
      _description.text = report.description ?? '';
      _textLocation.text = report.textLocation ?? '';
      _latitude.text = report.latitude?.toString() ?? '';
      _longitude.text = report.longitude?.toString() ?? '';
      setState(() {
        _draft = report;
        _pendingImages = const [];
        _fieldErrors = const {};
        _formError = null;
        _mode = 0;
      });
    } catch (error) {
      if (mounted) setState(() => _pageError = _messageFor(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openDetails(ComplaintReport report) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ComplaintDetailsScreen(
          summary: report,
          repository: _repository,
        ),
      ),
    );
    if (mounted) await _refreshReports();
  }

  Future<void> _deleteDraft(ComplaintReport report) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المسودة'),
        content: const Text('هل تريد حذف هذه المسودة نهائيًا؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حذف')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _repository.deleteDraft(report);
      if (_draft?.id == report.id) _clearEditor();
      await _refreshReports();
      if (mounted) _success('تم حذف المسودة.');
    } catch (error) {
      if (mounted) setState(() => _pageError = _messageFor(error));
    }
  }

  Future<void> _deleteImage(ComplaintImage image) async {
    final report = _draft;
    if (report == null || _busy) return;
    setState(() => _busy = true);
    try {
      await _repository.deleteImage(report: report, imageId: image.id);
      final refreshed = await _repository.getReport(report.id);
      if (mounted) setState(() => _draft = refreshed);
    } catch (error) {
      if (mounted) setState(() => _formError = _messageFor(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _clearEditor() {
    _draft = null;
    _categoryGroupId = null;
    _categoryId = null;
    _title.clear();
    _description.clear();
    _textLocation.clear();
    _latitude.clear();
    _longitude.clear();
    _pendingImages = const [];
    _fieldErrors = const {};
    _formError = null;
  }

  static int? _groupIdForCategory(
    List<ComplaintCategory> groups,
    int? categoryId,
  ) {
    if (categoryId == null) return null;
    for (final group in groups) {
      if (group.children.any((item) => item.id == categoryId)) {
        return group.id;
      }
    }
    return null;
  }

  List<ComplaintCategory> get _selectedCategoryTypes {
    for (final group in _categories) {
      if (group.id == _categoryGroupId) return group.children;
    }
    return const <ComplaintCategory>[];
  }

  void _selectCategoryGroup(int? value) {
    setState(() {
      _categoryGroupId = value;
      _categoryId = null;
    });
  }

  void _selectCategory(int? value) {
    final errors = Map<String, List<String>>.of(_fieldErrors)
      ..remove('category_id');
    setState(() {
      _categoryId = value;
      _fieldErrors = Map.unmodifiable(errors);
      _formError = null;
    });
  }

  String? _errorFor(String field) {
    final values = _fieldErrors[field];
    return values == null || values.isEmpty ? null : values.first;
  }

  static int? _municipalityIdFromUser(AuthUser? user) {
    final profile = user?.citizenProfile;
    final direct = _asInt(profile?['municipality_id']);
    if (direct != null) return direct;
    final municipality = profile?['municipality'];
    return municipality is Map ? _asInt(municipality['id']) : null;
  }

  Future<void> _openVerification() async {
    await Navigator.of(context).pushNamed(AppRoutes.profile);
    if (mounted) await _refreshVerificationStatus();
  }

  void _success(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _mode == 1 ? _refreshReports : _load,
      color: AppColors.primary,
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        children: [
          const SizedBox(height: 12),
          const PageHeader(
            title: 'الشكاوى',
            subtitle: 'أنشئ مسودة، أرفق الصور، ثم أرسلها للبلدية',
            dense: true,
          ),
          if (_verificationStatus != null &&
              _verificationStatus != CitizenVerificationStatus.verified) ...[
            const SizedBox(height: 14),
            CitizenVerificationNotice(
              status: _verificationStatus!,
              onAction:
                  _verificationStatus == CitizenVerificationStatus.pending
                      ? _refreshVerificationStatus
                      : _openVerification,
            ),
          ],
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
                child: _ModeButton(
              label: _draft == null ? 'بلاغ جديد' : 'تعديل المسودة',
              selected: _mode == 0,
              onTap: () => setState(() => _mode = 0),
            )),
            const SizedBox(width: 12),
            Expanded(
                child: _ModeButton(
              label: 'سجل الشكاوى',
              selected: _mode == 1,
              onTap: () => setState(() => _mode = 1),
            )),
          ]),
          if (_loading) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(color: AppColors.primary),
          ],
          if (_pageError != null) ...[
            const SizedBox(height: 16),
            _Notice(message: _pageError!, retry: _load),
          ],
          const SizedBox(height: 18),
          if (_mode == 0) _buildEditor() else _buildHistory(),
        ],
      ),
    );
  }

  Widget _buildEditor() {
    final canEdit = _draft?.canEdit ?? true;
    final existingImages = _draft?.images ?? const <ComplaintImage>[];
    final imageCount = existingImages.length + _pendingImages.length;
    return AppPanel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(
              child: Text(
            _draft == null
                ? 'إضافة شكوى جديدة'
                : 'تعديل المسودة #${_draft!.id}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          )),
          if (_draft != null)
            StatusPill(
              label: _draft!.status.label,
              color: _statusColor(_draft!.status.key),
              pale: true,
            ),
        ]),
        const SizedBox(height: 16),
        if (_municipalityId == null) ...[
          const _Notice(
              message:
                  'تعذر تحديد بلديتك من الملف الشخصي. حدّث بيانات الحساب قبل الإرسال.'),
          const SizedBox(height: 12),
        ],
        if (_formError != null) ...[
          _Notice(message: _formError!),
          const SizedBox(height: 12),
        ],
        DropdownButtonFormField<int>(
          key: const ValueKey('complaint_category_group_field'),
          value: _categories.any((item) => item.id == _categoryGroupId)
              ? _categoryGroupId
              : null,
          isExpanded: true,
          decoration: _decoration(
            'مجال الشكوى',
            'اختر المجال الرئيسي',
            null,
          ),
          items: _categories
              .map((item) =>
                  DropdownMenuItem(value: item.id, child: Text(item.name)))
              .toList(),
          onChanged: canEdit && !_busy && !_loading
              ? _selectCategoryGroup
              : null,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          key: const ValueKey('complaint_category_field'),
          value: _selectedCategoryTypes.any((item) => item.id == _categoryId)
              ? _categoryId
              : null,
          isExpanded: true,
          decoration: _decoration(
            'نوع الشكوى',
            _categoryGroupId == null
                ? 'اختر المجال أولًا'
                : 'اختر نوع المشكلة',
            _errorFor('category_id'),
          ),
          items: _selectedCategoryTypes
              .map((item) =>
                  DropdownMenuItem(value: item.id, child: Text(item.name)))
              .toList(),
          onChanged: canEdit &&
                  !_busy &&
                  !_loading &&
                  _categoryGroupId != null
              ? _selectCategory
              : null,
        ),
        const SizedBox(height: 12),
        _Field(
            key: const ValueKey('complaint_title_field'),
            controller: _title,
            label: 'العنوان',
            hint: 'أدخل عنوانًا واضحًا',
            error: _errorFor('title'),
            enabled: canEdit && !_busy),
        const SizedBox(height: 12),
        _Field(
            key: const ValueKey('complaint_description_field'),
            controller: _description,
            label: 'الوصف',
            hint: 'اكتب تفاصيل المشكلة',
            error: _errorFor('description'),
            enabled: canEdit && !_busy,
            lines: 4),
        const SizedBox(height: 12),
        _Field(
            key: const ValueKey('complaint_text_location_field'),
            controller: _textLocation,
            label: 'وصف الموقع (اختياري)',
            hint: 'مثال: المزة، الشارع الرئيسي',
            error: _errorFor('text_location'),
            enabled: canEdit && !_busy),
        const SizedBox(height: 12),
        _LocationField(
          latitude: _coordinate(_latitude.text),
          longitude: _coordinate(_longitude.text),
          latitudeError: _errorFor('latitude'),
          longitudeError: _errorFor('longitude'),
          enabled: canEdit && !_busy,
          onSelect: _pickLocation,
        ),
        const SizedBox(height: 18),
        Row(children: [
          const Expanded(
              child: Text('صور الشكوى (اختياري)',
                  style: TextStyle(fontWeight: FontWeight.w800))),
          Text('$imageCount/${ComplaintAttachment.maxCount}',
              style: const TextStyle(color: AppColors.muted)),
        ]),
        const SizedBox(height: 5),
        const Text('JPG أو PNG، حتى 5MB لكل صورة.',
            style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
        if (existingImages.isNotEmpty || _pendingImages.isNotEmpty) ...[
          const SizedBox(height: 10),
          for (final image in existingImages)
            ListTile(
              dense: true,
              leading: const Icon(Icons.image_outlined),
              title: Text(image.name ?? 'صورة مرفقة #${image.id}'),
              trailing: canEdit
                  ? IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: AppColors.danger),
                      onPressed: () => _deleteImage(image))
                  : null,
            ),
          for (var index = 0; index < _pendingImages.length; index++)
            ListTile(
              dense: true,
              leading: const Icon(Icons.add_photo_alternate_outlined,
                  color: AppColors.info),
              title: Text(_pendingImages[index].name),
              subtitle: const Text('ستُرفع بعد حفظ المسودة'),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: canEdit
                    ? () => setState(() {
                          final updated =
                              List<ComplaintAttachment>.of(_pendingImages)
                                ..removeAt(index);
                          _pendingImages = List.unmodifiable(updated);
                        })
                    : null,
              ),
            ),
        ],
        const SizedBox(height: 10),
        OutlinedButton.icon(
          key: const ValueKey('pick_complaint_images'),
          onPressed:
              canEdit && !_busy && imageCount < ComplaintAttachment.maxCount
                  ? _pickImages
                  : null,
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: const Text('إضافة صور'),
        ),
        const SizedBox(height: 16),
        if (_busy) ...[
          const LinearProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 12),
        ],
        if (canEdit) ...[
          SecondaryButton(
            key: const ValueKey('save_complaint_draft'),
            label: _draft == null ? 'حفظ كمسودة' : 'تحديث المسودة',
            icon: Icons.save_outlined,
            onPressed: _busy ? null : () => _save(submit: false),
          ),
          const SizedBox(height: 10),
          PrimaryButton(
            key: const ValueKey('submit_complaint'),
            label: 'إرسال الشكوى',
            icon: Icons.send_rounded,
            onPressed: _busy || _municipalityId == null
                ? null
                : () => _save(submit: true),
          ),
        ],
        if (_draft != null)
          TextButton.icon(
            onPressed: _busy ? null : () => setState(_clearEditor),
            icon: const Icon(Icons.close),
            label: const Text('إلغاء التعديل وبدء شكوى جديدة'),
          ),
      ]),
    );
  }

  Widget _buildHistory() {
    return AppPanel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const Expanded(
              child: Text('الشكاوى السابقة',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
          IconButton(
              onPressed: _refreshReports, icon: const Icon(Icons.refresh)),
        ]),
        const SizedBox(height: 10),
        if (_reports.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
                child: Text('لا توجد شكاوى حتى الآن.',
                    style: TextStyle(color: AppColors.muted))),
          )
        else ...[
          for (var index = 0; index < _reports.length; index++) ...[
            _ComplaintTile(
              report: _reports[index],
              onOpen: () => _openDetails(_reports[index]),
              onEdit:
                  _reports[index].canEdit ? () => _edit(_reports[index]) : null,
              onDelete: _reports[index].canEdit
                  ? () => _deleteDraft(_reports[index])
                  : null,
            ),
            if (index != _reports.length - 1) const SizedBox(height: 10),
          ],
          if ((_reportsPage?.total ?? 0) > _reports.length) ...[
            const SizedBox(height: 14),
            Text(
              'تم عرض ${_reports.length} من ${_reportsPage!.total} شكوى.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
            ),
          ],
          if (_reportsPage?.hasNextPage == true) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              key: const ValueKey('load_more_complaints'),
              onPressed: _loadingMoreReports ? null : _loadMoreReports,
              icon: _loadingMoreReports
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.expand_more_rounded),
              label: Text(
                _loadingMoreReports ? 'جارٍ تحميل المزيد...' : 'تحميل المزيد',
              ),
            ),
          ],
        ],
      ]),
    );
  }
}

class _ComplaintTile extends StatelessWidget {
  const _ComplaintTile({
    required this.report,
    required this.onOpen,
    this.onEdit,
    this.onDelete,
  });
  final ComplaintReport report;
  final VoidCallback onOpen;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('open_complaint_${report.id}'),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      report.title ?? 'شكوى #${report.id}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  StatusPill(
                    label: report.status.label,
                    color: _statusColor(report.status.key),
                    pale: true,
                  ),
                ],
              ),
              if (report.description != null) ...[
                const SizedBox(height: 7),
                Text(
                  report.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted),
                ),
              ],
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    '#${report.id}',
                    style: const TextStyle(color: AppColors.subtle),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.photo_library_outlined,
                    size: 16,
                    color: AppColors.subtle,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${report.images.length}',
                    style: const TextStyle(color: AppColors.subtle),
                  ),
                  const Spacer(),
                  if (onEdit != null)
                    TextButton.icon(
                      key: ValueKey('edit_complaint_${report.id}'),
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('تعديل'),
                    ),
                  if (onDelete != null)
                    IconButton(
                      key: ValueKey('delete_complaint_${report.id}'),
                      onPressed: onDelete,
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppColors.danger,
                      ),
                    ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.chevron_left_rounded,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationField extends StatelessWidget {
  const _LocationField({
    required this.latitude,
    required this.longitude,
    required this.latitudeError,
    required this.longitudeError,
    required this.enabled,
    required this.onSelect,
  });

  final double? latitude;
  final double? longitude;
  final String? latitudeError;
  final String? longitudeError;
  final bool enabled;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final hasLocation = latitude != null && longitude != null;
    final error = latitudeError ?? longitudeError;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: error == null ? AppColors.border : AppColors.danger,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: Color(0xFFE1EEE8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.map_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'موقع الشكوى على الخريطة',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hasLocation
                          ? 'تم تحديد الموقع بنجاح'
                          : 'اضغط لاختيار الموقع الدقيق',
                      style: TextStyle(
                        color: hasLocation
                            ? AppColors.success
                            : AppColors.muted,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (hasLocation) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${latitude!.toStringAsFixed(6)}, ${longitude!.toStringAsFixed(6)}',
                key: const ValueKey('complaint_selected_coordinates'),
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
          if (error != null) ...[
            const SizedBox(height: 7),
            Text(
              error,
              style: const TextStyle(color: AppColors.danger, fontSize: 12),
            ),
          ],
          const SizedBox(height: 10),
          OutlinedButton.icon(
            key: const ValueKey('select_complaint_location'),
            onPressed: enabled ? onSelect : null,
            icon: Icon(
              hasLocation
                  ? Icons.edit_location_alt_outlined
                  : Icons.add_location_alt_outlined,
            ),
            label: Text(hasLocation ? 'تغيير الموقع' : 'اختيار من الخريطة'),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field(
      {super.key,
      required this.controller,
      required this.label,
      required this.hint,
      required this.enabled,
      this.error,
      this.lines = 1});
  final TextEditingController controller;
  final String label;
  final String hint;
  final String? error;
  final bool enabled;
  final int lines;

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        enabled: enabled,
        maxLines: lines,
        minLines: lines,
        textDirection: TextDirection.rtl,
        decoration: _decoration(label, hint, error),
      );
}

class _ModeButton extends StatelessWidget {
  const _ModeButton(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: selected ? AppColors.primary : AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(10)),
          child: Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: selected ? Colors.white : AppColors.text,
                  fontWeight: FontWeight.w800)),
        ),
      );
}

class _Notice extends StatelessWidget {
  const _Notice({required this.message, this.retry});
  final String message;
  final VoidCallback? retry;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: AppColors.danger.withOpacity(.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.danger.withOpacity(.35))),
        child: Row(children: [
          const Icon(Icons.error_outline, color: AppColors.danger),
          const SizedBox(width: 9),
          Expanded(
              child: Text(message,
                  style: const TextStyle(
                      color: AppColors.danger, fontWeight: FontWeight.w700))),
          if (retry != null)
            TextButton(onPressed: retry, child: const Text('إعادة المحاولة')),
        ]),
      );
}

InputDecoration _decoration(String label, String hint, String? error) {
  final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.border));
  return InputDecoration(
    labelText: label,
    hintText: hint,
    errorText: error,
    filled: true,
    fillColor: AppColors.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    border: border,
    enabledBorder: border,
    focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
  );
}

Color _statusColor(String key) {
  switch (key.toLowerCase()) {
    case 'draft':
      return AppColors.gold;
    case 'resolved':
    case 'closed':
      return AppColors.success;
    case 'rejected':
      return AppColors.danger;
    case 'submitted':
    case 'in_progress':
      return AppColors.info;
    default:
      return AppColors.primary;
  }
}

String _messageFor(Object error) => error is ApiException
    ? error.message
    : 'تعذر إكمال العملية. حاول مرة أخرى.';

String _verificationMessage(CitizenVerificationStatus status) {
  if (status == CitizenVerificationStatus.pending) {
    return 'طلب توثيق حسابك قيد المراجعة. يمكنك إرسال الشكوى بعد اعتماد الطلب من البلدية.';
  }
  return 'حساب المواطن غير موثق. يجب توثيق الحساب قبل إرسال الشكوى.';
}

double? _coordinate(String value) =>
    double.tryParse(value.trim().replaceAll(',', '.'));

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}
