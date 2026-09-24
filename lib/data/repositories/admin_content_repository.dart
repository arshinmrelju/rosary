import '../../domain/models/daily_content.dart';

/// Admin-facing daily content storage, including drafts and unpublished docs
/// that the student repository deliberately never returns.
abstract interface class AdminContentRepository {
  /// Fetches content for a date key (`yyyy-MM-dd`) regardless of publication
  /// status. `null` when no document exists yet.
  Future<DailyContent?> fetch(String dateKey);

  /// All content documents between [start] and [end] (inclusive).
  Future<List<DailyContent>> fetchRange(DateTime start, DateTime end);

  /// Saves (or overwrites) content as a **draft** (`published: false`).
  Future<void> saveDraft(DailyContent content);

  /// Publishes content (`published: true`) so students see it immediately.
  Future<void> publish(DailyContent content);

  /// Deletes a day's content completely.
  Future<void> delete(String dateKey);
}