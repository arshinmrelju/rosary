/// Admin roles used across the app, the admin UI and Firestore rules.
///
/// The role key is persisted in `admins/{uid}` as `{ role: <key> }` and is
/// enforced server-side by the Firestore rules; the client only uses these
/// permissions to decide what to render.
enum AdminRole {
  superAdmin('superadmin', 'Super Admin'),
  contentAdmin('content', 'Content Admin'),
  moderator('moderator', 'Moderator');

  const AdminRole(this.key, this.label);

  /// Persisted key, e.g. `superadmin`.
  final String key;

  /// Human readable label, e.g. "Super Admin".
  final String label;

  static AdminRole? fromKey(String? key) {
    for (final role in AdminRole.values) {
      if (role.key == key) return role;
    }
    return null;
  }

  /// All roles, oldest-first (used for role pickers).
  static List<AdminRole> get all => AdminRole.values;

  // ----- Permission matrix (mirrors the Firestore rules). -----

  bool get canEditContent => this == AdminRole.superAdmin || this == AdminRole.contentAdmin;

  bool get canPublishContent => canEditContent;

  bool get canModerate => this == AdminRole.superAdmin || this == AdminRole.moderator;

  bool get canManageSchedule => this == AdminRole.superAdmin;

  bool get canManageCampaign => this == AdminRole.superAdmin;

  bool get canManageAdmins => this == AdminRole.superAdmin;

  bool get canManageAnnouncements => this == AdminRole.superAdmin;

  bool get canViewReports => canModerate || this == AdminRole.superAdmin;

  bool get canDeleteContent => this == AdminRole.superAdmin;

  bool get canViewStatistics => true;

  bool get canViewLogs => this == AdminRole.superAdmin;

  bool get canViewAdminList => this == AdminRole.superAdmin;
}