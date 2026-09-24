import 'package:flutter_test/flutter_test.dart';

import 'package:rosary_break/data/notifications/local_notification_service.dart';
import 'package:rosary_break/data/notifications/notification_settings_store.dart';
import 'package:rosary_break/domain/models/notification_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationSettings (pure model)', () {
    test('defaults: all five breaks on, 2-minute heads-up, not quiet', () {
      const s = NotificationSettings();
      expect(s.masterEnabled, isTrue);
      expect(s.breakEnabled, everyElement(isTrue));
      expect(s.quiet, isFalse);
      expect(s.remindMinutes, NotificationSettings.defaultRemindMinutes);
      for (var n = 1; n <= 5; n++) {
        expect(s.showsAtBreak(n), isTrue);
        expect(s.showsPreReminder(n), isTrue);
      }
    });

    test('reduce reminders per-break and via master/quiet switches', () {
      final breaks = List<bool>.filled(5, true);
      breaks[2] = false;
      NotificationSettings s = const NotificationSettings()
          .copyWith(breakEnabled: breaks);
      expect(s.showsAtBreak(3), isFalse);
      expect(s.showsAtBreak(2), isTrue);

      s = s.copyWith(quiet: true);
      expect(s.showsPreReminder(2), isFalse);
      expect(s.showsAtBreak(2), isTrue);

      s = s.copyWith(quiet: false, remindMinutes: 0);
      expect(s.showsPreReminder(2), isFalse);
      expect(s.showsAtBreak(2), isTrue);

      s = s.copyWith(masterEnabled: false);
      expect(s.showsAtBreak(2), isFalse);
      expect(NotificationSettings.fromJson(s.toJson()).showsAtBreak(2), isFalse);
    });

    test('lock copyWith/fromJson/toJson round-trip', () {
      const s = NotificationSettings(
        masterEnabled: true,
        breakEnabled: <bool>[true, false, true, false, true],
        quiet: false,
        remindMinutes: 5,
      );
      final back = NotificationSettings.decode(s.encode());
      expect(back, s);
    });

    test('decode of garbage falls back to defaults without throwing', () {
      final s = NotificationSettings.decode('not json at all');
      expect(s, const NotificationSettings());
    });

    test('decode normalizes unknown remind minutes to the default', () {
      final s = NotificationSettings.fromJson(<String, dynamic>{
        'remindMinutes': 99,
      });
      expect(s.remindMinutes, NotificationSettings.defaultRemindMinutes);
    });
  });

  group('NotificationSettingsStore', () {
    test('persists and restores across store instances', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final store = await NotificationSettingsStore.create();
      expect(store.settings, const NotificationSettings());

      final updated = await store.update(
        (s) => s.copyWith(quiet: true, remindMinutes: 5),
      );
      expect(updated.quiet, isTrue);
      expect(updated.remindMinutes, 5);

      // A fresh store (simulating a relaunch) reads the same values back.
      final reopened = await NotificationSettingsStore.create();
      expect(reopened.settings, updated);
    });

    test('corrupt stored value falls back to defaults', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'rosary_break:notification_settings': 'garbage{{{',
      });
      final store = await NotificationSettingsStore.create();
      expect(store.settings, const NotificationSettings());
    });

    test('maybeSetDefaults only writes when absent', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final store = await NotificationSettingsStore.create();
      await store.maybeSetDefaults();
      expect(store.settings, const NotificationSettings());

      final reopened = await NotificationSettingsStore.create();
      expect(reopened.settings, const NotificationSettings());
    });
  });

  group('nextWallClockOccurrence', () {
    test('later today stays today', () {
      final now = DateTime(2026, 9, 26, 10, 0);
      expect(
        nextWallClockOccurrence(now, 11, 0),
        DateTime(2026, 9, 26, 11, 0),
      );
    });

    test('exactly now moves to tomorrow', () {
      final now = DateTime(2026, 9, 26, 11, 0);
      expect(
        nextWallClockOccurrence(now, 11, 0),
        DateTime(2026, 9, 27, 11, 0),
      );
    });

    test('already past moves to tomorrow', () {
      final now = DateTime(2026, 9, 26, 12, 5);
      expect(
        nextWallClockOccurrence(now, 11, 0),
        DateTime(2026, 9, 27, 11, 0),
      );
    });

    test('crosses month boundaries correctly', () {
      expect(
        nextWallClockOccurrence(DateTime(2026, 10, 31, 23, 0), 11, 0),
        DateTime(2026, 11, 1, 11, 0),
      );
      expect(
        nextWallClockOccurrence(DateTime(2026, 12, 31, 23, 0), 11, 0),
        DateTime(2027, 1, 1, 11, 0),
      );
    });
  });
}