/// A user-submitted (or admin-curated) prayer intention.
///
/// Document path: `prayerIntentions/{intentionId}`.
class PrayerIntention {
  const PrayerIntention({
    this.id,
    required this.text,
    this.userId,
    this.anonymous = false,
    this.createdAt,
    this.prayerCount = 0,
    this.approved = false,
  });

  final String? id;
  final String text;
  final String? userId;
  final bool anonymous;
  final DateTime? createdAt;
  final int prayerCount;
  final bool approved;

  factory PrayerIntention.fromMap(String id, Map<String, dynamic> map) =>
      PrayerIntention(
        id: id,
        text: map['text'] as String? ?? '',
        userId: map['userId'] as String?,
        anonymous: map['anonymous'] as bool? ?? false,
        createdAt: map['createdAt'] is String
            ? DateTime.tryParse(map['createdAt'] as String)
            : map['createdAt'] is DateTime
            ? map['createdAt'] as DateTime
            : null,
        prayerCount: map['prayerCount'] as int? ?? 0,
        approved: map['approved'] as bool? ?? false,
      );

  Map<String, dynamic> toMap() => <String, dynamic>{
    'text': text,
    if (userId != null) 'userId': userId,
    'anonymous': anonymous,
    'createdAt': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    'prayerCount': prayerCount,
    'approved': approved,
  };
}