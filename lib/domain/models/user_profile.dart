/// Student profile stored in `users/{userId}`.
class UserProfile {
  const UserProfile({
    this.uid,
    this.displayName,
    this.email,
    this.photoUrl,
    this.department,
    this.year,
    this.createdAt,
    this.updatedAt,
  });

  final String? uid;
  final String? displayName;
  final String? email;
  final String? photoUrl;
  final String? department;
  final int? year;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isComplete =>
      displayName != null &&
      displayName!.isNotEmpty &&
      department != null &&
      year != null;

  UserProfile copyWith({
    String? uid,
    String? displayName,
    String? email,
    String? photoUrl,
    String? department,
    int? year,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => UserProfile(
    uid: uid ?? this.uid,
    displayName: displayName ?? this.displayName,
    email: email ?? this.email,
    photoUrl: photoUrl ?? this.photoUrl,
    department: department ?? this.department,
    year: year ?? this.year,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
    uid: map['uid'] as String?,
    displayName: map['displayName'] as String?,
    email: map['email'] as String?,
    photoUrl: map['photoUrl'] as String?,
    department: map['department'] as String?,
    year: map['year'] as int?,
    createdAt: _toDate(map['createdAt']),
    updatedAt: _toDate(map['updatedAt']),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    if (uid != null) 'uid': uid,
    if (displayName != null) 'displayName': displayName,
    if (email != null) 'email': email,
    if (photoUrl != null) 'photoUrl': photoUrl,
    if (department != null) 'department': department,
    if (year != null) 'year': year,
    if (createdAt != null) 'createdAt': createdAt,
    if (updatedAt != null) 'updatedAt': updatedAt,
  };
}

DateTime? _toDate(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}