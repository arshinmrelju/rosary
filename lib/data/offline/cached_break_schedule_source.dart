import 'dart:convert';

import '../../domain/models/break_slot.dart';
import '../../domain/models/break_time.dart';
import '../../domain/schedule/break_schedule.dart';
import '../../domain/schedule/break_schedule_source.dart';
import 'local_cache.dart';

/// Schedule source that caches the last successfully-loaded schedule and
/// serves it offline so break times still guide the day without a network.
///
/// The schedule is (deliberately) a once-a-day static read for now; the cache
/// simply makes it last through a network outage. A Firestore-backed source can
/// replace the delegate without changing callers.
class CachedBreakScheduleSource implements BreakScheduleSource {
  const CachedBreakScheduleSource(this._delegate, this._cache);

  final BreakScheduleSource _delegate;
  final LocalCache _cache;

  @override
  Future<BreakSchedule> load({DateTime? date}) async {
    try {
      final schedule = await _delegate.load(date: date);
      _cache.scheduleStore(_encode(schedule));
      return schedule;
    } catch (_) {
      final cached = _cache.schedule;
      if (cached == null) rethrow;
      final decoded = _decode(cached);
      if (decoded != null) return decoded;
      rethrow;
    }
  }

  String _encode(BreakSchedule schedule) => jsonEncode(<Object>[
    for (final slot in schedule.slots)
      <String, Object>{
        'breakNumber': slot.breakNumber,
        'hour': slot.time.hour,
        'minute': slot.time.minute,
        'decadeNumber': slot.decadeNumber,
        'title': slot.title,
        'isCompleted': slot.isCompleted,
        'windowMinutes': slot.activeWindow.inMinutes,
      },
  ]);

  BreakSchedule? _decode(String raw) {
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final slots = <BreakSlot>[
        for (final item in list)
          if (item is Map<String, dynamic>)
            BreakSlot(
              breakNumber: item['breakNumber'] as int,
              time: BreakTime(
                item['hour'] as int,
                item['minute'] as int,
              ),
              decadeNumber: item['decadeNumber'] as int,
              title: item['title'] as String,
              isCompleted: item['isCompleted'] as bool? ?? false,
              activeWindow: Duration(minutes: item['windowMinutes'] as int? ?? 3),
            ),
      ];
      return slots.isEmpty ? null : BreakSchedule(slots);
    } catch (_) {
      return null;
    }
  }
}