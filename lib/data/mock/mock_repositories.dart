import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/formatters.dart';
import '../../domain/models/daily_content.dart';
import '../../domain/models/day_participation.dart';
import '../../domain/models/day_stats.dart';
import '../../domain/models/month_stats.dart';
import '../../domain/models/prayer_intention.dart';
import '../../domain/models/prayer_report.dart';
import '../../domain/models/user_profile.dart';
import '../auth/auth_service.dart';
import '../repositories/daily_content_repository.dart';
import '../repositories/intention_repository.dart';
import '../repositories/participation_repository.dart';
import '../repositories/reports_repository.dart';
import '../repositories/stats_repository.dart';
import '../repositories/user_repository.dart';
import 'mock_community.dart';
import 'mock_content.dart';
import 'mock_admin_store.dart';

/// A fixed, in-memory "guest" session so the app is fully usable before
/// Firebase authentication is wired up.
class GuestAuthService implements AuthService {
  const GuestAuthService();

  static const String guestUserId = 'guest-student';

  @override
  Future<String> ensureUserId() async => guestUserId;

  @override
  Future<void> signOut() async {}

  @override
  Future<SignedInUser?> signInWithGoogle() async =>
      const SignedInUser(
        uid: MockAdminIdentity.uid,
        email: MockAdminIdentity.email,
        displayName: MockAdminIdentity.displayName,
      );
}

class MockUserRepository implements UserRepository {
  @override
  Future<UserProfile?> fetch(String userId) async =>
      const UserProfile(
        uid: GuestAuthService.guestUserId,
        displayName: 'Campus Student',
        department: 'Engineering',
        year: 2,
      );

  @override
  Future<void> save(UserProfile profile) async {}
}

class MockDailyContentRepository implements DailyContentRepository {
  @override
  Future<DailyContent?> fetch(DateTime date) async =>
      MockContent.forDate(date);

  @override
  Future<DailyContent?> fetchDefault() async =>
      MockContent.forDate(clockNow());

  @override
  Future<void> save(DailyContent content) async {}
}

/// In-memory participation store shared across the session so progress made
/// on one screen is visible on the others.
///
/// For the anonymous/guest path this store is additionally persisted to local
/// storage ([SharedPreferences], i.e. localStorage on web) so today's progress
/// survives a page refresh without requiring any account.
///
/// Completing a decade also nudges the shared [MockCommunityStore], matching
/// the guarded counting the Firestore transaction path performs.
class MockParticipationRepository implements ParticipationRepository {
  MockParticipationRepository._(this._prefs, this._store);

  /// Builds the repository, eagerly loading today's persisted snapshots.
  static Future<MockParticipationRepository> create({
    MockCommunityStore? store,
  }) async {
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (_) {
      prefs = null;
    }
    return MockParticipationRepository._(prefs, store ?? MockCommunityStore());
  }

  final SharedPreferences? _prefs;
  final MockCommunityStore _store;
  final Map<String, DayParticipation> _storeMap = <String, DayParticipation>{};

  static const String _keyPrefix = 'rosary_break:participation';

  String _key(String userId, String dateKey) => '$userId|$dateKey';

  String _prefsKey(String userId, String dateKey) =>
      '$_keyPrefix:$userId:$dateKey';

  DayParticipation? _fromStorage(String userId, String date) {
    final raw = _prefs?.getString(_prefsKey(userId, date));
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return DayParticipation.fromMap(map);
    } catch (_) {
      return null;
    }
  }

  void _toStorage(String userId, DayParticipation participation) {
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      prefs.setString(
        _prefsKey(userId, participation.date),
        jsonEncode(participation.toMap()),
      );
    } catch (_) {
      // Storage unavailable — session-only progress is still kept above.
    }
  }

  @override
  Future<DayParticipation> fetch(String userId, DateTime date) async {
    final key = _key(userId, dateKey(date));
    return _storeMap[key] ??
        _fromStorage(userId, dateKey(date)) ??
        DayParticipation.empty(date);
  }

  @override
  Future<DayParticipation> completeDecade(
    String userId,
    DateTime date,
    int decadeNumber,
  ) async {
    final current = await fetch(userId, date);
    final alreadyCompleted = current.isDecadeCompleted(decadeNumber);
    final isFirstOfTheDay = current.totalCompleted == 0;
    final updated = DayParticipation(
      date: current.date,
      decade1: decadeNumber == 1 || current.decade1,
      decade2: decadeNumber == 2 || current.decade2,
      decade3: decadeNumber == 3 || current.decade3,
      decade4: decadeNumber == 4 || current.decade4,
      decade5: decadeNumber == 5 || current.decade5,
      lastUpdated: DateTime.now(),
    );
    await save(userId, updated);
    if (!alreadyCompleted) {
      _store.recordDecade(date, isNewParticipant: isFirstOfTheDay);
    }
    return updated;
  }

  @override
  Future<void> save(String userId, DayParticipation participation) async {
    _storeMap[_key(userId, participation.date)] = participation;
    _toStorage(userId, participation);
  }

  /// Mock writes straight through (never fails), so nothing is ever queued.
  @override
  Future<int> syncPending() async => 0;

  @override
  Future<List<DayParticipation>> fetchRecent(String userId, {int limit = 30}) async {
    final days = await _allForUser(userId);
    days.sort((a, b) => b.date.compareTo(a.date));
    return days.take(limit).toList();
  }

  @override
  Future<List<DayParticipation>> fetchRange(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    final startKey = dateKey(start);
    final endKey = dateKey(end);
    final days = await _allForUser(userId);
    return days
        .where((d) => d.date.compareTo(startKey) >= 0 && d.date.compareTo(endKey) <= 0)
        .toList();
  }

  /// All participation snapshots for [userId] across the session store and
  /// persisted local storage (most recently written wins).
  Future<List<DayParticipation>> _allForUser(String userId) async {
    final byDate = <String, DayParticipation>{};
    for (final entry in _storeMap.entries) {
      if (entry.key.startsWith('$userId|')) {
        byDate[entry.value.date] = entry.value;
      }
    }
    final prefs = _prefs;
    if (prefs != null) {
      for (final key in prefs.getKeys()) {
        if (!key.startsWith('$_keyPrefix:$userId:')) continue;
        final raw = prefs.getString(key);
        if (raw == null) continue;
        try {
          final day = DayParticipation.fromMap(jsonDecode(raw) as Map<String, dynamic>);
          byDate[day.date] = day;
        } catch (_) {
          // Ignore corrupt storage entries.
        }
      }
    }
    return byDate.values.toList();
  }
}

class MockIntentionRepository implements IntentionRepository {
  MockIntentionRepository._(this._store, this._prefs, this._prayedIds)
      : _approved = List<PrayerIntention>.of(MockCommunity.approvedIntentions());

  /// Builds the repository, restoring the device-level "already prayed" guard
  /// so a guest cannot re-count a prayer by refreshing.
  static Future<MockIntentionRepository> create({
    MockCommunityStore? store,
  }) async {
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (_) {
      prefs = null;
    }
    final prayed = <String>[];
    try {
      final stored = prefs?.getStringList(_prayedKey);
      if (stored != null) prayed.addAll(stored);
    } catch (_) {
      // Ignore corrupt storage.
    }
    return MockIntentionRepository._(
      store ?? MockCommunityStore(),
      prefs,
      prayed.toSet(),
    );
  }

  final MockCommunityStore _store;
  final SharedPreferences? _prefs;
  final Set<String> _prayedIds;
  final List<PrayerIntention> _approved;
  final List<PrayerReport> _reports = <PrayerReport>[];
  DateTime? _lastSubmittedAt;

  static const String _prayedKey = 'rosary_break:prayed_intentions';
  static const Duration _cooldown = Duration(seconds: 60);

  @override
  Future<List<PrayerIntention>> fetchApproved({int limit = 20}) async =>
      _approved.take(limit).toList();

  @override
  Future<IntentionSubmission> submit(PrayerIntention intention) async {
    final text = intention.text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (text.length < 3 || text.length > 280) {
      return IntentionSubmission.invalid;
    }
    final now = DateTime.now();
    if (_lastSubmittedAt != null &&
        now.difference(_lastSubmittedAt!) < _cooldown) {
      return IntentionSubmission.throttled;
    }
    _lastSubmittedAt = now;
    _store.recordIntention(now);
    return IntentionSubmission.success;
  }

  @override
  Future<(bool, PrayerIntention?)> recordPrayer(
    String intentionId,
    String userId,
  ) async {
    if (_prayedIds.contains(intentionId)) return (false, null);
    final index = _approved.indexWhere((i) => i.id == intentionId);
    if (index < 0) return (false, null);
    _prayedIds.add(intentionId);
    _persistPrayed();

    final existing = _approved[index];
    _approved[index] = PrayerIntention(
      id: existing.id,
      text: existing.text,
      userId: existing.userId,
      anonymous: existing.anonymous,
      createdAt: existing.createdAt,
      prayerCount: existing.prayerCount + 1,
      approved: existing.approved,
    );
    _store.recordPrayer(DateTime.now());
    return (true, _approved[index]);
  }

  void _persistPrayed() {
    try {
      _prefs?.setStringList(_prayedKey, _prayedIds.toList());
    } catch (_) {
      // Storage unavailable — session-only guard is still kept in memory.
    }
  }

  @override
  Future<void> approve(String intentionId) async {}

  @override
  Future<ReportOutcome> report(PrayerReport request) async {
    final reason = request.reason.trim();
    if (reason.isEmpty || reason.length > 80) return ReportOutcome.invalid;
    _reports.add(
      PrayerReport(
        id: 'report-${_reports.length + 1}',
        intentionId: request.intentionId,
        reason: reason,
        note: request.note,
        createdAt: DateTime.now(),
        status: ReportStatus.pending,
        reporterUserId: request.reporterUserId,
        intentionText: request.intentionText,
      ),
    );
    return ReportOutcome.success;
  }
}

class MockStatsRepository implements StatsRepository {
  MockStatsRepository(this._store);

  final MockCommunityStore _store;

  @override
  Future<DayStats> fetch(DateTime date) async => _store.statsFor(date);

  @override
  Future<void> save(DayStats stats) async => _store.saveDay(stats);

  @override
  Future<MonthStats> fetchMonth(DateTime date) async =>
      _store.monthStatsFor(date);

  @override
  Future<void> saveMonth(MonthStats stats) async => _store.saveMonth(stats);
}