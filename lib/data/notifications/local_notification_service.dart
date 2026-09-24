import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../core/utils/formatters.dart';
import '../../domain/models/break_slot.dart';
import '../../domain/models/notification_settings.dart';
import '../../domain/schedule/break_schedule.dart';
import 'notification_service.dart';

/// Local-notification implementation for Android + iOS.
///
/// * Compiles and no-ops on web (PWA reminder support arrives later).
/// * Everything is scheduled in the user's **local timezone** (see
///   [_ensureTimezone]) and repeated daily using `DateTimeComponents.time`, so
///   no daily re-scheduling or server clock is involved.
/// * Notification ids are deterministic per break, so re-applying settings is
///   a simple cancel-and-reschedule with no duplicates.
class LocalNotificationService implements NotificationService {
  LocalNotificationService();

  static const int _atBreakBase = 100;
  static const int _preBreakBase = 200;
  static const String _channelId = 'rosary_break_reminders';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final ValueNotifier<int?> _pendingDecade = ValueNotifier<int?>(null);
  bool _available = false;
  bool _tzReady = false;

  @override
  ValueListenable<int?> get pendingDecade => _pendingDecade;

  @override
  int? consumePendingDecade() {
    final value = _pendingDecade.value;
    _pendingDecade.value = null;
    return value;
  }

  bool get _supportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Future<void> initialize() async {
    if (_available || !_supportedPlatform) return;
    try {
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      );
      await _plugin.initialize(
        settings,
        onDidReceiveNotificationResponse: _onResponse,
      );
      _available = true;
      await _consumeLaunchDetails();
    } catch (e) {
      _available = false;
    }
  }

  void _onResponse(NotificationResponse response) {
    final decade = int.tryParse(response.payload ?? '');
    if (decade != null && decade >= 1 && decade <= 5) {
      _pendingDecade.value = decade;
    }
  }

  Future<void> _consumeLaunchDetails() async {
    try {
      final launch = await _plugin.getNotificationAppLaunchDetails();
      final response = launch?.notificationResponse;
      if (launch?.didNotificationLaunchApp == true && response != null) {
        _onResponse(response);
      }
    } catch (_) {
      // Cold-start details unavailable — reminders still scheduled.
    }
  }

  @override
  Future<bool?> requestPermission() async {
    if (!_available) return null;
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final granted = await _plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
        return granted == true;
      }
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final granted = await _plugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, badge: true, sound: true);
        return granted == true;
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  @override
  Future<bool> hasPermission() async {
    if (!_available) return false;
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        return await _plugin
                .resolvePlatformSpecificImplementation<
                    AndroidFlutterLocalNotificationsPlugin>()
                ?.areNotificationsEnabled() ??
            false;
      }
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final result = await _plugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.checkPermissions();
        return result?.isEnabled ?? false;
      }
    } catch (_) {
      return false;
    }
    return false;
  }

  Future<void> _ensureTimezone() async {
    if (_tzReady) return;
    tz_data.initializeTimeZones();
    try {
      if (_supportedPlatform) {
        final name = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(name));
      }
    } catch (_) {
      // Could not resolve the IANA name — `tz.local` stays UTC and scheduling
      // still works (the trigger instant is computed from local wall-clock and
      // converted through the zone instance).
    }
    _tzReady = true;
  }

  @override
  Future<void> applySettings(
    BreakSchedule schedule,
    NotificationSettings settings,
  ) async {
    if (!_available) return;
    await _ensureTimezone();
    await cancelAll();
    final now = DateTime.now();

    for (var decade = 1; decade <= 5; decade++) {
      if (!settings.showsAtBreak(decade)) continue;
      final slot = schedule.slotForDecade(decade);
      final breakAt = _nextOccurrence(now, slot.time.hour, slot.time.minute);
      await _schedule(
        id: _atBreakBase + decade,
        title: '📿 Rosary Break',
        body: 'Take ${_windowLabel(slot)} for the ${ordinal(decade)} decade.',
        trigger: breakAt,
        decade: decade,
      );
      if (settings.showsPreReminder(decade)) {
        final remindAt = breakAt.subtract(Duration(minutes: settings.remindMinutes));
        await _schedule(
          id: _preBreakBase + decade,
          title: '📿 Rosary Break in ${settings.remindMinutes} minutes',
          body: 'Your ${ordinal(decade)} decade is coming up.\n'
              'Take a few minutes with Mary.',
          trigger: remindAt,
          decade: decade,
        );
      }
    }
  }

  String _windowLabel(BreakSlot slot) {
    final minutes = slot.activeWindow.inMinutes;
    return '$minutes minute${minutes == 1 ? '' : 's'}';
  }

  /// The next wall-clock occurrence of `hour:minute` in the local zone,
  /// i.e. today if still ahead of [now], otherwise tomorrow.
  ///
  /// Top-level and pure so the date logic is unit-testable without plugins.
  DateTime _nextOccurrence(DateTime now, int hour, int minute) =>
      nextWallClockOccurrence(now, hour, minute);

  Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required DateTime trigger,
    required int decade,
  }) async {
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(trigger, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            'Rosary Break Reminders',
            channelDescription:
                'Gentle reminders for your five daily decades.',
            importance: Importance.high,
            priority: Priority.high,
            category: AndroidNotificationCategory.reminder,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
            presentBadge: false,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: '$decade',
      );
    } catch (_) {
      // Scheduling on this device failed — reminder is skipped, never fatal.
    }
  }

  @override
  Future<void> cancelAll() async {
    if (!_available) return;
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }
}

/// The next local wall-clock occurrence of `hour:minute`: today if still in
/// the future, otherwise tomorrow. Pure so the scheduling math can be tested.
DateTime nextWallClockOccurrence(DateTime now, int hour, int minute) {
  var candidate = DateTime(now.year, now.month, now.day, hour, minute);
  if (!candidate.isAfter(now)) {
    candidate = DateTime(now.year, now.month, now.day + 1, hour, minute);
  }
  return candidate;
}