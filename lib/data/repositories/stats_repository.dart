import '../../domain/models/day_stats.dart';

/// Reads the daily community stats shown on the Home screen.
abstract interface class StatsRepository {
  Future<DayStats> fetch(DateTime date);

  Future<void> save(DayStats stats);
}