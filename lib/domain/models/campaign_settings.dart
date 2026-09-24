import 'break_time.dart';

/// Central campaign configuration managed by Super Admins.
///
/// Document path: `settings/campaign`.
///
/// When [paused] is `true` the student UI shows a calm message instead of
/// pushing breaks, giving organizers a single switch to control the campaign.
class CampaignSettings {
  const CampaignSettings({
    this.name = 'ROSARY BREAK',
    this.startDate,
    this.endDate,
    this.collegeStart = const BreakTime(10, 0),
    this.collegeEnd = const BreakTime(16, 0),
    this.timezone = 'Asia/Kolkata',
    this.paused = false,
  });

  final String name;

  /// Campaign start (date portion used).
  final DateTime? startDate;

  /// Campaign end (date portion used).
  final DateTime? endDate;

  /// When the college teaching day starts (informational).
  final BreakTime collegeStart;

  /// When the college teaching day ends (informational).
  final BreakTime collegeEnd;

  final String timezone;

  /// When `true`, students see a gentle notice instead of the break schedule.
  final bool paused;

  bool get isActive => !paused;

  /// Whether [date] falls inside the configured campaign window.
  bool covers(DateTime date) {
    final start = startDate;
    final end = endDate;
    if (start == null && end == null) return true;
    if (start != null &&
        date.isBefore(DateTime(start.year, start.month, start.day))) {
      return false;
    }
    if (end != null &&
        date.isAfter(
          DateTime(end.year, end.month, end.day, 23, 59, 59),
        )) {
      return false;
    }
    return true;
  }

  CampaignSettings copyWith({
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    BreakTime? collegeStart,
    BreakTime? collegeEnd,
    String? timezone,
    bool? paused,
  }) => CampaignSettings(
    name: name ?? this.name,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    collegeStart: collegeStart ?? this.collegeStart,
    collegeEnd: collegeEnd ?? this.collegeEnd,
    timezone: timezone ?? this.timezone,
    paused: paused ?? this.paused,
  );

  factory CampaignSettings.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic raw) => raw is String ? DateTime.tryParse(raw) : null;

    return CampaignSettings(
      name: map['name'] as String? ?? 'ROSARY BREAK',
      startDate: parseDate(map['startDate']),
      endDate: parseDate(map['endDate']),
      collegeStart: _parseTime(map['collegeStart']) ?? const BreakTime(10, 0),
      collegeEnd: _parseTime(map['collegeEnd']) ?? const BreakTime(16, 0),
      timezone: map['timezone'] as String? ?? 'Asia/Kolkata',
      paused: map['paused'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'name': name,
    if (startDate != null)
      'startDate': _dateOnly(startDate!).toIso8601String()
    else
      'startDate': '',
    if (endDate != null)
      'endDate': _dateOnly(endDate!).toIso8601String()
    else
      'endDate': '',
    'collegeStart': _encodeTime(collegeStart),
    'collegeEnd': _encodeTime(collegeEnd),
    'timezone': timezone,
    'paused': paused,
  };

  static BreakTime? _parseTime(dynamic raw) {
    if (raw is String) {
      final parts = raw.split(':');
      if (parts.length == 2) {
        final h = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        if (h != null && m != null) return BreakTime(h, m);
      }
    }
    if (raw is Map<String, dynamic>) {
      final h = raw['hour'] as int?;
      final m = raw['minute'] as int?;
      if (h != null && m != null) return BreakTime(h, m);
    }
    return null;
  }

  static String _encodeTime(BreakTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}