import '../models/break_slot.dart';
import '../models/break_time.dart';
import 'break_schedule.dart';
import 'break_schedule_source.dart';

/// In-memory, static schedule used until the schedule comes from
/// Firebase/Admin.
///
/// This is the SINGLE place the five break times are defined.
///
///   1. 11:00 AM → Decade 1
///   2. 12:05 PM → Decade 2
///   3. 1:00 PM  → Decade 3
///   4. 2:00 PM  → Decade 4
///   5. 3:00 PM  → Decade 5
///
/// To let an admin change these later, implement [BreakScheduleSource] with a
/// Firestore-backed source and swap it in `AppDependencies`.
class DefaultBreakScheduleSource implements BreakScheduleSource {
  @override
  Future<BreakSchedule> load({DateTime? date}) async {
    const List<(int, BreakTime)> definition = <(int, BreakTime)>[
      (1, BreakTime(11, 0)),
      (2, BreakTime(12, 5)),
      (3, BreakTime(13, 0)),
      (4, BreakTime(14, 0)),
      (5, BreakTime(15, 0)),
    ];

    final slots = <BreakSlot>[
      for (final (number, time) in definition)
        BreakSlot(
          breakNumber: number,
          time: time,
          decadeNumber: number,
          title: 'Decade $number',
        ),
    ];

    return BreakSchedule(slots);
  }
}