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

  runApp(RosaryBreakApp(dependencies: dependencies));
}