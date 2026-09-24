import 'package:flutter_test/flutter_test.dart';

import 'package:rosary_break/domain/schedule/break_day_state.dart';
import 'package:rosary_break/domain/schedule/break_schedule.dart';
import 'package:rosary_break/domain/schedule/default_break_schedule_source.dart';

Future<BreakSchedule> _today() =>
    DefaultBreakScheduleSource().load();

DateTime _day(int hour, int minute, {int day = 26}) =>
    DateTime(2026, 9, day, hour, minute);

/// A copy of [schedule] with the given [decadeNumbers] flagged as completed.
BreakSchedule _withCompleted(BreakSchedule schedule, List<int> decadeNumbers) =>
    BreakSchedule([
      for (final slot in schedule.slots)
        slot.withCompletion(decadeNumbers.contains(slot.decadeNumber)),
    ]);

void main() {
  test('before the first break → nextBreak phase pointing at break 1', () async {
    final schedule = await _today();
    final state = schedule.stateAt(_day(10, 30));
    expect(state.phase, BreakDayPhase.nextBreak);
    expect(state.nextToPray?.decadeNumber, 1);
    expect(state.nextToPray?.time.label, '11:00 AM');
    expect(state.completedCount, 0);
    expect(state.allCompleted, isFalse);
  });

  test('during the 11:00 break → breakIsActive on decade 1', () async {
    final schedule = await _today();
    final state = schedule.stateAt(_day(11, 1));
    expect(state.phase, BreakDayPhase.breakIsActive);
    expect(state.nextToPray?.decadeNumber, 1);
  });

  test('just after the break window → breakEnded, decade still advised', () async {
    final schedule = await _today();
    final state = schedule.stateAt(_day(11, 20));
    expect(state.phase, BreakDayPhase.breakEnded);
    expect(state.nextToPray?.decadeNumber, 1);
    expect(state.justEndedBreak?.decadeNumber, 1);
  });

  test('middle of span, nothing completed → decade 2 becomes next', () async {
    final schedule = await _today();
    final state = schedule.stateAt(_day(11, 45));
    expect(state.phase, BreakDayPhase.nextBreak);
    expect(state.nextToPray?.decadeNumber, 2);
    expect(state.justEndedBreak, isNull);
  });

  test('completed passes override catch-up phase', () async {
    final base = await _today();
    final prior = _withCompleted(base, const <int>[1, 2]);
    final state = prior.stateAt(_day(12, 30));
    expect(state.phase, BreakDayPhase.nextBreak);
    expect(state.completedCount, 2);
    expect(state.nextToPray?.decadeNumber, 3);
  });

  test('day completes when all five decades are completed', () async {
    final base = await _today();
    final prior = _withCompleted(base, const <int>[1, 2, 3, 4, 5]);
    final state = prior.stateAt(_day(16, 0));
    expect(state.phase, BreakDayPhase.dayComplete);
    expect(state.allCompleted, isTrue);
    expect(state.nextToPray, isNull);
  });
}
