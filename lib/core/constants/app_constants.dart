import 'package:flutter/foundation.dart';

/// Brand-level constants shared across the app.
///
/// Keep display strings here so the brand stays consistent and can be
/// updated from a single place.
abstract final class AppConstants {
  static const String appName = 'Rosary Break';
  static const String tagline = 'Five breaks. Five decades. One Rosary.';

  static const String secondaryTagline =
      'Pray one decade during each college break.';

  /// The five decades of one Rosary.
  static const int totalDecades = 5;

  /// First grade (year) offered by the college, used for the year picker.
  static const int minYear = 1;

  /// Last grade (year) offered by the college, used for the year picker.
  static const int maxYear = 4;

  /// Colleges department names shown in the Profile screen picker.
  static const List<String> departments = <String>[
    'Engineering',
    'Business',
    'Arts & Sciences',
    'Health Sciences',
    'Computing',
    'Other',
  ];
}

/// Debug helper that only logs on debug builds to keep release output clean.
void debugLog(String message) {
  assert(() {
    debugPrint('[RosaryBreak] $message');
    return true;
  }());
}