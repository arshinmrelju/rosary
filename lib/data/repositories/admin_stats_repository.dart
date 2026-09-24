import '../../domain/models/day_stats.dart';
import '../../domain/models/month_stats.dart';

/// Aggregates used by the admin statistics page.
abstract interface class AdminStatsRepository {
  /// Today's community stats (`stats/{date}`).
  Future<DayStats> fetchDay(DateTime date);

  /// Monthly community stats (`monthlyStats/{yyyy-MM}`).
  Future<MonthStats> fetchMonth(DateTime date);

  /// Every day's stats between [start] and [end] (inclusive) for the daily
  /// chart. Days without a stats document are omitted.
  Future<List<DayStats>> fetchDailyRange(DateTime start, DateTime end);
}