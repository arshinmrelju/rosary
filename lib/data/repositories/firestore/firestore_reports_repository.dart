import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/models/prayer_report.dart';
import '../../firebase/firestore_paths.dart';
import '../reports_repository.dart';

class FirestoreReportsRepository implements ReportsRepository {
  const FirestoreReportsRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<List<PrayerReport>> fetchAll({ReportStatus? status}) async {
    Query<Map<String, dynamic>> query =
        _firestore.collection(FirestorePaths.reports);
    if (status != null) {
      query = query.where('status', isEqualTo: status.key);
    }
    final snapshot = await query.orderBy('createdAt', descending: true).get();
    return snapshot.docs
        .map((doc) => PrayerReport.fromMap(doc.id, doc.data()))
        .toList();
  }

  @override
  Future<int> countPending() async {
    final snapshot = await _firestore
        .collection(FirestorePaths.reports)
        .where('status', isEqualTo: ReportStatus.pending.key)
        .get();
    return snapshot.docs.length;
  }

  @override
  Future<void> review(
    String reportId, {
    ReportStatus status = ReportStatus.reviewed,
  }) async {
    await _firestore
        .collection(FirestorePaths.reports)
        .doc(reportId)
        .update(<String, dynamic>{'status': status.key});
  }

  @override
  Future<void> dismiss(String reportId) async {
    await review(reportId, status: ReportStatus.dismissed);
  }

  @override
  Future<ReportOutcome> submit(PrayerReport report) async {
    final reason = report.reason.trim();
    if (reason.isEmpty || reason.length > 80) return ReportOutcome.invalid;

    // Always pending on write; sanctioned by the rules.
    final data = report.copyWith(status: ReportStatus.pending).toMap();
    try {
      final doc = _firestore.collection(FirestorePaths.reports).doc();
      await doc.set(data);
      return ReportOutcome.success;
    } catch (e) {
      return ReportOutcome.failure;
    }
  }
}