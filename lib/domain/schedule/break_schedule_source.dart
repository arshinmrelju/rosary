import 'break_schedule.dart';

/// Source of the day's [BreakSchedule].
///
/// The default implementation ships with hardcoded college-day times. A
/// Firestore-backed implementation can be dropped in later (Admin section)
/// without touching any UI code.
abstract interface class BreakScheduleSource {
  Future<BreakSchedule> load({DateTime? date});
}