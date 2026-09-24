import 'admin_role.dart';

/// An authenticated administrator.
///
/// Document path: `admins/{uid}`. The document is the authoritative source of
/// an admin's role (checked by Firestore rules); never trust a client-asserted
/// `isAdmin` flag.
class AdminUser {
  const AdminUser({
    required this.uid,
    required this.role,
    this.email,
    this.displayName,
    this.photoUrl,
    this.createdAt,
    this.createdBy,
  });

  final String uid;

  final AdminRole role;

  final String? email;

  final String? displayName;

  final String? photoUrl;

  final DateTime? createdAt;

  /// UID of the super admin who granted this role.
  final String? createdBy;

  AdminUser copyWith({
    AdminRole? role,
    String? email,
    String? displayName,
    String? photoUrl,
  }) => AdminUser(
    uid: uid,
    role: role ?? this.role,
    email: email ?? this.email,
    displayName: displayName ?? this.displayName,
    photoUrl: photoUrl ?? this.photoUrl,
    createdAt: createdAt,
    createdBy: createdBy,
  );

  factory AdminUser.fromMap(String uid, Map<String, dynamic> map) => AdminUser(
    uid: uid,
    role: AdminRole.fromKey(map['role'] as String?) ?? AdminRole.moderator,
    email: map['email'] as String?,
    displayName: map['displayName'] as String?,
    photoUrl: map['photoUrl'] as String?,
    createdAt: map['createdAt'] is String
        ? DateTime.tryParse(map['createdAt'] as String)
        : map['createdAt'] is DateTime
        ? map['createdAt'] as DateTime
        : null,
    createdBy: map['createdBy'] as String?,
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    'role': role.key,
    'uid': uid,
    if (email != null) 'email': email,
    if (displayName != null) 'displayName': displayName,
    if (photoUrl != null) 'photoUrl': photoUrl,
    if (createdAt != null)
      'createdAt': createdAt!.toIso8601String()
    else
      'createdAt': DateTime.now().toIso8601String(),
    if (createdBy != null) 'createdBy': createdBy,
  };
}