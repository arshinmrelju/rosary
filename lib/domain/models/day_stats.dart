/// Daily community aggregate.
///
/// Document path: `stats/{date}`.
///
/// The counters are maintained transactionally (guarded by the per-user
/// participation record, which stays the source of truth) so a single tap or
/// refresh cannot inflate them.
class DayStats {
  const DayStats({
    required this.date,
    this.totalParticipants = 0,
    this.totalDecades = 0,
    this.totalIntentions = 0,
    this.totalPrayers = 0,
  });

  final String date;
  final int totalParticipants;
  final int totalDecades;
  final int totalIntentions;
  final int totalPrayers;

  /// True when no community activity has been recorded for this day yet.
  bool get isEmpty =>
      totalParticipants == 0 &&
      totalDecades == 0 &&
      totalIntentions == 0 &&
      totalPrayers == 0;

  factory DayStats.fromMap(Map<String, dynamic> map) => DayStats(
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