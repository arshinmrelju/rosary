import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/dependencies.dart';
import '../../../domain/models/break_slot.dart';
import '../../../domain/models/daily_content.dart';
import '../../../domain/models/day_participation.dart';
import '../../../domain/models/day_stats.dart';
import '../../../domain/schedule/break_schedule.dart';

/// Loads and exposes the current day's state: schedule, participation,
/// daily content and community stats.
///
/// Uses a lightweight ChangeNotifier + periodic timer pattern (no external
/// state-management package). Swaps to Firebase repositories automatically
/// depending on the runtime configuration.
class TodayController extends ChangeNotifier {
  TodayController(this._deps);

  final AppDependencies _deps;

  bool _loading = true;
  String? _error;
  BreakSchedule? _schedule;
  DayParticipation? _participation;
  DailyContent? _content;
  DayStats? _stats;
  DateTime _now = clockNow();
  Timer? _ticker;

  bool get isLoading => _loading;
  String? get error => _error;
  BreakSchedule? get schedule => _schedule;
  DayParticipation? get participation => _participation;
  DailyContent? get content => _content;
  DayStats? get stats => _stats;
  DateTime get now => _now;

  /// The next break to pray per the schedule, or null when all done.
  BreakSlot? get nextBreak => _schedule?.nextBreakToPray(_now);

  int get completedCount => _participation?.totalCompleted ?? 0;

  int get nextDecadeNumber => nextBreak?.decadeNumber ?? 0;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    _startTicker();

    try {
      final userId = await _deps.authService.ensureUserId();
      final now = clockNow();

      final results = await Future.wait<Object?>(<Future<Object?>>[
        _deps.breakScheduleSource.load(date: now),
        _deps.participationRepository.fetch(userId, now),
        _deps.dailyContentRepository.fetch(now),
        _deps.statsRepository.fetch(now),
      ]);

      final schedule = results[0] as BreakSchedule;
      final participation = results[1] as DayParticipation;
      final content = results[2] as DailyContent?;
      final stats = results[3] as DayStats;

      _schedule = _markCompleted(schedule, participation);
      _participation = participation;
      _content = content;
      _stats = stats;
      _now = now;
      _loading = false;
      notifyListeners();
    } catch (e) {
      _error = 'We could not load today\'s Rosary. Please check your connection.';
      debugLog('Today load failed: $e');
      _loading = false;
      notifyListeners();
    }
  }

  BreakSchedule _markCompleted(
    BreakSchedule schedule,
    DayParticipation participation,
  ) {
    final updatedSlots = <BreakSlot>[
      for (final slot in schedule.slots)
        slot.withCompletion(
          participation.isDecadeCompleted(slot.decadeNumber),
        ),
    ];
    return BreakSchedule(updatedSlots);
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      _now = clockNow();
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}