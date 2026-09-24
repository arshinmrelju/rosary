import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/formatters.dart';
import '../../../domain/models/day_stats.dart';
import '../../../domain/models/month_stats.dart';
import '../../../domain/models/prayer_intention.dart';
import '../../../domain/models/prayer_report.dart';
import '../../firebase/firestore_paths.dart';
import '../intention_repository.dart';
import '../reports_repository.dart';

/// Firefox-backed prayer intentions repository.
///
/// * New submissions are always created `approved: false` (pending) so
///   un-moderated content never appears on the public wall.
/// * Text is validated (non-empty, length bounds) and a per-user submission
///   throttle is applied to discourage spam.
/// * `recordPrayer` uses a transaction with a per-user marker subcollection:
///   one user can count toward an intention's prayer total only once, which
///   prevents "tap to inflate" abuse. The same transaction also nudges the
///   daily/monthly `totalPrayers` aggregates.
///
/// Moderation (approve / delete, rate-limit hardening) is intentionally
/// admin/Cloud-Function territory and is kept out of the client.
class FirestoreIntentionRepository implements IntentionRepository {
  const FirestoreIntentionRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<List<PrayerIntention>> fetchApproved({int limit = 20}) async {
    final query = await _firestore
        .collection(FirestorePaths.prayerIntentions)
        .where('approved', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return query.docs
        .map((doc) => PrayerIntention.fromMap(doc.id, doc.data()))
        .toList();
  }

  @override
  Future<IntentionSubmission> submit(PrayerIntention intention) async {
    final text = _sanitize(intention.text);
    if (text.length < 3 || text.length > 280) {
      return IntentionSubmission.invalid;
    }

    final userId = intention.userId;
    final now = clockNow();
    final dayKey = dateKey(now);
    final monthKeyStr = monthKey(now);

    final intentionRef = _firestore
        .collection(FirestorePaths.prayerIntentions)
        .doc();
    final dayStatsRef = _firestore
        .collection(FirestorePaths.stats)
        .doc(dayKey);
    final monthStatsRef = _firestore
        .collection(FirestorePaths.monthlyStats)
        .doc(monthKeyStr);
    final throttleRef = _firestore
        .collection(FirestorePaths.intentionSubmissions)
        .doc(userId);

    // The pending intention payload. `approved` is forced to `false` here so a
    // client can never self-publish.
    final data = PrayerIntention(
      text: text,
      userId: userId,
      anonymous: intention.anonymous,
      createdAt: now,
      prayerCount: 0,
      approved: false,
    ).toMap();

    final submission = await _firestore.runTransaction<IntentionSubmission>((
      txn,
    ) async {
      // Per-user submission throttle (spam control).
      final throttleSnapshot = await txn.get(throttleRef);
      if (throttleSnapshot.exists) {
        final lastRaw = throttleSnapshot.data()!['lastSubmittedAt'];
        final lastTime = lastRaw is String ? DateTime.tryParse(lastRaw) : null;
        if (lastTime != null &&
            now.difference(lastTime) <
                const Duration(seconds: appSubmissionCooldownSeconds)) {
          return IntentionSubmission.throttled;
        }
      }

      txn.set(intentionRef, data);

      final daySnapshot = await txn.get(dayStatsRef);
      final day = daySnapshot.exists
          ? DayStats.fromMap(daySnapshot.data()!)
          : DayStats(date: dayKey);
      txn.set(
        dayStatsRef,
        DayStats(
          date: dayKey,
          totalDecades: day.totalDecades,
          totalParticipants: day.totalParticipants,
          totalIntentions: day.totalIntentions + 1,
          totalPrayers: day.totalPrayers,
        ).toMap(),
      );

      final monthSnapshot = await txn.get(monthStatsRef);
      final month = monthSnapshot.exists
          ? MonthStats.fromMap(monthSnapshot.data()!)
          : MonthStats(date: monthKeyStr);
      txn.set(
        monthStatsRef,
        MonthStats(
          date: monthKeyStr,
          totalDecades: month.totalDecades,
          totalParticipants: month.totalParticipants,
          totalIntentions: month.totalIntentions + 1,
          totalPrayers: month.totalPrayers,
        ).toMap(),
      );

      final previousCount = throttleSnapshot.exists
          ? throttleSnapshot.data()!['submittedCount'] as int? ?? 0
          : 0;
      txn.set(
        throttleRef,
        <String, dynamic>{
          'userId': userId,
          'lastSubmittedAt': now.toIso8601String(),
          'submittedCount': previousCount + 1,
        },
      );

      return IntentionSubmission.success;
    });

    return submission;
  }

  @override
  Future<(bool, PrayerIntention?)> recordPrayer(
    String intentionId,
    String userId,
  ) async {
    final now = clockNow();
    final dayKey = dateKey(now);
    final monthKeyStr = monthKey(now);

    final intentionRef = _firestore
        .collection(FirestorePaths.prayerIntentions)
        .doc(intentionId);
    final markerRef = _firestore.doc(
      FirestorePaths.intentionPrayer(intentionId, userId),
    );
    final dayStatsRef = _firestore
        .collection(FirestorePaths.stats)
        .doc(dayKey);
    final monthStatsRef = _firestore
        .collection(FirestorePaths.monthlyStats)
        .doc(monthKeyStr);

    return _firestore.runTransaction<(bool, PrayerIntention?)>((txn) async {
      // One user, one counted prayer per intention.
      final markerSnapshot = await txn.get(markerRef);
      if (markerSnapshot.exists) return (false, null);

      final intentionSnapshot = await txn.get(intentionRef);
      if (!intentionSnapshot.exists) return (false, null);

      txn.set(markerRef, <String, dynamic>{
        'prayedAt': now.toIso8601String(),
      });
      txn.update(intentionRef, <String, dynamic>{
        'prayerCount': FieldValue.increment(1),
      });

      final daySnapshot = await txn.get(dayStatsRef);
      final day = daySnapshot.exists
          ? DayStats.fromMap(daySnapshot.data()!)
          : DayStats(date: dayKey);
      txn.set(
        dayStatsRef,
        DayStats(
          date: dayKey,
          totalDecades: day.totalDecades,
          totalParticipants: day.totalParticipants,
          totalIntentions: day.totalIntentions,
          totalPrayers: day.totalPrayers + 1,
        ).toMap(),
      );

      final monthSnapshot = await txn.get(monthStatsRef);
      final month = monthSnapshot.exists
          ? MonthStats.fromMap(monthSnapshot.data()!)
          : MonthStats(date: monthKeyStr);
      txn.set(
        monthStatsRef,
        MonthStats(
          date: monthKeyStr,
          totalDecades: month.totalDecades,
          totalParticipants: month.totalParticipants,
          totalIntentions: month.totalIntentions,
          totalPrayers: month.totalPrayers + 1,
        ).toMap(),
      );

      final updated = PrayerIntention.fromMap(
        intentionId,
        <String, dynamic>{
          ...intentionSnapshot.data()!,
          'prayerCount': (intentionSnapshot.data()!['prayerCount'] as int? ?? 0) + 1,
        },
      );
      return (true, updated);
    });
  }

  @override
  Future<void> approve(String intentionId) async {
    await _firestore
        .collection(FirestorePaths.prayerIntentions)
        .doc(intentionId)
        .update(<String, dynamic>{'approved': true});
  }

  @override
  Future<ReportOutcome> report(PrayerReport request) async {
    final reason = request.reason.trim();
    if (reason.isEmpty || reason.length > 80) return ReportOutcome.invalid;

    final data = request.copyWith(
      status: ReportStatus.pending,
      createdAt: request.createdAt ?? clockNow(),
      intentionText:
          request.intentionText ?? (await _intentionText(request.intentionId)),
    ).toMap();

    try {
      await _firestore.collection(FirestorePaths.reports).doc().set(data);
      return ReportOutcome.success;
    } catch (e) {
      return ReportOutcome.failure;
    }
  }

  Future<String?> _intentionText(String intentionId) async {
    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.prayerIntentions)
          .doc(intentionId)
          .get();
      if (!snapshot.exists) return null;
      return snapshot.data()!['text'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Trims and collapses whitespace so displayed wall content stays clean.
  String _sanitize(String text) {
    return text.trim().replaceAll(RegExp(r'\s+'), ' ');
  }
}

/// Minimum interval between two intention submissions from the same user.
const int appSubmissionCooldownSeconds = 60;