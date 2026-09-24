import 'package:flutter_test/flutter_test.dart';

import 'package:rosary_break/data/mock/mock_admin_store.dart';
import 'package:rosary_break/data/repositories/reports_repository.dart';
import 'package:rosary_break/domain/models/admin_log_entry.dart';
import 'package:rosary_break/domain/models/admin_role.dart';
import 'package:rosary_break/domain/models/admin_user.dart';
import 'package:rosary_break/domain/models/announcement.dart';
import 'package:rosary_break/domain/models/daily_content.dart';
import 'package:rosary_break/domain/models/decade.dart';
import 'package:rosary_break/domain/models/prayer_intention.dart';
import 'package:rosary_break/domain/models/prayer_report.dart';

void main() {
  DailyContent fullContent(String date) => DailyContent(
        date: date,
        mysterySetTitle: 'Joyful Mysteries',
        intention: 'For our college community.',
        reflection: 'Even a single decade prayed with love is a gift.',
        scripture: 'Luke 1:38',
        decades: <Decade>[decade(1)],
      );

  late MockAdminStore store;

  setUp(() {
    store = MockAdminStore();
  });

  group('MockAdminContentRepository', () {
    test('saveDraft persist, students never see unpublished', () async {
      final repo = MockAdminContentRepository(store);
      final content = fullContent('2026-10-15');

      expect(await repo.fetch('2026-10-15'), isNull);
      await repo.saveDraft(content);

      final saved = await repo.fetch('2026-10-15');
      expect(saved, isNotNull);
      expect(saved!.published, isFalse);
      expect(saved.intention, content.intention);
    });

    test('publish flips the flag and fetchRange respects boundaries', () async {
      final repo = MockAdminContentRepository(store);
      await repo.publish(fullContent('2026-10-15'));

      final saved = await repo.fetch('2026-10-15');
      expect(saved!.published, isTrue);

      final range = await repo.fetchRange(
        DateTime(2026, 10, 1),
        DateTime(2026, 10, 31),
      );
      final dates = range.map((c) => c.date).toList();
      expect(dates, contains('2026-10-15'));
      expect(dates, isNot(contains('2026-11-01')));

      final outside = await repo.fetchRange(
        DateTime(2026, 11, 1),
        DateTime(2026, 11, 30),
      );
      expect(outside.map((c) => c.date), isNot(contains('2026-10-15')));
    });

    test('delete removes the day entirely', () async {
      final repo = MockAdminContentRepository(store);
      await repo.publish(fullContent('2026-10-15'));
      await repo.delete('2026-10-15');
      expect(await repo.fetch('2026-10-15'), isNull);
    });
  });

  group('MockModerationRepository', () {
    test('approve moves an intention to published', () async {
      final repo = MockModerationRepository(store);
      expect((await repo.fetchPending()).map((i) => i.id), contains('pending-1'));

      await repo.approve('pending-1');

      expect((await repo.fetchPending()).map((i) => i.id),
          isNot(contains('pending-1')));
      final approved = await repo.fetchApproved();
      expect(approved.map((i) => i.id), contains('pending-1'));
    });

    test('reject removes the intention entirely', () async {
      final repo = MockModerationRepository(store);
      await repo.reject('pending-2');
      expect((await repo.fetchPending()).map((i) => i.id),
          isNot(contains('pending-2')));
      expect((await repo.fetchApproved()).map((i) => i.id),
          isNot(contains('pending-2')));
    });

    test('hide PRESERVES the document and prayer count, returns to pending',
        () async {
      final repo = MockModerationRepository(store);
      await repo.approve('pending-1');

      // Give it a prayer count as if students prayed.
      final approvedBefore = (await repo.fetchApproved()).firstWhere(
        (i) => i.id == 'pending-1',
      );
      store.intentions[store.intentions.indexWhere((i) => i.id == 'pending-1')] =
          _bumpPrayers(approvedBefore);

      await repo.hide('pending-1');

      // Back in the pending queue.
      final pending = await repo.fetchPending();
      final hidden = pending.firstWhere((i) => i.id == 'pending-1');
      expect(hidden.approved, isFalse);
      // Firestore contract: prayer counts survive hiding.
      expect(hidden.prayerCount, greaterThan(0));
      expect(hidden.text, 'Please pray for my family');
    });

    test('delete permanently removes the intention', () async {
      final repo = MockModerationRepository(store);
      await repo.delete('pending-1');
      expect((await repo.fetchPending()).map((i) => i.id),
          isNot(contains('pending-1')));
    });
  });

  group('MockReportsRepository', () {
    test('review and dismiss set status, countPending mirrors it', () async {
      final repo = MockReportsRepository(store);
      expect(await repo.countPending(), 2);

      await repo.review('report-1');
      expect(await repo.countPending(), 1);

      await repo.dismiss('report-2');
      expect(await repo.countPending(), 0);

      final reviewed = await repo.fetchAll(status: ReportStatus.reviewed);
      expect(reviewed.map((r) => r.id), contains('report-1'));
      final dismissed = await repo.fetchAll(status: ReportStatus.dismissed);
      expect(dismissed.map((r) => r.id), contains('report-2'));
    });

    test('new student reports land as pending and validate reason size', () async {
      final repo = MockReportsRepository(store);
      final outcome = await repo.submit(
        PrayerReport(
          intentionId: 'pending-1',
          reason: 'inappropriate',
          reporterUserId: 'student-9',
          intentionText: 'Please pray for my family',
        ),
      );
      expect(outcome, ReportOutcome.success);
      expect(await repo.countPending(), greaterThanOrEqualTo(3));
      final all = await repo.fetchAll();
      expect(all.first.status, ReportStatus.pending);
    });
  });

  group('MockCampaignRepository + schedule + announcements', () {
    test('pause flag round-trips', () async {
      final repo = MockCampaignRepository(store);
      expect((await repo.fetch())!.paused, isFalse);
      await repo.save(store.campaign.copyWith(paused: true));
      expect((await repo.fetch())!.paused, isTrue);
    });

    test('schedule settings round-trip and keep five breaks', () async {
      final repo = MockScheduleSettingsRepository(store);
      final updated = store.schedule.copyWith(
        timezone: 'Asia/Kolkata',
      );
      await repo.save(updated);
      final loaded = await repo.fetch();
      expect(loaded!.breaks, hasLength(5));
      expect(loaded.toBreakSchedule().slots, hasLength(5));
    });

    test('announcements: save, activate, fetch active, delete', () async {
      final repo = MockAnnouncementsRepository(store);
      await repo.save(const Announcement(
        title: 'Welcome',
        message: 'The campaign is live.',
      ));
      final saved = (await repo.fetchAll()).first;
      expect(await repo.fetchActive(), isNull);

      await repo.setActive(saved.id!, true);
      expect((await repo.fetchActive())!.title, 'Welcome');

      await repo.delete(saved.id!);
      expect(await repo.fetchAll(), isEmpty);
    });
  });

  group('MockAdminLogRepository + users', () {
    test('every approved action writes an audit entry', () async {
      final repo = MockAdminLogRepository(store);
      await repo.log('mock-admin', AdminLogAction.approvedPrayerIntention,
          'pending-1');
      await repo.log('mock-admin', AdminLogAction.updatedCampaign, 'ROSARY BREAK');
      final recent = await repo.fetchRecent();
      expect(recent, hasLength(2));
      expect(recent.first.action, AdminLogAction.updatedCampaign);
    });

    test('grant + fetchCurrent + revoke', () async {
      final repo = MockAdminUsersRepository(store);
      await repo.grant(
        const AdminUser(
          uid: 'u-firebase-123',
          role: AdminRole.contentAdmin,
          displayName: 'Second Admin',
        ),
        grantedBy: 'mock-admin',
      );
      final granted = await repo.fetchCurrent('u-firebase-123');
      expect(granted!.role, AdminRole.contentAdmin);
      expect(granted.createdBy, 'mock-admin');

      await repo.revoke('u-firebase-123');
      expect(await repo.fetchCurrent('u-firebase-123'), isNull);
    });
  });
}

PrayerIntention _bumpPrayers(PrayerIntention intention) => PrayerIntention(
      id: intention.id,
      text: intention.text,
      userId: intention.userId,
      anonymous: intention.anonymous,
      createdAt: intention.createdAt,
      prayerCount: intention.prayerCount + 5,
      approved: intention.approved,
    );

Decade decade(int number) =>
    Decade(number: number, mysteryTitle: 'Mystery $number');