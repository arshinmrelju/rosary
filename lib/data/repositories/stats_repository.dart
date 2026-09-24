import '../../domain/models/day_stats.dart';
import '../../domain/models/month_stats.dart';

/// Reads the daily and monthly community stats shown on the Home and Prayer Wall.
abstract interface class StatsRepository {
  Future<DayStats> fetch(DateTime date);

  Future<void> save(DayStats stats);

  Future<MonthStats> fetchMonth(DateTime date);

  Future<void> saveMonth(MonthStats stats);
}