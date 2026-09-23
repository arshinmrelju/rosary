import '../../domain/models/user_profile.dart';

/// Student profile stored in `users/{userId}`.
abstract interface class UserRepository {
  Future<UserProfile?> fetch(String userId);

  Future<void> save(UserProfile profile);
}