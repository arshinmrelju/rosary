import 'package:flutter_test/flutter_test.dart';

import 'package:rosary_break/data/auth/auth_service.dart';
import 'package:rosary_break/data/repositories/admin_users_repository.dart';
import 'package:rosary_break/domain/models/admin_role.dart';
import 'package:rosary_break/domain/models/admin_user.dart';
import 'package:rosary_break/features/admin/presentation/admin_session.dart';

class _FakeAuth implements AuthService {
  _FakeAuth({this.nextUser});

  SignedInUser? nextUser;
  bool signOutCalled = false;

  @override
  Future<String> ensureUserId() async => 'anon-1';

  @override
  Future<SignedInUser?> signInWithGoogle() async => nextUser;

  @override
  Future<void> signOut() async {
    signOutCalled = true;
  }
}

class _FakeAdminRepo implements AdminUsersRepository {
  final Map<String, AdminUser> admins = <String, AdminUser>{};

  @override
  Future<AdminUser?> fetchCurrent(String uid) async => admins[uid];

  @override
  Future<List<AdminUser>> fetchAll() async => admins.values.toList();

  @override
  Future<void> grant(AdminUser user, {String? grantedBy}) async {
    admins[user.uid] = AdminUser(
      uid: user.uid,
      role: user.role,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoUrl,
      createdAt: user.createdAt,
      createdBy: grantedBy,
    );
  }

  @override
  Future<void> revoke(String uid) async {
    admins.remove(uid);
  }
}

void main() {
  group('AdminSession — mock mode', () {
    test('restore() starts as the demo Super Admin', () async {
      final session = AdminSession(
        adminUsersRepository: _FakeAdminRepo(),
        authService: _FakeAuth(),
        firebaseEnabled: false,
      );
      expect(session.isInitialized, isFalse);

      await session.restore();

      expect(session.isInitialized, isTrue);
      expect(session.isAdmin, isTrue);
      expect(session.role, AdminRole.superAdmin);
      expect(session.user!.uid, 'mock-admin');
    });

    test('setMockRole swaps the active role for dev/testing', () async {
      final session = AdminSession(
        adminUsersRepository: _FakeAdminRepo(),
        authService: _FakeAuth(),
        firebaseEnabled: false,
      );
      await session.restore();

      await session.setMockRole(AdminRole.moderator);

      expect(session.role, AdminRole.moderator);
      expect(session.role!.canModerate, isTrue);
      expect(session.role!.canEditContent, isFalse);
    });

    test('setMockRole is a no-op when Firebase is enabled', () async {
      final session = AdminSession(
        adminUsersRepository: _FakeAdminRepo(),
        authService: _FakeAuth(),
        firebaseEnabled: true,
      );
      await session.setMockRole(AdminRole.contentAdmin);
      expect(session.isAdmin, isFalse);
    });

    test('signOut clears the session and never calls Firebase signOut', () async {
      final auth = _FakeAuth();
      final session = AdminSession(
        adminUsersRepository: _FakeAdminRepo(),
        authService: auth,
        firebaseEnabled: false,
      );
      await session.restore();
      expect(session.isAdmin, isTrue);

      await session.signOut();

      expect(session.isAdmin, isFalse);
      expect(auth.signOutCalled, isFalse);
    });
  });

  group('AdminSession — Firebase mode', () {
    test('cancelled Google sign-in returns false and stays signed out', () async {
      final session = AdminSession(
        adminUsersRepository: _FakeAdminRepo(),
        authService: _FakeAuth(nextUser: null),
        firebaseEnabled: true,
      );

      expect(await session.signInWithGoogle(), isFalse);
      expect(session.isAdmin, isFalse);
      expect(session.signedInButNotAdmin, isFalse);
    });

    test('Google identity with no admins/{uid} doc is not an admin', () async {
      final session = AdminSession(
        adminUsersRepository: _FakeAdminRepo(),
        authService: _FakeAuth(
          nextUser: const SignedInUser(
            uid: 'u-unknown',
            email: 'someone@example.com',
            displayName: 'Not Admin',
          ),
        ),
        firebaseEnabled: true,
      );

      expect(await session.signInWithGoogle(), isFalse);
      expect(session.isAdmin, isFalse);
      expect(session.signedInButNotAdmin, isTrue);
    });

    test('the admins/{uid} document is the authoritative role source', () async {
      final repo = _FakeAdminRepo();
      await repo.grant(
        const AdminUser(
          uid: 'u-firebase-7',
          role: AdminRole.contentAdmin,
          email: 'stale@example.com',
          displayName: 'Old Name',
        ),
        grantedBy: 'mock-admin',
      );
      final session = AdminSession(
        adminUsersRepository: repo,
        authService: _FakeAuth(
          nextUser: const SignedInUser(
            uid: 'u-firebase-7',
            email: 'writer@example.com',
            displayName: 'Content Writer',
          ),
        ),
        firebaseEnabled: true,
      );

      expect(await session.signInWithGoogle(), isTrue);
      expect(session.isAdmin, isTrue);
      expect(session.role, AdminRole.contentAdmin);
      // Profile fields refresh from Google; role stays server-official.
      expect(session.user!.email, 'writer@example.com');
      expect(session.user!.displayName, 'Content Writer');
      expect(session.user!.role, AdminRole.contentAdmin);
    });

    test('signOut clears the session and calls Firebase signOut', () async {
      final repo = _FakeAdminRepo();
      await repo.grant(
        const AdminUser(uid: 'u-firebase-7', role: AdminRole.superAdmin),
      );
      final auth = _FakeAuth(
        nextUser: const SignedInUser(uid: 'u-firebase-7'),
      );
      final session = AdminSession(
        adminUsersRepository: repo,
        authService: auth,
        firebaseEnabled: true,
      );
      await session.signInWithGoogle();

      await session.signOut();

      expect(session.isAdmin, isFalse);
      expect(auth.signOutCalled, isTrue);
    });
  });
}