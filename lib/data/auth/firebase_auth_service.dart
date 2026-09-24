import 'package:firebase_auth/firebase_auth.dart';

import 'auth_service.dart';

/// Firebase-backed auth using anonymous sign-in so no registration wall
/// exists. Upgradeable to email/social login in a later stage.
class FirebaseAuthService implements AuthService {
  FirebaseAuthService({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  @override
  Future<String> ensureUserId() async {
    if (_auth.currentUser != null) return _auth.currentUser!.uid;
    final result = await _auth.signInAnonymously();
    return result.user!.uid;
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<SignedInUser?> signInWithGoogle() async {
    // Drop any anonymous student session so the popup creates a fresh,
    // non-anonymous admin session.
    final current = _auth.currentUser;
    if (current != null) {
      await _auth.signOut();
    }
    try {
      final result = await _auth.signInWithPopup(GoogleAuthProvider());
      final user = result.user;
      if (user == null) return null;
      return SignedInUser(
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
        photoUrl: user.photoURL,
      );
    } catch (e) {
      // User cancelled the popup or the provider flow failed.
      return null;
    }
  }
}