import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/formatters.dart';
import '../../../domain/models/day_stats.dart';
import '../../../domain/models/month_stats.dart';
import '../../firebase/firestore_paths.dart';
import '../admin_stats_repository.dart';

class FirestoreAdminStatsRepository implements AdminStatsRepository {
  const FirestoreAdminStatsRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<DayStats> fetchDay(DateTime date) async {
    final snapshot = await _firestore
        .collection(FirestorePaths.stats)
        .doc(dateKey(date))
        .get();
    if (!snapshot.exists) return DayStats(date: dateKey(date));
    return DayStats.fromMap(snapshot.data()!);
  }

  @override
  Future<MonthStats> fetchMonth(DateTime date) async {
    final snapshot = await _firestore
        .collection(FirestorePaths.monthlyStats)
        .doc(monthKey(date))
        .get();
    if (!snapshot.exists) return MonthStats(date: monthKey(date));
    return MonthStats.fromMap(snapshot.data()!);
  }

  @override
  Future<List<DayStats>> fetchDailyRange(DateTime start, DateTime end) async {
    final startKey = dateKey(start);
    final endKey = dateKey(end);
    final snapshot = await _firestore
        .collection(FirestorePaths.stats)
        .where('date', isGreaterThanOrEqualTo: startKey)
        .where('date', isLessThanOrEqualTo: endKey)
        .orderBy('date', descending: false)
        .get();

    return snapshot.docs
        .map((doc) => DayStats.fromMap(doc.data()))
        .toList();
  }
}