import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/models/admin_user.dart';
import '../../firebase/firestore_paths.dart';
import '../admin_users_repository.dart';

class FirestoreAdminUsersRepository implements AdminUsersRepository {
  const FirestoreAdminUsersRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<AdminUser?> fetchCurrent(String uid) async {
    final snapshot = await _firestore
        .collection(FirestorePaths.admins)
        .doc(uid)
        .get();
    if (!snapshot.exists) return null;
    return AdminUser.fromMap(uid, snapshot.data()!);
  }

  @override
  Future<List<AdminUser>> fetchAll() async {
    final snapshot = await _firestore
        .collection(FirestorePaths.admins)
        .get();
    return snapshot.docs
        .map((doc) => AdminUser.fromMap(doc.id, doc.data()))
        .toList();
  }

  @override
  Future<void> grant(AdminUser user, {String? grantedBy}) async {
    final data = AdminUser(
      uid: user.uid,
      role: user.role,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoUrl,
      createdAt: user.createdAt ?? DateTime.now(),
      createdBy: grantedBy,
    ).toMap();
    await _firestore
        .collection(FirestorePaths.admins)
        .doc(user.uid)
        .set(data);
  }

  @override
  Future<void> revoke(String uid) async {
    await _firestore
        .collection(FirestorePaths.admins)
        .doc(uid)
        .delete();
  }
}