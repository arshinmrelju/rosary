import '../../domain/models/day_participation.dart';

/// Per-user day progress.
abstract interface class ParticipationRepository {
  Future<DayParticipation> fetch(String userId, DateTime date);

  /// Marks a single decade completed. Repeated calls are idempotent.
  Future<DayParticipation> completeDecade(
    String userId,
    DateTime date,
    int decadeNumber,
  );

  /// Saves the full participation snapshot.
  Future<void> save(String userId, DayParticipation participation);

  /// Recent days with participation, newest first (for the history screen).
  Future<List<DayParticipation>> fetchRecent(String userId, {int limit = 30});

  /// Participation inside the date range `[start, end]` (for the calendar
  /// view). Days without participation are omitted.
  Future<List<DayParticipation>> fetchRange(
    String userId,
    DateTime start,
    DateTime end,
  );

  /// Flushes locally queued (offline) completions to the backend.
  ///
  /// Idempotent by contract — a repeat sync never double-counts. Repositories
  /// that write straight through simply return 0 (nothing queued).
  Future<int> syncPending();
}