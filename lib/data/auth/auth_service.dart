/// Identity returned by a provider sign-in (Google).
class SignedInUser {
  const SignedInUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
  });

  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
}

/// Resolves the identity used to store participation.
///
/// Rule: students must be able to use the app without signing up. Firebase
/// builds use anonymous authentication so progress is still per-device;
/// future stages can upgrade anonymous sessions to real accounts.
abstract interface class AuthService {
  /// Returns a stable user id for the current session, creating an anonymous
  /// account when the platform supports it.
  Future<String> ensureUserId();

  /// Signs the current session out.
  Future<void> signOut();

  /// Signs in with Google (Admin flow). Returns `null` when cancelled or the
  /// provider call fails. A user signed-in here is NOT necessarily an admin —
  /// the admin repository must confirm an `admins/{uid}` document exists.
  Future<SignedInUser?> signInWithGoogle();
}