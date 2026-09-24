import '../../domain/models/prayer_intention.dart';

/// Moderator-facing prayer wall operations.
abstract interface class ModerationRepository {
  /// All intentions waiting for moderation (`approved: false`).
  Future<List<PrayerIntention>> fetchPending();

  /// All approved intentions (oldest first for review).
  Future<List<PrayerIntention>> fetchApproved();

  /// Approves a pending intention — it becomes visible to students.
  Future<void> approve(String intentionId);

  /// Rejects a pending intention — removes it from the queue entirely.
  Future<void> reject(String intentionId);

  /// Hides a published intention (returns it to the pending queue).
  /// The document and its prayer counts are preserved.
  Future<void> hide(String intentionId);

  /// Permanently deletes an intention (with confirmation).
  Future<void> delete(String intentionId);
}