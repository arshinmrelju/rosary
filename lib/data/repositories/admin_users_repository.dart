import '../../domain/models/admin_user.dart';

/// Administrator directory (`admins/{uid}`).
///
/// This collection is the authoritative role store read by the Firestore
/// rules. Super Admins manage it; ordinary admins can only read their own
/// document (via the rules).
abstract interface class AdminUsersRepository {
  /// The current user's own admin document, or `null` when they have none.
  Future<AdminUser?> fetchCurrent(String uid);

  /// All administrators (Super Admin only in practice).
  Future<List<AdminUser>> fetchAll();

  /// Creates/updates an admin role document.
  Future<void> grant(AdminUser user, {String? grantedBy});

  Future<void> revoke(String uid);
}