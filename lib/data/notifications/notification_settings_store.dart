import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/notification_settings.dart';

/// Persists [NotificationSettings] locally and notifies listeners on change.
///
/// Kept separate from the notification *scheduler* so the settings UI works
/// (and is testable) even on platforms where local notifications are
/// unavailable.
class NotificationSettingsStore extends ChangeNotifier {
  NotificationSettingsStore._(this._prefs, this._settings);

  final SharedPreferences? _prefs;
  NotificationSettings _settings;

  static const String _key = 'rosary_break:notification_settings';

  static Future<NotificationSettingsStore> create() async {
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (_) {
      prefs = null;
    }
    var settings = const NotificationSettings();
    try {
      final raw = prefs?.getString(_key);
      if (raw != null) settings = NotificationSettings.decode(raw);
    } catch (_) {
      // Ignore corrupt storage; defaults apply.
    }
    return NotificationSettingsStore._(prefs, settings);
  }

  NotificationSettings get settings => _settings;

  bool get masterEnabled => _settings.masterEnabled;

  /// Persists [next] and notifies listeners. Returns the stored settings.
  Future<NotificationSettings> save(NotificationSettings next) async {
    _settings = next;
    notifyListeners();
    final prefs = _prefs;
    if (prefs != null) {
      try {
        await prefs.setString(_key, next.encode());
      } catch (_) {
        // Storage unavailable — in-memory settings still apply for the session.
      }
    }
    return _settings;
  }

  Future<NotificationSettings> update(NotificationSettings Function(NotificationSettings) change) =>
      save(change(_settings));

  Future<void> maybeSetDefaults() async {
    if (_prefs?.getString(_key) == null) {
      await save(const NotificationSettings());
    }
  }
}