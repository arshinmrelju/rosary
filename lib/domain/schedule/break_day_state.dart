import '../models/break_slot.dart';
import '../models/break_status.dart';

/// The overall "where is the college day now" phase, driving the Home hero and
/// the Today screen header.
///
/// The break time is a reminder, never a restriction: every phase still
/// leaves every incomplete decade open to pray.
enum BreakDayPhase {
  /// No break has started yet today.
  beforeFirstBreak,

  /// One of the five breaks is currently in its window.
  breakIsActive,

  /// The most recent break in its window has passed without being completed —
  /// the user can still pray it, any time.
  breakEnded,

  /// Breaks are running on schedule; the next one has not started yet.
  nextBreak,

  /// All five decades are completed for today.
  dayComplete,
}

/// Computed, immutable snapshot of the day at one instant.
///
/// All date/time judgement for the college day is centralised here (produced
/// by [BreakDayState.compute]) so the UI never re-implements "is it break
/// time?" logic.
class BreakDayState {
  const BreakDayState({
    required this.phase,
    required this.completedCount,
    this.activeBreak,
    this.justEndedBreak,
    this.nextUpcomingBreak,
    this.nextToPray,
  });

  final BreakDayPhase phase;
  final int completedCount;

  /// The break currently inside its active window (may be null).
  final BreakSlot? activeBreak;

  /// The most recent break whose window has passed but is not completed —
  /// the user is invited to catch it up.
  final BreakSlot? justEndedBreak;

  /// The soonest break that has not started yet.
  final BreakSlot? nextUpcomingBreak;

  /// The decade the user is recommended to pray next (PRAY NOW target).
  final BreakSlot? nextToPray;

  static const int totalDecades = 5;

  bool get allCompleted => completedCount >= totalDecades;

  /// Strongest signal describing what to show next. Prefers a break that is
  /// happening now, then the most recent ended-but-incomplete break (catch
  /// up), then the earliest upcoming break.
  static BreakDayState compute(List<BreakSlot> slots, DateTime now) {
    final active = <BreakSlot>[];
    final missed = <BreakSlot>[];
    final upcoming = <BreakSlot>[];
    var completedCount = 0;

    for (final slot in slots) {
      switch (slot.statusAt(now, completed: slot.isCompleted)) {
        case BreakStatus.active:
          active.add(slot);
        case BreakStatus.missed:
          missed.add(slot);
        case BreakStatus.upcoming:
          upcoming.add(slot);
        case BreakStatus.completed:
          completedCount++;
      }
    }

    int byTime(BreakSlot a, BreakSlot b) =>
        a.time.minutesSinceMidnight.compareTo(b.time.minutesSinceMidnight);

    active.sort(byTime);
    // Most recently passed first (largest start time).
    missed.sort((a, b) => b.time.minutesSinceMidnight.compareTo(a.time.minutesSinceMidnight));
    upcoming.sort(byTime);

    final activeBreak = active.isNotEmpty ? active.first : null;

    // A missed break deserves "catch it up now" emphasis only while we are in
    // the first half of the gap to the next break. Past the midpoint the app
    // shifts its recommendation to the next upcoming break; the missed decade
    // remains open and prayable, just no longer the spotlight target.
    final nearestMissed = missed.isNotEmpty ? missed.first : null;
    BreakSlot? justEndedBreak;
    if (nearestMissed != null) {
      final nextIndex = upcoming.indexWhere(
          (u) => u.time.minutesSinceMidnight > nearestMissed.time.minutesSinceMidnight);
      if (nextIndex < 0) {
        justEndedBreak = nearestMissed;
      } else {
        final gapEnd = upcoming[nextIndex].time.at(now);
        final gapStart = nearestMissed.endOn(now);
        final elapsed = now.difference(gapStart);
        if (elapsed * 2 < gapEnd.difference(gapStart)) {
          justEndedBreak = nearestMissed;
        }
      }
    }

    final nextUpcomingBreak = upcoming.isNotEmpty ? upcoming.first : null;

    // Recommended path stays sequential; active/just-ended take priority.
    BreakSlot? nextToPray = activeBreak ?? justEndedBreak ?? nextUpcomingBreak;
    nextToPray ??= missed.isNotEmpty ? missed.last : null;

    final phase = switch ((completedCount, activeBreak, justEndedBreak, nextUpcomingBreak)) {
      (final n, _, _, _) when n >= totalDecades => BreakDayPhase.dayComplete,
      (_, final a, _, _) when a != null => BreakDayPhase.breakIsActive,
      (_, _, final j, _) when j != null => BreakDayPhase.breakEnded,
      (_, _, _, final u) when u != null => BreakDayPhase.nextBreak,
      _ => BreakDayPhase.beforeFirstBreak,
    };

    return BreakDayState(
      phase: phase,
      completedCount: completedCount,
      activeBreak: activeBreak,
      justEndedBreak: justEndedBreak,
      nextUpcomingBreak: nextUpcomingBreak,
      nextToPray: nextToPray,
    );
  }
}