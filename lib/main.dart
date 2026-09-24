import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'data/dependencies.dart';
import 'data/firebase/firebase_starter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load `.env` values (used when present; mock mode otherwise).
  try {
    await dotenv.load(fileName: 'assets/env/.env');
    AppConfig.instance.apply(dotenv.env);
  } catch (e) {
    // Missing .env is expected in mock mode — the app never crashes.
    debugPrint('[RosaryBreak] No .env found, running in mock mode.');
  }

  // Start Firebase only when explicitly configured.
  await FirebaseStarter.start();

  final dependencies = await AppDependencies.create();

  // Start local reminders (no-ops on platforms without them) and restore the
  // day's schedule from the persisted preferences. Rescheduling is idempotent:
  // applySettings cancels and rebuilds, so this is safe on every launch.
  try {
    await dependencies.notificationService.initialize();
    final schedule = await dependencies.breakScheduleSource.load();
    await dependencies.notificationService.applySettings(
      schedule,
      dependencies.notificationSettingsStore.settings,
    );
  } catch (e) {
    // Reminders are an invitation, never a blocker — a scheduling failure at
    // startup must not prevent the app from launching.
    debugPrint('[RosaryBreak] Reminder setup skipped: $e');
  }

  // Resolve any existing admin session so /admin is ready immediately.
  await dependencies.adminSession.restore();

  runApp(RosaryBreakApp(dependencies: dependencies));
}