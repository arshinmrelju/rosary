import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/models/announcement.dart';
import '../../firebase/firestore_paths.dart';
import '../announcements_repository.dart';

class FirestoreAnnouncementsRepository implements AnnouncementsRepository {
  const FirestoreAnnouncementsRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<List<Announcement>> fetchAll() async {
    final snapshot = await _firestore
        .collection(FirestorePaths.announcements)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => Announcement.fromMap(doc.id, doc.data()))
        .toList();
  }

  @override
  Future<Announcement?> fetchActive() async {
    final snapshot = await _firestore
        .collection(FirestorePaths.announcements)
        .where('active', isEqualTo: true)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return Announcement.fromMap(snapshot.docs.first.id, snapshot.docs.first.data());
  }

  @override
  Future<void> save(Announcement announcement) async {
    final doc = announcement.id == null
        ? _firestore.collection(FirestorePaths.announcements).doc()
        : _firestore
              .collection(FirestorePaths.announcements)
              .doc(announcement.id);
    await doc.set(announcement.toMap());
  }

  @override
  Future<void> setActive(String id, bool active) async {
    await _firestore
        .collection(FirestorePaths.announcements)
        .doc(id)
        .update(<String, dynamic>{
          'active': active,
          'updatedAt': DateTime.now().toIso8601String(),
        });
  }

  @override
  Future<void> delete(String id) async {
    await _firestore
        .collection(FirestorePaths.announcements)
        .doc(id)
        .delete();
  }
}