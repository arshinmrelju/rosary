import '../../core/utils/formatters.dart';
import '../../domain/models/daily_content.dart';
import '../../domain/models/mystery_set.dart';

/// Deterministic in-memory daily content used until Firebase content is
/// connected. Content rotates by calendar day so screens behave like the real
/// product during development.
class MockContent {
  static DailyContent forDate(DateTime date) {
    final set = MysterySet.forWeekday(date.weekday);
    final index = date.difference(DateTime(date.year)).inDays;
    final intention = intentions[index % intentions.length];
    final reflection = reflections[index % reflections.length];

    return DailyContent(
      date: dateKey(date),
      mysterySetTitle: set.title,
      intention: intention,
      reflection: reflection,
      decades: set.decades,
      published: true,
    );
  }

  static const List<String> intentions = <String>[
    'For peace in our campus community',
    'For students facing exams and deadlines',
    'For the sick and those who care for them',
    'For unity among our families',
    'For those feeling alone or anxious',
    'For our teachers and staff',
    'For the healing of our country',
    'For greater faith and hope this week',
  ];

  static const List<String> reflections = <String>[
    'Even one decade, prayed with your whole heart, is a gift you give the world today.',
    'A short pause to pray is never wasted. It reorders what truly matters.',
    'You are not alone in this. Hundreds of students are praying the same decade with you.',
    'Let this decade be a still point in a busy day – a quiet breath of peace.',
    'Small, faithful moments shape a life of prayer. Today is one of those moments.',
    'Bring your worries with you. God has room for them all.',
  ];
}