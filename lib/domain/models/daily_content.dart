import 'decade.dart';

/// The daily content shown to every student for a given calendar day.
///
/// Document path: `dailyContent/{date}` where `date` is `yyyy-MM-dd`.
class DailyContent {
  const DailyContent({
    required this.date,
    required this.mysterySetTitle,
    required this.intention,
    this.theme,
    this.scripture,
    this.reflection,
    this.decades = const <Decade>[],
    this.published = true,
  });

  /// `yyyy-MM-dd` document key.
  final String date;

  /// Title of the Mystery set, e.g. "Joyful Mysteries".
  final String mysterySetTitle;

  /// Today's prayer intention, e.g. "For peace in our community".
  final String intention;

  /// One-line theme framing the day, e.g. "Saying yes to God".
  final String? theme;

  /// Optional top-level scripture for the day (groups the mystery set).
  final String? scripture;

  /// Optional short reflection shared with all students.
  final String? reflection;

  /// The five decades (mysteries) for this day.
  final List<Decade> decades;

  /// Whether an admin has published this content for students.
  final bool published;

  Decade decade(int number) =>
      decades.firstWhere(
        (d) => d.number == number,
        orElse: () => Decade(number: number, mysteryTitle: 'Decade $number'),
      );

  factory DailyContent.fromMap(Map<String, dynamic> map) {
    final rawDecades = map['decades'] as List? ?? const <dynamic>[];
    // Accept both `mysteryType` (current) and `mystery` (initial seed) keys.
    final mysteryType = map['mysteryType'] as String? ?? map['mystery'] as String?;
    return DailyContent(
      date: map['date'] as String? ?? '',
      mysterySetTitle: mysteryType ?? 'Rosary Mysteries',
      intention: map['intention'] as String? ?? '',
      theme: map['theme'] as String?,
      scripture: map['scripture'] as String?,
      reflection: map['reflection'] as String?,
      published: map['published'] as bool? ?? true,
      decades: <Decade>[
        for (var i = 0; i < rawDecades.length; i++)
          if (rawDecades[i] is Map<String, dynamic>)
            Decade.fromMap(
              rawDecades[i]! as Map<String, dynamic>,
              i + 1,
            ),
      ],
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'date': date,
    'mysteryType': mysterySetTitle,
    'intention': intention,
    if (theme != null) 'theme': theme,
    if (scripture != null) 'scripture': scripture,
    if (reflection != null) 'reflection': reflection,
    'decades': <Map<String, dynamic>>[
      for (final d in decades) d.toMap(),
    ],
    'published': published,
  };
}