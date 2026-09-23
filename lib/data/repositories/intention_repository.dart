import '../../domain/models/prayer_intention.dart';

/// Manages submitted prayer intentions.
abstract interface class IntentionRepository {
  /// Returns recently approved intentions for display.
  Future<List<PrayerIntention>> fetchApproved({int limit = 10});

  /// Creates a new intention. Returns the created record.
  Future<PrayerIntention> submit(PrayerIntention intention);

  /// Increments the prayer count for an intention.
  Future<void> incrementPrayerCount(String intentionId);

  /// Marks an intention as approved (admin action).
  Future<void> approve(String intentionId);
}