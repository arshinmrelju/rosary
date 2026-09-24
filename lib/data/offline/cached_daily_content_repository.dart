import '../../core/utils/formatters.dart';
import '../../domain/models/daily_content.dart';
import '../repositories/daily_content_repository.dart';
import 'local_cache.dart';

/// Content repository that falls back to a locally cached copy of the day's
/// content when the live fetch fails (offline).
///
/// The cached copy is refreshed on every successful fetch, so it is always the
/// most recent day the app has seen.
class CachedDailyContentRepository implements DailyContentRepository {
  const CachedDailyContentRepository(this._delegate, this._cache);

  final DailyContentRepository _delegate;
  final LocalCache _cache;

  @override
  Future<DailyContent?> fetch(DateTime date) async {
    try {
      final content = await _delegate.fetch(date);
      if (content != null) _cache.contentStore(date, content);
      return content;
    } catch (_) {
      return _cache.contentFor(date);
    }
  }

  @override
  Future<DailyContent?> fetchDefault() => fetch(clockNow());

  @override
  Future<void> save(DailyContent content) async {
    try {
      await _delegate.save(content);
    } catch (_) {
      // Offline — still cache the snapshot.
    }
    _cache.contentStore(DateTime.parse(content.date), content);
  }
}