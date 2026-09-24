import '../../domain/models/announcement.dart';

/// Simple campaign announcements.
///
/// The student app reads the single active announcement (`active: true`); the
/// admin dashboard manages the full list. Writes are Super-Admin only.
abstract interface class AnnouncementsRepository {
  Future<List<Announcement>> fetchAll();

  /// The announcement currently shown to students, if any.
  Future<Announcement?> fetchActive();

  /// Creates or updates an announcement.
  Future<void> save(Announcement announcement);

  Future<void> setActive(String id, bool active);

  Future<void> delete(String id);
}