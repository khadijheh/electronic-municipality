abstract final class ComplaintEndpoints {
  static const String categories = 'ComplaintCategories';
  static const String reports = 'citizen/complaints';
  static const String drafts = 'citizen/complaints/drafts';
  static const String unifiedComplaints = 'unified-complaints';

  static String report(int reportId) => '$reports/$reportId';

  static String images(int reportId) => '${report(reportId)}/images';

  static String image(int reportId, int imageId) =>
      '${images(reportId)}/$imageId';

  static String submit(int reportId) => '${report(reportId)}/submit';
}
