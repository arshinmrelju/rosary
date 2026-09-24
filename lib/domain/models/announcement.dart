/// A simple campaign-wide announcement shown on the student Home screen.
///
/// Document path: `announcements/{announcementId}`.
class Announcement {
  const Announcement({
    this.id,
    required this.title,
    required this.message,
    this.active = false,
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final String title;
  final String message;

  /// When `true` the student Home screen displays this announcement.
  final bool active;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  Announcement copyWith({
    String? title,
    String? message,
    bool? active,
    DateTime? updatedAt,
  }) => Announcement(
    id: id,
    title: title ?? this.title,
    message: message ?? this.message,
    active: active ?? this.active,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  factory Announcement.fromMap(String id, Map<String, dynamic> map) {
    final createdAt = map['createdAt'] is String
        ? DateTime.tryParse(map['createdAt'] as String)
        : map['createdAt'] is DateTime
        ? map['createdAt'] as DateTime
        : null;
    final updatedAt = map['updatedAt'] is String
        ? DateTime.tryParse(map['updatedAt'] as String)
        : map['updatedAt'] is DateTime
        ? map['updatedAt'] as DateTime
        : null;
    return Announcement(
      id: id,
      title: map['title'] as String? ?? '',
      message: map['message'] as String? ?? '',
      active: map['active'] as bool? ?? false,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'title': title,
    'message': message,
    'active': active,
    'createdAt': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
  };
}