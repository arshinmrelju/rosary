import 'package:flutter/widgets.dart';

import '../../../core/di/app_scope.dart';
import '../../../domain/models/admin_log_entry.dart';

/// Records an admin action into the audit trail. Best-effort: a failure in
/// the log write must never block the action it is recording.
Future<void> logAdminAction(
  BuildContext context,
  AdminLogAction action,
  String target,
) async {
  final deps = AppScope.of(context);
  final uid = deps.adminSession.user?.uid ?? 'unknown';
  try {
    await deps.adminLogRepository.log(uid, action, target);
  } catch (_) {
    // Audit logging is a bookkeeping concern, not a workflow blocker.
  }
}