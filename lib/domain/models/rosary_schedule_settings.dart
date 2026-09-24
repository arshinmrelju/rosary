import 'break_slot.dart';
import 'break_time.dart';
import '../schedule/break_schedule.dart';

/// The centrally-stored Rosary break schedule.
///
/// Document path: `settings/rosarySchedule`. Super Admins edit this from the
/// Admin dashboard; the student app reads it automatically through
/// `FirestoreBreakScheduleSource`, so a schedule change takes effect on the
/// student app within one load.
class RosaryScheduleSettings {
  const RosaryScheduleSettings({
    this.breaks = const <BreakTime>[
      BreakTime(11, 0),
      BreakTime(12, 5),
      BreakTime(13, 0),
      BreakTime(14, 0),
      BreakTime(15, 0),
    ],
    this.timezone = 'Asia/Kolkata',
    this.durationMinutes = 3,
  });

  /// Exactly five break times (Break 1 … Break 5).
  final List<BreakTime> breaks;

  final String timezone;

  /// How long a break counts as "happening now" (the active window).
  final int durationMinutes;

  bool get isComplete {
    if (breaks.length < 5) return false;
    return breaks.every((b) => b.hour >= 0 && b.hour < 24 && b.minute >= 0 && b.minute < 60);
  }

  RosaryScheduleSettings copyWith({
    List<BreakTime>? breaks,
    String? timezone,
    int? durationMinutes,
  }) => RosaryScheduleSettings(
    breaks: breaks ?? this.breaks,
    timezone: timezone ?? this.timezone,
    durationMinutes: durationMinutes ?? this.durationMinutes,
  );

  /// Materialises the student-facing [BreakSchedule] from these settings.
  BreakSchedule toBreakSchedule() {
    final count = breaks.length >= 5 ? 5 : breaks.length;
    final slots = <BreakSlot>[
      for (var i = 0; i < count; i++)
        BreakSlot(
          breakNumber: i + 1,
          time: breaks[i],
          decadeNumber: i + 1,
          title: 'Decade ${i + 1}',
          activeWindow: Duration(minutes: durationMinutes),
        ),
    ];
    return BreakSchedule(slots);
  }

  factory RosaryScheduleSettings.fromMap(Map<String, dynamic> map) {
    final times = <BreakTime?>[
      for (var i = 1; i <= 5; i++) _parseBreak(map['break$i']),
    ];
    final parsed = times.whereType<BreakTime>().toList();

    List<BreakTime> result;
    if (parsed.length >= 5) {
      result = <BreakTime>[...parsed.take(5)];
    } else {
      result = <BreakTime>[
        const BreakTime(11, 0),
        const BreakTime(12, 5),
        const BreakTime(13, 0),
        const BreakTime(14, 0),
        const BreakTime(15, 0),
      ];
    }

    return RosaryScheduleSettings(
      breaks: result,
      timezone: map['timezone'] as String? ?? 'Asia/Kolkata',
      durationMinutes: map['durationMinutes'] as int? ?? 3,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    for (var i = 0; i < breaks.length; i++)
      'break${i + 1}': _encode(breaks[i]),
    'timezone': timezone,
    'durationMinutes': durationMinutes,
  };

  static BreakTime? _parseBreak(dynamic raw) {
    if (raw is String) {
      final parts = raw.split(':');
      if (parts.length == 2) {
        final h = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        if (h != null && m != null && h >= 0 && h < 24 && m >= 0 && m < 60) {
          return BreakTime(h, m);
        }
      }
    }
    return null;
  }

  static String _encode(BreakTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}