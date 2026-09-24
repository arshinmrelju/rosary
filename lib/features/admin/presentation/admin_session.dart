import 'package:flutter/foundation.dart';

import '../../../data/auth/auth_service.dart';
import '../../../data/mock/mock_admin_store.dart';
import '../../../data/repositories/admin_users_repository.dart';
import '../../../domain/models/admin_role.dart';
import '../../../domain/models/admin_user.dart';

/// Holds the current admin session and role for the admin dashboard.
///
/// Identity comes from Google Sign-In (Firebase): a user is only an admin when
/// an `admins/{uid}` document exists. The Firestore rules re-check that same
/// document, so this client state is a UI convenience — never the security
/// boundary.
///
/// In non-Firebase (mock) mode a demo Super Admin session is used so the whole
/// dashboard can be developed, previewed and tested without a backend.
class AdminSession extends ChangeNotifier {
  AdminSession({
    required this.adminUsersRepository,
    required this.authService,
    required this.firebaseEnabled,
  });

  final AdminUsersRepository adminUsersRepository;
  final AuthService authService;
  final bool firebaseEnabled;

  AdminUser? _user;
  bool _busy = false;
  bool _initialized = false;
  String? _error;
  bool _attempted = false;

  /// The authenticated admin, or `null` while signed out.
  AdminUser? get user => _user;

  AdminRole? get role => _user?.role;

  bool get isAdmin => _user != null;

  bool get isBusy => _busy;

  /// False until the first [restore] has finished.
  bool get isInitialized => _initialized;

  String? get error => _error;

  /// True when the user attempted Google sign-in but was not an admin.
  bool get signedInButNotAdmin => _attempted && !isAdmin;

  /// Restores a previous session without opening any UI (called at boot).
  Future<void> restore() async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      if (!firebaseEnabled) {
        // Mock mode always starts as the demo Super Admin.
        _user = _mockAdmin();
      }
    } catch (e) {
      _error = 'Could not restore your admin session.';
    }
    _busy = false;
    _initialized = true;
    notifyListeners();
  }

  /// Signs in with Google (Firebase) or the demo admin (mock mode).
  ///
  /// Returns `true` only when the identity resolves to an admin role.
  Future<bool> signInWithGoogle() async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      final signedIn = await authService.signInWithGoogle();
      if (signedIn == null) return false;
      _attempted = true;

      final admin = await adminUsersRepository.fetchCurrent(signedIn.uid);
      if (admin == null) {
        _user = null;
        return false;
      }
      _user = admin;
      final signedInAdmin = _user;
      // Keep any profile fields from the identity up to date for display.
      if (signedInAdmin != null &&
          (signedInAdmin.email != signedIn.email ||
              signedInAdmin.displayName != signedIn.displayName)) {
        _user = AdminUser(
          uid: signedInAdmin.uid,
          role: signedInAdmin.role,
          email: signedIn.email ?? signedInAdmin.email,
          displayName: signedIn.displayName ?? signedInAdmin.displayName,
          photoUrl: signedIn.photoUrl ?? signedInAdmin.photoUrl,
          createdAt: signedInAdmin.createdAt,
          createdBy: signedInAdmin.createdBy,
        );
      }
      return true;
    } catch (e) {
      _error = 'Could not sign in with Google.';
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _user = null;
    _attempted = false;
    if (firebaseEnabled) await authService.signOut();
    notifyListeners();
  }

  /// Swaps the active role for local development/testing (mock mode only).
  @visibleForTesting
  Future<void> setMockRole(AdminRole role) async {
    if (firebaseEnabled) return;
    _user = _mockAdmin(role);
    notifyListeners();
  }

  AdminUser _mockAdmin([AdminRole role = AdminRole.superAdmin]) => AdminUser(
    uid: MockAdminIdentity.uid,
    role: role,
    email: MockAdminIdentity.email,
    displayName: MockAdminIdentity.displayName,
    createdAt: DateTime(2026, 9, 1),
  );
}