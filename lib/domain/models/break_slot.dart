import 'break_status.dart';
import 'break_time.dart';

/// One scheduled break of the college day.
///
/// Break N always maps to Decade N (1-based). The status is derived at query
/// time from the current time and the user's participation, so this model
/// stays immutable and free of Flutter dependencies.
class BreakSlot {
  const BreakSlot({
    required this.breakNumber,
    required this.time,
    required this.decadeNumber,
    required this.title,
    this.isCompleted = false,
  });

  /// 1-based break number (Break 1 … Break 5).
  final int breakNumber;

  /// Wall-clock time of the break.
  final BreakTime time;

  /// 1-based decade number (Decade 1 … Decade 5). Equals [breakNumber].
  final int decadeNumber;

  /// Short title, e.g. the mystery name for this decade.
  final String title;

  /// Whether the current user completed the decade for this break.
  final bool isCompleted;

  /// Date-time on [day] when this break happens.
  DateTime on(DateTime day) => time.at(day);

  /// Status of this break at [now] with the given completion state.
  BreakStatus statusAt(DateTime now, {required bool completed}) {
    if (completed) return BreakStatus.completed;

    final start = time.at(now);
    if (now.isBefore(start)) return BreakStatus.upcoming;

    // The break is "active" during and up to one hour after its start
    // (covers the whole break window before the next one begins).
    final windowEnd = start.add(const Duration(minutes: 60));
    if (!now.isAfter(windowEnd)) return BreakStatus.active;

    return BreakStatus.missed;
  }

  BreakSlot withCompletion(bool completed) =>
      BreakSlot(
        breakNumber: breakNumber,
        time: time,
        decadeNumber: decadeNumber,
        title: title,
        isCompleted: completed,
      );

  @override
  String toString() => 'Break $breakNumber @ ${time.label}';
}