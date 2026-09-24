import '../../domain/models/prayer_report.dart';

/// Given a [PrayerReport] submitted, whether Firestore accepted it.
enum ReportOutcome { success, invalid, duplicate, failure }

/// Admin + student reporting of prayer intentions.
abstract interface class ReportsRepository {
  /// All reports (usually filtered by the caller).
  Future<List<PrayerReport>> fetchAll({ReportStatus? status});

  /// Number of reports still awaiting review.
  Future<int> countPending();

  /// Marks a report as reviewed/resolved.
  Future<void> review(String reportId, {ReportStatus status = ReportStatus.reviewed});

  /// Silently dismisses a report without acting on the content.
  Future<void> dismiss(String reportId);

  /// Student-facing: creates a report. The status is forced to `pending`
  /// server-side.
  Future<ReportOutcome> submit(PrayerReport report);
}