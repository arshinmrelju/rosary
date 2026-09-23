import 'package:firebase_core/firebase_core.dart';

import '../constants/app_constants.dart';

/// Runtime configuration loaded from `assets/env/.env` (see `.env.example`).
///
/// Values are collated here and vended to Firebase initialisation. The app
/// runs in a Firebase-less MOCK mode unless `USE_FIREBASE=true` and a complete
/// set of Firebase values was provided.
class AppConfig {
  AppConfig._();

  static final AppConfig instance = AppConfig._();

  bool _loaded = false;
  String _useFirebase = 'false';
  String _apiKey = '';
  String _authDomain = '';
  String _projectId = '';
  String _appId = '';
  String _storageBucket = '';
  String _messagingSenderId = '';
  String _measurementId = '';

  bool get loaded => _loaded;

  void apply(Map<String, String> values) {
    String v(String key) => values[key]?.trim() ?? '';

    _useFirebase = v('USE_FIREBASE');
    _apiKey = v('FIREBASE_API_KEY');
    _authDomain = v('FIREBASE_AUTH_DOMAIN');
    _projectId = v('FIREBASE_PROJECT_ID');
    _appId = v('FIREBASE_APP_ID');
    _storageBucket = v('FIREBASE_STORAGE_BUCKET');
    _messagingSenderId = v('FIREBASE_MESSAGING_SENDER_ID');
    _measurementId = v('FIREBASE_MEASUREMENT_ID');
    _loaded = true;
  }

  bool get shouldUseFirebase => _useFirebase.toLowerCase() == 'true';

  bool get hasCompleteFirebaseConfig =>
      _apiKey.isNotEmpty &&
      _projectId.isNotEmpty &&
      _appId.isNotEmpty &&
      _messagingSenderId.isNotEmpty;

  /// Whether the app should initialise and talk to real Firebase services.
  bool get canUseFirebase =>
      shouldUseFirebase && hasCompleteFirebaseConfig;

  /// Firebase options consumed by `Firebase.initializeApp`.
  ///
  /// Returns `null` when not configured; the caller then stays in mock mode.
  FirebaseOptions? get firebaseOptions {
    if (!canUseFirebase) return null;
    return FirebaseOptions(
      apiKey: _apiKey,
      authDomain: _authDomain.isEmpty ? null : _authDomain,
      projectId: _projectId,
      storageBucket: _storageBucket.isEmpty ? null : _storageBucket,
      messagingSenderId: _messagingSenderId,
      appId: _appId,
      measurementId: _measurementId.isEmpty ? null : _measurementId,
    );
  }

  void logStatus() {
    debugLog('Firebase enabled: $canUseFirebase');
    if (!canUseFirebase && shouldUseFirebase) {
      debugLog('USE_FIREBASE=true but config is incomplete - running in mock mode.');
    }
  }
}