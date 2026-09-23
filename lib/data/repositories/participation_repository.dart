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
}