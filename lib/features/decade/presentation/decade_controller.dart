import 'package:flutter/foundation.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/dependencies.dart';
import '../../../domain/models/break_slot.dart';
import '../../../domain/models/daily_content.dart';
import '../../../domain/models/decade.dart';
import '../../../domain/models/day_participation.dart';
import '../../../domain/schedule/break_schedule.dart';

/// Loads and exposes everything the Today's Decade screen renders.
class DecadeController extends ChangeNotifier {
  DecadeController(this._deps, this.decadeNumber);

  final AppDependencies _deps;
  final int decadeNumber;

  bool _loading = true;
  String? _error;
  BreakSchedule? _schedule;
  DayParticipation? _participation;
  DailyContent? _content;

  bool _submitting = false;
  String? _submitError;

  bool get isLoading => _loading;
  String? get error => _error;
  bool get isSubmitting => _submitting;
  String? get submitError => _submitError;

  BreakSchedule? get schedule => _schedule;
  DayParticipation? get participation => _participation;
  DailyContent? get content => _content;

  /// The slot for this decade, or null when the schedule is unavailable.
  BreakSlot? get slotForDecade => _schedule?.slotForDecade(decadeNumber);

  /// The decade's mystery (from today's content), with a sensible fallback.
  Decade get decade {
    final content = _content;
    final mysteryTitle = content?.decade(decadeNumber).mysteryTitle ?? 'Decade $decadeNumber';
    final focus = content?.decade(decadeNumber).focus;
    final scripture = content?.decade(decadeNumber).scripture;
    final reflection = content?.decade(decadeNumber).reflection;
    return Decade(
      number: decadeNumber,
      mysteryTitle: mysteryTitle,
      focus: focus,
      scripture: scripture,
      reflection: reflection,
    );
  }

  /// Today's mystery set title, or a fallback when content is missing.
  String get mysterySetTitle =>
      _content?.mysterySetTitle ?? 'Rosary Mysteries';

  /// Today's intention (may be empty when content is unpublished).
  String get intention => _content?.intention ?? '';

  /// Number of decades completed today (for the completion summary).
  int get completedCount => _participation?.totalCompleted ?? 0;

  bool get isCompleted =>
      _participation?.isDecadeCompleted(decadeNumber) ?? false;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final userId = await _deps.authService.ensureUserId();
      final now = clockNow();
      final content = await _deps.dailyContentRepository.fetch(now);
      _content = content;

      final results = await Future.wait<Object?>([
        _deps.breakScheduleSource.load(date: now),
        _deps.participationRepository.fetch(userId, now),
      ]);
      _schedule = results[0] as BreakSchedule;
      _participation = results[1] as DayParticipation;
      _loading = false;
      notifyListeners();
    } catch (e) {
      debugLog('decade load failed: $e');
      _error = 'We could not load this decade. Please try again.';
      _loading = false;
      notifyListeners();
    }
  }

  /// Persists completion of this decade. Returns true on success.
  Future<bool> completeDecade() async {
    if (_submitting) return false;
    _submitting = true;
    _submitError = null;
    notifyListeners();

    try {
      final userId = await _deps.authService.ensureUserId();
      final updated = await _deps.participationRepository.completeDecade(
        userId,
        clockNow(),
        decadeNumber,
      );
      _participation = updated;
      _submitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugLog('decade complete failed: $e');
      _submitError =
          'We could not save your progress right now. Please try again.';
      _submitting = false;
      notifyListeners();
      return false;
    }
  }
}