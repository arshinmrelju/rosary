import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/formatters.dart';
import '../../../domain/models/daily_content.dart';
import '../../firebase/firestore_paths.dart';
import '../daily_content_repository.dart';

class FirestoreDailyContentRepository implements DailyContentRepository {
  const FirestoreDailyContentRepository(this._firestore);

  final FirebaseFirestore _firestore;

  /// Student-facing read: only published content is ever returned.
  ///
  /// The security rules already forbid students from reading drafts; this
  /// also treats `permission-denied` (a draft guarded by the rules) the same
  /// as "nothing published today", so the app degrades gracefully.
  @override
  Future<DailyContent?> fetch(DateTime date) async {
    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.dailyContent)
          .doc(dateKey(date))
          .get();
      if (!snapshot.exists) return null;
      final content = DailyContent.fromMap(snapshot.data()!);
      return content.published ? content : null;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') return null;
      rethrow;
    }
  }

  @override
  Future<DailyContent?> fetchDefault() => fetch(DateTime.now());

  @override
  Future<void> save(DailyContent content) async {
    await _firestore
        .collection(FirestorePaths.dailyContent)
        .doc(content.date)
        .set(content.toMap());
  }
}