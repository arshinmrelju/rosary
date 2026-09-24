/// One decade of the Rosary: the mystery plus the ten Hail Marys guided text.
class Decade {
  const Decade({
    required this.number,
    required this.mysteryTitle,
    this.focus,
    this.scripture,
    this.reflection,
    this.prayers = const <String>[],
  });

  /// 1-based decade number (1 … 5).
  final int number;

  /// The mystery being contemplated, e.g. "The Annunciation".
  final String mysteryTitle;

  /// One-line contemplation focus shown on the Today's Decade screen.
  final String? focus;

  /// Short scripture quote connected to the mystery.
  final String? scripture;

  /// Personal reflection text shown before starting the decade.
  final String? reflection;

  /// Ordered prayer text shown while praying this decade. Empty when the
  /// detail prayers are rendered by the UI from standard Rosary steps.
  final List<String> prayers;

  factory Decade.fromMap(Map<String, dynamic> map, int number) => Decade(
    number: number,
    // Accept both `title` (published shape) and `mysteryTitle` (initial seed).
    mysteryTitle:
        map['mysteryTitle'] as String? ?? map['title'] as String? ?? 'Decade $number',
    focus: map['focus'] as String?,
    scripture: map['scripture'] as String?,
    reflection: map['reflection'] as String?,
    prayers: (map['prayers'] as List?)?.cast<String>() ?? const <String>[],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    'number': number,
    'mysteryTitle': mysteryTitle,
    'title': mysteryTitle,
    if (focus != null) 'focus': focus,
    if (scripture != null) 'scripture': scripture,
    if (reflection != null) 'reflection': reflection,
    'prayers': prayers,
  };
}