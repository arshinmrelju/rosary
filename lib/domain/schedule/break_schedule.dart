import '../models/break_slot.dart';
import '../models/break_status.dart';

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

  /// The next break the user should pray.
  ///
  /// - Prefers the break that is currently active.
  /// - Otherwise the next not-yet-passed incomplete break.
  /// - Falls back to the first incomplete break (for the home card before
  ///   the day starts or after the last break has passed).
  BreakSlot? nextBreakToPray(DateTime now) {
    final incomplete = slots.where((s) => !s.isCompleted).toList();
    if (incomplete.isEmpty) return null;

    final active = incomplete.where(
      (s) => s.statusAt(now, completed: s.isCompleted) == BreakStatus.active,
    );
    if (active.isNotEmpty) return active.first;

    final pending = incomplete
        .where(
          (s) => s.statusAt(now, completed: s.isCompleted) == BreakStatus.upcoming,
        )
        .toList()
      ..sort(
        (a, b) => a.time.minutesSinceMidnight.compareTo(b.time.minutesSinceMidnight),
      );
    if (pending.isNotEmpty) return pending.first;

    // Everything has passed but is incomplete → surface the first one so the
    // user can still catch up.
    return incomplete.first;
  }
}