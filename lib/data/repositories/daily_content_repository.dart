import '../../domain/models/daily_content.dart';

/// Provides the daily Rosary content shown to students.
abstract interface class DailyContentRepository {
  /// Returns content for [date], or `null` when nothing is published yet.
  Future<DailyContent?> fetch(DateTime date);

  Future<DailyContent?> fetchDefault();

  Future<void> save(DailyContent content);
}