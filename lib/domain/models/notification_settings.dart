import 'dart:convert';

/// User-controlled reminder preferences.
///
/// Pure Dart so it can be unit-tested and serialised without Flutter, and
/// stored locally (SharedPreferences) until accounts make server-side syncing
/// worthwhile.
class NotificationSettings {
  const NotificationSettings({
    this.masterEnabled = true,
    this.breakEnabled = const <bool>[true, true, true, true, true],
    this.quiet = false,
    this.remindMinutes = defaultRemindMinutes,
  });

  /// Master switch: all reminders off when false.
  final bool masterEnabled;

  /// Per-break toggles indexed by decade (1…5). A user can turn off a single
  /// break (e.g. a class always runs through the 1:00 PM break).
  final List<bool> breakEnabled;

  /// Quiet mode: only the short at-break notification, no pre-reminders —
  /// gentle, never spammy.
  final bool quiet;

  /// Minutes before the break for the "coming up" reminder.
  ///
  /// One of [remindChoices]; 0 disables pre-reminders entirely.
  final int remindMinutes;

  static const int defaultRemindMinutes = 2;
  static const List<int> remindChoices = <int>[2, 5, 0];

  bool breakEnabledAt(int decadeNumber) => breakEnabled[decadeNumber - 1];

  /// True when the at-break notification for [decadeNumber] should fire.
  bool showsAtBreak(int decadeNumber) =>
      masterEnabled && breakEnabledAt(decadeNumber);

  /// True when the "X minutes before" reminder for [decadeNumber] should fire.
  bool showsPreReminder(int decadeNumber) =>
      !quiet && masterEnabled && breakEnabledAt(decadeNumber) && remindMinutes > 0;

  NotificationSettings copyWith({
    bool? masterEnabled,
    List<bool>? breakEnabled,
    bool? quiet,
    int? remindMinutes,
  }) =>
      NotificationSettings(
        masterEnabled: masterEnabled ?? this.masterEnabled,
        breakEnabled: breakEnabled ?? List<bool>.of(this.breakEnabled),
        quiet: quiet ?? this.quiet,
        remindMinutes: remindMinutes ?? this.remindMinutes,
      );

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    final raw = json['breakEnabled'] as List<dynamic>?;
    final breaks = <bool>[
      for (var i = 0; i < 5; i++)
        raw != null && i < raw.length ? raw[i] == true : true,
    ];
    final remind = json['remindMinutes'] as int? ?? defaultRemindMinutes;
    return NotificationSettings(
      masterEnabled: json['masterEnabled'] as bool? ?? true,
      breakEnabled: breaks,
      quiet: json['quiet'] as bool? ?? false,
      remindMinutes: remindChoices.contains(remind) ? remind : defaultRemindMinutes,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'masterEnabled': masterEnabled,
    'breakEnabled': breakEnabled,
    'quiet': quiet,
    'remindMinutes': remindMinutes,
  };

  String encode() => jsonEncode(toJson());

  static NotificationSettings decode(String raw) {
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return NotificationSettings.fromJson(map);
    } catch (_) {
      return const NotificationSettings();
    }
  }

  @override
  bool operator ==(Object other) =>
      other is NotificationSettings &&
      other.masterEnabled == masterEnabled &&
      other.quiet == quiet &&
      other.remindMinutes == remindMinutes &&
      _listEquals(other.breakEnabled, breakEnabled);

  @override
  int get hashCode => Object.hash(masterEnabled, quiet, remindMinutes, breakEnabled);

  static bool _listEquals(List<bool> a, List<bool> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  String toString() =>
      'Reminders(master=$masterEnabled, breaks=$breakEnabled, quiet=$quiet, remind=${remindMinutes}min)';
}