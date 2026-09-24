import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/models/prayer_intention.dart';
import '../../firebase/firestore_paths.dart';
import '../moderation_repository.dart';

class FirestoreModerationRepository implements ModerationRepository {
  const FirestoreModerationRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<List<PrayerIntention>> fetchPending() => _fetchWhereApproved(false);

  @override
  Future<List<PrayerIntention>> fetchApproved() => _fetchWhereApproved(true);

  Future<List<PrayerIntention>> _fetchWhereApproved(bool approved) async {
    final query = await _firestore
        .collection(FirestorePaths.prayerIntentions)
        .where('approved', isEqualTo: approved)
        .orderBy('createdAt', descending: false)
        .get();

    return query.docs
        .map((doc) => PrayerIntention.fromMap(doc.id, doc.data()))
        .toList();
  }

  @override
  Future<void> approve(String intentionId) async {
    await _firestore
        .collection(FirestorePaths.prayerIntentions)
        .doc(intentionId)
        .update(<String, dynamic>{'approved': true});
  }

  @override
  Future<void> reject(String intentionId) async {
    await _firestore
        .collection(FirestorePaths.prayerIntentions)
        .doc(intentionId)
        .delete();
  }

  @override
  Future<void> hide(String intentionId) async {
    await _firestore
        .collection(FirestorePaths.prayerIntentions)
        .doc(intentionId)
        .update(<String, dynamic>{'approved': false});
  }

  @override
  Future<void> delete(String intentionId) async {
    await _firestore
        .collection(FirestorePaths.prayerIntentions)
        .doc(intentionId)
        .delete();
  }
}