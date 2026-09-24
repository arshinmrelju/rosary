import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/formatters.dart';
import '../../../domain/models/day_participation.dart';
import '../../../domain/models/day_stats.dart';
import '../../../domain/models/month_stats.dart';
import '../../firebase/firestore_paths.dart';
import '../participation_repository.dart';

/// Per-user participation with community-counting built in.
///
/// A decade completion is recorded in a **single Firestore transaction** that
/// reads the user's own participation document first. Because
/// `participation/{userId}/days/{date}` only ever flips a decade from
/// `false` to `true` (never back), it acts as the idempotent source of truth:
///
/// * Repeat taps / refreshes read `true` for that decade → **no counter
///   change**, so double counting, refresh counting and re-completion are all
///   impossible.
/// * `uniqueParticipants` (day) and the month's participant count only
///   increase the first time the user completes a decade that day, guarded by
///   the same read plus a one-per-month marker document.
/// * The whole write is atomic — no partial state if the network drops.
///
/// This keeps client-side counting to a single guarded path. When Cloud
/// Functions are added later, this transaction can be moved server-side
/// without changing any caller: the interface stays identical.
class FirestoreParticipationRepository implements ParticipationRepository {
  const FirestoreParticipationRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<DayParticipation> fetch(String userId, DateTime date) async {
    final doc = _firestore.doc(
      FirestorePaths.participationDay(userId, dateKey(date)),
    );
    final snapshot = await doc.get();
    if (!snapshot.exists) return DayParticipation.empty(date);
    return DayParticipation.fromMap(snapshot.data()!);
  }

  @override
  Future<DayParticipation> completeDecade(
    String userId,
    DateTime date,
    int decadeNumber,
  ) async {
    final dayKey = dateKey(date);
    final monthKeyStr = monthKey(date);
    final dayStatsRef = _firestore
        .collection(FirestorePaths.stats)
        .doc(dayKey);
    final monthStatsRef = _firestore
        .collection(FirestorePaths.monthlyStats)
        .doc(monthKeyStr);
    final monthMarkerRef = _firestore.doc(
      FirestorePaths.monthParticipant(monthKeyStr, userId),
    );
    final participationRef = _firestore.doc(
      FirestorePaths.participationDay(userId, dayKey),
    );

    return _firestore.runTransaction<DayParticipation>((txn) async {
      final participationSnapshot = await txn.get(participationRef);
      final current = participationSnapshot.exists
          ? DayParticipation.fromMap(participationSnapshot.data()!)
          : DayParticipation.empty(date);

      // Idempotent: a decade that is already recorded never bumps counters.
      final alreadyCompleted = current.isDecadeCompleted(decadeNumber);
      final isFirstOfTheDay = current.totalCompleted == 0;

      final updated = DayParticipation(
        date: current.date,
        decade1: decadeNumber == 1 || current.decade1,
        decade2: decadeNumber == 2 || current.decade2,
        decade3: decadeNumber == 3 || current.decade3,
        decade4: decadeNumber == 4 || current.decade4,
        decade5: decadeNumber == 5 || current.decade5,
        lastUpdated: DateTime.now(),
      );
      txn.set(participationRef, updated.toMap());
      if (alreadyCompleted) return updated;

      final daySnapshot = await txn.get(dayStatsRef);
      final day = daySnapshot.exists
          ? DayStats.fromMap(daySnapshot.data()!)
          : DayStats(date: dayKey);
      txn.set(
        dayStatsRef,
        DayStats(
          date: dayKey,
          totalDecades: day.totalDecades + 1,
          totalParticipants: day.totalParticipants + (isFirstOfTheDay ? 1 : 0),
          totalIntentions: day.totalIntentions,
          totalPrayers: day.totalPrayers,
        ).toMap(),
      );

      final monthSnapshot = await txn.get(monthStatsRef);
      final month = monthSnapshot.exists
          ? MonthStats.fromMap(monthSnapshot.data()!)
          : MonthStats(date: monthKeyStr);
      final monthMarkerSnapshot = await txn.get(monthMarkerRef);
      // A user counts as a monthly participant exactly once, even on
      // subsequent days within the same month.
      final isNewMonthParticipant = isFirstOfTheDay && !monthMarkerSnapshot.exists;

      txn.set(
        monthStatsRef,
        MonthStats(
          date: monthKeyStr,
          totalDecades: month.totalDecades + 1,
          totalParticipants:
              month.totalParticipants + (isNewMonthParticipant ? 1 : 0),
          totalIntentions: month.totalIntentions,
          totalPrayers: month.totalPrayers,
        ).toMap(),
      );
      if (isNewMonthParticipant) {
        txn.set(monthMarkerRef, <String, dynamic>{
          'month': monthKeyStr,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return updated;
    });
  }

  @override
  Future<void> save(String userId, DayParticipation participation) async {
    await _firestore
        .doc(FirestorePaths.participationDay(userId, participation.date))
        .set(participation.toMap());
  }

  /// Firestore writes straight through — the offline queue is the wrapper's
  /// concern (`OfflineParticipationRepository`), so there is nothing to flush
  /// here.
  @override
  Future<int> syncPending() async => 0;

  @override
  Future<List<DayParticipation>> fetchRecent(String userId, {int limit = 30}) async {
    final snapshot = await _firestore
        .collection('${FirestorePaths.participation}/$userId/days')
        .orderBy('date', descending: true)
        .limit(limit)
        .get();
    return <DayParticipation>[
      for (final doc in snapshot.docs)
        if (doc.exists) DayParticipation.fromMap(doc.data()),
    ];
  }

  @override
  Future<List<DayParticipation>> fetchRange(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    final snapshot = await _firestore
        .collection('${FirestorePaths.participation}/$userId/days')
        .where('date', isGreaterThanOrEqualTo: dateKey(start))
        .where('date', isLessThanOrEqualTo: dateKey(end))
        .orderBy('date')
        .get();
    return <DayParticipation>[
      for (final doc in snapshot.docs)
        if (doc.exists) DayParticipation.fromMap(doc.data()),
    ];
  }
}
