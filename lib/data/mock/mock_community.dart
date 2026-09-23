import '../../core/utils/formatters.dart';
import '../../domain/models/day_stats.dart';
import '../../domain/models/prayer_intention.dart';

/// Fixed community data for mock mode.
abstract final class MockCommunity {
  static DayStats statsFor(DateTime date) => DayStats(
    date: dateKey(date),
    totalParticipants: 214,
    totalDecades: 640,
    totalIntentions: 38,
  );

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