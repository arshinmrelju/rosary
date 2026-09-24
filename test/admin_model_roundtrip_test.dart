import 'package:flutter_test/flutter_test.dart';

import 'package:rosary_break/domain/models/admin_log_entry.dart';
import 'package:rosary_break/domain/models/admin_role.dart';
import 'package:rosary_break/domain/models/admin_user.dart';
import 'package:rosary_break/domain/models/break_time.dart';
import 'package:rosary_break/domain/models/campaign_settings.dart';
import 'package:rosary_break/domain/models/daily_content.dart';
import 'package:rosary_break/domain/models/day_stats.dart';
import 'package:rosary_break/domain/models/decade.dart';
import 'package:rosary_break/domain/models/month_stats.dart';
import 'package:rosary_break/domain/models/prayer_report.dart';
import 'package:rosary_break/domain/models/rosary_schedule_settings.dart';

void main() {
  group('DailyContent round-trip', () {
    test('toMap → fromMap preserves every field including decades', () {
      final original = DailyContent(
        date: '2026-10-15',
        mysterySetTitle: 'Sorrowful Mysteries',
        intention: 'For the sick',
        theme: 'Perseverance',
        scripture: 'Matthew 26:39',
        reflection: 'Stay close when it is hardest.',
        decades: <Decade>[
          for (var i = 1; i <= 5; i++)
            Decade(
              number: i,
              mysteryTitle: 'Mystery $i',
              focus: 'Focus $i',
              scripture: 'Verse $i',
              reflection: 'Reflection $i',
              prayers: <String>['Our Father', 'Hail Mary x$i'],
            ),
        ],
        published: true,
      );

      final restored = DailyContent.fromMap(original.toMap());
      expect(restored.date, original.date);
      expect(restored.mysterySetTitle, original.mysterySetTitle);
      expect(restored.intention, original.intention);
      expect(restored.theme, original.theme);
      expect(restored.scripture, original.scripture);
      expect(restored.reflection, original.reflection);
      expect(restored.published, isTrue);
      expect(restored.decades, hasLength(5));
      expect(restored.decades[2].number, 3);
      expect(restored.decades[2].mysteryTitle, 'Mystery 3');
      expect(restored.decades[2].reflection, 'Reflection 3');
      expect(restored.decades[2].prayers, hasLength(2));
    });

    test('draft survives a round-trip with published flag intact', () {
      const content = DailyContent(
        date: '2026-10-16',
        mysterySetTitle: '',
        intention: '',
        published: false,
      );
      expect(DailyContent.fromMap(content.toMap()).published, isFalse);
    });
  });

  group('RosaryScheduleSettings', () {
    test('round-trip preserves all five breaks and metadata', () {
      const settings = RosaryScheduleSettings(
        breaks: <BreakTime>[
          BreakTime(9, 30),
          BreakTime(10, 45),
          BreakTime(12, 0),
          BreakTime(14, 20),
          BreakTime(16, 5),
        ],
        timezone: 'Asia/Kolkata',
        durationMinutes: 5,
      );

      final restored = RosaryScheduleSettings.fromMap(settings.toMap());
      expect(restored.breaks, hasLength(5));
      expect(restored.breaks[1].hour, 10);
      expect(restored.breaks[4].minute, 5);
      expect(restored.timezone, 'Asia/Kolkata');
      expect(restored.durationMinutes, 5);
      expect(restored.isComplete, isTrue);
    });

    test('fromMap falls back to defaults when fewer than five breaks', () {
      final restored = RosaryScheduleSettings.fromMap(
        <String, dynamic>{'break1': '09:00', 'timezone': 'UTC'},
      );
      expect(restored.isComplete, isTrue);
      expect(restored.breaks, hasLength(5));
      expect(restored.timezone, 'UTC');
    });

    test('toBreakSchedule materialises five decade slots with the window', () {
      const settings = RosaryScheduleSettings(durationMinutes: 3);
      final schedule = settings.toBreakSchedule();
      final slots = schedule.slots;
      expect(slots, hasLength(5));
      for (var i = 0; i < 5; i++) {
        expect(slots[i].breakNumber, i + 1);
        expect(slots[i].decadeNumber, i + 1);
        expect(slots[i].activeWindow, const Duration(minutes: 3));
      }
    });
  });

  group('CampaignSettings', () {
    test('round-trip preserves window, times and paused state', () {
      final original = CampaignSettings(
        name: 'Rosary Month',
        startDate: DateTime(2026, 10, 1),
        endDate: DateTime(2026, 10, 31),
        collegeStart: BreakTime(9, 0),
        collegeEnd: BreakTime(17, 0),
        timezone: 'Asia/Kolkata',
        paused: true,
      );
      final restored = CampaignSettings.fromMap(original.toMap());
      expect(restored.name, 'Rosary Month');
      expect(restored.startDate, DateTime(2026, 10, 1));
      expect(restored.endDate, DateTime(2026, 10, 31));
      expect(restored.collegeStart.hour, 9);
      expect(restored.collegeEnd.hour, 17);
      expect(restored.paused, isTrue);
      expect(restored.isActive, isFalse);
    });

    test('covers() respects the configured window on the date portion', () {
      final campaign = CampaignSettings(
        startDate: DateTime(2026, 10, 1),
        endDate: DateTime(2026, 10, 31),
      );
      expect(campaign.covers(DateTime(2026, 10, 1)), isTrue);
      expect(campaign.covers(DateTime(2026, 10, 15)), isTrue);
      expect(campaign.covers(DateTime(2026, 10, 31)), isTrue);
      expect(campaign.covers(DateTime(2026, 9, 30)), isFalse);
      expect(campaign.covers(DateTime(2026, 11, 1)), isFalse);
    });
  });

  group('Admin audit trail and users', () {
    test('AdminLogAction keys are stable and unique', () {
      final keys = AdminLogAction.values.map((a) => a.key).toSet();
      expect(keys, hasLength(AdminLogAction.values.length));
      expect(AdminLogAction.fromKey('GRANTED_ADMIN'), AdminLogAction.grantedAdmin);
      expect(AdminLogAction.fromKey('nope'), isNull);
    });

    test('AdminLogEntry round-trips action + actor', () {
      final entry = AdminLogEntry(
        id: 'log-9',
        adminUserId: 'u-1',
        action: AdminLogAction.reviewedReportAndHidden,
        target: 'report-3',
        timestamp: DateTime(2026, 10, 1, 10, 0),
      );
      final restored = AdminLogEntry.fromMap('log-9', entry.toMap());
      expect(restored.adminUserId, 'u-1');
      expect(restored.action, AdminLogAction.reviewedReportAndHidden);
      expect(restored.target, 'report-3');
      expect(restored.timestamp, DateTime(2026, 10, 1, 10, 0));
    });

    test('AdminUser round-trips role, profile and grants', () {
      final user = AdminUser(
        uid: 'u-firebase-7',
        role: AdminRole.contentAdmin,
        email: 'writer@example.com',
        displayName: 'Content Writer',
        createdAt: DateTime(2026, 9, 10),
        createdBy: 'mock-admin',
      );
      final restored = AdminUser.fromMap('u-firebase-7', user.toMap());
      expect(restored.role, AdminRole.contentAdmin);
      expect(restored.email, 'writer@example.com');
      expect(restored.displayName, 'Content Writer');
      expect(restored.createdBy, 'mock-admin');
    });
  });

  group('Reports and stats', () {
    test('PrayerReport round-trips with status', () {
      final report = PrayerReport(
        id: 'report-5',
        intentionId: 'int-1',
        reason: 'spam',
        note: 'Repeated posting.',
        createdAt: DateTime(2026, 10, 1),
        status: ReportStatus.pending,
        reporterUserId: 'student-3',
        intentionText: 'Please pray for me',
      );
      final restored = PrayerReport.fromMap('report-5', report.toMap());
      expect(restored.intentionId, 'int-1');
      expect(restored.status, ReportStatus.pending);
      expect(restored.intentionText, 'Please pray for me');
      expect(restored.copyWith(status: ReportStatus.dismissed).status,
          ReportStatus.dismissed);
    });

    test('DayStats and MonthStats round-trip counters', () {
      const day = DayStats(
        date: '2026-10-15',
        totalParticipants: 120,
        totalDecades: 480,
        totalIntentions: 12,
        totalPrayers: 900,
      );
      final dayRestored = DayStats.fromMap(day.toMap());
      expect(dayRestored.totalParticipants, 120);
      expect(dayRestored.totalPrayers, 900);
      expect(dayRestored.isEmpty, isFalse);

      const month = MonthStats(
        date: '2026-10',
        totalParticipants: 900,
        totalDecades: 4100,
        totalIntentions: 140,
        totalPrayers: 8000,
      );
      final monthRestored = MonthStats.fromMap(month.toMap());
      expect(monthRestored.date, '2026-10');
      expect(monthRestored.totalDecades, 4100);
    });
  });
}