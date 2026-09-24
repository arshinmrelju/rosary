import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rosary_break/core/utils/formatters.dart';
import 'package:rosary_break/data/mock/mock_community.dart';
import 'package:rosary_break/data/mock/mock_repositories.dart';
import 'package:rosary_break/domain/models/day_stats.dart';
import 'package:rosary_break/domain/models/month_stats.dart';
import 'package:rosary_break/domain/models/prayer_intention.dart';
import 'package:rosary_break/data/repositories/intention_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('decade completion bumps community stats exactly once per decade', () async {
    final store = MockCommunityStore();
    final repo = await MockParticipationRepository.create(store: store);
    final date = DateTime(2026, 10, 1, 9, 0);

    final beforeDay = store.statsFor(date);
    final beforeMonth = store.monthStatsFor(date);

    // First completion of the day also bumps participants.
    await repo.completeDecade('u1', date, 1);
    final afterFirst = store.statsFor(date);
    expect(afterFirst.totalDecades, beforeDay.totalDecades + 1);
    expect(afterFirst.totalParticipants, beforeDay.totalParticipants + 1);
    expect(store.monthStatsFor(date).totalDecades, beforeMonth.totalDecades + 1);

    // A second decade on the same day is not a new participant.
    await repo.completeDecade('u1', date, 2);
    final afterSecond = store.statsFor(date);
    expect(afterSecond.totalDecades, afterFirst.totalDecades + 1);
    expect(afterSecond.totalParticipants, afterFirst.totalParticipants);

    // Repeating an already-completed decade must NOT bump anything.
    final beforeRepeat = store.statsFor(date);
    await repo.completeDecade('u1', date, 2);
    final afterRepeat = store.statsFor(date);
    expect(afterRepeat.totalDecades, beforeRepeat.totalDecades);

    // A second user starting a fresh day is a new participant again.
    await repo.completeDecade('u2', date, 1);
    expect(store.statsFor(date).totalParticipants,
        afterRepeat.totalParticipants + 1);
  });

  test('intention submit validates, throttles and never self-publishes', () async {
    final store = MockCommunityStore();
    final repo = await MockIntentionRepository.create(store: store);
    final before = store.statsFor(DateTime.now());

    // Too short.
    expect(
      await repo.submit(PrayerIntention(text: 'hi', approved: false)),
      IntentionSubmission.invalid,
    );

    // Valid.
    expect(
      await repo.submit(PrayerIntention(text: 'For a sick friend', approved: false)),
      IntentionSubmission.success,
    );
    expect(store.statsFor(DateTime.now()).totalIntentions,
        before.totalIntentions + 1);

    // Immediately throttled (60s cooldown).
    expect(
      await repo.submit(PrayerIntention(text: 'Another intention', approved: false)),
      IntentionSubmission.throttled,
    );
  });

  test('recordPrayer counts once per device even if called repeatedly', () async {
    final store = MockCommunityStore();
    final repo = await MockIntentionRepository.create(store: store);
    final before = store.statsFor(DateTime.now());

    final (firstCounted, firstUpdated) = await repo.recordPrayer('mock-1', 'u1');
    expect(firstCounted, isTrue);
    expect(firstUpdated, isNotNull);
    expect(firstUpdated!.prayerCount, 97);

    // Second call for the same intention must not count again.
    final (secondCounted, secondUpdated) = await repo.recordPrayer('mock-1', 'u1');
    expect(secondCounted, isFalse);
    expect(secondUpdated, isNull);

    expect(store.statsFor(DateTime.now()).totalPrayers,
        before.totalPrayers + 1);
  });

  test('stats repository surfaces day and month aggregates', () async {
    final stats = MockStatsRepository(MockCommunityStore());
    final date = DateTime(2026, 10, 1, 12, 0);

    final day = await stats.fetch(date);
    expect(day, isA<DayStats>());
    expect(day.date, dateKey(date));
    expect(day.totalDecades, greaterThan(0));

    final month = await stats.fetchMonth(date);
    expect(month, isA<MonthStats>());
    expect(month.date, monthKey(date));
    expect(month.totalDecades, greaterThan(0));
  });
}