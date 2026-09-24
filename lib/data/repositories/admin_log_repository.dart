import '../../domain/models/admin_log_entry.dart';

/// The admin audit trail (`adminLogs/{logId}`).
abstract interface class AdminLogRepository {
  /// Records an action taken by an admin. Never stores sensitive content.
  Future<void> log(
    String adminUserId,
    AdminLogAction action,
    String target,
  );

  Future<List<AdminLogEntry>> fetchRecent({int limit = 50});
}