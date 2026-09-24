/// Monthly community aggregate.
///
/// Document path: `monthlyStats/{yyyy-MM}`.
class MonthStats {
  const MonthStats({
    required this.date,
    this.totalParticipants = 0,
    this.totalDecades = 0,
    this.totalIntentions = 0,
    this.totalPrayers = 0,
  });

  /// `yyyy-MM` calendar-month key, e.g. `2026-10`.
  final String date;

  final int totalParticipants;
  final int totalDecades;
  final int totalIntentions;
  final int totalPrayers;

  /// True when no distinguishable community activity has been recorded yet.
  bool get isEmpty =>
      totalParticipants == 0 &&
      totalDecades == 0 &&
      totalIntentions == 0 &&
      totalPrayers == 0;

  factory MonthStats.fromMap(Map<String, dynamic> map) => MonthStats(
    date: map['date'] as String? ?? '',
    totalParticipants: map['totalParticipants'] as int? ?? 0,
    totalDecades: map['totalDecades'] as int? ?? 0,
    totalIntentions: map['totalIntentions'] as int? ?? 0,
    totalPrayers: map['totalPrayers'] as int? ?? 0,
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    'date': date,
    'totalParticipants': totalParticipants,
    'totalDecades': totalDecades,
    'totalIntentions': totalIntentions,
    'totalPrayers': totalPrayers,
  };
}