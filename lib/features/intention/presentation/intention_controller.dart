import 'package:flutter/foundation.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/dependencies.dart';
import '../../../domain/models/prayer_intention.dart';

/// Loads approved intentions and submits new ones.
class IntentionController extends ChangeNotifier {
  IntentionController(this._deps);

  final AppDependencies _deps;

  bool _loading = true;
  String? _error;
  List<PrayerIntention> _intentions = <PrayerIntention>[];

  bool _submitting = false;
  String? _submitError;

  bool get isLoading => _loading;
  String? get error => _error;
  List<PrayerIntention> get intentions => _intentions;
  bool get isSubmitting => _submitting;
  String? get submitError => _submitError;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _intentions = await _deps.intentionRepository.fetchApproved(limit: 10);
      _loading = false;
      notifyListeners();
    } catch (e) {
      debugLog('intentions load failed: $e');
      _error = 'We could not load intentions. Please try again.';
      _loading = false;
      notifyListeners();
    }
  }

  /// Submits a new intention. Returns true on success.
  Future<bool> submit(PrayerIntention intention) async {
    if (_submitting) return false;
    _submitting = true;
    _submitError = null;
    notifyListeners();

    try {
      final userId = await _deps.authService.ensureUserId();
      final created = await _deps.intentionRepository.submit(
        PrayerIntention(
          text: intention.text,
          userId: userId,
          anonymous: intention.anonymous,
          createdAt: DateTime.now(),
          approved: intention.approved,
        ),
      );
      _intentions = <PrayerIntention>[created, ..._intentions];
      _submitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugLog('intention submit failed: $e');
      _submitError = 'Your intention could not be submitted. Please try again.';
      _submitting = false;
      notifyListeners();
      return false;
    }
  }
}