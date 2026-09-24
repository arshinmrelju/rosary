import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/models/daily_content.dart';
import '../../firebase/firestore_paths.dart';
import '../admin_content_repository.dart';

class FirestoreAdminContentRepository implements AdminContentRepository {
  const FirestoreAdminContentRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<DailyContent?> fetch(String dateKey) async {
    final snapshot = await _firestore
        .collection(FirestorePaths.dailyContent)
        .doc(dateKey)
        .get();
    if (!snapshot.exists) return null;
    return DailyContent.fromMap(snapshot.data()!);
  }

  @override
  Future<List<DailyContent>> fetchRange(DateTime start, DateTime end) async {
    final query = await _firestore
        .collection(FirestorePaths.dailyContent)
        .where('date', isGreaterThanOrEqualTo: dateRangeKey(start, end).$1)
        .where('date', isLessThanOrEqualTo: dateRangeKey(start, end).$2)
        .get();

    return query.docs
        .map((doc) => DailyContent.fromMap(doc.data()))
        .toList();
  }

  @override
  Future<void> saveDraft(DailyContent content) async {
    final data = content.toMap();
    data['published'] = false;
    await _firestore
        .collection(FirestorePaths.dailyContent)
        .doc(content.date)
        .set(data);
  }

  @override
  Future<void> publish(DailyContent content) async {
    final data = content.toMap();
    data['published'] = true;
    await _firestore
        .collection(FirestorePaths.dailyContent)
        .doc(content.date)
        .set(data);
  }

  @override
  Future<void> delete(String dateKey) async {
    await _firestore
        .collection(FirestorePaths.dailyContent)
        .doc(dateKey)
        .delete();
  }
}

(String, String) dateRangeKey(DateTime start, DateTime end) {
  String key(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  return (key(start), key(end));
}