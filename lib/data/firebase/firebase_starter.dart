import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/app_constants.dart';

/// Idempotent Firebase bootstrap.
///
/// Call once from `main()` before running the app. When configuration is
/// missing the app simply stays in mock mode and this returns `false`.
class FirebaseStarter {
  static bool _initialized = false;

  /// Initialises Firebase and returns `true` when remote services are live.
  static Future<bool> start() async {
    if (_initialized) return true;

    final config = AppConfig.instance;
    config.logStatus();

    if (!config.canUseFirebase) return false;

    await Firebase.initializeApp(
      name: kIsWeb ? 'rosary-break' : null,
      options: config.firebaseOptions,
    );
    _initialized = true;
    debugLog('Firebase initialised.');
    return true;
  }
}