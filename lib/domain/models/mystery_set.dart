import 'decade.dart';

/// The five Mystery sets of the Rosary.
///
/// Standard Catholic practice assigns sets to weekday groups. The app keeps
/// these as a static reference so daily content (from Firebase or mock data)
/// can look up the correct decades for a given day.
///
/// Each mystery ships with a short scripture quote and reflection default.
/// Daily content from an admin overrides these per-decade when present.
enum MysterySet {
  joyful(
    'Joyful Mysteries',
    <String>[
      'The Annunciation',
      'The Visitation',
      'The Nativity',
      'The Presentation in the Temple',
      'The Finding in the Temple',
    ],
    <String>[
      '"Behold, I am the handmaid of the Lord. Let it be done to me according to your word."',
      '"Blessed are you among women, and blessed is the fruit of your womb."',
      '"She gave birth to her firstborn son, and placed him in a manger."',
      '"When the days of their purification were completed, they brought him to the temple."',
      '"When his parents found him, he said, \'Did you not know I must be in my Father\'s house?\'"',
    ],
  ),
  sorrowful(
    'Sorrowful Mysteries',
    <String>[
      'The Agony in the Garden',
      'The Scourging at the Pillar',
      'The Crowning with Thorns',
      'The Carrying of the Cross',
      'The Crucifixion',
    ],
    <String>[
      '"My Father, if it is possible, let this cup pass from me; yet not as I will, but as you will."',
      '"He was pierced for our offenses, crushed for our sins."',
      '"They wove a crown of thorns and placed it on his head."',
      '"Whoever wishes to come after me must carry his cross."',
      '"Father, forgive them, for they know not what they do."',
    ],
  ),
  glorious(
    'Glorious Mysteries',
    <String>[
      'The Resurrection',
      'The Ascension',
      'The Descent of the Holy Spirit',
      'The Assumption of Mary',
      'The Coronation of Mary',
    ],
    <String>[
      '"He is not here; he has been raised just as he said."',
      '"As he blessed them he parted from them and was taken up to heaven."',
      '"They were all filled with the Holy Spirit."',
      '"Blessed is she who believed that what was spoken to her would be fulfilled."',
      '"A great sign appeared in the sky: a woman clothed with the sun."',
    ],
  ),
  luminous(
    'Luminous Mysteries',
    <String>[
      'The Baptism in the Jordan',
      'The Wedding at Cana',
      'The Proclamation of the Kingdom',
      'The Transfiguration',
      'The Institution of the Eucharist',
    ],
    <String>[
      '"This is my beloved Son, with whom I am well pleased."',
      '"Do whatever he tells you."',
      '"The kingdom of God is at hand. Repent and believe in the Gospel."',
      '"Lord, it is good that we are here."',
      '"This is my body given for you; do this in memory of me."',
    ],
  );

  const MysterySet(this.title, this.mysteries, this.scriptures);

  final String title;
  final List<String> mysteries;

  /// Scripture quote for each mystery, parallel to [mysteries].
  final List<String> scriptures;

  static const String defaultReflection =
      'Take a slow breath. Let this mystery sit with you while you pray the ten Hail Marys.';

  List<Decade> get decades => <Decade>[
    for (var i = 0; i < mysteries.length; i++)
      Decade(
        number: i + 1,
        mysteryTitle: mysteries[i],
        scripture: i < scriptures.length ? scriptures[i] : null,
        reflection: defaultReflection,
      ),
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