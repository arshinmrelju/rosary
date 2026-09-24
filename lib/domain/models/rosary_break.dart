import 'break_slot.dart';
import 'break_time.dart';

/// Scheduled state of one break — the calendar, not the prayer.
///
/// This is intentionally distinct from [BreakSlot.isCompleted]: a break can be
/// `missed` on the clock while the corresponding decade is still un-prayed,
/// and the user can always start it later.
enum RosaryBreakState {
  /// The break has not started yet and is not the immediate next target.
  before,

  /// The break is happening right now (inside its window).
  active,

  /// The break's window has passed and the decade was completed.
  completed,

  /// The break's window has passed and the decade was not completed.
  missed,

  /// The break is the immediate "next" one the student should join.
  upcoming,
}

/// One scheduled break of the day, materialised for a concrete calendar day.
///
/// Exposes everything a screen needs — clock times as real local [DateTime]s,
/// the scheduled state (see [RosaryBreakState]) and the prayer state
/// ([prayerCompleted]) — so widgets describe, never calculate.
class RosaryBreak {
  const RosaryBreak({
    required this.id,
    required this.decadeNumber,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.scheduledState,
    required this.prayerCompleted,
  });

  /// Break identifier, 1-based ("Break 1 … Break 5").
  final int id;

  /// 1-based decade this break belongs to (equals [id]).
  final int decadeNumber;

  /// Short title, e.g. the mystery name for this decade.
  final String title;

  /// Local wall-clock start of the break on its calendar day.
  final DateTime startTime;

  /// End of the 3-minute prayer window (start + [BreakSlot.activeWindow]).
  final DateTime endTime;

  /// Clock state: before / active / completed / missed / upcoming.
  final RosaryBreakState scheduledState;

  /// Whether the user has prayed this decade (the prayer state).
  final bool prayerCompleted;

  /// Whether the user can begin praying this decade right now.
  ///
  /// True only once the break's window has opened or passed (active / missed)
  /// and the decade is unfinished. An `upcoming` or `before` break is the
  /// countdown target — the moment hasn't arrived, but nothing stops the user
  /// from opening it if they want to.
  bool get isPrayable =>
      !prayerCompleted &&
      (scheduledState == RosaryBreakState.active ||
          scheduledState == RosaryBreakState.missed);
}

/// Builds the five [RosaryBreak]s for a day from [slots].
///
/// [nextToPrayNumber] is the decade the scheduler recommends praying next; the
/// not-yet-started break that matches it becomes `upcoming` (countdown target)
/// while the others are `before`.
List<RosaryBreak> rosaryBreaksForDay({
  required List<BreakSlot> slots,
  required DateTime day,
  required DateTime now,
  int? nextToPrayNumber,
}) {
  final ordered = <BreakSlot>[
    ...slots,
  ]..sort((a, b) => a.time.minutesSinceMidnight.compareTo(b.time.minutesSinceMidnight));

  return <RosaryBreak>[
    for (final slot in ordered)
      _rosaryBreakForSlot(slot, day, now, nextToPrayNumber: nextToPrayNumber),
  ];
}

RosaryBreak _rosaryBreakForSlot(
  BreakSlot slot,
  DateTime day,
  DateTime now, {
  int? nextToPrayNumber,
}) {
  final start = slot.on(day);
  final end = slot.endOn(day);

  final scheduledState = switch (BreakTime.fromDateTime(now).minutesSinceMidnight) {
    _ when slot.isCompleted => RosaryBreakState.completed,
    _ when !now.isBefore(start) && now.isBefore(end) => RosaryBreakState.active,
    _ when !now.isBefore(end) => RosaryBreakState.missed,
    _ when nextToPrayNumber != null && slot.decadeNumber == nextToPrayNumber =>
      RosaryBreakState.upcoming,
    _ => RosaryBreakState.before,
  };

  return RosaryBreak(
    id: slot.breakNumber,
    decadeNumber: slot.decadeNumber,
    title: slot.title,
    startTime: start,
    endTime: end,
    scheduledState: scheduledState,
    prayerCompleted: slot.isCompleted,
  );
}