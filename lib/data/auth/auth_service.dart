/// Resolves the identity used to store participation.
///
/// Rule: students must be able to use the app without signing up. Firebase
/// builds use anonymous authentication so progress is still per-device;
/// future stages can upgrade anonymous sessions to real accounts.
abstract interface class AuthService {
  /// Returns a stable user id for the current session, creating an anonymous
  /// account when the platform supports it.
  Future<String> ensureUserId();

  Future<void> signOut();
}