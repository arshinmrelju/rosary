/// Daily community aggregate.
///
/// Document path: `stats/{date}`.
class DayStats {
  const DayStats({
    required this.date,
    this.totalParticipants = 0,
    this.totalDecades = 0,
    this.totalIntentions = 0,
  });

  final String date;
  final int totalParticipants;
  final int totalDecades;
  final int totalIntentions;

  factory DayStats.fromMap(Map<String, dynamic> map) => DayStats(
    date: map['date'] as String? ?? '',
    totalParticipants: map['totalParticipants'] as int? ?? 0,
    totalDecades: map['totalDecades'] as int? ?? 0,
    totalIntentions: map['totalIntentions'] as int? ?? 0,
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    'date': date,
    'totalParticipants': totalParticipants,
    'totalDecades': totalDecades,
    'totalIntentions': totalIntentions,
  };
}