import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/models/user_profile.dart';
import '../../firebase/firestore_paths.dart';
import '../user_repository.dart';

class FirestoreUserRepository implements UserRepository {
  const FirestoreUserRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<UserProfile?> fetch(String userId) async {
    final snapshot = await _firestore
        .collection(FirestorePaths.users)
        .doc(userId)
        .get();
    if (!snapshot.exists) return null;
    return UserProfile.fromMap(snapshot.data()!);
  }

  @override
  Future<void> save(UserProfile profile) async {
    if (profile.uid == null || profile.uid!.isEmpty) {
      throw ArgumentError('Cannot save a UserProfile without a uid.');
    }
    await _firestore
        .collection(FirestorePaths.users)
        .doc(profile.uid)
        .set(profile.toMap());
  }
}