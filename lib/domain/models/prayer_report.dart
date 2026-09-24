/// Moderation status of a reported prayer intention.
enum ReportStatus {
  pending('pending'),
  reviewed('reviewed'),
  dismissed('dismissed');

  const ReportStatus(this.key);

  final String key;

  static ReportStatus fromKey(String? key) {
    for (final status in ReportStatus.values) {
      if (status.key == key) return status;
    }
    return ReportStatus.pending;
  }
}

/// A report raised against a prayer intention.
///
/// Document path: `reports/{reportId}`. Students create these (status always
/// `pending`); admins review / dismiss them and optionally hide the content.
class PrayerReport {
  const PrayerReport({
    this.id,
    required this.intentionId,
    required this.reason,
    this.note,
    this.createdAt,
    this.status = ReportStatus.pending,
    this.reporterUserId,
    this.intentionText,
  });

  final String? id;
  final String intentionId;

  /// Short reason code, e.g. "inappropriate", "spam", "other".
  final String reason;

  /// Optional free-text detail from the reporter.
  final String? note;

  final DateTime? createdAt;
  final ReportStatus status;

  final String? reporterUserId;

  /// Snapshot of the reported intention text at report time (denormalised so
  /// moderators can still see context after the intention is hidden/deleted).
  final String? intentionText;

  PrayerReport copyWith({
    ReportStatus? status,
    DateTime? createdAt,
    String? intentionText,
  }) => PrayerReport(
    id: id,
    intentionId: intentionId,
    reason: reason,
    note: note,
    createdAt: createdAt ?? this.createdAt,
    status: status ?? this.status,
    reporterUserId: reporterUserId,
    intentionText: intentionText ?? this.intentionText,
  );

  factory PrayerReport.fromMap(String id, Map<String, dynamic> map) {
    final createdAt = map['createdAt'] is String
        ? DateTime.tryParse(map['createdAt'] as String)
        : map['createdAt'] is DateTime
        ? map['createdAt'] as DateTime
        : null;
    return PrayerReport(
      id: id,
      intentionId: map['intentionId'] as String? ?? '',
      reason: map['reason'] as String? ?? '',
      note: map['note'] as String?,
      createdAt: createdAt,
      status: ReportStatus.fromKey(map['status'] as String?),
      reporterUserId: map['reporterUserId'] as String?,
      intentionText: map['intentionText'] as String?,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'intentionId': intentionId,
    'reason': reason,
    if (note != null) 'note': note,
    'createdAt': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    'status': status.key,
    if (reporterUserId != null) 'reporterUserId': reporterUserId,
    if (intentionText != null) 'intentionText': intentionText,
  };
}