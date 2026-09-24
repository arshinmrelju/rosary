import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/models/admin_log_entry.dart';
import '../../firebase/firestore_paths.dart';
import '../admin_log_repository.dart';

class FirestoreAdminLogRepository implements AdminLogRepository {
  const FirestoreAdminLogRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<void> log(
    String adminUserId,
    AdminLogAction action,
    String target,
  ) async {
    await _firestore.collection(FirestorePaths.adminLogs).add(
      AdminLogEntry(
        adminUserId: adminUserId,
        action: action,
        target: target,
        timestamp: DateTime.now(),
      ).toMap(),
    );
  }

  @override
  Future<List<AdminLogEntry>> fetchRecent({int limit = 50}) async {
    final snapshot = await _firestore
        .collection(FirestorePaths.adminLogs)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs
        .map((doc) => AdminLogEntry.fromMap(doc.id, doc.data()))
        .toList();
  }
}