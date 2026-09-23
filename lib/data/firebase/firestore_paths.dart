/// Central mapping of Firestore collection/document paths.
///
/// Keep every path literal here so repositories and future admin/scheduler
/// code never type paths inline.
abstract final class FirestorePaths {
  static const String users = 'users'; // users/{userId}

  static const String dailyContent = 'dailyContent'; // dailyContent/{date}

  /// participation/{userId}/days/{date}
  static String participationDay(String userId, String date) =>
      'participation/$userId/days/$date';

  static const String prayerIntentions = 'prayerIntentions'; // {intentionId}

  static const String stats = 'stats'; // stats/{date}
}