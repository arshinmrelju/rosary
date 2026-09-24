import 'package:flutter/foundation.dart';

/// Brand-level constants shared across the app.
///
/// Keep display strings here so the brand stays consistent and can be
/// updated from a single place.
abstract final class AppConstants {
  /// The official public-facing campaign name: BEAD5.
  /// Always treated as one complete brand name.
  static const String appName = 'BEAD5';

  /// Primary campaign tagline.
  static const String tagline = 'Five Moments. One Journey.';

  /// Secondary explanation tagline.
  static const String secondaryTagline =
      'Five moments throughout the college day. Five decades of the Rosary. One journey of prayer.';

  /// Campaign event subtitle.
  static const String campaignTitle = 'ROSARY MONTH';

  /// Campaign organizer.
  static const String organizer = 'Jesus Youth — Pazhassiraja College';

  /// Jesus Youth logo asset (SVG).
  static const String jesusYouthLogo = 'assets/yellow svg.svg';

  /// Short campus identifier.
  static const String campusShortName = 'JY PRC';

  /// Technical project identifier.
  static const String projectId = 'BEAD5JYPRC';

  /// Hosting domain URL.
  static const String hostingDomain = 'bead5jyprc.web.app';

  /// Core message.
  static const String coreMessage =
      "You don't need to stop your whole day for prayer. Give God five moments within it.";

  /// Short campaign message.
  static const String shortMessage = 'Pause. Pray. Continue the journey.';

  /// Prayer text length bounds enforced in `IntentionRepository.submit`.
  static const int intentionMinLength = 3;
  static const int intentionMaxLength = 280;

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