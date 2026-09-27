import '../data/models/complaint_models.dart';

abstract class ComplaintsRepository {
  Future<List<ComplaintCategory>> getCategories();

  Future<List<ComplaintReport>> getReports();

  Future<ComplaintReportsPage> getReportsPage({
    int page = 1,
    int perPage = 15,
  });

  Future<ComplaintReport> getReport(int reportId);

  Future<ComplaintReport> createDraft(ComplaintDraftInput input);

  Future<ComplaintReport> updateDraft({
    required ComplaintReport report,
    required ComplaintDraftInput input,
  });

  Future<void> uploadImages({
    required ComplaintReport report,
    required List<ComplaintAttachment> images,
  });

  Future<void> deleteImage({
    required ComplaintReport report,
    required int imageId,
  });

  Future<void> deleteDraft(ComplaintReport report);

  Future<ComplaintReport> submitDraft(ComplaintReport report);
}
