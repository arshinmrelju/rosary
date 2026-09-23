import '../../core/utils/formatters.dart';

/// A user's per-day progress.
///
/// Document path: `participation/{userId}/days/{date}`.
class DayParticipation {
  const DayParticipation({
    required this.date,
    this.decade1 = false,
    this.decade2 = false,
    this.decade3 = false,
    this.decade4 = false,
    this.decade5 = false,
    this.lastUpdated,
  });

  factory DayParticipation.empty(DateTime date) =>
      DayParticipation(date: dateKey(date));

  /// `yyyy-MM-dd` day key.
  final String date;

  final bool decade1;
  final bool decade2;
  final bool decade3;
  final bool decade4;
  final bool decade5;
  final DateTime? lastUpdated;

  bool isDecadeCompleted(int number) {
    switch (number) {
      case 1:
        return decade1;
      case 2:
        return decade2;
      case 3:
        return decade3;
      case 4:
        return decade4;
      case 5:
        return decade5;
      default:
        return false;
    }
  }

  int get totalCompleted =>
      <bool>[decade1, decade2, decade3, decade4, decade5]
          .where((v) => v)
          .length;

  factory DayParticipation.fromMap(Map<String, dynamic> map) =>
      DayParticipation(
        date: map['date'] as String? ?? '',
        decade1: map['decade1'] as bool? ?? false,
        decade2: map['decade2'] as bool? ?? false,
        decade3: map['decade3'] as bool? ?? false,
        decade4: map['decade4'] as bool? ?? false,
        decade5: map['decade5'] as bool? ?? false,
        lastUpdated: map['lastUpdated'] is String
            ? DateTime.tryParse(map['lastUpdated'] as String)
            : map['lastUpdated'] is DateTime
            ? map['lastUpdated'] as DateTime
            : null,
      );

  Map<String, dynamic> toMap() => <String, dynamic>{
    'date': date,
    'decade1': decade1,
    'decade2': decade2,
    'decade3': decade3,
    'decade4': decade4,
    'decade5': decade5,
    'totalCompleted': totalCompleted,
    'lastUpdated': lastUpdated?.toIso8601String(),
  };
}