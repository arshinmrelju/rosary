import 'decade.dart';

/// The five Mystery sets of the Rosary.
///
/// Standard Catholic practice assigns sets to weekday groups. The app keeps
/// these as a static reference so daily content (from Firebase or mock data)
/// can look up the correct decades for a given day.
enum MysterySet {
  joyful('Joyful Mysteries', <String>[
    'The Annunciation',
    'The Visitation',
    'The Nativity',
    'The Presentation in the Temple',
    'The Finding in the Temple',
  ]),
  sorrowful('Sorrowful Mysteries', <String>[
    'The Agony in the Garden',
    'The Scourging at the Pillar',
    'The Crowning with Thorns',
    'The Carrying of the Cross',
    'The Crucifixion',
  ]),
  glorious('Glorious Mysteries', <String>[
    'The Resurrection',
    'The Ascension',
    'The Descent of the Holy Spirit',
    'The Assumption of Mary',
    'The Coronation of Mary',
  ]),
  luminous('Luminous Mysteries', <String>[
    'The Baptism in the Jordan',
    'The Wedding at Cana',
    'The Proclamation of the Kingdom',
    'The Transfiguration',
    'The Institution of the Eucharist',
  ]);

  const MysterySet(this.title, this.mysteries);

  final String title;
  final List<String> mysteries;

  List<Decade> get decades => <Decade>[
    for (var i = 0; i < mysteries.length; i++)
      Decade(number: i + 1, mysteryTitle: mysteries[i]),
  ];

  /// The set traditionally prayed on [weekday]
  /// (1 = Monday … 7 = Sunday).
  static MysterySet forWeekday(int weekday) {
    switch (weekday) {
      case DateTime.tuesday:
      case DateTime.friday:
        return MysterySet.sorrowful;
      case DateTime.wednesday:
      case DateTime.sunday:
        return MysterySet.glorious;
      case DateTime.thursday:
        return MysterySet.luminous;
      default:
        // Monday & Saturday
        return MysterySet.joyful;
    }
  }
}