import 'package:flutter_test/flutter_test.dart';

import 'package:rosary_break/domain/models/admin_role.dart';

void main() {
  group('AdminRole permission matrix', () {
    test('every role resolves from its persisted key', () {
      expect(AdminRole.fromKey('superadmin'), AdminRole.superAdmin);
      expect(AdminRole.fromKey('content'), AdminRole.contentAdmin);
      expect(AdminRole.fromKey('moderator'), AdminRole.moderator);
      expect(AdminRole.fromKey('nonsense'), isNull);
      expect(AdminRole.fromKey(null), isNull);
    });

    test('Super Admin can do everything', () {
      final role = AdminRole.superAdmin;
      expect(role.canEditContent, isTrue);
      expect(role.canPublishContent, isTrue);
      expect(role.canModerate, isTrue);
      expect(role.canManageSchedule, isTrue);
      expect(role.canManageCampaign, isTrue);
      expect(role.canManageAdmins, isTrue);
      expect(role.canManageAnnouncements, isTrue);
      expect(role.canViewReports, isTrue);
      expect(role.canDeleteContent, isTrue);
      expect(role.canViewStatistics, isTrue);
      expect(role.canViewLogs, isTrue);
      expect(role.canViewAdminList, isTrue);
    });

    test('Content Admin edits content but cannot moderate or manage admins', () {
      final role = AdminRole.contentAdmin;
      expect(role.canEditContent, isTrue);
      expect(role.canPublishContent, isTrue);
      expect(role.canModerate, isFalse);
      expect(role.canManageSchedule, isFalse);
      expect(role.canManageCampaign, isFalse);
      expect(role.canManageAdmins, isFalse);
      expect(role.canManageAnnouncements, isFalse);
      expect(role.canViewReports, isFalse);
      expect(role.canDeleteContent, isFalse);
      expect(role.canViewStatistics, isTrue);
      expect(role.canViewLogs, isFalse);
      expect(role.canViewAdminList, isFalse);
    });

    test('Moderator moderates but cannot edit content or manage admins', () {
      final role = AdminRole.moderator;
      expect(role.canEditContent, isFalse);
      expect(role.canPublishContent, isFalse);
      expect(role.canModerate, isTrue);
      expect(role.canViewReports, isTrue);
      expect(role.canManageSchedule, isFalse);
      expect(role.canManageCampaign, isFalse);
      expect(role.canManageAdmins, isFalse);
      expect(role.canDeleteContent, isFalse);
      expect(role.canViewStatistics, isTrue);
      expect(role.canViewLogs, isFalse);
    });

    test('role keys are stable and unique', () {
      final keys = AdminRole.all.map((r) => r.key).toSet();
      expect(keys, hasLength(AdminRole.all.length));
      expect(keys, containsAll(<String>['superadmin', 'content', 'moderator']));
    });
  });
}