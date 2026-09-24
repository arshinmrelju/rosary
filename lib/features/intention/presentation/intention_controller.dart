import 'package:flutter/foundation.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/dependencies.dart';
import '../../../domain/models/day_stats.dart';
import '../../../domain/models/month_stats.dart';
import '../../../domain/models/prayer_intention.dart';
import '../../../data/repositories/intention_repository.dart';

/// Drives the Prayer Wall screen: loads approved intentions and the daily +
/// monthly community statistics, submits new (pending) intentions and records
/// the guarded "I prayed for this" interaction.
///
/// Pending submissions are intentionally routed to moderation and are never
/// added to the public list here.
class IntentionController extends ChangeNotifier {
  IntentionController(this._deps);

  final AppDependencies _deps;

  bool _loading = true;
  String? _error;
  List<PrayerIntention> _intentions = <PrayerIntention>[];
  DayStats? _dayStats;
  MonthStats? _monthStats;

  bool _submitting = false;
  String? _submitError;

  bool _praying = false;

  /// Intention ids this user/device already prayed for during this session.
  final Set<String> _prayedIds = <String>{};

  bool get isLoading => _loading;
  String? get error => _error;
  List<PrayerIntention> get intentions => _intentions;
  DayStats? get dayStats => _dayStats;
  MonthStats? get monthStats => _monthStats;
  bool get isSubmitting => _submitting;
  String? get submitError => _submitError;
  bool get isPraying => _praying;

  bool hasPrayed(String intentionId) => _prayedIds.contains(intentionId);

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final now = clockNow();
      final results = await Future.wait<Object?>(<Future<Object?>>[
        _deps.intentionRepository.fetchApproved(limit: 24),
        _deps.statsRepository.fetch(now),
        _deps.statsRepository.fetchMonth(now),
      ]);
      _intentions = results[0] as List<PrayerIntention>;
      _dayStats = results[1] as DayStats;
      _monthStats = results[2] as MonthStats;
      _loading = false;
      notifyListeners();
    } catch (e) {
      debugLog('prayer wall load failed: $e');
      _error = 'We could not load the prayer wall. Please try again.';
      _loading = false;
      notifyListeners();
    }
  }

  /// Submits a new intention (always pending). Returns true on success.
  Future<bool> submit(PrayerIntention intention) async {
    if (_submitting) return false;
    _submitting = true;
    _submitError = null;
    notifyListeners();

    try {
      final userId = await _deps.authService.ensureUserId();
      final result = await _deps.intentionRepository.submit(
        PrayerIntention(
          text: intention.text,
          userId: userId,
          anonymous: intention.anonymous,
          createdAt: DateTime.now(),
          approved: false,
        ),
      );
      _submitting = false;
      switch (result) {
        case IntentionSubmission.success:
          await _refreshStats();
          notifyListeners();
          return true;
        case IntentionSubmission.invalid:
          _submitError = 'Please write between ${AppConstants.intentionMinLength} '
              'and ${AppConstants.intentionMaxLength} characters.';
          notifyListeners();
          return false;
        case IntentionSubmission.throttled:
          _submitError =
              'Please wait a moment before sharing another intention.';
          notifyListeners();
          return false;
        case IntentionSubmission.failure:
          _submitError =
              'Your intention could not be shared. Please try again.';
          notifyListeners();
          return false;
      }
    } catch (e) {
      debugLog('intention submit failed: $e');
      _submitError = 'Your intention could not be shared. Please try again.';
      _submitting = false;
      notifyListeners();
      return false;
    }
  }

  /// Records "I prayed for this". Returns true when newly counted.
  Future<bool> recordPrayer(PrayerIntention intention) async {
    final id = intention.id;
    if (id == null || _praying || _prayedIds.contains(id)) return false;
    _praying = true;
    notifyListeners();

    try {
      final userId = await _deps.authService.ensureUserId();
      final (counted, updated) = await _deps.intentionRepository.recordPrayer(
        id,
        userId,
      );
      if (counted) {
        _prayedIds.add(id);
        final index = _intentions.indexWhere((i) => i.id == id);
        if (index >= 0 && updated != null) {
          _intentions = <PrayerIntention>[
            for (var i = 0; i < _intentions.length; i++)
              i == index ? updated : _intentions[i],
          ];
        }
        await _refreshStats();
      }
      _praying = false;
      notifyListeners();
      return counted;
    } catch (e) {
      debugLog('record prayer failed: $e');
      _praying = false;
      notifyListeners();
      return false;
    }
  }

  /// Re-reads the day/month aggregates without flipping the loading state.
  Future<void> _refreshStats() async {
    try {
      final now = clockNow();
      _dayStats = await _deps.statsRepository.fetch(now);
      _monthStats = await _deps.statsRepository.fetchMonth(now);
    } catch (e) {
      debugLog('stats refresh failed: $e');
    }
  }
}