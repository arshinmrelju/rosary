import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/daily_content.dart';
import '../../domain/models/day_participation.dart';
import '../../core/utils/formatters.dart';

/// Tidy read/write/pending helpers over [SharedPreferences] for the offline
/// story.
///
/// The cache stores *yesterday-and-today's* essentials only: the schedule, the
/// daily content and per-day participation. Prayer text is static app data and
/// needs no cache. Nothing here knows about Firebase.
class LocalCache {
  LocalCache(this._prefs);

  final SharedPreferences _prefs;

  static const String _scheduleKey = 'rosary_break:cache:schedule';
  static const String _pendingKey = 'rosary_break:cache:pending_participation';
  static const String _contentPrefix = 'rosary_break:cache:daily_content';
  static const String _participationPrefix = 'rosary_break:cache:participation';

  static Future<LocalCache?> create() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return LocalCache(prefs);
    } catch (_) {
      return null;
    }
  }

  // ---------- Schedule ----------

  void scheduleStore(String encoded) {
    try {
      _prefs.setString(_scheduleKey, encoded);
    } catch (_) {}
  }

  String? get schedule => _prefs.getString(_scheduleKey);

  // ---------- Daily content ----------

  void contentStore(DateTime date, DailyContent content) {
    try {
      _prefs.setString('$_contentPrefix:${dateKey(date)}', jsonEncode(content.toMap()));
    } catch (_) {}
  }

  DailyContent? contentFor(DateTime date) {
    final raw = _prefs.getString('$_contentPrefix:${dateKey(date)}');
    if (raw == null) return null;
    try {
      return DailyContent.fromMap(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  // ---------- Participation ----------

  void participationStore(String userId, DayParticipation day) {
    try {
      _prefs.setString(
        '$_participationPrefix:$userId:${day.date}',
        jsonEncode(day.toMap()),
      );
    } catch (_) {}
  }

  DayParticipation? participationFor(String userId, DateTime date) {
    final raw = _prefs.getString('$_participationPrefix:$userId:${dateKey(date)}');
    if (raw == null) return null;
    try {
      return DayParticipation.fromMap(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// All cached days for [userId] (used for offline history).
  List<DayParticipation> allParticipation(String userId) {
    final prefix = '$_participationPrefix:$userId:';
    final byDate = <String, DayParticipation>{};
    for (final key in _prefs.getKeys()) {
      if (!key.startsWith(prefix)) continue;
      final raw = _prefs.getString(key);
      if (raw == null) continue;
      try {
        final day = DayParticipation.fromMap(jsonDecode(raw) as Map<String, dynamic>);
        byDate[day.date] = day;
      } catch (_) {}
    }
    final days = byDate.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return days;
  }

  // ---------- Pending sync queue ----------

  /// Queues a decade completion that could not reach the server yet.
  void enqueuePending(String userId, String date, int decadeNumber) {
    try {
      final items = pendingItems();
      items.add(<String, Object>{'userId': userId, 'date': date, 'decade': decadeNumber});
      _prefs.setString(_pendingKey, jsonEncode(items));
    } catch (_) {}
  }

  List<Map<String, Object>> pendingItems() {
    final raw = _prefs.getString(_pendingKey);
    if (raw == null) return <Map<String, Object>>[];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return <Map<String, Object>>[
        for (final item in list)
          if (item is Map) Map<String, Object>.from(item),
      ];
    } catch (_) {
      return <Map<String, Object>>[];
    }
  }

  /// Drops the given queue items (after they were applied server-side).
  void removePending(Iterable<Map<String, Object>> items) {
    try {
      String key(Object? v) => '$v';
      final removals = <(String, String, String)>[for (final item in items) (key(item['userId']), key(item['date']), key(item['decade']))];
      final remaining = <Map<String, Object>>[
        for (final item in pendingItems())
          if (!removals.contains((key(item['userId']), key(item['date']), key(item['decade'])))) item,
      ];
      _prefs.setString(_pendingKey, jsonEncode(remaining));
    } catch (_) {}
  }

  bool hasPending() => pendingItems().isNotEmpty;
}