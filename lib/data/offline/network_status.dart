import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../../core/constants/app_constants.dart';

/// Observes device connectivity and exposes a single, always-valid answer.
///
/// Defaults to "online" so missing platform support (web, tests, desktops)
/// never breaks the app. Screen-level code only ever reads [isOffline]; the
/// platform specifics are contained here.
class NetworkStatus extends ChangeNotifier {
  NetworkStatus() {
    _subscribe();
  }

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _offline = false;

  bool get isOffline => _offline;

  Future<void> _subscribe() async {
    try {
      _sub?.cancel();
      // Current state first.
      final results = await _connectivity.checkConnectivity();
      _apply(results);

      // Then live changes.
      _sub = _connectivity.onConnectivityChanged.listen(
        (results) => _apply(results),
        onError: (_) {},
      );
    } catch (e) {
      debugLog('connectivity unavailable: $e');
      _offline = false;
    }
  }

  void _apply(List<ConnectivityResult> results) {
    final offline =
        results.isEmpty ||
        results.every((r) => r == ConnectivityResult.none);
    if (offline != _offline) {
      _offline = offline;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}