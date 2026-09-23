import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/utils/formatters.dart';
import '../../../domain/models/day_stats.dart';
import '../../firebase/firestore_paths.dart';
import '../stats_repository.dart';

class FirestoreStatsRepository implements StatsRepository {
  const FirestoreStatsRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<DayStats> fetch(DateTime date) async {
    final key = dateKey(date);
    final snapshot = await _firestore
        .collection(FirestorePaths.stats)
        .doc(key)
        .get();
    if (!snapshot.exists) return DayStats(date: key);
    return DayStats.fromMap(snapshot.data()!);
  }

  @override
  Future<void> save(DayStats stats) async {
    await _firestore
        .collection(FirestorePaths.stats)
        .doc(stats.date)
        .set(stats.toMap());
  }
}