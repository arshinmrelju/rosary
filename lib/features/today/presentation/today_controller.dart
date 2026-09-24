import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/dependencies.dart';
import '../../../domain/models/announcement.dart';
import '../../../domain/models/break_slot.dart';
import '../../../domain/models/campaign_settings.dart';
import '../../../domain/models/daily_content.dart';
import '../../../domain/models/day_participation.dart';
import '../../../domain/models/day_stats.dart';
import '../../../domain/models/rosary_break.dart';
import '../../../domain/schedule/break_day_state.dart';
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
  CampaignSettings? _campaign;
  Announcement? _announcement;
  DateTime _now = clockNow();
  Timer? _ticker;
  bool _netArmed = false;

  bool get isLoading => _loading;
  String? get error => _error;
  BreakSchedule? get schedule => _schedule;
  DayParticipation? get participation => _participation;
  DailyContent? get content => _content;
  DayStats? get stats => _stats;
  CampaignSettings? get campaign => _campaign;
  Announcement? get announcement => _announcement;

  /// Whether organizers have paused the campaign (students see a calm note).
  bool get campaignPaused => _campaign?.paused ?? false;

  DateTime get now => _now;
  bool get isOffline => _deps.networkStatus.isOffline;

  /// The next break to pray per the schedule, or null when all done.
  BreakSlot? get nextBreak => _schedule?.nextBreakToPray(_now);

  /// The five breaks of today, materialised for the UI to describe.
  List<RosaryBreak> get breaks =>
      _schedule == null ? const <RosaryBreak>[] : _schedule!.breaksOn(_now, _now);

  int get completedCount => _participation?.totalCompleted ?? 0;

  int get nextDecadeNumber => nextBreak?.decadeNumber ?? 0;

  int get remainingCount {
    final schedule = _schedule;
    if (schedule == null) return 0;
    return schedule.remainingCount();
  }

  bool get dayEnded => _schedule?.dayEndedAt(_now) ?? false;

  /// Precomputed snapshot of the college day at [_now].
  BreakDayState? get dayState => _schedule?.stateAt(_now);

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
        _deps.campaignRepository.fetch(),
        _deps.announcementsRepository.fetchActive(),
      ]);

      final schedule = results[0] as BreakSchedule;
      final participation = results[1] as DayParticipation;
      final content = results[2] as DailyContent?;
      final stats = results[3] as DayStats;
      final campaign = results[4] as CampaignSettings?;
      final announcement = results[5] as Announcement?;

      _schedule = _markCompleted(schedule, participation);
      _participation = participation;
      _content = content;
      _stats = stats;
      _campaign = campaign;
      _announcement = announcement;
      _now = now;
      _loading = false;
      notifyListeners();

      // If the network returned while we were offline, push queued progress
      // back up — idempotently — then refresh.
      _armSyncIfNeeded();
    } catch (e) {
      _error = 'We could not load today\'s Rosary. Please check your connection.';
      debugLog('Today load failed: $e');
      _loading = false;
      notifyListeners();
    }
  }

  /// Watches connectivity and replays offline completions once back online.
  void _armSyncIfNeeded() {
    if (_netArmed || !isOffline) return;
    _netArmed = true;
    _deps.networkStatus.addListener(_onNetworkBack);
  }

  void _onNetworkBack() {
    if (_deps.networkStatus.isOffline) return;
    _deps.networkStatus.removeListener(_onNetworkBack);
    _netArmed = false;
    debugLog('network back — syncing pending participation');
    _deps.participationRepository.syncPending().then((_) => load());
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
      final previous = _now;
      _now = clockNow();
      if (!isSameDay(previous, _now)) {
        // Date rolled over while the app was open — reload the new day.
        load();
        return;
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    if (_netArmed) _deps.networkStatus.removeListener(_onNetworkBack);
    super.dispose();
  }
}