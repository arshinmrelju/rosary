import '../../domain/models/prayer_intention.dart';
import '../../domain/models/prayer_report.dart';
import 'reports_repository.dart';

/// Result of a prayer-wall submission attempt.
enum IntentionSubmission {
  success,

  /// The text failed validation (empty / too short / too long).
  invalid,

  /// Submitted too recently after the previous one.
  throttled,

  /// Network or storage failure.
  failure,
}

/// Manages submitted prayer intentions.
abstract interface class IntentionRepository {
  /// Returns recently approved intentions for display.
  ///
  /// Pending (un-moderated) intentions are never returned to students.
  Future<List<PrayerIntention>> fetchApproved({int limit = 20});

  /// Creates a new intention as **pending** (`approved: false`).
  ///
  /// Validates the text and applies a per-user submission throttle so a
  /// single user cannot flood the wall.
  Future<IntentionSubmission> submit(PrayerIntention intention);

  /// Records that [userId] prayed for [intentionId].
  ///
  /// Returns `true` when the prayer was newly counted and `false` when this
  /// user has already prayed for this intention (idempotent). The caller
  /// should surface the updated count from the returned intention.
  Future<(bool counted, PrayerIntention? intention)> recordPrayer(
    String intentionId,
    String userId,
  );

  /// Marks an intention as approved (admin action).
  Future<void> approve(String intentionId);

  /// Reports a prayer intention for moderation (student action). Reports are
  /// always created pending and never reveal the reporter's identity publicly.
  Future<ReportOutcome> report(PrayerReport request);
}
