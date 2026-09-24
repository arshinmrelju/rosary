import '../models/break_slot.dart';
import '../models/break_status.dart';
import '../models/rosary_break.dart';
import 'break_day_state.dart';

/// The complete set of breaks for one college day.
///
/// The default times are declared in exactly one place:
/// `DefaultBreakScheduleSource`. The UI never hardcodes times; it always reads
/// them from a [BreakSchedule] instance.
class BreakSchedule {
  const BreakSchedule(this.slots);

  /// All five slots ordered by break number.
  final List<BreakSlot> slots;

  static const int totalDecades = 5;

  BreakSlot slotForDecade(int decadeNumber) =>
      slots.firstWhere((s) => s.decadeNumber == decadeNumber, orElse: () => slots.first);

  /// Number of completed decades for the current user.
  int completedCount() => slots.where((s) => s.isCompleted).length;

  /// Number of decades still to pray today.
  int remainingCount() => totalDecades - completedCount();

  /// The five [RosaryBreak]s for [day] as they appear at [now].
  ///
  /// This is the single place that materialises breaks for the UI; widgets
  /// only read the resulting times and states.
  List<RosaryBreak> breaksOn(DateTime day, DateTime now) =>
      rosaryBreaksForDay(
        slots: slots,
        day: day,
        now: now,
        nextToPrayNumber: stateAt(now).nextToPray?.decadeNumber,
      );

  /// Last break's closing time on [day] (start of its window end).
  DateTime lastBreakEndsOn(DateTime day) {
    final last = <BreakSlot>[
      ...slots,
    ].reduce((a, b) => a.time.isAfter(b.time) ? a : b);
    return last.endOn(day);
  }

  /// Whether the whole college-day window has passed by [now].
  bool dayEndedAt(DateTime now) => !now.isBefore(lastBreakEndsOn(now));

  /// Snapshot of the whole college day at [now]: phase, next targets and
  /// completion count. All date/time logic flows through here.
  BreakDayState stateAt(DateTime now) => BreakDayState.compute(slots, now);

  /// A single break's status at [now], using its recorded completion state.
  BreakStatus statusOf(int decadeNumber, DateTime now) =>
      slotForDecade(decadeNumber).statusAt(now, completed: slotForDecade(decadeNumber).isCompleted);

  /// The next break the user should pray (PRAY NOW target).
  ///
  /// Delegates to [BreakDayState.compute]; kept as the friendly entry point
  /// used across screens.
  BreakSlot? nextBreakToPray(DateTime now) => BreakDayState.compute(slots, now).nextToPray;
}