import '../../../core/network/api_exception.dart';
import '../domain/complaints_repository.dart';
import 'complaints_remote_data_source.dart';
import 'models/complaint_models.dart';

class ComplaintsRepositoryApi implements ComplaintsRepository {
  const ComplaintsRepositoryApi({
    required ComplaintsRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final ComplaintsRemoteDataSource _remoteDataSource;

  @override
  Future<List<ComplaintCategory>> getCategories() {
    return _remoteDataSource.getCategories();
  }

  @override
  Future<List<ComplaintReport>> getReports() {
    return _remoteDataSource.getReports();
  }

  @override
  Future<ComplaintReportsPage> getReportsPage({
    int page = 1,
    int perPage = 15,
  }) {
    return _remoteDataSource.getReportsPage(
      page: page,
      perPage: perPage,
    );
  }

  @override
  Future<ComplaintReport> getReport(int reportId) {
    return _remoteDataSource.getReport(reportId);
  }

  @override
  Future<ComplaintReport> createDraft(ComplaintDraftInput input) {
    return _remoteDataSource.createDraft(input);
  }

  @override
  Future<ComplaintReport> updateDraft({
    required ComplaintReport report,
    required ComplaintDraftInput input,
  }) {
    _ensureEditable(report);
    return _remoteDataSource.updateDraft(
      reportId: report.id,
      input: input,
    );
  }

  @override
  Future<void> uploadImages({
    required ComplaintReport report,
    required List<ComplaintAttachment> images,
  }) {
    _ensureEditable(report);
    ComplaintAttachment.validateSelection(
      images,
      existingCount: report.images.length,
    );
    return _remoteDataSource.uploadImages(
      reportId: report.id,
      images: images,
    );
  }

  @override
  Future<void> deleteImage({
    required ComplaintReport report,
    required int imageId,
  }) {
    _ensureEditable(report);
    return _remoteDataSource.deleteImage(
      reportId: report.id,
      imageId: imageId,
    );
  }

  @override
  Future<void> deleteDraft(ComplaintReport report) {
    _ensureEditable(report);
    return _remoteDataSource.deleteDraft(report.id);
  }

  @override
  Future<ComplaintReport> submitDraft(ComplaintReport report) {
    _ensureEditable(report);
    return _remoteDataSource.submitDraft(report.id);
  }

  static void _ensureEditable(ComplaintReport report) {
    if (report.canEdit) return;
    throw const ApiException(
      kind: ApiExceptionKind.forbidden,
      message: 'لا يمكن تعديل الشكوى بعد إرسالها.',
      statusCode: 403,
    );
  }
}
