import '../../core/utils/formatters.dart';
import '../../domain/models/day_participation.dart';
import '../repositories/participation_repository.dart';
import 'local_cache.dart';

/// Participation repository that keeps working without a network and merges
/// cleanly when connectivity returns.
///
/// Written-data flow:
///  * online — the wrapped repository (Firestore transaction) is the source of
///    truth, and its result is mirrored to the local cache;
///  * offline — completions are applied to the local cache immediately (so the
///    UI never lies about progress) and queued in `LocalCache.pendingItems()`;
///  * returning online — [syncPending] replays the queue through the wrapped
///    repository. Replays are idempotent: the guarded `false → true` flip in
///    `participation/{userId}/days/{date}` means a decade that already counted
///    once never counts again, so duplicates during sync are impossible.
class OfflineParticipationRepository implements ParticipationRepository {
  const OfflineParticipationRepository(this._delegate, this._cache);

  final ParticipationRepository _delegate;
  final LocalCache _cache;

  @override
  Future<DayParticipation> fetch(String userId, DateTime date) async {
    try {
      final day = await _delegate.fetch(userId, date);
      _cache.participationStore(userId, day);
      return _mergeCached(day, userId);
    } catch (_) {
      return _cache.participationFor(userId, date) ?? DayParticipation.empty(date);
    }
  }

  @override
  Future<DayParticipation> completeDecade(
    String userId,
    DateTime date,
    int decadeNumber,
  ) async {
    try {
      final updated = await _delegate.completeDecade(userId, date, decadeNumber);
      _cache.participationStore(userId, updated);
      return updated;
    } catch (_) {
      // Offline: apply locally so the decade still appears prayed.
      final current = await fetch(userId, date);
      final patched = DayParticipation(
        date: current.date,
        decade1: decadeNumber == 1 || current.decade1,
        decade2: decadeNumber == 2 || current.decade2,
        decade3: decadeNumber == 3 || current.decade3,
        decade4: decadeNumber == 4 || current.decade4,
        decade5: decadeNumber == 5 || current.decade5,
        lastUpdated: DateTime.now(),
      );
      _cache.participationStore(userId, patched);
      _cache.enqueuePending(userId, dateKey(date), decadeNumber);
      return patched;
    }
  }

  @override
  Future<void> save(String userId, DayParticipation participation) async {
    try {
      await _delegate.save(userId, participation);
    } catch (_) {
      // Offline: keep the snapshot locally for later sync.
    }
    _cache.participationStore(userId, participation);
  }

  @override
  Future<List<DayParticipation>> fetchRecent(String userId, {int limit = 30}) async {
    try {
      final days = await _delegate.fetchRecent(userId, limit: limit);
      for (final day in days) {
        _cache.participationStore(userId, day);
      }
      return <DayParticipation>[
        for (final day in days) _mergeCached(day, userId),
      ];
    } catch (_) {
      return _cache.allParticipation(userId).take(limit).toList();
    }
  }

  @override
  Future<List<DayParticipation>> fetchRange(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    try {
      final days = await _delegate.fetchRange(userId, start, end);
      for (final day in days) {
        _cache.participationStore(userId, day);
      }
      return <DayParticipation>[
        for (final day in days) _mergeCached(day, userId),
      ];
    } catch (_) {
      final startKey = dateKey(start);
      final endKey = dateKey(end);
      return _cache.allParticipation(userId)
          .where((d) => d.date.compareTo(startKey) >= 0 && d.date.compareTo(endKey) <= 0)
          .toList();
    }
  }

  /// Server state wins except for decades the user completed while offline.
  DayParticipation _mergeCached(DayParticipation server, String userId) {
    final cached = _cache.participationFor(userId, DateTime.parse(server.date));
    if (cached == null) return server;
    var merged = server;
    for (var n = 1; n <= 5; n++) {
      if (cached.isDecadeCompleted(n) && !server.isDecadeCompleted(n)) {
        merged = _withDecade(merged, n, true);
      }
    }
    return merged;
  }

  /// Replays the pending queue through the delegate. Returns items synced.
  @override
  Future<int> syncPending() async {
    final items = _cache.pendingItems();
    var synced = 0;
    for (final item in items) {
      final userId = item['userId'] as String;
      final rawDate = item['date'] as String;
      final decade = item['decade'] is num
          ? (item['decade'] as num).toInt()
          : int.tryParse('${item['decade']}') ?? 0;
      if (decade < 1 || decade > 5) continue;
      try {
        await _delegate.completeDecade(
          userId,
          DateTime.parse(rawDate),
          decade,
        );
        _cache.removePending(<Map<String, Object>>[item]);
        synced++;
      } catch (_) {
        // Still offline — keep the item queued.
      }
    }
    return synced;
  }

  DayParticipation _withDecade(DayParticipation day, int number, bool done) {
    switch (number) {
      case 1:
        return DayParticipation(date: day.date, decade1: done, decade2: day.decade2, decade3: day.decade3, decade4: day.decade4, decade5: day.decade5, lastUpdated: day.lastUpdated);
      case 2:
        return DayParticipation(date: day.date, decade1: day.decade1, decade2: done, decade3: day.decade3, decade4: day.decade4, decade5: day.decade5, lastUpdated: day.lastUpdated);
      case 3:
        return DayParticipation(date: day.date, decade1: day.decade1, decade2: day.decade2, decade3: done, decade4: day.decade4, decade5: day.decade5, lastUpdated: day.lastUpdated);
      case 4:
        return DayParticipation(date: day.date, decade1: day.decade1, decade2: day.decade2, decade3: day.decade3, decade4: done, decade5: day.decade5, lastUpdated: day.lastUpdated);
      default:
        return DayParticipation(date: day.date, decade1: day.decade1, decade2: day.decade2, decade3: day.decade3, decade4: day.decade4, decade5: done, lastUpdated: day.lastUpdated);
    }
  }
}