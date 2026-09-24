import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/formatters.dart';
import '../../../domain/models/day_stats.dart';
import '../../../domain/models/month_stats.dart';
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

  @override
  Future<MonthStats> fetchMonth(DateTime date) async {
    final key = monthKey(date);
    final snapshot = await _firestore
        .collection(FirestorePaths.monthlyStats)
        .doc(key)
        .get();
    if (!snapshot.exists) return MonthStats(date: key);
    return MonthStats.fromMap(snapshot.data()!);
  }

  @override
  Future<void> saveMonth(MonthStats stats) async {
    await _firestore
        .collection(FirestorePaths.monthlyStats)
        .doc(stats.date)
        .set(stats.toMap());
  }
}
