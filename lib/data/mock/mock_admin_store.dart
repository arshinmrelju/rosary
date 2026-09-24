import '../../core/utils/formatters.dart';
import '../../domain/models/admin_log_entry.dart';
import '../../domain/models/admin_role.dart';
import '../../domain/models/admin_user.dart';
import '../../domain/models/announcement.dart';
import '../../domain/models/campaign_settings.dart';
import '../../domain/models/daily_content.dart';
import '../../domain/models/day_stats.dart';
import '../../domain/models/month_stats.dart';
import '../../domain/models/mystery_set.dart';
import '../../domain/models/prayer_intention.dart';
import '../../domain/models/prayer_report.dart';
import '../../domain/models/rosary_schedule_settings.dart';
import '../repositories/admin_content_repository.dart';
import '../repositories/admin_log_repository.dart';
import '../repositories/admin_stats_repository.dart';
import '../repositories/admin_users_repository.dart';
import '../repositories/announcements_repository.dart';
import '../repositories/campaign_repository.dart';
import '../repositories/moderation_repository.dart';
import '../repositories/reports_repository.dart';
import '../repositories/schedule_settings_repository.dart';
import 'mock_community.dart';

/// In-memory admin data shared by the mock admin repositories.
///
/// Purpose-built for local development and unit tests so the whole admin
/// dashboard can be exercised without Firebase.
class MockAdminStore {
  MockAdminStore() {
    _seedCampaign();
    _seedIntentions();
    _seedReports();
    admins[MockAdminIdentity.uid] = AdminUser(
      uid: MockAdminIdentity.uid,
      role: AdminRole.superAdmin,
      email: MockAdminIdentity.email,
      displayName: MockAdminIdentity.displayName,
      createdAt: DateTime(2026, 9, 1),
    );
  }

  final Map<String, DailyContent> content = <String, DailyContent>{};
  final List<PrayerIntention> intentions = <PrayerIntention>[
    ...MockCommunity.approvedIntentions(),
  ];
  final List<PrayerReport> reports = <PrayerReport>[];
  final List<Announcement> announcements = <Announcement>[];
  final List<AdminLogEntry> logs = <AdminLogEntry>[];
  final Map<String, AdminUser> admins = <String, AdminUser>{};
  CampaignSettings campaign = CampaignSettings(
    startDate: DateTime(2026, 10, 1),
    endDate: DateTime(2026, 10, 31),
  );
  RosaryScheduleSettings schedule = const RosaryScheduleSettings();

  void _seedCampaign() {
    content.putIfAbsent(dateKey(DateTime(2026, 10, 1)), () {
      final set = MysterySet.joyful;
      return DailyContent(
        date: dateKey(DateTime(2026, 10, 1)),
        mysterySetTitle: set.title,
        theme: 'Seeds of the Kingdom',
        intention: 'For our college community as the campaign begins.',
        scripture: set.scriptures.first,
        reflection: 'Even one decade, prayed with your whole heart, is a gift.',
        decades: set.decades,
        published: true,
      );
    });
  }

  void _seedIntentions() {
    intentions.addAll(<PrayerIntention>[
      PrayerIntention(
        id: 'pending-1',
        text: 'Please pray for my family',
        anonymous: true,
        createdAt: DateTime(2026, 10, 1, 10, 32),
        approved: false,
        prayerCount: 0,
      ),
      PrayerIntention(
        id: 'pending-2',
        text: 'For my final semester project to go well',
        anonymous: true,
        createdAt: DateTime(2026, 10, 1, 11, 5),
        approved: false,
        prayerCount: 0,
      ),
    ]);
  }

  void _seedReports() {
    reports.addAll(<PrayerReport>[
      PrayerReport(
        id: 'report-1',
        intentionId: 'pending-2',
        reason: 'inappropriate',
        note: 'Contains offensive language.',
        reporterUserId: 'student-42',
        createdAt: DateTime(2026, 10, 1, 11, 40),
        status: ReportStatus.pending,
      ),
      PrayerReport(
        id: 'report-2',
        intentionId: 'pending-1',
        reason: 'spam',
        reporterUserId: 'student-7',
        createdAt: DateTime(2026, 10, 1, 12, 1),
        status: ReportStatus.pending,
      ),
    ]);
  }
}

class MockAdminContentRepository implements AdminContentRepository {
  MockAdminContentRepository(this.store);

  final MockAdminStore store;

  @override
  Future<DailyContent?> fetch(String dateKey) async => store.content[dateKey];

  @override
  Future<List<DailyContent>> fetchRange(DateTime start, DateTime end) async {
    final startKey = dateKey(start);
    final endKey = dateKey(end);
    final result = store.content.values
        .where((c) => c.date.compareTo(startKey) >= 0 && c.date.compareTo(endKey) <= 0)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return result;
  }

  @override
  Future<void> saveDraft(DailyContent content) async {
    final data = content.toMap();
    data['published'] = false;
    store.content[content.date] = DailyContent.fromMap(data);
  }

  @override
  Future<void> publish(DailyContent content) async {
    final data = content.toMap();
    data['published'] = true;
    store.content[content.date] = DailyContent.fromMap(data);
  }

  @override
  Future<void> delete(String dateKey) async {
    store.content.remove(dateKey);
  }
}

class MockModerationRepository implements ModerationRepository {
  MockModerationRepository(this.store);

  final MockAdminStore store;

  @override
  Future<List<PrayerIntention>> fetchPending() async =>
      store.intentions.where((i) => !i.approved).toList();

  @override
  Future<List<PrayerIntention>> fetchApproved() async =>
      store.intentions.where((i) => i.approved).toList();

  @override
  Future<void> approve(String intentionId) async {
    final index = store.intentions.indexWhere((i) => i.id == intentionId);
    if (index < 0) return;
    final existing = store.intentions[index];
    store.intentions[index] = PrayerIntention(
      id: existing.id,
      text: existing.text,
      userId: existing.userId,
      anonymous: existing.anonymous,
      createdAt: existing.createdAt,
      prayerCount: existing.prayerCount,
      approved: true,
    );
  }

  @override
  Future<void> reject(String intentionId) async {
    store.intentions.removeWhere((i) => i.id == intentionId);
  }

  @override
  Future<void> hide(String intentionId) async {
    // Mirror of the Firestore behaviour: hide removes the intention from the
    // wall but keeps the document and its prayer counts by returning it to
    // the pending (unapproved) state.
    final index = store.intentions.indexWhere((i) => i.id == intentionId);
    if (index < 0) return;
    final existing = store.intentions[index];
    store.intentions[index] = PrayerIntention(
      id: existing.id,
      text: existing.text,
      userId: existing.userId,
      anonymous: existing.anonymous,
      createdAt: existing.createdAt,
      prayerCount: existing.prayerCount,
      approved: false,
    );
  }

  @override
  Future<void> delete(String intentionId) async {
    store.intentions.removeWhere((i) => i.id == intentionId);
  }
}

class MockReportsRepository implements ReportsRepository {
  MockReportsRepository(this.store);

  final MockAdminStore store;

  @override
  Future<List<PrayerReport>> fetchAll({ReportStatus? status}) async {
    final all = store.reports.toList()..sort((a, b) {
      final at = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bt.compareTo(at);
    });
    if (status == null) return all;
    return all.where((r) => r.status == status).toList();
  }

  @override
  Future<int> countPending() async =>
      store.reports.where((r) => r.status == ReportStatus.pending).length;

  @override
  Future<void> review(
    String reportId, {
    ReportStatus status = ReportStatus.reviewed,
  }) async {
    final index = store.reports.indexWhere((r) => r.id == reportId);
    if (index < 0) return;
    store.reports[index] = store.reports[index].copyWith(status: status);
  }

  @override
  Future<void> dismiss(String reportId) async =>
      review(reportId, status: ReportStatus.dismissed);

  @override
  Future<ReportOutcome> submit(PrayerReport report) async {
    final reason = report.reason.trim();
    if (reason.isEmpty || reason.length > 80) return ReportOutcome.invalid;
    store.reports.add(
      PrayerReport(
        id: 'report-${store.reports.length + 1}',
        intentionId: report.intentionId,
        reason: reason,
        note: report.note,
        createdAt: DateTime.now(),
        status: ReportStatus.pending,
        reporterUserId: report.reporterUserId,
        intentionText: report.intentionText,
      ),
    );
    return ReportOutcome.success;
  }
}

class MockCampaignRepository implements CampaignRepository {
  MockCampaignRepository(this.store);

  final MockAdminStore store;

  @override
  Future<CampaignSettings?> fetch() async => store.campaign;

  @override
  Future<void> save(CampaignSettings settings) async {
    store.campaign = settings;
  }
}

class MockScheduleSettingsRepository implements ScheduleSettingsRepository {
  MockScheduleSettingsRepository(this.store);

  final MockAdminStore store;

  @override
  Future<RosaryScheduleSettings?> fetch() async => store.schedule;

  @override
  Future<void> save(RosaryScheduleSettings settings) async {
    store.schedule = settings;
  }
}

class MockAnnouncementsRepository implements AnnouncementsRepository {
  MockAnnouncementsRepository(this.store);

  final MockAdminStore store;

  @override
  Future<List<Announcement>> fetchAll() async => store.announcements;

  @override
  Future<Announcement?> fetchActive() async {
    for (final announcement in store.announcements) {
      if (announcement.active) return announcement;
    }
    return null;
  }

  @override
  Future<void> save(Announcement announcement) async {
    if (announcement.id != null) {
      final index = store.announcements.indexWhere((a) => a.id == announcement.id);
      if (index >= 0) {
        store.announcements[index] = announcement;
        return;
      }
    }
    store.announcements.add(
      Announcement(
        id: 'a-${store.announcements.length + 1}',
        title: announcement.title,
        message: announcement.message,
        active: announcement.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> setActive(String id, bool active) async {
    final index = store.announcements.indexWhere((a) => a.id == id);
    if (index < 0) return;
    final existing = store.announcements[index];
    store.announcements[index] = existing.copyWith(active: active);
  }

  @override
  Future<void> delete(String id) async {
    store.announcements.removeWhere((a) => a.id == id);
  }
}

class MockAdminStatsRepository implements AdminStatsRepository {
  MockAdminStatsRepository(this.store, this._community);

  final MockAdminStore store;
  final MockCommunityStore _community;

  @override
  Future<DayStats> fetchDay(DateTime date) async => _community.statsFor(date);

  @override
  Future<MonthStats> fetchMonth(DateTime date) async =>
      _community.monthStatsFor(date);

  @override
  Future<List<DayStats>> fetchDailyRange(DateTime start, DateTime end) async {
    final days = <DayStats>[];
    for (var d = DateTime(start.year, start.month, start.day);
        !d.isAfter(DateTime(end.year, end.month, end.day));
        d = d.add(const Duration(days: 1))) {
      final stats = _community.statsFor(d);
      if (stats.isEmpty) continue;
      days.add(stats);
    }
    return days;
  }
}

class MockAdminLogRepository implements AdminLogRepository {
  MockAdminLogRepository(this.store);

  final MockAdminStore store;

  @override
  Future<void> log(String adminUserId, AdminLogAction action, String target) async {
    store.logs.add(
      AdminLogEntry(
        id: 'log-${store.logs.length + 1}',
        adminUserId: adminUserId,
        action: action,
        target: target,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  Future<List<AdminLogEntry>> fetchRecent({int limit = 50}) async {
    final sorted = store.logs.toList()
      ..sort((a, b) {
        final at = a.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bt = b.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
        final byTime = bt.compareTo(at);
        if (byTime != 0) return byTime;
        return (a.id ?? '').compareTo(b.id ?? '') * -1;
      });
    return sorted.take(limit).toList();
  }
}

class MockAdminUsersRepository implements AdminUsersRepository {
  MockAdminUsersRepository(this.store);

  final MockAdminStore store;

  @override
  Future<AdminUser?> fetchCurrent(String uid) async => store.admins[uid];

  @override
  Future<List<AdminUser>> fetchAll() async =>
      store.admins.values.toList();

  @override
  Future<void> grant(AdminUser user, {String? grantedBy}) async {
    store.admins[user.uid] = AdminUser(
      uid: user.uid,
      role: user.role,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoUrl,
      createdAt: user.createdAt ?? DateTime.now(),
      createdBy: grantedBy,
    );
  }

  @override
  Future<void> revoke(String uid) async {
    store.admins.remove(uid);
  }
}

/// A mock admin session identity for local development.
abstract final class MockAdminIdentity {
  static const String uid = 'mock-admin';
  static const String email = 'admin@rosary.local';
  static const String displayName = 'Demo Admin';
}