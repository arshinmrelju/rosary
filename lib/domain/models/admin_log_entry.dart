/// Actions recorded in the admin audit log (`adminLogs/{logId}`).
enum AdminLogAction {
  publishedDailyContent('PUBLISHED_DAILY_CONTENT'),
  savedDailyContentDraft('SAVED_DAILY_CONTENT_DRAFT'),
  deletedDailyContent('DELETED_DAILY_CONTENT'),
  approvedPrayerIntention('APPROVED_PRAYER_INTENTION'),
  rejectedPrayerIntention('REJECTED_PRAYER_INTENTION'),
  hidPrayerIntention('HID_PRAYER_INTENTION'),
  deletedPrayerIntention('DELETED_PRAYER_INTENTION'),
  reviewedReport('REVIEWED_REPORT'),
  dismissedReport('DISMISSED_REPORT'),
  updatedSchedule('UPDATED_SCHEDULE'),
  updatedCampaign('UPDATED_CAMPAIGN'),
  pausedCampaign('PAUSED_CAMPAIGN'),
  resumedCampaign('RESUMED_CAMPAIGN'),
  createdAnnouncement('CREATED_ANNOUNCEMENT'),
  updatedAnnouncement('UPDATED_ANNOUNCEMENT'),
  deletedAnnouncement('DELETED_ANNOUNCEMENT'),
  grantedAdmin('GRANTED_ADMIN'),
  revokedAdmin('REVOKED_ADMIN'),
  importedBulkContent('IMPORTED_BULK_CONTENT'),
  reviewedReportAndHidden('REVIEWED_REPORT_AND_HID');

  const AdminLogAction(this.key);

  final String key;

  static AdminLogAction? fromKey(String? key) {
    for (final action in AdminLogAction.values) {
      if (action.key == key) return action;
    }
    return null;
  }
}

/// One entry in the admin audit trail.
///
/// Document path: `adminLogs/{logId}`. Contains no sensitive student data —
/// only who acted, what they did and what they acted on.
class AdminLogEntry {
  const AdminLogEntry({
    this.id,
    required this.adminUserId,
    required this.action,
    required this.target,
    this.timestamp,
  });

  final String? id;
  final String adminUserId;
  final AdminLogAction action;

  /// Human readable target, e.g. "2026-10-01 daily content".
  final String target;

  final DateTime? timestamp;

  factory AdminLogEntry.fromMap(String id, Map<String, dynamic> map) {
    final timestamp = map['timestamp'] is String
        ? DateTime.tryParse(map['timestamp'] as String)
        : map['timestamp'] is DateTime
        ? map['timestamp'] as DateTime
        : null;
    return AdminLogEntry(
      id: id,
      adminUserId: map['adminUserId'] as String? ?? '',
      action: AdminLogAction.fromKey(map['action'] as String?) ??
          AdminLogAction.updatedCampaign,
      target: map['target'] as String? ?? '',
      timestamp: timestamp,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'adminUserId': adminUserId,
    'action': action.key,
    'target': target,
    'timestamp': timestamp?.toIso8601String() ?? DateTime.now().toIso8601String(),
  };
}