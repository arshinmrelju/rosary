/// A clock time (no date). Kept free of Flutter imports so it can be used in
/// the pure Dart domain layer and mapped to Firestore later.
class BreakTime {
  const BreakTime(this.hour, this.minute);

  final int hour;
  final int minute;

  /// Minutes since midnight, used for ordering and range comparisons.
  int get minutesSinceMidnight => hour * 60 + minute;

  /// `h:mm AM/PM` label, e.g. `1:00 PM`.
  String get label {
    final period = hour >= 12 ? 'PM' : 'AM';
    final h12 = hour % 12 == 0 ? 12 : hour % 12;
    final m = minute.toString().padLeft(2, '0');
    return '$h12:$m $period';
  }

  bool isAfter(BreakTime other) =>
      minutesSinceMidnight > other.minutesSinceMidnight;

  bool isBefore(BreakTime other) =>
      minutesSinceMidnight < other.minutesSinceMidnight;

  /// True when this time falls inside `[start, end]` (inclusive).
  bool isBetween(BreakTime start, BreakTime end) =>
      minutesSinceMidnight >= start.minutesSinceMidnight &&
      minutesSinceMidnight <= end.minutesSinceMidnight;

  /// Build a [DateTime] on [day] at this time.
  DateTime at(DateTime day) =>
      DateTime(day.year, day.month, day.day, hour, minute);

  factory BreakTime.fromDateTime(DateTime dateTime) =>
      BreakTime(dateTime.hour, dateTime.minute);

  @override
  bool operator ==(Object other) =>
      other is BreakTime && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  String toString() => label;
}