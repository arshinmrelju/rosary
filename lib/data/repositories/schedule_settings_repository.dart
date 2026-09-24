import '../../domain/models/rosary_schedule_settings.dart';

/// Admin read/write access to the central break schedule
/// (`settings/rosarySchedule`). The student app reads the same document via
/// `FirestoreBreakScheduleSource`, so updates propagate automatically.
abstract interface class ScheduleSettingsRepository {
  Future<RosaryScheduleSettings?> fetch();

  Future<void> save(RosaryScheduleSettings settings);
}