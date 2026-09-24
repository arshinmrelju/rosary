/// Central mapping of Firestore collection/document paths.
///
/// Keep every path literal here so repositories and future admin/scheduler
/// code never type paths inline.
abstract final class FirestorePaths {
  static const String users = 'users'; // users/{userId}

  static const String dailyContent = 'dailyContent'; // dailyContent/{date}

  static const String participation = 'participation'; // participation/{userId}/days/{date}

  /// participation/{userId}/days/{date}
  static String participationDay(String userId, String date) =>
      'participation/$userId/days/$date';

  static const String prayerIntentions = 'prayerIntentions'; // prayerIntentions/{intentionId}

  /// Subcollection guarding one user's "I prayed for this" marker:
  /// prayerIntentions/{intentionId}/prayers/{userId}
  static const String prayers = 'prayers';

  static String intentionPrayer(String intentionId, String userId) =>
      'prayerIntentions/$intentionId/prayers/$userId';

  static const String stats = 'stats'; // stats/{date}

  static const String monthlyStats = 'monthlyStats'; // monthlyStats/{yyyy-MM}

  /// Per-user submission throttle: intentionSubmissions/{userId}
  static const String intentionSubmissions = 'intentionSubmissions';

  /// Subcollection of per-user participation markers for a month:
  /// monthlyStats/{yyyy-MM}/participants/{userId}
  ///
  /// Each marker exists at most once per user per month, which lets the
  /// transaction that records a decade completion increment
  /// `uniqueParticipants` exactly once per month per user without exposing
  /// any authentication identifier in the readable aggregate.
  static const String participants = 'participants';

  static String monthParticipant(String month, String userId) =>
      'monthlyStats/$month/participants/$userId';

  // ---------- Admin collections ----------

  /// admins/{uid} — the authoritative admin role store read by the rules.
  static const String admins = 'admins';

  /// settings/{settingId} — campaign + schedule configuration.
  static const String settings = 'settings';
  static const String campaignSetting = 'settings/campaign';
  static const String rosaryScheduleSetting = 'settings/rosarySchedule';

  /// announcements/{announcementId} — campaign announcements.
  static const String announcements = 'announcements';

  /// reports/{reportId} — flagged prayer intentions.
  static const String reports = 'reports';

  /// adminLogs/{logId} — the admin audit trail.
  static const String adminLogs = 'adminLogs';
}
