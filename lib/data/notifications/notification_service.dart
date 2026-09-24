import 'package:flutter/foundation.dart';

import '../../domain/models/notification_settings.dart';
import '../../domain/schedule/break_schedule.dart';

/// Contract for the reminder system. UI and controllers depend on this
/// interface only — swapping web push for local notifications later never
/// touches screens.
abstract interface class NotificationService {
  /// Initialises platform channels. Safe to call more than once; no-ops on
  /// platforms without local notifications (web).
  Future<void> initialize();

  /// Requests notification permission. Returns `true` when granted, `false`
  /// when denied and `null` when the platform can't answer (e.g. web).
  Future<bool?> requestPermission();

  /// Whether the user has already granted permission.
  Future<bool> hasPermission();

  /// (Re)schedules the daily reminders for [settings] against [schedule].
  ///
  /// Idempotent: previous reminders are cancelled first, then every enabled
  /// break gets its "at break" notification and (unless quiet / off) a
  /// pre-break reminder. Uses the device's local timezone.
  Future<void> applySettings(
    BreakSchedule schedule,
    NotificationSettings settings,
  );

  /// Turns every scheduled reminder off.
  Future<void> cancelAll();

  /// The decade a tapped notification asked the user to open (null = none).
  ///
  /// Set both when the app was already running and on cold start (launch
  /// details). Listeners should navigate to that decade once.
  ValueListenable<int?> get pendingDecade;

  /// Returns the decade from a notification tap, clearing it.
  int? consumePendingDecade();
}