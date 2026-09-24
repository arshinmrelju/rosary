import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rosary_break/core/utils/formatters.dart';
import 'package:rosary_break/data/offline/local_cache.dart';
import 'package:rosary_break/data/offline/offline_participation_repository.dart';
import 'package:rosary_break/data/repositories/participation_repository.dart';
import 'package:rosary_break/domain/models/day_participation.dart';
import 'package:rosary_break/domain/models/daily_content.dart';
import 'package:rosary_break/domain/schedule/default_break_schedule_source.dart';

/// A participation repository whose [completeDecade] fails until [online] is
/// set to true — used to exercise the offline queue deterministically.
class FlakyParticipationRepository implements ParticipationRepository {
  FlakyParticipationRepository({this.online = false});

  bool online;
  final Map<String, DayParticipation> _store = <String, DayParticipation>{};
  int completedCalls = 0;

  @override
  Future<int> syncPending() async => 0;

  @override
  Future<List<DayParticipation>> fetchRecent(
    String userId, {
    int limit = 30,
  }) async {
    final days = _store.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return days.take(limit).toList();
  }

  @override
  Future<List<DayParticipation>> fetchRange(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    final startKey = dateKey(start);
    final endKey = dateKey(end);
    return <DayParticipation>[
      for (final day in _store.values)
        if (day.date.compareTo(startKey) >= 0 && day.date.compareTo(endKey) <= 0)
          day,
    ];
  }

  @override
  Future<DayParticipation> fetch(String userId, DateTime date) async {
    if (!online) throw Exception('offline');
    return _store[dateKey(date)] ?? DayParticipation.empty(date);
  }

  @override
  Future<DayParticipation> completeDecade(
    String userId,
    DateTime date,
    int decadeNumber,
  ) async {
    if (!online) throw Exception('offline');
    completedCalls++;
    final key = dateKey(date);
    final current = _store[key] ?? DayParticipation.empty(date);
    final updated = DayParticipation(
      date: current.date,
      decade1: decadeNumber == 1 || current.decade1,
      decade2: decadeNumber == 2 || current.decade2,
      decade3: decadeNumber == 3 || current.decade3,
      decade4: decadeNumber == 4 || current.decade4,
      decade5: decadeNumber == 5 || current.decade5,
      lastUpdated: DateTime.now(),
    );
    _store[key] = updated;
    return updated;
  }

  @override
  Future<void> save(String userId, DayParticipation participation) async {
    if (!online) throw Exception('offline');
    _store[participation.date] = participation;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalCache cache;
  late FlakyParticipationRepository backend;
  late OfflineParticipationRepository repo;
  final date = DateTime(2026, 9, 26);
  const userId = 'u-offline';

  Future<void> fresh() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    cache = LocalCache(prefs);
    backend = FlakyParticipationRepository();
    repo = OfflineParticipationRepository(backend, cache);
  }

  group('offline participation', () {
    test('offline completions apply locally and queue for later sync',
        () async {
      await fresh();

      final offline = await repo.completeDecade(userId, date, 1);
      expect(offline.decade1, isTrue);
      expect(offline.totalCompleted, 1);

      // The queue holds exactly one pending item for the backend.
      final pending = cache.pendingItems();
      expect(pending.length, 1);
      expect(pending.single['decade'], 1);
      expect(pending.single['date'], dateKey(date));

      // Reads still work offline and reflect the local completion.
      final read = await repo.fetch(userId, date);
      expect(read.decade1, isTrue);
    });

    test('queue replays idempotently once online — no duplicate decades',
        () async {
      await fresh();
      await repo.completeDecade(userId, date, 2); // offline: queued.

      backend.online = true;
      final synced = await repo.syncPending();
      expect(synced, 1);
      expect(backend.completedCalls, 1);
      expect(cache.hasPending(), isFalse);

      // Second flush (e.g. another reconnect event) does nothing extra because
      // the queue is empty — combined with the guarded false→true flip server
      // side, duplicates are impossible.
      expect(await repo.syncPending(), 0);
      expect(backend.completedCalls, 1);

      final day = await backend.fetch(userId, date);
      expect(day.decade2, isTrue);
    });

    test('offline catch-up merges onto server state without double counting',
        () async {
      await fresh();

      // Online: server records decade 1 (straight through, nothing queued).
      backend.online = true;
      await repo.completeDecade(userId, date, 1);
      expect(cache.hasPending(), isFalse);

      // Offline moment: user prays decade 3 — applied locally and queued.
      backend.online = false;
      await repo.completeDecade(userId, date, 3);
      expect(cache.hasPending(), isTrue);

      // Back online: flush replays once; decade 1 was already server-side.
      backend.online = true;
      expect(await repo.syncPending(), 1);
      final merged = await repo.fetch(userId, date);
      expect(merged.totalCompleted, 2);
      expect(merged.decade1, isTrue);
      expect(merged.decade3, isTrue);
    });
  });

  group('local cache', () {
    test('schedule round-trips through the cache', () async {
      await fresh();
      final schedule = await DefaultBreakScheduleSource().load();
      final bytes = <String>[
        for (final s in schedule.slots)
          '${s.decadeNumber}:${s.time.label}:${s.activeWindow.inMinutes}',
      ];
      cache.scheduleStore(bytes.join('|'));
      expect(cache.schedule, bytes.join('|'));
    });

    test('daily content round-trips per day', () async {
      await fresh();
      final content = DailyContent(
        date: dateKey(date),
        mysterySetTitle: 'Glorious Mysteries',
        intention: 'For peace in the campus',
      );
      cache.contentStore(date, content);
      final back = cache.contentFor(date);
      expect(back, isNotNull);
      expect(back!.mysterySetTitle, 'Glorious Mysteries');
      expect(back.intention, 'For peace in the campus');
    });

    test('participation list is sorted newest first for history', () async {
      await fresh();
      backend.online = true;
      final older = DateTime(2026, 9, 25);
      await repo.completeDecade(userId, older, 1);
      cache.removePending(cache.pendingItems());
      backend.online = false;
      await repo.completeDecade(userId, DateTime(2026, 9, 26), 2);

      final all = cache.allParticipation(userId);
      expect(all.length, 2);
      expect(all.first.date, '2026-09-26');
      expect(all.last.date, '2026-09-25');
    });
  });

  group('history queries through the offline proxy', () {
    test('fetchRange serves cached days when the backend is down', () async {
      await fresh();
      await repo.completeDecade(userId, DateTime(2026, 9, 25), 1);
      backend.online = true;
      await repo.syncPending();
      backend.online = false;

      final range = await repo.fetchRange(
        userId,
        DateTime(2026, 9, 1),
        DateTime(2026, 9, 30),
      );
      expect(range.length, 1);
      expect(range.single.decade1, isTrue);
    });
  });
}