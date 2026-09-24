import '../../core/utils/formatters.dart';
import '../../domain/models/day_stats.dart';
import '../../domain/models/month_stats.dart';
import '../../domain/models/prayer_intention.dart';

/// In-memory community ledger shared by the mock repositories.
///
/// Unlike the fixed constants of earlier stages, this store actually mutates
/// when a decade is completed / an intention is submitted / a user prays for
/// an intention, so the mock experience demonstrates the same guarded-counting
/// behaviour the Firestore transaction path provides.
///
/// A single instance is created in `AppDependencies.create()` and injected
/// into every mock repository so their numbers stay consistent.
class MockCommunityStore {
  final Map<String, DayStats> _days = <String, DayStats>{};
  final Map<String, MonthStats> _months = <String, MonthStats>{};

  int _hash(String value) => value.hashCode.abs();

  DayStats statsFor(DateTime date) {
    final key = dateKey(date);
    return _days[key] ??= DayStats(
      date: key,
      totalParticipants: 60 + (_hash(key) % 90),
      totalDecades: 200 + (_hash('decades:$key') % 300),
      totalIntentions: 12 + (_hash('intentions:$key') % 40),
      totalPrayers: 40 + (_hash('prayers:$key') % 120),
    );
  }

  MonthStats monthStatsFor(DateTime date) {
    final key = monthKey(date);
    return _months[key] ??= MonthStats(
      date: key,
      totalParticipants: 320 + (_hash('mp:$key') % 300),
      totalDecades: 2500 + (_hash('md:$key') % 2300),
      totalIntentions: 120 + (_hash('mi:$key') % 200),
      totalPrayers: 400 + (_hash('mpr:$key') % 600),
    );
  }

  /// Registers one newly-completed decade for the day. Called with
  /// [isNewParticipant] when this is the user's first completed decade of
  /// the day, matching the Firestore transaction's guarded increments.
  void recordDecade(DateTime date, {required bool isNewParticipant}) {
    final key = dateKey(date);
    final current = statsFor(date);
    _days[key] = DayStats(
      date: key,
      totalDecades: current.totalDecades + 1,
      totalParticipants:
          current.totalParticipants + (isNewParticipant ? 1 : 0),
      totalIntentions: current.totalIntentions,
      totalPrayers: current.totalPrayers,
    );

    final monthKeyStr = monthKey(date);
    final month = monthStatsFor(date);
    _months[monthKeyStr] = MonthStats(
      date: monthKeyStr,
      totalDecades: month.totalDecades + 1,
      totalParticipants: month.totalParticipants + (isNewParticipant ? 1 : 0),
      totalIntentions: month.totalIntentions,
      totalPrayers: month.totalPrayers,
    );
  }

  void recordIntention(DateTime date) {
    final key = dateKey(date);
    final current = statsFor(date);
    _days[key] = DayStats(
      date: key,
      totalDecades: current.totalDecades,
      totalParticipants: current.totalParticipants,
      totalIntentions: current.totalIntentions + 1,
      totalPrayers: current.totalPrayers,
    );

    final monthKeyStr = monthKey(date);
    final month = monthStatsFor(date);
    _months[monthKeyStr] = MonthStats(
      date: monthKeyStr,
      totalDecades: month.totalDecades,
      totalParticipants: month.totalParticipants,
      totalIntentions: month.totalIntentions + 1,
      totalPrayers: month.totalPrayers,
    );
  }

  void recordPrayer(DateTime date) {
    final key = dateKey(date);
    final current = statsFor(date);
    _days[key] = DayStats(
      date: key,
      totalDecades: current.totalDecades,
      totalParticipants: current.totalParticipants,
      totalIntentions: current.totalIntentions,
      totalPrayers: current.totalPrayers + 1,
    );

    final monthKeyStr = monthKey(date);
    final month = monthStatsFor(date);
    _months[monthKeyStr] = MonthStats(
      date: monthKeyStr,
      totalDecades: month.totalDecades,
      totalParticipants: month.totalParticipants,
      totalIntentions: month.totalIntentions,
      totalPrayers: month.totalPrayers + 1,
    );
  }

  void saveDay(DayStats stats) => _days[stats.date] = stats;

  void saveMonth(MonthStats stats) => _months[stats.date] = stats;
}

/// Fixed community data for mock mode (seeded approved intentions).
abstract final class MockCommunity {
  static List<PrayerIntention> approvedIntentions() => const <PrayerIntention>[
    PrayerIntention(
      id: 'mock-1',
      text: 'For my grandmother who is in hospital',
      anonymous: true,
      approved: true,
      prayerCount: 96,
    ),
    PrayerIntention(
      id: 'mock-2',
      text: 'For success in our final examinations',
      anonymous: true,
      approved: true,
      prayerCount: 140,
    ),
    PrayerIntention(
      id: 'mock-3',
      text: 'For peace in my family',
      anonymous: true,
      approved: true,
      prayerCount: 61,
    ),
  ];
}