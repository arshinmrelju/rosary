import '../../core/utils/formatters.dart';
import '../../domain/models/daily_content.dart';
import '../../domain/models/day_participation.dart';
import '../auth/auth_service.dart';
import '../repositories/daily_content_repository.dart';
import '../repositories/intention_repository.dart';
import '../repositories/participation_repository.dart';
import '../repositories/stats_repository.dart';
import '../repositories/user_repository.dart';
import '../../domain/models/day_stats.dart';
import '../../domain/models/prayer_intention.dart';
import '../../domain/models/user_profile.dart';
import 'mock_community.dart';
import 'mock_content.dart';

/// A fixed, in-memory "guest" session so the app is fully usable before
/// Firebase authentication is wired up.
class GuestAuthService implements AuthService {
  const GuestAuthService();

  static const String guestUserId = 'guest-student';

  @override
  Future<String> ensureUserId() async => guestUserId;

  @override
  Future<void> signOut() async {}
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
      MockContent.forDate(DateTime.now());

  @override
  Future<void> save(DailyContent content) async {}
}

/// In-memory participation store shared across the session so progress made
/// on one screen is visible on the others.
class MockParticipationRepository implements ParticipationRepository {
  MockParticipationRepository();

  final Map<String, DayParticipation> _store = <String, DayParticipation>{};

  String _key(String userId, String dateKey) => '$userId|$dateKey';

  @override
  Future<DayParticipation> fetch(String userId, DateTime date) async =>
      _store[_key(userId, dateKey(date))] ?? DayParticipation.empty(date);

  @override
  Future<DayParticipation> completeDecade(
    String userId,
    DateTime date,
    int decadeNumber,
  ) async {
    final current = await fetch(userId, date);
    final updated = DayParticipation(
      date: current.date,
      decade1: decadeNumber == 1 || current.decade1,
      decade2: decadeNumber == 2 || current.decade2,
      decade3: decadeNumber == 3 || current.decade3,
      decade4: decadeNumber == 4 || current.decade4,
      decade5: decadeNumber == 5 || current.decade5,
      lastUpdated: DateTime.now(),
    );
    _store[_key(userId, updated.date)] = updated;
    return updated;
  }

  @override
  Future<void> save(String userId, DayParticipation participation) async {
    _store[_key(userId, participation.date)] = participation;
  }
}

class MockIntentionRepository implements IntentionRepository {
  MockIntentionRepository() : _intentions = MockCommunity.approvedIntentions();

  final List<PrayerIntention> _intentions;

  @override
  Future<List<PrayerIntention>> fetchApproved({int limit = 10}) async =>
      _intentions.take(limit).toList();

  @override
  Future<PrayerIntention> submit(PrayerIntention intention) async {
    final created = PrayerIntention(
      id: 'mock-${DateTime.now().microsecondsSinceEpoch}',
      text: intention.text,
      userId: intention.userId,
      anonymous: intention.anonymous,
      createdAt: DateTime.now(),
      approved: true,
    );
    _intentions.insert(0, created);
    return created;
  }

  @override
  Future<void> incrementPrayerCount(String intentionId) async {}

  @override
  Future<void> approve(String intentionId) async {}
}

class MockStatsRepository implements StatsRepository {
  @override
  Future<DayStats> fetch(DateTime date) async =>
      MockCommunity.statsFor(date);

  @override
  Future<void> save(DayStats stats) async {}
}