import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/formatters.dart';
import '../../../domain/models/daily_content.dart';
import '../../firebase/firestore_paths.dart';
import '../daily_content_repository.dart';

class FirestoreDailyContentRepository implements DailyContentRepository {
  const FirestoreDailyContentRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<DailyContent?> fetch(DateTime date) async {
    final snapshot = await _firestore
        .collection(FirestorePaths.dailyContent)
        .doc(dateKey(date))
        .get();
    if (!snapshot.exists) return null;
    return DailyContent.fromMap(snapshot.data()!);
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