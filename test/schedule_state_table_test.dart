import 'package:flutter_test/flutter_test.dart';

import 'package:rosary_break/core/utils/formatters.dart';
import 'package:rosary_break/domain/models/break_slot.dart';
import 'package:rosary_break/domain/models/rosary_break.dart';
import 'package:rosary_break/domain/schedule/break_day_state.dart';
import 'package:rosary_break/domain/schedule/break_schedule.dart';
import 'package:rosary_break/domain/schedule/default_break_schedule_source.dart';

Future<BreakSchedule> _today() async => DefaultBreakScheduleSource().load();

BreakSchedule _withCompleted(BreakSchedule schedule, List<int> decades) =>
    BreakSchedule(<BreakSlot>[
      for (final slot in schedule.slots)
        slot.withCompletion(decades.contains(slot.decadeNumber)),
    ]);

DateTime _moment(int hour, int minute, {int day = 26}) =>
    DateTime(2026, 9, day, hour, minute);

/// The full schedule-state table from the design: one row per moment across
/// the college day, asserting phase, recommended decade and counts. The rows
/// at 11:00 (exactly at the start) and 11:04 (just past the window) pin the
/// 3-minute window boundary behaviour.
void main() {
  late BreakSchedule schedule;

  setUpAll(() async {
    schedule = await _today();
  });

  test('schedule exposes the five canonical break times', () {
    expect(schedule.slots.length, 5);
    expect(
      <String>[
        for (final s in schedule.slots) s.time.label,
      ],
      <String>['11:00 AM', '12:05 PM', '1:00 PM', '2:00 PM', '3:00 PM'],
    );
  });

  group('college-day timeline (untouched prayer state)', () {
    test('10:30 → before the first break, decade 1 at 11:00', () {
      final s = schedule.stateAt(_moment(10, 30));
      expect(s.phase, BreakDayPhase.nextBreak);
      expect(s.nextToPray?.decadeNumber, 1);
      expect(s.nextUpcomingBreak?.decadeNumber, 1);
    });

    test('10:59 → one minute before, still upcoming', () {
      final s = schedule.stateAt(_moment(10, 59));
      expect(s.phase, BreakDayPhase.nextBreak);
      expect(s.nextToPray?.decadeNumber, 1);
    });

    test('11:00 → break is active the moment it starts', () {
      final s = schedule.stateAt(_moment(11, 0));
      expect(s.phase, BreakDayPhase.breakIsActive);
      expect(s.activeBreak?.decadeNumber, 1);
    });

    test('11:02 → inside the 3-minute window, still active', () {
      final s = schedule.stateAt(_moment(11, 2));
      expect(s.phase, BreakDayPhase.breakIsActive);
      expect(s.activeBreak?.decadeNumber, 1);
    });

    test('11:04 → past the window (3 min), break ended, catch-up invited', () {
      final s = schedule.stateAt(_moment(11, 4));
      expect(s.phase, BreakDayPhase.breakEnded);
      expect(s.justEndedBreak?.decadeNumber, 1);
      expect(s.nextToPray?.decadeNumber, 1);
    });

    test('12:05 → second break active', () {
      final s = schedule.stateAt(_moment(12, 5));
      expect(s.phase, BreakDayPhase.breakIsActive);
      expect(s.activeBreak?.decadeNumber, 2);
    });

    test('1:00 → third break active', () {
      final s = schedule.stateAt(_moment(13, 0));
      expect(s.phase, BreakDayPhase.breakIsActive);
      expect(s.activeBreak?.decadeNumber, 3);
    });

    test('3:00 → fifth break active', () {
      final s = schedule.stateAt(_moment(15, 0));
      expect(s.phase, BreakDayPhase.breakIsActive);
      expect(s.activeBreak?.decadeNumber, 5);
    });

    test('4:00 → past the last break, still singling out decade 5', () {
      final s = schedule.stateAt(_moment(16, 0));
      expect(s.phase, BreakDayPhase.breakEnded);
      expect(s.nextToPray?.decadeNumber, 5);
      expect(schedule.dayEndedAt(_moment(16, 0)), isTrue);
    });

    test('before 11:00 the day has not ended', () {
      expect(schedule.dayEndedAt(_moment(10, 30)), isFalse);
      expect(schedule.dayEndedAt(_moment(15, 3)), isTrue);
    });
  });

  group('user states (partial / complete days)', () {
    test('all five completed → dayComplete regardless of time', () {
      final done = _withCompleted(schedule, const <int>[1, 2, 3, 4, 5]);
      final s = done.stateAt(_moment(14, 0));
      expect(s.phase, BreakDayPhase.dayComplete);
      expect(s.allCompleted, isTrue);
      expect(s.nextToPray, isNull);
      expect(done.remainingCount(), 0);
    });

    test('first two completed → third becomes next at midday', () {
      final done = _withCompleted(schedule, const <int>[1, 2]);
      final s = done.stateAt(_moment(12, 30));
      expect(s.completedCount, 2);
      expect(s.nextToPray?.decadeNumber, 3);
      expect(done.remainingCount(), 3);
    });

    test('completed counts do not reset at day-end', () {
      final done = _withCompleted(schedule, const <int>[1, 3, 5]);
      expect(done.completedCount(), 3);
      expect(done.dayEndedAt(_moment(23, 59)), isTrue);
    });
  });

  group('materialised breaks (rosaryBreaksForDay)', () {
    test('maps windows, titles and prayer state for one day', () {
      final done = _withCompleted(schedule, const <int>[1, 4]);
      final breaks = done.breaksOn(_moment(8, 0), _moment(8, 0));

      expect(breaks.length, 5);
      expect(breaks[0].decadeNumber, 1);
      expect(breaks[0].prayerCompleted, isTrue);
      expect(breaks[0].scheduledState, RosaryBreakState.completed);
      expect(breaks[1].decadeNumber, 2);
      expect(breaks[1].scheduledState, RosaryBreakState.upcoming);
      expect(breaks[1].isPrayable, isFalse);
      expect(breaks[3].prayerCompleted, isTrue);
    });

    test('break window = start + 3 default minutes', () {
      final breaks = schedule.breaksOn(_moment(8, 0), _moment(8, 0));
      expect(breaks[1].startTime, _moment(12, 5));
      expect(breaks[1].endTime, _moment(12, 8));
    });

    test('actively updating breaks when now is inside a window', () {
      final breaks = schedule.breaksOn(_moment(9, 26), _moment(11, 2));
      final first = breaks.firstWhere((b) => b.decadeNumber == 1);
      expect(first.scheduledState, RosaryBreakState.active);
      expect(first.endTime, _moment(11, 3));
    });
  });

  group('date rollover', () {
    test('breaks materialise on the correct calendar days', () {
      // Shortly before midnight the "day" is still 31 Oct.
      final evening = DateTime(2026, 10, 31, 22, 0);
      final octoberBreaks = schedule.breaksOn(evening, evening);
      expect(octoberBreaks.first.startTime, DateTime(2026, 10, 31, 11, 0));

      // After midnight the same schedule belongs to 1 Nov.
      final nextMorning = DateTime(2026, 11, 1, 1, 30);
      final novemberBreaks = schedule.breaksOn(nextMorning, nextMorning);
      expect(novemberBreaks.first.startTime, DateTime(2026, 11, 1, 11, 0));
    });
  });

  group('ordinal + countdown formatting', () {
    test('ordinal handles the irregular teens', () {
      expect(ordinal(1), '1st');
      expect(ordinal(2), '2nd');
      expect(ordinal(3), '3rd');
      expect(ordinal(4), '4th');
      expect(ordinal(11), '11th');
      expect(ordinal(12), '12th');
      expect(ordinal(13), '13th');
    });

    test('formatCountdown pads to hh:mm:ss', () {
      expect(formatCountdown(Duration.zero), '00:00:00');
      expect(formatCountdown(const Duration(seconds: 59)), '00:00:59');
      expect(formatCountdown(const Duration(minutes: 4, seconds: 32)), '00:04:32');
      expect(formatCountdown(const Duration(hours: 1, minutes: 5)), '01:05:00');
      expect(formatCountdown(const Duration(seconds: -5)), '00:00:00');
    });

    test('startsInCopy phrases the gap', () {
      expect(startsInCopy(const Duration(seconds: 30)), 'Starts in 30 seconds');
      expect(startsInCopy(const Duration(minutes: 1)), 'Starts in 1 minute');
      expect(startsInCopy(const Duration(minutes: 2)), 'Starts in 2 minutes');
      expect(startsInCopy(const Duration(hours: 1, minutes: 4)), 'Starts in 1 h 4 min');
      expect(startsInCopy(Duration.zero), 'Starting now');
    });
  });
}